#!/usr/bin/env bash
set -euo pipefail

# This script is triggered for manual package bumping via the web interface
# shellcheck source=./util.shlib
source .ci/util.shlib

# Read config file into global variables
UTIL_READ_CONFIG_FILE

export TMPDIR="${TMPDIR:-/tmp}"

# Set git identity for commits
git config --global user.name "$GIT_AUTHOR_NAME" 2>/dev/null || true
git config --global user.email "$GIT_AUTHOR_EMAIL" 2>/dev/null || true

if [ "$PACKAGES" == "all" ]; then
  PACKAGES_LIST=()
  UTIL_GET_PACKAGES PACKAGES_LIST
else
  IFS=':' read -r -a PACKAGES_LIST <<<"$PACKAGES"
fi

function collect_versions() {
  set -euo pipefail

  local DEST_FILE="$1"

  if [ -z "$CI_LIB_DB" ]; then
    return 0
  fi

  IFS=' ' read -r -a link_array <<<"${CI_LIB_DB//\"/}"

  local _TEMP_LIB
  _TEMP_LIB="$(mktemp -d)"

  for repo in "${link_array[@]}"; do
    UTIL_PARSE_DATABASE "${repo}" "${_TEMP_LIB}"
  done

  # Sort versions file in-place because comm requires it
  sort -o "${_TEMP_LIB}/version-state"{,}

  dd if="${_TEMP_LIB}/version-state" of="${DEST_FILE}"
  rm -rf "$_TEMP_LIB"
}

# Force bump a package by incrementing pkgrel
function force_bump() {
  local versions_file="$1"
  local package="$2"
  unset VARIABLES
  declare -A VARIABLES=()
  UTIL_READ_MANAGED_PACAKGE "$package" VARIABLES || true

  # Force writing config even if it didn't exist
  unset 'VARIABLES[CI_NO_CONFIG]'

  # Get current version from the versions file
  if [ -f "${versions_file}" ]; then
    local current_version
    current_version="$(grep "^$package:" "${versions_file}" | cut -d ":" -f 2 || true)"

    if [ -n "$current_version" ]; then
      # Parse pkgver-pkgrel.bumped format
      # Examples: 1.0-1, 1.0-1.5, 1.0rc-1.8
      if [[ "$current_version" =~ ^(.+)-([0-9]+)(\.([0-9]+))?$ ]]; then
        local pkgver="${BASH_REMATCH[1]}"
        local pkgrel="${BASH_REMATCH[2]}"
        local current_bump="${BASH_REMATCH[4]:-0}"
        local base_version="$pkgver-$pkgrel"
        local bump_number=$((current_bump + 1))

        # If the config already has a bump for this version, increment it further
        if [ -v "VARIABLES[CI_PACKAGE_BUMP]" ]; then
          if [[ "${VARIABLES[CI_PACKAGE_BUMP]}" =~ ^(.+)/([0-9]+)$ ]]; then
            local existing_base="${BASH_REMATCH[1]}"
            local existing_bump="${BASH_REMATCH[2]}"
            if [ "$existing_base" == "$base_version" ]; then
              bump_number=$((existing_bump > current_bump ? existing_bump + 1 : current_bump + 1))
            fi
          fi
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
    UTIL_PRINT_WARNING "$package: No versions file found"
    return 1
  fi

  VARIABLES[CI_ANY_UPDATE]=true
  UTIL_WRITE_MANAGED_PACKAGE "$package" VARIABLES
  return 0
}

TEMP_VERSIONS="$(mktemp)"
# Parse database files for current package versions
collect_versions "${TEMP_VERSIONS}"

MODIFIED_PACKAGES=()

for package in "${PACKAGES_LIST[@]}"; do
  if force_bump "$TEMP_VERSIONS" "$package"; then
    git add "$package"
    MODIFIED_PACKAGES+=("$package")
  else
    UTIL_PRINT_WARNING "$package: force_bump failed"
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

  git commit -q -m "$COMMIT_MESSAGE"
fi

# Push changes
git push origin HEAD:main
