#!/usr/bin/env bash
set -euo pipefail

# This script is triggered for manual package bumping via the web interface
# shellcheck source=./util.shlib
source .ci/util.shlib

# Read config file into global variables
UTIL_READ_CONFIG_FILE

export TMPDIR="${TMPDIR:-/tmp}"

if [ "$PACKAGES" == "all" ]; then
  PACKAGES_LIST=()
  UTIL_GET_PACKAGES PACKAGES_LIST
else
  IFS=':' read -r -a PACKAGES_LIST <<<"$PACKAGES"
fi

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

  mv "${_TEMP_LIB}/version-state" .newstate/.version-state
  rm -rf "$_TEMP_LIB"
}

# Force bump a package by incrementing pkgrel
function force_bump() {
  local package="$1"
  unset VARIABLES
  declare -A VARIABLES=()
  UTIL_READ_MANAGED_PACAKGE "$package" VARIABLES || true

  # Get current version from the updated version-state
  if [ -f .newstate/.version-state ]; then
    local current_version
    current_version="$(grep "^$package:" ".newstate/.version-state" | cut -d ":" -f 2 || true)"

    if [ -n "$current_version" ]; then
      # Parse pkgver-pkgrel from current_version
      if [[ "$current_version" =~ ^(.+)-([0-9]+)$ ]]; then
        local base_version="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}"
        local bump_number=1

        # Check if already has a bump
        if [[ "$current_version" =~ ^(.+)-([0-9]+)\.([0-9]+)$ ]]; then
          base_version="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}"
          bump_number=$((${BASH_REMATCH[3]} + 1))
        fi

        VARIABLES[CI_PACKAGE_BUMP]="$base_version/$bump_number"
        UTIL_PRINT_INFO "$package: Forcing pkgrel bump to $base_version/$bump_number"
      else
        UTIL_PRINT_WARNING "$package: Could not parse version $current_version"
        return 1
      fi
    else
      UTIL_PRINT_WARNING "$package: No current version found in database"
      return 1
    fi
  else
    UTIL_PRINT_WARNING "$package: No version-state file found"
    return 1
  fi

  VARIABLES[CI_ANY_UPDATE]=true
  UTIL_WRITE_MANAGED_PACKAGE "$package" VARIABLES
  return 0
}

# Create .state and .newstate worktrees
manage_state

# Parse database files for current package versions
collect_changed_libs

MODIFIED_PACKAGES=()

for package in "${PACKAGES_LIST[@]}"; do
  if force_bump "$package"; then
    # Check if package directory has changes (e.g., .CI/config was updated)
    if ! git diff --exit-code --quiet -- "$package"; then
      git add "$package"
      MODIFIED_PACKAGES+=("$package")
    fi
  fi
done

# Commit package changes if any
if [ ${#MODIFIED_PACKAGES[@]} -ne 0 ]; then
  COMMIT_MESSAGE=""
  if ((${#MODIFIED_PACKAGES[@]} == 1)); then
    COMMIT_MESSAGE="chore(bump): bump ${MODIFIED_PACKAGES[0]}"
  else
    COMMIT_MESSAGE="chore(bump): bump packages (${#MODIFIED_PACKAGES[@]})"
  fi

  if [ -v GITLAB_CI ]; then
    COMMIT_MESSAGE+=" [skip ci]"
  fi

  git commit -q -m "$COMMIT_MESSAGE"
fi

if [ ${#MODIFIED_PACKAGES[@]} -ne 0 ]; then
  .ci/schedule-packages.sh schedule "${MODIFIED_PACKAGES[@]}"
  .ci/manage-aur.sh "${MODIFIED_PACKAGES[@]}"
fi

# Commit state changes
git -C .newstate add -A
git -C .newstate commit -q -m "chore(state): manual bump" --allow-empty

# Push changes
git push origin state
