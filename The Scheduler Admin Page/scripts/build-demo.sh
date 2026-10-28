#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="${DEMO_ENV_FILE:-$ROOT_DIR/.env.demo.local}"

require_line() {
  local pattern="$1"
  local message="$2"
  if ! grep -Eq "$pattern" "$ENV_FILE"; then
    echo "ERROR: $message"
    exit 1
  fi
}

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: $ENV_FILE not found."
  echo "Copy .env.demo.local.example to .env.demo.local and fill in the demo Firebase values."
  exit 1
fi

require_line '^VITE_DEMO_MODE=true$' "VITE_DEMO_MODE=true is required in $ENV_FILE"
require_line '^VITE_DEMO_BUSINESS_ID=.+$' "VITE_DEMO_BUSINESS_ID is required in $ENV_FILE"
require_line '^VITE_DEMO_FIREBASE_API_KEY=.+$' "VITE_DEMO_FIREBASE_API_KEY is required in $ENV_FILE"
require_line '^VITE_DEMO_FIREBASE_AUTH_DOMAIN=.+$' "VITE_DEMO_FIREBASE_AUTH_DOMAIN is required in $ENV_FILE"
require_line '^VITE_DEMO_FIREBASE_PROJECT_ID=.+$' "VITE_DEMO_FIREBASE_PROJECT_ID is required in $ENV_FILE"
require_line '^VITE_DEMO_FIREBASE_STORAGE_BUCKET=.+$' "VITE_DEMO_FIREBASE_STORAGE_BUCKET is required in $ENV_FILE"
require_line '^VITE_DEMO_FIREBASE_MESSAGING_SENDER_ID=.+$' "VITE_DEMO_FIREBASE_MESSAGING_SENDER_ID is required in $ENV_FILE"
require_line '^VITE_DEMO_FIREBASE_APP_ID=.+$' "VITE_DEMO_FIREBASE_APP_ID is required in $ENV_FILE"

echo "Building Admin Dashboard in demo mode with $ENV_FILE..."
(
  cd "$ROOT_DIR"
  npx vite build --mode demo
)

echo "Admin demo build complete. Output in dist/"
