#!/bin/bash

set -e

# Install kind to local .bin directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${SCRIPT_DIR}/../.bin"
KIND_VERSION="${KIND_VERSION:-v0.31.0}"

mkdir -p "${BIN_DIR}"

echo "Installing kind ${KIND_VERSION} to ${BIN_DIR}..."

# Detect OS and architecture
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

case "${ARCH}" in
    x86_64)
        ARCH="amd64"
        ;;
    aarch64|arm64)
        ARCH="arm64"
        ;;
    *)
        echo "Unsupported architecture: ${ARCH}"
        exit 1
        ;;
esac

# Download kind
KIND_URL="https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-${OS}-${ARCH}"
curl -Lo "${BIN_DIR}/kind" "${KIND_URL}"
chmod +x "${BIN_DIR}/kind"

echo "kind installed successfully!"
echo "Add ${BIN_DIR} to your PATH or use: ${BIN_DIR}/kind"
