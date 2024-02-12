#!/usr/bin/env bash

set -euo pipefail
set -x

# This script parses the parameters passed to this script and outputs a list of package names to a file

declare -a PACKAGES
COMMAND="$1"
shift

PACKAGES=("$@")

source .ci/util.shlib

if [ -v "PACKAGES[0]" ] && [ "${PACKAGES[0]}" == "all" ] && [ "$COMMAND" == "schedule" ]; then
    echo "Rebuild of all packages requested."
    UTIL_GET_PACKAGES PACKAGES
fi

declare -a PARAMS
if [ "$COMMAND" == "auto-repo-remove" ]; then
    UTIL_GET_PACKAGES PACKAGES
    PARAMS+=("auto-repo-remove" "--repo=$REPO_NAME")
elif [ "$COMMAND" == "schedule" ]; then
    PARAMS+=("schedule" "--repo=$REPO_NAME")
else
    echo "Unknown command: $COMMAND"
    exit 1
fi

# Check if the array of packages is empty
if [ ${#PACKAGES[@]} -eq 0 ]; then
    echo "No packages selected."
    exit 0
fi

# Check if running on gitlab
if [ -v GITLAB_CI ]; then
    PARAMS+=("--commit")
    PARAMS+=("${CI_COMMIT_SHA}:${CI_PIPELINE_ID}")
elif [ -v GITHUB_ACTIONS ]; then
    echo "Warning: Pipeline updates are not supported on GitHub Actions yet."
fi

if [ "$COMMAND" == "schedule" ]; then
    # Prepend the source repo name to each package name and push to PARAMS
    for i in "${!PACKAGES[@]}"; do
        PARAMS+=("${BUILD_REPO}:${PACKAGES[$i]}")
    done
elif [ "$COMMAND" == "auto-repo-remove" ]; then
    # Prepend the source repo name to each package name and push to PARAMS
    PARAMS+=("${PACKAGES[@]}")
fi

if [ ! -f .ci/schedule-params.txt ]; then
    # Write necessary redis variables to file .ci/schedule-redis.txt
    for key in "REDIS_SSH_HOST" "REDIS_SSH_PORT" "REDIS_SSH_USER" "REDIS_PORT"; do
        declare -p "$key" >>.ci/schedule-params.txt
    done
fi

if [ "$COMMAND" == "auto-repo-remove" ]; then
    declare -a PARAMS_AUTOREPOREMOVE
    PARAMS_AUTOREPOREMOVE=("${PARAMS[@]}")
    declare -p PARAMS_AUTOREPOREMOVE >>.ci/schedule-params.txt
elif [ "$COMMAND" == "schedule" ]; then
    declare -a PARAMS_SCHEDULE
    PARAMS_SCHEDULE=("${PARAMS[@]}")
    declare -p PARAMS_SCHEDULE >>.ci/schedule-params.txt
fi
