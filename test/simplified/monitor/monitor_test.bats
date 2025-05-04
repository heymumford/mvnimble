#!/usr/bin/env bats
# Tests for the monitor.sh module

# Load the test helpers
load ../common/helpers

# Setup test environment
setup() {
  # Call the common setup function
  load_libs
  
  # Create a temporary directory for test artifacts
  TEST_TEMP_DIR="$(mktemp -d)"
  export TEST_TEMP_DIR
  
  # Load required modules
  load_module "constants"
  load_module "common"
  load_module "monitor"
}

# Clean up after tests
teardown() {
  # Call the common teardown function
  if [ -n "$TEST_TEMP_DIR" ] && [ -d "$TEST_TEMP_DIR" ]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# Test that the monitor_maven_build function exists
@test "monitor_maven_build function exists" {
  # Check that the function is defined
  declare -f monitor_maven_build
}

# Test monitoring setup
@test "monitoring setup creates necessary directories" {
  # Create test output directory
  local output_dir="${TEST_TEMP_DIR}/monitor_output"
  
  # Run the monitoring setup
  setup_monitoring "$output_dir" 5 300
  
  # Check that necessary directories were created
  [ -d "$output_dir" ]
  [ -d "${output_dir}/metrics" ]
  [ -d "${output_dir}/logs" ]
}

# Test parsing of Maven output
@test "parser extracts test execution details from Maven output" {
  # Create a mock Maven output file
  local maven_output=$(create_mock_maven_output "success")
  
  # Run the parser
  parse_maven_output "$maven_output" "${TEST_TEMP_DIR}/parsed_output.json"
  
  # Check that the parser extracted the correct information
  [ -f "${TEST_TEMP_DIR}/parsed_output.json" ]
  
  # Check for expected content in the parsed output
  grep -q '"total_tests": 3' "${TEST_TEMP_DIR}/parsed_output.json"
  grep -q '"failed_tests": 0' "${TEST_TEMP_DIR}/parsed_output.json"
  grep -q '"skipped_tests": 0' "${TEST_TEMP_DIR}/parsed_output.json"
}

# Test resource usage monitoring
@test "resource monitor collects system metrics" {
  # Create output directory
  local output_dir="${TEST_TEMP_DIR}/resource_monitor"
  mkdir -p "$output_dir"
  
  # Run the resource monitor for a short time
  run_with_timeout 2s collect_resource_metrics "$output_dir" 1
  
  # Check that metrics were collected
  [ -f "${output_dir}/cpu_usage.log" ]
  [ -f "${output_dir}/memory_usage.log" ]
  [ -f "${output_dir}/disk_io.log" ]
}

# Test failed build detection
@test "monitor detects failed builds" {
  # Create a mock Maven output with a failure
  local maven_output=$(create_mock_maven_output "failure")
  
  # Run the failure detector
  detect_build_failure "$maven_output" "${TEST_TEMP_DIR}/failure_report.json"
  
  # Check that the failure was detected
  [ -f "${TEST_TEMP_DIR}/failure_report.json" ]
  grep -q '"status": "failure"' "${TEST_TEMP_DIR}/failure_report.json"
  grep -q '"failed_tests": 1' "${TEST_TEMP_DIR}/failure_report.json"
}

# Test build duration calculation
@test "monitor calculates build duration correctly" {
  # Create start and end time markers
  echo "$(date +%s)" > "${TEST_TEMP_DIR}/start_time"
  sleep 1
  echo "$(date +%s)" > "${TEST_TEMP_DIR}/end_time"
  
  # Calculate duration
  local start_time=$(cat "${TEST_TEMP_DIR}/start_time")
  local end_time=$(cat "${TEST_TEMP_DIR}/end_time")
  local duration=$(calculate_duration "$start_time" "$end_time")
  
  # Check that duration is at least 1 second
  [ "$duration" -ge 1 ]
}

# Test output file generation
@test "monitor generates data output file" {
  # Create test output directory
  local output_dir="${TEST_TEMP_DIR}/output_test"
  mkdir -p "$output_dir"
  
  # Create mock Maven output
  local maven_output=$(create_mock_maven_output "success")
  
  # Generate output data file
  generate_monitor_data "$output_dir" "$maven_output" 10 "$(date +%s)" "$(date +%s)"
  
  # Check that the data file was created
  [ -f "${output_dir}/data.json" ]
  
  # Check content of the data file
  grep -q '"build_status": "success"' "${output_dir}/data.json"
  grep -q '"build_duration"' "${output_dir}/data.json"
}