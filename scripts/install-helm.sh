#!/bin/bash
#
# Install helm to the local .bin directory.
#
# Usage:
#   ./scripts/install-helm.sh
#
# Environment variables:
#   HELM_VERSION    Version to install (default: v3.17.0)
#
# Examples:
#   ./scripts/install-helm.sh
#   HELM_VERSION=v3.17.0 ./scripts/install-helm.sh
#

set -e

# Install helm to local .bin directory
BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.bin"
HELM_VERSION="${HELM_VERSION:-v3.17.0}"

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

# Download and extract helm
HELM_TAR="helm-${HELM_VERSION}-${OS}-${ARCH}.tar.gz"
HELM_URL="https://get.helm.sh/${HELM_TAR}"

TMP_DIR=$(mktemp -d)
trap "rm -rf ${TMP_DIR}" EXIT

curl -fsSLo "${TMP_DIR}/${HELM_TAR}" "${HELM_URL}"
tar -xzf "${TMP_DIR}/${HELM_TAR}" -C "${TMP_DIR}"
mv "${TMP_DIR}/${OS}-${ARCH}/helm" "${BIN_DIR}/helm"
chmod +x "${BIN_DIR}/helm"

echo "${BIN_DIR}/helm"
