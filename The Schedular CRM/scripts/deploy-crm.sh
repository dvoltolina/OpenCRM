#!/bin/bash

################################################################################
# CRM Deployment Script
#
# Deploys Firestore rules, indexes, and Cloud Functions for the CRM application.
# This script coordinates deployment between the CRM repo and Admin Dashboard repo.
#
# Usage:
#   ./scripts/deploy-crm.sh                    # Deploy to staging (default)
#   ./scripts/deploy-crm.sh --prod             # Deploy to production
#   ./scripts/deploy-crm.sh --dry-run          # Show what would be deployed
#   ./scripts/deploy-crm.sh --validate-only    # Only validate configs
#
# Requirements:
#   - firebase-tools installed (npm install -g firebase-tools)
#   - Authenticated with Firebase CLI (firebase login)
#   - Admin Dashboard repo cloned alongside this repo
#   - .env file configured with project IDs
#
# Safety Features:
#   - Defaults to staging environment
#   - Requires --prod flag for production
#   - Interactive confirmation prompts
#   - Validation before deployment
#   - Dry-run mode
#
################################################################################

set -e  # Exit on error

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CRM_ROOT="$(dirname "$SCRIPT_DIR")"

# Default settings
ENVIRONMENT="staging"
DRY_RUN=false
VALIDATE_ONLY=false
SKIP_CONFIRMATION=false

# Admin Dashboard repo path. Prefer an explicit env var, otherwise try common
# sibling-directory names used across local clones and historical docs.
resolve_admin_repo_path() {
    local parent_dir
    parent_dir="$(dirname "$CRM_ROOT")"

    local candidates=(
        "$parent_dir/scheduler-admin-dashboard"
        "$parent_dir/The Scheduler Admin Dashboard"
        "$parent_dir/The Schedular Admin Dashboard"
    )

    for candidate in "${candidates[@]}"; do
        if [ -d "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
    done

    echo "$parent_dir/scheduler-admin-dashboard"
}

ADMIN_REPO_PATH="${ADMIN_REPO_PATH:-$(resolve_admin_repo_path)}"

################################################################################
# Helper Functions
################################################################################

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
}

print_banner() {
    echo ""
    echo "=========================================="
    echo "  CRM Deployment Script"
    echo "=========================================="
    echo ""
}

print_summary() {
    echo ""
    echo "=========================================="
    echo "  Deployment Summary"
    echo "=========================================="
    echo "Environment:      $ENVIRONMENT"
    echo "Dry Run:          $DRY_RUN"
    echo "Validate Only:    $VALIDATE_ONLY"
    echo "CRM Root:         $CRM_ROOT"
    echo "Admin Repo:       $ADMIN_REPO_PATH"
    echo "=========================================="
    echo ""
}

confirm() {
    if [ "$SKIP_CONFIRMATION" = true ]; then
        return 0
    fi

    local prompt="$1"
    read -p "$(echo -e ${YELLOW}${prompt}${NC}) [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_error "Deployment cancelled by user"
        exit 1
    fi
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "Required command '$1' not found. Please install it first."
        exit 1
    fi
}

check_file() {
    if [ ! -f "$1" ]; then
        log_error "Required file not found: $1"
        exit 1
    fi
}

check_directory() {
    if [ ! -d "$1" ]; then
        log_error "Required directory not found: $1"
        exit 1
    fi
}

################################################################################
# Validation Functions
################################################################################

