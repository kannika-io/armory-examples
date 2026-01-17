#!/bin/bash
# Environment configuration helpers

__env_file() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo "${script_dir}/../.env"
}

__env_generate() {
    local env_file="$(__env_file)"
    cat > "${env_file}" << 'EOF'
ARMORY_CONSOLE_PORT=8080
ARMORY_API_PORT=8081
KAFKA_SOURCE_CONSOLE_PORT=8180
KAFKA_TARGET_CONSOLE_PORT=8181
EOF
}

__env_load() {
    local env_file="$(__env_file)"
    [ ! -f "${env_file}" ] && __env_generate
    source "${env_file}"
}
