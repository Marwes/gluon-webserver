#!/bin/bash
set -eux

USE_CACHE=${1:-}
if [ "$USE_CACHE" == 'cache' ];
then
    EXTRA_BUILD_ARGS=(--network host --build-arg=RUSTC_WRAPPER=./sccache)
else
    EXTRA_BUILD_ARGS=()
fi

docker build \
    ${EXTRA_BUILD_ARGS[@]+"${EXTRA_BUILD_ARGS[@]}"} \
    --pull \
    --target dependencies \
    --tag marwes/try_gluon:dependencies \
    --cache-from marwes/try_gluon:dependencies \
    .

if [ -n "${REGISTRY_PASS:-}" ]; then
    docker push marwes/try_gluon:dependencies
fi

docker build \
    ${EXTRA_BUILD_ARGS[@]+"${EXTRA_BUILD_ARGS[@]}"} \
    --pull \
    --target builder \
    --tag marwes/try_gluon:builder \
    --cache-from marwes/try_gluon:builder \
    --cache-from marwes/try_gluon:dependencies \
    .

if [ -n "${REGISTRY_PASS:-}" ]; then
    docker push marwes/try_gluon:builder
fi

docker build \
    ${EXTRA_BUILD_ARGS[@]+"${EXTRA_BUILD_ARGS[@]}"} \
    --pull \
    --tag marwes/try_gluon \
    --cache-from marwes/try_gluon \
    --cache-from marwes/try_gluon:builder \
    --cache-from marwes/try_gluon:dependencies \
    .

if [ -z ${BUILD_ONLY:-} ]; then
    docker run \
        --init \
        -it \
        --env=RUST_BACKTRACE \
        marwes/try_gluon:builder \
        cargo test --release
fi
