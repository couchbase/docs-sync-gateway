#!/bin/sh

set -exuo pipefail

cd $(dirname $0)

GIT_ROOT=$(git rev-parse --show-toplevel)

PATH_TO_SYNC_GATEWAY=${PATH_TO_SYNC_GATEWAY:-${GIT_ROOT}/../sync_gateway/}
PATH_TO_SPECS="${PATH_TO_SYNC_GATEWAY}/docs/api/"

PATH_TO_BUNDLE=${PATH_TO_BUNDLE:-${GIT_ROOT}/modules/ROOT/assets/attachments/}

generate() {
    WHAT=$1

    # this bundle may be needed for the database configuration part?
    npx '@redocly/cli' bundle \
        --config "${PATH_TO_SYNC_GATEWAY}/.redocly.yaml" \
        "${PATH_TO_SYNC_GATEWAY}/docs/api/${WHAT}.yaml" \
        --dereferenced \
        --output "${PATH_TO_BUNDLE}/bundled-${WHAT}.yaml"

    npx @redocly/cli \
      build-docs \
      --config redocly.yaml \
      "${PATH_TO_SYNC_GATEWAY}/docs/api/${WHAT}.yaml" \
      --output partials/sgw-openapi-$WHAT.html \
      --template partials/redocAll.hbs
}

generate public
generate admin
generate metric
