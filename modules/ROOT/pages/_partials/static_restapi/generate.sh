#!/bin/sh

set -exuo pipefail

cd $(dirname $0)

GIT_ROOT=$(git rev-parse --show-toplevel)

PATH_TO_SYNC_GATEWAY=${PATH_TO_SYNC_GATEWAY:-${GIT_ROOT}/../sync_gateway/}
PATH_TO_SPECS="${PATH_TO_SYNC_GATEWAY}/docs/api/"

generate() {
    SPEC=$1
    openapi-generator generate \
        --generator-name asciidoc  \
        --input-spec "${PATH_TO_SPECS}/${SPEC}.yaml" \
        --template-dir override/asciidoc \
        --output $SPEC
        # --generate-alias-as-model \
}

generate public
generate admin
generate metric
