#!/bin/bash
# =============================================================================
# Cloud Run Deployment Script for The Scheduler AI Services
# Agent AI-13: Docker & Cloud Deployment
# =============================================================================
#
# Usage:
#   ./deploy.sh [service] [environment]
#
# Examples:
#   ./deploy.sh prediction prod     # Deploy prediction to production
#   ./deploy.sh routing staging     # Deploy routing to staging
#   ./deploy.sh all prod            # Deploy all services to production
#
# Prerequisites:
#   1. gcloud CLI installed and authenticated
#   2. Docker installed (for building images)
#   3. Required secrets created in Secret Manager
#   4. Service account created with appropriate permissions
#
# Required Secrets (create in Secret Manager):
#   - prediction-api-keys
#   - routing-api-key
#   - cors-allowed-origins
#   - osrm-url
#
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Default values (override via environment or .env file)
PROJECT_ID="${GCP_PROJECT_ID:-}"
REGION="${GCP_REGION:-us-central1}"
CONTAINER_REGISTRY="${CONTAINER_REGISTRY:-gcr.io/${PROJECT_ID}}"
VERSION="${VERSION:-$(git rev-parse --short HEAD 2>/dev/null || echo 'latest')}"

# =============================================================================
# Utility Functions
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check gcloud
    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud CLI not found. Install from: https://cloud.google.com/sdk/docs/install"
    fi

    # Check docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker not found. Install from: https://docs.docker.com/get-docker/"
    fi

    # Check project ID
    if [[ -z "$PROJECT_ID" ]]; then
        log_error "GCP_PROJECT_ID not set. Export it or set in .env file"
    fi

    # Verify gcloud auth
    if ! gcloud auth print-identity-token &> /dev/null; then
        log_error "Not authenticated with gcloud. Run: gcloud auth login"
    fi

    log_success "All prerequisites met"
}

load_env() {
    local env_file="$PROJECT_ROOT/.env"
    if [[ -f "$env_file" ]]; then
        log_info "Loading environment from .env file..."
        set -a
        source "$env_file"
        set +a
    fi
}

# =============================================================================
# Build Functions
# =============================================================================

build_image() {
    local service=$1
    local image_tag="${CONTAINER_REGISTRY}/scheduler-${service}:${VERSION}"

    log_info "Building ${service} image: ${image_tag}"

    docker build \
        -t "$image_tag" \
        -t "${CONTAINER_REGISTRY}/scheduler-${service}:latest" \
        -f "$PROJECT_ROOT/${service}/Dockerfile" \
        "$PROJECT_ROOT/${service}"

    log_success "Built ${service} image"
}

push_image() {
    local service=$1
    local image_tag="${CONTAINER_REGISTRY}/scheduler-${service}:${VERSION}"

    log_info "Pushing ${service} image to registry..."

    # Configure docker for gcr.io
    gcloud auth configure-docker gcr.io --quiet

    docker push "$image_tag"
    docker push "${CONTAINER_REGISTRY}/scheduler-${service}:latest"

    log_success "Pushed ${service} image"
}

# =============================================================================
# Deployment Functions
# =============================================================================

create_secrets_if_missing() {
    log_info "Checking required secrets..."

    local secrets=(
        "prediction-api-keys"
        "routing-api-key"
        "cors-allowed-origins"
        "osrm-url"
    )

    for secret in "${secrets[@]}"; do
        if ! gcloud secrets describe "$secret" --project="$PROJECT_ID" &> /dev/null; then
            log_warning "Secret '$secret' not found. Creating placeholder..."
            echo "PLACEHOLDER_VALUE" | gcloud secrets create "$secret" \
                --project="$PROJECT_ID" \
                --data-file=- \
                --replication-policy="automatic"
            log_warning "Please update secret '$secret' with actual value"
        fi
    done
}

setup_service_account() {
    local sa_name="scheduler-ai-services"
    local sa_email="${sa_name}@${PROJECT_ID}.iam.gserviceaccount.com"

    log_info "Setting up service account..."

    # Create service account if it doesn't exist
    if ! gcloud iam service-accounts describe "$sa_email" --project="$PROJECT_ID" &> /dev/null; then
        gcloud iam service-accounts create "$sa_name" \
            --project="$PROJECT_ID" \
            --display-name="Scheduler AI Services"
    fi

    # Grant necessary roles
    local roles=(
        "roles/secretmanager.secretAccessor"
        "roles/logging.logWriter"
        "roles/monitoring.metricWriter"
    )

    for role in "${roles[@]}"; do
        gcloud projects add-iam-policy-binding "$PROJECT_ID" \
            --member="serviceAccount:${sa_email}" \
            --role="$role" \
            --quiet
    done

    log_success "Service account configured"
}

