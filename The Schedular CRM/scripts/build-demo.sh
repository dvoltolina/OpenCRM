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

read_env_value() {
  local key="$1"
  awk -F= -v key="$key" '$1 == key { print substr($0, index($0, "=") + 1); exit }' "$ENV_FILE"
}

require_real_value() {
  local key="$1"
  local placeholder="$2"
  local value
  value="$(read_env_value "$key")"

  if [ -z "$value" ]; then
    echo "ERROR: $key is required in $ENV_FILE"
    exit 1
  fi

  if [ "$value" = "$placeholder" ]; then
    echo "ERROR: $key still uses the example placeholder value in $ENV_FILE"
    echo "Replace $placeholder with the real demo Firebase value before building."
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

require_real_value 'VITE_DEMO_FIREBASE_API_KEY' 'demo-public-api-key'
require_real_value 'VITE_DEMO_FIREBASE_AUTH_DOMAIN' 'demo-project.firebaseapp.com'
require_real_value 'VITE_DEMO_FIREBASE_PROJECT_ID' 'demo-project-id'
require_real_value 'VITE_DEMO_FIREBASE_STORAGE_BUCKET' 'demo-project.appspot.com'
require_real_value 'VITE_DEMO_FIREBASE_MESSAGING_SENDER_ID' '1234567890'
require_real_value 'VITE_DEMO_FIREBASE_APP_ID' ''

if grep -Eq '^VITE_FUNCTIONS_BASE_URL=.+$' "$ENV_FILE"; then
  echo "WARNING: VITE_FUNCTIONS_BASE_URL is set in $ENV_FILE."
  echo "         Confirm it targets demo infrastructure only before shipping this build."
fi

if grep -Eq '^VITE_REPORTING_ENDPOINT_URL=.+$' "$ENV_FILE"; then
  echo "WARNING: VITE_REPORTING_ENDPOINT_URL is set in $ENV_FILE."
  echo "         Confirm it targets demo infrastructure only before shipping this build."
fi

echo "Building CRM in demo mode with $ENV_FILE..."
(
  cd "$ROOT_DIR"
  npx tsc -b
  npx vite build --mode demo
)

echo "CRM demo build complete. Output in dist/"
