#!/usr/bin/env bash
# pairwise_test_matrix.bash
# Comprehensive pairwise test matrix for problem simulators
#
# This file implements a sophisticated combinatorial testing framework for
# simulating multiple interacting failure conditions in Maven builds.
# It uses pairwise testing techniques to efficiently explore the vast
# space of possible combinations of performance issues.
#
# TESTING APPROACH:
#
# Instead of exhaustively testing all possible combinations of issues
# (which would be computationally infeasible), this framework uses 
# pairwise (2-way) or higher-order combinatorial testing to create an efficient
# test matrix that covers all important interactions with a minimal number of test cases.
#
# The framework combines:
# - CPU constraints (none/low/medium/high)
# - Memory constraints (none/low/medium/high)
# - Disk issues (none/slow/full)
# - Network problems (none/latency/loss/disconnected)
# - Thread safety issues (none/race/deadlock/isolation)
# - I/O problems (none/throttled/interrupted)
# - Repository issues (none/missing/corrupted/intermittent)
# - Temporary directory issues (none/space/permissions)
#
# BENEFITS:
#
# 1. Identifies complex interactions between different problem types
# 2. Discovers obscure bugs that only manifest with multiple issues present
# 3. Systematically explores failure space with minimal test cases
# 4. Provides structured approach to reproducing complex real-world scenarios
# 5. Helps develop more resilient build systems by understanding issue interactions
#
# This approach is particularly valuable for QA engineers and build system
# developers who need to ensure their systems remain reliable even under
# multiple concurrent adverse conditions.

# Load all problem simulators
source "${BATS_TEST_DIRNAME:-$(dirname "$0")/..}/test_helper.bash"
source "${BATS_TEST_DIRNAME:-$(dirname "$0")}/resource_constraints.bash"
source "${BATS_TEST_DIRNAME:-$(dirname "$0")}/thread_safety_issues.bash"
source "${BATS_TEST_DIRNAME:-$(dirname "$0")}/network_io_bottlenecks.bash"

# ------------------------------------------------------------------------------
# PROBLEM CATEGORIES AND LEVELS
# ------------------------------------------------------------------------------

# Define problem categories and their possible values
declare -A PROBLEM_CATEGORIES
PROBLEM_CATEGORIES=(
  ["cpu"]="none low medium high"
  ["memory"]="none low medium high"
  ["disk"]="none slow full"
  ["network"]="none latency loss disconnected"
  ["thread"]="none race deadlock isolation"
  ["io"]="none throttled interrupted"
  ["repo"]="none missing corrupted intermittent"
  ["temp"]="none space permissions"
)

# ------------------------------------------------------------------------------
# PROBLEM SIMULATION FUNCTIONS
# ------------------------------------------------------------------------------

# Apply a specific problem constraint
apply_problem() {
  local category="$1"
  local level="$2"
  
  # Skip if level is "none"
  if [[ "$level" == "none" ]]; then
    return 0
  fi
  
  echo "Applying problem: $category=$level"
  
  # Handle each category and level
  case "$category" in
    cpu)
      case "$level" in
        low)
          simulate_high_cpu_load 30
          ;;
        medium)
          simulate_high_cpu_load 60
          ;;
        high)
          simulate_high_cpu_load 90
          ;;
      esac
      ;;
    
    memory)
      case "$level" in
        low)
          simulate_memory_pressure 50
          ;;
        medium)
          simulate_memory_pressure 75
          ;;
        high)
          simulate_memory_pressure 90
          ;;
      esac
      ;;
    
    disk)
      case "$level" in
        slow)
          simulate_slow_disk 1024 1024
          ;;
        full)
          mock_disk_space_issues 50
          ;;
      esac
      ;;
    
    network)
      case "$level" in
        latency)
          simulate_network_latency "example.com" 300
          ;;
        loss)
          simulate_network_latency "example.com" 50 10 20
          ;;
        disconnected)
          simulate_network_latency "example.com" 2000 50 80
          ;;
      esac
      ;;
    
    thread)
      case "$level" in
        race)
          simulate_race_condition
          ;;
        deadlock)
          simulate_deadlock
          ;;
        isolation)
          simulate_test_isolation_issue
          ;;
      esac
      ;;
    
    io)
      case "$level" in
        throttled)
          simulate_io_throttling 512 512
          ;;
        interrupted)
          simulate_io_throttling 128 128
          ;;
      esac
      ;;
    
    repo)
      case "$level" in
        missing)
          simulate_repository_issues "missing"
          ;;
        corrupted)
          simulate_repository_issues "corrupted"
          ;;
        intermittent)
          simulate_repository_issues "intermittent"
          ;;
      esac
      ;;
    
    temp)
      case "$level" in
        space)
          simulate_temp_dir_issues "space"
          ;;
        permissions)
          simulate_temp_dir_issues "permissions"
          ;;
      esac
      ;;
  esac
}

# Clean up after a problem simulation
cleanup_problem() {
  local category="$1"
  local level="$2"
  
  # Skip if level is "none"
  if [[ "$level" == "none" ]]; then
    return 0
  fi
  
  echo "Cleaning up problem: $category=$level"
  
  # Handle each category and level
  case "$category" in
    cpu)
      # No cleanup needed for CPU simulation
      # Background processes are automatically terminated
      ;;
    
    memory)
      # No cleanup needed for memory simulation
      # Background processes are automatically terminated
      ;;
    
    disk)
      case "$level" in
        slow)
          # Clean up disk simulation
          ;;
        full)
          restore_disk_space_check
          ;;
      esac
      ;;
    
    network)
      # Clean up network simulation
      # Network simulation is done via function overrides that will be
      # automatically unset when the shell exits
      ;;
    
    thread)
      # No specific cleanup needed
      ;;
    
    io)
      # Clean up I/O simulation
      # I/O simulation is done via function overrides that will be
      # automatically unset when the shell exits
      ;;
    
    repo)
      # No specific cleanup needed
      # Repository simulation is done via temporary directories that will
      # be removed when the shell exits
      ;;
    
    temp)
      # No specific cleanup needed
      # Temporary directory issues are simulated with temporary files that
      # will be removed when the shell exits
      ;;
  esac
}

# ------------------------------------------------------------------------------
# PAIRWISE TESTING FUNCTIONS
# ------------------------------------------------------------------------------

