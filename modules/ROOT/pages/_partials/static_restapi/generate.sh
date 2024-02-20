#!/bin/sh

set -exuo pipefail

cd $(dirname $0)

GIT_ROOT=$(git rev-parse --show-toplevel)

PATH_TO_SYNC_GATEWAY=${PATH_TO_SYNC_GATEWAY:-${GIT_ROOT}/../sync_gateway/}
PATH_TO_SPECS="${PATH_TO_SYNC_GATEWAY}/docs/api/"

PATH_TO_BUNDLE=${PATH_TO_BUNDLE:-${GIT_ROOT}/modules/ROOT/assets/attachments/}

generate() {
    SPEC=$1

    cd ${PATH_TO_SYNC_GATEWAY}

    redocly bundle \
        ${SPEC} \
        --dereferenced \
        --output "${PATH_TO_BUNDLE}/bundled-${SPEC}.yaml"

    cd $(dirname $0)

    openapi-generator generate \
        --generator-name asciidoc  \
        --input-spec "${PATH_TO_BUNDLE}/bundled-${SPEC}.yaml" \
        --template-dir override/asciidoc \
        --output $SPEC
}

generate public
generate admin
generate metric
