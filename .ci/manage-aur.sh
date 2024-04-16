#!/usr/bin/env bash
# shellcheck disable=2153
set -euo pipefail

# This script is used to manage a packages corresponding AUR repo
# No point in running this script if we don't have keys available
# we are skipping debug output here to not leak the key
AUR_KEY_FILE="$TMPDIR/AUR_KEY"
set +x
if [[ -z ${AUR_KEY+x} ]]; then
    echo "No AUR SSH key available, backing off!"
    exit 1
else
    touch "$AUR_KEY_FILE"

    trap 'rm -f "$AUR_KEY_FILE"' EXIT ERR

    chmod 600 "$AUR_KEY_FILE"
    echo "$AUR_KEY" >"$AUR_KEY_FILE"
fi

set -x

declare -a PACKAGES
PACKAGES=("$@")

# CI-specific variables
if [ -v GITLAB_CI ]; then
    _CI_PIPELINE_URL="$CI_PIPELINE_URL"
    _CI_REPOSITORY_URL="${CI_SERVER_URL}/${CI_PROJECT_PATH}/-/commits/${CI_DEFAULT_BRANCH}"
elif [ -v GITHUB_ACTIONS ]; then
    _CI_PIPELINE_URL="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
    _CI_REPOSITORY_URL="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/commits/${GITHUB_REF}"
else
    echo "Warning: supplying pipeline/project details in commit messages is only supported on GitLab CI/GitHub Actions."
fi

# shellcheck source=/dev/null
source .ci/util.shlib
export GIT_SSH_COMMAND="-i \"$AUR_KEY_FILE\" ssh -o StrictHostKeyChecking=accept-new"

[[ -v "TMPDIR" ]] || TMPDIR="/tmp"
mkdir -p "$TMPDIR/aur-push"

if [ -v "PACKAGES[0]" ] && [ "${PACKAGES[0]}" == "all" ]; then
    echo "AUR push of all managed packages requested."
    UTIL_GET_PACKAGES PACKAGES
fi

# Check if the array of packages is empty
if [ ${#PACKAGES[@]} -eq 0 ]; then
    echo "No packages to push."
    exit 0
fi

for package in "${PACKAGES[@]}"; do
    unset VARIABLES
    declare -A VARIABLES
    if UTIL_READ_MANAGED_PACAKGE "$package" VARIABLES; then
        if [[ ! -v "VARIABLES[CI_MANAGE_AUR]" ]] || [[ "${VARIABLES[CI_MANAGE_AUR]}" != "true" ]]; then
            continue
        fi

        # Clone via SSH to allow pushing
        if ! test -d "$TMPDIR/aur-push/$package"; then
            git clone "ssh://aur@aur.archlinux.org/$package.git" "$TMPDIR/aur-push/$package"
        fi

        # We always run shfmt on the PKGBUILD. Two runs of shfmt on the same file should not change anything
        shfmt -w "$TMPDIR/aur-pulls/$package/PKGBUILD"

        # Rsync: delete files in the destination that are not in the source. Exclude copying .CI and .git            # shellcheck disable=SC2046
        rsync -a --delete "$(UTIL_GET_EXCLUDE_LIST "--exclude")" "$package/" "$TMPDIR/aur-pulls/$package/"

        # Only push if there are changes
        if ! git diff --exit-code --quiet; then
            git add .
            if [ -v _CI_COMMITS_URL ]; then
                git commit -m "chore: update $package" \
                    -m "This commit was automatically generated to reflect changes to this package in another repository." \
                    -m "The changelog for this package can be found at ${_CI_COMMITS_URL}." \
                    -m "Logs of the corresponding pipeline run can be found here: $_CI_PIPELINE_URL."
            else
                git commit -m "chore: update $package" \
                    -m "This commit was automatically generated to reflect changes to this package in another repository." \
                    -m "Unfortunately, due to a misconfiguration, the URL of the source repository is not available."
            fi
            git push
        else
            echo "No changes detected, skipping!"
            continue
        fi
    else
        continue
    fi
done
