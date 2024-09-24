#!/usr/bin/env bash

# The purpose of this script is to clean up old gitlab CI artifacts, including job logs. These grow linearly over time until the repository runs out of space.

set -euo pipefail

# No access token, no cleaning
if [ -z "${ACCESS_TOKEN:-}" ]; then
    exit 0
fi

if ! ARTIFACTS="$(curl --silent --fail-with-body "https://$CI_SERVER_HOST/api/graphql" --header "PRIVATE-TOKEN: ${ACCESS_TOKEN}" \
     --header "Content-Type: application/json" --request POST \
     --data "{
	\"operationName\": \"getJobArtifacts\",
	\"query\": \"query getJobArtifacts(\$projectPath: ID\!, \$first: Int, \$last: Int, \$after: String, \$before: String) { project(fullPath: \$projectPath) { jobs(withArtifacts: true, first: \$first, last: \$last, after: \$after, before: \$before) { nodes { finishedAt, artifacts { nodes { id } } } } } }\",
    \"variables\": {
        \"projectPath\": \"${CI_PROJECT_NAMESPACE}/${CI_PROJECT_NAME}\",
        \"first\": null,
        \"last\": 100,
        \"after\": \"\",
        \"before\": \"\"
    }
}" | jq -e '[.data.project.jobs.nodes[] | select(.finishedAt | fromdate < (now - 604800)).artifacts.nodes[].id] | select(. != [])')"; then
    exit 0
fi

PROJECT_ID="gid://gitlab/Project/${CI_PROJECT_ID}"
BASE_DELETE_REQUEST='{
    "operationName": "bulkDestroyJobArtifacts",
    "query": "mutation bulkDestroyJobArtifacts($projectId: ProjectID!, $ids: [CiJobArtifactID!]!) { bulkDestroyJobArtifacts(input: {projectId: $projectId, ids: $ids}) { destroyedCount destroyedIds } }",
    "variables": { }
}'

if ! BODY="$(jq --argjson ids "$ARTIFACTS" --arg project "$PROJECT_ID" '.variables.ids = $ids | .variables.projectId = $project' <<<"$BASE_DELETE_REQUEST")"; then
    exit 0
fi

if curl --fail --silent -o /dev/null "https://$CI_SERVER_HOST/api/graphql" --header "PRIVATE-TOKEN: ${ACCESS_TOKEN}" \
     --header "Content-Type: application/json" --request POST \
     --data "$BODY"; then
    echo -e "\nSuccessfully deleted old artifacts."
    exit 0
fi