#!/usr/bin/env bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
#
# Run all validation tests for MVNimble
#
# This script runs all the test.bats files in the validation subdirectories
# to ensure that the validation framework itself works correctly.

# Find all validation test files
test_files=(
  "closed_loop/closed_loop_test.bats"
  "gold_standard/gold_standard_test.bats"
  "thread_safety/thread_safety_test.bats"
  "educational/educational_effectiveness_test.bats"
)

# Track results
total_tests=0
passed_tests=0
failed_tests=0

# Output colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Running MVNimble Validation Framework Tests${NC}"
echo "===================================="
echo ""

# Run each test file
for test_file in "${test_files[@]}"; do
  echo -e "${YELLOW}Running ${test_file}...${NC}"
  
  if [ ! -f "${test_file}" ]; then
    echo -e "${RED}Test file not found: ${test_file}${NC}"
    continue
  fi
  
  # Run the test
  bats_output=$(bats "${test_file}" 2>&1)
  bats_exit_code=$?
  
  # Extract test count
  file_tests=$(echo "${bats_output}" | grep -o '[0-9]* tests\?' | grep -o '[0-9]*')
  total_tests=$((total_tests + file_tests))
  
  if [ ${bats_exit_code} -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed in ${test_file}${NC}"
    passed_tests=$((passed_tests + file_tests))
  else
    echo -e "${RED}✗ Some tests failed in ${test_file}${NC}"
    echo "${bats_output}"
    
    # Extract failed test count
    file_failed=$(echo "${bats_output}" | grep -o '[0-9]* failed' | grep -o '[0-9]*')
    failed_tests=$((failed_tests + file_failed))
    passed_tests=$((passed_tests + file_tests - file_failed))
  fi
  
  echo ""
done

# Print summary
echo "===================================="
echo -e "${YELLOW}Test Summary:${NC}"
echo "Total tests: ${total_tests}"
echo -e "${GREEN}Passed: ${passed_tests}${NC}"
if [ ${failed_tests} -gt 0 ]; then
  echo -e "${RED}Failed: ${failed_tests}${NC}"
  exit 1
else
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
fi