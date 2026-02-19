#!/bin/bash
# Initialize tutorial resources for: Backup with S3 Storage (MinIO)
set -e

TUTORIAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${TUTORIAL_DIR}/../.." && pwd)"

source "${REPO_ROOT}/scripts/env.sh"
__env_load
source "${REPO_ROOT}/scripts/kafka-helpers.sh"

print_info "Setting up tutorial data..."

# Clean up existing topic
kafka_delete_topic kafka-source orders

# Create topic
kafka_create_topic kafka-source orders

# Produce sample order data
kafka_produce_jsonl kafka-source orders "${TUTORIAL_DIR}/sample-data/orders.jsonl"
