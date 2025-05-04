#!/usr/bin/env bash
# thread_safety_issues.bash
# Test doubles to simulate various thread safety issues in test environments
#
# This file INTENTIONALLY implements various thread safety antipatterns
# to allow MVNimble to detect and diagnose multithreading issues in test environments.
# Each simulation creates reproducible scenarios to demonstrate common concurrency
# problems that occur in multi-threaded applications and tests.
#
# ANTIPATTERNS IMPLEMENTED:
#
# 1. Race Conditions
#    - Concurrent access to shared resources without synchronization
#    - Non-atomic read-modify-write operations
#    - Time-of-check to time-of-use (TOCTOU) bugs
#
# 2. Thread Ordering Dependencies
#    - Tests that require other tests to run in specific order
#    - Initialization dependencies between threads
#    - Assumption of sequential execution in concurrent environment
#
# 3. Deadlocks
#    - Resource acquisition in different orders
#    - Circular wait conditions
#    - Lack of timeout mechanisms
#
# 4. Database Contention
#    - Connection pool exhaustion
#    - Concurrent transactions without proper isolation
#    - Lack of retry mechanisms for temporary failures
#
# 5. Test Isolation Issues
#    - Shared static state between tests
#    - Improper setup/teardown of test environments
#    - Tests that modify global state
#
# EDUCATIONAL PURPOSE:
# These simulations are deliberately designed to fail in specific ways to 
# demonstrate the typical symptoms of thread safety issues. They serve as
# teaching tools for understanding how to diagnose and fix concurrency problems.
# Each test function includes detailed commentary explaining why the issue
# occurs and how to properly fix it.

# Load test helpers
source "${BATS_TEST_DIRNAME:-$(dirname "$0")/..}/test_helper.bash"

# ------------------------------------------------------------------------------
# SHARED STATE ISSUES
# ------------------------------------------------------------------------------

# Simulates a shared static variable that causes thread safety issues
simulate_static_variable_conflict() {
  local variable_name="${1:-SHARED_STATIC_VAR}"
  local file_path="${2:-$(mktemp)}"
  
  # Create a file with a static variable that will be shared across threads
  cat > "$file_path" << EOF
# This file simulates a shared static variable that causes thread safety issues
${variable_name}=0

# Function to increment the shared variable
increment_${variable_name}() {
  # Read current value (non-atomic operation)
  local current_value=\$${variable_name}
  
  # Simulate thread scheduling delay
  sleep 0.$(( RANDOM % 10 + 1 ))
  
  # Increment (non-atomic operation)
  ${variable_name}=\$((current_value + 1))
  
  # Return new value
  echo \$${variable_name}
}

# Function to get the shared variable
get_${variable_name}() {
  echo \$${variable_name}
}
EOF
  
  # Source the file to make functions available
  source "$file_path"
  
  # Create a test function that demonstrates the issue
  test_static_variable_conflict() {
    local expected_value=10
    local threads=10
    
    # Reset variable
    eval "${variable_name}=0"
    
    # Run increment in parallel
    for i in $(seq 1 $threads); do
      eval "increment_${variable_name}" &
    done
    
    # Wait for all background jobs to complete
    wait
    
    # Get final value
    local final_value=$(eval "get_${variable_name}")
    
    # In thread-safe code, final_value should equal threads
    # but due to the race condition, it will likely be less
    echo "Expected: $expected_value, Actual: $final_value"
    [[ "$final_value" -eq "$expected_value" ]]
  }
  
  # Export the functions
  export -f test_static_variable_conflict
  
  # Return the file path for potential cleanup
  echo "$file_path"
}

