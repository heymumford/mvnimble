#!/usr/bin/env bats
# flaky_test_detection_workflow.bats
# End-to-end tests for the flaky test detection workflow
#
# These tests validate the full flaky test detection workflow
# from existing test run data through to analysis reports.
#
# Author: MVNimble Team
# Version: 1.0.0

load "../../test_helper.bash"
load "../../helpers/bats-assert/load.bash"

# Define assert functions if they don't exist
assert_success() {
  if [ "$status" -ne 0 ]; then
    echo "Expected success (status 0), got status: $status" >&2
    return 1
  fi
  return 0
}

assert_failure() {
  if [ "$status" -eq 0 ]; then
    echo "Expected failure (non-zero status), got status: $status" >&2
    return 1
  fi
  return 0
}

# Define assert command
assert() {
  if ! "$@"; then
    echo "Assertion failed: $*" >&2
    return 1
  fi
  return 0
}

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
TEST_FIXTURES_DIR="${ROOT_DIR}/test/bats/fixtures/flaky_tests"
TEST_TEMP_DIR="${BATS_TEST_TMPDIR}"
DETECTOR_SCRIPT="${ROOT_DIR}/bin/mvnimble-detect-flaky"

setup() {
  # Create temporary directory for test artifacts
  mkdir -p "${TEST_TEMP_DIR}/results"
  
  # Copy test fixtures to temp directory
  mkdir -p "${TEST_TEMP_DIR}/runs/run-1" "${TEST_TEMP_DIR}/runs/run-2" "${TEST_TEMP_DIR}/runs/run-3" "${TEST_TEMP_DIR}/runs/run-4" "${TEST_TEMP_DIR}/runs/run-5"
  
  cp "${TEST_FIXTURES_DIR}/timing_flaky_test.log" "${TEST_TEMP_DIR}/runs/run-1/test_output.log"
  cp "${TEST_FIXTURES_DIR}/resource_contention_flaky_test.log" "${TEST_TEMP_DIR}/runs/run-2/test_output.log"
  cp "${TEST_FIXTURES_DIR}/environment_flaky_test.log" "${TEST_TEMP_DIR}/runs/run-3/test_output.log"
  cp "${TEST_FIXTURES_DIR}/thread_safety_flaky_test.log" "${TEST_TEMP_DIR}/runs/run-4/test_output.log"
  
  # Create a passing run with no failures
  cat > "${TEST_TEMP_DIR}/runs/run-5/test_output.log" << EOF
[INFO] Scanning for projects...
[INFO] 
[INFO] -------------< io.checkvox:checkvox-service >--------------
[INFO] Building Checkvox Service 1.0-SNAPSHOT
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-resources-plugin:3.2.0:resources (default-resources) @ checkvox-service ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] Using 'UTF-8' encoding to copy filtered properties files.
[INFO] Copying 1 resource
[INFO] Copying 1 resource
[INFO] 
[INFO] --- maven-compiler-plugin:3.8.1:compile (default-compile) @ checkvox-service ---
[INFO] Nothing to compile - all classes are up to date
[INFO] 
[INFO] --- maven-resources-plugin:3.2.0:testResources (default-testResources) @ checkvox-service ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] Using 'UTF-8' encoding to copy filtered properties files.
[INFO] skip non existing resourceDirectory /Users/vorthruna/Code/checkvox-service/src/test/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.8.1:testCompile (default-testCompile) @ checkvox-service ---
[INFO] Nothing to compile - all classes are up to date
[INFO] 
[INFO] --- maven-surefire-plugin:2.22.2:test (default-test) @ checkvox-service ---
[INFO] 
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running io.checkvox.service.AsyncServiceTest
[INFO] Tests run: 5, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 2.103 s - in io.checkvox.service.AsyncServiceTest
[INFO] Running io.checkvox.service.DataServiceTest
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.175 s - in io.checkvox.service.DataServiceTest
[INFO] Running io.checkvox.service.ConcurrentServiceTest
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 3.642 s - in io.checkvox.service.ConcurrentServiceTest
[INFO] Running io.checkvox.service.TimingDependentServiceTest
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 1.542 s - in io.checkvox.service.TimingDependentServiceTest
[INFO] Running io.checkvox.service.ConnectionPoolServiceTest
[INFO] Tests run: 4, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 3.642 s - in io.checkvox.service.ConnectionPoolServiceTest
[INFO] Running io.checkvox.service.ConfigDependentServiceTest
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.842 s - in io.checkvox.service.ConfigDependentServiceTest
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 19, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  12.321 s
[INFO] Finished at: 2025-05-04T10:30:42-04:00
[INFO] ------------------------------------------------------------------------
EOF
  
  # Copy thread dump and metrics data
  cp "${TEST_FIXTURES_DIR}/thread_dump.json" "${TEST_TEMP_DIR}/runs/run-4/thread_dump.json"
  cp "${TEST_FIXTURES_DIR}/system_metrics.json" "${TEST_TEMP_DIR}/runs/system_metrics.json"
  
  # Ensure flaky test detector module is available
  if [[ ! -f "${ROOT_DIR}/src/lib/modules/flaky_test_detector.sh" ]]; then
    print_error "Flaky test detector module not found"
    return 1
  fi
  
  # Ensure detector script is available and executable
  if [[ ! -f "$DETECTOR_SCRIPT" ]]; then
    print_error "Flaky test detector script not found"
    return 1
  fi
  
  chmod +x "$DETECTOR_SCRIPT"
}

