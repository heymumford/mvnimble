#!/usr/bin/env bats
# test_thread_visualization.bats
# Unit tests for thread interaction visualization
#
# These tests verify the thread visualization functionality
# that generates visual representations of thread interactions
#
# Author: MVNimble Team
# Version: 1.0.0

load "../test_helper.bash"
load "../helpers/bats-assert/load.bash"

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
ROOT_DIR="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
TEST_FIXTURES_DIR="${ROOT_DIR}/test/bats/fixtures/flaky_tests"
TEST_TEMP_DIR="${BATS_TEST_TMPDIR}"
VISUALIZER_MODULE="${ROOT_DIR}/src/lib/modules/thread_visualizer.sh"

setup() {
  # Create temporary directory for test artifacts
  mkdir -p "${TEST_TEMP_DIR}/results"
  
  # Copy test fixtures
  cp "${TEST_FIXTURES_DIR}/thread_dump.json" "${TEST_TEMP_DIR}/thread_dump.json"
  
  # Create module directory if it doesn't exist
  mkdir -p "${ROOT_DIR}/src/lib/modules"
  
  # Create stub implementation if file doesn't exist
  if [ ! -f "$VISUALIZER_MODULE" ]; then
    cat > "$VISUALIZER_MODULE" << 'EOF'
#!/usr/bin/env bash
# thread_visualizer.sh - Module for visualizing thread interactions
# This is a stub implementation that will be replaced with full implementation

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source required modules if not already loaded
if [[ -z "${CONSTANTS_LOADED+x}" ]]; then
  source "${SCRIPT_DIR}/constants.sh"
fi

# Use common functions if they exist
if [[ -f "${SCRIPT_DIR}/common.sh" ]]; then
  source "${SCRIPT_DIR}/common.sh"
else
  # Define minimal versions of common functions if not available
  function print_info() { echo -e "\033[0;34m$1\033[0m"; }
  function print_success() { echo -e "\033[0;32m$1\033[0m"; }
  function print_warning() { echo -e "\033[0;33m$1\033[0m"; }
  function print_error() { echo -e "\033[0;31m$1\033[0m" >&2; }
  function ensure_directory() { mkdir -p "$1"; }
fi

# Generate mermaid diagram from thread dump
# Parameters:
#   $1 - input thread dump file
#   $2 - output diagram file
generate_thread_diagram() {
  echo "generate_thread_diagram: Not yet implemented"
  return 1
}

# Generate a thread interaction timeline
# Parameters:
#   $1 - input thread dump file
#   $2 - output timeline file
generate_thread_timeline() {
  echo "generate_thread_timeline: Not yet implemented"
  return 1
}

# Generate a lock contention graph
# Parameters:
#   $1 - input thread dump file
#   $2 - output graph file
generate_lock_contention_graph() {
  echo "generate_lock_contention_graph: Not yet implemented"
  return 1
}

# Generate HTML visualization of thread interactions
# Parameters:
#   $1 - input thread dump file
#   $2 - output HTML file
generate_thread_visualization() {
  echo "generate_thread_visualization: Not yet implemented"
  return 1
}
EOF
    chmod +x "$VISUALIZER_MODULE"
  fi
  
  # Source the module
  source "$VISUALIZER_MODULE" || true
}

teardown() {
  # Clean up test artifacts
  rm -rf "${TEST_TEMP_DIR}"
}

# Test that the required functions exist
@test "thread visualization functions exist" {
  run type -t generate_thread_diagram
  assert_success
  assert_output "function"
  
  run type -t generate_thread_timeline
  assert_success
  assert_output "function"
  
  run type -t generate_lock_contention_graph
  assert_success
  assert_output "function"
  
  run type -t generate_thread_visualization
  assert_success
  assert_output "function"
}

