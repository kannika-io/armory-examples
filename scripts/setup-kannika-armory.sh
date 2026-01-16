#!/bin/bash

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
CLUSTER_NAME="${CLUSTER_NAME:-kannika-kind}"
KANNIKA_VERSION="${KANNIKA_VERSION:-0.13.0}"
KANNIKA_SYSTEM_NS="${KANNIKA_SYSTEM_NS:-kannika-system}"
KANNIKA_DATA_NS="${KANNIKA_DATA_NS:-kannika-data}"
LICENSE_PATH="${LICENSE_PATH:-}"

# Print colored message
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${SCRIPT_DIR}/.bin"

# Add local bin directory to PATH if it exists
if [ -d "${BIN_DIR}" ]; then
    export PATH="${BIN_DIR}:${PATH}"
fi

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
        echo ""
        echo "For kind, kubectl, and helm, you can use the provided installation scripts:"
        for tool in "${missing_tools[@]}"; do
            if [ "$tool" != "docker" ] && [ -f "${SCRIPT_DIR}/scripts/install-${tool}.sh" ]; then
                echo "  - ${tool}: ./scripts/install-${tool}.sh"
            fi
        done
        echo ""
        echo "Or install them manually:"
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

    # Create the cluster with port mappings
    kind create cluster --name "${CLUSTER_NAME}" --config "${SCRIPT_DIR}/kind-config.yaml"

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
    print_info "Creating Kannika system namespace: ${KANNIKA_SYSTEM_NS}..."

    if kubectl get namespace "${KANNIKA_SYSTEM_NS}" >/dev/null 2>&1; then
        print_warning "Namespace '${KANNIKA_SYSTEM_NS}' already exists. Skipping creation."
    else
        kubectl create namespace "${KANNIKA_SYSTEM_NS}"
        print_info "System namespace created successfully!"
    fi
}

# Create Kannika data namespace
create_kannika_data_namespace() {
    # Validate that data namespace is different from system namespace
    if [ "${KANNIKA_DATA_NS}" = "${KANNIKA_SYSTEM_NS}" ]; then
        print_error "Data namespace cannot be the same as system namespace."
        print_error "System namespace: ${KANNIKA_SYSTEM_NS}"
        print_error "Data namespace: ${KANNIKA_DATA_NS}"
        print_error "Please specify a different namespace for data resources."
        exit 1
    fi

    print_info "Creating Kannika data namespace: ${KANNIKA_DATA_NS}..."

    if kubectl get namespace "${KANNIKA_DATA_NS}" >/dev/null 2>&1; then
        print_warning "Namespace '${KANNIKA_DATA_NS}' already exists. Skipping creation."
    else
        kubectl create namespace "${KANNIKA_DATA_NS}"
        print_info "Data namespace created successfully!"
    fi
}

# Set default kubectl namespace
set_default_namespace() {
    print_info "Setting default namespace to ${KANNIKA_DATA_NS}..."
    kubectl config set-context --current --namespace="${KANNIKA_DATA_NS}"
}

# Create license secret
create_license_secret() {
    if [ -z "${LICENSE_PATH}" ]; then
        print_warning "No license path provided. Skipping license secret creation."
        echo ""
        echo "To get a free license, visit: https://www.kannika.io/free-trial"
        echo ""
        print_warning "To add a license later, run:"
        echo "  kubectl create secret generic kannika-license \\"
        echo "    --namespace ${KANNIKA_SYSTEM_NS} \\"
        echo "    --from-file=license=<path-to-license-file> \\"
        echo "    --type=kannika.io/license"
        return 0
    fi

    if [ ! -f "${LICENSE_PATH}" ]; then
        print_error "License file not found: ${LICENSE_PATH}"
        print_warning "Continuing without license. You can add it later."
        echo ""
        echo "To get a free license, visit: https://www.kannika.io/free-trial"
        echo ""
        return 0
    fi

    print_info "Creating license secret..."

    kubectl create secret generic kannika-license \
        --namespace "${KANNIKA_SYSTEM_NS}" \
        --from-file=license="${LICENSE_PATH}" \
        --type=kannika.io/license

    print_info "License secret created successfully!"
}

# Install Kannika Armory
install_kannika_armory() {
    print_info "Installing Kannika Armory (version ${KANNIKA_VERSION})..."

    helm install kannika oci://quay.io/kannika/charts/kannika \
        --namespace "${KANNIKA_SYSTEM_NS}" \
        --version "${KANNIKA_VERSION}" \
        --set global.kubernetes.namespace="${KANNIKA_DATA_NS}" \
        --set console.config.apiUrl="http://localhost:8081" \
        --wait

    print_info "Kannika Armory installed successfully!"
}

# Expose services via NodePort
expose_services() {
    print_info "Exposing console and API services..."

    kubectl patch svc console -n "${KANNIKA_SYSTEM_NS}" -p '{"spec": {"type": "NodePort", "ports": [{"port": 8080, "nodePort": 30080}]}}'
    kubectl patch svc api -n "${KANNIKA_SYSTEM_NS}" -p '{"spec": {"type": "NodePort", "ports": [{"port": 8080, "nodePort": 30081}]}}'

    print_info "Services exposed:"
    echo "  Console: http://localhost:8080"
    echo "  API:     http://localhost:8081"
}

# Verify installation
verify_installation() {
    print_info "Verifying Kannika Armory installation..."

    echo ""
    echo "Deployments in namespace ${KANNIKA_SYSTEM_NS}:"
    kubectl get deployments --namespace "${KANNIKA_SYSTEM_NS}"

    echo ""
    echo "Pods in namespace ${KANNIKA_SYSTEM_NS}:"
    kubectl get pods --namespace "${KANNIKA_SYSTEM_NS}"

    echo ""
    print_info "Checking deployment status..."

    # Wait for deployments to be ready
    local deployments=("api" "console" "operator")
    for deployment in "${deployments[@]}"; do
        if kubectl get deployment "${deployment}" --namespace "${KANNIKA_SYSTEM_NS}" >/dev/null 2>&1; then
            print_info "Waiting for deployment '${deployment}' to be ready..."
            kubectl wait --for=condition=available --timeout=300s \
                deployment/"${deployment}" --namespace "${KANNIKA_SYSTEM_NS}" || true
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
    -h, --help                 Show this help message
    -c, --cluster NAME         Kind cluster name (default: kannika-kind)
    -v, --version VERSION      Kannika version to install (default: 0.13.0)
    -n, --namespace NS         Kubernetes namespace for Kannika system (default: kannika-system)
    -d, --data-namespace NS    Kubernetes namespace for Kannika data resources (optional)
    -l, --license PATH         Path to license file (optional)

ENVIRONMENT VARIABLES:
    CLUSTER_NAME               Same as --cluster
    KANNIKA_VERSION            Same as --version
    KANNIKA_SYSTEM_NS          Same as --namespace
    KANNIKA_DATA_NS            Same as --data-namespace
    LICENSE_PATH               Same as --license

EXAMPLES:
    # Basic installation
    $0

    # Custom cluster name and version
    $0 --cluster my-cluster --version 0.13.0

    # With data namespace
    $0 --data-namespace kannika-data

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
                if [ -z "$2" ] || [[ "$2" == -* ]]; then
                    print_error "Option --cluster requires a value"
                    exit 1
                fi
                CLUSTER_NAME="$2"
                shift 2
                ;;
            -v|--version)
                if [ -z "$2" ] || [[ "$2" == -* ]]; then
                    print_error "Option --version requires a value"
                    exit 1
                fi
                KANNIKA_VERSION="$2"
                shift 2
                ;;
            -n|--namespace)
                if [ -z "$2" ] || [[ "$2" == -* ]]; then
                    print_error "Option --namespace requires a value"
                    exit 1
                fi
                KANNIKA_SYSTEM_NS="$2"
                shift 2
                ;;
            -l|--license)
                if [ -z "$2" ] || [[ "$2" == -* ]]; then
                    print_error "Option --license requires a value"
                    exit 1
                fi
                LICENSE_PATH="$2"
                shift 2
                ;;
            -d|--data-namespace)
                if [ -z "$2" ] || [[ "$2" == -* ]]; then
                    print_error "Option --data-namespace requires a value"
                    exit 1
                fi
                KANNIKA_DATA_NS="$2"
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
    echo "  System namespace: ${KANNIKA_SYSTEM_NS}"
    echo "  Data namespace: ${KANNIKA_DATA_NS}"
    echo "  License path: ${LICENSE_PATH:-<not provided>}"
    echo ""

    check_prerequisites
    create_kind_cluster
    install_kannika_crds
    create_kannika_namespace
    create_kannika_data_namespace
    set_default_namespace
    create_license_secret
    install_kannika_armory
    expose_services
    verify_installation

    echo ""
    print_info "========================================="
    print_info "Kannika Armory setup completed!"
    print_info "========================================="
    echo ""
    echo "Kannika Armory:"
    echo "  Console: http://localhost:8080"
    echo "  API:     http://localhost:8081"
    echo ""
    echo "Next steps:"
    echo ""
    echo "  1. Start Kafka clusters:"
    echo "     docker-compose up -d"
    echo ""
    echo "  2. Connect Kind to Kafka:"
    echo "     ./connect-kafka-to-kind.sh"
    echo ""
    echo "  3. Access Redpanda Console:"
    echo "     Source: http://localhost:8180"
    echo "     Target: http://localhost:8181"
    echo ""
    echo "  4. To tear down the environment:"
    echo "     ./teardown.sh          # Kind cluster only"
    echo "     ./teardown.sh --all    # Kind cluster and Kafka"
    echo ""
}

# Run main function
main "$@"