validate_environment() {
    log_info "Validating environment..."

    # Check for required commands
    check_command "firebase"
    check_command "node"
    check_command "npx"

    # Check for .env file
    if [ ! -f "$CRM_ROOT/.env" ]; then
        log_warning ".env file not found. Will use environment variables."
    fi

    # Check for Firestore rules file
    check_file "$CRM_ROOT/firestore.rules"

    # Check for Admin Dashboard repo
    if [ ! -d "$ADMIN_REPO_PATH" ]; then
        log_error "Admin Dashboard repo not found at: $ADMIN_REPO_PATH"
        log_error "Set ADMIN_REPO_PATH environment variable or ensure it's in the expected location"
        exit 1
    fi

    # Check for firebase.json in Admin repo
    check_file "$ADMIN_REPO_PATH/firebase.json"

    # Run environment validation script
    log_info "Running environment validation script..."
    if ! npx tsx "$SCRIPT_DIR/validate-env.ts"; then
        log_error "Environment validation failed"
        exit 1
    fi

    log_success "Environment validation passed"
}

validate_firestore_config() {
    log_info "Validating Firestore configuration..."

    # Run Firestore config validation
    if ! npx tsx "$SCRIPT_DIR/validate-firestore-config.ts"; then
        log_error "Firestore configuration validation failed"
        exit 1
    fi

    log_success "Firestore configuration validation passed"
}

################################################################################
# Deployment Functions
################################################################################

deploy_firestore_rules() {
    log_info "Deploying Firestore rules..."

    local rules_file="$CRM_ROOT/firestore.rules"
    local admin_rules_file="$ADMIN_REPO_PATH/firestore.rules"

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would copy rules from: $rules_file"
        log_info "[DRY RUN] Would copy rules to: $admin_rules_file"
        log_info "[DRY RUN] Would deploy rules to $ENVIRONMENT"
        return 0
    fi

    # Backup existing rules in Admin repo
    if [ -f "$admin_rules_file" ]; then
        cp "$admin_rules_file" "$admin_rules_file.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Backed up existing rules"
    fi

    # Copy rules to Admin repo
    log_info "Copying Firestore rules to Admin Dashboard repo..."
    cp "$rules_file" "$admin_rules_file"
    log_success "Rules copied"

    # Deploy from Admin repo
    log_info "Deploying rules from Admin Dashboard repo..."
    (
        cd "$ADMIN_REPO_PATH"
        if [ "$ENVIRONMENT" = "production" ]; then
            firebase use production
        else
            firebase use staging
        fi
        firebase deploy --only firestore:rules
    )

    log_success "Firestore rules deployed successfully"
}

deploy_firestore_indexes() {
    log_info "Deploying Firestore indexes..."

    local indexes_doc="$CRM_ROOT/docs/operations/firestore_indexes.md"
    local admin_indexes_file="$ADMIN_REPO_PATH/firestore.indexes.json"

    # Extract JSON from markdown
    local indexes_json=$(awk '/^```json$/,/^```$/' "$indexes_doc" | grep -A 1000 '"indexes"' | head -n 1000 | grep -B 1000 '^\]' | head -n -1)

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would extract indexes from: $indexes_doc"
        log_info "[DRY RUN] Would write indexes to: $admin_indexes_file"
        log_info "[DRY RUN] Would deploy indexes to $ENVIRONMENT"
        return 0
    fi

    # Backup existing indexes in Admin repo
    if [ -f "$admin_indexes_file" ]; then
        cp "$admin_indexes_file" "$admin_indexes_file.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Backed up existing indexes"
    fi

    # Create indexes file from documentation
    log_info "Creating firestore.indexes.json in Admin Dashboard repo..."
    awk '/^```json$/,/^```$/' "$indexes_doc" | \
        awk '/\{/,/\]$/' | \
        sed '/^```/d' | \
        grep -v '^[[:space:]]*$' > "$admin_indexes_file"

    # Validate JSON
    if ! node -e "JSON.parse(require('fs').readFileSync('$admin_indexes_file', 'utf-8'))"; then
        log_error "Generated indexes JSON is invalid"
        exit 1
    fi

    log_success "Indexes file created"

    # Deploy from Admin repo
    log_info "Deploying indexes from Admin Dashboard repo..."
    log_warning "Note: Index creation may take several minutes..."
    (
        cd "$ADMIN_REPO_PATH"
        if [ "$ENVIRONMENT" = "production" ]; then
            firebase use production
        else
            firebase use staging
        fi
        firebase deploy --only firestore:indexes
    )

    log_success "Firestore indexes deployed successfully"
}

