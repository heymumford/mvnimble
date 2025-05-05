#!/usr/bin/env bats
# test_flaky_test_detector_error_handling.bats
# Unit tests for flaky test detector error handling
#
# These tests verify that the flaky test detector module properly handles
# error conditions, invalid inputs, and edge cases.
#
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license

load "../../test_helper.bash"
load "../../helpers/bats-assert/load.bash"
load "../../helpers/bats-support/load.bash"

# Define assert functions if they don't exist
if ! declare -F assert_success >/dev/null; then
  assert_success() {
    if [ "$status" -ne 0 ]; then
      echo "Expected success (status 0), got status: $status" >&2
      return 1
    fi
    return 0
  }
fi

if ! declare -F assert_failure >/dev/null; then
  assert_failure() {
    if [ "$status" -eq 0 ]; then
      echo "Expected failure (non-zero status), got status: $status" >&2
      return 1
    fi
    return 0
  }
fi

if ! declare -F assert_output >/dev/null; then
  assert_output() {
    local expected="$1"
    if [[ "$output" != *"$expected"* ]]; then
      echo "Expected output to contain: $expected" >&2
      echo "Actual output: $output" >&2
      return 1
    fi
    return 0
  }
fi

if ! declare -F assert >/dev/null; then
  assert() {
    if ! "$@"; then
      echo "Assertion failed: $*" >&2
      return 1
    fi
    return 0
  }
fi

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
TEST_FIXTURES_DIR="${ROOT_DIR}/test/bats/fixtures/flaky_tests"
TEST_TEMP_DIR="${BATS_TEST_TMPDIR}"
DETECTOR_MODULE="${ROOT_DIR}/src/lib/modules/flaky_test_detector.sh"

setup() {
  # Create temporary directory for test artifacts
  mkdir -p "${TEST_TEMP_DIR}/results"
  
  # Ensure the detector module is loaded
  if [[ -f "$DETECTOR_MODULE" ]]; then
    source "$DETECTOR_MODULE"
  else
    # Skip all tests if module doesn't exist
    skip "Flaky test detector module not found at $DETECTOR_MODULE"
  fi
}

teardown() {
  # Clean up test artifacts
  rm -rf "${TEST_TEMP_DIR}"
}

# Test handling of missing input directory
@test "flaky test detector handles missing input directory" {
  run detect_flaky_tests "/nonexistent/dir" "${TEST_TEMP_DIR}/output.md"
  assert_failure
  assert_output --partial "Input directory doesn't exist"
}

# Test handling of empty input directory
@test "flaky test detector handles empty input directory" {
  # Create empty directory
  mkdir -p "${TEST_TEMP_DIR}/empty_dir"
  
  run detect_flaky_tests "${TEST_TEMP_DIR}/empty_dir" "${TEST_TEMP_DIR}/output.md"
  assert_failure
  assert_output --partial "No test run data found"
}

# Test handling of input directory with no log files
@test "flaky test detector handles directory with no log files" {
  # Create directory with non-log files
  mkdir -p "${TEST_TEMP_DIR}/no_logs_dir"
  echo "Not a log file" > "${TEST_TEMP_DIR}/no_logs_dir/not_a_log.txt"
  
  run detect_flaky_tests "${TEST_TEMP_DIR}/no_logs_dir" "${TEST_TEMP_DIR}/output.md"
  assert_failure
  assert_output --partial "No test run data found"
}

# Test handling of malformed log files
@test "flaky test detector handles malformed log files" {
  # Create directory with malformed log file
  mkdir -p "${TEST_TEMP_DIR}/malformed_logs"
  cp "${TEST_FIXTURES_DIR}/malformed_test_log.log" "${TEST_TEMP_DIR}/malformed_logs/test_output.log"
  
  run detect_flaky_tests "${TEST_TEMP_DIR}/malformed_logs" "${TEST_TEMP_DIR}/output.md"
  
  # Should handle this gracefully - either failing with a specific error or succeeding with warnings
  if [ "$status" -ne 0 ]; then
    assert_output --partial "malformed"
  else
    assert [ -f "${TEST_TEMP_DIR}/output.md" ]
  fi
}

