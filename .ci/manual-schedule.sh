#!/usr/bin/env bash
set -euo pipefail

source .ci/util.shlib

# This script is used to manually trigger a build via pipeline UI
# PACKAGES is a ":" separated list of package names and needs
# to be supplied via pipeline variables

# Read config file into global variables
UTIL_READ_CONFIG_FILE

if [ "$PACKAGES" == "all" ]; then
    .ci/schedule-packages.sh schedule all
    exit 0
fi

declare -a FINAL=()
IFS=':' read -r -a FINAL <<<"$PACKAGES"
.ci/schedule-packages.sh schedule "${FINAL[@]}"