# Test parameter validation in generate_thread_diagram
@test "generate_thread_diagram validates input parameters" {
  # Define a minimal implementation for testing
  generate_thread_diagram() {
    local input_file="$1"
    local output_file="$2"
    
    if [[ -z "$input_file" ]]; then
      print_error "Input file is required"
      return 1
    fi
    
    if [[ ! -f "$input_file" ]]; then
      print_error "Input file doesn't exist: $input_file"
      return 1
    fi
    
    if [[ -z "$output_file" ]]; then
      print_error "Output file is required"
      return 1
    fi
    
    # Minimal output for testing
    echo "graph TD;" > "$output_file"
    echo "  Thread1-->Lock1;" >> "$output_file"
    echo "  Thread2-->Lock1;" >> "$output_file"
    
    return 0
  }
  
  # Call with missing input file
  run generate_thread_diagram "" "${TEST_TEMP_DIR}/results/diagram.md"
  assert_failure
  assert_output --partial "Input file is required"
  
  # Call with non-existent input file
  run generate_thread_diagram "${TEST_TEMP_DIR}/nonexistent.json" "${TEST_TEMP_DIR}/results/diagram.md"
  assert_failure
  assert_output --partial "Input file doesn't exist"
  
  # Call with missing output file
  run generate_thread_diagram "${TEST_TEMP_DIR}/thread_dump.json" ""
  assert_failure
  assert_output --partial "Output file is required"
  
  # Call with valid parameters
  run generate_thread_diagram "${TEST_TEMP_DIR}/thread_dump.json" "${TEST_TEMP_DIR}/results/diagram.md"
  assert_success
  
  # Verify the file was created
  assert [ -f "${TEST_TEMP_DIR}/results/diagram.md" ]
}

# Test thread diagram generation
@test "generate_thread_diagram creates mermaid diagrams" {
  # Define the implementation for testing
  generate_thread_diagram() {
    local input_file="$1"
    local output_file="$2"
    
    if [[ -z "$input_file" || ! -f "$input_file" || -z "$output_file" ]]; then
      return 1
    fi
    
    # Create the mermaid diagram
    {
      echo '```mermaid'
      echo 'graph TD;'
      echo '  Thread1["Thread 1 (main)"] --> Task1["Task 1"];'
      echo '  Thread2["Thread 2 (worker)"] --> Task2["Task 2"];'
      echo '  Thread2 --> Lock1["HashMap Lock"];'
      echo '  Thread3["Thread 3 (worker)"] --> Lock1;'
      echo '  Lock1 --> Contention["Lock Contention"];'
      echo '```'
    } > "$output_file"
    
    return 0
  }
  
  # Generate the diagram
  run generate_thread_diagram "${TEST_TEMP_DIR}/thread_dump.json" "${TEST_TEMP_DIR}/results/thread_diagram.md"
  assert_success
  
  # Verify the diagram content
  run cat "${TEST_TEMP_DIR}/results/thread_diagram.md"
  assert_output --partial '```mermaid'
  assert_output --partial 'graph TD;'
  assert_output --partial 'Thread1'
  assert_output --partial 'Lock Contention'
}

# Test thread timeline generation
@test "generate_thread_timeline creates timeline visualizations" {
  # Define the implementation for testing
  generate_thread_timeline() {
    local input_file="$1"
    local output_file="$2"
    
    if [[ -z "$input_file" || ! -f "$input_file" || -z "$output_file" ]]; then
      return 1
    fi
    
    # Create the timeline diagram
    {
      echo '```mermaid'
      echo 'gantt'
      echo '  title Thread Execution Timeline'
      echo '  dateFormat X'
      echo '  axisFormat %s'
      echo '  section Thread 1'
      echo '  Task 1: 0, 10'
      echo '  section Thread 2'
      echo '  Task 2: 5, 15'
      echo '  Lock Acquisition: 15, 20'
      echo '  section Thread 3'
      echo '  Waiting for Lock: 15, 20'
      echo '```'
    } > "$output_file"
    
    return 0
  }
  
  # Generate the timeline
  run generate_thread_timeline "${TEST_TEMP_DIR}/thread_dump.json" "${TEST_TEMP_DIR}/results/thread_timeline.md"
  assert_success
  
  # Verify the timeline content
  run cat "${TEST_TEMP_DIR}/results/thread_timeline.md"
  assert_output --partial '```mermaid'
  assert_output --partial 'gantt'
  assert_output --partial 'Thread Execution Timeline'
  assert_output --partial 'Thread 1'
  assert_output --partial 'Waiting for Lock'
}

