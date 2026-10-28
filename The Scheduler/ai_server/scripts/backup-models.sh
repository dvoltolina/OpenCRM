#!/bin/bash
# =============================================================================
# Model Backup Script for The Scheduler AI Services
# Agent AI-13: Docker & Cloud Deployment
# =============================================================================
#
# Backs up trained ML models and Ollama model cache.
#
# Usage:
#   ./backup-models.sh [options]
#
# Examples:
#   ./backup-models.sh                      # Backup to default location
#   ./backup-models.sh --output=/backups    # Custom backup location
#   ./backup-models.sh --gcs=gs://bucket    # Backup to Google Cloud Storage
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
BACKUP_DIR="${BACKUP_DIR:-${SCRIPT_DIR}/../backups}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
GCS_BUCKET=""
COMPRESS=true
INCLUDE_OLLAMA=true
INCLUDE_PREDICTION=true
INCLUDE_OSRM=false  # Large, usually not needed

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
        log_error "Docker not found"
    fi
}

format_size() {
    local size=$1
    if [[ $size -gt 1073741824 ]]; then
        echo "$(( size / 1073741824 ))GB"
    elif [[ $size -gt 1048576 ]]; then
        echo "$(( size / 1048576 ))MB"
    else
        echo "$(( size / 1024 ))KB"
    fi
}

# =============================================================================
# Backup Functions
# =============================================================================

backup_prediction_models() {
    log_info "Backing up prediction models..."

    local backup_path="${BACKUP_DIR}/prediction_models_${TIMESTAMP}"
    mkdir -p "$backup_path"

    # Copy from Docker volume
    docker run --rm \
        -v scheduler-prediction-models:/source:ro \
        -v "$backup_path":/backup \
        alpine sh -c "cp -r /source/* /backup/ 2>/dev/null || echo 'No models to backup'"

    # Check if anything was copied
    if [[ -z "$(ls -A "$backup_path" 2>/dev/null)" ]]; then
        log_warning "No prediction models found in volume"
        rmdir "$backup_path"
        return 1
    fi

    local size=$(du -sb "$backup_path" | cut -f1)
    log_success "Prediction models backed up: $(format_size $size)"

    if $COMPRESS; then
        log_info "Compressing prediction models..."
        tar -czf "${backup_path}.tar.gz" -C "$BACKUP_DIR" "prediction_models_${TIMESTAMP}"
        rm -rf "$backup_path"
        log_success "Compressed to: prediction_models_${TIMESTAMP}.tar.gz"
    fi

    return 0
}

backup_ollama_models() {
    log_info "Backing up Ollama models..."

    local backup_path="${BACKUP_DIR}/ollama_models_${TIMESTAMP}"
    mkdir -p "$backup_path"

    # Copy from Docker volume
    docker run --rm \
        -v scheduler-ollama-models:/source:ro \
        -v "$backup_path":/backup \
        alpine sh -c "cp -r /source/* /backup/ 2>/dev/null || echo 'No models to backup'"

    # Check if anything was copied
    if [[ -z "$(ls -A "$backup_path" 2>/dev/null)" ]]; then
        log_warning "No Ollama models found in volume"
        rmdir "$backup_path"
        return 1
    fi

    local size=$(du -sb "$backup_path" | cut -f1)
    log_success "Ollama models backed up: $(format_size $size)"

    if $COMPRESS; then
        log_info "Compressing Ollama models (this may take a while)..."
        tar -czf "${backup_path}.tar.gz" -C "$BACKUP_DIR" "ollama_models_${TIMESTAMP}"
        rm -rf "$backup_path"
        log_success "Compressed to: ollama_models_${TIMESTAMP}.tar.gz"
    fi

    return 0
}