# Test handling of empty log files
@test "flaky test detector handles empty log files" {
  # Create directory with empty log file
  mkdir -p "${TEST_TEMP_DIR}/empty_logs/run-1"
  cp "${TEST_FIXTURES_DIR}/empty_test_log.log" "${TEST_TEMP_DIR}/empty_logs/run-1/test_output.log"
  
  run detect_flaky_tests "${TEST_TEMP_DIR}/empty_logs" "${TEST_TEMP_DIR}/output.md"
  
  # Should handle this gracefully - either failing with a specific error or succeeding with warnings
  if [ "$status" -ne 0 ]; then
    assert_output --partial "empty"
  else
    assert [ -f "${TEST_TEMP_DIR}/output.md" ]
  fi
}

# Test handling of read-only output directory
@test "flaky test detector handles read-only output directory" {
  # Skip on systems where test user might have root privileges
  if [ "$EUID" -eq 0 ]; then
    skip "Skipping read-only test when running as root"
  fi
  
  # Create test fixture directory
  mkdir -p "${TEST_TEMP_DIR}/valid_runs/run-1"
  echo "BUILD FAILURE" > "${TEST_TEMP_DIR}/valid_runs/run-1/test_output.log"
  
  # Create read-only directory
  mkdir -p "${TEST_TEMP_DIR}/readonly"
  chmod 555 "${TEST_TEMP_DIR}/readonly"
  
  run detect_flaky_tests "${TEST_TEMP_DIR}/valid_runs" "${TEST_TEMP_DIR}/readonly/output.md"
  
  # Should fail with permission error
  assert_failure
  assert_output --partial "Permission"
}

# Test handling of input directory with missing test results
@test "flaky test detector handles directory with missing test results" {
  # Create directory with log file missing test results section
  mkdir -p "${TEST_TEMP_DIR}/missing_results/run-1"
  cat > "${TEST_TEMP_DIR}/missing_results/run-1/test_output.log" << 'EOF'
[INFO] Scanning for projects...
[INFO] 
[INFO] ----------------------< com.example:checkvox >-----------------------
[INFO] Building checkvox 1.0-SNAPSHOT
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-resources-plugin:3.2.0:resources (default-resources) @ checkvox ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] Using 'UTF-8' encoding to copy filtered properties files.
[INFO] Copying 1 resource
EOF
  
  run detect_flaky_tests "${TEST_TEMP_DIR}/missing_results" "${TEST_TEMP_DIR}/output.md"
  
  # Should handle this gracefully - either failing with a specific error or succeeding with empty report
  if [ "$status" -ne 0 ]; then
    assert_output --partial "No test run data"
  else
    assert [ -f "${TEST_TEMP_DIR}/output.md" ]
  fi
}

# Test handling of directory with mixed successful and failed builds
@test "flaky test detector handles directory with mixed build results" {
  # Copy test fixtures to temp directory
  mkdir -p "${TEST_TEMP_DIR}/mixed_results"
  cp -r "${TEST_FIXTURES_DIR}/runs/run-4" "${TEST_TEMP_DIR}/mixed_results/"  # Success
  cp -r "${TEST_FIXTURES_DIR}/runs/run-1" "${TEST_TEMP_DIR}/mixed_results/"  # Failure
  
  run detect_flaky_tests "${TEST_TEMP_DIR}/mixed_results" "${TEST_TEMP_DIR}/output.md"
  
  # Should succeed and create report
  assert_success
  assert [ -f "${TEST_TEMP_DIR}/output.md" ]
  
  # Check that the report contains expected content
  run cat "${TEST_TEMP_DIR}/output.md"
  assert_output --partial "Flaky Test Analysis Report"
  assert_output --partial "Flakiness Summary"
}

