#!/bin/bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# test_all_adrs.sh
# Test runner for all ADR compliance tests
#
# This script runs all the ADR compliance tests in sequence and
# reports the overall results.

# Set strict mode
set -e

# Source test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./test.sh
source "${SCRIPT_DIR}/test.sh"

# Print header
print_header "MVNimble ADR Compliance Tests"
echo "Running all ADR compliance tests..."
echo

# Find all ADR test files
ADR_TEST_FILES=("${SCRIPT_DIR}"/test_adr_*.sh)

# Track overall results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
FAILED_FILES=()

# Run each test file
for test_file in "${ADR_TEST_FILES[@]}"; do
  if [ ! -f "$test_file" ]; then
    echo "Warning: No ADR test files found"
    break
  fi
  
  echo "Running tests in $(basename "$test_file")..."
  
  # Reset counters for global test framework variables
  TESTS_RUN=0
  TESTS_PASSED=0
  TESTS_FAILED=0
  
  # Run the tests
  bash "$test_file"
  result=$?
  
  # Update totals
  TOTAL_TESTS=$((TOTAL_TESTS + TESTS_RUN))
  PASSED_TESTS=$((PASSED_TESTS + TESTS_PASSED))
  FAILED_TESTS=$((FAILED_TESTS + TESTS_FAILED))
  
  if [ $result -ne 0 ]; then
    FAILED_FILES+=("$(basename "$test_file")")
  fi
  
  echo
done

# Print summary
print_header "ADR Compliance Test Summary"
echo "Files tested: ${#ADR_TEST_FILES[@]}"
echo "Total tests: $TOTAL_TESTS"

if $COLOR_ENABLED; then
  echo -e "Tests passed: ${COLOR_GREEN}$PASSED_TESTS${COLOR_RESET}"
  echo -e "Tests failed: ${COLOR_RED}$FAILED_TESTS${COLOR_RESET}"
else
  echo "Tests passed: $PASSED_TESTS"
  echo "Tests failed: $FAILED_TESTS"
fi

if [ ${#FAILED_FILES[@]} -gt 0 ]; then
  echo
  print_failure "Failed test files:"
  for file in "${FAILED_FILES[@]}"; do
    echo "  - $file"
  done
  echo
  echo "Review the specific test failures above for details."
  exit 1
else
  echo
  print_success "All ADR compliance tests passed!"
  exit 0
fi