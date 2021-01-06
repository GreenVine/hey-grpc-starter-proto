#!/usr/bin/env bash

set -e

PROJECT_ROOT=${2:-$(pwd)}

PROTO_SRC_NAME='proto'
PROTO_EXT_NAME='proto_ext'
PROTO_TMP_NAME='.proto_ext.tmp'

PROTO_EXT_DIR="${PROJECT_ROOT}/${PROTO_EXT_NAME}"
PROTO_EXT_ABS=$(readlink -mn "${PROTO_EXT_DIR}")
PROTO_TMP_DIR="${PROJECT_ROOT}/${PROTO_TMP_NAME}"
DOCKER_IMAGE=${3:-heyproto-node-builder:local-build}

if [ ! -d "${PROJECT_ROOT}" ]; then
  echo 'Project root folder does not exist.'
  exit 2
fi

build_proto() {
  docker run --rm \
    -v "${PROJECT_ROOT}:/workspace" \
    "${DOCKER_IMAGE}" \
    generate proto --walk-timeout 10s
}

# Copy included vendor files to temporary folder
prepare_vendor_files() {
  rm -rf "${PROTO_TMP_DIR}"
  mkdir -p "${PROTO_TMP_DIR}/third_party/googleapis/google"/{api,rpc}
  mkdir -p "${PROTO_TMP_DIR}/third_party/validator/validate"

  # Copy only included files/folders from the vendor (proto_ext)
  while IFS='' read -r inc || [ -n "$inc" ]; do
    inc_formatted=${inc// }  # remove redundant spaces

    # skip empty lines or lines start with hashtag
    if [[ "${inc_formatted}" = \#* ]] || [[ -z "${inc_formatted}" ]]; then
      continue
    fi

    # skip files which are outside vendor folder
    inc_abs_path=$(readlink -mn "${PROTO_EXT_DIR}/${inc}")
    if ! [[ "${inc_abs_path}" =~ ^"${PROTO_EXT_ABS}/".* ]]; then
      echo "Included out-of-scope file: ${inc}"
      return 1
    fi

    # copy over file and folders, and abort on non-exist entry
    if [[ -d "${inc_abs_path}" ]]; then
      mkdir -p "${PROTO_TMP_DIR}/${inc}"
      cp -rfp "${inc_abs_path}" $(dirname "${PROTO_TMP_DIR}/${inc}")
    elif [[ -f "${inc_abs_path}" ]]; then
      mkdir -p $(dirname "${PROTO_TMP_DIR}/${inc}")
      cp -rfp "${inc_abs_path}" "${PROTO_TMP_DIR}/${inc}"
    else
      echo "Included file/folder does not exist: ${inc}"
      return 2
    fi
  done < "${PROTO_EXT_DIR}/INCLUDE"

  return 0
}

build_vendor_proto() {
  docker run --rm \
    -v "${PROJECT_ROOT}:/workspace" \
    "${DOCKER_IMAGE}" \
    generate "${PROTO_TMP_NAME}" --walk-timeout 10s
}

format_proto() {
  docker run --rm \
    -v "${PROJECT_ROOT}:/workspace" \
    "${DOCKER_IMAGE}" \
    format -w "${PROTO_SRC_NAME}" --walk-timeout 10s
}

lint_proto() {
  docker run --rm \
    -v "${PROJECT_ROOT}:/workspace" \
    "${DOCKER_IMAGE}" \
    lint "${PROTO_SRC_NAME}" --walk-timeout 10s
}

cleanup() {
  rm -rf "${PROTO_TMP_DIR}"
}


case $1 in
'build')
  echo 'Building Protobuf files...'
  build_proto

  prepare_vendor_files
  echo 'Building vendor Protobuf files...'
  build_vendor_proto

  cleanup
  ;;
'format')
  echo 'Formatting Protobuf files...'
  format_proto
  ;;
'lint')
  echo 'Linting Protobuf files...'
  lint_proto
  ;;
'clean')
  cleanup
  ;;
*)
  echo "Unrecognised command '${command}'. Valid choices are: build, clean, format, lint"
  exit 1
  ;;
esac