# Generate all pairwise combinations of problem factors
generate_pairwise_matrix() {
  local output_file="${1:-pairwise_matrix.txt}"
  
  echo "Generating pairwise test matrix..."
  
  # Header row
  echo "TestID,CPU,Memory,Disk,Network,Thread,IO,Repository,Temporary" > "$output_file"
  
  # Basic test case: all parameters set to "none"
  echo "1,none,none,none,none,none,none,none,none" >> "$output_file"
  
  # Generate pairwise combinations for each pair of categories
  local test_id=2
  
  # Iterate through each pair of categories
  for cat1 in "${!PROBLEM_CATEGORIES[@]}"; do
    local values1=(${PROBLEM_CATEGORIES[$cat1]})
    
    for ((i=1; i<${#values1[@]}; i++)); do  # Skip "none" value (index 0)
      local val1="${values1[$i]}"
      
      for cat2 in "${!PROBLEM_CATEGORIES[@]}"; do
        # Skip same category
        if [[ "$cat1" == "$cat2" ]]; then
          continue
        fi
        
        local values2=(${PROBLEM_CATEGORIES[$cat2]})
        
        for ((j=1; j<${#values2[@]}; j++)); do  # Skip "none" value (index 0)
          local val2="${values2[$j]}"
          
          # Create a test case with this pair of parameters set
          local test_case="$test_id"
          
          for cat in "${!PROBLEM_CATEGORIES[@]}"; do
            if [[ "$cat" == "$cat1" ]]; then
              test_case="$test_case,$val1"
            elif [[ "$cat" == "$cat2" ]]; then
              test_case="$test_case,$val2"
            else
              test_case="$test_case,none"
            fi
          done
          
          echo "$test_case" >> "$output_file"
          test_id=$((test_id + 1))
        done
      done
    done
  done
  
  # Add some manually selected triples for more complex scenarios
  
  # High CPU, High Memory, and Slow Disk
  echo "$test_id,high,high,slow,none,none,none,none,none" >> "$output_file"
  test_id=$((test_id + 1))
  
  # Network Latency, High CPU, and IO Throttled
  echo "$test_id,high,none,none,latency,none,throttled,none,none" >> "$output_file"
  test_id=$((test_id + 1))
  
  # Thread Race, IO Interrupted, and Repository Intermittent
  echo "$test_id,none,none,none,none,race,interrupted,intermittent,none" >> "$output_file"
  test_id=$((test_id + 1))
  
  # Memory High, Network Loss, and Temporary Space
  echo "$test_id,none,high,none,loss,none,none,none,space" >> "$output_file"
  test_id=$((test_id + 1))
  
  echo "Generated $((test_id - 1)) test cases in $output_file"
  echo "$output_file"
}

# Run a specific test case from the matrix
run_test_case() {
  local test_id="$1"
  local matrix_file="${2:-pairwise_matrix.txt}"
  local test_command="${3:-mvn test}"
  
  # Find the test case in the matrix file
  local test_case=$(grep "^$test_id," "$matrix_file")
  
  if [[ -z "$test_case" ]]; then
    echo "Error: Test case $test_id not found in matrix file" >&2
    return 1
  fi
  
  echo "Running test case $test_id: $test_case"
  
  # Parse the test case parameters
  IFS=',' read -r id cpu memory disk network thread io repo temp <<< "$test_case"
  
  # Apply all problem constraints
  local cleanup_commands=()
  
  for category in cpu memory disk network thread io repo temp; do
    # Get the level for this category
    local level="${!category}"
    
    # Apply the problem
    apply_problem "$category" "$level"
    
    # Store cleanup command
    cleanup_commands+=("cleanup_problem $category $level")
  done
  
  # Run the test command
  echo "Executing: $test_command"
  eval "$test_command"
  local status=$?
  
  # Run cleanup commands in reverse order
  for ((i=${#cleanup_commands[@]}-1; i>=0; i--)); do
    eval "${cleanup_commands[$i]}"
  done
  
  return $status
}

# Run all test cases in the matrix
run_all_test_cases() {
  local matrix_file="${1:-pairwise_matrix.txt}"
  local test_command="${2:-mvn test}"
  local output_file="${3:-pairwise_results.csv}"
  
  # Create the matrix file if it doesn't exist
  if [[ ! -f "$matrix_file" ]]; then
    matrix_file=$(generate_pairwise_matrix "$matrix_file")
  fi
  
  # Create results file with header
  echo "TestID,CPU,Memory,Disk,Network,Thread,IO,Repository,Temporary,Status,Duration,Notes" > "$output_file"
  
  # Get number of test cases
  local test_count=$(grep -c "^[0-9]" "$matrix_file")
  
  echo "Running $test_count test cases..."
  
  # Run each test case
  while IFS= read -r line; do
    # Skip header line
    if [[ "$line" =~ ^TestID ]]; then
      continue
    fi
    
    # Extract test ID
    local test_id=$(echo "$line" | cut -d, -f1)
    
    # Measure execution time
    local start_time=$(date +%s.%N)
    run_test_case "$test_id" "$matrix_file" "$test_command" > /tmp/mvnimble_test_${test_id}.log 2>&1
    local status=$?
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc)
    
    # Extract notes from log
    local notes=$(grep -E 'ERROR|WARNING|FAILURE|Exception' /tmp/mvnimble_test_${test_id}.log | head -3 | tr '\n' ';' | sed 's/"/\\\"/g')
    
    # Append result to output file
    echo "$line,$status,$duration,\"$notes\"" >> "$output_file"
    
    echo "Test case $test_id completed with status $status in $duration seconds"
  done < "$matrix_file"
  
  echo "All test cases completed. Results saved to $output_file"
  echo "$output_file"
}

# Generate a summary report of the results
generate_pairwise_summary() {
  local results_file="${1:-pairwise_results.csv}"
  local output_file="${2:-pairwise_summary.md}"
  
  echo "Generating summary report from $results_file..."
  
  # Create summary report
  {
    echo "# MVNimble Pairwise Problem Simulation Results"
    echo
    echo "Generated: $(date +'%Y-%m-%d %H:%M:%S')"
    echo
    echo "## Summary Statistics"
    echo
    
    # Calculate summary statistics
    local total_tests=$(grep -c "^[0-9]" "$results_file")
    local passed_tests=$(grep -c ",0," "$results_file")
    local failed_tests=$((total_tests - passed_tests))
    
    echo "- **Total Test Cases:** $total_tests"
    echo "- **Passed:** $passed_tests"
    echo "- **Failed:** $failed_tests"
    echo "- **Pass Rate:** $((passed_tests * 100 / total_tests))%"
    echo
    
    echo "## Problem Category Impact"
    echo
    echo "| Category | Success Rate | Avg Duration | Most Common Failure |"
    echo "|----------|--------------|--------------|---------------------|"
    
    # Analyze each problem category
    for category in CPU Memory Disk Network Thread IO Repository Temporary; do
      # Get index for this category
      local index=0
      case $category in
        CPU) index=2 ;;
        Memory) index=3 ;;
        Disk) index=4 ;;
        Network) index=5 ;;
        Thread) index=6 ;;
        IO) index=7 ;;
        Repository) index=8 ;;
        Temporary) index=9 ;;
      esac
      
      # Calculate success rate for each level except "none"
      local levels=$(cut -d, -f$index "$results_file" | grep -v "none" | sort | uniq)
      local success_count=0
      local total_count=0
      local duration_sum=0
      local common_failure=""
      local failure_count=0
      
      for level in $levels; do
        # Count tests with this level
        local level_count=$(grep ",$level," "$results_file" | wc -l)
        # Count successful tests with this level
        local level_success=$(grep ",$level," "$results_file" | grep ",0," | wc -l)
        # Sum durations for this level
        local level_duration=$(grep ",$level," "$results_file" | cut -d, -f11 | paste -sd+ | bc)
        
        total_count=$((total_count + level_count))
        success_count=$((success_count + level_success))
        duration_sum=$(echo "$duration_sum + $level_duration" | bc)
        
        # Check if this level has more failures than current most common
        local level_failure=$((level_count - level_success))
        if [[ "$level_failure" -gt "$failure_count" ]]; then
          common_failure="$level"
          failure_count=$level_failure
        fi
      done
      
      # Calculate success rate
      local success_rate=0
      if [[ "$total_count" -gt 0 ]]; then
        success_rate=$((success_count * 100 / total_count))
      fi
      
      # Calculate average duration
      local avg_duration=0
      if [[ "$total_count" -gt 0 ]]; then
        avg_duration=$(echo "scale=2; $duration_sum / $total_count" | bc)
      fi
      
      echo "| $category | $success_rate% | ${avg_duration}s | $common_failure |"
    done
    
    echo
    echo "## Problematic Combinations"
    echo
    echo "The following combinations had the most severe impact on test execution:"
    echo
    
    # Find the worst performing test cases (longest duration or failures)
    echo "### Slowest Test Cases"
    echo
    echo "| Test ID | Configuration | Duration | Status |"
    echo "|---------|--------------|----------|--------|"
    
    # Sort by duration and get top 5
    grep "^[0-9]" "$results_file" | sort -t, -k11 -nr | head -5 | while IFS=, read -r id cpu memory disk network thread io repo temp status duration notes; do
      echo "| $id | CPU=$cpu, Memory=$memory, Disk=$disk, Network=$network, Thread=$thread, IO=$io, Repo=$repo, Temp=$temp | ${duration}s | $status |"
    done
    
    echo
    echo "### Most Common Failure Patterns"
    echo
    
    # Group failure patterns and count occurrences
    grep -v ",0," "$results_file" | cut -d, -f2-9 | sort | uniq -c | sort -nr | head -5 | while read -r count pattern; do
      echo "- **$count occurrences**: $pattern"
    done
    
    echo
    echo "## Recommendations"
    echo
    echo "Based on the pairwise testing results, here are recommendations to improve test robustness:"
    echo
    
    # Generate recommendations based on results
    
    # Check if CPU problems are significant
    if grep -q "CPU.*[0-6][0-9]%" <(echo "| CPU | $success_rate% | ${avg_duration}s | $common_failure |"); then
      echo "- **CPU Management**: Tests are sensitive to CPU constraints. Consider:"
      echo "  - Adding CPU resource guarantees in container environments"
      echo "  - Implementing adaptive thread counts based on available CPU"
      echo "  - Adding timeouts to prevent test hangs under CPU pressure"
      echo
    fi
    
    # Check if memory problems are significant
    if grep -q "Memory.*[0-6][0-9]%" <(echo "| Memory | $success_rate% | ${avg_duration}s | $common_failure |"); then
      echo "- **Memory Management**: Tests show sensitivity to memory constraints. Consider:"
      echo "  - Adding memory limits to JVM to prevent OOM issues"
      echo "  - Implementing memory usage monitoring during tests"
      echo "  - Breaking down large tests into smaller units"
      echo
    fi
    
    # Check if network problems are significant
    if grep -q "Network.*[0-6][0-9]%" <(echo "| Network | $success_rate% | ${avg_duration}s | $common_failure |"); then
      echo "- **Network Resilience**: Tests are affected by network issues. Consider:"
      echo "  - Implementing retry mechanisms for network operations"
      echo "  - Adding proper timeouts to network calls"
      echo "  - Creating fallback mechanisms for critical network dependencies"
      echo
    fi
    
    # Check if thread problems are significant
    if grep -q "Thread.*[0-6][0-9]%" <(echo "| Thread | $success_rate% | ${avg_duration}s | $common_failure |"); then
      echo "- **Thread Safety**: Tests exhibit thread safety issues. Consider:"
      echo "  - Reviewing shared state in test fixtures"
      echo "  - Adding synchronization to shared resources"
      echo "  - Implementing test isolation patterns"
      echo
    fi
    
    echo "## Detailed Test Results"
    echo
    echo "For the complete set of test results, see the CSV file: \`$results_file\`"
    echo
    echo "---"
    echo "Generated by MVNimble's Pairwise Problem Simulator"
  } > "$output_file"
  
  echo "Summary report generated: $output_file"
  echo "$output_file"
}