backup_osrm_data() {
    log_info "Backing up OSRM data..."

    local backup_path="${BACKUP_DIR}/osrm_data_${TIMESTAMP}"
    mkdir -p "$backup_path"

    # Copy from Docker volume
    docker run --rm \
        -v scheduler-osrm-data:/source:ro \
        -v "$backup_path":/backup \
        alpine sh -c "cp -r /source/* /backup/ 2>/dev/null || echo 'No data to backup'"

    # Check if anything was copied
    if [[ -z "$(ls -A "$backup_path" 2>/dev/null)" ]]; then
        log_warning "No OSRM data found in volume"
        rmdir "$backup_path"
        return 1
    fi

    local size=$(du -sb "$backup_path" | cut -f1)
    log_success "OSRM data backed up: $(format_size $size)"

    if $COMPRESS; then
        log_info "Compressing OSRM data (this may take a while)..."
        tar -czf "${backup_path}.tar.gz" -C "$BACKUP_DIR" "osrm_data_${TIMESTAMP}"
        rm -rf "$backup_path"
        log_success "Compressed to: osrm_data_${TIMESTAMP}.tar.gz"
    fi

    return 0
}

upload_to_gcs() {
    local file=$1

    if [[ -z "$GCS_BUCKET" ]]; then
        return 0
    fi

    log_info "Uploading to GCS: $GCS_BUCKET"

    if ! command -v gsutil &> /dev/null; then
        log_error "gsutil not found. Install Google Cloud SDK."
    fi

    gsutil cp "$file" "${GCS_BUCKET}/models/${TIMESTAMP}/"

    log_success "Uploaded: $file"
}

