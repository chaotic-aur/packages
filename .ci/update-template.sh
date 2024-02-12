#!/usr/bin/env bash
set -euo pipefail
set -x

# This script updates this repository with the latest changes from the template repository

CURRENT_REV="$(git rev-parse --abbrev-ref HEAD)"

git clone --depth=1 "$TEMPLATE_REPO" "$TMPDIR/template" -b "main"

trap "git reset --hard $CURRENT_REV" ERR

rsync -a --delete --include ".gitlab-ci.yml" \
    --exclude ".ci/config" \
    --include ".ci/***" \
    --include ".editorconfig" \
    --include ".envrc" \
    --include ".github" \
    --include ".github/workflows" \
    --include ".github/workflows/chaotic-on-commit.yml" \
    --include ".github/workflows/chaotic-on-schedule.yml" \
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
    git commit -m "chore(ci): Update CI from template [skip ci]"
    # Check if the scheduled tag does not exist or scheduled does not point to HEAD. In which case, the scheduled tag will not be pushed
    if ! [ "$(git tag -l "scheduled")" ] || [ "$(git rev-parse HEAD^)" != "$(git rev-parse scheduled)" ]; then
        git push --atomic origin HEAD:main
    else
        git tag -f scheduled
        git push --atomic origin HEAD:main +refs/tags/scheduled
    fi
    exit 0
fi

exit 1
