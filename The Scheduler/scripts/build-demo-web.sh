#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="${DEMO_ENV_FILE:-$ROOT_DIR/.env.demo.web.local}"

if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

require_value() {
  local key="$1"
  local value="${!key:-}"
  if [ -z "$value" ]; then
    echo "ERROR: $key is required."
    if [ ! -f "$ENV_FILE" ]; then
      echo "Copy .env.demo.web.local.example to .env.demo.web.local or export the required vars first."
    else
      echo "Update $ENV_FILE with the required demo Firebase values."
    fi
    exit 1
  fi
}

require_value "DEMO_BUSINESS_ID"
require_value "DEMO_FIREBASE_API_KEY"
require_value "DEMO_FIREBASE_AUTH_DOMAIN"
require_value "DEMO_FIREBASE_PROJECT_ID"
require_value "DEMO_FIREBASE_STORAGE_BUCKET"
require_value "DEMO_FIREBASE_MESSAGING_SENDER_ID"
require_value "DEMO_FIREBASE_APP_ID"

echo "Building Scheduler web demo..."

BUILD_ARGS=(
  "build"
  "web"
  "--release"
  "--dart-define=DEMO_MODE=true"
  "--dart-define=DEMO_BUSINESS_ID=${DEMO_BUSINESS_ID}"
  "--dart-define=DEMO_FIREBASE_API_KEY=${DEMO_FIREBASE_API_KEY}"
  "--dart-define=DEMO_FIREBASE_AUTH_DOMAIN=${DEMO_FIREBASE_AUTH_DOMAIN}"
  "--dart-define=DEMO_FIREBASE_PROJECT_ID=${DEMO_FIREBASE_PROJECT_ID}"
  "--dart-define=DEMO_FIREBASE_STORAGE_BUCKET=${DEMO_FIREBASE_STORAGE_BUCKET}"
  "--dart-define=DEMO_FIREBASE_MESSAGING_SENDER_ID=${DEMO_FIREBASE_MESSAGING_SENDER_ID}"
  "--dart-define=DEMO_FIREBASE_APP_ID=${DEMO_FIREBASE_APP_ID}"
)

if [ -n "${DEMO_SIGN_UP_URL:-}" ]; then
  BUILD_ARGS+=("--dart-define=DEMO_SIGN_UP_URL=${DEMO_SIGN_UP_URL}")
fi

if [ -n "${CRM_PORTAL_BASE_URL:-}" ]; then
  BUILD_ARGS+=("--dart-define=CRM_PORTAL_BASE_URL=${CRM_PORTAL_BASE_URL}")
fi

if [ -n "${ADMIN_PORTAL_BASE_URL:-}" ]; then
  BUILD_ARGS+=("--dart-define=ADMIN_PORTAL_BASE_URL=${ADMIN_PORTAL_BASE_URL}")
fi

if [ -n "${DEMO_FIREBASE_DATABASE_URL:-}" ]; then
  BUILD_ARGS+=("--dart-define=DEMO_FIREBASE_DATABASE_URL=${DEMO_FIREBASE_DATABASE_URL}")
fi

if [ -n "${DEMO_FIREBASE_IOS_BUNDLE_ID:-}" ]; then
  BUILD_ARGS+=("--dart-define=DEMO_FIREBASE_IOS_BUNDLE_ID=${DEMO_FIREBASE_IOS_BUNDLE_ID}")
fi

if [ -n "${DEMO_FIREBASE_ANDROID_CLIENT_ID:-}" ]; then
  BUILD_ARGS+=("--dart-define=DEMO_FIREBASE_ANDROID_CLIENT_ID=${DEMO_FIREBASE_ANDROID_CLIENT_ID}")
fi

if [ -n "${DEMO_FIREBASE_IOS_CLIENT_ID:-}" ]; then
  BUILD_ARGS+=("--dart-define=DEMO_FIREBASE_IOS_CLIENT_ID=${DEMO_FIREBASE_IOS_CLIENT_ID}")
fi

(
  cd "$ROOT_DIR"
  flutter "${BUILD_ARGS[@]}"
)

BOOKING_HTML="$ROOT_DIR/build/web/public-booking.html"
if [ -f "$BOOKING_HTML" ]; then
  # The static public-booking asset ships outside the Flutter bundle, so patch
  # the generated demo artifact to the isolated demo Firebase project as well.
  perl -0pi -e "s|apiKey: \".*?\"|apiKey: \"$DEMO_FIREBASE_API_KEY\"|g; s|authDomain: \".*?\"|authDomain: \"$DEMO_FIREBASE_AUTH_DOMAIN\"|g; s|projectId: \".*?\"|projectId: \"$DEMO_FIREBASE_PROJECT_ID\"|g; s|storageBucket: \".*?\"|storageBucket: \"$DEMO_FIREBASE_STORAGE_BUCKET\"|g; s|messagingSenderId: \".*?\"|messagingSenderId: \"$DEMO_FIREBASE_MESSAGING_SENDER_ID\"|g; s|appId: \".*?\"|appId: \"$DEMO_FIREBASE_APP_ID\"|g; s|databaseURL: \".*?\"|databaseURL: \"${DEMO_FIREBASE_DATABASE_URL:-}\"|g" "$BOOKING_HTML"
fi

echo "Scheduler demo build complete. Output in build/web/"
