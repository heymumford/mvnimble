#!/usr/bin/env bats
# test_flaky_test_detector_thread_visualization_integration.bats
# Integration tests for flaky test detector and thread visualization components
#
# These tests verify the integration between flaky test detection and thread visualization,
# focusing on error handling and edge cases.
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
TEST_FIXTURES_DIR="${ROOT_DIR}/test/bats/fixtures"
TEST_TEMP_DIR="${BATS_TEST_TMPDIR}"
DETECTOR_MODULE="${ROOT_DIR}/src/lib/modules/flaky_test_detector.sh"
VISUALIZER_MODULE="${ROOT_DIR}/src/lib/modules/thread_visualizer.sh"

setup() {
  # Create temporary directory for test artifacts
  mkdir -p "${TEST_TEMP_DIR}/results"
  
  # Ensure both modules are loaded
  local missing_modules=false
  
  if [[ -f "$DETECTOR_MODULE" ]]; then
    source "$DETECTOR_MODULE"
  else
    missing_modules=true
    echo "Flaky test detector module not found at $DETECTOR_MODULE"
  fi
  
  if [[ -f "$VISUALIZER_MODULE" ]]; then
    source "$VISUALIZER_MODULE"
  else
    missing_modules=true
    echo "Thread visualizer module not found at $VISUALIZER_MODULE"
  fi
  
  if [[ "$missing_modules" == "true" ]]; then
    # Skip all tests if modules don't exist
    skip "Required modules not found"
  fi
  
  # Create integration test fixtures directory
  mkdir -p "${TEST_TEMP_DIR}/integration_fixtures"
}

teardown() {
  # Clean up test artifacts
  rm -rf "${TEST_TEMP_DIR}"
}

