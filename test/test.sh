#!/bin/bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# test.sh
# MVNimble - Test framework for unit testing
#
# This script contains a lightweight unit testing framework for
# testing MVNimble functionality and validating implementation
# against ADR specifications.

# Set strict mode
set -e

# Source constants
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../src/lib/modules/constants.sh
source "${SCRIPT_DIR}/../src/lib/modules/constants.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TEST_FILE=""
CURRENT_TEST=""

# Set up colors if terminal supports it
if [ -t 1 ]; then
  COLOR_ENABLED=true
else
  COLOR_ENABLED=false
fi

# Set up output formatting
print_header() {
  if $COLOR_ENABLED; then
    echo -e "${COLOR_BOLD}${COLOR_BLUE}==== $1 ====${COLOR_RESET}"
  else
    echo "==== $1 ===="
  fi
}

print_success() {
  if $COLOR_ENABLED; then
    echo -e "${COLOR_GREEN}✓ $1${COLOR_RESET}"
  else
    echo "PASS: $1"
  fi
}

print_failure() {
  if $COLOR_ENABLED; then
    echo -e "${COLOR_RED}✗ $1${COLOR_RESET}"
  else
    echo "FAIL: $1"
  fi
}

print_info() {
  if $COLOR_ENABLED; then
    echo -e "${COLOR_CYAN}$1${COLOR_RESET}"
  else
    echo "INFO: $1"
  fi
}

# Testing functions
assert_equal() {
  local expected="$1"
  local actual="$2"
  local message="${3:-Expected '$expected' but got '$actual'}"
  
  if [ "$expected" = "$actual" ]; then
    return 0
  else
    echo "Assertion failed: $message" >&2
    echo "Expected: '$expected'" >&2
    echo "Actual:   '$actual'" >&2
    return 1
  fi
}

assert_not_equal() {
  local unexpected="$1"
  local actual="$2"
  local message="${3:-Expected value to differ from '$unexpected'}"
  
  if [ "$unexpected" != "$actual" ]; then
    return 0
  else
    echo "Assertion failed: $message" >&2
    echo "Unexpected: '$unexpected'" >&2
    echo "Actual:     '$actual'" >&2
    return 1
  fi
}

assert_contains() {
  local expected="$1"
  local actual="$2"
  local message="${3:-Expected '$actual' to contain '$expected'}"
  
  if [[ "$actual" == *"$expected"* ]]; then
    return 0
  else
    echo "Assertion failed: $message" >&2
    echo "Expected to find: '$expected'" >&2
    echo "In:              '$actual'" >&2
    return 1
  fi
}

assert_file_exists() {
  local file="$1"
  local message="${2:-Expected file '$file' to exist}"
  
  if [ -f "$file" ]; then
    return 0
  else
    echo "Assertion failed: $message" >&2
    echo "File not found: '$file'" >&2
    return 1
  fi
}

assert_directory_exists() {
  local directory="$1"
  local message="${2:-Expected directory '$directory' to exist}"
  
  if [ -d "$directory" ]; then
    return 0
  else
    echo "Assertion failed: $message" >&2
    echo "Directory not found: '$directory'" >&2
    return 1
  fi
}

assert_command_exists() {
  local cmd="$1"
  local message="${2:-Expected command '$cmd' to be available}"
  
  if command -v "$cmd" >/dev/null 2>&1; then
    return 0
  else
    echo "Assertion failed: $message" >&2
    echo "Command not found: '$cmd'" >&2
    return 1
  fi
}

assert_exit_code() {
  local expected="$1"
  local actual="$2"
  local message="${3:-Expected exit code '$expected' but got '$actual'}"
  
  if [ "$expected" -eq "$actual" ]; then
    return 0
  else
    echo "Assertion failed: $message" >&2
    echo "Expected exit code: $expected" >&2
    echo "Actual exit code:   $actual" >&2
    return 1
  fi
}

run_test() {
  local test_name="$1"
  local test_file="$2"
  
  CURRENT_TEST="$test_name"
  ((TESTS_RUN++))
  
  # Run the test in a subshell to isolate it
  (
    # Source the test file to get access to its functions
    # shellcheck source=../test/test_*.sh
    source "$test_file"
    
    # Call the test function
    "$test_name"
  )
  
  local result=$?
  
  if [ $result -eq 0 ]; then
    print_success "$test_name"
    ((TESTS_PASSED++))
  else
    print_failure "$test_name"
    ((TESTS_FAILED++))
  fi
  
  return $result
}

# Function to run all tests
run_all_tests() {
  local test_pattern="${1:-test_*.sh}"
  local test_dir="${2:-$SCRIPT_DIR}"
  
  print_header "Running MVNimble Unit Tests"
  print_info "Test pattern: $test_pattern"
  print_info "Test directory: $test_dir"
  echo
  
  # Find all test files matching the pattern
  for test_file in "$test_dir"/$test_pattern; do
    if [ ! -f "$test_file" ]; then
      continue
    fi
    
    TEST_FILE="$test_file"
    print_header "Test File: $(basename "$test_file")"
    
    # Source the test file to get access to its functions
    # shellcheck source=../test/test_*.sh
    source "$test_file"
    
    # Find all functions that start with "test_"
    for test_func in $(grep -E "^test_[a-zA-Z0-9_]+" "$test_file" | sed 's/() {//g' | xargs); do
      run_test "$test_func" "$test_file"
    done
    
    echo
  done
  
  # Print summary
  print_header "Test Results"
  echo "Tests run:    $TESTS_RUN"
  
  if $COLOR_ENABLED; then
    echo -e "Tests passed: ${COLOR_GREEN}$TESTS_PASSED${COLOR_RESET}"
    echo -e "Tests failed: ${COLOR_RED}$TESTS_FAILED${COLOR_RESET}"
  else
    echo "Tests passed: $TESTS_PASSED"
    echo "Tests failed: $TESTS_FAILED"
  fi
  
  if [ "$TESTS_FAILED" -eq 0 ]; then
    print_success "All tests passed!"
    return 0
  else
    print_failure "There were test failures"
    return 1
  fi
}

# If this script is being run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Run the tests
  run_all_tests "$@"
fi