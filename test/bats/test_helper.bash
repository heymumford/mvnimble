#!/usr/bin/env bash
# test_helper.bash
# Helper functions and common setup for BATS tests

# Determine the root project directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Directory containing the modules
MODULE_DIR="${PROJECT_ROOT}/src/lib/modules"

# Directory for test fixtures
FIXTURE_DIR="${PROJECT_ROOT}/test/bats/fixtures"

# Directory for test results
TEST_RESULTS_DIR="${PROJECT_ROOT}/test/test_results"

# Load tag support
source "$(dirname "${BASH_SOURCE[0]}")/test_tags.bash"

# Create necessary directories
mkdir -p "$FIXTURE_DIR"
mkdir -p "$TEST_RESULTS_DIR"

# Source common modules for testing
source_module() {
  local module="$1"
  
  # First source our test constants to ensure CONSTANTS_LOADED is set
  # This prevents the module from trying to source constants.sh again
  source "${PROJECT_ROOT}/test/bats/test_constants.sh"
  
  # Special handling for constants.sh to avoid readonly variable issues
  if [[ "$module" == "constants.sh" ]]; then
    # Already loaded test constants above, nothing more to do
    return 0
  else
    # Normal module
    if [[ -f "${MODULE_DIR}/${module}" ]]; then
      source "${MODULE_DIR}/${module}"
    else
      echo "Module ${module} not found" >&2
      return 1
    fi
  fi
}

# Setup a temporary directory for tests
setup_temp_dir() {
  BATS_TMPDIR="$(mktemp -d -t mvnimble_bats.XXXXXX)"
  cd "$BATS_TMPDIR" || exit 1
}

# Cleanup temporary directory
cleanup_temp_dir() {
  if [[ -d "$BATS_TMPDIR" ]]; then
    rm -rf "$BATS_TMPDIR"
  fi
}

# Create a fixture file with given content
create_fixture() {
  local name="$1"
  local content="$2"
  local fixture_path="${FIXTURE_DIR}/${name}"
  
  echo "$content" > "$fixture_path"
  echo "$fixture_path"
}

# Custom assertion: check if a string contains a substring
assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-Expected '$haystack' to contain '$needle'}"
  
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "$message" >&2
    return 1
  fi
  
  return 0
}

# Custom assertion: check if a command exists
assert_command_exists() {
  local command_name="$1"
  local message="${2:-Expected command '$command_name' to exist}"
  
  if ! command -v "$command_name" > /dev/null 2>&1; then
    echo "$message" >&2
    return 1
  fi
  
  return 0
}

# Custom assertion: check if a file exists
assert_file_exists() {
  local file_path="$1"
  local message="${2:-Expected file '$file_path' to exist}"
  
  if [[ ! -f "$file_path" ]]; then
    echo "$message" >&2
    return 1
  fi
  
  return 0
}

# Mock a command for testing
mock_command() {
  local command_name="$1"
  local exit_code="${2:-0}"
  local output="${3:-}"
  
  MOCKS_DIR="${BATS_TMPDIR}/mocks"
  mkdir -p "$MOCKS_DIR"
  
  cat > "${MOCKS_DIR}/${command_name}" <<EOF
#!/bin/bash
echo "${output}"
exit ${exit_code}
EOF
  
  chmod +x "${MOCKS_DIR}/${command_name}"
  export PATH="${MOCKS_DIR}:$PATH"
}

# Remove a mock
unmock_command() {
  local command_name="$1"
  
  if [[ -f "${BATS_TMPDIR}/mocks/${command_name}" ]]; then
    rm "${BATS_TMPDIR}/mocks/${command_name}"
  fi
}