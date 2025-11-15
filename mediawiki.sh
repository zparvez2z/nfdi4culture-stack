#!/bin/bash
# MediaWiki + Wikibase Management Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
COMPOSE_FILE="${SCRIPT_DIR}/configs/mediawiki/docker-compose.local.yml"

# Check if .env exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found at $ENV_FILE"
    echo "Please copy .env.example to .env and configure it."
    exit 1
fi

# Run docker compose with proper env file
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"
