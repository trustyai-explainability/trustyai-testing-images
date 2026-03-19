FROM quay.io/redhat-ai-services/huggingface-modelcar-builder:latest AS base

# The model repo to download
ENV MODEL_REPO="microsoft/Phi-4-mini-instruct"

# Download the necessary model files
RUN python3 download_model.py --model-repo ${MODEL_REPO}

# Final image containing only the essential model files
FROM registry.access.redhat.com/ubi9/ubi-micro:9.6

COPY --from=base /models /models

USER 1001