teardown() {
  # Clean up test artifacts
  rm -rf "${TEST_TEMP_DIR}"
}

# Test that the flaky test detector script exists and is executable
@test "flaky test detector script exists and is executable" {
  assert [ -f "$DETECTOR_SCRIPT" ]
  assert [ -x "$DETECTOR_SCRIPT" ]
}

# Test the flaky test detection workflow using existing test runs
@test "detect-flaky can analyze existing test runs" {
  # Run the detector in analyze-only mode
  run "$DETECTOR_SCRIPT" --analyze-only --output "${TEST_TEMP_DIR}/results" "${TEST_TEMP_DIR}/runs"
  assert_success
  
  # Verify output files were created
  assert [ -f "${TEST_TEMP_DIR}/results/flaky_tests.md" ]
  assert [ -f "${TEST_TEMP_DIR}/results/categorized_tests.json" ]
  
  # Verify report content
  run cat "${TEST_TEMP_DIR}/results/flaky_tests.md"
  assert_output --partial "Flaky Test Analysis Report"
  assert_output --partial "io.checkvox.service.TimingDependentServiceTest"
  assert_output --partial "io.checkvox.service.ConnectionPoolServiceTest"
  assert_output --partial "io.checkvox.service.ConfigDependentServiceTest"
  assert_output --partial "io.checkvox.service.ConcurrentServiceTest"
  
  # Verify categorization
  run cat "${TEST_TEMP_DIR}/results/categorized_tests.json"
  assert_output --partial "\"category\": \"TIMING\""
  assert_output --partial "\"category\": \"RESOURCE_CONTENTION\""
  assert_output --partial "\"category\": \"ENVIRONMENT_DEPENDENCY\""
  assert_output --partial "\"category\": \"THREAD_SAFETY\""
}

# Test that the detector correctly identifies flaky tests
@test "detect-flaky identifies different types of flaky tests" {
  # Run the detector with specific focus on identifying flaky tests
  run "$DETECTOR_SCRIPT" --analyze-only --output "${TEST_TEMP_DIR}/results" "${TEST_TEMP_DIR}/runs"
  assert_success
  
  # Verify flaky test report includes categorization
  run cat "${TEST_TEMP_DIR}/results/flaky_tests.md"
  
  # Check for timing issues
  assert_output --partial "Timing-Related Issues"
  assert_output --partial "io.checkvox.service.TimingDependentServiceTest.testAsyncResponseProcessing"
  
  # Check for resource contention
  assert_output --partial "Resource Contention"
  assert_output --partial "io.checkvox.service.ConnectionPoolServiceTest.testConcurrentConnections"
  
  # Check for environment dependencies
  assert_output --partial "Environment Dependencies"
  assert_output --partial "io.checkvox.service.ConfigDependentServiceTest.testConfigBasedProcessing"
  
  # Check for thread safety issues
  assert_output --partial "Thread Safety Issues"
  assert_output --partial "io.checkvox.service.ConcurrentServiceTest.testConcurrentModification"
}

