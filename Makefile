# Makefile for building Docker images in trustyai-testing-images project

# Get all directories containing Dockerfiles (excluding current directory)
DOCKER_DIRS := $(shell find . -name "Dockerfile" -not -path "./Dockerfile" -exec dirname {} \; | sed 's|./||' | sort)

# Container engine configuration
ENGINE ?= docker

# Target platforms for multi-arch builds
PLATFORMS ?= linux/amd64,linux/arm64,linux/ppc64le,linux/s390x

# Default target
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  build <image-name>     - Build container image for specified directory"
	@echo "  build-all              - Build all container images"
	@echo "  list                   - List all available image directories"
	@echo ""
	@echo "Configuration:"
	@echo "  ENGINE                 - Container engine to use (docker or podman, default: docker)"
	@echo ""
	@echo "Usage examples:"
	@echo "  make build gaussian-credit-model-modelcar"
	@echo "  make build gaussian-credit-model-modelcar --push \"quay.io/trustyai_testing/gaussian-credit-model-modelcar:latest\""
	@echo "  make build-all"
	@echo "  make ENGINE=podman build gaussian-credit-model-modelcar"
	@echo ""
	@echo "Available image directories:"
	@$(foreach dir,$(DOCKER_DIRS),echo "  - $(dir)";)

# List available Docker directories
.PHONY: list
list:
	@echo "Available Docker image directories:"
	@$(foreach dir,$(DOCKER_DIRS),echo "  - $(dir)";)

# Build all images
.PHONY: build-all
build-all:
	@$(foreach dir,$(DOCKER_DIRS),echo "Building $(dir)..." && $(MAKE) build $(dir) &&) echo "All images built successfully!"

# Build specific image with optional push
.PHONY: build
build:
	@if [ -z "$(filter-out build,$(MAKECMDGOALS))" ]; then \
		echo "Error: Please specify an image name to build"; \
		echo "Usage: make build <image-name>"; \
		echo "Available images: $(DOCKER_DIRS)"; \
		exit 1; \
	fi
	@IMAGE_NAME=$(filter-out build,$(MAKECMDGOALS)); \
	if [ ! -d "$$IMAGE_NAME" ]; then \
		echo "Error: Directory $$IMAGE_NAME does not exist"; \
		echo "Available directories: $(DOCKER_DIRS)"; \
		exit 1; \
	fi; \
	if [ ! -f "$$IMAGE_NAME/Dockerfile" ]; then \
		echo "Error: No Dockerfile found in $$IMAGE_NAME directory"; \
		exit 1; \
	fi; \
	echo "Building container image for $$IMAGE_NAME..."; \
	if [ "$(ENGINE)" = "docker" ]; then \
		$(ENGINE) buildx create --use --name multiarch-builder --platform=$(PLATFORMS) || true; \
		$(ENGINE) buildx build --platform=$(PLATFORMS) -t $$IMAGE_NAME $$IMAGE_NAME --load; \
		if [ "$(findstring --push,$(MAKECMDGOALS))" ]; then \
			PUSH_TAG=$$(echo "$(MAKECMDGOALS)" | sed -n 's/.*--push[[:space:]]*"\([^"]*\)".*/\1/p'); \
			if [ -n "$$PUSH_TAG" ]; then \
				echo "Building and pushing multi-arch image $$PUSH_TAG"; \
				$(ENGINE) buildx build --platform=$(PLATFORMS) -t $$PUSH_TAG $$IMAGE_NAME --push; \
			else \
				echo "Error: Push flag provided but no tag specified"; \
				echo "Usage: make build <image-name> --push \"registry/image:tag\""; \
				exit 1; \
			fi; \
		fi; \
	else \
		$(ENGINE) build -t $$IMAGE_NAME $$IMAGE_NAME; \
		if [ "$(findstring --push,$(MAKECMDGOALS))" ]; then \
			PUSH_TAG=$$(echo "$(MAKECMDGOALS)" | sed -n 's/.*--push[[:space:]]*"\([^"]*\)".*/\1/p'); \
			if [ -n "$$PUSH_TAG" ]; then \
				echo "Building and pushing image $$PUSH_TAG"; \
				$(ENGINE) tag $$IMAGE_NAME $$PUSH_TAG; \
				$(ENGINE) push $$PUSH_TAG; \
			else \
				echo "Error: Push flag provided but no tag specified"; \
				echo "Usage: make build <image-name> --push \"registry/image:tag\""; \
				exit 1; \
			fi; \
		fi; \
	fi

# Prevent make from treating image names and flags as targets
%:
	@:

# Clean up Docker images
.PHONY: clean
clean:
	@echo "Removing built images..."
	@$(foreach dir,$(DOCKER_DIRS),$(ENGINE) rmi -f $(dir) 2>/dev/null || true;)
	@echo "Cleanup complete"