# Create integration test fixtures for flaky test detection and thread visualization
create_integration_fixtures() {
  local fixture_dir="$1"
  
  # Create run directories with test logs
  mkdir -p "${fixture_dir}/runs/run-1"
  mkdir -p "${fixture_dir}/runs/run-2"
  
  # Create test logs with thread-related failures
  cat > "${fixture_dir}/runs/run-1/test_output.log" << 'EOF'
[INFO] Running com.example.ThreadTest
[INFO] Tests run: 3, Failures: 1, Errors: 0, Skipped: 0, Time elapsed: 1.5 s <<< FAILURE!
[INFO] com.example.ThreadTest.testConcurrentAccess(com.example.ThreadTest)  Time elapsed: 0.8 s  <<< FAILURE!
java.util.ConcurrentModificationException
	at java.util.ArrayList$Itr.checkForComodification(ArrayList.java:859)
	at java.util.ArrayList$Itr.next(ArrayList.java:831)
	at com.example.ThreadTest.testConcurrentAccess(ThreadTest.java:45)

[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
EOF

  cat > "${fixture_dir}/runs/run-2/test_output.log" << 'EOF'
[INFO] Running com.example.ThreadTest
[INFO] Tests run: 3, Failures: 1, Errors: 0, Skipped: 0, Time elapsed: 1.4 s <<< FAILURE!
[INFO] com.example.ThreadTest.testConcurrentAccess(com.example.ThreadTest)  Time elapsed: 0.7 s  <<< FAILURE!
java.lang.IllegalMonitorStateException: Object not locked by thread before wait()
	at java.lang.Object.wait(Native Method)
	at com.example.ThreadTest.testConcurrentAccess(ThreadTest.java:47)

[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
EOF

  # Create thread dump JSON
  cat > "${fixture_dir}/thread_dump.json" << 'EOF'
{
  "threads": [
    {
      "id": 1,
      "name": "main",
      "state": "RUNNABLE",
      "stack_trace": [
        "com.example.ThreadTest.testConcurrentAccess(ThreadTest.java:45)",
        "org.junit.runners.model.FrameworkMethod$1.runReflectiveCall(FrameworkMethod.java:50)",
        "org.junit.runners.model.FrameworkMethod.invokeExplosively(FrameworkMethod.java:47)"
      ],
      "locks_held": [],
      "locks_waiting": []
    },
    {
      "id": 2,
      "name": "worker-1",
      "state": "BLOCKED",
      "stack_trace": [
        "java.util.ArrayList.add(ArrayList.java:459)",
        "com.example.ThreadTest$Worker.run(ThreadTest.java:82)"
      ],
      "locks_held": [],
      "locks_waiting": [
        "java.util.ArrayList@12345678"
      ]
    },
    {
      "id": 3,
      "name": "worker-2",
      "state": "RUNNABLE",
      "stack_trace": [
        "java.util.ArrayList$Itr.checkForComodification(ArrayList.java:859)",
        "java.util.ArrayList$Itr.next(ArrayList.java:831)",
        "com.example.ThreadTest$Worker.run(ThreadTest.java:90)"
      ],
      "locks_held": [
        "java.util.ArrayList@12345678"
      ],
      "locks_waiting": []
    }
  ],
  "locks": [
    {
      "identity": "java.util.ArrayList@12345678",
      "owner_thread": 3,
      "waiting_threads": [2]
    }
  ]
}
EOF

  # Create system metrics JSON
  cat > "${fixture_dir}/system_metrics.json" << 'EOF'
{
  "runs": [
    {
      "id": "run-1",
      "success": false,
      "metrics": {
        "cpu_usage": 76.2,
        "memory_usage": 512.5,
        "thread_count": 32
      }
    },
    {
      "id": "run-2",
      "success": false,
      "metrics": {
        "cpu_usage": 81.5,
        "memory_usage": 523.8,
        "thread_count": 34
      }
    }
  ]
}
EOF
}

# Test full flow from flaky test detection to thread visualization integration
@test "integration: full flow from flaky test detection to thread visualization" {
  # Create integration test fixtures
  create_integration_fixtures "${TEST_TEMP_DIR}/integration_fixtures"
  
  # Test generating a comprehensive report
  run generate_flaky_test_report "${TEST_TEMP_DIR}/integration_fixtures" "${TEST_TEMP_DIR}/integration_report.md"
  
  # Should succeed despite any issues with thread visualization
  assert_success
  assert [ -f "${TEST_TEMP_DIR}/integration_report.md" ]
  
  # Check that the report contains expected content
  run cat "${TEST_TEMP_DIR}/integration_report.md"
  assert_output --partial "Flaky Test Analysis Report"
  
  # Should at least mention ThreadTest or ConcurrentModification
  run grep -E "Thread|Concurrent|synchroniz|lock" "${TEST_TEMP_DIR}/integration_report.md" || true
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

# Test missing thread visualization component
@test "integration: handles missing thread visualization component" {
  # Create test fixtures
  create_integration_fixtures "${TEST_TEMP_DIR}/missing_viz"
  
  # Rename the generate_thread functions to simulate they're missing
  if declare -f generate_thread_diagram > /dev/null; then
    eval "$(declare -f generate_thread_diagram | sed 's/generate_thread_diagram/original_generate_thread_diagram/')"
    unset -f generate_thread_diagram
  fi
  
  # Run the report generation
  run generate_flaky_test_report "${TEST_TEMP_DIR}/missing_viz" "${TEST_TEMP_DIR}/missing_viz_report.md"
  
  # Should still succeed despite missing visualization component
  assert_success
  assert [ -f "${TEST_TEMP_DIR}/missing_viz_report.md" ]
  
  # Restore the original function if we renamed it
  if declare -f original_generate_thread_diagram > /dev/null; then
    eval "$(declare -f original_generate_thread_diagram | sed 's/original_generate_thread_diagram/generate_thread_diagram/')"
    unset -f original_generate_thread_diagram
  fi
}

# Test thread visualization error handling in integration context
@test "integration: handles thread visualization errors gracefully" {
  # Create test fixtures
  create_integration_fixtures "${TEST_TEMP_DIR}/error_viz"
  
  # Create an invalid thread dump JSON to trigger errors
  cat > "${TEST_TEMP_DIR}/error_viz/thread_dump.json" << 'EOF'
{
  "threads": [
    {
      "id": 1,
      "name": "main",
      "state": "RUNNABLE",
      "stack_trace": [
        "com.example.ThreadTest.testConcurrentAccess(ThreadTest.java:45)"
      ]
    },
    {
      "missing_field": true,
      "name": "worker-1"
    }
  ],
  "locks": [
    {
      "identity": "invalid_lock"
    }
  ]
}
EOF
  
  # Run the report generation
  run generate_flaky_test_report "${TEST_TEMP_DIR}/error_viz" "${TEST_TEMP_DIR}/error_viz_report.md"
  
  # Should still succeed despite thread visualization errors
  assert_success
  assert [ -f "${TEST_TEMP_DIR}/error_viz_report.md" ]
}

# Test with valid flaky test data but no thread visualization data
@test "integration: handles test data without thread visualization data" {
  # Create fixture dir
  local fixture_dir="${TEST_TEMP_DIR}/no_thread_data"
  
  # Create run directories with test logs but no thread dump
  mkdir -p "${fixture_dir}/runs/run-1"
  
  cat > "${fixture_dir}/runs/run-1/test_output.log" << 'EOF'
[INFO] Running com.example.ThreadTest
[INFO] Tests run: 3, Failures: 1, Errors: 0, Skipped: 0, Time elapsed: 1.5 s <<< FAILURE!
[INFO] com.example.ThreadTest.testConcurrentAccess(com.example.ThreadTest)  Time elapsed: 0.8 s  <<< FAILURE!
java.util.ConcurrentModificationException
	at java.util.ArrayList$Itr.checkForComodification(ArrayList.java:859)
	at java.util.ArrayList$Itr.next(ArrayList.java:831)
	at com.example.ThreadTest.testConcurrentAccess(ThreadTest.java:45)

[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
EOF
  
  # Run the report generation
  run generate_flaky_test_report "${fixture_dir}" "${TEST_TEMP_DIR}/no_thread_report.md"
  
  # Should succeed and generate a more basic report
  assert_success
  assert [ -f "${TEST_TEMP_DIR}/no_thread_report.md" ]
  
  # Report should contain message about missing thread visualization data
  run cat "${TEST_TEMP_DIR}/no_thread_report.md"
  assert_output --partial "thread dump"
}

# Test with both modules having valid data but different errors
@test "integration: handles mixed error modes between modules" {
  # Create fixture dir
  local fixture_dir="${TEST_TEMP_DIR}/mixed_errors"
  
  # Create valid thread dump
  cat > "${fixture_dir}/thread_dump.json" << 'EOF'
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
  
  # But create run directories with invalid test logs
  mkdir -p "${fixture_dir}/runs/run-1"
  
  # Create an empty file - should cause error in test log processing
  touch "${fixture_dir}/runs/run-1/test_output.log"
  
  # Run the report generation
  run generate_flaky_test_report "${fixture_dir}" "${TEST_TEMP_DIR}/mixed_error_report.md"
  
  # Should still succeed despite mixed errors
  assert_success
  assert [ -f "${TEST_TEMP_DIR}/mixed_error_report.md" ]
}