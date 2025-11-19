#!/bin/bash
# OpenRefine Management Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/configs/openrefine/docker-compose.yml"
export STACK_REPOS_ROOT="${STACK_REPOS_ROOT:-$SCRIPT_DIR}"

# Run docker compose
docker compose -f "$COMPOSE_FILE" "$@"
