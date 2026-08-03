FROM registry.access.redhat.com/ubi9/ubi-minimal

LABEL \
    org.opencontainers.image.title="MinIO MC" \
    org.opencontainers.image.source="https://github.com/minio/mc" \
    org.opencontainers.image.vendor="TrustyAI"

COPY --chmod=755 mc /usr/bin/mc

USER 1001

ENTRYPOINT ["/usr/bin/mc"]
