FROM registry.access.redhat.com/ubi9/ubi-minimal

LABEL maintainer="TrustAI Testing"

COPY --chmod=755 mc /usr/bin/mc

USER 1001

ENTRYPOINT ["/usr/bin/mc"]
