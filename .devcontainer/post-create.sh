#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

FRONTEND_DIR="$ROOT_DIR/repos/annotation-service/frontend"
BACKEND_DIR="$ROOT_DIR/repos/annotation-service/backend"

if [ -d "$FRONTEND_DIR" ] && [ -f "$FRONTEND_DIR/package.json" ]; then
  echo "Installing frontend dependencies..."
  pushd "$FRONTEND_DIR" >/dev/null
  npm install
  popd >/dev/null
else
  echo "Skipping frontend install; $FRONTEND_DIR not found."
fi

if [ -d "$BACKEND_DIR" ] && [ -f "$BACKEND_DIR/mvnw" ]; then
  echo "Priming Maven cache..."
  pushd "$BACKEND_DIR" >/dev/null
  ./mvnw -Pdev -DskipTests compile
  popd >/dev/null
else
  echo "Skipping backend compile; $BACKEND_DIR not found."
fi

echo "Post-create setup complete."