# Simulates a shared file resource that causes thread safety issues
simulate_shared_file_conflict() {
  local file_path="${1:-$(mktemp)}"
  
  # Initialize the file
  echo "0" > "$file_path"
  
  # Create a test function that demonstrates the issue
  test_shared_file_conflict() {
    local expected_lines=10
    local threads=10
    
    # Reset file
    echo "0" > "$file_path"
    
    # Function to append to file
    append_to_file() {
      # Read current value
      local value=$(cat "$file_path")
      
      # Simulate thread scheduling delay
      sleep 0.$(( RANDOM % 10 + 1 ))
      
      # Increment
      value=$((value + 1))
      
      # Write back (potential race condition)
      echo "$value" > "$file_path"
    }
    
    # Export the function
    export -f append_to_file
    export file_path
    
    # Run append in parallel
    for i in $(seq 1 $threads); do
      bash -c 'append_to_file' &
    done
    
    # Wait for all background jobs to complete
    wait
    
    # Get final value
    local final_value=$(cat "$file_path")
    
    # In thread-safe code, final_value should equal threads
    # but due to the race condition, it will likely be less
    echo "Expected: $expected_lines, Actual: $final_value"
    [[ "$final_value" -eq "$expected_lines" ]]
  }
  
  # Export the functions
  export -f test_shared_file_conflict
  
  # Return the file path for potential cleanup
  echo "$file_path"
}

# ------------------------------------------------------------------------------
# DATABASE CONTENTION ISSUES
# ------------------------------------------------------------------------------

# Simulates database contention issues
simulate_database_contention() {
  local db_file="${1:-$(mktemp)}"
  local max_connections="${2:-5}"
  
  # Create a fake SQLite database to simulate contention
  if command -v sqlite3 >/dev/null 2>&1; then
    sqlite3 "$db_file" << EOF
CREATE TABLE connections (
  id INTEGER PRIMARY KEY,
  process_id INTEGER,
  status TEXT
);

CREATE TABLE test_data (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  test_name TEXT,
  value INTEGER
);
EOF
  else
    # Fallback to simple file-based "database"
    cat > "$db_file" << EOF
# Simple file-based database
connections=0
EOF
  fi
  
  # Create a function that simulates a database connection pool
  db_connection_pool() {
    local db_file="$1"
    local max_connections="$2"
    local action="$3"
    local params="$4"
    
    # Track connections
    local current_connections
    
    if command -v sqlite3 >/dev/null 2>&1; then
      # Use SQLite
      case "$action" in
        acquire)
          # Check current connections
          current_connections=$(sqlite3 "$db_file" "SELECT COUNT(*) FROM connections WHERE status='active';")
          
          if [[ "$current_connections" -ge "$max_connections" ]]; then
            echo "Error: Connection pool exhausted" >&2
            return 1
          fi
          
          # Add new connection
          local conn_id=$(sqlite3 "$db_file" "INSERT INTO connections (process_id, status) VALUES ($$, 'active') RETURNING id;")
          echo "$conn_id"
          ;;
        
        release)
          local conn_id="$params"
          sqlite3 "$db_file" "UPDATE connections SET status='inactive' WHERE id=$conn_id;"
          ;;
        
        query)
          local conn_id="$params"
          # Simulate query execution with potential contention
          local result=$(sqlite3 "$db_file" "SELECT value FROM test_data WHERE test_name='test1' LIMIT 1;")
          echo "${result:-0}"
          ;;
        
        update)
          local conn_id=$(echo "$params" | cut -d: -f1)
          local value=$(echo "$params" | cut -d: -f2)
          
          # Simulate update with potential race condition
          local current=$(sqlite3 "$db_file" "SELECT value FROM test_data WHERE test_name='test1' LIMIT 1;")
          
          if [[ -z "$current" ]]; then
            sqlite3 "$db_file" "INSERT INTO test_data (test_name, value) VALUES ('test1', $value);"
          else
            sqlite3 "$db_file" "UPDATE test_data SET value=$value WHERE test_name='test1';"
          fi
          ;;
      esac
    else
      # Use file-based approach
      case "$action" in
        acquire)
          # Check current connections
          source "$db_file"
          
          if [[ "$connections" -ge "$max_connections" ]]; then
            echo "Error: Connection pool exhausted" >&2
            return 1
          fi
          
          # Add new connection
          connections=$((connections + 1))
          echo "connections=$connections" > "$db_file"
          echo "$RANDOM"  # Return random connection ID
          ;;
        
        release)
          source "$db_file"
          connections=$((connections - 1))
          if [[ "$connections" -lt 0 ]]; then connections=0; fi
          echo "connections=$connections" > "$db_file"
          ;;
        
        query|update)
          # Simplified operation for file-based approach
          echo "0"
          ;;
      esac
    fi
  }
  
  # Create a test function that demonstrates database contention
  test_database_contention() {
    local threads=10
    local max_retries=3
    
    # Initialize test data
    if command -v sqlite3 >/dev/null 2>&1; then
      sqlite3 "$db_file" "DELETE FROM test_data WHERE test_name='test1';"
      sqlite3 "$db_file" "INSERT INTO test_data (test_name, value) VALUES ('test1', 0);"
    fi
    
    # Function to perform database operation
    db_operation() {
      local retry=0
      local conn_id
      
      # Try to acquire connection with retries
      while [[ "$retry" -lt "$max_retries" ]]; do
        conn_id=$(db_connection_pool "$db_file" "$max_connections" "acquire")
        
        if [[ $? -eq 0 ]]; then
          break
        fi
        
        retry=$((retry + 1))
        sleep 0.$(( RANDOM % 10 + 1 ))
      done
      
      # If we couldn't get a connection, fail
      if [[ -z "$conn_id" ]]; then
        echo "Failed to acquire database connection after $max_retries attempts" >&2
        return 1
      fi
      
      # Perform read-modify-write operation (prone to race conditions)
      local current_value=$(db_connection_pool "$db_file" "$max_connections" "query" "$conn_id")
      
      # Simulate processing delay
      sleep 0.$(( RANDOM % 10 + 1 ))
      
      # Update with incremented value
      local new_value=$((current_value + 1))
      db_connection_pool "$db_file" "$max_connections" "update" "$conn_id:$new_value"
      
      # Release connection
      db_connection_pool "$db_file" "$max_connections" "release" "$conn_id"
    }
    
    # Export functions and variables
    export -f db_operation
    export -f db_connection_pool
    export db_file
    export max_connections
    
    # Run operations in parallel
    for i in $(seq 1 $threads); do
      bash -c 'db_operation' &
    done
    
    # Wait for all background jobs to complete
    wait
    
    # Check final value
    local final_value
    if command -v sqlite3 >/dev/null 2>&1; then
      final_value=$(sqlite3 "$db_file" "SELECT value FROM test_data WHERE test_name='test1';")
    else
      final_value=0  # Simplified for file-based approach
    fi
    
    # Due to contention and lack of proper transactions,
    # final_value will likely be less than threads
    echo "Expected: $threads, Actual: $final_value"
    [[ "$final_value" -eq "$threads" ]]
  }
  
  # Export the functions
  export -f test_database_contention
  
  # Return the database file for potential cleanup
  echo "$db_file"
}

