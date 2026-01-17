#!/bin/bash
# Environment configuration helpers

__env_repo_root() {
    (cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
}

__env_file() {
    echo "$(__env_repo_root)/.env"
}

__env_bin_dir() {
    echo "$(__env_repo_root)/.bin"
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

__env_setup_path() {
    local bin_dir="$(__env_bin_dir)"
    if [ -d "${bin_dir}" ]; then
        export PATH="${bin_dir}:${PATH}"
    fi
}

__env_load() {
    local env_file="$(__env_file)"
    [ ! -f "${env_file}" ] && __env_generate
    source "${env_file}"
    __env_setup_path
}
