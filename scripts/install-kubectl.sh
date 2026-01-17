#!/bin/bash

set -e

# Install kubectl to local .bin directory
BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.bin"
KUBECTL_VERSION="${KUBECTL_VERSION:-v1.31.4}"

mkdir -p "${BIN_DIR}"

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

# Download kubectl
KUBECTL_URL="https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/${OS}/${ARCH}/kubectl"
curl -fsSLo "${BIN_DIR}/kubectl" "${KUBECTL_URL}"
chmod +x "${BIN_DIR}/kubectl"

echo "${BIN_DIR}/kubectl"