# ------------------------------------------------------------------------------
# DEADLOCK SIMULATIONS
# ------------------------------------------------------------------------------

# Simulates deadlock scenarios with multiple resources
simulate_deadlock() {
  local resource1_file="${1:-$(mktemp)}"
  local resource2_file="${2:-$(mktemp)}"
  
  # Initialize resource files
  echo "resource1" > "$resource1_file"
  echo "resource2" > "$resource2_file"
  
  # Create lock functions
  acquire_lock() {
    local resource_file="$1"
    local lock_file="${resource_file}.lock"
    
    # Try to create lock file
    if ( set -o noclobber; echo "$$" > "$lock_file" ) 2>/dev/null; then
      # Lock acquired
      return 0
    else
      # Lock failed
      return 1
    fi
  }
  
  release_lock() {
    local resource_file="$1"
    local lock_file="${resource_file}.lock"
    
    # Remove lock file
    rm -f "$lock_file"
  }
  
  # Create a test function that demonstrates deadlock
  test_deadlock() {
    # Process 1: tries to lock resource1 then resource2
    process1() {
      # Acquire first lock
      if ! acquire_lock "$resource1_file"; then
        echo "Process 1: Failed to lock resource 1" >&2
        return 1
      fi
      
      echo "Process 1: Acquired lock on resource 1"
      
      # Simulate work
      sleep 1
      
      # Try to acquire second lock
      if ! acquire_lock "$resource2_file"; then
        echo "Process 1: Failed to lock resource 2" >&2
        # Release first lock
        release_lock "$resource1_file"
        return 1
      fi
      
      echo "Process 1: Acquired lock on resource 2"
      
      # Do work with both resources
      echo "Process 1: $(cat "$resource1_file") + $(cat "$resource2_file")"
      
      # Release locks in reverse order
      release_lock "$resource2_file"
      release_lock "$resource1_file"
    }
    
    # Process 2: tries to lock resource2 then resource1 (reverse order)
    process2() {
      # Acquire first lock
      if ! acquire_lock "$resource2_file"; then
        echo "Process 2: Failed to lock resource 2" >&2
        return 1
      fi
      
      echo "Process 2: Acquired lock on resource 2"
      
      # Simulate work
      sleep 1
      
      # Try to acquire second lock
      if ! acquire_lock "$resource1_file"; then
        echo "Process 2: Failed to lock resource 1" >&2
        # Release first lock
        release_lock "$resource2_file"
        return 1
      fi
      
      echo "Process 2: Acquired lock on resource 1"
      
      # Do work with both resources
      echo "Process 2: $(cat "$resource2_file") + $(cat "$resource1_file")"
      
      # Release locks in reverse order
      release_lock "$resource1_file"
      release_lock "$resource2_file"
    }
    
    # Export functions and variables
    export -f process1
    export -f process2
    export -f acquire_lock
    export -f release_lock
    export resource1_file
    export resource2_file
    
    # Run processes in parallel
    bash -c 'process1' &
    local pid1=$!
    
    bash -c 'process2' &
    local pid2=$!
    
    # Wait for processes with timeout
    local timeout=5
    local start_time=$(date +%s)
    
    while kill -0 $pid1 2>/dev/null || kill -0 $pid2 2>/dev/null; do
      local current_time=$(date +%s)
      local elapsed=$((current_time - start_time))
      
      if [[ "$elapsed" -gt "$timeout" ]]; then
        # Deadlock likely occurred
        echo "Deadlock detected - killing processes" >&2
        kill -9 $pid1 2>/dev/null || true
        kill -9 $pid2 2>/dev/null || true
        break
      fi
      
      sleep 0.1
    done
    
    # Clean up lock files
    rm -f "${resource1_file}.lock" "${resource2_file}.lock"
    
    # Return whether deadlock occurred (timeout reached)
    local end_time=$(date +%s)
    local total_time=$((end_time - start_time))
    
    echo "Execution time: ${total_time}s (timeout: ${timeout}s)"
    [[ "$total_time" -lt "$timeout" ]]
  }
  
  # Export the main test function
  export -f test_deadlock
  
  # Return resource files for cleanup
  echo "$resource1_file $resource2_file"
}

