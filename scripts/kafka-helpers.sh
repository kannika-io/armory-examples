#!/bin/bash
# Reusable Kafka helper functions for tutorials
# Source this file: source scripts/kafka-helpers.sh
#
# All functions take container name as first parameter (e.g., kafka-source, kafka-target).
# Bootstrap is derived as: ${container}:29092

print_info() { echo -e "\033[0;32m[INFO]\033[0m $1"; }
print_error() { echo -e "\033[0;31m[ERROR]\033[0m $1" >&2; }

kafka_check() {
    local container="$1"
    [[ -z "$container" ]] && { print_error "Usage: kafka_check <container>"; return 1; }
    docker ps --format '{{.Names}}' | grep -q "^${container}$" || {
        print_error "Kafka container '${container}' not running. Start with: docker-compose up -d"
        return 1
    }
}

kafka_create_topic() {
    local container="$1" topic="$2" partitions="${3:-1}"
    [[ -z "$container" || -z "$topic" ]] && { print_error "Usage: kafka_create_topic <container> <topic> [partitions]"; return 1; }
    local bootstrap="${container}:29092"
    print_info "Creating topic: ${topic} on ${container}"
    docker exec "${container}" kafka-topics \
        --bootstrap-server "${bootstrap}" \
        --create --topic "${topic}" \
        --partitions "${partitions}" \
        --replication-factor 1 \
        --if-not-exists
}

kafka_delete_topic() {
    local container="$1" topic="$2"
    [[ -z "$container" || -z "$topic" ]] && { print_error "Usage: kafka_delete_topic <container> <topic>"; return 1; }
    local bootstrap="${container}:29092"
    docker exec "${container}" kafka-topics \
        --bootstrap-server "${bootstrap}" \
        --delete --topic "${topic}" --if-exists 2>/dev/null || true
}

kafka_produce() {
    local container="$1" topic="$2" key="$3" value="$4"
    [[ -z "$container" || -z "$topic" ]] && { print_error "Usage: kafka_produce <container> <topic> <key> <value>"; return 1; }
    kafka_check "${container}" || return 1
    local bootstrap="${container}:29092"
    echo "${key}:${value}" | docker exec -i "${container}" kafka-console-producer \
        --bootstrap-server "${bootstrap}" \
        --topic "${topic}" \
        --property "parse.key=true" \
        --property "key.separator=:" || { print_error "Failed to produce message to ${topic}"; return 1; }
}

kafka_produce_batch() {
    local container="$1" topic="$2" count="$3" value="$4"
    [[ -z "$container" || -z "$topic" || -z "$count" ]] && { print_error "Usage: kafka_produce_batch <container> <topic> <count> <value>"; return 1; }
    kafka_check "${container}" || return 1
    local bootstrap="${container}:29092"
    print_info "Producing ${count} messages to ${topic}"
    seq 1 "${count}" | while read i; do echo "${i}:${value}"; done | \
        docker exec -i "${container}" kafka-console-producer \
            --bootstrap-server "${bootstrap}" \
            --topic "${topic}" \
            --property "parse.key=true" \
            --property "key.separator=:" || { print_error "Failed to produce batch to ${topic}"; return 1; }
}

kafka_produce_jsonl() {
    local container="$1" topic="$2" file="$3"
    [[ -z "$container" || -z "$topic" || -z "$file" ]] && { print_error "Usage: kafka_produce_jsonl <container> <topic> <file>"; return 1; }
    [ -f "${file}" ] || { print_error "File not found: ${file}"; return 1; }
    print_info "Producing messages to ${topic}"
    while IFS= read -r line || [ -n "$line" ]; do
        [ -z "$line" ] && continue
        local key value
        key=$(echo "$line" | jq -r '.key')
        value=$(echo "$line" | jq -c '.value')
        kafka_produce "${container}" "${topic}" "${key}" "${value}"
    done < "${file}"
}

kafka_consume() {
    local container="$1" group="$2" topic="$3" count="$4"
    [[ -z "$container" || -z "$group" || -z "$topic" || -z "$count" ]] && { print_error "Usage: kafka_consume <container> <group> <topic> <count>"; return 1; }
    local bootstrap="${container}:29092"
    print_info "Consuming ${count} messages from '${topic}' with group '${group}'"
    docker exec "${container}" kafka-console-consumer \
        --bootstrap-server "${bootstrap}" \
        --topic "${topic}" \
        --group "${group}" \
        --from-beginning \
        --max-messages "${count}" \
        --timeout-ms 10000 >/dev/null 2>&1
}

kafka_describe_group() {
    local container="$1" group="$2"
    [[ -z "$container" || -z "$group" ]] && { print_error "Usage: kafka_describe_group <container> <group>"; return 1; }
    local bootstrap="${container}:29092"
    docker exec "${container}" kafka-consumer-groups \
        --bootstrap-server "${bootstrap}" \
        --group "${group}" --describe
}

kafka_delete_records() {
    local container="$1" topic="$2" partition="${3:-0}" offset="$4"
    [[ -z "$container" || -z "$topic" || -z "$offset" ]] && { print_error "Usage: kafka_delete_records <container> <topic> <partition> <offset>"; return 1; }
    local bootstrap="${container}:29092"
    print_info "Deleting records from ${topic} up to offset ${offset}"
    echo "{\"partitions\": [{\"topic\": \"${topic}\", \"partition\": ${partition}, \"offset\": ${offset}}], \"version\": 1}" | \
        docker exec -i "${container}" kafka-delete-records \
            --bootstrap-server "${bootstrap}" \
            --offset-json-file /dev/stdin
}
