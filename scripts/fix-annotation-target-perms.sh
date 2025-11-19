#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPOS_ROOT="${STACK_REPOS_ROOT:-$STACK_ROOT/repos}"
ANNOTATION_REPO="$REPOS_ROOT/annotation-service"
TARGET_DIR="$ANNOTATION_REPO/target"
USER_PAIR="$(id -u):$(id -g)"

if [[ ! -d "$ANNOTATION_REPO" ]]; then
  echo "annotation-service repo not found at $ANNOTATION_REPO" >&2
  echo "Set STACK_REPOS_ROOT to the directory containing your repos/ clone if needed." >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"

current_pair="$(stat -c '%u:%g' "$TARGET_DIR")"
if [[ "$current_pair" != "$USER_PAIR" ]]; then
  echo "Updating ownership of $TARGET_DIR to $USER_PAIR"
  if chown -R "$USER_PAIR" "$TARGET_DIR" 2>/dev/null; then
    :
  else
    if command -v sudo >/dev/null 2>&1; then
      sudo chown -R "$USER_PAIR" "$TARGET_DIR"
    else
      echo "Failed to change ownership. Re-run with sudo." >&2
      exit 1
    fi
  fi
fi

chmod -R u+rwX "$TARGET_DIR"
find "$TARGET_DIR" -type d -exec chmod u+rwx {} + >/dev/null 2>&1 || true

echo "Directory $TARGET_DIR is now owned by $USER_PAIR with user write permissions."
