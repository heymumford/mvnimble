#!/usr/bin/env bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# test_build_failure_feature.sh
# Test runner for build failure analysis feature (ADR-007)
#
# This script runs both unit tests and validation tests for the
# build failure analysis feature.
#
# Author: MVNimble Team
# Version: 1.0.0

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
RESET='\033[0m'

# Run unit tests
run_unit_tests() {
  echo -e "\n${BOLD}${BLUE}Running Build Failure Analysis Unit Tests${RESET}"
  
  # Run BATS tests
  "${SCRIPT_DIR}/run_bats_tests.sh" "${SCRIPT_DIR}/bats/unit/test_build_failure_analysis.bats"
  
  # Check if tests passed
  local unit_result=$?
  if [ $unit_result -eq 0 ]; then
    echo -e "${GREEN}Unit tests passed${RESET}"
  else
    echo -e "${RED}Unit tests failed${RESET}"
  fi
  
  return $unit_result
}

# Run validation tests
run_validation_tests() {
  echo -e "\n${BOLD}${BLUE}Running Build Failure Analysis Validation Tests${RESET}"
  
  # Run validation script
  "${SCRIPT_DIR}/bats/validation/monitoring/build_failure_validation.sh"
  
  # Check if validation passed
  local validation_result=$?
  if [ $validation_result -eq 0 ]; then
    echo -e "${GREEN}Validation tests passed${RESET}"
  else
    echo -e "${RED}Validation tests failed${RESET}"
  fi
  
  return $validation_result
}

# Run all tests
run_all_tests() {
  # Track overall result
  local overall_result=0
  
  # Run unit tests
  run_unit_tests
  local unit_result=$?
  
  # Run validation tests
  run_validation_tests
  local validation_result=$?
  
  # Set overall result
  if [ $unit_result -ne 0 ] || [ $validation_result -ne 0 ]; then
    overall_result=1
  fi
  
  # Print summary
  echo -e "\n${BOLD}${BLUE}Build Failure Analysis Test Summary${RESET}"
  if [ $unit_result -eq 0 ]; then
    echo -e "${GREEN}✓ Unit tests: PASSED${RESET}"
  else
    echo -e "${RED}✗ Unit tests: FAILED${RESET}"
  fi
  
  if [ $validation_result -eq 0 ]; then
    echo -e "${GREEN}✓ Validation tests: PASSED${RESET}"
  else
    echo -e "${RED}✗ Validation tests: FAILED${RESET}"
  fi
  
  # Overall result
  if [ $overall_result -eq 0 ]; then
    echo -e "\n${GREEN}${BOLD}All tests PASSED${RESET}"
  else
    echo -e "\n${RED}${BOLD}Some tests FAILED${RESET}"
  fi
  
  return $overall_result
}

# Show help
show_help() {
  echo "Usage: $0 [OPTION]"
  echo ""
  echo "Test runner for build failure analysis feature (ADR-007)"
  echo ""
  echo "Options:"
  echo "  unit         Run unit tests only"
  echo "  validation   Run validation tests only"
  echo "  all          Run all tests (default)"
  echo "  help         Show this help message"
  echo ""
}

# Main function
main() {
  local mode="${1:-all}"
  
  case "$mode" in
    "unit")
      run_unit_tests
      ;;
    "validation")
      run_validation_tests
      ;;
    "all")
      run_all_tests
      ;;
    "help"|"--help"|"-h")
      show_help
      ;;
    *)
      echo -e "${RED}Error: Invalid option '$mode'${RESET}"
      show_help
      return 1
      ;;
  esac
}

# Execute main if script is not being sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi