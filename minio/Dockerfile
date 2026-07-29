FROM registry.access.redhat.com/ubi9/ubi-minimal

LABEL \
    org.opencontainers.image.title="MinIO" \
    org.opencontainers.image.source="https://github.com/minio/minio" \
    org.opencontainers.image.vendor="TrustyAI"

COPY --chmod=755 minio /usr/bin/minio

USER 1001

ENTRYPOINT ["/usr/bin/minio"]
