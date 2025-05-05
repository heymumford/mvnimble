#!/usr/bin/env bats
# test_thread_visualizer_error_handling.bats
# Unit tests for thread visualizer error handling
#
# These tests verify that the thread visualizer module properly handles
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
VISUALIZER_MODULE="${ROOT_DIR}/src/lib/modules/thread_visualizer.sh"

setup() {
  # Create temporary directory for test artifacts
  mkdir -p "${TEST_TEMP_DIR}/results"
  
  # Ensure the visualizer module is loaded
  if [[ -f "$VISUALIZER_MODULE" ]]; then
    source "$VISUALIZER_MODULE"
  else
    # Skip all tests if module doesn't exist
    skip "Thread visualizer module not found at $VISUALIZER_MODULE"
  fi
}

teardown() {
  # Clean up test artifacts
  rm -rf "${TEST_TEMP_DIR}"
}

# Test handling of missing input file
@test "thread visualizer handles missing input file" {
  run generate_thread_diagram "/nonexistent/file.json" "${TEST_TEMP_DIR}/output.md"
  assert_failure
  assert_output --partial "Input file doesn't exist"
}

# Test handling of empty input file
@test "thread visualizer handles empty input file" {
  # Create empty file
  touch "${TEST_TEMP_DIR}/empty.json"
  
  run generate_thread_diagram "${TEST_TEMP_DIR}/empty.json" "${TEST_TEMP_DIR}/output.md"
  assert_failure
  assert_output --partial "Input file is empty"
}

# Test handling of invalid JSON file
@test "thread visualizer handles invalid JSON file" {
  # Create invalid JSON file
  echo '{ "invalid": "json' > "${TEST_TEMP_DIR}/invalid.json"
  
  run generate_thread_diagram "${TEST_TEMP_DIR}/invalid.json" "${TEST_TEMP_DIR}/output.md"
  # Either it should fail, or it should handle the error gracefully (success with warning)
  if [ "$status" -ne 0 ]; then
    assert_output --partial "Invalid JSON"
  else
    assert_output --partial "Warning"
  fi
}

# Test handling of JSON without thread data
@test "thread visualizer handles JSON without thread data" {
  # Create JSON file without thread data
  echo '{"timestamp": "2025-05-05T12:00:00"}' > "${TEST_TEMP_DIR}/no_threads.json"
  
  run generate_thread_diagram "${TEST_TEMP_DIR}/no_threads.json" "${TEST_TEMP_DIR}/output.md"
  # Either it should fail, or it should handle the error gracefully (success with warning)
  if [ "$status" -ne 0 ]; then
    assert_output --partial "No thread data"
  else
    assert_output --partial "No threads found"
  fi
}

# Test handling of missing output directory
@test "thread visualizer handles missing output directory" {
  # Create a sample thread dump
  cp "${TEST_FIXTURES_DIR}/thread_dump.json" "${TEST_TEMP_DIR}/"
  
  # Use non-existent deep directory structure
  run generate_thread_diagram "${TEST_TEMP_DIR}/thread_dump.json" "/nonexistent/deep/path/output.md"
  
  # Either it should create the directories or fail with a clear message
  if [ "$status" -ne 0 ]; then
    assert_output --partial "Cannot create directory" 
  else
    # If successful, the directory should have been created
    assert [ -f "/nonexistent/deep/path/output.md" ]
  fi
}

# Test handling of read-only output directory
@test "thread visualizer handles read-only output directory" {
  # Skip on systems where test user might have root privileges
  if [ "$EUID" -eq 0 ]; then
    skip "Skipping read-only test when running as root"
  fi
  
  # Create a sample thread dump
  cp "${TEST_FIXTURES_DIR}/thread_dump.json" "${TEST_TEMP_DIR}/"
  
  # Create read-only directory
  mkdir -p "${TEST_TEMP_DIR}/readonly"
  chmod 555 "${TEST_TEMP_DIR}/readonly"
  
  run generate_thread_diagram "${TEST_TEMP_DIR}/thread_dump.json" "${TEST_TEMP_DIR}/readonly/output.md"
  
  # Should fail with permission error
  assert_failure
  assert_output --partial "Permission denied" 
}

# Test handling of missing jq dependency
@test "thread visualizer handles missing jq dependency" {
  # Create a sample thread dump
  cp "${TEST_FIXTURES_DIR}/thread_dump.json" "${TEST_TEMP_DIR}/"
  
  # Mock the command lookup to simulate missing jq
  command() {
    if [[ "$1" == "-v" && "$2" == "jq" ]]; then
      return 1
    else
      builtin command "$@"
    fi
  }
  
  run generate_thread_diagram "${TEST_TEMP_DIR}/thread_dump.json" "${TEST_TEMP_DIR}/output.md"
  
  # Should fall back to simple mode, not fail
  assert_success
  assert_output --partial "jq not found" 
  
  # Clean up the mock
  unset -f command
}

