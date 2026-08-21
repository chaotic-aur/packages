#!/usr/bin/env bash
set -euo pipefail

# $1: pkgbase
# $2: Assign to GitLab user id
# $3: Review source (optional, "nvchecker" or default)

# shellcheck source=./util.shlib
source .ci/util.shlib

if [ -z "${ACCESS_TOKEN:-}" ]; then
  UTIL_PRINT_ERROR "ACCESS_TOKEN is not set. Please set it to a valid access token to use human review or disable CI_HUMAN_REVIEW."
  exit 0
fi

# $1: pkgbase
# $2: branch
# $3: target branch
# $4: assign_to_id (optional)
function create_gitlab_pr() {
  local pkgbase="$1"
  local branch="$2"
  local target_branch="$3"
  local assign_to_id="${4:-}"  # Default to empty string if not provided

  # Taken from https://about.gitlab.com/2017/09/05/how-to-automatically-create-a-new-mr-on-gitlab-with-gitlab-ci/
  # Require a list of all the merge request and take a look if there is already
  # one with the same source branch
  local _COUNTBRANCHES _LISTMR _MR_EXISTS BODY
  if ! _LISTMR=$(curl --fail-with-body --silent "https://gitlab.com/api/v4/projects/${CI_PROJECT_ID}/merge_requests?state=opened&per_page=100" --header "PRIVATE-TOKEN:${ACCESS_TOKEN}"); then
    UTIL_PRINT_ERROR "$pkgbase: Failed to get list of merge requests."
    return
  fi

  _COUNTBRANCHES=$(grep -o "\"source_branch\":\"${branch}\"" <<<"${_LISTMR}" | wc -l || true)

  if [ "${_COUNTBRANCHES}" == "0" ]; then
    _MR_EXISTS=0
  else
    _MR_EXISTS=1
  fi

  # The description of our new MR, we want to remove the branch after the MR has
  # been closed.
  if [ -n "${assign_to_id}" ]; then
    BODY=$(jq -n \
      --arg project_id "$CI_PROJECT_ID" \
      --arg source_branch "$branch" \
      --arg target_branch "$target_branch" \
      --arg title "$PR_TITLE" \
      --arg description "$PR_DESCRIPTION" \
      --arg assignee_id "$assign_to_id" \
      --arg pr_labels "$PR_LABELS" \
      '{
        project_id: ($project_id | tonumber),
        source_branch: $source_branch,
        target_branch: $target_branch,
        remove_source_branch: true,
        force_remove_source_branch: false,
        allow_collaboration: true,
        subscribed: false,
        title: $title,
        description: $description,
        labels: $pr_labels,
        assignee_ids: [($assignee_id | tonumber)]
      }')
  else
    BODY=$(jq -n \
      --arg project_id "$CI_PROJECT_ID" \
      --arg source_branch "$branch" \
      --arg target_branch "$target_branch" \
      --arg title "$PR_TITLE" \
      --arg description "$PR_DESCRIPTION" \
      --arg pr_labels "$PR_LABELS" \
      '{
        project_id: ($project_id | tonumber),
        source_branch: $source_branch,
        target_branch: $target_branch,
        remove_source_branch: true,
        force_remove_source_branch: false,
        allow_collaboration: true,
        subscribed: false,
        title: $title,
        description: $description,
        labels: $pr_labels
      }')
  fi

  # No MR found, let's create a new one
  if [ "$_MR_EXISTS" == 0 ]; then
    if curl --fail-with-body -s -X POST "https://gitlab.com/api/v4/projects/${CI_PROJECT_ID}/merge_requests" \
      --header "PRIVATE-TOKEN:${ACCESS_TOKEN}" \
      --header "Content-Type: application/json" \
      --data "${BODY}" >/dev/null 2>&1; then
      UTIL_PRINT_INFO "$pkgbase: Created merge request."
    else
      UTIL_PRINT_ERROR "$pkgbase: Failed to create merge request."
    fi
  else
    UTIL_PRINT_INFO "$pkgbase: No new merge request opened due to an already existing MR."
  fi
}