# ------------------------------------------------------------------------------
# RACE CONDITION SIMULATIONS
# ------------------------------------------------------------------------------

# Simulates timing-dependent race conditions
simulate_race_condition() {
  local flag_file="${1:-$(mktemp)}"
  
  # Initialize flag file
  echo "0" > "$flag_file"
  
  # Create a test function that demonstrates a race condition
  test_race_condition() {
    local iterations=10
    local successes=0
    
    # Function with a race condition
    race_function() {
      # Check if flag is set
      local flag=$(cat "$flag_file")
      
      # Critical section: should only run if flag is 0
      if [[ "$flag" -eq 0 ]]; then
        # Simulate delay between check and action (where race occurs)
        sleep 0.$(( RANDOM % 10 + 1 ))
        
        # Set flag to indicate we're in critical section
        echo "1" > "$flag_file"
        
        # Perform "critical section" work
        echo "Thread $$ entered critical section"
        
        # Simulate work
        sleep 0.$(( RANDOM % 10 + 5 ))
        
        # Release flag
        echo "0" > "$flag_file"
        return 0
      else
        echo "Thread $$ found flag already set"
        return 1
      fi
    }
    
    # Run multiple races to demonstrate the issue
    for i in $(seq 1 $iterations); do
      # Reset flag
      echo "0" > "$flag_file"
      
      # Launch competing threads
      bash -c 'race_function' > "${flag_file}.1.log" 2>&1 &
      local pid1=$!
      
      # Introduce slight delay to control race timing
      sleep 0.$(( RANDOM % 5 + 1 ))
      
      bash -c 'race_function' > "${flag_file}.2.log" 2>&1 &
      local pid2=$!
      
      # Wait for both to complete
      wait $pid1
      wait $pid2
      
      # Check results - look for both threads entering critical section
      if grep -q "entered critical section" "${flag_file}.1.log" && 
         grep -q "entered critical section" "${flag_file}.2.log"; then
        echo "Race condition detected in iteration $i - both threads entered critical section"
        successes=$((successes + 1))
      fi
    done
    
    # Clean up log files
    rm -f "${flag_file}".*.log
    
    # Return success based on whether we demonstrated the race condition
    echo "Demonstrated race condition in $successes/$iterations iterations"
    [[ "$successes" -gt 0 ]]
  }
  
  # Export functions and variables
  export -f test_race_condition
  export -f race_function
  export flag_file
  
  # Return the flag file for potential cleanup
  echo "$flag_file"
}

