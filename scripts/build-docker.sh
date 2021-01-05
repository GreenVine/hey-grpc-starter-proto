#!/usr/bin/env bash

set -e

PROJECT_ROOT=${1:-$(pwd)}
DOCKERFILE_DIR="${PROJECT_ROOT}/docker"

if [ ! -d "${DOCKERFILE_DIR}" ]; then
  echo 'Expecting `docker` folder under the project root.'
  exit 1
fi

echo 'Building base image: heyproto-base...'
docker build -f "${DOCKERFILE_DIR}/base.Dockerfile" \
  -t heyproto-base:local-build \
  "${DOCKERFILE_DIR}"

echo 'Building Node.js builder: heyproto-node-builder...'
docker build -f "${DOCKERFILE_DIR}/node-builder.Dockerfile" \
  --build-arg BASE_IMAGE=heyproto-base:local-build \
  -t heyproto-node-builder:local-build \
  "${DOCKERFILE_DIR}"
