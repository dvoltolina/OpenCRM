#!/bin/bash
# =============================================================================
# Health Check Script for The Scheduler AI Services
# Agent AI-13: Docker & Cloud Deployment
# =============================================================================
#
# Performs comprehensive health checks on all AI services.
#
# Usage:
#   ./health-check.sh [options]
#
# Examples:
#   ./health-check.sh              # Check all services
#   ./health-check.sh --local      # Check local Docker services
#   ./health-check.sh --cloud      # Check Cloud Run services
#   ./health-check.sh --verbose    # Detailed output
#
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERBOSE=false
CHECK_LOCAL=true
CHECK_CLOUD=false
TIMEOUT=10

# Service definitions
declare -A LOCAL_SERVICES=(
    ["prediction"]="http://localhost:8001/health/live"
    ["sentiment"]="http://localhost:8002/health/live"
    ["routing"]="http://localhost:8003/api/v1/health"
    ["osrm"]="http://localhost:5000/health"
    ["ollama"]="http://localhost:11434/api/tags"
)

declare -A READINESS_ENDPOINTS=(
    ["prediction"]="http://localhost:8001/health/ready"
    ["sentiment"]="http://localhost:8002/health/ready"
    ["routing"]="http://localhost:8003/api/v1/health"
)

# =============================================================================
# Utility Functions
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

log_verbose() {
    if $VERBOSE; then
        echo -e "${CYAN}[DEBUG]${NC} $1"
    fi
}

print_header() {
    echo ""
    echo "========================================"
    echo "$1"
    echo "========================================"
}

# =============================================================================
# Health Check Functions
# =============================================================================

check_endpoint() {
    local name=$1
    local url=$2
    local expected_status=${3:-200}

    log_verbose "Checking: $url"

    local response
    local http_code
    local response_time

    # Make request and capture response
    local start_time=$(date +%s%3N)

    if response=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT" "$url" 2>/dev/null); then
        http_code=$response
    else
        http_code="000"
    fi

    local end_time=$(date +%s%3N)
    response_time=$((end_time - start_time))

    # Evaluate result
    if [[ "$http_code" == "$expected_status" ]]; then
        log_success "$name: OK (${response_time}ms)"
        return 0
    elif [[ "$http_code" == "000" ]]; then
        log_error "$name: Connection failed"
        return 1
    else
        log_error "$name: HTTP $http_code (expected $expected_status)"
        return 1
    fi
}

