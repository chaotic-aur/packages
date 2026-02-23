#!/usr/bin/env bash
set -euo pipefail

# This script is triggered for manual package dropping via the web interface
# shellcheck source=./util.shlib
source .ci/util.shlib

# Read config file into global variables
UTIL_READ_CONFIG_FILE

UTIL_SET_GIT_IDENTITY

export TMPDIR="${TMPDIR:-/tmp}"

PACKAGES_LIST=()
UTIL_PARSE_PACKAGELIST PACKAGES_LIST "$PACKAGES"

MODIFIED_PACKAGES=()

for package in "${PACKAGES_LIST[@]}"; do
  if [ -d "${package}" ]; then
    UTIL_PRINT_INFO "Dropping package ${package}..."
    git rm -r "${package}"
    MODIFIED_PACKAGES+=("${package}")
  else
    UTIL_PRINT_WARNING "Package ${package} does not exist. Skipping."
  fi
done

# Commit package changes if any
if [ ${#MODIFIED_PACKAGES[@]} -ne 0 ]; then
  COMMIT_MESSAGE=""
  COMMIT_DESCRIPTION=""
  {
    read -r COMMIT_MESSAGE
    read -r COMMIT_DESCRIPTION
  } < <(UTIL_COMMIT_MESSAGE MODIFIED_PACKAGES "chore(drop)!" "dropped")

  commit_args=("-q" "-m" "$COMMIT_MESSAGE")
  if [[ -n "$COMMIT_DESCRIPTION" ]]; then
    commit_args+=("-m" "$COMMIT_DESCRIPTION")
  fi

  git commit "${commit_args[@]}"
fi

# Push changes
git push origin HEAD:main
