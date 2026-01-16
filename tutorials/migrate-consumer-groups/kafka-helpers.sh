#!/bin/bash
# Reusable Kafka helper functions for tutorials
# Source this file: source kafka-helpers.sh

KAFKA_CONTAINER="${KAFKA_CONTAINER:-kafka-source}"
KAFKA_BOOTSTRAP="${KAFKA_BOOTSTRAP:-kafka-source:29092}"

print_info() { echo -e "\033[0;32m[INFO]\033[0m $1"; }
print_error() { echo -e "\033[0;31m[ERROR]\033[0m $1" >&2; }

kafka_check() {
    docker ps --format '{{.Names}}' | grep -q "^${KAFKA_CONTAINER}$" || {
        print_error "Kafka container '${KAFKA_CONTAINER}' not running. Start with: docker-compose up -d"
        return 1
    }
}

kafka_create_topic() {
    local cluster="$1" topic="$2" partitions="${3:-1}"
    [[ -z "$cluster" ]] && { print_error "cluster required: kafka_create_topic <cluster> <topic> [partitions]"; return 1; }
    local container="kafka-${cluster}"
    local bootstrap="kafka-${cluster}:29092"
    print_info "Creating topic: ${topic} on ${container}"
    docker exec "${container}" kafka-topics \
        --bootstrap-server "${bootstrap}" \
        --create --topic "${topic}" \
        --partitions "${partitions}" \
        --replication-factor 1 \
        --if-not-exists
}

kafka_delete_topic() {
    local cluster="$1" topic="$2"
    [[ -z "$cluster" ]] && { print_error "cluster required: kafka_delete_topic <cluster> <topic>"; return 1; }
    local container="kafka-${cluster}"
    local bootstrap="kafka-${cluster}:29092"
    docker exec "${container}" kafka-topics \
        --bootstrap-server "${bootstrap}" \
        --delete --topic "${topic}" --if-exists 2>/dev/null || true
}

kafka_produce() {
    local topic="$1" key="$2" value="$3"
    echo "${key}:${value}" | docker exec -i "${KAFKA_CONTAINER}" kafka-console-producer \
        --bootstrap-server "${KAFKA_BOOTSTRAP}" \
        --topic "${topic}" \
        --property "parse.key=true" \
        --property "key.separator=:"
}

kafka_produce_jsonl() {
    local topic="$1" file="$2"
    [ -f "${file}" ] || { print_error "File not found: ${file}"; return 1; }
    print_info "Producing messages to ${topic}"
    while IFS= read -r line || [ -n "$line" ]; do
        [ -z "$line" ] && continue
        local key value
        key=$(echo "$line" | jq -r '.key')
        value=$(echo "$line" | jq -c '.value')
        kafka_produce "${topic}" "${key}" "${value}"
    done < "${file}"
}

kafka_consume() {
    local group="$1" topic="$2" count="$3"
    print_info "Consuming ${count} messages from '${topic}' with group '${group}'"
    docker exec "${KAFKA_CONTAINER}" kafka-console-consumer \
        --bootstrap-server "${KAFKA_BOOTSTRAP}" \
        --topic "${topic}" \
        --group "${group}" \
        --from-beginning \
        --max-messages "${count}" \
        --timeout-ms 10000 >/dev/null 2>&1
}

kafka_describe_group() {
    local group="$1"
    docker exec "${KAFKA_CONTAINER}" kafka-consumer-groups \
        --bootstrap-server "${KAFKA_BOOTSTRAP}" \
        --group "${group}" --describe
}
