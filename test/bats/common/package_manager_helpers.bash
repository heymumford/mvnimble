#\!/usr/bin/env bash
# package_manager_helpers.bash
# Helper functions for testing package manager functionality

# Load environment helpers
load environment_helpers

# Parse Maven test output for key metrics
parse_maven_test_output() {
  local output="$1"
  
  # Extract test counts
  local tests_run=$(echo "$output" | grep -oE "Tests run: [0-9]+" | grep -oE "[0-9]+" | head -1)
  local failures=$(echo "$output" | grep -oE "Failures: [0-9]+" | grep -oE "[0-9]+" | head -1)
  local errors=$(echo "$output" | grep -oE "Errors: [0-9]+" | grep -oE "[0-9]+" | head -1)
  local skipped=$(echo "$output" | grep -oE "Skipped: [0-9]+" | grep -oE "[0-9]+" | head -1)
  
  # Extract execution time
  local execution_time=$(echo "$output" | grep -oE "Total time:  [0-9.]+ s" | grep -oE "[0-9.]+" | head -1)
  
  # Create result object
  echo "{\"tests\":$tests_run,\"failures\":${failures:-0},\"errors\":${errors:-0},\"skipped\":${skipped:-0},\"time\":$execution_time}"
}

# Analyze Maven test output for thread safety issues
detect_thread_safety_issues() {
  local output="$1"
  
  # Check for common thread safety issues
  local concurrent_issues=$(echo "$output" | grep -c "ConcurrentModificationException")
  local race_conditions=$(echo "$output" | grep -c "Race condition detected")
  local deadlocks=$(echo "$output" | grep -c "DeadlockError")
  local illegal_monitor=$(echo "$output" | grep -c "IllegalMonitorStateException")
  
  # Count total thread safety issues
  local total_issues=$((concurrent_issues + race_conditions + deadlocks + illegal_monitor))
  
  # Create result object
  echo "{\"total_issues\":$total_issues,\"concurrent_exceptions\":$concurrent_issues,\"race_conditions\":$race_conditions,\"deadlocks\":$deadlocks,\"monitor_exceptions\":$illegal_monitor}"
}

# Generate Maven command with optimized settings
generate_optimized_maven_command() {
  local cpu_count="$1"
  local memory_mb="$2"
  local thread_count="$3"
  
  # Calculate optimal settings if not provided
  [[ -z "$cpu_count" ]] && cpu_count=$(get_cpu_count)
  [[ -z "$memory_mb" ]] && memory_mb=$(get_memory_info)
  [[ -z "$thread_count" ]] && thread_count=$((cpu_count * 2))
  
  # Calculate optimal heap size (70% of available memory)
  local heap_size=$((memory_mb * 70 / 100))
  
  # Generate command
  echo "mvn clean test -T ${cpu_count}C -Dmaven.test.failure.ignore=true -Dsurefire.useFile=false -Djava.io.tmpdir=/tmp -DargLine=\"-Xms${heap_size}m -Xmx${heap_size}m -XX:+UseG1GC -XX:+HeapDumpOnOutOfMemoryError\""
}

# Generate Maven parallel test command
generate_parallel_test_command() {
  local parallel_mode="$1"  # classes, methods, both, etc.
  local thread_count="$2"
  
  # Set defaults if not provided
  [[ -z "$parallel_mode" ]] && parallel_mode="both"
  [[ -z "$thread_count" ]] && thread_count=$(get_cpu_count)
  
  # Generate command
  echo "mvn test -Dsurefire.parallel=${parallel_mode} -DforkCount=1C -DreuseForks=true -DperCoreThreadCount=false -DthreadCount=${thread_count}"
}

# Parse dependency tree for insights
analyze_dependency_tree() {
  local output="$1"
  
  # Count total dependencies
  local total_deps=$(echo "$output" | grep -c "\- ")
  
  # Count direct dependencies
  local direct_deps=$(echo "$output" | grep -c "^\[INFO\] +\- ")
  
  # Count transitive dependencies
  local transitive_deps=$((total_deps - direct_deps))
  
  # Count test dependencies
  local test_deps=$(echo "$output" | grep -c "test")
  
  # Create result object
  echo "{\"total\":$total_deps,\"direct\":$direct_deps,\"transitive\":$transitive_deps,\"test\":$test_deps}"
}