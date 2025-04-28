#!/bin/bash
set -e

# Define variables
PROJECT_ROOT="$(pwd)"
BUILD_DIR="$(pwd)/tmp/MEGAcmd"
DIST_DIR="$(pwd)/dist"
MEGACMD_VERSION="e8b0858980a16e950258c64c04accf853ed485de"
DEFAULT_IMAGE_NAME="mega-sync"

# Allow overriding the image name via a script argument
IMAGE_NAME="${1:-$DEFAULT_IMAGE_NAME}"

# Clean up previous builds
rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$DIST_DIR"

# Clone MEGAcmd and checkout specific version
git clone --recurse-submodules https://github.com/meganz/MEGAcmd.git "$BUILD_DIR"
cd "$BUILD_DIR"
git checkout "$MEGACMD_VERSION"
git submodule update --init --recursive

# Apply MEGAcmd patch if it exists
if [ -f "../../megacmd.patch" ]; then
    git apply ../../megacmd.patch || git am < ../../megacmd.patch
fi

# Apply SDK submodule patch
cd sdk
if [ -f "../../../sdk.patch" ]; then
    git apply ../../../sdk.patch || git am < ../../../sdk.patch
fi
cd ..

# Build the Docker image for MEGAcmd
docker build -t custom-megacmd -f "$BUILD_DIR/build-with-docker/Dockerfile.cmake" "$BUILD_DIR"

# Create a temporary container
CONTAINER_ID=$(docker create custom-megacmd)

# Copy MEGAcmd binaries
BINARIES=$(docker run --rm --entrypoint sh custom-megacmd -c "find /usr/bin/ -name 'mega*'")

for file in $BINARIES; do
    docker cp "$CONTAINER_ID:$file" "$DIST_DIR/"
done

# Copy additional binaries if they exist
docker cp "$CONTAINER_ID:/opt/megacmd" "$DIST_DIR/" || true

# Cleanup
docker rm -v "$CONTAINER_ID"

echo "✅ Build complete. Binaries are in $DIST_DIR"

# Return to the original project root
cd "$PROJECT_ROOT"

echo "Current working directory: $(pwd)"
ls -l  # Debug: Check if Dockerfile exists

# Build the final lightweight Docker image using the copied binaries
docker build -t "$IMAGE_NAME" -f Dockerfile .
echo "✅ Runtime Docker image $IMAGE_NAME built successfully."