# $1: pkgbase
# $2: branch
# $3: target branch
function create_github_pr() {
  local pkgbase="$1"
  local branch="$2"
  local target_branch="$3"

  # Taken from https://about.gitlab.com/2017/09/05/how-to-automatically-create-a-new-mr-on-gitlab-with-gitlab-ci/
  # Require a list of all the merge request and take a look if there is already
  # one with the same source branch
  local _COUNTBRANCHES _LISTMR _MR_EXISTS BODY
  if ! _LISTMR=$(curl --fail-with-body --silent "$GITHUB_API_URL/repos/$GITHUB_REPOSITORY/pulls?state=open&head=$GITHUB_REPOSITORY_OWNER:$branch" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    -H "Authorization: token ${ACCESS_TOKEN}"); then
    UTIL_PRINT_ERROR "$pkgbase: Failed to get list of pull requests."
    return
  fi

  _COUNTBRANCHES=$(jq length <<<"${_LISTMR}" || true)

  if [ "${_COUNTBRANCHES}" == "0" ]; then
    _MR_EXISTS=0
  else
    _MR_EXISTS=1
  fi

  # The description of our new PR, we want to allow maintainer modifications.
  BODY=$(jq -n \
    --arg head "$branch" \
    --arg base "$target_branch" \
    --arg title "$PR_TITLE" \
    --arg body "$PR_DESCRIPTION" \
    '{
      head: $head,
      base: $base,
      maintainer_can_modify: true,
      title: $title,
      body: $body
    }')

  # No MR found, let's create a new one
  if [ "$_MR_EXISTS" == 0 ]; then
    # PR doesn't exist, create a new one
    if curl --fail-with-body -s -X POST "$GITHUB_API_URL/repos/$GITHUB_REPOSITORY/pulls" \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      -H "Authorization: token ${ACCESS_TOKEN}" \
      --data "${BODY}" >/dev/null 2>&1; then
      UTIL_PRINT_INFO "$pkgbase: Created pull request."
    else
      UTIL_PRINT_ERROR "$pkgbase: Failed to create pull request."
    fi
  else
    UTIL_PRINT_INFO "$pkgbase: No new pull request opened due to an already existing MR."
  fi
}

# $1: branch
# $2: base ref the PR branch is built on
# $3: pkgbase
function manage_branch() {
  local branch="$1"
  local base_ref="$2"
  local pkgbase="$3"
  local tmpwork

  # Scope the stash to just this package: parallel Phase A leaves all other
  # packages' updates in the worktree, and a global stash would drop them here.
  git stash push -q -u -- "$pkgbase"

  # Do all branch work in an isolated worktree: switching branches in the main
  # worktree would refuse (or clobber) the other packages' pending changes.
  tmpwork="$(mktemp -d)"
  trap 'if [ -n "${tmpwork:-}" ]; then git worktree remove --force "$tmpwork" >/dev/null 2>&1 || true; rm -rf "$tmpwork"; fi' EXIT
  git worktree add --quiet --detach "$tmpwork" "$base_ref"
  (
    cd "$tmpwork" || exit 1
    # Restore tracked changes from the WIP commit, then untracked files
    # from the untracked commit (stash@{0}^3, created by -u).
    git checkout stash@{0} -- "$pkgbase"
    git checkout stash@{0}^3 -- "$pkgbase" 2>/dev/null || true
    git add "$pkgbase"
    # Skip when the branch already carries exactly these changes
    if ! git diff --staged --exit-code --quiet; then
      git commit -q -m "chore(update): $pkgbase"
	  
      if push_output=$(git push --quiet --force-with-lease origin "HEAD:refs/heads/$branch" 2>&1); then
        UTIL_PRINT_INFO "$pkgbase: Pushed branch $branch for review."
      else
        UTIL_PRINT_ERROR "$pkgbase: Failed to push branch $branch:\n$push_output"
        exit 1
      fi
    fi
  )
  git worktree remove --force "$tmpwork"
  rm -rf "$tmpwork"
  git stash drop -q
}
PKGBASE="$1"
REVIEW_SOURCE="${3:-regular}"

PR_TITLE="chore(update): $PKGBASE"
PR_DESCRIPTION="A recent update of this package requires human review! Please check whether any potentially dangerous changes were made."
PR_LABELS="ci,human-review,update"
if [ "$REVIEW_SOURCE" == "nvchecker" ]; then
  PR_TITLE="chore(update): $PKGBASE"
  PR_DESCRIPTION="This version update was generated by nvchecker and requires human review. Please verify upstream release changes and packaging impact."
  PR_LABELS="ci,human-review,update,nvchecker"
fi

ASSIGN_TO_ID="${CI_HUMAN_REVIEW_ASSIGNEE:-}"
ASSIGN_TO_ID="${ASSIGN_TO_ID%\"}"  # Remove trailing quote
ASSIGN_TO_ID="${ASSIGN_TO_ID#\"}"  # Remove leading quote

if [ -v CI_COMMIT_REF_NAME ]; then
  TARGET_BRANCH="$CI_COMMIT_REF_NAME"
elif [ -v GITHUB_REF_NAME ]; then
  TARGET_BRANCH="$GITHUB_REF_NAME"
else
  # Current branch name
  TARGET_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
fi

CHANGE_BRANCH="update-$PKGBASE"

manage_branch "$CHANGE_BRANCH" "origin/$TARGET_BRANCH" "$PKGBASE"

if [ -v GITLAB_CI ]; then
  create_gitlab_pr "$PKGBASE" "$CHANGE_BRANCH" "$TARGET_BRANCH" "${ASSIGN_TO_ID:-}"
elif [ -v GITHUB_ACTIONS ]; then
  create_github_pr "$PKGBASE" "$CHANGE_BRANCH" "$TARGET_BRANCH" "${ASSIGN_TO_ID:-}"
else
  UTIL_PRINT_WARNING "Pull request creation is only supported on GitLab CI/GitHub Actions. Please disable CI_HUMAN_REVIEW."
  exit 0
fi