# Test that the detector provides meaningful recommendations
@test "detect-flaky provides recommendations for fixing flaky tests" {
  # Run the detector
  run "$DETECTOR_SCRIPT" --analyze-only --output "${TEST_TEMP_DIR}/results" "${TEST_TEMP_DIR}/runs"
  assert_success
  
  # Verify recommendations section exists
  run cat "${TEST_TEMP_DIR}/results/flaky_tests.md"
  assert_output --partial "## Recommendations"
  
  # Check for specific recommendations
  assert_output --partial "For Timing-Related Issues"
  assert_output --partial "Avoid fixed wait times"
  
  assert_output --partial "For Resource Contention"
  assert_output --partial "Increase resource limits"
  
  assert_output --partial "For Environment Dependencies"
  assert_output --partial "Standardize environments"
  
  assert_output --partial "For Thread Safety Issues"
  assert_output --partial "Use thread-safe collections"
}

# Test thread dump analysis functionality
@test "detect-flaky can analyze thread dumps for concurrency issues" {
  # Run the detector with thread analysis
  run "$DETECTOR_SCRIPT" --analyze-only --visualize --output "${TEST_TEMP_DIR}/results" "${TEST_TEMP_DIR}/runs"
  assert_success
  
  # Verify the flaky test report includes thread analysis
  run cat "${TEST_TEMP_DIR}/results/flaky_tests.md"
  assert_output --partial "Visualizations"
  assert_output --partial "visualization:thread-interaction"
  
  # Check if thread analysis was included
  run grep -c "Thread" "${TEST_TEMP_DIR}/results/flaky_tests.md"
  assert [ "$output" -gt 0 ]
}

# Test environment correlation analysis
@test "detect-flaky can correlate flakiness with environment variables" {
  # Run the detector with environment correlation
  run "$DETECTOR_SCRIPT" --analyze-only --output "${TEST_TEMP_DIR}/results" "${TEST_TEMP_DIR}/runs"
  assert_success
  
  # Verify the flaky test report includes environment correlation
  run cat "${TEST_TEMP_DIR}/results/flaky_tests.md"
  assert_output --partial "Environment Variables"
  
  # Check if system metrics were analyzed
  run grep -c "Environment" "${TEST_TEMP_DIR}/results/flaky_tests.md"
  assert [ "$output" -gt 0 ]
}

# Test command-line options
@test "detect-flaky supports various command-line options" {
  # Check help option
  run "$DETECTOR_SCRIPT" --help
  assert_success
  assert_output --partial "Usage: mvnimble-detect-flaky"
  
  # Check analyze-only option
  run "$DETECTOR_SCRIPT" --analyze-only --output "${TEST_TEMP_DIR}/results" "${TEST_TEMP_DIR}/runs"
  assert_success
  
  # Check output directory option
  run "$DETECTOR_SCRIPT" --analyze-only --output "${TEST_TEMP_DIR}/custom-results" "${TEST_TEMP_DIR}/runs"
  assert_success
  assert [ -d "${TEST_TEMP_DIR}/custom-results" ]
  
  # Check visualize option
  run "$DETECTOR_SCRIPT" --analyze-only --visualize --output "${TEST_TEMP_DIR}/results2" "${TEST_TEMP_DIR}/runs"
  assert_success
  assert [ -f "${TEST_TEMP_DIR}/results2/flaky_tests.md" ]
  run cat "${TEST_TEMP_DIR}/results2/flaky_tests.md"
  assert_output --partial "visualization"
}