# ------------------------------------------------------------------------------
# REAL-WORLD SCENARIO SIMULATIONS
# ------------------------------------------------------------------------------

# Simulate a CI environment with limited resources
simulate_ci_environment() {
  local test_command="${1:-mvn test}"
  
  echo "Simulating CI environment with limited resources..."
  
  # Apply typical CI constraints:
  # 1. Limited CPU and memory
  # 2. Network latency
  # 3. Disk I/O contention
  
  # Apply constraints
  mock_limited_cpu_cores 2
  mock_limited_memory 4096 1024
  simulate_network_latency "repo1.maven.org" 100 10
  simulate_io_throttling 2048 1024
  
  # Run the test command
  echo "Executing in simulated CI environment: $test_command"
  eval "$test_command"
  local status=$?
  
  # Clean up constraints
  # (not strictly necessary as they'll be cleaned up when the shell exits)
  
  return $status
}

# Simulate an environment with a flaky network connection
simulate_flaky_network() {
  local test_command="${1:-mvn test}"
  
  echo "Simulating environment with flaky network connection..."
  
  # Apply flaky network constraints:
  # 1. Intermittent packet loss
  # 2. DNS resolution issues
  # 3. Repository connection issues
  
  # Apply constraints
  simulate_network_latency "repo1.maven.org" 50 30 15
  simulate_dns_issues "repo1.maven.org" "intermittent"
  simulate_connection_issues "repo1.maven.org" "reset" 30
  
  # Run the test command
  echo "Executing with flaky network: $test_command"
  eval "$test_command"
  local status=$?
  
  # Clean up constraints
  # (not strictly necessary as they'll be cleaned up when the shell exits)
  
  return $status
}

