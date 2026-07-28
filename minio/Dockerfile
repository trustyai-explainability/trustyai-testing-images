FROM registry.access.redhat.com/ubi9/ubi-minimal

LABEL maintainer="TrustAI Testing"

COPY --chmod=755 minio /usr/bin/minio

USER 1001

ENTRYPOINT ["/usr/bin/minio"]
