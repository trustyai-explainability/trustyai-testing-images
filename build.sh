#!/bin/bash

set -e

# Default values
PUSH=true
BACKEND=""
REGISTRY="quay.io/trustyai_testing"
PLATFORMS="linux/amd64,linux/arm64,linux/ppc64le"

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS] <directory>"
    echo ""
    echo "Build container images from the specified directory"
    echo ""
    echo "Arguments:"
    echo "  <directory>           Directory containing the Dockerfile (e.g., onnx-loan-model-modelcar)"
    echo ""
    echo "Options:"
    echo "  --no-push            Build without pushing to registry"
    echo "  --backend <backend>  Specify backend: docker or podman (auto-detected if not specified)"
    echo "  --registry <url>     Registry URL (default: quay.io/trustyai_testing)"
    echo "  --platforms <list>   Comma-separated list of platforms (default: linux/amd64,linux/arm64,linux/ppc64le)"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 onnx-loan-model-modelcar"
    echo "  $0 --no-push gaussian-credit-model-modelcar"
    echo "  $0 --backend podman onnx-loan-model-modelcar"
}

# Function to detect available backend
detect_backend() {
    if command -v docker >/dev/null 2>&1; then
        if docker buildx version >/dev/null 2>&1; then
            echo "docker"
            return
        fi
    fi
    
    if command -v podman >/dev/null 2>&1; then
        echo "podman"
        return
    fi
    
    echo "ERROR: Neither docker with buildx nor podman found" >&2
    exit 1
}

# Function to build with Docker
build_with_docker() {
    local dir="$1"
    local tag="$2"
    local output_type="$3"
    
    echo "Building with Docker buildx..."
    docker buildx build \
        --no-cache \
        --pull \
        --platform "$PLATFORMS" \
        --output "$output_type" \
        --tag "$tag" \
        "$dir"
}

# Function to build with Podman
build_with_podman() {
    local dir="$1"
    local tag="$2"
    local should_push="$3"
    
    echo "Building with Podman..."
    
    # Parse platforms into array
    IFS=',' read -ra PLATFORM_ARRAY <<< "$PLATFORMS"
    
    # Check if we have multiple platforms
    if [ ${#PLATFORM_ARRAY[@]} -eq 1 ]; then
        # Single platform build
        local platform="${PLATFORM_ARRAY[0]}"
        echo "Building single platform: $platform"
        
        podman build \
            --no-cache \
            --pull \
            --platform "$platform" \
            --tag "$tag" \
            "$dir"
        
        if [ "$should_push" = true ]; then
            echo "Pushing image with Podman..."
            podman push "$tag"
        fi
    else
        # Multi-platform build using manifest
        echo "Building multi-platform images and creating manifest..."
        
        # Array to store individual image tags
        local image_tags=()
        
        # Build for each platform
        for platform in "${PLATFORM_ARRAY[@]}"; do
            # Create platform-specific tag
            local platform_tag="${tag}-${platform//\//-}"
            image_tags+=("$platform_tag")
            
            echo "Building for platform: $platform"
            podman build \
                --no-cache \
                --pull \
                --platform "$platform" \
                --tag "$platform_tag" \
                "$dir"
            
            if [ "$should_push" = true ]; then
                echo "Pushing platform-specific image: $platform_tag"
                podman push "$platform_tag"
            fi
        done
        
        # Create and push manifest
        if [ "$should_push" = true ]; then
            echo "Creating and pushing manifest: $tag"
            
            # Create manifest
            podman manifest create "$tag"
            
            # Add each platform image to manifest
            for image_tag in "${image_tags[@]}"; do
                echo "Adding $image_tag to manifest"
                podman manifest add "$tag" "$image_tag"
            done
            
            # Push the manifest
            echo "Pushing manifest: $tag"
            podman manifest push "$tag"
            
            # Clean up individual platform images from registry if desired
            # (keeping them locally for potential reuse)
            echo "Multi-platform manifest pushed successfully"
        else
            # Create local manifest even when not pushing
            echo "Creating local manifest: $tag"
            podman manifest create "$tag"
            
            # Add each platform image to manifest
            for image_tag in "${image_tags[@]}"; do
                echo "Adding $image_tag to local manifest"
                podman manifest add "$tag" "$image_tag"
            done
            
            echo "Local multi-platform manifest created"
        fi
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-push)
            PUSH=false
            shift
            ;;
        --backend)
            BACKEND="$2"
            shift 2
            ;;
        --registry)
            REGISTRY="$2"
            shift 2
            ;;
        --platforms)
            PLATFORMS="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            echo "ERROR: Unknown option $1" >&2
            usage
            exit 1
            ;;
        *)
            if [ -z "$DIRECTORY" ]; then
                DIRECTORY="$1"
            else
                echo "ERROR: Multiple directories specified" >&2
                usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Check if directory is provided
if [ -z "$DIRECTORY" ]; then
    echo "ERROR: Directory argument is required" >&2
    usage
    exit 1
fi

# Check if directory exists
if [ ! -d "$DIRECTORY" ]; then
    echo "ERROR: Directory '$DIRECTORY' does not exist" >&2
    exit 1
fi

# Check if Dockerfile exists in the directory
if [ ! -f "$DIRECTORY/Dockerfile" ]; then
    echo "ERROR: Dockerfile not found in '$DIRECTORY'" >&2
    exit 1
fi

# Auto-detect backend if not specified
if [ -z "$BACKEND" ]; then
    BACKEND=$(detect_backend)
fi

# Validate backend
if [ "$BACKEND" != "docker" ] && [ "$BACKEND" != "podman" ]; then
    echo "ERROR: Backend must be either 'docker' or 'podman'" >&2
    exit 1
fi

# Generate image tag
IMAGE_TAG="$REGISTRY/$DIRECTORY:latest"

echo "Building container image..."
echo "Directory: $DIRECTORY"
echo "Backend: $BACKEND"
echo "Tag: $IMAGE_TAG"
echo "Push: $PUSH"
echo "Platforms: $PLATFORMS"
echo ""

# Build based on backend
case "$BACKEND" in
    docker)
        if [ "$PUSH" = true ]; then
            OUTPUT_TYPE="type=image,push=true"
        else
            OUTPUT_TYPE="type=docker"
        fi
        build_with_docker "$DIRECTORY" "$IMAGE_TAG" "$OUTPUT_TYPE"
        ;;
    podman)
        build_with_podman "$DIRECTORY" "$IMAGE_TAG" "$PUSH"
        ;;
esac

echo ""
echo "Build completed successfully!"
if [ "$PUSH" = true ]; then
    echo "Image pushed to: $IMAGE_TAG"
else
    echo "Image built locally: $IMAGE_TAG"
fi
