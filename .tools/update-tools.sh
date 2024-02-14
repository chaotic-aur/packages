#!/usr/bin/env bash
set -euo pipefail
set -x

# This script updates this repository with the latest changes from the tools repository
# these are opinionated configs that not every user might want to use

CURRENT_REV="$(git rev-parse --abbrev-ref HEAD)"
TMPDIR="/tmp"
TOOLS_REPO="https://gitlab.com/chaotic-aur/repo-common.git"

# shellcheck source=/dev/null
source .ci/config

git config --global user.name "$GIT_AUTHOR_NAME"
git config --global user.email "$GIT_AUTHOR_EMAIL"
git checkout main
git pull --rebase

if [ -v GITLAB_CI ]; then
    CI_COMMIT_MSG=("-m" "chore(ci): update tools from commons")
    CI_PUSH_ARGS=("-o" "ci.skip")
elif [ -v GITHUB_ACTIONS ]; then
    CI_COMMIT_MSG=("-m" "chore(ci): update tools from commons [skip ci]")
fi

git clone --depth=1 "$TOOLS_REPO" "$TMPDIR/template" -b "main"

trap "git reset --hard $CURRENT_REV" ERR

rsync -a --verbose --delete --include ".tools/update-tools.sh" \
    --include ".cz.yaml" \
    --include ".editorconfig" \
    --include ".envrc" \
    --include ".gitignore" \
    --include ".gitlab-ci-sync-tools.yml" \
    --include ".markdownlint.yaml" \
    --include ".prettierignore" \
    --include ".shellcheckrc" \
    --include ".yamllint" \
    --include "default.nix" \
    --include "flake.lock" \
    --include "flake.nix" \
    --include "shell.nix" \
    --exclude "*" \
    "$TMPDIR/template/" .

if ! git diff --exit-code --quiet; then
    git add .
    git commit "${CI_COMMIT_MSG[@]}"
    # Check if the scheduled tag does not exist or scheduled does not point to HEAD. In which case, the scheduled tag will not be pushed
    if ! [ "$(git tag -l "scheduled")" ] || [ "$(git rev-parse HEAD^)" != "$(git rev-parse scheduled)" ]; then
        git push --atomic origin HEAD:main "${CI_PUSH_ARGS[@]}"
    else
        git tag -f scheduled
        git push --atomic origin HEAD:main +refs/tags/scheduled "${CI_PUSH_ARGS[@]}"
    fi
    exit 0
fi