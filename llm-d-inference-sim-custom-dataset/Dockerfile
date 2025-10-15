FROM quay.io/trustyai_testing/llm-d-inference-sim:latest
LABEL authors="scyril"

EXPOSE 8000

COPY --chown=65532:65532 ./build_artifacts /data
USER 65532:65532

ENTRYPOINT ["/app/llm-d-inference-sim", "--dataset-path", "data/db.sqlite", "--tokenizers-cache-dir", "/data/tokenizers_cache"]