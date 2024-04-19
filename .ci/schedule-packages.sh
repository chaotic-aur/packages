#!/usr/bin/env bash

set -euo pipefail

# This script parses the parameters passed to this script and outputs a list of package names to a file

declare -a PACKAGES
COMMAND="$1"
shift

PACKAGES=("$@")

# shellcheck source=/dev/null
source .ci/util.shlib

if [ -v "PACKAGES[0]" ] && [ "${PACKAGES[0]}" == "all" ] && [ "$COMMAND" == "schedule" ]; then
    UTIL_PRINT_INFO "Rebuild of all packages requested."
    UTIL_GET_PACKAGES PACKAGES
fi

declare -a PARAMS
if [ "$COMMAND" == "auto-repo-remove" ]; then
    UTIL_GET_PACKAGES PACKAGES
    PARAMS+=("auto-repo-remove" "--target-repo=$REPO_NAME")
elif [ "$COMMAND" == "schedule" ]; then
    PARAMS+=("schedule" "--target-repo=$REPO_NAME" "--source-repo=$BUILD_REPO")
else
    UTIL_PRINT_ERROR "Unknown command: $COMMAND"
    exit 1
fi

# Check if the array of packages is empty
if [ ${#PACKAGES[@]} -eq 0 ]; then
    UTIL_PRINT_WARNING "No packages selected."
    exit 0
fi

# Check if running on gitlab
if [ -v GITLAB_CI ]; then
    PARAMS+=("--commit")
    PARAMS+=("${CI_COMMIT_SHA}:${CI_PIPELINE_ID}")
elif [ -v GITHUB_ACTIONS ]; then
    UTIL_PRINT_WARNING "Pipeline updates are not supported on GitHub Actions yet."
fi

function generate_deptree() {
    set -euo pipefail
    declare -a ALL_PACKAGES
    UTIL_GET_PACKAGES ALL_PACKAGES
    local deptree=""

    for i in "${ALL_PACKAGES[@]}"; do
        local PKGNAMES="" DEPS=""
        if [ -f "$i/.SRCINFO" ]; then
            local AWK_OUTPUT
            if ! AWK_OUTPUT=$(awk -f .ci/awk/get-deps.awk "$i/.SRCINFO"); then
                continue
            fi
            read -r PKGNAMES DEPS <<<"$AWK_OUTPUT"
        fi
        if [ -n "$deptree" ]; then
            deptree+=";"
        fi
        deptree+="$i:$PKGNAMES:$DEPS"
    done
    echo "$deptree"
}

if [ "$COMMAND" == "schedule" ]; then
    PARAMS+=("--deptree")
    PARAMS+=("$(generate_deptree)")
    PARAMS+=("${PACKAGES[@]}")
elif [ "$COMMAND" == "auto-repo-remove" ]; then
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