check_docker_container() {
    local container_name=$1

    local status=$(docker inspect -f '{{.State.Status}}' "$container_name" 2>/dev/null || echo "not_found")
    local health=$(docker inspect -f '{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "unknown")

    if [[ "$status" == "running" ]]; then
        if [[ "$health" == "healthy" ]]; then
            log_success "$container_name: running (healthy)"
            return 0
        elif [[ "$health" == "unhealthy" ]]; then
            log_error "$container_name: running (unhealthy)"
            return 1
        else
            log_warning "$container_name: running (no health check)"
            return 0
        fi
    elif [[ "$status" == "not_found" ]]; then
        log_error "$container_name: not found"
        return 1
    else
        log_error "$container_name: $status"
        return 1
    fi
}

check_local_services() {
    print_header "Local Docker Services"

    local all_passed=true

    # Check Docker daemon
    if ! docker info &> /dev/null; then
        log_error "Docker daemon not running"
        return 1
    fi

    # Check containers
    echo ""
    echo "Container Status:"
    for container in scheduler-prediction scheduler-sentiment scheduler-routing scheduler-osrm scheduler-ollama; do
        if ! check_docker_container "$container"; then
            all_passed=false
        fi
    done

    # Check health endpoints
    echo ""
    echo "Health Endpoints:"
    for service in "${!LOCAL_SERVICES[@]}"; do
        if ! check_endpoint "$service" "${LOCAL_SERVICES[$service]}"; then
            all_passed=false
        fi
    done

    # Check readiness
    echo ""
    echo "Readiness Status:"
    for service in "${!READINESS_ENDPOINTS[@]}"; do
        if ! check_endpoint "${service} (ready)" "${READINESS_ENDPOINTS[$service]}"; then
            all_passed=false
        fi
    done

    if $all_passed; then
        return 0
    else
        return 1
    fi
}

check_cloud_services() {
    print_header "Cloud Run Services"

    local all_passed=true

    # Check if gcloud is available
    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud CLI not installed"
        return 1
    fi

    # Get project ID
    local project_id="${GCP_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"
    local region="${GCP_REGION:-us-central1}"

    if [[ -z "$project_id" ]]; then
        log_error "GCP project not configured"
        return 1
    fi

    log_info "Project: $project_id, Region: $region"
    echo ""

    # Check prediction service
    local prediction_url=$(gcloud run services describe scheduler-prediction \
        --project="$project_id" \
        --region="$region" \
        --format="value(status.url)" 2>/dev/null || echo "")

    if [[ -n "$prediction_url" ]]; then
        check_endpoint "prediction (Cloud Run)" "${prediction_url}/health/live" || all_passed=false
    else
        log_error "prediction: not deployed"
        all_passed=false
    fi

    # Check routing service
    local routing_url=$(gcloud run services describe scheduler-routing \
        --project="$project_id" \
        --region="$region" \
        --format="value(status.url)" 2>/dev/null || echo "")

    if [[ -n "$routing_url" ]]; then
        check_endpoint "routing (Cloud Run)" "${routing_url}/api/v1/health" || all_passed=false
    else
        log_error "routing: not deployed"
        all_passed=false
    fi

    if $all_passed; then
        return 0
    else
        return 1
    fi
}

check_model_availability() {
    print_header "Model Availability"

    local all_passed=true

    # Check prediction model
    local prediction_model_check=$(curl -s "http://localhost:8001/health/ready" 2>/dev/null | grep -c '"model_loaded":true' || echo "0")
    if [[ "$prediction_model_check" -gt 0 ]]; then
        log_success "Prediction model: loaded"
    else
        log_warning "Prediction model: not loaded or endpoint unavailable"
    fi

    # Check Ollama models
    local ollama_models=$(curl -s "http://localhost:11434/api/tags" 2>/dev/null | grep -o '"name":"[^"]*"' | cut -d'"' -f4 || echo "")

    if [[ -n "$ollama_models" ]]; then
        echo "Ollama models available:"
        echo "$ollama_models" | while read -r model; do
            log_success "  - $model"
        done
    else
        log_warning "No Ollama models found or Ollama unavailable"
    fi

    return 0
}

check_network_connectivity() {
    print_header "Network Connectivity"

    local all_passed=true

    # Check internal network
    echo "Docker Network:"

    local network_exists=$(docker network ls --filter name=scheduler-ai-network --format "{{.Name}}" 2>/dev/null)
    if [[ -n "$network_exists" ]]; then
        log_success "scheduler-ai-network: exists"

        # Check connected containers
        local connected=$(docker network inspect scheduler-ai-network --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null || echo "")
        if [[ -n "$connected" ]]; then
            log_info "Connected: $connected"
        fi
    else
        log_error "scheduler-ai-network: not found"
        all_passed=false
    fi

    echo ""
    echo "Inter-service Communication:"

    # Test prediction -> internal (should work)
    log_verbose "Testing internal network..."

    if $all_passed; then
        return 0
    else
        return 1
    fi
}

generate_report() {
    print_header "Health Check Summary"

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "Timestamp: $timestamp"
    echo ""

    local total=0
    local passed=0

    # Run all checks and count results
    if $CHECK_LOCAL; then
        check_local_services && ((passed++)) || true
        ((total++))

        check_model_availability && ((passed++)) || true
        ((total++))

        check_network_connectivity && ((passed++)) || true
        ((total++))
    fi

    if $CHECK_CLOUD; then
        check_cloud_services && ((passed++)) || true
        ((total++))
    fi

    echo ""
    echo "========================================"
    if [[ $passed -eq $total ]]; then
        echo -e "${GREEN}All checks passed ($passed/$total)${NC}"
        return 0
    else
        echo -e "${RED}Some checks failed ($passed/$total passed)${NC}"
        return 1
    fi
}

# =============================================================================
# Main Script
# =============================================================================

show_usage() {
    cat << EOF
Health Check Script for The Scheduler AI Services

Usage: $0 [options]

Options:
  --local             Check local Docker services (default)
  --cloud             Check Cloud Run services
  --all               Check both local and cloud
  --verbose, -v       Show detailed output
  --timeout=SECONDS   Request timeout (default: 10)
  --json              Output as JSON (for monitoring integration)
  --help, -h          Show this help message

Examples:
  $0                  # Check local services
  $0 --cloud          # Check Cloud Run services
  $0 --all --verbose  # Check everything with details

EOF
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --local)
                CHECK_LOCAL=true
                CHECK_CLOUD=false
                shift
                ;;
            --cloud)
                CHECK_LOCAL=false
                CHECK_CLOUD=true
                shift
                ;;
            --all)
                CHECK_LOCAL=true
                CHECK_CLOUD=true
                shift
                ;;
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --timeout=*)
                TIMEOUT="${1#*=}"
                shift
                ;;
            --json)
                # TODO: Implement JSON output
                log_warning "JSON output not yet implemented"
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                ;;
        esac
    done

    echo "========================================"
    echo "The Scheduler AI Services Health Check"
    echo "========================================"

    # Run health checks
    local exit_code=0

    if $CHECK_LOCAL; then
        check_local_services || exit_code=1
        check_model_availability || true
        check_network_connectivity || exit_code=1
    fi

    if $CHECK_CLOUD; then
        check_cloud_services || exit_code=1
    fi

    # Summary
    echo ""
    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}========================================"
        echo "All health checks passed"
        echo -e "========================================${NC}"
    else
        echo -e "${RED}========================================"
        echo "Some health checks failed"
        echo -e "========================================${NC}"
    fi

    exit $exit_code
}

main "$@"