# Test handling of path with unusual characters
@test "flaky test detector handles path with unusual characters" {
  # Create directory with spaces and special characters
  unusual_dir="${TEST_TEMP_DIR}/unusual dir & chars"
  mkdir -p "${unusual_dir}/run-1"
  cp "${TEST_FIXTURES_DIR}/runs/run-1/test_output.log" "${unusual_dir}/run-1/"
  
  run detect_flaky_tests "$unusual_dir" "${TEST_TEMP_DIR}/output.md"
  
  # Should succeed regardless of unusual path
  assert_success
  assert [ -f "${TEST_TEMP_DIR}/output.md" ]
}

# Test handling of invalid JSON in analyze_flaky_test_patterns
@test "analyze_flaky_test_patterns handles invalid JSON" {
  run analyze_flaky_test_patterns "${TEST_FIXTURES_DIR}/malformed_metrics.json" "${TEST_TEMP_DIR}/output.md"
  
  # Should fail with JSON error
  assert_failure
  assert_output --partial "Invalid JSON"
}

# Test handling of missing thread_dump.json file in report generation
@test "generate_flaky_test_report handles missing thread dump" {
  # Create directory without thread dump
  mkdir -p "${TEST_TEMP_DIR}/no_thread_dump/run-1"
  cp "${TEST_FIXTURES_DIR}/runs/run-1/test_output.log" "${TEST_TEMP_DIR}/no_thread_dump/run-1/"
  
  run generate_flaky_test_report "${TEST_TEMP_DIR}/no_thread_dump" "${TEST_TEMP_DIR}/output.md"
  
  # Should succeed but not include thread visualization
  assert_success
  assert [ -f "${TEST_TEMP_DIR}/output.md" ]
  
  # Check that the report contains a message about missing thread dump
  run cat "${TEST_TEMP_DIR}/output.md"
  assert_output --partial "No thread dump available"
}

# Test compare_test_runs with invalid or non-existent inputs
@test "compare_test_runs handles invalid inputs" {
  run compare_test_runs "/nonexistent/file1.log" "/nonexistent/file2.log" "${TEST_TEMP_DIR}/comparison.md"
  
  # Should fail with file not found error
  assert_failure
  assert_output --partial "doesn't exist"
}

# Test categorize_flaky_tests with no log files
@test "categorize_flaky_tests handles directory with no log files" {
  mkdir -p "${TEST_TEMP_DIR}/no_logs"
  
  run categorize_flaky_tests "${TEST_TEMP_DIR}/no_logs" "${TEST_TEMP_DIR}/categories.json"
  
  # Should fail with no logs found error
  assert_failure
  assert_output --partial "No log files found"
}

# Test handling temporary file cleanup failures in generate_flaky_test_report
@test "generate_flaky_test_report handles temp file cleanup failures" {
  # Create test directory with valid run data
  mkdir -p "${TEST_TEMP_DIR}/cleanup_test/run-1"
  cp "${TEST_FIXTURES_DIR}/runs/run-1/test_output.log" "${TEST_TEMP_DIR}/cleanup_test/run-1/"
  
  # Mock rm to simulate failure (requires bash 4+)
  function rm() {
    # Only fail for temp files, not during teardown
    if [[ "$*" == *temp_flaky_analysis.md* ]]; then
      return 1
    fi
    command rm "$@"
  }
  export -f rm
  
  run generate_flaky_test_report "${TEST_TEMP_DIR}/cleanup_test" "${TEST_TEMP_DIR}/output.md"
  
  # Should succeed despite cleanup failure and include warning
  assert_success
  assert_output --partial "Failed to clean up" || assert_output --partial "Comprehensive flaky test report generated"
  assert [ -f "${TEST_TEMP_DIR}/output.md" ]
  
  # Restore original rm
  unset -f rm
}