deploy_service() {
    local service=$1
    local yaml_file="$SCRIPT_DIR/${service}-service.yaml"

    if [[ ! -f "$yaml_file" ]]; then
        log_error "Service configuration not found: $yaml_file"
    fi

    log_info "Deploying ${service} service to Cloud Run..."

    # Substitute environment variables in YAML
    local temp_yaml=$(mktemp)
    envsubst < "$yaml_file" > "$temp_yaml"

    # Deploy to Cloud Run
    gcloud run services replace "$temp_yaml" \
        --project="$PROJECT_ID" \
        --region="$REGION" \
        --quiet

    rm "$temp_yaml"

    # Get service URL
    local url=$(gcloud run services describe "scheduler-${service}" \
        --project="$PROJECT_ID" \
        --region="$REGION" \
        --format="value(status.url)")

    log_success "Deployed ${service} service: $url"
}

deploy_prediction() {
    build_image "prediction"
    push_image "prediction"
    deploy_service "prediction"
}

deploy_routing() {
    build_image "routing"
    push_image "routing"
    deploy_service "routing"
}

deploy_all() {
    log_info "Deploying all services..."
    deploy_prediction
    deploy_routing
    log_success "All services deployed"
}

# =============================================================================
# Health Check Functions
# =============================================================================

check_service_health() {
    local service=$1

    local url=$(gcloud run services describe "scheduler-${service}" \
        --project="$PROJECT_ID" \
        --region="$REGION" \
        --format="value(status.url)" 2>/dev/null)

    if [[ -z "$url" ]]; then
        log_warning "${service} service not deployed"
        return 1
    fi

    local health_path="/health/live"
    [[ "$service" == "routing" ]] && health_path="/api/v1/health"

    local response=$(curl -s -o /dev/null -w "%{http_code}" "${url}${health_path}" --max-time 10)

    if [[ "$response" == "200" ]]; then
        log_success "${service}: healthy (${url})"
        return 0
    else
        log_warning "${service}: unhealthy (HTTP ${response})"
        return 1
    fi
}

check_all_health() {
    log_info "Checking service health..."
    local all_healthy=true

    for service in prediction routing; do
        if ! check_service_health "$service"; then
            all_healthy=false
        fi
    done

    if $all_healthy; then
        log_success "All services healthy"
    else
        log_warning "Some services are unhealthy"
    fi
}

# =============================================================================
# Main Script
# =============================================================================

show_usage() {
    cat << EOF
Usage: $0 [command] [options]

Commands:
  prediction        Build and deploy prediction service
  routing           Build and deploy routing service
  all               Deploy all services
  health            Check health of all services
  setup             Initial setup (secrets, service account)
  build <service>   Build image only (no deploy)
  push <service>    Push image only (no deploy)

Options:
  --project=ID      GCP project ID (or set GCP_PROJECT_ID)
  --region=REGION   GCP region (default: us-central1)
  --version=TAG     Image version tag (default: git commit hash)
  --help            Show this help message

Environment Variables:
  GCP_PROJECT_ID    Google Cloud project ID
  GCP_REGION        Google Cloud region
  CONTAINER_REGISTRY Container registry URL
  VERSION           Image version tag

Examples:
  $0 prediction                  # Deploy prediction service
  $0 all                         # Deploy all services
  $0 health                      # Check service health
  $0 build prediction            # Build prediction image only
  $0 --project=my-project all    # Deploy with specific project

EOF
}

main() {
    # Parse arguments
    local command=""
    local sub_command=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --project=*)
                PROJECT_ID="${1#*=}"
                shift
                ;;
            --region=*)
                REGION="${1#*=}"
                shift
                ;;
            --version=*)
                VERSION="${1#*=}"
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                if [[ -z "$command" ]]; then
                    command="$1"
                else
                    sub_command="$1"
                fi
                shift
                ;;
        esac
    done

    # Load environment
    load_env

    # Update registry with project ID
    CONTAINER_REGISTRY="${CONTAINER_REGISTRY:-gcr.io/${PROJECT_ID}}"

    # Execute command
    case "$command" in
        prediction)
            check_prerequisites
            deploy_prediction
            ;;
        routing)
            check_prerequisites
            deploy_routing
            ;;
        all)
            check_prerequisites
            setup_service_account
            create_secrets_if_missing
            deploy_all
            ;;
        health)
            check_all_health
            ;;
        setup)
            check_prerequisites
            setup_service_account
            create_secrets_if_missing
            log_success "Setup complete"
            ;;
        build)
            [[ -z "$sub_command" ]] && log_error "Specify service to build"
            build_image "$sub_command"
            ;;
        push)
            [[ -z "$sub_command" ]] && log_error "Specify service to push"
            check_prerequisites
            push_image "$sub_command"
            ;;
        "")
            show_usage
            exit 0
            ;;
        *)
            log_error "Unknown command: $command"
            ;;
    esac
}

# Export variables for envsubst
export PROJECT_ID REGION CONTAINER_REGISTRY VERSION

main "$@"
