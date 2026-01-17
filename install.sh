#!/bin/bash
set -e

INSTALL_DIR="${KANNIKA_EXAMPLES_DIR:-$HOME/.kannika-examples}"
REPO_URL="https://github.com/kannika-io/armory-examples/tarball/main"

if [ -d "$INSTALL_DIR" ]; then
    echo "Directory $INSTALL_DIR already exists."
    read -p "Update existing installation? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Using existing installation."
        cd "$INSTALL_DIR"
        ./setup "$@"
        exit 0
    fi
    echo "Updating..."
    rm -rf "$INSTALL_DIR"
fi

echo "Downloading to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
curl -fsSL "$REPO_URL" | tar xz --strip-components=1 -C "$INSTALL_DIR"

cd "$INSTALL_DIR"
./setup "$@"
