#!/usr/bin/env bash
set -euo pipefail

# This script is triggered by a scheduled pipeline
# shellcheck source=./util.shlib
source .ci/util.shlib

# Read config file into global variables
UTIL_READ_CONFIG_FILE

export TMPDIR="${TMPDIR:-/tmp}"

# Special case: We are told to trigger a specific trigger
if [ -v TRIGGER ]; then
  PACKAGES=()
  TO_BUILD=()
  UTIL_GET_PACKAGES PACKAGES
  for package in "${PACKAGES[@]}"; do
    unset VARIABLES
    declare -A VARIABLES=()
    if UTIL_READ_MANAGED_PACAKGE "$package" VARIABLES; then
      if [ -v "VARIABLES[CI_ON_TRIGGER]" ]; then
        if [ "${VARIABLES[CI_ON_TRIGGER]}" == "$TRIGGER" ]; then
          TO_BUILD+=("$package")
        fi
      fi
    fi
  done
  if [ ${#TO_BUILD[@]} -ne 0 ]; then
    .ci/schedule-packages.sh schedule "${TO_BUILD[@]}"
  fi
  exit 0
fi

git config --global user.name "$GIT_AUTHOR_NAME"
git config --global user.email "$GIT_AUTHOR_EMAIL"

# Silence some very insane log spam. Master is set by default and the silenced
# message is declared as hint.
git config --global init.defaultBranch "master"

if [ -v TEMPLATE_ENABLE_UPDATES ] && [ "$TEMPLATE_ENABLE_UPDATES" == "true" ]; then
  { .ci/update-template.sh && UTIL_PRINT_INFO "Updated CI template." && exit 0; } || true
fi

# Check if the scheduled tag does not exist or scheduled does not point to HEAD
if ! [ "$(git tag -l "scheduled")" ] || [ "$(git rev-parse HEAD)" != "$(git rev-parse scheduled)" ]; then
  UTIL_PRINT_ERROR "Previous on-commit pipeline did not seem to run successfully. Aborting."
  exit 1
fi

PACKAGES=()
declare -A AUR_TIMESTAMPS
declare -A AUR_MAINTAINERS
LAST_AUR_TIMESTAMP=0
MODIFIED_PACKAGES=()
declare -A CHANGED_LIBS=()
DELETE_BRANCHES=()
UTIL_GET_PACKAGES PACKAGES
COMMIT="${COMMIT:-false}"
COMMIT_MESSAGE_PACKAGES=()

# Manage the .state worktree to confine the state of packages to a separate branch
# The goal is to keep the commit history clean
function manage_state() {
  if git show-ref --quiet "origin/state"; then
    git worktree add .state origin/state --detach -q
  else
    mkdir .state
  fi
  git worktree add .newstate -B state --orphan -q
}

# Loop through all packages to do optimized aur RPC calls
# $1 = Output associative timestamp array
# $2 = Output associative maintainers array
function collect_aur_info() {
  set -euo pipefail
  # shellcheck disable=SC2034
  local -n collect_aur_timestamps_output=$1
  # shellcheck disable=SC2034
  local -n collect_aur_maintainers_output=$2
  local AUR_PACKAGES=()

  if [ -f .ci/aur-state ]; then
    LAST_AUR_TIMESTAMP="$(<.ci/aur-state)"
  fi
  date +%s >.ci/aur-state

  for package in "${PACKAGES[@]}"; do
    unset VARIABLES
    declare -A VARIABLES=()
    if UTIL_READ_MANAGED_PACAKGE "$package" VARIABLES; then
      if [ -v "VARIABLES[CI_PKGBUILD_SOURCE]" ]; then
        local PKGBUILD_SOURCE="${VARIABLES[CI_PKGBUILD_SOURCE]}"
        if [[ "$PKGBUILD_SOURCE" == aur ]]; then
          AUR_PACKAGES+=("$package")
        fi
      fi
    fi
  done

  # Get all timestamps from AUR
  http_proxy="$CI_AUR_PROXY" https_proxy="$CI_AUR_PROXY" UTIL_FETCH_AUR_INFO collect_aur_timestamps_output collect_aur_maintainers_output "${AUR_PACKAGES[*]}"
}

function collect_changed_libs() {
  set -euo pipefail

  if [ -z "$CI_LIB_DB" ]; then
    return 0
  fi
  if [ ! -f .state/.version-state ]; then
    touch .state/.version-state
  fi

  IFS=' ' read -r -a link_array <<<"${CI_LIB_DB//\"/}"

  local _TEMP_LIB
  _TEMP_LIB="$(mktemp -d)"

  for repo in "${link_array[@]}"; do
    UTIL_PARSE_DATABASE "${repo}" "${_TEMP_LIB}"
  done

  # Sort versions file in-place because comm requires it
  sort -o "${_TEMP_LIB}/version-state"{,}
  comm -13 .state/.version-state "${_TEMP_LIB}/version-state" >"$_TEMP_LIB/versions.diff"

  while IFS= read -r line; do
    IFS=':' read -r -a pkg <<<"$line"
    CHANGED_LIBS["${pkg[0]}"]="true"
  done <"$_TEMP_LIB/versions.diff"

  mv "${_TEMP_LIB}/version-state" .newstate/.version-state
  rm -rf "$_TEMP_LIB"
}

function generate-commit() {
  set -euo pipefail

  local COMMIT_MESSAGE
  if ((${#COMMIT_MESSAGE_PACKAGES[@]} > 0)) && ((${#COMMIT_MESSAGE_PACKAGES[@]} < 4)); then
    local packages="$(printf "%s, " "${COMMIT_MESSAGE_PACKAGES[@]}")"
    COMMIT_MESSAGE="chore(update): ${packages%, }"
  elif ((${#COMMIT_MESSAGE_PACKAGES[@]} > 3)); then
    COMMIT_MESSAGE="chore(update): update packages (${#COMMIT_MESSAGE_PACKAGES[@]})"
  else
    COMMIT_MESSAGE="chore(update): update packages"
  fi

  if [ -v GITHUB_ACTIONS ]; then
    COMMIT_MESSAGE+=" [skip ci]"
  fi
  if [ "$1" == ".final" ]; then
    local COMMIT_DESCRIPTION=""
    if ((${#COMMIT_MESSAGE_PACKAGES[@]} > 3)); then
      local packages="$(printf "%s, " "${COMMIT_MESSAGE_PACKAGES[@]}")"
      COMMIT_DESCRIPTION+="changed: ${packages%, }"
    fi
    git commit -q --amend -m "$COMMIT_MESSAGE" -m "$COMMIT_DESCRIPTION"
  else
    COMMIT_MESSAGE_PACKAGES+=("$1")
    if [ "$COMMIT" == "false" ]; then
      COMMIT=true
      git commit -q -m "$COMMIT_MESSAGE"
    else
      git commit -q --amend --no-edit
    fi
  fi
}

function update-lib-bump() {
  set -euo pipefail
  local bump=0
  local -n pkg_config=${1:-VARIABLES}

  if [[ ! -v pkg_config[CI_REBUILD_TRIGGERS] ]]; then
    return 0
  fi

  # Split the string on : into an array
  IFS=':' read -r -a LIBS <<<"${pkg_config[CI_REBUILD_TRIGGERS]}"
  for library in "${LIBS[@]}"; do
    if [[ -v CHANGED_LIBS["$library"] ]]; then
      bump=1
      break
    fi
  done

  if [ $bump -eq 1 ]; then
    UTIL_PRINT_INFO "$package: Bumping pkgrel of $package because of a detected library version change"

    local _PKGVER_IN_DB _DB_BASE _DB_BUMP
    _PKGVER_IN_DB="$(grep "^$package:" ".state/.version-state" | cut -d ":" -f 2 || true)"

    if [[ "$_PKGVER_IN_DB" =~ ^(.+)-([0-9]+)(\.([0-9]+))?$ ]]; then
      _DB_BASE="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}" # base: pkgver-pkgrel
      _DB_BUMP=$((${BASH_REMATCH[4]:-0} + 1))          # bump
    else
      UTIL_PRINT_WARNING "$package: Could not find package version in the version-state file."
      return 0
    fi
    pkg_config[CI_PACKAGE_BUMP]="$_DB_BASE/$_DB_BUMP"
    pkg_config[CI_ANY_UPDATE]=true
  fi
}

# $1: dir1
# $2: dir2
function package_changed() {
  set -euo pipefail
  # Check if the package has changed
  # NOTE: We don't care if anything but the PKGBUILD or .SRCINFO has changed.
  # Any properly built PKGBUILD will use hashes, which will change
  if diff -q "$1/PKGBUILD" "$2/PKGBUILD" >/dev/null; then
    if [ ! -f "$1/.SRCINFO" ] && [ ! -f "$2/.SRCINFO" ]; then
      return 1
    elif [ -f "$1/.SRCINFO" ] && [ -f "$2/.SRCINFO" ]; then
      if diff -q "$1/.SRCINFO" "$2/.SRCINFO" >/dev/null; then
        return 1
      fi
    fi
  fi
  return 0
}

function package_major_change_normalize() {
  local line="$1"
  sed -Ee "s/'([a-zA-Z0-9_.-]+)'/\1/g" -e 's/"([a-zA-Z0-9_.-]+)"/\1/g' <<<"$line"
}

function package_major_change_sum_legal() {
  local sumline="$1"
  sumline="$(package_major_change_normalize "$sumline")"

  if [[ "$sumline" =~ ^[[:space:]]*([a-fA-F0-9]+|SKIP)?[[:space:]]*$ ]]; then
    # This is a legal sum line
    echo "PASS"
  elif [[ "$sumline" =~ ^[[:space:]]*([a-fA-F0-9]+|SKIP)?[[:space:]]*\)[[:space:]]*$ ]]; then
    # Legal sum line (optional) + end of sums array
    # The reason for making the sum optional is to allow for the array to end on a line that only has ")"
    echo "END"
  else
    # Illegal line in sums array
    echo "FAIL"
  fi
}

# Check if the package has gotten major changes
# Any change that is not a pkgver or pkgrel bump is considered a major change
# $1: Directory containing new PKGBUILD
# $2: Directory containing old PKGBUILD
# Return code is 0 if no errors have been detected
# 0 does NOT mean no major changes.
# The string "PASS" is output if no major changes have been detected
# Otherwise, no output is given
function package_major_change() {
  set -euo pipefail
  local newFileLine oldFileLine inSums
  inSums=false

  local pkgverRegex='^_?pkgver *= *[a-zA-Z0-9_.-]+[[:space:]]*$'
  local pkgrelRegex='^pkgrel *= *[a-zA-Z0-9_.-]+[[:space:]]*$'
  local sumsArrayStartRegex='^(sha(1|224|256|384|512)|md5|b2)sums(_(x86_64|i686|aarch64|armv7h))? *= *\((.*)$'

  # Compare file line by line
  while true; do
    local newFileLineCode=0 oldFileLineCode=0
    read newFileLine <&3 || newFileLineCode=$?
    read oldFileLine <&4 || oldFileLineCode=$?

    if [[ $newFileLineCode -ne $oldFileLineCode ]]; then
      # One file ended before the other, major change
      return 0
    fi

    if [[ $newFileLineCode -ne 0 ]]; then
      # Both files ended, done checking
      break
    fi

    if [[ "$newFileLine" =~ $sumsArrayStartRegex ]] && [[ "$inSums" == false ]]; then
      inSums=true
      newFileLine="${BASH_REMATCH[5]}"
      # Old file also has to be checked. Is this also the start of the sums array?
      if [[ "$oldFileLine" =~ $sumsArrayStartRegex ]]; then
        oldFileLine="${BASH_REMATCH[5]}"
      else
        # Old file does not have sums array start where new file has it. Major change.
        return 0
      fi
    fi

    if [[ "$inSums" == true ]]; then
        local newSumCheck oldSumCheck
        newSumCheck="$(package_major_change_sum_legal "$newFileLine")"
        oldSumCheck="$(package_major_change_sum_legal "$oldFileLine")"
        if [[ "$newSumCheck" != "$oldSumCheck" ]]; then
          # One of the files has an illegal sum line or one ended the sums while the other didn't
          return 0
        fi
        case "$newSumCheck" in
          PASS) continue ;;
          END) inSums=false; continue ;;
          FAIL) return 0 ;;
        esac
        # Failsafe
        return 0
    fi

    if [[ "$newFileLine" == "$oldFileLine" ]]; then
      # Exact match, ignore this
      continue
    fi

    # Normalize any kinds of quotes in the lines for the following checks
    newFileLine="$(package_major_change_normalize "$newFileLine")"
    oldFileLine="$(package_major_change_normalize "$oldFileLine")"

    # Check if the line is a legal pkgver or pkgrel change
    # Legal means that both the line in the old file and the line in the new file are okay
    # This prevents a malicious change that changes a line that wasn't a pkgver line before
    if [[ "$newFileLine" =~ $pkgverRegex && "$oldFileLine" =~ $pkgverRegex ]]; then
      # A-okay
      continue
    fi

    # Check if the line is a legal pkgrel change
    # Same notes as above
    if [[ "$newFileLine" =~ $pkgrelRegex && "$oldFileLine" =~ $pkgrelRegex ]]; then
      continue
    fi

    # If we reach this point, the change is major
    return 0
  done 3<"$1/PKGBUILD" 4<"$2/PKGBUILD"

  # Check the rest of the files in the folder for changes
  # Excluding PKGBUILD .SRCINFO, .gitignore, .git .CI
  # shellcheck disable=SC2046
  if ! diff -q $(UTIL_GET_EXCLUDE_LIST "-x" "PKGBUILD .SRCINFO") -r "$1" "$2" >/dev/null; then
    return 0
  fi

  # No major changes found
  echo "PASS"
}

# $1: VARIABLES
# $2: git URL
function update_via_git() {
  set -euo pipefail
  local -n VARIABLES_VIA_GIT=${1:-VARIABLES}
  local git_url="${2:-}"
  local branch="${3:-}"
  local pkgbase="${VARIABLES_VIA_GIT[PKGBASE]}"

  for i in {1..2}; do
    local clone_args=("-q" "--depth=1" "$git_url" "$TMPDIR/aur-pulls/$pkgbase")
    if [ -n "$branch" ]; then
      clone_args=("-q" "--depth=1" "--branch" "$branch" "--single-branch" "$git_url" "$TMPDIR/aur-pulls/$pkgbase")
    fi

    if git clone "${clone_args[@]}" 2>/dev/null; then
      break
    fi

    if [ "$i" -ne 2 ]; then
      UTIL_PRINT_WARNING "$pkgbase: Failed to clone $git_url. Retrying in 30 seconds."
      sleep 30
    else
      # Give up
      false
    fi
  done

  # Ratelimits
  sleep "$CI_CLONE_DELAY"

  # We always run shfmt on the PKGBUILD. Two runs of shfmt on the same file should not change anything
  shfmt -w "$TMPDIR/aur-pulls/$pkgbase/PKGBUILD"
  if package_changed "$TMPDIR/aur-pulls/$pkgbase" "$pkgbase"; then
    if [ -v CI_HUMAN_REVIEW ] && [ "$CI_HUMAN_REVIEW" == "true" ]; then
      local package_major_change_output
      if ! package_major_change_output="$(package_major_change "$TMPDIR/aur-pulls/$pkgbase" "$pkgbase")"; then
        UTIL_PRINT_ERROR "$pkgbase: Error running major change check."
        return
      fi
      if [ "$package_major_change_output" != "PASS" ]; then
        UTIL_PRINT_INFO "$pkgbase: Major change detected."
        VARIABLES_VIA_GIT[CI_REQUIRES_REVIEW]=true
      fi
    fi
    # Rsync: delete files in the destination that are not in the source. Exclude deleting .CI, exclude copying .git
    # shellcheck disable=SC2046
    rsync -a --delete $(UTIL_GET_EXCLUDE_LIST "--exclude") "$TMPDIR/aur-pulls/$pkgbase/" "$pkgbase/"
    VARIABLES_VIA_GIT[CI_ANY_UPDATE]=true
  fi
}

# $1: VARIABLES
# $2: source
function update_from_gitlab_tag() {
  set -euo pipefail
  local -n VARIABLES_UPDATE_FROM_GITLAB_TAG=${1:-VARIABLES}
  local pkgbase="${VARIABLES_UPDATE_FROM_GITLAB_TAG[PKGBASE]}"
  local project_id="${2:-}"

  if [ ! -f "$pkgbase/.SRCINFO" ]; then
    UTIL_PRINT_ERROR "$pkgbase: .SRCINFO does not exist."
    return
  fi

  local TAG_OUTPUT
  if ! TAG_OUTPUT="$(curl --fail-with-body --silent "https://gitlab.com/api/v4/projects/${project_id}/repository/tags?order_by=version&per_page=1")" || [ -z "$TAG_OUTPUT" ]; then
    UTIL_PRINT_ERROR "$pkgbase: Failed to get list of tags."
    return
  fi

  local COMMIT_URL VERSION
  COMMIT_URL="$(jq -r '.[0].commit.web_url' <<<"$TAG_OUTPUT")"
  VERSION="$(jq -r '.[0].name' <<<"$TAG_OUTPUT")"

  if [ -z "$COMMIT_URL" ] || [ -z "$VERSION" ]; then
    UTIL_PRINT_ERROR "$pkgbase: Failed to get latest tag."
    return
  fi

  # Parse .SRCINFO file for PKGVER
  local SRCINFO_PKGVER
  if ! SRCINFO_PKGVER="$(grep -m 1 -oP '\tpkgver\s=\s\K.*$' "$pkgbase/.SRCINFO")"; then
    UTIL_PRINT_ERROR "$pkgbase: Failed to parse PKGVER from .SRCINFO."
    return
  fi

  # Check if the tag is different from the PKGVER
  if [ "$VERSION" == "$SRCINFO_PKGVER" ]; then
    return
  fi

  # Extract project URL and commit hash from commit URL
  # shellcheck disable=2034
  local DOWNLOAD_URL BASE_URL COMMIT PROJECT_NAME
  if [[ "$COMMIT_URL" =~ ^(.*)/([^/]+)/-/commit/([^/]+)$ ]]; then
    PROJECT_NAME="${BASH_REMATCH[2]}"
    COMMIT="${BASH_REMATCH[3]}"
    BASE_URL="${BASH_REMATCH[1]}/${PROJECT_NAME}/-/archive"
  else
    UTIL_PRINT_ERROR "$pkgbase: Failed to parse commit URL."
    return
  fi

  shfmt -w "$pkgbase/PKGBUILD"

  VARIABLES_UPDATE_FROM_GITLAB_TAG[CI_ANY_UPDATE]=true
  gawk -i inplace -f .ci/awk/update-pkgbuild.awk -v TARGET_VERSION="$VERSION" -v BASE_URL="$BASE_URL" -v TARGET_URL="${BASE_URL}/\${_commit}/${PROJECT_NAME}-\${_commit}.tar.gz" -v COMMIT="$COMMIT" "$pkgbase/PKGBUILD"
  gawk -i inplace -f .ci/awk/update-srcinfo.awk -v TARGET_VERSION="$VERSION" -v BASE_URL="$BASE_URL" -v TARGET_URL="${BASE_URL}/${COMMIT}/${PROJECT_NAME}-${COMMIT}.tar.gz" "$pkgbase/.SRCINFO"
}

function update_pkgbuild() {
  set -euo pipefail
  local -n VARIABLES_UPDATE_PKGBUILD=${1:-VARIABLES}
  local pkgbase="${VARIABLES_UPDATE_PKGBUILD[PKGBASE]}"

  if ! [ -v "VARIABLES_UPDATE_PKGBUILD[CI_PKGBUILD_SOURCE]" ] || [ -z "${VARIABLES_UPDATE_PKGBUILD[CI_PKGBUILD_SOURCE]}" ]; then
    UTIL_PRINT_WARNING "$pkgbase: CI_PKGBUILD_SOURCE is not set. If this is on purpose, please set it to 'custom'."
    return 0
  fi

  local PKGBUILD_SOURCE="${VARIABLES_UPDATE_PKGBUILD[CI_PKGBUILD_SOURCE]}"

  if [[ "$PKGBUILD_SOURCE" == "custom" ]]; then
    return 0
  # Check if the source starts with gitlab:
  elif [[ "$PKGBUILD_SOURCE" =~ ^gitlab:(.*) ]]; then
    update_from_gitlab_tag VARIABLES_UPDATE_PKGBUILD "${BASH_REMATCH[1]}"
  # Check if the package is from the AUR
  elif [[ "$PKGBUILD_SOURCE" != aur ]]; then
    update_via_git VARIABLES_UPDATE_PKGBUILD "$PKGBUILD_SOURCE"
  else
    local git_url="https://github.com/archlinux/aur.git"

    # Fetch from optimized AUR RPC call
    if ! [ -v "AUR_TIMESTAMPS[$pkgbase]" ]; then
      UTIL_PRINT_WARNING "Could not find $pkgbase in cached AUR timestamps."
      return 0
    fi
    local NEW_TIMESTAMP="${AUR_TIMESTAMPS[$pkgbase]}"

    if ((NEW_TIMESTAMP <= LAST_AUR_TIMESTAMP)); then
      return 0
    fi
    http_proxy="$CI_AUR_PROXY" https_proxy="$CI_AUR_PROXY" update_via_git VARIABLES_UPDATE_PKGBUILD "$git_url" "$pkgbase"
  fi
}

function update_vcs() {
  set -euo pipefail
  local -n VARIABLES_UPDATE_VCS=${1:-VARIABLES}
  local pkgbase="${VARIABLES_UPDATE_VCS[PKGBASE]}"

  # Check if pkgbase ends with -git or if CI_FORCE_VCS is set
  if [[ "$pkgbase" != *-git ]] && [[ "${VARIABLES[CI_FORCE_VCS]:-false}" != "true" ]]; then
    return 0
  fi

  local _NEWEST_COMMIT
  if ! _NEWEST_COMMIT="$(UTIL_FETCH_VCS_COMMIT VARIABLES_UPDATE_VCS)"; then
    UTIL_PRINT_WARNING "Could not fetch latest commit for $pkgbase via heuristic."
    return 0
  fi

  if [ -z "$_NEWEST_COMMIT" ]; then
    unset "VARIABLES_UPDATE_VCS[CI_GIT_COMMIT]"
    return 0
  fi

  # Check if CI_GIT_COMMIT is set
  if [ -v "VARIABLES_UPDATE_VCS[CI_GIT_COMMIT]" ]; then
    local CI_GIT_COMMIT="${VARIABLES_UPDATE_VCS[CI_GIT_COMMIT]}"
    if [ "$CI_GIT_COMMIT" != "$_NEWEST_COMMIT" ]; then
      UTIL_UPDATE_VCS_COMMIT VARIABLES_UPDATE_VCS "$_NEWEST_COMMIT"
      VARIABLES_UPDATE_VCS[CI_ANY_UPDATE]=true
    fi
  else
    UTIL_UPDATE_VCS_COMMIT VARIABLES_UPDATE_VCS "$_NEWEST_COMMIT"
    VARIABLES_UPDATE_VCS[CI_ANY_UPDATE]=true
  fi
}

# Format maintainer names for display
# $1: maintainer string (comma-separated list)
# Returns formatted string like "maintainer1" or "maintainer1, maintainer2"
function format_maintainers() {
  set -euo pipefail
  local maintainers="$1"
  local -a maintainer_list

  IFS=',' read -ra maintainer_list <<<"$maintainers"

  # Remove leading/trailing whitespace from each maintainer
  for i in "${!maintainer_list[@]}"; do
    maintainer_list[$i]=$(echo "${maintainer_list[$i]}" | xargs)
  done

  if [ ${#maintainer_list[@]} -eq 1 ]; then
    printf "%s" "${maintainer_list[0]}"
  elif [ ${#maintainer_list[@]} -eq 2 ]; then
    printf "%s, %s" "${maintainer_list[0]}" "${maintainer_list[1]}"
  else
    printf "%s" "$(printf '%s, ' "${maintainer_list[@]}" | sed 's/, $//')"
  fi
}

# Check maintainer trust level for AUR packages
# $1: package name
# $2: VARIABLES array name
# Stores formatted maintainer info in VARIABLES array for later use
function check_maintainer_trust() {
  set -euo pipefail
  local package="$1"
  local -n pkg_vars=${2:-VARIABLES}

  # Only check if package is from AUR
  if ! [ -v "pkg_vars[CI_PKGBUILD_SOURCE]" ] || [ "${pkg_vars[CI_PKGBUILD_SOURCE]}" != "aur" ]; then
    UTIL_PRINT_INFO "$package: Package is not from AUR, skipping maintainer trust check."
    VARIABLES[CI_MAINTAINER_TRUSTED]=true
    return 0
  fi

  # Only check if we have maintainer info
  if ! [ -v "AUR_MAINTAINERS[$package]" ]; then
    UTIL_PRINT_WARNING "Could not find $package in cached AUR maintainers."
    VARIABLES[CI_MAINTAINER_TRUSTED]=false
    return 0
  fi

  local untrusted_maintainers
  UTIL_SET_MAINTAINER_STRATEGY VARIABLES "${AUR_MAINTAINERS[$package]}"
  untrusted_maintainers="${VARIABLES[CI_MAINTAINER_UNTRUSTED]:-}"

  # Store formatted maintainer info in VARIABLES for later use
  if [ "${VARIABLES[CI_MAINTAINER_TRUSTED]:-false}" == "true" ]; then
    VARIABLES[CI_MAINTAINER_FORMATTED]=$(format_maintainers "${AUR_MAINTAINERS[$package]}")
  else
    # Store untrusted maintainers if any
    if [ -n "$untrusted_maintainers" ]; then
      VARIABLES[CI_MAINTAINER_FORMATTED]=$(format_maintainers "$untrusted_maintainers")
    fi
  fi
}

# Create .state and .newstate worktrees
manage_state

# Collect last modified timestamps and maintainer information from AUR in an efficient way
collect_aur_info AUR_TIMESTAMPS AUR_MAINTAINERS

# Parse database files for library version changes
collect_changed_libs CHANGED_LIBS

mkdir "$TMPDIR/aur-pulls"
if [ -f "./.editorconfig" ]; then
  cp "./.editorconfig" "$TMPDIR/aur-pulls/.editorconfig"
fi

# Loop through all packages to check if they need to be updated
for package in "${PACKAGES[@]}"; do
  unset VARIABLES
  declare -A VARIABLES=()
  UTIL_READ_MANAGED_PACAKGE "$package" VARIABLES || true
  update_pkgbuild VARIABLES
  update_vcs VARIABLES
  update-lib-bump VARIABLES
  UTIL_LOAD_CUSTOM_HOOK "./${package}" "./${package}/.CI/update.sh" && VARIABLES[CI_ANY_UPDATE]=true || true
  UTIL_WRITE_MANAGED_PACKAGE "$package" VARIABLES

  if [ "${VARIABLES[CI_ANY_UPDATE]:-false}" != "true" ]; then
    continue
  fi

  if ! git diff --exit-code --quiet -- "$package"; then
    # shellcheck disable=SC2102
    if [[ -v VARIABLES[CI_REQUIRES_REVIEW] ]] && [ "${VARIABLES[CI_REQUIRES_REVIEW]}" == "true" ]; then
      check_maintainer_trust "$package" VARIABLES
      maintainer_info=""
      if [[ -v VARIABLES[CI_MAINTAINER_FORMATTED] ]]; then
        maintainer_info=" ${VARIABLES[CI_MAINTAINER_FORMATTED]}"
      fi

      # If maintainer is trusted, skip PR creation and apply update directly
      if [ "${VARIABLES[CI_MAINTAINER_TRUSTED]:-false}" == "true" ]; then
        UTIL_PRINT_INFO "$package: Skipping PR creation due to trusted maintainer(s)$maintainer_info"
        # Drop back to normal update flow
      else
        UTIL_PRINT_INFO "$package: Creating PR for review due to untrusted maintainer(s)$maintainer_info"
        if [ "$COMMIT" == "false" ]; then
          .ci/create-pr.sh "$package" false "$CI_HUMAN_REVIEW_ASSIGNEE"
        else
          # If we already made a commit, we should go one commit further back to avoid merge conflicts
          # This is because there is a very high chance this current commit will be amended
          .ci/create-pr.sh "$package" true "$CI_HUMAN_REVIEW_ASSIGNEE"
        fi
        # Prevent from dropping into the normal update flow, since we already created the PR
        continue
      fi
    fi

    # Normal update flow
    git add "$package"
    generate-commit "$package"

    # We don't want to schedule packages that have a specific trigger to prevent
    # large packages getting scheduled too often and wasting resources (e.g. llvm-git)
    if [[ -v "VARIABLES[CI_ON_TRIGGER]" ]]; then
      UTIL_PRINT_INFO "Will not schedule $package because it has trigger ${VARIABLES[CI_ON_TRIGGER]} set."
    else
      MODIFIED_PACKAGES+=("$package")
    fi

    if [ -v CI_HUMAN_REVIEW ] && [ "$CI_HUMAN_REVIEW" == "true" ] && git show-ref --quiet "origin/update-$package"; then
      DELETE_BRANCHES+=("update-$package")
    fi
  # We also need to check the worktree for changes, because we might have an updated git hash
  elif ! UTIL_CHECK_STATE_DIFF "$package"; then
    if [[ -v "VARIABLES[CI_ON_TRIGGER]" ]]; then
      UTIL_PRINT_INFO "Will not schedule $package because it has trigger ${VARIABLES[CI_ON_TRIGGER]} set."
    else
      MODIFIED_PACKAGES+=("$package")
    fi
  fi
done

git -C .newstate add -A
git -C .newstate commit -q -m "chore(state): update state" --allow-empty

if [ ${#MODIFIED_PACKAGES[@]} -ne 0 ]; then
  .ci/schedule-packages.sh schedule "${MODIFIED_PACKAGES[@]}"
  .ci/manage-aur.sh "${MODIFIED_PACKAGES[@]}"
fi

git_push_args=()
for branch in "${DELETE_BRANCHES[@]}"; do
  git_push_args+=(":$branch")
done
[ -v GITLAB_CI ] && git_push_args+=("-o" "ci.skip")

if [ "$COMMIT" == "true" ]; then
  git add .ci/aur-state
  generate-commit ".final"

  git tag -f scheduled
  git push --atomic origin HEAD:main +state +refs/tags/scheduled "${git_push_args[@]}"
else
  git push --atomic origin +state "${git_push_args[@]}"
fi
