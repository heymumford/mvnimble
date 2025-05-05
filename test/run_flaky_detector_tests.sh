#!/usr/bin/env bash
# A simple script to run the flaky test detector error handling tests

cd "$(dirname "$0")" || exit 1

# Define color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
RESET='\033[0m'

echo -e "${BLUE}Running flaky test detector error handling tests...${RESET}"

# Run the tests
./run_bats_tests.sh --test-dir "./bats/unit/error_handling"

exit_code=$?

if [[ $exit_code -eq 0 ]]; then
  echo -e "${GREEN}All tests passed!${RESET}"
else
  echo -e "${RED}Some tests failed!${RESET}"
fi

exit $exit_code