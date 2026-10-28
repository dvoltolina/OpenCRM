#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRM_DIR="$(dirname "$SCRIPT_DIR")"
WORKSPACE_DIR="$(dirname "$CRM_DIR")"
ADMIN_DIR="$WORKSPACE_DIR/The Scheduler Admin Page"
SCHEDULER_DIR="$WORKSPACE_DIR/The Scheduler"
MARKETING_DIR="$WORKSPACE_DIR/Scheduler Website Home page"
CRM_ENV_FILE="${DEMO_ENV_FILE:-$CRM_DIR/.env.demo.local}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: required command not found: $1"
    exit 1
  fi
}

require_directory() {
  if [ ! -d "$1" ]; then
    echo "ERROR: required directory not found: $1"
    exit 1
  fi
}

read_env_value() {
  local file="$1"
  local key="$2"
  awk -F= -v key="$key" '$1 == key { print substr($0, index($0, "=") + 1); exit }' "$file"
}

require_real_value() {
  local value="$1"
  local key="$2"
  local placeholder="$3"

  if [ -z "$value" ]; then
    echo "ERROR: $key is required."
    exit 1
  fi

  if [ "$value" = "$placeholder" ]; then
    echo "ERROR: $key still uses the example placeholder value: $placeholder"
    echo "Update the demo env files with the real demo Firebase project configuration before deploying."
    exit 1
  fi
}

require_command "firebase"
require_command "bash"
require_command "npx"
require_directory "$ADMIN_DIR"
require_directory "$SCHEDULER_DIR"
require_directory "$MARKETING_DIR"

if [ ! -f "$CRM_ENV_FILE" ]; then
  echo "ERROR: CRM demo env file not found: $CRM_ENV_FILE"
  echo "Copy .env.demo.local.example to .env.demo.local before deploying demos."
  exit 1
fi

DEMO_PROJECT_ID="${DEMO_FIREBASE_PROJECT_ID:-$(read_env_value "$CRM_ENV_FILE" "VITE_DEMO_FIREBASE_PROJECT_ID")}"
DEMO_BUSINESS_ID="${DEMO_BUSINESS_ID:-$(read_env_value "$CRM_ENV_FILE" "VITE_DEMO_BUSINESS_ID")}"
DEMO_OWNER_EMAIL="${DEMO_OWNER_EMAIL:-$(read_env_value "$CRM_ENV_FILE" "VITE_DEMO_USER_EMAIL")}"
DEMO_OWNER_UID="${DEMO_OWNER_UID:-demo-user-001}"

if [ -z "$DEMO_PROJECT_ID" ]; then
  echo "ERROR: DEMO_FIREBASE_PROJECT_ID is required."
  echo "Set it in the environment or in $CRM_ENV_FILE as VITE_DEMO_FIREBASE_PROJECT_ID."
  exit 1
fi

if [ -z "$DEMO_BUSINESS_ID" ]; then
  echo "ERROR: DEMO_BUSINESS_ID is required."
  echo "Set it in the environment or in $CRM_ENV_FILE as VITE_DEMO_BUSINESS_ID."
  exit 1
fi

if [ -z "$DEMO_OWNER_EMAIL" ]; then
  echo "ERROR: DEMO_OWNER_EMAIL is required."
  echo "Set it in the environment or in $CRM_ENV_FILE as VITE_DEMO_USER_EMAIL."
  exit 1
fi

require_real_value "$DEMO_PROJECT_ID" "DEMO_FIREBASE_PROJECT_ID" "demo-project-id"
require_real_value "$(read_env_value "$CRM_ENV_FILE" "VITE_DEMO_FIREBASE_API_KEY")" "VITE_DEMO_FIREBASE_API_KEY" "demo-public-api-key"
require_real_value "$(read_env_value "$CRM_ENV_FILE" "VITE_DEMO_FIREBASE_AUTH_DOMAIN")" "VITE_DEMO_FIREBASE_AUTH_DOMAIN" "demo-project.firebaseapp.com"
require_real_value "$(read_env_value "$CRM_ENV_FILE" "VITE_DEMO_FIREBASE_STORAGE_BUCKET")" "VITE_DEMO_FIREBASE_STORAGE_BUCKET" "demo-project.appspot.com"
require_real_value "$(read_env_value "$CRM_ENV_FILE" "VITE_DEMO_FIREBASE_MESSAGING_SENDER_ID")" "VITE_DEMO_FIREBASE_MESSAGING_SENDER_ID" "1234567890"
require_real_value "$(read_env_value "$CRM_ENV_FILE" "VITE_DEMO_FIREBASE_APP_ID")" "VITE_DEMO_FIREBASE_APP_ID" ""

echo "=== Deploying demo instances to Firebase project: $DEMO_PROJECT_ID ==="

echo "1/6 Deploying read-only Firestore rules..."
(
  cd "$CRM_DIR"
  firebase deploy --config firebase-demo.json --only firestore:rules --project "$DEMO_PROJECT_ID"
)

echo "2/6 Ensuring demo data is seeded..."
if [ "${DEMO_SKIP_SEED:-false}" = "true" ]; then
  echo "Skipping demo seed because DEMO_SKIP_SEED=true."
else
  if [ -z "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]; then
    echo "ERROR: GOOGLE_APPLICATION_CREDENTIALS is required to seed the demo tenant."
    echo "Set DEMO_SKIP_SEED=true only if the demo Firebase project is already seeded."
    exit 1
  fi

  (
    cd "$CRM_DIR"
    DEMO_FIREBASE_PROJECT_ID="$DEMO_PROJECT_ID" \
    DEMO_BUSINESS_ID="$DEMO_BUSINESS_ID" \
    DEMO_OWNER_UID="$DEMO_OWNER_UID" \
    DEMO_OWNER_EMAIL="$DEMO_OWNER_EMAIL" \
    npx tsx scripts/seed-demo-data.ts
  )
fi

echo "3/6 Building CRM demo..."
DEMO_ENV_FILE="$CRM_ENV_FILE" bash "$CRM_DIR/scripts/build-demo.sh"

echo "4/6 Building Admin demo..."
(
  cd "$ADMIN_DIR"
  DEMO_ENV_FILE="$ADMIN_DIR/.env.demo.local" bash scripts/build-demo.sh
)

echo "5/6 Building Scheduler demo..."
(
  cd "$SCHEDULER_DIR"
  DEMO_ENV_FILE="$SCHEDULER_DIR/.env.demo.web.local" bash scripts/build-demo-web.sh
)

echo "6/6 Deploying demo hosting sites..."
(
  cd "$CRM_DIR"
  firebase deploy --config firebase-demo.json --only hosting --project "$DEMO_PROJECT_ID"
)
(
  cd "$ADMIN_DIR"
  firebase deploy --config firebase-demo.json --only hosting --project "$DEMO_PROJECT_ID"
)
(
  cd "$SCHEDULER_DIR"
  firebase deploy --config firebase-demo.json --only hosting --project "$DEMO_PROJECT_ID"
)
(
  cd "$MARKETING_DIR"
  firebase deploy --config firebase-demo.json --only hosting --project "$DEMO_PROJECT_ID"
)

echo "=== Demo deployment complete ==="
