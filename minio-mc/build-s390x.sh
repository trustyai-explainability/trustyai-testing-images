#!/bin/bash

set -euo pipefail

echo "Building MinIO client for linux/s390x..."

WORKDIR=$(mktemp -d)
trap "rm -rf ${WORKDIR}" EXIT

git clone \
  --branch RELEASE.2025-08-13T08-35-41Z \
  --depth 1 \
  https://github.com/minio/mc.git "${WORKDIR}"

cd "${WORKDIR}"

CGO_ENABLED=0 \
GOOS=linux \
GOARCH=s390x \
go build -o mc

cp mc "$OLDPWD"

echo "s390x MinIO Client  binary created."