# ------------------------------------------------------------------------------
# THREAD ORDERING ISSUES
# ------------------------------------------------------------------------------

# Simulates thread ordering dependency issues
simulate_thread_ordering_dependency() {
  local dependency_file="${1:-$(mktemp)}"
  
  # Initialize dependency file
  echo "not_initialized" > "$dependency_file"
  
  # Create a test function that demonstrates thread ordering dependency
  test_thread_ordering() {
    # Thread 1: Sets up environment that thread 2 depends on
    setup_thread() {
      # Simulate varying execution time
      sleep 0.$(( RANDOM % 10 + 1 ))
      
      # Initialize dependency
      echo "initialized" > "$dependency_file"
      echo "Setup thread: dependency initialized"
    }
    
    # Thread 2: Depends on thread 1 having completed
    dependent_thread() {
      # Check if dependency is initialized
      local status=$(cat "$dependency_file")
      
      if [[ "$status" == "initialized" ]]; then
        echo "Dependent thread: dependency correctly initialized"
        return 0
      else
        echo "Dependent thread: dependency NOT initialized, failing" >&2
        return 1
      fi
    }
    
    # Export functions and variables
    export -f setup_thread
    export -f dependent_thread
    export dependency_file
    
    # Run multiple iterations to demonstrate ordering issues
    local iterations=10
    local failures=0
    
    for i in $(seq 1 $iterations); do
      # Reset dependency
      echo "not_initialized" > "$dependency_file"
      
      # Launch dependent thread first (incorrect order)
      bash -c 'dependent_thread' > "${dependency_file}.dep.log" 2>&1 &
      local pid1=$!
      
      # Launch setup thread with delay
      sleep 0.$(( RANDOM % 3 ))  # Random delay to vary outcome
      bash -c 'setup_thread' > "${dependency_file}.setup.log" 2>&1 &
      local pid2=$!
      
      # Wait for both to complete
      wait $pid1
      local dep_status=$?
      wait $pid2
      
      # Check if dependent thread failed (expected in most iterations due to order)
      if [[ "$dep_status" -ne 0 ]]; then
        failures=$((failures + 1))
      fi
    done
    
    # Clean up log files
    rm -f "${dependency_file}".*.log
    
    # Return success based on whether we demonstrated the ordering issue
    echo "Demonstrated ordering issue in $failures/$iterations iterations"
    [[ "$failures" -gt 0 ]]
  }
  
  # Export the test function
  export -f test_thread_ordering
  
  # Return the dependency file for potential cleanup
  echo "$dependency_file"
}

# ------------------------------------------------------------------------------
# TEST ISOLATION ISSUES
# ------------------------------------------------------------------------------

