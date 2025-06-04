#!/usr/bin/env bash

set -euo pipefail

# This script parses the parameters passed to this script and outputs a list of package names to a file

declare -a PACKAGES
COMMAND="$1"
shift

PACKAGES=("$@")

# shellcheck source=./util.shlib
source .ci/util.shlib
UTIL_READ_CONFIG_FILE

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

function generate_mirror_url() {
    set -euo pipefail
    local mirror=""

    if [ -v CI_LIB_DB ]; then
        # Handle quoted database URLs more robustly
        local db_list="$CI_LIB_DB"
        db_list="${db_list//\"/}"

        IFS=' ' read -r -a databases <<<"$db_list"
        local database=""

        for db in "${databases[@]}"; do
            [[ -z "$db" ]] && continue

            # Check for core, extra, or community databases
            if [[ "$db" == *"/core/os/"* ]] || [[ "$db" == *"/extra/os/"* ]] || [[ "$db" == *"/community/os/"* ]]; then
                database="$db"
                break
            fi
        done

        if [ -n "$database" ]; then
            # Transform database URL to pacman mirrorlist format
            # https://mirror.example.com/core/os/x86_64/core.db -> https://mirror.example.com/$repo/os/$arch
            # Extract base URL by removing /repo/os/arch/repo.db part
            local base_url="${database%/*/*/*/*}"
            mirror="$base_url/\$repo/os/\$arch"
            # Ensure clean output without any stray quotes or whitespace
            mirror="${mirror//\"/}"
            mirror="${mirror// /}"
            printf '%s' "$mirror"
        else
            UTIL_PRINT_WARNING "No valid database (core, extra, community) found in CI_LIB_DB."
        fi
    else
        UTIL_PRINT_WARNING "CI_LIB_DB is not set. Cannot generate mirror URL."
    fi
}

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
    # Write dep tree to file so it can be transferred as file.
    # This is necessary because the output of the function turned out too large for the command line.
    generate_deptree >.ci/deptree.txt

    arch_mirror=$(generate_mirror_url)
    if [[ -n "$arch_mirror" ]]; then
        UTIL_PRINT_INFO "Passing arch mirror: $arch_mirror"
        clean_mirror="${arch_mirror//\"/}"
        clean_mirror="${clean_mirror// /}"
        PARAMS+=("--arch-mirror=$clean_mirror")
    fi

    for package in "${PACKAGES[@]}"; do
        package="${package#"${package%%[![:space:]]*}"}"
        package="${package%"${package##*[![:space:]]}"}"

        [[ -z "$package" ]] && continue

        unset VARIABLES
        declare -A VARIABLES=()
        UTIL_READ_MANAGED_PACAKGE "$package" VARIABLES || true
        PACKAGE_PASSED_STRING="$package"
        # Append the build class (e.g. a package that requires a lot of compute resources will be class 2)
        if [ -v "VARIABLES[BUILDER_CLASS]" ]; then
            PACKAGE_PASSED_STRING+="/${VARIABLES[BUILDER_CLASS]}"
        elif [ "$CI_DEFAULT_CLASS" != "" ]; then
            PACKAGE_PASSED_STRING+="/${CI_DEFAULT_CLASS}"
        fi
        PARAMS+=("$PACKAGE_PASSED_STRING")
    done
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
