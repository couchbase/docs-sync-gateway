#!/bin/sh

set -exuo pipefail

GIT_ROOT=$(git rev-parse --show-toplevel)
cd "${GIT_ROOT}"

# Get docs tag name from current major.minor version
yq -V || brew install yq
tag=$(yq -r .version antora.yml)-docs

# Get upstream sync_gateway repo
git clone --no-checkout https://github.com/couchbase/sync_gateway.git
cd sync_gateway
git sparse-checkout init --cone
git sparse-checkout set docs/api
# check & delete local tag in case remote tag has been moved
has_tag=$(git tag -l ${tag})
if [[ -n ${has_tag} ]]; then
    git tag -d ${tag}
fi
# update remote tags after deleting local ones
git fetch --tags
git reset --hard ${tag}
cd ..

PATH_TO_SYNC_GATEWAY="${GIT_ROOT}/sync_gateway"
PATH_TO_REDOCLY="${GIT_ROOT}/redocly"

PATH_TO_ASSETS="${GIT_ROOT}/modules/rest-api/attachments"
PATH_TO_PARTIALS="${GIT_ROOT}/modules/rest-api/partials"
PATH_TO_TEMP="${GIT_ROOT}/modules/rest-api/bld"
PATH_TO_STATIC="${GIT_ROOT}/modules/ROOT/partials/static_restapi"
PATH_TO_METRICS="${GIT_ROOT}/modules/manage/partials"

# Create a bld directory to hold temporary files, if it doesn't already exist
[[ -d "${PATH_TO_TEMP}" ]] || mkdir "${PATH_TO_TEMP}"

# Use jq to transform the Prometheus metrics file into JSON schema.
# Temporarily omitting the description until we can sort out Redocly CSS issues.
# Should be {"type": "integer", "format": .value.type, "description": .value.help}
npx node-jq 'to_entries |
map(.value += {"type": "integer", "format": .value.type}) |
map(.value |= del(.added, .labels, .unit, .stability, .help)) |
from_entries |
{type: "object", properties: .}' \
  "${PATH_TO_METRICS}/metrics_metadata.json" \
 > "${PATH_TO_ASSETS}/metrics_metadata.json"

generate() {
    WHAT=$1

    # this bundle may be needed for the database configuration part?
    npx '@redocly/cli' bundle \
        --config "${PATH_TO_SYNC_GATEWAY}/.redocly.yaml" \
        "${WHAT}" \
        --dereferenced \
        --output "${PATH_TO_TEMP}/${WHAT}.bundle.yaml"

    # Get the bundled spec, apply the OpenAPI overlay,
    # and output to the attachments folder.
    npx openapi-overlays-js \
        --openapi "${PATH_TO_TEMP}/${WHAT}.bundle.yaml" \
        --overlay "${PATH_TO_ASSETS}/_${WHAT}.overlay.yaml" \
        > "${PATH_TO_ASSETS}/${WHAT}.overlaid.yaml"

    # Build the reference documentation using the overlaid spec.
    npx @redocly/cli \
      build-docs \
      --config "${PATH_TO_REDOCLY}/theme.yaml" \
      "${PATH_TO_ASSETS}/${WHAT}.overlaid.yaml" \
      --output "${PATH_TO_PARTIALS}/sgw-openapi-$WHAT.html" \
      --template "${PATH_TO_PARTIALS}/redocAll.hbs"

    # Build the static output using the overlaid spec.
    npx @openapitools/openapi-generator-cli generate \
        --skip-validate-spec \
        --generator-name asciidoc  \
        --input-spec "${PATH_TO_ASSETS}/${WHAT}.overlaid.yaml" \
        --template-dir "${PATH_TO_STATIC}/templates" \
        --additional-properties skipExamples=true \
        --output "${PATH_TO_STATIC}/${WHAT}"
}

generate public
generate admin
generate metric

# Clear upstream repo
rm -rf "${PATH_TO_SYNC_GATEWAY}"