#!/usr/bin/env bash
set -euo pipefail
set -x

source .ci/util.shlib

# This script is used to manually trigger a build via pipeline UI
# CI_MANUAL_BUILD is a ":" separated list of package names and needs
# to be supplied via pipeline variables

# Read config file into global variables
UTIL_READ_CONFIG_FILE

if [ "$CI_MANUAL_BUILD" == "all" ]; then
    .ci/schedule-packages.sh schedule all
    exit 0
fi

IFS=':' read -r -a PACKAGES <<<"$CI_MANUAL_BUILD"
.ci/schedule-packages.sh schedule "${PACKAGES[@]}"