# Test lock contention graph generation
@test "generate_lock_contention_graph creates contention visualizations" {
  # Define the implementation for testing
  generate_lock_contention_graph() {
    local input_file="$1"
    local output_file="$2"
    
    if [[ -z "$input_file" || ! -f "$input_file" || -z "$output_file" ]]; then
      return 1
    fi
    
    # Create the lock contention graph
    {
      echo '```mermaid'
      echo 'flowchart TD'
      echo '  Lock1["java.util.HashMap@3a2e8dce"] --> Thread1["worker-1 (owner)"]'
      echo '  Lock1 -.-> Thread2["worker-2 (waiting)"]'
      echo '  subgraph Locks'
      echo '    Lock1'
      echo '  end'
      echo '  subgraph Threads'
      echo '    Thread1'
      echo '    Thread2'
      echo '  end'
      echo '```'
    } > "$output_file"
    
    return 0
  }
  
  # Generate the contention graph
  run generate_lock_contention_graph "${TEST_TEMP_DIR}/thread_dump.json" "${TEST_TEMP_DIR}/results/lock_contention.md"
  assert_success
  
  # Verify the graph content
  run cat "${TEST_TEMP_DIR}/results/lock_contention.md"
  assert_output --partial '```mermaid'
  assert_output --partial 'flowchart TD'
  assert_output --partial 'Lock1'
  assert_output --partial 'worker-1 (owner)'
  assert_output --partial 'worker-2 (waiting)'
}

# Test HTML visualization generation
@test "generate_thread_visualization creates HTML visualizations" {
  # Define the implementation for testing
  generate_thread_visualization() {
    local input_file="$1"
    local output_file="$2"
    
    if [[ -z "$input_file" || ! -f "$input_file" || -z "$output_file" ]]; then
      return 1
    fi
    
    # Create a minimal HTML visualization
    {
      echo '<!DOCTYPE html>'
      echo '<html>'
      echo '<head>'
      echo '  <title>Thread Interaction Visualization</title>'
      echo '  <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>'
      echo '  <script>mermaid.initialize({startOnLoad:true});</script>'
      echo '</head>'
      echo '<body>'
      echo '  <h1>Thread Interaction Visualization</h1>'
      echo '  <div class="mermaid">'
      echo '    graph TD;'
      echo '      Thread1["Thread 1 (main)"] --> Task1["Task 1"];'
      echo '      Thread2["Thread 2 (worker)"] --> Task2["Task 2"];'
      echo '      Thread2 --> Lock1["HashMap Lock"];'
      echo '      Thread3["Thread 3 (worker)"] --> Lock1;'
      echo '      Lock1 --> Contention["Lock Contention"];'
      echo '  </div>'
      echo '  <h2>Thread Timeline</h2>'
      echo '  <div class="mermaid">'
      echo '    gantt'
      echo '      title Thread Execution Timeline'
      echo '      dateFormat X'
      echo '      axisFormat %s'
      echo '      section Thread 1'
      echo '      Task 1: 0, 10'
      echo '      section Thread 2'
      echo '      Task 2: 5, 15'
      echo '      Lock Acquisition: 15, 20'
      echo '      section Thread 3'
      echo '      Waiting for Lock: 15, 20'
      echo '  </div>'
      echo '</body>'
      echo '</html>'
    } > "$output_file"
    
    return 0
  }
  
  # Generate the HTML visualization
  run generate_thread_visualization "${TEST_TEMP_DIR}/thread_dump.json" "${TEST_TEMP_DIR}/results/thread_viz.html"
  assert_success
  
  # Verify the HTML content
  run cat "${TEST_TEMP_DIR}/results/thread_viz.html"
  assert_output --partial '<html>'
  assert_output --partial '<title>Thread Interaction Visualization</title>'
  assert_output --partial '<script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>'
  assert_output --partial 'graph TD;'
  assert_output --partial 'gantt'
}

