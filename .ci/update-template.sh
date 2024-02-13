#!/usr/bin/env bash
set -euo pipefail
set -x

# This script updates this repository with the latest changes from the template repository

CURRENT_REV="$(git rev-parse --abbrev-ref HEAD)"

if [ -v GITLAB_CI ]; then
    CI_RSYNC_ARGS=("--include" ".gitlab-ci.yml")
    CI_COMMIT_MSG=("-m" "chore(ci): update CI from template")
    CI_PUSH_ARGS=("-o" "ci.skip")
elif [ -v GITHUB_ACTIONS ]; then
    CI_RSYNC_ARGS=("--include" ".github"
        "--include" ".github/workflows"
        "--include" ".github/workflows/chaotic-on-commit.yml"
        "--include" ".github/workflows/chaotic-on-schedule.yml")
    CI_COMMIT_MSG=("-m" "chore(ci): update CI from template [skip ci]")
fi

git clone --depth=1 "$TEMPLATE_REPO" "$TMPDIR/template" -b "main"

trap "git reset --hard $CURRENT_REV" ERR

# Generic template files
rsync -a --delete --exclude ".ci/config" \
    --include ".ci/***" \
    --include ".editorconfig" \
    --include ".envrc" \
    --include ".markdownlint.yaml" \
    --include ".prettierignore" \
    --include ".shellcheckrc" \
    --include ".yamllint" \
    --include "default.nix" \
    --include "flake.lock" \
    --include "flake.nix" \
    --include "shell.nix" \
    "${CI_RSYNC_ARGS[@]}" \
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

exit 1