# Simulate an overloaded developer workstation
simulate_overloaded_workstation() {
  local test_command="${1:-mvn test}"
  
  echo "Simulating overloaded developer workstation..."
  
  # Apply typical overloaded workstation constraints:
  # 1. High CPU usage from other applications
  # 2. Limited memory available
  # 3. Slow disk I/O from other processes
  
  # Apply constraints
  simulate_high_cpu_load 80 9999 2  # Long-running CPU load on 2 cores
  simulate_memory_pressure 70 9999  # Long-running memory pressure
  simulate_io_throttling 4096 2048  # Moderate I/O throttling
  
  # Run the test command
  echo "Executing on simulated overloaded workstation: $test_command"
  eval "$test_command"
  local status=$?
  
  # Clean up constraints
  # (not strictly necessary as they'll be cleaned up when the shell exits)
  
  return $status
}

# Simulate an environment with thread safety issues
simulate_thread_unsafe_environment() {
  local test_command="${1:-mvn test}"
  
  echo "Simulating environment with thread safety issues..."
  
  # Apply thread safety constraints:
  # 1. Race conditions in shared resources
  # 2. Test isolation issues
  # 3. Deadlocks
  
  # Apply constraints
  simulate_race_condition
  simulate_test_isolation_issue
  simulate_deadlock
  
  # Run the test command
  echo "Executing in thread-unsafe environment: $test_command"
  eval "$test_command"
  local status=$?
  
  # Clean up constraints
  # (not strictly necessary as they'll be cleaned up when the shell exits)
  
  return $status
}