# Test handling of malformed thread data
@test "thread visualizer handles malformed thread data" {
  # Create JSON with malformed thread data
  cat > "${TEST_TEMP_DIR}/malformed_threads.json" << 'EOF'
{
  "timestamp": "2025-05-05T12:00:00",
  "threads": [
    {
      "id": "not-a-number",
      "name": 12345,
      "state": null,
      "locks_held": "not-an-array"
    }
  ]
}
EOF
  
  run generate_thread_diagram "${TEST_TEMP_DIR}/malformed_threads.json" "${TEST_TEMP_DIR}/output.md"
  
  # Should handle malformed data gracefully
  assert_success
  
  # Output file should be created with warning
  assert [ -f "${TEST_TEMP_DIR}/output.md" ]
}

# Test handling of deadlock detection with invalid input
@test "deadlock detection handles invalid input" {
  run detect_deadlocks "/nonexistent/file.json"
  
  assert_failure
  assert_output --partial "Valid input file is required"
}

# Test handling of deadlock detection with no locks
@test "deadlock detection handles thread dump with no locks" {
  # Create JSON with no locks
  cat > "${TEST_TEMP_DIR}/no_locks.json" << 'EOF'
{
  "timestamp": "2025-05-05T12:00:00",
  "threads": [
    {
      "id": 1,
      "name": "main",
      "state": "RUNNABLE",
      "locks_held": [],
      "locks_waiting": []
    }
  ],
  "locks": []
}
EOF
  
  run detect_deadlocks "${TEST_TEMP_DIR}/no_locks.json"
  
  # Should not detect deadlocks
  assert_failure
  assert_output --partial "No deadlocks detected"
}

# Test handling of very large thread dumps
@test "thread visualizer handles large thread dumps" {
  # Create a large thread dump
  {
    echo '{'
    echo '  "timestamp": "2025-05-05T12:00:00",'
    echo '  "threads": ['
    
    # Generate 1000 threads
    for i in {1..1000}; do
      # Add comma for all but the last thread
      if [[ $i -lt 1000 ]]; then
        comma=","
      else
        comma=""
      fi
      
      echo '    {'
      echo "      \"id\": $i,"
      echo "      \"name\": \"thread-$i\","
      echo '      "state": "RUNNABLE",'
      echo '      "stack_trace": ['
      echo '        "java.lang.Thread.run(Thread.java:829)"'
      echo '      ],'
      echo '      "locks_held": [],'
      echo '      "locks_waiting": []'
      echo "    }$comma"
    done
    
    echo '  ],'
    echo '  "locks": []'
    echo '}'
  } > "${TEST_TEMP_DIR}/large_dump.json"
  
  # Check the file size
  local file_size=$(wc -c < "${TEST_TEMP_DIR}/large_dump.json")
  echo "Large thread dump size: $file_size bytes" >&3
  
  # Should be able to process large file
  run generate_thread_diagram "${TEST_TEMP_DIR}/large_dump.json" "${TEST_TEMP_DIR}/output.md"
  
  assert_success
  assert [ -f "${TEST_TEMP_DIR}/output.md" ]
}

# Test thread visualization with unusual characters
@test "thread visualization handles thread names with unusual characters" {
  # Create thread dump with unusual characters in thread names
  cat > "${TEST_TEMP_DIR}/unusual_chars.json" << 'EOF'
{
  "timestamp": "2025-05-05T12:00:00",
  "threads": [
    {
      "id": 1,
      "name": "Thread with spaces and \"quotes\" and 'apostrophes'",
      "state": "RUNNABLE",
      "locks_held": [],
      "locks_waiting": []
    },
    {
      "id": 2,
      "name": "Thread with <html> & special characters / \\ $ ; |",
      "state": "RUNNABLE",
      "locks_held": [],
      "locks_waiting": []
    }
  ],
  "locks": []
}
EOF
  
  run generate_thread_visualization "${TEST_TEMP_DIR}/unusual_chars.json" "${TEST_TEMP_DIR}/output.html"
  
  assert_success
  assert [ -f "${TEST_TEMP_DIR}/output.html" ]
}

# Test thread visualization with minimum parameters
@test "thread visualization works with minimum required parameters" {
  # Create minimal thread dump
  cat > "${TEST_TEMP_DIR}/minimal.json" << 'EOF'
{"threads":[{"id":1}]}
EOF
  
  run generate_thread_visualization "${TEST_TEMP_DIR}/minimal.json" "${TEST_TEMP_DIR}/output.html"
  
  assert_success
  assert [ -f "${TEST_TEMP_DIR}/output.html" ]
}

# Test thread visualization with special lock names
@test "lock contention graph handles lock names with special characters" {
  # Create thread dump with special characters in lock names
  cat > "${TEST_TEMP_DIR}/special_locks.json" << 'EOF'
{
  "threads": [
    {"id": 1, "locks_held": ["Class$Inner@12a3b4c5"], "locks_waiting": []},
    {"id": 2, "locks_held": [], "locks_waiting": ["Class$Inner@12a3b4c5"]}
  ],
  "locks": [
    {"identity": "Class$Inner@12a3b4c5", "owner_thread": 1, "waiting_threads": [2]}
  ]
}
EOF
  
  run generate_lock_contention_graph "${TEST_TEMP_DIR}/special_locks.json" "${TEST_TEMP_DIR}/output.md"
  
  assert_success
  assert [ -f "${TEST_TEMP_DIR}/output.md" ]
}