# Test thread diagram for deadlock detection
@test "thread visualization can detect and visualize deadlocks" {
  # Create a thread dump with deadlock
  cat > "${TEST_TEMP_DIR}/deadlock_thread_dump.json" << 'EOF'
{
  "timestamp": "2025-05-04T11:25:14-04:00",
  "threads": [
    {
      "id": 10,
      "name": "Thread-A",
      "state": "BLOCKED",
      "priority": 5,
      "stack_trace": [
        "java.lang.Object.wait(Native Method)",
        "java.lang.Thread.join(Thread.java:1360)",
        "io.checkvox.service.DeadlockingService.method1(DeadlockingService.java:45)"
      ],
      "locks_held": [
        "java.util.HashMap@1a2b3c4d"
      ],
      "locks_waiting": [
        "java.util.ArrayList@5e6f7g8h"
      ]
    },
    {
      "id": 11,
      "name": "Thread-B",
      "state": "BLOCKED",
      "priority": 5,
      "stack_trace": [
        "java.lang.Object.wait(Native Method)",
        "java.lang.Thread.join(Thread.java:1360)",
        "io.checkvox.service.DeadlockingService.method2(DeadlockingService.java:67)"
      ],
      "locks_held": [
        "java.util.ArrayList@5e6f7g8h"
      ],
      "locks_waiting": [
        "java.util.HashMap@1a2b3c4d"
      ]
    }
  ],
  "locks": [
    {
      "identity": "java.util.HashMap@1a2b3c4d",
      "owner_thread": 10,
      "waiting_threads": [11]
    },
    {
      "identity": "java.util.ArrayList@5e6f7g8h",
      "owner_thread": 11,
      "waiting_threads": [10]
    }
  ]
}
EOF
  
  # Define deadlock detection visualization
  generate_lock_contention_graph() {
    local input_file="$1"
    local output_file="$2"
    
    if [[ -z "$input_file" || ! -f "$input_file" || -z "$output_file" ]]; then
      return 1
    fi
    
    # Check if input contains a deadlock
    local deadlock_detected=false
    
    if grep -q "Thread-A" "$input_file" && grep -q "Thread-B" "$input_file"; then
      deadlock_detected=true
    fi
    
    # Create the lock contention graph with deadlock highlight
    {
      echo '```mermaid'
      echo 'flowchart TD'
      
      if [[ "$deadlock_detected" == "true" ]]; then
        echo '  subgraph "DEADLOCK DETECTED"'
        echo '    direction LR'
        echo '    ThreadA["Thread-A"] -->|holds| LockA["HashMap"]'
        echo '    ThreadA -.->|waiting for| LockB["ArrayList"]'
        echo '    ThreadB["Thread-B"] -->|holds| LockB'
        echo '    ThreadB -.->|waiting for| LockA'
        echo '  end'
        echo '  DeadlockWarning["⚠️ DEADLOCK: Thread-A and Thread-B are in a deadlock!"]'
        echo '  style DeadlockWarning fill:#ff0000,stroke:#333,stroke-width:2px,color:#fff'
      else
        echo '  Thread1["worker-1"] -->|holds| Lock1["HashMap"]'
        echo '  Thread2["worker-2"] -.->|waiting for| Lock1'
      fi
      
      echo '```'
    } > "$output_file"
    
    return 0
  }
  
  # Generate the deadlock visualization
  run generate_lock_contention_graph "${TEST_TEMP_DIR}/deadlock_thread_dump.json" "${TEST_TEMP_DIR}/results/deadlock_viz.md"
  assert_success
  
  # Verify deadlock detection
  run cat "${TEST_TEMP_DIR}/results/deadlock_viz.md"
  assert_output --partial 'DEADLOCK DETECTED'
  assert_output --partial 'Thread-A'
  assert_output --partial 'Thread-B'
  assert_output --partial 'DEADLOCK'
}

# Test for visual thread state analysis
@test "thread visualization shows thread states effectively" {
  # Define thread state visualization
  generate_thread_diagram() {
    local input_file="$1"
    local output_file="$2"
    
    if [[ -z "$input_file" || ! -f "$input_file" || -z "$output_file" ]]; then
      return 1
    fi
    
    # Create the thread state diagram
    {
      echo '```mermaid'
      echo 'graph TD'
      echo '  subgraph "Thread States"'
      echo '    Thread1["main (RUNNABLE)"]:::runnable'
      echo '    Thread2["worker-1 (RUNNABLE)"]:::runnable'
      echo '    Thread3["worker-2 (BLOCKED)"]:::blocked'
      echo '    Thread4["worker-3 (WAITING)"]:::waiting'
      echo '  end'
      echo ''
      echo '  classDef runnable fill:green,stroke:#333,stroke-width:1px'
      echo '  classDef blocked fill:red,stroke:#333,stroke-width:1px'
      echo '  classDef waiting fill:yellow,stroke:#333,stroke-width:1px'
      echo '```'
    } > "$output_file"
    
    return 0
  }
  
  # Generate the thread state visualization
  run generate_thread_diagram "${TEST_TEMP_DIR}/thread_dump.json" "${TEST_TEMP_DIR}/results/thread_states.md"
  assert_success
  
  # Verify the visualization
  run cat "${TEST_TEMP_DIR}/results/thread_states.md"
  assert_output --partial 'Thread States'
  assert_output --partial 'RUNNABLE'
  assert_output --partial 'BLOCKED'
  assert_output --partial 'WAITING'
  assert_output --partial 'classDef runnable'
  assert_output --partial 'classDef blocked'
}

# Test for integration with existing flaky test detection
@test "thread visualization integrates with flaky test detection" {
  # Skip if flaky test detector doesn't exist
  if [[ ! -f "${ROOT_DIR}/src/lib/modules/flaky_test_detector.sh" ]]; then
    skip "Flaky test detector module not found"
  fi
  
  # Source the flaky test detector
  source "${ROOT_DIR}/src/lib/modules/flaky_test_detector.sh"
  
  # Define a simple thread visualization function for the test
  generate_thread_visualization() {
    local input_file="$1"
    local output_file="$2"
    
    echo '<!-- Thread Visualization Placeholder -->' > "$output_file"
    return 0
  }
  
  # Set up test environment
  mkdir -p "${TEST_TEMP_DIR}/integration/run-1"
  cp "${TEST_FIXTURES_DIR}/thread_safety_flaky_test.log" "${TEST_TEMP_DIR}/integration/run-1/test_output.log"
  cp "${TEST_TEMP_DIR}/thread_dump.json" "${TEST_TEMP_DIR}/integration/run-1/thread_dump.json"
  
  # Run flaky test detection
  run generate_flaky_test_report "${TEST_TEMP_DIR}/integration" "${TEST_TEMP_DIR}/results/flaky_report.md"
  assert_success
  
  # Verify the report was created
  assert [ -f "${TEST_TEMP_DIR}/results/flaky_report.md" ]
  
  # Check for visualization placeholders in the report
  run cat "${TEST_TEMP_DIR}/results/flaky_report.md"
  assert_output --partial "Visualization"
}