# ------------------------------------------------------------------------------
# MAIN FUNCTION - Run one of the simulations
# ------------------------------------------------------------------------------

# Generate diagnostic guidance based on test results
generate_diagnostic_guidance() {
  local results_file="$1"
  local output_file="${2:-diagnostic_guidance.md}"
  
  echo "Generating diagnostic guidance from results file: $results_file"
  
  # Source the diagnostic patterns library
  source "$(dirname "${BASH_SOURCE[0]}")/diagnostic_patterns.bash"
  
  # Generate the diagnostic plan
  generate_diagnostic_plan "$results_file" "$output_file"
}

# Main function to run simulations
main() {
  local action="$1"
  shift
  
  case "$action" in
    generate-matrix)
      generate_pairwise_matrix "$@"
      ;;
    
    run-test-case)
      run_test_case "$@"
      ;;
    
    run-all-cases)
      run_all_test_cases "$@"
      ;;
    
    generate-summary)
      generate_pairwise_summary "$@"
      ;;
    
    generate-guidance)
      generate_diagnostic_guidance "$@"
      ;;
    
    diagnose-pattern)
      # Source the diagnostic patterns library
      source "$(dirname "${BASH_SOURCE[0]}")/diagnostic_patterns.bash"
      show_diagnostic_guide "$@"
      ;;
    
    identify-patterns)
      # Source the diagnostic patterns library
      source "$(dirname "${BASH_SOURCE[0]}")/diagnostic_patterns.bash"
      identify_patterns_from_log "$@"
      ;;
    
    ci-environment)
      simulate_ci_environment "$@"
      ;;
    
    flaky-network)
      simulate_flaky_network "$@"
      ;;
    
    overloaded-workstation)
      simulate_overloaded_workstation "$@"
      ;;
    
    thread-unsafe)
      simulate_thread_unsafe_environment "$@"
      ;;
    
    help|--help|-h)
      echo "Usage: $(basename "$0") <action> [options]"
      echo
      echo "Actions:"
      echo "  generate-matrix [output_file]         Generate pairwise test matrix"
      echo "  run-test-case <id> [matrix] [cmd]     Run a specific test case"
      echo "  run-all-cases [matrix] [cmd] [output] Run all test cases in matrix"
      echo "  generate-summary [results] [output]   Generate summary report"
      echo "  generate-guidance [results] [output]  Generate diagnostic guidance with 1-2-3 approach"
      echo "  diagnose-pattern <pattern>            Show detailed guide for a specific pattern"
      echo "  identify-patterns <log_file>          Identify patterns from test log"
      echo "  ci-environment [cmd]                  Simulate CI environment"
      echo "  flaky-network [cmd]                   Simulate flaky network"
      echo "  overloaded-workstation [cmd]          Simulate overloaded workstation"
      echo "  thread-unsafe [cmd]                   Simulate thread-unsafe environment"
      echo "  help                                  Show this help message"
      echo
      echo "Examples:"
      echo "  $(basename "$0") generate-matrix pairwise.csv"
      echo "  $(basename "$0") run-test-case 1 pairwise.csv 'mvn test'"
      echo "  $(basename "$0") run-all-cases pairwise.csv 'mvn test' results.csv"
      echo "  $(basename "$0") generate-summary results.csv summary.md"
      echo "  $(basename "$0") generate-guidance results.csv guidance.md"
      echo "  $(basename "$0") diagnose-pattern cpu_bound"
      echo "  $(basename "$0") identify-patterns test-output.log"
      echo "  $(basename "$0") ci-environment 'mvn test'"
      ;;
    
    *)
      echo "Unknown action: $action" >&2
      echo "Run '$(basename "$0") help' for usage information" >&2
      return 1
      ;;
  esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi