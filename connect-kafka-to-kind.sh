#!/bin/bash

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Configuration
CLUSTER_NAME="${CLUSTER_NAME:-kannika-kind}"
KAFKA_NETWORK="kafka-migration"

# Print usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Connect a Kind cluster to the Kafka migration network.

This allows pods running in the Kind cluster to access the Kafka clusters
at kafka-source:29092 and kafka-target:29092.

OPTIONS:
    -h, --help              Show this help message
    -c, --cluster NAME      Kind cluster name (default: kannika-kind)

ENVIRONMENT VARIABLES:
    CLUSTER_NAME            Same as --cluster

EXAMPLES:
    # Connect default cluster
    $0

    # Connect custom cluster
    $0 --cluster my-cluster

    # Using environment variable
    CLUSTER_NAME=my-cluster $0

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
            *)
                print_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Check if Docker is running
check_docker() {
    if ! docker ps >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Check if Kafka network exists
check_kafka_network() {
    if ! docker network inspect "${KAFKA_NETWORK}" >/dev/null 2>&1; then
        print_error "Kafka network '${KAFKA_NETWORK}' does not exist."
        print_error "Please start the Kafka clusters first with: docker compose up -d"
        exit 1
    fi
    print_info "Kafka network '${KAFKA_NETWORK}' found."
}

# Get Kind control plane container name
get_kind_control_plane() {
    local container_name="${CLUSTER_NAME}-control-plane"
    
    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        print_error "Kind cluster '${CLUSTER_NAME}' control plane container not found."
        print_error "Expected container name: ${container_name}"
        echo ""
        echo "Available Kind containers:"
        docker ps --filter "name=control-plane" --format "  - {{.Names}}"
        echo ""
        print_error "Please create the Kind cluster first."
        print_error "You can use './setup-kannika-armory.sh' or 'kind create cluster --name ${CLUSTER_NAME}'"
        exit 1
    fi
    
    echo "${container_name}"
}

# Connect Kind cluster to Kafka network
connect_to_network() {
    local container_name=$1
    
    # Check if already connected
    local networks=$(docker inspect "${container_name}" --format '{{range $net, $v := .NetworkSettings.Networks}}{{$net}} {{end}}')
    if echo "${networks}" | grep -q "${KAFKA_NETWORK}"; then
        print_warning "Container '${container_name}' is already connected to network '${KAFKA_NETWORK}'."
        return 0
    fi
    
    print_info "Connecting '${container_name}' to network '${KAFKA_NETWORK}'..."
    docker network connect "${KAFKA_NETWORK}" "${container_name}"
    print_info "Successfully connected!"
}

# Verify connection
verify_connection() {
    local container_name=$1
    
    print_info "Verifying connection..."
    
    # Check if the network is in the container's networks
    local networks=$(docker inspect "${container_name}" --format '{{range $net, $v := .NetworkSettings.Networks}}{{$net}} {{end}}')
    
    if echo "${networks}" | grep -q "${KAFKA_NETWORK}"; then
        print_info "Verification successful!"
        echo ""
        print_info "The Kind cluster can now access:"
        echo "  - Source Kafka: kafka-source:29092"
        echo "  - Target Kafka: kafka-target:29092"
        echo ""
        print_info "Test connectivity from a pod:"
        echo "  kubectl run kafka-test --image=confluentinc/cp-kafka:7.6.0 --rm -it --restart=Never -- kafka-topics --bootstrap-server kafka-source:29092 --list"
    else
        print_error "Connection verification failed."
        exit 1
    fi
}

# Main function
main() {
    parse_args "$@"
    
    print_info "Connecting Kind cluster '${CLUSTER_NAME}' to Kafka network..."
    echo ""
    
    check_docker
    check_kafka_network
    
    local container_name=$(get_kind_control_plane)
    print_info "Found Kind control plane: ${container_name}"
    
    connect_to_network "${container_name}"
    verify_connection "${container_name}"
    
    echo ""
    print_info "========================================="
    print_info "Connection completed successfully!"
    print_info "========================================="
    echo ""
}

# Run main function
main "$@"
