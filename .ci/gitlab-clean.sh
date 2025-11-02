#!/usr/bin/env bash

# The purpose of this script is to clean up old gitlab CI artifacts, including job logs. These grow linearly over time until the repository runs out of space.

set -euo pipefail

# shellcheck source=./util.shlib
source .ci/util.shlib

# No access token, no cleaning
if [ -z "${ACCESS_TOKEN:-}" ]; then
  exit 0
fi

# Function to fetch artifacts with pagination
fetch_old_artifacts() {
  local all_artifacts=()
  local has_next_page=true
  local cursor=""
  local page_size=100
  local retry_count=0
  local max_retries=3
  local delay=1
  local page_count=0
  local max_pages=50

  while [ "$has_next_page" = true ] && [ $page_count -lt $max_pages ]; do
    page_count=$((page_count + 1))
    local query_variables
    if [ -z "$cursor" ]; then
      query_variables="{
                \"projectPath\": \"${CI_PROJECT_NAMESPACE}/${CI_PROJECT_NAME}\",
                \"first\": $page_size,
                \"after\": null
            }"
    else
      query_variables="{
                \"projectPath\": \"${CI_PROJECT_NAMESPACE}/${CI_PROJECT_NAME}\",
                \"first\": $page_size,
                \"after\": \"$cursor\"
            }"
    fi

    local response
    local curl_exit_code

    # Retry loop for handling timeouts
    while [ $retry_count -le $max_retries ]; do
      response="$(curl --silent --fail-with-body --max-time 30 "https://$CI_SERVER_HOST/api/graphql" --header "PRIVATE-TOKEN: ${ACCESS_TOKEN}" \
        --header "Content-Type: application/json" --request POST \
        --data "{
                    \"operationName\": \"getJobArtifacts\",
                    \"query\": \"query getJobArtifacts(\\\$projectPath: ID!, \\\$first: Int, \\\$after: String) { project(fullPath: \\\$projectPath) { jobs(withArtifacts: true, first: \\\$first, after: \\\$after) { pageInfo { hasNextPage endCursor } nodes { finishedAt, artifacts { nodes { id } } } } } }\",
                    \"variables\": $query_variables
                }" 2>&1)"
      curl_exit_code=$?

      if [ $curl_exit_code -eq 0 ]; then
        break
      elif [ $curl_exit_code -eq 22 ] && echo "$response" | grep -q "Request timed out"; then
        retry_count=$((retry_count + 1))
        if [ $retry_count -le $max_retries ]; then
          UTIL_PRINT_WARNING "Request timed out, retrying in ${delay}s (attempt $retry_count/$max_retries)..."
          sleep $delay
          delay=$((delay * 2)) # Exponential backoff
          continue
        fi
      fi
      break
    done

    # Reset retry count for next request
    retry_count=0
    delay=1

    if [ $curl_exit_code -ne 0 ]; then
      UTIL_PRINT_ERROR "Failed to fetch artifacts from GitLab API after $max_retries retries (curl exit code: $curl_exit_code)"
      if [ -n "$response" ]; then
        UTIL_PRINT_ERROR "Response: $response"
      fi
      return 1
    fi

    # Check for GraphQL errors in response
    if echo "$response" | jq -e '.errors' >/dev/null 2>&1; then
      local errors
      errors=$(echo "$response" | jq -r '.errors[].message' 2>/dev/null || echo "Unknown GraphQL error")
      UTIL_PRINT_ERROR "GraphQL API returned errors: $errors"
      UTIL_PRINT_ERROR "Full response: $response"
      return 1
    fi

    # Check if project exists
    if ! echo "$response" | jq -e '.data.project' >/dev/null 2>&1; then
      UTIL_PRINT_ERROR "Project not found or inaccessible: ${CI_PROJECT_NAMESPACE}/${CI_PROJECT_NAME}"
      return 1
    fi

    # Extract artifacts from current page
    local page_artifacts
    if page_artifacts="$(echo "$response" | jq -r '[.data.project.jobs.nodes[]? | select(.finishedAt and (.finishedAt | fromdate < (now - 604800))) | .artifacts.nodes[]?.id] | select(. != [] and . != null) | .[]?' 2>/dev/null)"; then
      if [ -n "$page_artifacts" ]; then
        all_artifacts+=($page_artifacts)
      fi
    fi

    # Check if there are more pages
    has_next_page=$(echo "$response" | jq -r '.data.project.jobs.pageInfo.hasNextPage // false')
    cursor=$(echo "$response" | jq -r '.data.project.jobs.pageInfo.endCursor // ""')

    if [ "$has_next_page" != "true" ] || [ -z "$cursor" ] || [ "$cursor" = "null" ]; then
      has_next_page=false
    fi

    # Progress indicator - send to stderr so it's not captured by command substitution
    printf "." >&2

    # Show progress every 20 pages
    if [ $((page_count % 20)) -eq 0 ]; then
      printf " [%d artifacts found so far]\n" "${#all_artifacts[@]}" >&2
    fi

    if [ ${#all_artifacts[@]} -ge 100 ]; then
      UTIL_PRINT_INFO "Found 100 or more artifacts to delete. Stopping search." >&2
      all_artifacts=("${all_artifacts[@]:0:100}") # Trim array to exactly 100
      break
    fi

    # Small delay between requests to avoid overwhelming the API
    if [ "$has_next_page" = "true" ]; then
      sleep 0.5
    fi
  done

  # Add newline after progress dots
  printf "\n" >&2

  # Warn if we hit the page limit
  if [ $page_count -ge $max_pages ] && [ ${#all_artifacts[@]} -lt 100 ]; then
    UTIL_PRINT_WARNING "Reached maximum page limit ($max_pages). Some artifacts may not have been processed."
  fi

  if [ ${#all_artifacts[@]} -eq 0 ]; then
    return 1
  fi

  # Output as JSON array
  printf '%s\n' "${all_artifacts[@]}" | jq -R . | jq -s .
}

UTIL_PRINT_INFO "Fetching old artifacts..."
if ! ARTIFACTS="$(fetch_old_artifacts)"; then
  UTIL_PRINT_WARNING "No old artifacts found, project inaccessible, or an error occurred while fetching artifacts."
  UTIL_PRINT_INFO "Project path: ${CI_PROJECT_NAMESPACE}/${CI_PROJECT_NAME}"
  exit 0
fi
UTIL_PRINT_INFO "Found $(echo "$ARTIFACTS" | jq length) old artifacts to delete."

PROJECT_ID="gid://gitlab/Project/${CI_PROJECT_ID}"
BASE_DELETE_REQUEST='{
    "operationName": "bulkDestroyJobArtifacts",
    "query": "mutation bulkDestroyJobArtifacts($projectId: ProjectID!, $ids: [CiJobArtifactID!]!) { bulkDestroyJobArtifacts(input: {projectId: $projectId, ids: $ids}) { destroyedCount destroyedIds } }",
    "variables": { }
}'

if ! BODY="$(jq --argjson ids "$ARTIFACTS" --arg project "$PROJECT_ID" '.variables.ids = $ids | .variables.projectId = $project' <<<"$BASE_DELETE_REQUEST")"; then
  UTIL_PRINT_ERROR "Failed to prepare deletion request body"
  exit 1
fi

UTIL_PRINT_INFO "Deleting $(echo "$ARTIFACTS" | jq length) old artifacts..."

delete_response="$(curl --fail --silent --show-error "https://$CI_SERVER_HOST/api/graphql" --header "PRIVATE-TOKEN: ${ACCESS_TOKEN}" \
  --header "Content-Type: application/json" --request POST \
  --data "$BODY" 2>&1)"
curl_exit_code=$?

if [ $curl_exit_code -eq 0 ]; then
  # Check for GraphQL errors in deletion response
  if echo "$delete_response" | jq -e '.errors' >/dev/null 2>&1; then
    delete_errors=$(echo "$delete_response" | jq -r '.errors[].message' 2>/dev/null || echo "Unknown GraphQL error")
    UTIL_PRINT_ERROR "Failed to delete artifacts: $delete_errors"
    exit 1
  fi

  if [ "$(echo "$delete_response" | jq -r '.data.bulkDestroyJobArtifacts.errors | length')" -gt 0 ]; then
    delete_errors=$(echo "$delete_response" | jq -r '.data.bulkDestroyJobArtifacts.errors[]' 2>/dev/null || echo "Unknown GraphQL error")
    UTIL_PRINT_ERROR "Failed to delete artifacts: $delete_errors"
    exit 1
  fi

  # Extract deletion count if available
  deleted_count=$(echo "$delete_response" | jq -r '.data.bulkDestroyJobArtifacts.destroyedCount // 0' 2>/dev/null)
  if [ "$deleted_count" != "0" ] && [ "$deleted_count" != "null" ]; then
    UTIL_PRINT_INFO "Successfully deleted $deleted_count artifacts."
  else
    # Fallback to the number we attempted to delete
    attempted_count=$(echo "$ARTIFACTS" | jq length)
    UTIL_PRINT_INFO "Successfully submitted deletion request for $attempted_count artifacts."
  fi
else
  UTIL_PRINT_ERROR "Failed to delete artifacts (curl exit code: $curl_exit_code)"
  if [ -n "$delete_response" ]; then
    UTIL_PRINT_ERROR "Response: $delete_response"
  fi
  exit 1
fi
