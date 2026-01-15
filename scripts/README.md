# Installation Scripts

This directory contains optional installation scripts for installing prerequisite tools locally without requiring system-wide installation or administrator privileges.

## Available Scripts

### install-kind.sh
Installs [kind](https://kind.sigs.k8s.io/) (Kubernetes IN Docker) to the local `.bin` directory.

**Usage:**
```bash
./scripts/install-kind.sh

# Or specify a custom version
KIND_VERSION=v0.31.0 ./scripts/install-kind.sh
```

**Default version:** v0.31.0

### install-kubectl.sh
Installs [kubectl](https://kubernetes.io/docs/reference/kubectl/) to the local `.bin` directory.

**Usage:**
```bash
./scripts/install-kubectl.sh

# Or specify a custom version
KUBECTL_VERSION=v1.31.4 ./scripts/install-kubectl.sh
```

**Default version:** v1.31.4

### install-helm.sh
Installs [helm](https://helm.sh/) to the local `.bin` directory.

**Usage:**
```bash
./scripts/install-helm.sh

# Or specify a custom version
HELM_VERSION=v3.17.0 ./scripts/install-helm.sh
```

**Default version:** v3.17.0

## How It Works

- Each script downloads the specified tool for your operating system and architecture
- Tools are installed to the `.bin` directory at the repository root
- The `.bin` directory is git-ignored, so these binaries won't be committed
- The main setup script (`setup-kannika-armory.sh`) automatically detects and uses tools from `.bin` if available

## Using Locally Installed Tools

After running the installation scripts, you can:

1. **Add `.bin` to your PATH** (for the current session):
   ```bash
   export PATH="$(pwd)/.bin:$PATH"
   ```

2. **Use the full path**:
   ```bash
   ./.bin/kind --version
   ./.bin/kubectl version --client
   ./.bin/helm version
   ```

3. **Run the setup script** (which automatically uses `.bin` tools):
   ```bash
   ./setup-kannika-armory.sh
   ```

## Supported Platforms

These scripts support:
- **Operating Systems:** Linux, macOS
- **Architectures:** x86_64 (amd64), aarch64/arm64

## Notes

- Docker must still be installed system-wide as it requires root/administrator privileges
- To update a tool, simply re-run the installation script with the desired version
- To remove locally installed tools, delete the `.bin` directory: `rm -rf .bin`
