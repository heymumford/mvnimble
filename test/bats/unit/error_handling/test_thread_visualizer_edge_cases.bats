#!/usr/bin/env bats
# test_thread_visualizer_edge_cases.bats
# Unit tests for thread visualizer edge case handling
#
# These tests verify that the thread visualizer module properly handles
# edge cases and unusual inputs, particularly focusing on complex
# deadlock patterns and unusual thread states.
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

if ! declare -F refute_output >/dev/null; then
  refute_output() {
    local expected="$1"
    if [[ "$output" == *"$expected"* ]]; then
      echo "Expected output not to contain: $expected" >&2
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

# Test thread visualization with no locks
@test "thread visualizer handles thread dump with no locks" {
  # Create thread dump with threads but no locks
  cat > "${TEST_TEMP_DIR}/no_locks.json" << 'EOF'
{
  "timestamp": "2025-05-05T12:00:00-04:00",
  "threads": [
    {
      "id": 1,
      "name": "main",
      "state": "RUNNABLE",
      "priority": 5,
      "stack_trace": [],
      "locks_held": [],
      "locks_waiting": []
    }
  ],
  "locks": []
}
EOF
  
  run generate_lock_contention_graph "${TEST_TEMP_DIR}/no_locks.json" "${TEST_TEMP_DIR}/output.md"
  
  assert_success
  # Output should not mention contention
  run cat "${TEST_TEMP_DIR}/output.md"
  refute_output --partial "Lock Contention"
}

# Test thread visualization with simple deadlock pattern
@test "thread visualizer handles simple deadlock pattern" {
  # Create thread dump with simple deadlock (2 threads)
  cat > "${TEST_TEMP_DIR}/simple_deadlock.json" << 'EOF'
{
  "timestamp": "2025-05-05T12:00:00-04:00",
  "threads": [
    {
      "id": 1,
      "name": "Thread-A",
      "state": "BLOCKED",
      "priority": 5,
      "stack_trace": [],
      "locks_held": ["java.util.HashMap@1a2b3c4d"],
      "locks_waiting": ["java.util.ArrayList@5e6f7g8h"]
    },
    {
      "id": 2,
      "name": "Thread-B",
      "state": "BLOCKED",
      "priority": 5,
      "stack_trace": [],
      "locks_held": ["java.util.ArrayList@5e6f7g8h"],
      "locks_waiting": ["java.util.HashMap@1a2b3c4d"]
    }
  ],
  "locks": [
    {
      "identity": "java.util.HashMap@1a2b3c4d",
      "owner_thread": 1,
      "waiting_threads": [2]
    },
    {
      "identity": "java.util.ArrayList@5e6f7g8h",
      "owner_thread": 2,
      "waiting_threads": [1]
    }
  ]
}
EOF
  
  # Deadlock detection should succeed
  run detect_deadlocks "${TEST_TEMP_DIR}/simple_deadlock.json"
  assert_success
  assert_output --partial "DEADLOCK DETECTED"
  
  # Visualization should show deadlock
  run generate_lock_contention_graph "${TEST_TEMP_DIR}/simple_deadlock.json" "${TEST_TEMP_DIR}/output.md"
  assert_success
  
  run cat "${TEST_TEMP_DIR}/output.md"
  assert_output --partial "DEADLOCK"
}

# Test thread visualization with complex deadlock pattern (3+ threads)
@test "thread visualizer handles complex deadlock patterns" {
  # Create thread dump with complex deadlock (3 threads in a cycle)
  cat > "${TEST_TEMP_DIR}/complex_deadlock.json" << 'EOF'
{
  "timestamp": "2025-05-05T12:00:00-04:00",
  "threads": [
    {
      "id": 1,
      "name": "Thread-A",
      "state": "BLOCKED",
      "priority": 5,
      "stack_trace": [],
      "locks_held": ["LockA"],
      "locks_waiting": ["LockB"]
    },
    {
      "id": 2,
      "name": "Thread-B",
      "state": "BLOCKED",
      "priority": 5,
      "stack_trace": [],
      "locks_held": ["LockB"],
      "locks_waiting": ["LockC"]
    },
    {
      "id": 3,
      "name": "Thread-C",
      "state": "BLOCKED",
      "priority": 5,
      "stack_trace": [],
      "locks_held": ["LockC"],
      "locks_waiting": ["LockA"]
    }
  ],
  "locks": [
    {
      "identity": "LockA",
      "owner_thread": 1,
      "waiting_threads": [3]
    },
    {
      "identity": "LockB",
      "owner_thread": 2,
      "waiting_threads": [1]
    },
    {
      "identity": "LockC",
      "owner_thread": 3,
      "waiting_threads": [2]
    }
  ]
}
EOF
  
  # Should detect complex deadlock
  run detect_deadlocks "${TEST_TEMP_DIR}/complex_deadlock.json"
  
  # Since our current implementation might only detect pairwise deadlocks,
  # we'll check if it finds at least one deadlock pair
  assert_output --partial "DEADLOCK DETECTED"
}

# Test thread visualization with unusual thread states
@test "thread visualization handles unusual thread states" {
  # Create thread dump with unusual states
  cat > "${TEST_TEMP_DIR}/unusual_states.json" << 'EOF'
{
  "timestamp": "2025-05-05T12:00:00-04:00",
  "threads": [
    {
      "id": 1,
      "name": "thread1",
      "state": "UNKNOWN_STATE",
      "priority": 5,
      "stack_trace": [],
      "locks_held": [],
      "locks_waiting": []
    },
    {
      "id": 2,
      "name": "thread2",
      "state": "",
      "priority": 5,
      "stack_trace": [],
      "locks_held": [],
      "locks_waiting": []
    },
    {
      "id": 3,
      "name": "thread3",
      "state": null,
      "priority": 5,
      "stack_trace": [],
      "locks_held": [],
      "locks_waiting": []
    }
  ],
  "locks": []
}
EOF
  
  run generate_thread_diagram "${TEST_TEMP_DIR}/unusual_states.json" "${TEST_TEMP_DIR}/output.md"
  
  assert_success
  assert [ -f "${TEST_TEMP_DIR}/output.md" ]
}

# Test thread visualization with diverse thread states
@test "thread visualization handles all standard thread states" {
  # Create thread dump with all standard thread states
  cat > "${TEST_TEMP_DIR}/all_states.json" << 'EOF'
{
  "timestamp": "2025-05-05T12:00:00-04:00",
  "threads": [
    {
      "id": 1,
      "name": "runnable-thread",
      "state": "RUNNABLE",
      "priority": 5,
      "stack_trace": [],
      "locks_held": [],
      "locks_waiting": []
    },
    {
      "id": 2,
      "name": "blocked-thread",
      "state": "BLOCKED",
      "priority": 5,
      "stack_trace": [],
      "locks_held": [],
      "locks_waiting": []
    },
    {
      "id": 3,
      "name": "waiting-thread",
      "state": "WAITING",
      "priority": 5,
      "stack_trace": [],
      "locks_held": [],
      "locks_waiting": []
    },
    {
      "id": 4,
      "name": "timed-waiting-thread",
      "state": "TIMED_WAITING",
      "priority": 5,
      "stack_trace": [],
      "locks_held": [],
      "locks_waiting": []
    },
    {
      "id": 5,
      "name": "terminated-thread",
      "state": "TERMINATED",
      "priority": 5,
      "stack_trace": [],
      "locks_held": [],
      "locks_waiting": []
    },
    {
      "id": 6,
      "name": "new-thread",
      "state": "NEW",
      "priority": 5,
      "stack_trace": [],
      "locks_held": [],
      "locks_waiting": []
    }
  ],
  "locks": []
}
EOF
  
  run generate_thread_diagram "${TEST_TEMP_DIR}/all_states.json" "${TEST_TEMP_DIR}/output.md"
  
  assert_success
  
  # Check if the output contains all thread states
  run cat "${TEST_TEMP_DIR}/output.md"
  assert_output --partial "RUNNABLE"
  assert_output --partial "BLOCKED"
  assert_output --partial "WAITING"
  assert_output --partial "TIMED_WAITING"
}

# Test thread visualization with minimal thread dump
@test "thread visualization handles minimal thread dump" {
  # Create minimal thread dump with just the required fields
  cat > "${TEST_TEMP_DIR}/minimal.json" << 'EOF'
{
  "threads": [
    {
      "id": 1
    }
  ]
}
EOF
  
  run generate_thread_visualization "${TEST_TEMP_DIR}/minimal.json" "${TEST_TEMP_DIR}/output.html"
  
  assert_success
  assert [ -f "${TEST_TEMP_DIR}/output.html" ]
}

# Test thread visualization with complex lock patterns
@test "thread visualization handles complex lock patterns" {
  # Create thread dump with complex lock patterns
  cat > "${TEST_TEMP_DIR}/complex_locks.json" << 'EOF'
{
  "timestamp": "2025-05-05T12:00:00-04:00",
  "threads": [
    {
      "id": 1,
      "name": "Thread-1",
      "state": "RUNNABLE",
      "priority": 5,
      "stack_trace": [],
      "locks_held": ["LockA", "LockB", "LockC"],
      "locks_waiting": []
    },
    {
      "id": 2,
      "name": "Thread-2",
      "state": "BLOCKED",
      "priority": 5,
      "stack_trace": [],
      "locks_held": ["LockD"],
      "locks_waiting": ["LockA"]
    },
    {
      "id": 3,
      "name": "Thread-3",
      "state": "BLOCKED",
      "priority": 5,
      "stack_trace": [],
      "locks_held": [],
      "locks_waiting": ["LockB"]
    },
    {
      "id": 4,
      "name": "Thread-4",
      "state": "BLOCKED",
      "priority": 5,
      "stack_trace": [],
      "locks_held": [],
      "locks_waiting": ["LockC"]
    },
    {
      "id": 5,
      "name": "Thread-5",
      "state": "BLOCKED",
      "priority": 5,
      "stack_trace": [],
      "locks_held": [],
      "locks_waiting": ["LockD"]
    }
  ],
  "locks": [
    {
      "identity": "LockA",
      "owner_thread": 1,
      "waiting_threads": [2]
    },
    {
      "identity": "LockB",
      "owner_thread": 1,
      "waiting_threads": [3]
    },
    {
      "identity": "LockC",
      "owner_thread": 1,
      "waiting_threads": [4]
    },
    {
      "identity": "LockD",
      "owner_thread": 2,
      "waiting_threads": [5]
    }
  ]
}
EOF
  
  run generate_lock_contention_graph "${TEST_TEMP_DIR}/complex_locks.json" "${TEST_TEMP_DIR}/output.md"
  
  assert_success
  assert [ -f "${TEST_TEMP_DIR}/output.md" ]
  
  # Visualization should show multiple locks and threads
  run cat "${TEST_TEMP_DIR}/output.md"
  assert_output --partial "LockA"
  assert_output --partial "LockB"
  assert_output --partial "LockC"
  assert_output --partial "LockD"
}

# Test thread timeline with complex thread interactions
@test "thread timeline handles complex thread interactions" {
  # Create thread dump with complex timeline of interactions
  cat > "${TEST_TEMP_DIR}/complex_timeline.json" << 'EOF'
{
  "timestamp": "2025-05-05T12:00:00-04:00",
  "threads": [
    {
      "id": 1,
      "name": "WorkerThread-1",
      "state": "RUNNABLE",
      "priority": 5,
      "stack_trace": [],
      "locks_held": ["Lock-1"],
      "locks_waiting": []
    },
    {
      "id": 2,
      "name": "WorkerThread-2",
      "state": "BLOCKED",
      "priority": 5,
      "stack_trace": [],
      "locks_held": [],
      "locks_waiting": ["Lock-1"]
    },
    {
      "id": 3,
      "name": "TimerThread",
      "state": "TIMED_WAITING",
      "priority": 5,
      "stack_trace": [],
      "locks_held": [],
      "locks_waiting": []
    },
    {
      "id": 4,
      "name": "WaitingThread",
      "state": "WAITING",
      "priority": 5,
      "stack_trace": [],
      "locks_held": [],
      "locks_waiting": []
    }
  ],
  "locks": [
    {
      "identity": "Lock-1",
      "owner_thread": 1,
      "waiting_threads": [2]
    }
  ]
}
EOF
  
  run generate_thread_timeline "${TEST_TEMP_DIR}/complex_timeline.json" "${TEST_TEMP_DIR}/output.md"
  
  assert_success
  assert [ -f "${TEST_TEMP_DIR}/output.md" ]
  
  # Timeline should show different thread states
  run cat "${TEST_TEMP_DIR}/output.md"
  assert_output --partial "gantt"
  assert_output --partial "WorkerThread-1"
  assert_output --partial "WorkerThread-2"
  assert_output --partial "TimerThread"
  assert_output --partial "WaitingThread"
}

# Test HTML visualization with all features
@test "HTML visualization includes all visualization types" {
  # Create a thread dump with various features
  cat > "${TEST_TEMP_DIR}/full_features.json" << 'EOF'
{
  "timestamp": "2025-05-05T12:00:00-04:00",
  "threads": [
    {
      "id": 1,
      "name": "Main",
      "state": "RUNNABLE",
      "priority": 5,
      "stack_trace": [],
      "locks_held": ["LockA"],
      "locks_waiting": []
    },
    {
      "id": 2,
      "name": "Worker",
      "state": "BLOCKED",
      "priority": 5,
      "stack_trace": [],
      "locks_held": [],
      "locks_waiting": ["LockA"]
    }
  ],
  "locks": [
    {
      "identity": "LockA",
      "owner_thread": 1,
      "waiting_threads": [2]
    }
  ]
}
EOF
  
  run generate_thread_visualization "${TEST_TEMP_DIR}/full_features.json" "${TEST_TEMP_DIR}/output.html"
  
  assert_success
  assert [ -f "${TEST_TEMP_DIR}/output.html" ]
  
  # HTML should include all visualization types
  run cat "${TEST_TEMP_DIR}/output.html"
  assert_output --partial "Thread Interaction Diagram"
  assert_output --partial "Thread Timeline"
  assert_output --partial "Lock Contention Graph"
  assert_output --partial "Raw Thread Dump"
}

# Test thread analysis on actual format
@test "thread visualization works with actual thread dump format" {
  # Create a thread dump in format similar to what jstack produces
  cat > "${TEST_TEMP_DIR}/actual_format.json" << 'EOF'
{
  "timestamp": "2025-05-05T12:00:00-04:00",
  "threads": [
    {
      "id": 1,
      "name": "main",
      "daemon": false,
      "state": "RUNNABLE",
      "priority": 5,
      "os_priority": 31,
      "stack_trace": [
        "java.lang.Thread.dumpThreads(Native Method)",
        "java.lang.Thread.getAllStackTraces(Thread.java:1653)",
        "com.example.Main.main(Main.java:10)"
      ],
      "locks_held": [],
      "locks_waiting": []
    },
    {
      "id": 20,
      "name": "Service Thread",
      "daemon": true,
      "state": "RUNNABLE",
      "priority": 9,
      "os_priority": 31,
      "stack_trace": [],
      "locks_held": [],
      "locks_waiting": []
    },
    {
      "id": 21,
      "name": "C1 CompilerThread",
      "daemon": true,
      "state": "RUNNABLE",
      "priority": 9,
      "os_priority": 31,
      "stack_trace": [],
      "locks_held": [],
      "locks_waiting": []
    }
  ],
  "locks": []
}
EOF
  
  run generate_thread_visualization "${TEST_TEMP_DIR}/actual_format.json" "${TEST_TEMP_DIR}/output.html"
  
  assert_success
  assert [ -f "${TEST_TEMP_DIR}/output.html" ]
}

# Test with a huge number of locks
@test "thread visualization handles large number of locks" {
  # Create a thread dump with many locks
  {
    echo '{'
    echo '  "timestamp": "2025-05-05T12:00:00-04:00",'
    echo '  "threads": ['
    echo '    {'
    echo '      "id": 1,'
    echo '      "name": "LockMaster",'
    echo '      "state": "RUNNABLE",'
    echo '      "priority": 5,'
    echo '      "stack_trace": [],'
    echo '      "locks_held": ['
    
    # Generate 100 locks held
    for i in {1..100}; do
      if [[ $i -lt 100 ]]; then
        echo "        \"Lock-$i\","
      else
        echo "        \"Lock-$i\""
      fi
    done
    
    echo '      ],'
    echo '      "locks_waiting": []'
    echo '    },'
    
    # Add 100 waiting threads
    for i in {2..101}; do
      if [[ $i -lt 101 ]]; then
        comma=","
      else
        comma=""
      fi
      
      echo "    {"
      echo "      \"id\": $i,"
      echo "      \"name\": \"Waiter-$i\","
      echo '      "state": "BLOCKED",'
      echo '      "priority": 5,'
      echo '      "stack_trace": [],'
      echo '      "locks_held": [],'
      echo "      \"locks_waiting\": [\"Lock-$((i-1))\"]"
      echo "    }$comma"
    done
    
    echo '  ],'
    echo '  "locks": ['
    
    # Generate 100 locks
    for i in {1..100}; do
      if [[ $i -lt 100 ]]; then
        comma=","
      else
        comma=""
      fi
      
      echo "    {"
      echo "      \"identity\": \"Lock-$i\","
      echo "      \"owner_thread\": 1,"
      echo "      \"waiting_threads\": [$((i+1))]"
      echo "    }$comma"
    done
    
    echo '  ]'
    echo '}'
  } > "${TEST_TEMP_DIR}/many_locks.json"
  
  run generate_lock_contention_graph "${TEST_TEMP_DIR}/many_locks.json" "${TEST_TEMP_DIR}/output.md"
  
  assert_success
  assert [ -f "${TEST_TEMP_DIR}/output.md" ]
}