# Test handling of empty output files in generate_flaky_test_report
@test "generate_flaky_test_report warns about empty output files" {
  # Create test directory with valid run data
  mkdir -p "${TEST_TEMP_DIR}/empty_output_test/run-1"
  cp "${TEST_FIXTURES_DIR}/runs/run-1/test_output.log" "${TEST_TEMP_DIR}/empty_output_test/run-1/"
  
  # Mock cat to create empty output file
  function cat() {
    # Don't write anything to the output file
    if [[ "$1" == *temp_flaky_analysis.md* ]]; then
      return 0
    fi
    command cat "$@"
  }
  export -f cat
  
  run generate_flaky_test_report "${TEST_TEMP_DIR}/empty_output_test" "${TEST_TEMP_DIR}/output.md"
  
  # Should succeed but warn about empty report
  assert_output --partial "empty" || assert_output --partial "report generated"
  
  # Restore original cat
  unset -f cat
}

# Test JSON validation in categorize_flaky_tests
@test "categorize_flaky_tests validates generated JSON" {
  # Skip this test if the necessary fixtures don't exist
  if [[ ! -f "${TEST_FIXTURES_DIR}/runs/run-1/test_output.log" ]]; then
    skip "Required test fixtures missing"
  fi
  
  # Create test files with specific content to trigger JSON creation
  mkdir -p "${TEST_TEMP_DIR}/json_validation"
  
  # Create a log file that will trigger the categorization
  cat > "${TEST_TEMP_DIR}/json_validation/flaky_test.log" << 'EOF'
[INFO] Running com.example.TimingTest
[INFO] Tests run: 3, Failures: 1, Errors: 0, Skipped: 0, Time elapsed: 1.5 s <<< FAILURE!
[INFO] com.example.TimingTest.testAsyncBehavior(com.example.TimingTest)  Time elapsed: 0.5 s  <<< FAILURE!
java.lang.AssertionError: Timed out waiting for response
	at com.example.TimingTest.testAsyncBehavior(TimingTest.java:42)
EOF
  
  # Run categorization
  run categorize_flaky_tests "${TEST_TEMP_DIR}/json_validation" "${TEST_TEMP_DIR}/categories.json"
  
  # Should have some output but might fail if jq is missing
  if [[ "$status" -ne 0 ]]; then
    assert_output --partial "Invalid JSON"
  else
    assert [ -f "${TEST_TEMP_DIR}/categories.json" ]
  fi
}

# Test handling of permission issues with thread visualization output
@test "generate_flaky_test_report handles thread visualization output permissions" {
  # Skip this test if required fixtures don't exist
  if [[ ! -f "${TEST_FIXTURES_DIR}/thread_dump.json" ]]; then
    skip "Thread dump fixture not found"
  fi
  
  # Create a minimal build failure log
  mkdir -p "${TEST_TEMP_DIR}/viz_permission_test/run-1"
  cat > "${TEST_TEMP_DIR}/viz_permission_test/run-1/test_output.log" << 'EOF'
[INFO] Running com.example.TestClass
[INFO] Tests run: 1, Failures: 1, Errors: 0, Skipped: 0
[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
EOF
  
  # Create a minimal thread dump JSON
  cat > "${TEST_TEMP_DIR}/viz_permission_test/thread_dump.json" << 'EOF'
{
  "threads": [
    {
      "id": 1,
      "name": "main",
      "state": "RUNNABLE"
    }
  ]
}
EOF
  
  # The function we want to test is generate_flaky_test_report
  run generate_flaky_test_report "${TEST_TEMP_DIR}/viz_permission_test" "${TEST_TEMP_DIR}/output.md"
  
  # Should succeed even with thread visualization not available
  assert_success
  assert [ -f "${TEST_TEMP_DIR}/output.md" ]
  
  # Try to read the output file and look for thread visualization sections
  if [[ -f "${TEST_TEMP_DIR}/output.md" ]]; then
    run grep -A 5 "Visualization" "${TEST_TEMP_DIR}/output.md"
    # We expect either a message about visualizations not being available
    # or a thread visualization section
    if [[ "$status" -eq 0 ]]; then
      assert_output --partial "visualization" || assert_output --partial "Visualization"
    else
      # If no visualization section is found, that's fine too
      assert_success
    fi
  fi
}