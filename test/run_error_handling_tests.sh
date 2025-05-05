#!/usr/bin/env bash
# run_error_handling_tests.sh
#
# A specialized test runner script that focuses on error handling
# and edge case tests for MVNimble components.
#
# This script provides quick feedback on the robustness of MVNimble
# by specifically targeting error conditions and unusual inputs.
#
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license

# Exit on error
set -e 

# Get the directory where this script is located
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

# Configuration
ERROR_HANDLING_TEST_DIR="${ROOT_DIR}/test/bats/unit/error_handling"
FIXTURES_DIR="${ROOT_DIR}/test/bats/fixtures"
BATS_RUNNER="${ROOT_DIR}/test/run_bats_tests.sh"
OUTPUT_DIR="${ROOT_DIR}/test/test_results"
REPORT_FORMAT="md"

# Make sure output directory exists
mkdir -p "$OUTPUT_DIR"

# Show help message
show_help() {
  echo -e "${BOLD}MVNimble Error Handling Test Runner${RESET}"
  echo ""
  echo "This script runs tests specifically focused on error handling and edge cases"
  echo "to ensure the robustness of MVNimble components."
  echo ""
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  --verbose, -v          Show verbose test output"
  echo "  --fail-fast, -f        Stop on first test failure"
  echo "  --report FORMAT        Generate a report in the specified format (markdown, json, tap, html)"
  echo "  --component NAME       Test only the specified component (thread_visualizer, flaky_test_detector, etc.)"
  echo "  --help, -h             Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0 --verbose"
  echo "  $0 --fail-fast --component thread_visualizer"
  echo "  $0 --report html"
  echo ""
  echo "Report bugs to: https://github.com/mvnimble/mvnimble/issues"
}

# Parse command line arguments
VERBOSE=""
FAIL_FAST=""
COMPONENT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --verbose|-v)
      VERBOSE="--verbose"
      shift
      ;;
    --fail-fast|-f)
      FAIL_FAST="--fail-fast"
      shift
      ;;
    --report)
      REPORT_FORMAT="$2"
      shift 2
      ;;
    --component)
      COMPONENT="$2"
      shift 2
      ;;
    --help|-h)
      show_help
      exit 0
      ;;
    *)
      echo -e "${RED}Error: Unknown option: $1${RESET}" >&2
      show_help
      exit 1
      ;;
  esac
done

# Print header
echo -e "${BOLD}${BLUE}=== MVNimble Error Handling Test Suite ===${RESET}"
echo ""

# Create test fixtures if they don't exist
if [[ ! -d "${FIXTURES_DIR}/flaky_tests" ]]; then
  echo -e "${YELLOW}Creating test fixtures...${RESET}"
  mkdir -p "${FIXTURES_DIR}/flaky_tests"
  
  # Create a basic thread dump fixture if it doesn't exist
  if [[ ! -f "${FIXTURES_DIR}/flaky_tests/thread_dump.json" ]]; then
    cat > "${FIXTURES_DIR}/flaky_tests/thread_dump.json" << 'EOF'
{
  "timestamp": "2025-05-04T10:25:14-04:00",
  "threads": [
    {
      "id": 1,
      "name": "main",
      "state": "RUNNABLE",
      "priority": 5,
      "stack_trace": [
        "java.lang.Thread.dumpThreads(Native Method)",
        "java.lang.Thread.getAllStackTraces(Thread.java:1653)",
        "io.checkvox.service.ConcurrentServiceTest.testConcurrentModification(ConcurrentServiceTest.java:55)"
      ],
      "locks_held": [],
      "locks_waiting": []
    },
    {
      "id": 24,
      "name": "worker-1",
      "state": "RUNNABLE",
      "priority": 5,
      "stack_trace": [
        "io.checkvox.service.ConcurrentService.processItem(ConcurrentService.java:87)",
        "io.checkvox.service.ConcurrentService.lambda$processItems$0(ConcurrentService.java:64)"
      ],
      "locks_held": ["java.util.HashMap@3a2e8dce"],
      "locks_waiting": []
    },
    {
      "id": 25,
      "name": "worker-2",
      "state": "RUNNABLE",
      "priority": 5,
      "stack_trace": [
        "io.checkvox.service.ConcurrentService.processItem(ConcurrentService.java:91)",
        "io.checkvox.service.ConcurrentService.lambda$processItems$0(ConcurrentService.java:64)"
      ],
      "locks_held": [],
      "locks_waiting": ["java.util.HashMap@3a2e8dce"]
    }
  ],
  "locks": [
    {
      "identity": "java.util.HashMap@3a2e8dce",
      "owner_thread": 24,
      "waiting_threads": [25]
    }
  ]
}
EOF
  fi
fi

# Determine which tests to run
TEST_DIR="${ERROR_HANDLING_TEST_DIR}"

if [[ -n "$COMPONENT" ]]; then
  # Construct the test file pattern based on the component
  TEST_PATTERN="test_${COMPONENT}_*.bats"
  echo -e "${BLUE}Running error handling tests for component: ${BOLD}${COMPONENT}${RESET}"
else
  # Run all error handling tests
  TEST_PATTERN="*.bats"
  echo -e "${BLUE}Running all error handling tests${RESET}"
fi

# Count test files
test_files=("${TEST_DIR}"/${TEST_PATTERN})
test_file_count=${#test_files[@]}

if [[ $test_file_count -eq 0 || ( $test_file_count -eq 1 && ! -f "${test_files[0]}" ) ]]; then
  echo -e "${RED}No test files found matching pattern: ${TEST_PATTERN}${RESET}"
  exit 1
fi

echo -e "${BLUE}Found ${test_file_count} test files${RESET}"
echo ""

# Run the tests
timestamp=$(date '+%Y%m%d_%H%M%S')
report_file="${OUTPUT_DIR}/error_handling_report_${timestamp}.${REPORT_FORMAT}"
report_option=""

if [[ -n "$REPORT_FORMAT" ]]; then
  report_option="--report ${REPORT_FORMAT}"
fi

echo -e "${BOLD}${BLUE}=== Running Error Handling Tests ===${RESET}"

# Run tests with the BATS runner
"${BATS_RUNNER}" ${VERBOSE} ${FAIL_FAST} ${report_option} --test-dir "${TEST_DIR}" --tags error_handling,edge_case

# Check the result
if [[ $? -eq 0 ]]; then
  echo -e "${GREEN}All error handling tests passed!${RESET}"
  echo ""
  echo -e "This indicates that MVNimble components are handling errors and edge cases properly."
  echo -e "The software should be robust against unexpected inputs and conditions."
else
  echo -e "${RED}Some error handling tests failed.${RESET}"
  echo ""
  echo -e "${YELLOW}Review the test output above to identify the specific issues.${RESET}"
  echo -e "${YELLOW}Failing error handling tests indicate potential robustness issues in the codebase.${RESET}"
  exit 1
fi

# Done
echo ""
echo -e "${BOLD}${BLUE}=== Error Handling Test Suite Complete ===${RESET}"
exit 0