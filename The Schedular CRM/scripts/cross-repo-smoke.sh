#!/bin/bash
#
# Cross-Repo Integration Smoke Tests
#
# Purpose: verify the current shared-backend contract across Scheduler, Admin, and CRM.
# Usage: ./scripts/cross-repo-smoke.sh [--verbose]
#
# Exit codes:
#   0 = All tests passed
#   1 = One or more tests failed
#   2 = Script error (missing dependencies, etc.)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Flags
VERBOSE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --verbose)
      VERBOSE=true
      shift
      ;;
    --help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --emulator    Run tests against Firebase emulator"
      echo "  --verbose     Show detailed output"
      echo "  --help        Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Run with --help for usage information"
      exit 2
      ;;
  esac
done

# Print header
echo ""
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  Cross-Repo Integration Smoke Tests${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Check dependencies
check_dependency() {
  local cmd=$1
  local name=$2

  if ! command -v "$cmd" &> /dev/null; then
    echo -e "${RED}✗ Missing dependency: $name${NC}"
    echo "  Install $name and try again"
    exit 2
  fi

  if [ "$VERBOSE" = true ]; then
    echo -e "${GREEN}✓ Found dependency: $name${NC}"
  fi
}

echo -e "${YELLOW}Checking dependencies...${NC}"
check_dependency node "Node.js"
check_dependency npm "npm"
check_dependency flutter "Flutter"

echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRM_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_DIR="$(cd "$CRM_DIR/.." && pwd)"
SCHEDULER_DIR="$WORKSPACE_DIR/The Scheduler"
ADMIN_DIR="$WORKSPACE_DIR/The Scheduler Admin Page"

# Test runner helper
run_test() {
  local test_name=$1
  local test_cmd=$2

  TESTS_RUN=$((TESTS_RUN + 1))

  echo -ne "${YELLOW}Running: $test_name...${NC} "

  if eval "$test_cmd" &> /dev/null; then
    echo -e "${GREEN}PASS${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}FAIL${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))

    if [ "$VERBOSE" = true ]; then
      echo -e "${RED}  Command: $test_cmd${NC}"
      eval "$test_cmd" 2>&1 | sed 's/^/  /'
    fi

    return 1
  fi
}

# Test: Project structure
echo -e "${BLUE}1. Project Structure Tests${NC}"
echo ""

run_test "Scheduler repo exists" "test -d \"$SCHEDULER_DIR\""
run_test "Admin repo exists" "test -d \"$ADMIN_DIR\""
run_test "CRM repo exists" "test -d \"$CRM_DIR\""
run_test "Scheduler firestore rules exist" "test -f \"$SCHEDULER_DIR/firestore.rules\""
run_test "Scheduler functions source exists" "test -d \"$SCHEDULER_DIR/functions/src\""
run_test "CRM contract tests exist" "test -f \"$CRM_DIR/src/test/cross_repo.test.ts\""
run_test "Admin contract docs exist" "test -f \"$ADMIN_DIR/docs/shared_data_contract.md\""

echo ""

# Test: Shared ownership docs
run_test "Suite configuration exists" "test -f \"$WORKSPACE_DIR/CONFIGURATION.md\""
echo -e "${BLUE}2. Shared Ownership Tests${NC}"
echo ""

run_test "Admin shared contract points rules/indexes to Scheduler" "grep -q 'Shared rules/indexes deploy from' \"$ADMIN_DIR/docs/shared_data_contract.md\""
run_test "CRM shared contract points rules/indexes to Scheduler" "grep -q 'The Scheduler/firestore.rules' \"$CRM_DIR/docs/shared_data_contract.md\""

echo ""

# Test: Scheduler automated checks
echo -e "${BLUE}3. Scheduler Automated Checks${NC}"
echo ""

run_test "Scheduler Functions build" "npm --prefix \"$SCHEDULER_DIR/functions\" run build"
run_test "Scheduler Functions tests" "npm --prefix \"$SCHEDULER_DIR/functions\" test"
run_test "Scheduler role/runtime smoke tests" "cd \"$SCHEDULER_DIR\" && flutter test test/core/routing/role_router_test.dart test/modules/provider/provider_home_shell_test.dart test/modules/provider_mode/provider_mode_page_test.dart test/contracts/smoke_test.dart"

echo ""

# Test: Admin automated checks
echo -e "${BLUE}4. Admin Automated Checks${NC}"
echo ""

run_test "Admin build" "npm --prefix \"$ADMIN_DIR\" run build"
run_test "Admin shared contract tests" "npm --prefix \"$ADMIN_DIR\" test -- src/data/backupCodes.test.ts src/data/billingProfile.test.ts src/data/bulkInvites.test.ts src/data/firestoreBase.contract.test.ts"

echo ""

# Test: CRM automated checks
echo -e "${BLUE}5. CRM Automated Checks${NC}"
echo ""

run_test "CRM build" "npm --prefix \"$CRM_DIR\" run build"
run_test "CRM contract test suite" "npm --prefix \"$CRM_DIR\" run test:run -- src/test/cross_repo.test.ts"
run_test "CRM shared function client tests" "npm --prefix \"$CRM_DIR\" run test:run -- src/services/__tests__/calendar-functions-client.test.ts src/services/__tests__/cloud-functions-integration.test.ts src/services/__tests__/email-tracking-service.test.ts src/services/__tests__/calendar-oauth-service.test.ts src/services/__tests__/calendar-sync-service.test.ts"

echo ""

# Test: Documentation and verification assets
run_test "Release verification exists" "test -f \"$WORKSPACE_DIR/VERIFICATION.md\""
echo -e "${BLUE}6. Documentation And Verification Assets${NC}"
echo ""

run_test "Scheduler shared contract exists" "test -f \"$SCHEDULER_DIR/docs/shared_data_contract.md\""

echo ""

# Print summary
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  Test Summary${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo "Tests run:    $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"

if [ $TESTS_FAILED -gt 0 ]; then
  echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
  echo ""
  echo -e "${RED}Some tests failed. See output above for details.${NC}"
  echo ""
  exit 1
else
  echo -e "Tests failed: ${GREEN}0${NC}"
  echo ""
  echo -e "${GREEN}All tests passed!${NC}"
  echo ""
  exit 0
fi
