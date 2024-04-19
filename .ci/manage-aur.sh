#!/usr/bin/env bash
# shellcheck disable=2153
set -euo pipefail

# shellcheck source=/dev/null
source .ci/util.shlib

# Set up required environment
[[ -v "TMPDIR" ]] || TMPDIR="/tmp"
mkdir -p "$TMPDIR/aur-push"

git config --global user.name "$GIT_AUTHOR_NAME"
git config --global user.email "$GIT_AUTHOR_EMAIL"

# This script is used to manage a packages corresponding AUR repo
# No point in running this script if we don't have keys available
# we are skipping debug output here to not leak the key
AUR_KEY_FILE="$TMPDIR/AUR_KEY"
set +x
if [[ -z ${AUR_KEY+x} ]]; then
    UTIL_PRINT_ERROR "No AUR SSH key available, backing off!"
    exit 0
else
    touch "$AUR_KEY_FILE"

    trap 'rm -f "$AUR_KEY_FILE"' EXIT ERR

    chmod 600 "$AUR_KEY_FILE"
    echo "$AUR_KEY" >"$AUR_KEY_FILE"
fi

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
    UTIL_PRINT_WARNING "Supplying pipeline/project details in commit messages is only supported on GitLab CI/GitHub Actions."
fi

export GIT_SSH_COMMAND="ssh -i $AUR_KEY_FILE -o StrictHostKeyChecking=accept-new"

if [ -v "PACKAGES[0]" ] && [ "${PACKAGES[0]}" == "all" ]; then
    UTIL_PRINT_INFO "AUR push of all managed packages requested."
    UTIL_GET_PACKAGES PACKAGES
fi

# Check if the array of packages is empty
if [ ${#PACKAGES[@]} -eq 0 ]; then
    UTIL_PRINT_INFO "No packages to push."
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
            git clone -q "ssh://aur@aur.archlinux.org/$package.git" "$TMPDIR/aur-push/$package"
        fi

        # We always run shfmt on the PKGBUILD. Two runs of shfmt on the same file should not change anything
        if [ -f "$TMPDIR/aur-push/$package/.editorconfig" ]; then
            cp "./.editorconfig" "$TMPDIR/aur-push/$package/.editorconfig"
        fi
        shfmt -w "$TMPDIR/aur-push/$package/PKGBUILD"

        # Rsync: delete files in the destination that are not in the source. Exclude copying .CI and .git
        # shellcheck disable=SC2046
        rsync -av --delete $(UTIL_GET_EXCLUDE_LIST "--exclude") "$package/" "$TMPDIR/aur-push/$package/"

        # Only push if there are changes
        pushd "$TMPDIR/aur-push/$package"
        if [[ -n $(git status -uno --porcelain) ]]; then
            git add .
            if [ -v _CI_REPOSITORY_URL ]; then
                git commit -q -m "chore: update $package" \
                    -m "This commit was automatically generated to reflect changes to this package in another repository." \
                    -m "The changelog for this package can be found at ${_CI_REPOSITORY_URL}/$package." \
                    -m "Logs of the corresponding pipeline run can be found here: $_CI_PIPELINE_URL."
            else
                git commit -q -m "chore: update $package" \
                    -m "This commit was automatically generated to reflect changes to this package in another repository." \
                    -m "Unfortunately, due to a misconfiguration, the URL of the source repository is not available."
            fi
            git push
        else
            UTIL_PRINT_INFO "No changes detected, skipping!"
            continue
        fi
        popd
    else
        continue
    fi
done
