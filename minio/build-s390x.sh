#!/bin/bash

set -euo pipefail

echo "Building MinIO for linux/s390x..."

WORKDIR=$(mktemp -d)
trap "rm -rf ${WORKDIR}" EXIT

git clone \
  --branch RELEASE.2024-10-29T16-01-48Z \
  --depth 1 \
  https://github.com/minio/minio.git "${WORKDIR}"

cd "${WORKDIR}"

CGO_ENABLED=0 \
GOOS=linux \
GOARCH=s390x \
go build -o minio

cp minio "$OLDPWD"

echo "s390x MinIO binary created."
