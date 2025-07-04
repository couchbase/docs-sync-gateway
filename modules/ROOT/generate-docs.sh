#!/bin/sh

set -exuo pipefail

cd $(dirname "${BASH_SOURCE[0]}")

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

PATH_TO_BUNDLE="${GIT_ROOT}/modules/ROOT/assets/attachments"
PATH_TO_STATIC="${GIT_ROOT}/modules/ROOT/pages/_partials/static_restapi"

cd modules/ROOT

generate() {
    WHAT=$1

    # Build the bundled spec using Redocly CLI.
    npx '@redocly/cli' bundle \
        --config "${PATH_TO_SYNC_GATEWAY}/.redocly.yaml" \
        "${WHAT}" \
        --dereferenced \
        --output "${PATH_TO_BUNDLE}/bundled-${WHAT}.yaml"

    # Build the static output using the bundled spec.
    npx @openapitools/openapi-generator-cli generate \
        --skip-validate-spec \
        --generator-name asciidoc  \
        --input-spec "${PATH_TO_BUNDLE}/bundled-${WHAT}.yaml" \
        --template-dir "${PATH_TO_STATIC}/templates" \
        --additional-properties skipExamples=true \
        --additional-properties useTableTitles=true \
        --output "${PATH_TO_STATIC}/${WHAT}"
}

generate public
generate admin
generate metric

# Clear upstream repo
rm -rf "${PATH_TO_SYNC_GATEWAY}"