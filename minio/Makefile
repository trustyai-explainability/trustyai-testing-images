# MinIO Makefile

ENGINE ?= docker

# Passed from top-level Makefile
PUSH_TAG ?=

# Temporary local image
LOCAL_IMAGE := minio-s390x:local

# Upstream architecture-specific images
AMD64_IMAGE   := docker://quay.io/minio/minio@sha256:a1a8bd4ac40ad7881a245bab97323e18f971e4d4cba2c2007ec1bedd21cbaba2
ARM64_IMAGE   := docker://quay.io/minio/minio@sha256:9966a92a734f9411e32f4f41d7d9d826fcdc0f68c4e20b70295bd4e7c11f8a2f
PPC64LE_IMAGE := docker://quay.io/minio/minio@sha256:4a9aa577940a788932fbee555cb67d136187d57697864814414d2ac4ffe3aa47

.PHONY: all
all: build

#
# Entry point called from top-level Makefile
#
.PHONY: build
build:
ifeq ($(strip $(PUSH_TAG)),)
	@echo "Building MinIO locally (no push)..."
	$(MAKE) binary image
else
	@echo "Building and publishing MinIO..."
	$(MAKE) release
endif

#
# Build MinIO binary
#
.PHONY: binary
binary:
	@echo "Building MinIO s390x binary..."
	@test -x build-s390x.sh || { \
		echo "Error: build-s390x.sh is missing or not executable"; \
		exit 1; \
	}
	./build-s390x.sh

#
# Build local container image
#
.PHONY: image
image:
	@echo "Building MinIO container image..."
	$(ENGINE) build -t $(LOCAL_IMAGE) .

#
# Push s390x image
#
.PHONY: push
push:
ifeq ($(strip $(PUSH_TAG)),)
	$(error PUSH_TAG is required)
endif
	@echo "Tagging image as $(PUSH_TAG)-s390x"
	$(ENGINE) tag $(LOCAL_IMAGE) $(PUSH_TAG)-s390x

	@echo "Pushing $(PUSH_TAG)-s390x"
	$(ENGINE) push $(PUSH_TAG)-s390x

#
# Create multi-arch manifest
#
.PHONY: manifest
manifest:
ifeq ($(strip $(PUSH_TAG)),)
	$(error PUSH_TAG is required)
endif

	@echo "Creating multi-arch manifest $(PUSH_TAG)"

	-$(ENGINE) manifest rm $(PUSH_TAG) >/dev/null 2>&1 || true

	$(ENGINE) manifest create $(PUSH_TAG)

	@echo "Adding amd64 image"
	$(ENGINE) manifest add $(PUSH_TAG) $(AMD64_IMAGE)

	@echo "Adding arm64 image"
	$(ENGINE) manifest add $(PUSH_TAG) $(ARM64_IMAGE)

	@echo "Adding ppc64le image"
	$(ENGINE) manifest add $(PUSH_TAG) $(PPC64LE_IMAGE)

	@echo "Resolving s390x image digest"
	@S390X_REPO=$$(echo "$(PUSH_TAG)-s390x" | sed 's/:[^:]*$$//'); \
	S390X_DIGEST=$$(skopeo inspect --format '{{.Digest}}' docker://$(PUSH_TAG)-s390x); \
	if [ -z "$$S390X_DIGEST" ] || [ "$$S390X_DIGEST" = "null" ]; then \
    		echo "Failed to resolve remote manifest digest"; \
    		exit 1; \
	fi; \
	echo "Adding s390x image ($$S390X_DIGEST)"; \
	$(ENGINE) manifest add $(PUSH_TAG) docker://$$S390X_REPO@$$S390X_DIGEST
#
# Push manifest
#
.PHONY: manifest-push
manifest-push:
ifeq ($(strip $(PUSH_TAG)),)
	$(error PUSH_TAG is required)
endif

	@echo "Pushing multi-arch manifest"

	$(ENGINE) manifest push --all \
		$(PUSH_TAG) \
		docker://$(PUSH_TAG)

#
# Complete release
#
.PHONY: release
release: binary image push manifest manifest-push

#
# Cleanup
#
.PHONY: clean
clean:
	-rm -f minio
	-$(ENGINE) rmi -f $(LOCAL_IMAGE) >/dev/null 2>&1 || true
