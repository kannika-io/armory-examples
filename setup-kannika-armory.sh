#!/bin/bash

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
CLUSTER_NAME="${CLUSTER_NAME:-kannika-kind}"
KANNIKA_VERSION="${KANNIKA_VERSION:-0.12.4}"
KANNIKA_NAMESPACE="${KANNIKA_NAMESPACE:-kannika-system}"
LICENSE_PATH="${LICENSE_PATH:-}"

# Print colored message
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    local missing_tools=()
    
    if ! command_exists docker; then
        missing_tools+=("docker")
    fi
    
    if ! command_exists kind; then
        missing_tools+=("kind")
    fi
    
    if ! command_exists kubectl; then
        missing_tools+=("kubectl")
    fi
    
    if ! command_exists helm; then
        missing_tools+=("helm")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        echo ""
        echo "Please install the missing tools:"
        echo "  - Docker: https://docs.docker.com/get-docker/"
        echo "  - kind: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
        echo "  - kubectl: https://kubernetes.io/docs/tasks/tools/"
        echo "  - helm: https://helm.sh/docs/intro/install/"
        exit 1
    fi
    
    # Check if Docker is running
    if ! docker ps >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    
    print_info "All prerequisites met!"
}

# Create kind cluster
create_kind_cluster() {
    print_info "Creating kind cluster: ${CLUSTER_NAME}..."
    
    # Check if cluster already exists
    if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
        print_warning "Cluster '${CLUSTER_NAME}' already exists. Skipping creation."
        kind get clusters
        return 0
    fi
    
    # Create the cluster
    kind create cluster --name "${CLUSTER_NAME}"
    
    # Verify cluster is ready
    kubectl cluster-info --context "kind-${CLUSTER_NAME}"
    
    print_info "Kind cluster created successfully!"
}

# Install Kannika CRDs
install_kannika_crds() {
    print_info "Installing Kannika CRDs (version ${KANNIKA_VERSION})..."
    
    # Install CRDs using Helm
    helm install kannika-crd oci://quay.io/kannika/charts/kannika-crd \
        --version "${KANNIKA_VERSION}" \
        --wait
    
    print_info "Kannika CRDs installed successfully!"
}

# Create Kannika namespace
create_kannika_namespace() {
    print_info "Creating Kannika namespace: ${KANNIKA_NAMESPACE}..."
    
    if kubectl get namespace "${KANNIKA_NAMESPACE}" >/dev/null 2>&1; then
        print_warning "Namespace '${KANNIKA_NAMESPACE}' already exists. Skipping creation."
    else
        kubectl create namespace "${KANNIKA_NAMESPACE}"
        print_info "Namespace created successfully!"
    fi
}

# Create license secret
create_license_secret() {
    if [ -z "${LICENSE_PATH}" ]; then
        print_warning "No license path provided. Skipping license secret creation."
        print_warning "To add a license later, run:"
        echo "  kubectl create secret generic kannika-license \\"
        echo "    --namespace ${KANNIKA_NAMESPACE} \\"
        echo "    --from-file=license=<path-to-license-file> \\"
        echo "    --type=kannika.io/license"
        return 0
    fi
    
    if [ ! -f "${LICENSE_PATH}" ]; then
        print_error "License file not found: ${LICENSE_PATH}"
        print_warning "Continuing without license. You can add it later."
        return 0
    fi
    
    print_info "Creating license secret..."
    
    kubectl create secret generic kannika-license \
        --namespace "${KANNIKA_NAMESPACE}" \
        --from-file=license="${LICENSE_PATH}" \
        --type=kannika.io/license
    
    print_info "License secret created successfully!"
}

# Install Kannika Armory
install_kannika_armory() {
    print_info "Installing Kannika Armory (version ${KANNIKA_VERSION})..."
    
    helm install kannika oci://quay.io/kannika/charts/kannika \
        --create-namespace \
        --namespace "${KANNIKA_NAMESPACE}" \
        --version "${KANNIKA_VERSION}" \
        --wait
    
    print_info "Kannika Armory installed successfully!"
}

# Verify installation
verify_installation() {
    print_info "Verifying Kannika Armory installation..."
    
    echo ""
    echo "Deployments in namespace ${KANNIKA_NAMESPACE}:"
    kubectl get deployments --namespace "${KANNIKA_NAMESPACE}"
    
    echo ""
    echo "Pods in namespace ${KANNIKA_NAMESPACE}:"
    kubectl get pods --namespace "${KANNIKA_NAMESPACE}"
    
    echo ""
    print_info "Checking deployment status..."
    
    # Wait for deployments to be ready
    local deployments=("api" "console" "operator")
    for deployment in "${deployments[@]}"; do
        if kubectl get deployment "${deployment}" --namespace "${KANNIKA_NAMESPACE}" >/dev/null 2>&1; then
            print_info "Waiting for deployment '${deployment}' to be ready..."
            kubectl wait --for=condition=available --timeout=300s \
                deployment/"${deployment}" --namespace "${KANNIKA_NAMESPACE}" || true
        fi
    done
    
    print_info "Installation verification complete!"
}

# Print usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Setup Kannika Armory on a kind cluster.

OPTIONS:
    -h, --help              Show this help message
    -c, --cluster NAME      Kind cluster name (default: kannika-kind)
    -v, --version VERSION   Kannika version to install (default: 0.12.4)
    -n, --namespace NS      Kubernetes namespace for Kannika (default: kannika-system)
    -l, --license PATH      Path to license file (optional)

ENVIRONMENT VARIABLES:
    CLUSTER_NAME            Same as --cluster
    KANNIKA_VERSION         Same as --version
    KANNIKA_NAMESPACE       Same as --namespace
    LICENSE_PATH            Same as --license

EXAMPLES:
    # Basic installation
    $0

    # Custom cluster name and version
    $0 --cluster my-cluster --version 0.12.4

    # With license file
    $0 --license /path/to/license.key

    # Using environment variables
    CLUSTER_NAME=my-cluster LICENSE_PATH=/path/to/license.key $0

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -c|--cluster)
                CLUSTER_NAME="$2"
                shift 2
                ;;
            -v|--version)
                KANNIKA_VERSION="$2"
                shift 2
                ;;
            -n|--namespace)
                KANNIKA_NAMESPACE="$2"
                shift 2
                ;;
            -l|--license)
                LICENSE_PATH="$2"
                shift 2
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Main function
main() {
    print_info "Starting Kannika Armory setup on kind cluster..."
    echo ""
    
    parse_args "$@"
    
    echo "Configuration:"
    echo "  Cluster name: ${CLUSTER_NAME}"
    echo "  Kannika version: ${KANNIKA_VERSION}"
    echo "  Namespace: ${KANNIKA_NAMESPACE}"
    echo "  License path: ${LICENSE_PATH:-<not provided>}"
    echo ""
    
    check_prerequisites
    create_kind_cluster
    install_kannika_crds
    create_kannika_namespace
    create_license_secret
    install_kannika_armory
    verify_installation
    
    echo ""
    print_info "========================================="
    print_info "Kannika Armory setup completed!"
    print_info "========================================="
    echo ""
    echo "Next steps:"
    echo "  1. Access your cluster:"
    echo "     kubectl config use-context kind-${CLUSTER_NAME}"
    echo ""
    echo "  2. Check the status:"
    echo "     kubectl get all -n ${KANNIKA_NAMESPACE}"
    echo ""
    echo "  3. To delete the cluster when done:"
    echo "     kind delete cluster --name ${CLUSTER_NAME}"
    echo ""
}

# Run main function
main "$@"
