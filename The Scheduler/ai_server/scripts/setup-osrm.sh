#!/bin/bash
# =============================================================================
# OSRM Setup Script for The Scheduler AI Services
# Agent AI-13: Docker & Cloud Deployment
# =============================================================================
#
# Downloads and processes OpenStreetMap data for OSRM routing engine.
#
# Usage:
#   ./setup-osrm.sh [region]
#
# Examples:
#   ./setup-osrm.sh us-west        # California, Nevada, Oregon, Washington
#   ./setup-osrm.sh us-california  # California only
#   ./setup-osrm.sh us-northeast   # NY, NJ, PA, CT, MA, etc.
#
# Prerequisites:
#   - Docker installed
#   - At least 20GB free disk space (varies by region)
#   - Internet connection for downloading OSM data
#
# Data Source: Geofabrik (https://download.geofabrik.de)
#
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${SCRIPT_DIR}/../data/osrm"
REGION="${1:-us-west}"

# Geofabrik URLs for different regions
declare -A REGION_URLS=(
    # US Regions
    ["us-west"]="https://download.geofabrik.de/north-america/us-west-latest.osm.pbf"
    ["us-california"]="https://download.geofabrik.de/north-america/us/california-latest.osm.pbf"
    ["us-northeast"]="https://download.geofabrik.de/north-america/us-northeast-latest.osm.pbf"
    ["us-midwest"]="https://download.geofabrik.de/north-america/us-midwest-latest.osm.pbf"
    ["us-south"]="https://download.geofabrik.de/north-america/us-south-latest.osm.pbf"
    ["us-pacific"]="https://download.geofabrik.de/north-america/us-pacific-latest.osm.pbf"
    # Individual States (add more as needed)
    ["us-texas"]="https://download.geofabrik.de/north-america/us/texas-latest.osm.pbf"
    ["us-florida"]="https://download.geofabrik.de/north-america/us/florida-latest.osm.pbf"
    ["us-newyork"]="https://download.geofabrik.de/north-america/us/new-york-latest.osm.pbf"
    # International
    ["europe"]="https://download.geofabrik.de/europe-latest.osm.pbf"
    ["germany"]="https://download.geofabrik.de/europe/germany-latest.osm.pbf"
    ["uk"]="https://download.geofabrik.de/europe/great-britain-latest.osm.pbf"
    ["australia"]="https://download.geofabrik.de/australia-oceania/australia-latest.osm.pbf"
    # Test region (small, fast to process)
    ["test"]="https://download.geofabrik.de/north-america/us/delaware-latest.osm.pbf"
)

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

check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker not found. Install from: https://docs.docker.com/get-docker/"
    fi
}

check_disk_space() {
    local required_gb=$1
    local available_gb=$(df -BG "$DATA_DIR" 2>/dev/null | tail -1 | awk '{print $4}' | tr -d 'G')

    if [[ -z "$available_gb" || "$available_gb" -lt "$required_gb" ]]; then
        log_warning "Less than ${required_gb}GB free disk space. Processing may fail."
    fi
}

show_regions() {
    echo "Available regions:"
    echo ""
    echo "US Regions:"
    echo "  us-west        - California, Nevada, Oregon, Washington (~3GB)"
    echo "  us-california  - California only (~1GB)"
    echo "  us-northeast   - NY, NJ, PA, CT, MA, etc. (~2GB)"
    echo "  us-midwest     - IL, OH, MI, etc. (~2GB)"
    echo "  us-south       - TX, FL, GA, etc. (~3GB)"
    echo "  us-texas       - Texas only (~500MB)"
    echo "  us-florida     - Florida only (~300MB)"
    echo "  us-newyork     - New York only (~300MB)"
    echo ""
    echo "International:"
    echo "  europe         - All of Europe (~25GB, requires 64GB+ RAM)"
    echo "  germany        - Germany only (~4GB)"
    echo "  uk             - Great Britain (~1GB)"
    echo "  australia      - Australia (~500MB)"
    echo ""
    echo "Test:"
    echo "  test           - Delaware (tiny, for testing ~20MB)"
}

# =============================================================================
# Main Functions
# =============================================================================

download_osm() {
    local url="${REGION_URLS[$REGION]:-}"

    if [[ -z "$url" ]]; then
        log_error "Unknown region: $REGION"
        show_regions
        exit 1
    fi

    local filename="${REGION}.osm.pbf"
    local filepath="${DATA_DIR}/${filename}"

    log_info "Downloading OSM data for region: $REGION"
    log_info "Source: $url"

    mkdir -p "$DATA_DIR"

    # Download with progress
    if command -v wget &> /dev/null; then
        wget -c -O "$filepath" "$url"
    elif command -v curl &> /dev/null; then
        curl -L -C - -o "$filepath" "$url"
    else
        log_error "Neither wget nor curl found. Install one to continue."
    fi

    log_success "Downloaded: $filepath"
}

extract_osrm() {
    local input="${DATA_DIR}/${REGION}.osm.pbf"
    local output="${DATA_DIR}/${REGION}.osrm"

    if [[ ! -f "$input" ]]; then
        log_error "OSM file not found: $input"
    fi

    log_info "Extracting road network (this may take a while)..."

    docker run --rm \
        -v "${DATA_DIR}:/data" \
        osrm/osrm-backend:latest \
        osrm-extract -p /opt/car.lua "/data/${REGION}.osm.pbf"

    log_success "Extraction complete"
}

partition_osrm() {
    log_info "Partitioning graph (MLD algorithm)..."

    docker run --rm \
        -v "${DATA_DIR}:/data" \
        osrm/osrm-backend:latest \
        osrm-partition "/data/${REGION}.osrm"

    log_success "Partitioning complete"
}

customize_osrm() {
    log_info "Customizing graph..."

    docker run --rm \
        -v "${DATA_DIR}:/data" \
        osrm/osrm-backend:latest \
        osrm-customize "/data/${REGION}.osrm"

    log_success "Customization complete"
}

verify_setup() {
    log_info "Verifying OSRM setup..."

    # Start test container
    docker run --rm -d \
        --name osrm-test \
        -p 5001:5000 \
        -v "${DATA_DIR}:/data" \
        osrm/osrm-backend:latest \
        osrm-routed --algorithm mld "/data/${REGION}.osrm"

    sleep 5

    # Test query
    local response=$(curl -s "http://localhost:5001/route/v1/driving/-122.4194,37.7749;-122.2712,37.8044?overview=false")

    docker stop osrm-test

    if echo "$response" | grep -q '"code":"Ok"'; then
        log_success "OSRM is working correctly!"
    else
        log_warning "OSRM test query failed. Check the data processing."
        echo "Response: $response"
    fi
}

copy_to_volume() {
    log_info "Copying processed data to Docker volume..."

    # Create volume if it doesn't exist
    docker volume create scheduler-osrm-data 2>/dev/null || true

    # Copy data to volume
    docker run --rm \
        -v "${DATA_DIR}:/source:ro" \
        -v scheduler-osrm-data:/data \
        alpine sh -c "cp /source/${REGION}.osrm* /data/"

    log_success "Data copied to volume: scheduler-osrm-data"
}

cleanup_pbf() {
    local pbf_file="${DATA_DIR}/${REGION}.osm.pbf"

    if [[ -f "$pbf_file" ]]; then
        log_info "Cleaning up PBF file to save space..."
        rm "$pbf_file"
        log_success "Removed: $pbf_file"
    fi
}

# =============================================================================
# Main Script
# =============================================================================

show_usage() {
    cat << EOF
OSRM Setup Script for The Scheduler

Usage: $0 [region] [options]

Arguments:
  region              Region to download and process (default: us-west)

Options:
  --list              List available regions
  --skip-download     Skip download (use existing PBF file)
  --skip-copy         Skip copying to Docker volume
  --keep-pbf          Keep PBF file after processing
  --verify-only       Only verify existing setup
  --help              Show this help message

Examples:
  $0 us-west                    # Full setup for US West
  $0 us-california --keep-pbf   # Setup California, keep source file
  $0 test                       # Quick test with Delaware
  $0 --verify-only              # Verify existing setup

EOF
}

main() {
    local skip_download=false
    local skip_copy=false
    local keep_pbf=false
    local verify_only=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --list)
                show_regions
                exit 0
                ;;
            --skip-download)
                skip_download=true
                shift
                ;;
            --skip-copy)
                skip_copy=true
                shift
                ;;
            --keep-pbf)
                keep_pbf=true
                shift
                ;;
            --verify-only)
                verify_only=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                ;;
            *)
                REGION="$1"
                shift
                ;;
        esac
    done

    echo "========================================"
    echo "OSRM Setup for The Scheduler"
    echo "Region: $REGION"
    echo "========================================"
    echo ""

    check_docker

    if $verify_only; then
        verify_setup
        exit 0
    fi

    # Estimate disk space needed
    local required_space=20
    [[ "$REGION" == "europe" ]] && required_space=100
    [[ "$REGION" == "test" ]] && required_space=2

    check_disk_space "$required_space"

    # Process steps
    if ! $skip_download; then
        download_osm
    fi

    extract_osrm
    partition_osrm
    customize_osrm

    if ! $skip_copy; then
        copy_to_volume
    fi

    if ! $keep_pbf; then
        cleanup_pbf
    fi

    verify_setup

    echo ""
    echo "========================================"
    log_success "OSRM setup complete for region: $REGION"
    echo "========================================"
    echo ""
    echo "To start OSRM with docker-compose:"
    echo "  1. Set OSRM_REGION=$REGION in .env"
    echo "  2. Run: docker compose up osrm"
    echo ""
}

main "$@"