# Simulates test isolation issues where tests affect each other
simulate_test_isolation_issue() {
  local shared_state_file="${1:-$(mktemp)}"
  
  # Initialize shared state
  echo "initial_state" > "$shared_state_file"
  
  # Function to represent a test that modifies shared state
  test_modifies_state() {
    echo "test_modified_state" > "$shared_state_file"
    echo "Test 1: Modified shared state"
    return 0
  }
  
  # Function to represent a test that depends on initial state
  test_expects_initial_state() {
    local state=$(cat "$shared_state_file")
    
    if [[ "$state" == "initial_state" ]]; then
      echo "Test 2: Found expected initial state"
      return 0
    else
      echo "Test 2: ERROR - Expected initial state, found: $state" >&2
      return 1
    fi
  }
  
  # Create a test function that demonstrates isolation issues
  test_isolation_issue() {
    # Reset shared state
    echo "initial_state" > "$shared_state_file"
    
    # Export functions and variables
    export -f test_modifies_state
    export -f test_expects_initial_state
    export shared_state_file
    
    # Run tests in two different orders to show issue
    
    echo "=== Running tests in order that works ==="
    # Order 1: test_expects_initial_state, then test_modifies_state
    bash -c 'test_expects_initial_state' && bash -c 'test_modifies_state'
    local order1_status=$?
    
    # Reset shared state
    echo "initial_state" > "$shared_state_file"
    
    echo "=== Running tests in order that fails ==="
    # Order 2: test_modifies_state, then test_expects_initial_state
    bash -c 'test_modifies_state' && bash -c 'test_expects_initial_state'
    local order2_status=$?
    
    # In a proper test suite, both orders should pass
    # But with isolation issues, one order will fail
    echo "Order 1 status: $order1_status"
    echo "Order 2 status: $order2_status"
    
    # Return success if we demonstrated the isolation issue
    [[ "$order1_status" -eq 0 && "$order2_status" -ne 0 ]]
  }
  
  # Export the test function
  export -f test_isolation_issue
  
  # Return the shared state file for potential cleanup
  echo "$shared_state_file"
}

# ------------------------------------------------------------------------------
# THREAD SIMULATION HELPER
# ------------------------------------------------------------------------------

# Helper to run tests with various thread configurations
run_with_thread_issues() {
  local test_function="$1"
  local issue_type="$2"
  local threads="${3:-4}"
  local iterations="${4:-3}"
  
  # Setup based on issue type
  local cleanup_file=""
  
  case "$issue_type" in
    static_variable)
      cleanup_file=$(simulate_static_variable_conflict)
      ;;
    shared_file)
      cleanup_file=$(simulate_shared_file_conflict)
      ;;
    database)
      cleanup_file=$(simulate_database_contention)
      ;;
    deadlock)
      cleanup_file=$(simulate_deadlock)
      ;;
    race)
      cleanup_file=$(simulate_race_condition)
      ;;
    ordering)
      cleanup_file=$(simulate_thread_ordering_dependency)
      ;;
    isolation)
      cleanup_file=$(simulate_test_isolation_issue)
      ;;
    *)
      echo "Unknown thread issue type: $issue_type" >&2
      return 1
      ;;
  esac
  
  # Run the actual test
  local success_count=0
  
  for i in $(seq 1 $iterations); do
    echo "=== Iteration $i ==="
    
    # Run the appropriate test function
    case "$issue_type" in
      static_variable)
        test_static_variable_conflict && success_count=$((success_count + 1))
        ;;
      shared_file)
        test_shared_file_conflict && success_count=$((success_count + 1))
        ;;
      database)
        test_database_contention && success_count=$((success_count + 1))
        ;;
      deadlock)
        test_deadlock && success_count=$((success_count + 1))
        ;;
      race)
        test_race_condition && success_count=$((success_count + 1))
        ;;
      ordering)
        test_thread_ordering && success_count=$((success_count + 1))
        ;;
      isolation)
        test_isolation_issue && success_count=$((success_count + 1))
        ;;
    esac
  done
  
  # Clean up
  if [[ -n "$cleanup_file" ]]; then
    # Handle space-separated list of files
    for file in $cleanup_file; do
      rm -f "$file" "${file}".*
    done
  fi
  
  # Report results
  echo "=== Thread Issue Test Results ==="
  echo "Issue type: $issue_type"
  echo "Successfully demonstrated issue in $success_count/$iterations iterations"
  
  # Return success based on whether we demonstrated the issue at least once
  [[ "$success_count" -gt 0 ]]
}