# Test comparison of multiple test runs
@test "detect-flaky compares multiple test runs to identify patterns" {
  # Run test comparison
  run bash -c "cd \"$ROOT_DIR\" && source \"${ROOT_DIR}/src/lib/modules/flaky_test_detector.sh\" && compare_test_runs \"${TEST_TEMP_DIR}/runs/run-1/test_output.log\" \"${TEST_TEMP_DIR}/runs/run-5/test_output.log\" \"${TEST_TEMP_DIR}/results/comparison.md\""
  assert_success
  
  # Verify comparison report was created
  assert [ -f "${TEST_TEMP_DIR}/results/comparison.md" ]
  
  # Check comparison content
  run cat "${TEST_TEMP_DIR}/results/comparison.md"
  assert_output --partial "Test Run Comparison"
  assert_output --partial "Test Differences"
  
  # Verify it identifies the differences
  assert_output --partial "io.checkvox.service.TimingDependentServiceTest"
  assert_output --partial "FAIL"
  assert_output --partial "PASS"
}

# Test full workflow integration
@test "detect-flaky integrates with MVNimble architecture" {
  # Test integration with MVNimble main script (if available)
  if [ -f "${ROOT_DIR}/bin/mvnimble" ]; then
    # Make a copy of the main script for testing
    cp "${ROOT_DIR}/bin/mvnimble" "${TEST_TEMP_DIR}/mvnimble.test"
    
    # Modify it to add the flaky detection command (non-destructive test)
    cat >> "${TEST_TEMP_DIR}/mvnimble.test" << 'EOF'
# Test function to verify integration
function test_flaky_detector_integration() {
  if [[ -f "${SCRIPT_DIR}/mvnimble-detect-flaky" ]]; then
    return 0
  else
    return 1
  fi
}
# Call test function and return the result
test_flaky_detector_integration
exit $?
EOF
    
    # Make it executable
    chmod +x "${TEST_TEMP_DIR}/mvnimble.test"
    
    # Run the test
    run "${TEST_TEMP_DIR}/mvnimble.test"
    
    # The test should pass if the file exists, which we've made sure of in setup
    assert_success
  else
    skip "MVNimble main script not found for integration test"
  fi
}

# Performance test for flaky test detection
@test "flaky test detector has acceptable performance" {
  # Set up a larger test dataset
  local large_dataset="${TEST_TEMP_DIR}/large-dataset"
  mkdir -p "$large_dataset"
  
  # Create multiple copies of test runs
  for i in {1..20}; do
    mkdir -p "${large_dataset}/run-$i"
    cp "${TEST_TEMP_DIR}/runs/run-$((i % 5 + 1))/test_output.log" "${large_dataset}/run-$i/test_output.log"
  done
  
  # Measure performance
  local start_time=$(date +%s)
  
  run "$DETECTOR_SCRIPT" --analyze-only --output "${TEST_TEMP_DIR}/perf-results" "${large_dataset}"
  assert_success
  
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))
  
  # Performance criterion: should process 20 runs in under 10 seconds
  # This is a flexible threshold; adjust based on target environment
  assert [ $duration -lt 10 ]
}

# Test handling of edge cases
@test "detect-flaky handles edge cases gracefully" {
  # Test with empty directory
  mkdir -p "${TEST_TEMP_DIR}/empty"
  run "$DETECTOR_SCRIPT" --analyze-only --output "${TEST_TEMP_DIR}/empty-results" "${TEST_TEMP_DIR}/empty"
  assert_failure
  assert_output --partial "No test run data found"
  
  # Test with directory containing non-log files
  mkdir -p "${TEST_TEMP_DIR}/non-logs"
  echo "Not a log file" > "${TEST_TEMP_DIR}/non-logs/file.txt"
  run "$DETECTOR_SCRIPT" --analyze-only --output "${TEST_TEMP_DIR}/non-logs-results" "${TEST_TEMP_DIR}/non-logs"
  assert_failure
  
  # Test with invalid JSON files
  mkdir -p "${TEST_TEMP_DIR}/invalid-json/run-1"
  cp "${TEST_TEMP_DIR}/runs/run-1/test_output.log" "${TEST_TEMP_DIR}/invalid-json/run-1/test_output.log"
  echo "{invalid json}" > "${TEST_TEMP_DIR}/invalid-json/system_metrics.json"
  run "$DETECTOR_SCRIPT" --analyze-only --output "${TEST_TEMP_DIR}/invalid-json-results" "${TEST_TEMP_DIR}/invalid-json"
  # Should still succeed but with warnings
  assert_success
}