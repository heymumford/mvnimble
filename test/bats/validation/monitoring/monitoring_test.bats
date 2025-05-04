#!/usr/bin/env bats
# monitoring_test.bats
# BATS tests for real-time monitoring validation
#
# This file contains test cases for validating the real-time
# monitoring capabilities of MVNimble
#
# Author: MVNimble Team
# Version: 1.0.0

load "../../test_helper.bash"

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
VALIDATION_SCRIPT="${SCRIPT_DIR}/monitoring_validation.sh"
RESULTS_DIR="${ROOT_DIR}/results/validation/monitoring"

setup() {
  mkdir -p "${RESULTS_DIR}"
  # Ensure the validation script is executable
  chmod +x "${VALIDATION_SCRIPT}"
}

# Test the validation script itself
@test "Monitoring validation script exists and is executable" {
  assert [ -f "${VALIDATION_SCRIPT}" ]
  assert [ -x "${VALIDATION_SCRIPT}" ]
}

# Test the real-time analyzer module
@test "Real-time analyzer module exists" {
  assert [ -f "${ROOT_DIR}/src/lib/modules/real_time_analyzer.sh" ]
}

# Test real-time analyzer is imported in main script
@test "Main script imports real-time analyzer module" {
  assert grep -q "real_time_analyzer.sh" "${ROOT_DIR}/src/lib/mvnimble.sh"
}

# Test basic monitoring functions
@test "Basic monitoring functions are defined" {
  source "${ROOT_DIR}/src/lib/modules/real_time_analyzer.sh"
  assert type -t start_real_time_monitoring
  assert type -t capture_system_metrics
  assert type -t generate_monitoring_report
}

# Test command-line arguments for monitoring
@test "Main script handles monitoring command-line arguments" {
  assert grep -q -- "--monitor" "${ROOT_DIR}/src/lib/mvnimble.sh"
  assert grep -q "monitor_mode=true" "${ROOT_DIR}/src/lib/mvnimble.sh"
}

# Test flakiness analysis functions
@test "Flakiness analysis functions are defined" {
  source "${ROOT_DIR}/src/lib/modules/real_time_analyzer.sh"
  assert type -t identify_flakiness_patterns
  assert type -t generate_resource_correlation
}

# Mock test for platform compatibility check
@test "Capture system metrics is platform-aware" {
  source "${ROOT_DIR}/src/lib/modules/real_time_analyzer.sh"
  
  # Create a temp output file
  local temp_file="${BATS_TEST_TMPDIR}/test_metrics.csv"
  touch "$temp_file"
  
  # This should not fail on any platform
  run capture_system_metrics "$temp_file" "$$"
  assert_success
  
  # Check platform-specific code sections exist
  assert grep -q "uname" "${ROOT_DIR}/src/lib/modules/real_time_analyzer.sh"
  assert grep -q "Darwin" "${ROOT_DIR}/src/lib/modules/real_time_analyzer.sh"
  assert grep -q "Linux" "${ROOT_DIR}/src/lib/modules/real_time_analyzer.sh"
}

# Run basic validation in mock mode
@test "Basic monitoring validation works in mock mode" {
  # Mock test - doesn't actually need Maven
  MOCK_MODE=true run "${VALIDATION_SCRIPT}" platform
  assert_success
}

# Test that monitoring validation checks all required aspects
@test "Monitoring validation checks all required aspects" {
  assert grep -q "Basic Monitoring" "${VALIDATION_SCRIPT}"
  assert grep -q "Resource Correlation" "${VALIDATION_SCRIPT}"
  assert grep -q "Flakiness Detection" "${VALIDATION_SCRIPT}"
  assert grep -q "Cross-platform Compatibility" "${VALIDATION_SCRIPT}"
}