create_manifest() {
    local manifest_file="${BACKUP_DIR}/backup_manifest_${TIMESTAMP}.json"

    log_info "Creating backup manifest..."

    local files=$(ls -la "${BACKUP_DIR}"/*_${TIMESTAMP}* 2>/dev/null | awk '{print $9}' | tr '\n' ',' | sed 's/,$//')

    cat > "$manifest_file" << EOF
{
  "timestamp": "${TIMESTAMP}",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "hostname": "$(hostname)",
  "files": [
$(ls -la "${BACKUP_DIR}"/*_${TIMESTAMP}* 2>/dev/null | awk '{printf "    {\"name\": \"%s\", \"size\": %s},\n", $9, $5}' | sed '$ s/,$//')
  ],
  "volumes_backed_up": {
    "prediction_models": $INCLUDE_PREDICTION,
    "ollama_models": $INCLUDE_OLLAMA,
    "osrm_data": $INCLUDE_OSRM
  }
}
EOF

    log_success "Manifest created: $manifest_file"
}

cleanup_old_backups() {
    local keep_days=${1:-30}

    log_info "Cleaning up backups older than ${keep_days} days..."

    local deleted=0

    find "$BACKUP_DIR" -name "*.tar.gz" -type f -mtime +${keep_days} -print0 | while IFS= read -r -d '' file; do
        rm "$file"
        ((deleted++))
        log_info "Deleted: $file"
    done

    if [[ $deleted -gt 0 ]]; then
        log_success "Deleted $deleted old backup(s)"
    else
        log_info "No old backups to delete"
    fi
}

# =============================================================================
# Restore Functions
# =============================================================================

list_backups() {
    log_info "Available backups in $BACKUP_DIR:"
    echo ""

    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_warning "Backup directory does not exist"
        return 1
    fi

    ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null || log_warning "No backups found"
}

restore_backup() {
    local backup_file=$1
    local volume_name=$2

    if [[ ! -f "$backup_file" ]]; then
        log_error "Backup file not found: $backup_file"
    fi

    log_info "Restoring: $backup_file to $volume_name"
    log_warning "This will REPLACE all data in the volume!"

    read -p "Continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Restore cancelled"
        return 1
    fi

    # Create temporary directory
    local temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT

    # Extract backup
    tar -xzf "$backup_file" -C "$temp_dir"

    # Get extracted directory name
    local extracted_dir=$(ls "$temp_dir")

    # Restore to volume
    docker run --rm \
        -v "$temp_dir/$extracted_dir":/source:ro \
        -v "$volume_name":/target \
        alpine sh -c "rm -rf /target/* && cp -r /source/* /target/"

    log_success "Restored $backup_file to $volume_name"
}

# =============================================================================
# Main Script
# =============================================================================

show_usage() {
    cat << EOF
Model Backup Script for The Scheduler AI Services

Usage: $0 [command] [options]

Commands:
  backup              Create backup of models (default)
  restore <file>      Restore from backup file
  list                List available backups
  cleanup [days]      Remove backups older than N days (default: 30)

Options:
  --output=PATH       Backup output directory
  --gcs=BUCKET        Upload to Google Cloud Storage bucket
  --no-compress       Don't compress backups
  --no-ollama         Skip Ollama models
  --no-prediction     Skip prediction models
  --include-osrm      Include OSRM data (large!)
  --help, -h          Show this help message

Examples:
  $0                                    # Backup all models
  $0 --gcs=gs://my-bucket/backups       # Backup and upload to GCS
  $0 restore backups/ollama_20240115.tar.gz
  $0 cleanup 7                          # Remove backups older than 7 days

EOF
}

main() {
    local command="backup"
    local restore_file=""
    local cleanup_days=30

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            backup|restore|list|cleanup)
                command="$1"
                shift
                if [[ "$command" == "restore" && $# -gt 0 && ! "$1" =~ ^-- ]]; then
                    restore_file="$1"
                    shift
                fi
                if [[ "$command" == "cleanup" && $# -gt 0 && ! "$1" =~ ^-- ]]; then
                    cleanup_days="$1"
                    shift
                fi
                ;;
            --output=*)
                BACKUP_DIR="${1#*=}"
                shift
                ;;
            --gcs=*)
                GCS_BUCKET="${1#*=}"
                shift
                ;;
            --no-compress)
                COMPRESS=false
                shift
                ;;
            --no-ollama)
                INCLUDE_OLLAMA=false
                shift
                ;;
            --no-prediction)
                INCLUDE_PREDICTION=false
                shift
                ;;
            --include-osrm)
                INCLUDE_OSRM=true
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

    check_docker
    mkdir -p "$BACKUP_DIR"

    case $command in
        backup)
            echo "========================================"
            echo "The Scheduler Model Backup"
            echo "Timestamp: $TIMESTAMP"
            echo "Output: $BACKUP_DIR"
            echo "========================================"
            echo ""

            local success=true

            if $INCLUDE_PREDICTION; then
                backup_prediction_models || success=false
            fi

            if $INCLUDE_OLLAMA; then
                backup_ollama_models || success=false
            fi

            if $INCLUDE_OSRM; then
                backup_osrm_data || success=false
            fi

            create_manifest

            # Upload to GCS if configured
            if [[ -n "$GCS_BUCKET" ]]; then
                for file in "${BACKUP_DIR}"/*_${TIMESTAMP}*; do
                    upload_to_gcs "$file"
                done
            fi

            echo ""
            echo "========================================"
            if $success; then
                log_success "Backup complete!"
            else
                log_warning "Backup completed with warnings"
            fi
            echo "========================================"
            ;;

        restore)
            if [[ -z "$restore_file" ]]; then
                log_error "Please specify backup file to restore"
            fi

            # Determine volume from filename
            local volume_name=""
            if [[ "$restore_file" == *"prediction"* ]]; then
                volume_name="scheduler-prediction-models"
            elif [[ "$restore_file" == *"ollama"* ]]; then
                volume_name="scheduler-ollama-models"
            elif [[ "$restore_file" == *"osrm"* ]]; then
                volume_name="scheduler-osrm-data"
            else
                log_error "Cannot determine target volume from filename"
            fi

            restore_backup "$restore_file" "$volume_name"
            ;;

        list)
            list_backups
            ;;

        cleanup)
            cleanup_old_backups "$cleanup_days"
            ;;

        *)
            log_error "Unknown command: $command"
            ;;
    esac
}

main "$@"
