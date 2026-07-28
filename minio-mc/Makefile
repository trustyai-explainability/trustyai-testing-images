# MinIO Makefile

ENGINE ?= docker

# Passed from top-level Makefile
PUSH_TAG ?=

# Temporary local image
LOCAL_IMAGE := minio-mc-s390x:local

# Upstream architecture-specific images
AMD64_IMAGE   := docker://quay.io/minio/mc@sha256:eb4ea9884b77704230e2423e9004d2fa738dc272876b9cc41a297d29443b8780
ARM64_IMAGE   := docker://quay.io/minio/mc@sha256:37d109dddbbb2c95873f5fc81ac93f37023264770fc580a7564148892087b1b7
PPC64LE_IMAGE := docker://quay.io/minio/mc@sha256:3f44d78099010e8c0176fa3fb7335759c004eda04c94e8613d3c77b276ee26e9

.PHONY: all
all: build

#
# Entry point called from top-level Makefile
#
.PHONY: build
build:
ifeq ($(strip $(PUSH_TAG)),)
	@echo "Building minio client locally (no push)..."
	$(MAKE) binary image
else
	@echo "Building and publishing minio client..."
	$(MAKE) release
endif

#
# Build MinIO-MC binary
#
.PHONY: binary
binary:
	@echo "Building MinIO client s390x binary..."
	./build-s390x.sh

#
# Build local container image
#
.PHONY: image
image:
	@echo "Building MinIO-MC container image..."
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

	@echo "Adding s390x image"
	$(ENGINE) manifest add $(PUSH_TAG) docker://$(PUSH_TAG)-s390x

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
	-rm -f mc
	-$(ENGINE) rmi -f $(LOCAL_IMAGE) >/dev/null 2>&1 || true