deploy_functions() {
    log_info "Checking for Cloud Functions..."

    local functions_dir="$CRM_ROOT/functions"

    if [ ! -d "$functions_dir" ]; then
        log_info "No Cloud Functions directory found, skipping..."
        return 0
    fi

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would deploy Cloud Functions to $ENVIRONMENT"
        return 0
    fi

    log_info "Deploying Cloud Functions..."
    (
        cd "$CRM_ROOT"
        if [ "$ENVIRONMENT" = "production" ]; then
            firebase use production
        else
            firebase use staging
        fi
        firebase deploy --only functions
    )

    log_success "Cloud Functions deployed successfully"
}

run_post_deploy_checks() {
    log_info "Running post-deployment checks..."

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would run post-deployment verification"
        return 0
    fi

    # Check Firebase authentication
    log_info "Verifying Firebase authentication..."
    if ! firebase projects:list > /dev/null 2>&1; then
        log_error "Firebase authentication failed"
        exit 1
    fi

    log_success "Post-deployment checks passed"

    echo ""
    log_info "Next steps:"
    log_info "  1. Review post-deploy checklist: docs/operations/post_deploy_checklist.md"
    log_info "  2. Run smoke tests: npm run test:security"
    log_info "  3. Monitor Firebase Console for index build status"
    log_info "  4. Verify rules in Firebase Console"
}

################################################################################
# Main Deployment Flow
################################################################################

main() {
    print_banner

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --prod|--production)
                ENVIRONMENT="production"
                shift
                ;;
            --staging)
                ENVIRONMENT="staging"
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --validate-only)
                VALIDATE_ONLY=true
                shift
                ;;
            --yes|-y)
                SKIP_CONFIRMATION=true
                shift
                ;;
            --admin-repo)
                ADMIN_REPO_PATH="$2"
                shift 2
                ;;
            --help|-h)
                echo "Usage: $0 [options]"
                echo ""
                echo "Options:"
                echo "  --prod, --production    Deploy to production (requires confirmation)"
                echo "  --staging               Deploy to staging (default)"
                echo "  --dry-run               Show what would be deployed without making changes"
                echo "  --validate-only         Only validate configs without deploying"
                echo "  --yes, -y               Skip confirmation prompts"
                echo "  --admin-repo PATH       Path to Admin Dashboard repo"
                echo "  --help, -h              Show this help message"
                echo ""
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done

    print_summary

    # Safety check for production
    if [ "$ENVIRONMENT" = "production" ]; then
        log_warning "WARNING: You are about to deploy to PRODUCTION!"
        confirm "Are you absolutely sure you want to deploy to production?"
    else
        if [ "$DRY_RUN" = false ] && [ "$VALIDATE_ONLY" = false ]; then
            confirm "Deploy to $ENVIRONMENT?"
        fi
    fi

    # Validation
    validate_environment
    validate_firestore_config

    if [ "$VALIDATE_ONLY" = true ]; then
        log_success "Validation complete. No deployment performed."
        exit 0
    fi

    if [ "$DRY_RUN" = true ]; then
        log_info "=== DRY RUN MODE ==="
    fi

    # Deploy components
    log_info "Starting deployment to $ENVIRONMENT..."
    echo ""

    deploy_firestore_rules
    echo ""

    deploy_firestore_indexes
    echo ""

    deploy_functions
    echo ""

    run_post_deploy_checks
    echo ""

    if [ "$DRY_RUN" = false ]; then
        log_success "Deployment to $ENVIRONMENT completed successfully!"
    else
        log_success "Dry run completed. No actual changes were made."
    fi
}

# Run main function
main "$@"
