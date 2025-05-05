#!/usr/bin/env bash
# flaky_test_detector.sh
# Module for detecting and analyzing flaky tests in Maven projects
#
# This module provides functionality to detect, analyze, and report on flaky tests
# by examining multiple test runs and identifying patterns that indicate flakiness.
#
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license

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

# Source thread visualizer if it exists
if [[ -f "${SCRIPT_DIR}/thread_visualizer.sh" ]]; then
  source "${SCRIPT_DIR}/thread_visualizer.sh"
fi

# Detect flaky tests by analyzing multiple test runs
# Parameters:
#   $1 - input directory containing test run data
#   $2 - output report file path
detect_flaky_tests() {
  local input_dir="$1"
  local output_report="$2"
  
  # Parameter validation
  if [[ -z "$input_dir" ]]; then
    print_error "Input directory is required"
    return 1
  fi
  
  if [[ ! -d "$input_dir" ]]; then
    print_error "Input directory doesn't exist: $input_dir"
    return 1
  fi
  
  if [[ -z "$output_report" ]]; then
    print_error "Output report path is required"
    return 1
  fi
  
  # Ensure output directory exists
  local output_dir="$(dirname "$output_report")"
  if ! ensure_directory "$output_dir" 2>/dev/null; then
    print_error "Cannot create output directory: $output_dir"
    return 1
  fi
  
  # Check if output directory is writable
  if [[ ! -w "$output_dir" ]]; then
    print_error "Permission denied: Cannot write to $output_dir"
    return 1
  fi
  
  print_info "Analyzing test runs in $input_dir"
  
  # Find all test run directories
  local run_dirs=()
  for dir in "$input_dir"/run*; do
    if [[ -d "$dir" ]]; then
      run_dirs+=("$dir")
    fi
  done
  
  # If no run directories found, check if logs are directly in input_dir
  if [[ ${#run_dirs[@]} -eq 0 ]]; then
    if [[ -f "$input_dir/test_output.log" || -f "$input_dir/timing_flaky_test.log" || -f "$input_dir/resource_contention_flaky_test.log" || -f "$input_dir/environment_flaky_test.log" || -f "$input_dir/thread_safety_flaky_test.log" ]]; then
      # Directly process files in input_dir
      run_dirs=("$input_dir")
    else
      # Look for any log files
      local count=0
      for file in "$input_dir"/*.log; do
        if [[ -f "$file" ]]; then
          count=$((count + 1))
        fi
      done
      
      if [[ $count -gt 0 ]]; then
        run_dirs=("$input_dir")
      else
        print_error "No test run data found in $input_dir"
        return 1
      fi
    fi
  fi
  
  print_info "Found ${#run_dirs[@]} test runs to analyze"
  
  # Initialize data structures to store flaky test information
  local total_runs=${#run_dirs[@]}
  local failed_runs=0
  local test_failures=()
  local test_failure_counts=()
  local test_classes=()
  local test_methods=()
  
  # Process each test run
  for run_dir in "${run_dirs[@]}"; do
    local log_file=""
    
    # Find the log file
    if [[ -f "$run_dir/test_output.log" ]]; then
      log_file="$run_dir/test_output.log"
    else
      # Look for any .log file
      for file in "$run_dir"/*.log; do
        if [[ -f "$file" ]]; then
          log_file="$file"
          break
        fi
      done
      
      # If still not found, try direct files in input_dir
      if [[ -z "$log_file" && -f "$run_dir" ]]; then
        log_file="$run_dir"
      fi
    fi
    
    if [[ -z "$log_file" || ! -f "$log_file" ]]; then
      print_warning "No log file found in $run_dir"
      continue
    fi
    
    # Check if log file is empty
    if [[ ! -s "$log_file" ]]; then
      print_warning "Empty log file in $run_dir"
      continue
    fi
    
    # Check if the build failed
    if grep -q "BUILD FAILURE" "$log_file"; then
      failed_runs=$((failed_runs + 1))
      
      # Extract test failures
      local failures=""
      
      # Try multiple patterns to extract test failures, handling different formats
      if grep -q "<<< FAILURE" "$log_file"; then
        failures=$(grep -A 5 "<<< FAILURE" "$log_file" | grep -E "\([a-zA-Z0-9.]+\.[a-zA-Z0-9]+\)" | sed -E 's/.*\(([^)]+)\).*/\1/' 2>/dev/null || echo "")
      fi
      
      if [[ -z "$failures" ]] && grep -q "Failures:" "$log_file"; then
        failures=$(grep -A 5 "Failures:" "$log_file" | grep -E "[a-zA-Z0-9.]+\.[a-zA-Z0-9]+" | sed -E 's/[^a-zA-Z0-9.]+([a-zA-Z0-9.]+\.[a-zA-Z0-9]+).*/\1/' 2>/dev/null || echo "")
      fi
      
      # Additional pattern for error section
      if [[ -z "$failures" ]] && grep -q "Errors:" "$log_file"; then
        failures=$(grep -A 5 "Errors:" "$log_file" | grep -E "[a-zA-Z0-9.]+\.[a-zA-Z0-9]+" | sed -E 's/[^a-zA-Z0-9.]+([a-zA-Z0-9.]+\.[a-zA-Z0-9]+).*/\1/' 2>/dev/null || echo "")
      fi
      
      # If still no failures found, try extracting from Results section
      if [[ -z "$failures" ]] && grep -q "Results:" "$log_file"; then
        failures=$(grep -A 20 "Results:" "$log_file" | grep -E "[a-zA-Z0-9.]+\.[a-zA-Z0-9]+" | sed -E 's/[^a-zA-Z0-9.]+([a-zA-Z0-9.]+\.[a-zA-Z0-9]+).*/\1/' 2>/dev/null || echo "")
      fi
      
      # If no failures could be parsed, warn but don't fail
      if [[ -z "$failures" ]]; then
        print_warning "Could not parse test failures from log file: $log_file"
        # Add a dummy failure to ensure the build is counted as failed
        failures="UnknownTest.unknownMethod"
      fi
      
      # Process each failure
      for failure in $failures; do
        local class_name=$(echo "$failure" | sed 's/\.[^.]*$//')
        local method_name=$(echo "$failure" | sed 's/.*\.//')
        local full_name="$class_name.$method_name"
        
        # Check if we've seen this failure before
        local found=false
        local index=0
        for i in "${!test_failures[@]}"; do
          if [[ "${test_failures[$i]}" == "$full_name" ]]; then
            test_failure_counts[$i]=$((test_failure_counts[$i] + 1))
            found=true
            break
          fi
        done
        
        # If not found, add it
        if [[ "$found" == "false" ]]; then
          test_failures+=("$full_name")
          test_failure_counts+=(1)
          test_classes+=("$class_name")
          test_methods+=("$method_name")
        fi
      done
    fi
  done
  
  # Calculate flaky test statistics
  local flaky_test_count=${#test_failures[@]}
  local flakiness_rate=0
  if [[ $total_runs -gt 0 ]]; then
    flakiness_rate=$(( (failed_runs * 100) / total_runs ))
  fi
  
  # Generate the report
  {
    echo "# Flaky Test Analysis Report"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "## Flakiness Summary"
    echo ""
    echo "* **Total Test Runs**: $total_runs"
    echo "* **Failed Runs**: $failed_runs"
    echo "* **Flaky Tests Identified**: $flaky_test_count"
    echo "* **Flakiness Rate**: ${flakiness_rate}%"
    echo ""
    
    echo "## Flaky Tests"
    echo ""
    
    # Categorize flaky tests
    local timing_issues=()
    local resource_contention=()
    local environment_dependencies=()
    local thread_safety=()
    local other_issues=()
    
    for i in "${!test_failures[@]}"; do
      local test_name="${test_failures[$i]}"
      local failure_count="${test_failure_counts[$i]}"
      local fail_rate=$(( (failure_count * 100) / total_runs ))
      
      # Categorize based on patterns
      local category=""
      if grep -q "Timeout\|timing\|wait\|sleep\|delay\|async" <<< "$test_name"; then
        timing_issues+=("$test_name ($fail_rate% failure rate)")
        category="Timing-Related Issue"
      elif grep -q "Connection\|Resource\|Pool\|Capacity\|memory\|timeout" <<< "$test_name"; then
        resource_contention+=("$test_name ($fail_rate% failure rate)")
        category="Resource Contention"
      elif grep -q "Config\|Environment\|Profile\|Mode\|Setting\|Property" <<< "$test_name"; then
        environment_dependencies+=("$test_name ($fail_rate% failure rate)")
        category="Environment Dependency"
      elif grep -q "Concurrent\|Thread\|Synchronize\|Lock\|Atomic\|Race" <<< "$test_name"; then
        thread_safety+=("$test_name ($fail_rate% failure rate)")
        category="Thread Safety Issue"
      else
        other_issues+=("$test_name ($fail_rate% failure rate)")
        category="Unclassified Issue"
      fi
    done
    
    # Output categorized tests
    if [[ ${#timing_issues[@]} -gt 0 ]]; then
      echo "### Timing-Related Issues"
      echo ""
      for test in "${timing_issues[@]}"; do
        echo "* $test"
      done
      echo ""
    fi
    
    if [[ ${#resource_contention[@]} -gt 0 ]]; then
      echo "### Resource Contention"
      echo ""
      for test in "${resource_contention[@]}"; do
        echo "* $test"
      done
      echo ""
    fi
    
    if [[ ${#environment_dependencies[@]} -gt 0 ]]; then
      echo "### Environment Dependencies"
      echo ""
      for test in "${environment_dependencies[@]}"; do
        echo "* $test"
      done
      echo ""
    fi
    
    if [[ ${#thread_safety[@]} -gt 0 ]]; then
      echo "### Thread Safety Issues"
      echo ""
      for test in "${thread_safety[@]}"; do
        echo "* $test"
      done
      echo ""
    fi
    
    if [[ ${#other_issues[@]} -gt 0 ]]; then
      echo "### Other Issues"
      echo ""
      for test in "${other_issues[@]}"; do
        echo "* $test"
      done
      echo ""
    fi
    
    echo "## Recommendations"
    echo ""
    
    # Add recommendations based on findings
    if [[ ${#timing_issues[@]} -gt 0 ]]; then
      echo "### For Timing-Related Issues"
      echo ""
      echo "1. **Avoid fixed wait times**: Replace `Thread.sleep()` with proper synchronization"
      echo "2. **Use wait conditions**: Implement explicit waiting with polling or conditions"
      echo "3. **Increase timeouts**: Consider increasing timeouts for asynchronous operations"
      echo "4. **Consider retry mechanisms**: Add retry logic for operations that may occasionally time out"
      echo ""
    fi
    
    if [[ ${#resource_contention[@]} -gt 0 ]]; then
      echo "### For Resource Contention"
      echo ""
      echo "1. **Increase resource limits**: Configure larger connection pools or memory limits"
      echo "2. **Improve resource cleanup**: Ensure resources are properly closed after use"
      echo "3. **Implement better pooling**: Use connection pooling with appropriate sizing"
      echo "4. **Isolate tests**: Run resource-intensive tests in isolation"
      echo ""
    fi
    
    if [[ ${#environment_dependencies[@]} -gt 0 ]]; then
      echo "### For Environment Dependencies"
      echo ""
      echo "1. **Standardize environments**: Ensure consistent configuration across all environments"
      echo "2. **Explicitly set properties**: Don't rely on default or environment-specific settings"
      echo "3. **Mock external dependencies**: Use mocks instead of real external systems"
      echo "4. **Document requirements**: Clearly document required environment configurations"
      echo ""
    fi
    
    if [[ ${#thread_safety[@]} -gt 0 ]]; then
      echo "### For Thread Safety Issues"
      echo ""
      echo "1. **Use thread-safe collections**: Replace standard collections with concurrent versions"
      echo "2. **Add synchronization**: Add proper synchronization to shared resources"
      echo "3. **Avoid shared state**: Redesign tests to minimize shared state"
      echo "4. **Use atomics**: Replace primitive counters with atomic variables"
      echo ""
    fi
    
    echo "## Next Steps"
    echo ""
    echo "1. Run a more detailed analysis on the identified flaky tests"
    echo "2. Implement fixes for the most frequently failing tests first"
    echo "3. Add monitoring to verify fixes are effective"
    echo "4. Set up continuous flaky test detection in your CI pipeline"
    echo ""
    
    echo "---"
    echo "Generated by MVNimble Flaky Test Detector v${MVNIMBLE_VERSION:-0.1.0}"
  } > "$output_report"
  
  print_success "Flaky test analysis complete. Report saved to: $output_report"
  return 0
}

# Analyze flaky test patterns to determine root causes
# Parameters:
#   $1 - input file (thread dump or system metrics)
#   $2 - output report file path
analyze_flaky_test_patterns() {
  local input_file="$1"
  local output_report="$2"
  
  # Parameter validation
  if [[ -z "$input_file" ]]; then
    print_error "Input file is required"
    return 1
  fi
  
  if [[ ! -f "$input_file" ]]; then
    print_error "Input file doesn't exist: $input_file"
    return 1
  fi
  
  # Check if file is empty
  if [[ ! -s "$input_file" ]]; then
    print_error "Input file is empty: $input_file"
    return 1
  fi
  
  if [[ -z "$output_report" ]]; then
    print_error "Output report path is required"
    return 1
  fi
  
  # Ensure output directory exists
  local output_dir="$(dirname "$output_report")"
  if ! ensure_directory "$output_dir" 2>/dev/null; then
    print_error "Cannot create output directory: $output_dir"
    return 1
  fi
  
  # Check if output directory is writable
  if [[ ! -w "$output_dir" ]]; then
    print_error "Permission denied: Cannot write to $output_dir"
    return 1
  fi
  
  print_info "Analyzing patterns in $input_file"
  
  # Validate JSON format
  if command -v jq &> /dev/null; then
    if ! jq empty "$input_file" 2>/dev/null; then
      print_error "Invalid JSON format in input file: $input_file"
      return 1
    fi
  else
    # Fallback validation if jq is not available
    if ! grep -q "^{" "$input_file" || ! grep -q "}$" "$input_file"; then
      print_warning "Cannot validate JSON format without jq. File may be invalid."
    fi
  fi
  
  # Determine the type of input file
  local file_type=""
  if grep -q "\"threads\"" "$input_file"; then
    file_type="thread_dump"
  elif grep -q "\"runs\"" "$input_file" || grep -q "\"metrics\"" "$input_file"; then
    file_type="system_metrics"
  else
    print_error "Unrecognized input file format: $input_file"
    return 1
  fi
  
  # Generate the appropriate report
  if [[ "$file_type" == "thread_dump" ]]; then
    # Process thread dump
    {
      echo "# Thread Interaction Analysis"
      echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
      echo ""
      echo "## Thread Overview"
      echo ""
      
      # Extract thread information
      local thread_count=$(grep -o "\"id\":" "$input_file" | wc -l)
      echo "Total Threads: $thread_count"
      echo ""
      
      echo "## Thread States"
      echo ""
      echo "| Thread ID | Name | State | Locks Held | Locks Waiting |"
      echo "|-----------|------|-------|------------|---------------|"
      
      # Extract and format thread data
      while read -r line; do
        if [[ "$line" =~ \"id\":\ ([0-9]+),\"name\":\ \"([^\"]+)\",\"state\":\ \"([^\"]+)\" ]]; then
          local thread_id="${BASH_REMATCH[1]}"
          local thread_name="${BASH_REMATCH[2]}"
          local thread_state="${BASH_REMATCH[3]}"
          
          # Find locks held and waiting
          local locks_held=$(grep -A 10 "\"id\": $thread_id" "$input_file" | grep -A 3 "\"locks_held\"" | grep -o "\"[^\"]*\"" | tr -d '"' | tr '\n' ',' | sed 's/,$//')
          local locks_waiting=$(grep -A 10 "\"id\": $thread_id" "$input_file" | grep -A 3 "\"locks_waiting\"" | grep -o "\"[^\"]*\"" | tr -d '"' | tr '\n' ',' | sed 's/,$//')
          
          echo "| $thread_id | $thread_name | $thread_state | $locks_held | $locks_waiting |"
        fi
      done < <(grep -A 2 "\"id\":" "$input_file")
      
      echo ""
      echo "## Potential Deadlocks"
      echo ""
      
      # Simple deadlock detection by looking for threads waiting on locks held by other threads
      local has_deadlocks=false
      while read -r lock_line; do
        if [[ "$lock_line" =~ \"identity\":\ \"([^\"]+)\",\"owner_thread\":\ ([0-9]+),\"waiting_threads\":\ \[([0-9,\ ]+)\] ]]; then
          local lock_id="${BASH_REMATCH[1]}"
          local owner="${BASH_REMATCH[2]}"
          local waiters="${BASH_REMATCH[3]}"
          
          if [[ -n "$waiters" && "$waiters" != " " ]]; then
            has_deadlocks=true
            echo "Lock $lock_id:"
            echo "- Held by: Thread $owner"
            echo "- Waited on by: Thread(s) $waiters"
            echo ""
          fi
        fi
      done < <(grep -A 2 "\"identity\":" "$input_file")
      
      if [[ "$has_deadlocks" == "false" ]]; then
        echo "No potential deadlocks detected."
        echo ""
      fi
      
      echo "## Stack Trace Analysis"
      echo ""
      echo "Common patterns in stack traces:"
      echo ""
      
      # Look for common patterns in stack traces
      local has_timing_issues=$(grep -c "sleep\|wait\|timeout\|join" "$input_file")
      local has_sync_issues=$(grep -c "synchronized\|lock\|monitor\|ReentrantLock\|Semaphore" "$input_file")
      local has_collection_issues=$(grep -c "HashMap\|ArrayList\|HashSet\|ConcurrentModificationException" "$input_file")
      
      if [[ $has_timing_issues -gt 0 ]]; then
        echo "- **Timing-Related Issues**: Found $has_timing_issues references to timing operations (sleep, wait, timeout)"
        echo ""
      fi
      
      if [[ $has_sync_issues -gt 0 ]]; then
        echo "- **Synchronization Issues**: Found $has_sync_issues references to locks or synchronization"
        echo ""
      fi
      
      if [[ $has_collection_issues -gt 0 ]]; then
        echo "- **Collection Issues**: Found $has_collection_issues references to collections (potential concurrent modification)"
        echo ""
      fi
      
      echo "## Recommendations"
      echo ""
      echo "Based on thread analysis:"
      echo ""
      
      if [[ $has_timing_issues -gt 0 ]]; then
        echo "1. **Review timing operations**: Check for hard-coded sleep/wait times"
        echo "2. **Implement proper waiting**: Use CountDownLatch or CompletableFuture instead of sleep"
        echo ""
      fi
      
      if [[ $has_sync_issues -gt 0 ]]; then
        echo "1. **Review lock ordering**: Ensure consistent lock acquisition order"
        echo "2. **Minimize lock scope**: Reduce the time locks are held"
        echo ""
      fi
      
      if [[ $has_collection_issues -gt 0 ]]; then
        echo "1. **Use thread-safe collections**: Replace HashMap with ConcurrentHashMap"
        echo "2. **Implement proper synchronization**: Synchronize access to collections"
        echo ""
      fi
      
      echo "---"
      echo "Generated by MVNimble Thread Analyzer v${MVNIMBLE_VERSION:-0.1.0}"
    } > "$output_report"
  elif [[ "$file_type" == "system_metrics" ]]; then
    # Process system metrics
    {
      echo "# Environment Correlation Analysis"
      echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
      echo ""
      echo "## Overview"
      echo ""
      
      # Extract run information
      local run_count=$(grep -o "\"id\":" "$input_file" | wc -l)
      local fail_count=$(grep -o "\"success\": false" "$input_file" | wc -l)
      
      echo "Total Runs: $run_count"
      echo "Failed Runs: $fail_count"
      echo "Success Rate: $(( ((run_count - fail_count) * 100) / run_count ))%"
      echo ""
      
      echo "## Environment Variables Correlation"
      echo ""
      echo "| Variable | Value in Failed Runs | Value in Successful Runs | Correlation Score |"
      echo "|----------|----------------------|--------------------------|------------------|"
      
      # Extract and analyze environment variables
      local env_vars=()
      while read -r var_line; do
        if [[ "$var_line" =~ \"name\":\ \"([^\"]+)\" ]]; then
          env_vars+=("${BASH_REMATCH[1]}")
        fi
      done < <(grep "\"name\":" "$input_file")
      
      for var in "${env_vars[@]}"; do
        # Get values in failed runs
        local failed_values=""
        local success_values=""
        
        # This is a simplification - in a real implementation, we would need more complex JSON parsing
        # For demonstration purposes, we'll use basic text extraction
        failed_values=$(grep -A 10 "\"success\": false" "$input_file" | grep -A 2 "\"name\": \"$var\"" | grep -o "\"run-[^\"]*\": \"[^\"]*\"" | cut -d':' -f2 | tr -d '"' | tr '\n' ',' | sed 's/,$//')
        
        success_values=$(grep -A 10 "\"success\": true" "$input_file" | grep -A 2 "\"name\": \"$var\"" | grep -o "\"run-[^\"]*\": \"[^\"]*\"" | cut -d':' -f2 | tr -d '"' | tr '\n' ',' | sed 's/,$//')
        
        # Calculate simple correlation score (placeholder)
        local correlation=0
        if [[ "$failed_values" != "$success_values" ]]; then
          correlation=80
        elif [[ "$failed_values" == *","* && "$failed_values" != "$success_values" ]]; then
          correlation=50
        else
          correlation=10
        fi
        
        echo "| $var | $failed_values | $success_values | $correlation% |"
      done
      
      echo ""
      echo "## Resource Usage Correlation"
      echo ""
      echo "| Metric | Average in Failed Runs | Average in Successful Runs | Difference |"
      echo "|--------|------------------------|----------------------------|------------|"
      
      # Extract resource metrics
      # Again, simplified for demonstration
      local cpu_failed=$(grep -A 5 "\"success\": false" "$input_file" | grep -A 3 "\"metrics\"" | grep "\"cpu_usage\"" | grep -o "[0-9.]\+" | head -1)
      local mem_failed=$(grep -A 5 "\"success\": false" "$input_file" | grep -A 3 "\"metrics\"" | grep "\"memory_usage\"" | grep -o "[0-9.]\+" | head -1)
      
      local cpu_success=$(grep -A 5 "\"success\": true" "$input_file" | grep -A 3 "\"metrics\"" | grep "\"cpu_usage\"" | grep -o "[0-9.]\+" | head -1)
      local mem_success=$(grep -A 5 "\"success\": true" "$input_file" | grep -A 3 "\"metrics\"" | grep "\"memory_usage\"" | grep -o "[0-9.]\+" | head -1)
      
      # Calculate differences
      local cpu_diff=0
      local mem_diff=0
      
      if [[ -n "$cpu_failed" && -n "$cpu_success" ]]; then
        cpu_diff=$(echo "$cpu_failed - $cpu_success" | bc)
      fi
      
      if [[ -n "$mem_failed" && -n "$mem_success" ]]; then
        mem_diff=$(echo "$mem_failed - $mem_success" | bc)
      fi
      
      echo "| CPU Usage | ${cpu_failed:-N/A}% | ${cpu_success:-N/A}% | ${cpu_diff:-N/A}% |"
      echo "| Memory Usage | ${mem_failed:-N/A}MB | ${mem_success:-N/A}MB | ${mem_diff:-N/A}MB |"
      
      echo ""
      echo "## Recommendations"
      echo ""
      echo "Based on environment analysis:"
      echo ""
      
      # Make recommendations based on findings
      if [[ $(grep -c "TEST_ENV" "$input_file") -gt 0 ]]; then
        echo "1. **Standardize Test Environment**: Ensure tests run in a consistent environment"
        echo ""
      fi
      
      if [[ $(grep -c "MEMORY_LIMIT" "$input_file") -gt 0 ]]; then
        echo "1. **Increase Memory Limits**: Tests may require more memory to run reliably"
        echo ""
      fi
      
      if [[ $(grep -c "ASYNC_TIMEOUT" "$input_file") -gt 0 ]]; then
        echo "1. **Adjust Timeouts**: Increase timeouts for asynchronous operations"
        echo ""
      fi
      
      if [[ $(grep -c "MAX_CONNECTIONS" "$input_file") -gt 0 ]]; then
        echo "1. **Increase Connection Limits**: Tests may be hitting connection pool limits"
        echo ""
      fi
      
      echo "---"
      echo "Generated by MVNimble Environment Analyzer v${MVNIMBLE_VERSION:-0.1.0}"
    } > "$output_report"
  fi
  
  print_success "Pattern analysis complete. Report saved to: $output_report"
  return 0
}

# Generate a flaky test report with recommendations
# Parameters:
#   $1 - input directory containing test run data
#   $2 - output report file path
generate_flaky_test_report() {
  local input_dir="$1"
  local output_report="$2"
  
  # Parameter validation
  if [[ -z "$input_dir" ]]; then
    print_error "Input directory is required"
    return 1
  fi
  
  if [[ ! -d "$input_dir" ]]; then
    print_error "Input directory doesn't exist: $input_dir"
    return 1
  fi
  
  if [[ -z "$output_report" ]]; then
    print_error "Output report path is required"
    return 1
  fi
  
  # Ensure output directory exists
  local output_dir="$(dirname "$output_report")"
  if ! ensure_directory "$output_dir" 2>/dev/null; then
    print_error "Cannot create output directory: $output_dir"
    return 1
  fi
  
  # Check if output directory is writable
  if [[ ! -w "$output_dir" ]]; then
    print_error "Permission denied: Cannot write to $output_dir"
    return 1
  fi
  
  # Create a detailed flaky test report
  print_info "Generating comprehensive flaky test report"
  
  # First, run detect_flaky_tests to get basic analysis
  local temp_report="${output_dir}/temp_flaky_analysis.md"
  if ! detect_flaky_tests "$input_dir" "$temp_report"; then
    print_error "Failed to analyze flaky tests in $input_dir"
    return 1
  fi
  
  # Verify temp report was created
  if [[ ! -f "$temp_report" ]]; then
    print_error "Expected analysis file not generated: $temp_report"
    return 1
  fi
  
  # Check for additional data for more detailed analysis
  local thread_dump=""
  local system_metrics=""
  
  # Look for thread dump and system metrics files
  for file in "$input_dir"/*.json "$input_dir"/run*/*.json; do
    if [[ -f "$file" ]]; then
      if grep -q "\"threads\"" "$file"; then
        thread_dump="$file"
      elif grep -q "\"runs\"" "$file" || grep -q "\"metrics\"" "$file"; then
        system_metrics="$file"
      fi
    fi
  done
  
  # Generate additional analysis reports if possible
  local thread_analysis=""
  local env_analysis=""
  
  if [[ -n "$thread_dump" ]]; then
    if [[ ! -f "$thread_dump" ]]; then
      print_warning "Thread dump file not found or not readable: $thread_dump"
    else
      thread_analysis="${output_dir}/thread_analysis.md"
      if ! analyze_flaky_test_patterns "$thread_dump" "$thread_analysis"; then
        print_warning "Thread analysis failed, continuing with basic report only"
        thread_analysis=""
      elif [[ ! -f "$thread_analysis" ]]; then
        print_warning "Thread analysis file not generated: $thread_analysis"
        thread_analysis=""
      fi
    fi
  fi
  
  if [[ -n "$system_metrics" ]]; then
    if [[ ! -f "$system_metrics" ]]; then
      print_warning "System metrics file not found or not readable: $system_metrics"
    else
      env_analysis="${output_dir}/env_analysis.md"
      if ! analyze_flaky_test_patterns "$system_metrics" "$env_analysis"; then
        print_warning "Environment analysis failed, continuing with basic report only"
        env_analysis=""
      elif [[ ! -f "$env_analysis" ]]; then
        print_warning "Environment analysis file not generated: $env_analysis"
        env_analysis=""
      fi
    fi
  fi
  
  # Combine reports into a comprehensive analysis
  {
    # Include basic flaky test analysis
    cat "$temp_report"
    
    echo ""
    echo "# Detailed Analysis"
    echo ""
    
    # Include thread analysis if available
    if [[ -n "$thread_analysis" && -f "$thread_analysis" ]]; then
      echo "## Thread Interaction Analysis"
      echo ""
      # Extract the relevant sections
      sed -n '/^## Thread/,/Generated by/p' "$thread_analysis" | sed '/Generated by/d'
      echo ""
    fi
    
    # Include environment analysis if available
    if [[ -n "$env_analysis" && -f "$env_analysis" ]]; then
      echo "## Environment Correlation Analysis"
      echo ""
      # Extract the relevant sections
      sed -n '/^## Environment/,/Generated by/p' "$env_analysis" | sed '/Generated by/d'
      echo ""
    fi
    
    # Add visualizations
    echo "## Visualizations"
    echo ""
    
    # Generate thread visualizations if thread dump exists and thread visualizer is available
    if [[ -n "$thread_dump" && -f "$thread_dump" ]]; then
      local thread_viz_available=false
      if type -t generate_thread_visualization &>/dev/null; then
        thread_viz_available=true
      fi
      
      if [[ "$thread_viz_available" == "true" ]]; then
        print_info "Generating thread visualizations from thread dump"
        
        # Generate thread interaction diagram
        local thread_diagram="${output_dir}/thread_diagram.md"
        if ! generate_thread_diagram "$thread_dump" "$thread_diagram" 2>/dev/null; then
          print_warning "Failed to generate thread diagram, continuing without it"
          thread_diagram=""
        fi
        
        # Generate thread timeline
        local thread_timeline="${output_dir}/thread_timeline.md"
        if ! generate_thread_timeline "$thread_dump" "$thread_timeline" 2>/dev/null; then
          print_warning "Failed to generate thread timeline, continuing without it"
          thread_timeline=""
        fi
        
        # Generate lock contention graph
        local lock_contention="${output_dir}/lock_contention.md"
        if ! generate_lock_contention_graph "$thread_dump" "$lock_contention" 2>/dev/null; then
          print_warning "Failed to generate lock contention graph, continuing without it"
          lock_contention=""
        fi
        
        # Generate HTML visualization
        local html_viz="${output_dir}/thread_visualization.html"
        if ! generate_thread_visualization "$thread_dump" "$html_viz" 2>/dev/null; then
          print_warning "Failed to generate HTML visualization, continuing without it"
          html_viz=""
        fi
        
        # Check for deadlocks
        local has_deadlocks=false
        if detect_deadlocks "$thread_dump" &>/dev/null; then
          has_deadlocks=true
        fi
        
        # Include visualizations and links in the report
        echo "### Thread Interaction Analysis"
        echo ""
        
        if [[ "$has_deadlocks" == "true" ]]; then
          echo "**⚠️ DEADLOCK DETECTED in thread dump!** This indicates a serious thread safety issue."
          echo ""
        fi
        
        if [[ -n "$thread_diagram" && -f "$thread_diagram" && -s "$thread_diagram" ]]; then
          echo "**Thread Interaction Diagram:**"
          echo ""
          cat "$thread_diagram"
          echo ""
        else
          echo "**Thread Interaction Diagram:** Not available"
          echo ""
        fi
        
        if [[ -n "$thread_timeline" && -f "$thread_timeline" && -s "$thread_timeline" ]]; then
          echo "**Thread Timeline:**"
          echo ""
          cat "$thread_timeline"
          echo ""
        else
          echo "**Thread Timeline:** Not available"
          echo ""
        fi
        
        if [[ -n "$lock_contention" && -f "$lock_contention" && -s "$lock_contention" ]]; then
          echo "**Lock Contention Graph:**"
          echo ""
          cat "$lock_contention"
          echo ""
        else
          echo "**Lock Contention Graph:** Not available"
          echo ""
        fi
        
        if [[ -n "$html_viz" && -f "$html_viz" ]]; then
          echo "For a detailed interactive visualization, open [thread_visualization.html](thread_visualization.html)"
        else
          echo "Detailed interactive visualization not available"
        fi
        echo ""
      else
        # Fallback to placeholders if thread visualizer not available
        echo "Thread interaction visualization:"
        echo ""
        echo "```visualization:thread-interaction"
        echo "source: ${thread_dump}"
        echo "```"
        echo ""
        echo "To enable interactive thread visualizations, ensure thread_visualizer.sh is in the modules directory."
        echo ""
      fi
    else
      echo "No thread dump available for visualization. To enable thread visualization:"
      echo ""
      echo "1. Generate a thread dump during test execution using jcmd or jstack"
      echo "2. Save the thread dump as JSON in the test run directory"
      echo ""
    fi
    
    # Environment correlation visualization (placeholder for now)
    if [[ -n "$system_metrics" && -f "$system_metrics" ]]; then
      echo "### Environment Correlation Analysis"
      echo ""
      echo "```visualization:environment-correlation"
      echo "source: ${system_metrics}"
      echo "```"
      echo ""
    else
      echo "No system metrics available for environment correlation analysis."
      echo ""
    fi
    
    echo "---"
    echo "Generated by MVNimble Flaky Test Analyzer v${MVNIMBLE_VERSION:-0.1.0}"
  } > "$output_report"
  
  # Clean up temporary files
  if [[ -f "$temp_report" ]]; then
    if ! rm -f "$temp_report" 2>/dev/null; then
      print_warning "Failed to clean up temporary file: $temp_report"
    fi
  fi
  
  # Verify final report was created
  if [[ ! -f "$output_report" ]]; then
    print_error "Failed to generate final report: $output_report"
    return 1
  fi
  
  # Check if report is empty
  if [[ ! -s "$output_report" ]]; then
    print_warning "Generated report is empty: $output_report"
  fi
  
  print_success "Comprehensive flaky test report generated: $output_report"
  return 0
}

# Compare multiple test runs to identify flakiness
# Parameters:
#   $1 - first test run log file
#   $2 - second test run log file
#   $3 - output comparison report file
compare_test_runs() {
  local first_run="$1"
  local second_run="$2"
  local output_report="$3"
  
  # Parameter validation
  if [[ -z "$first_run" ]]; then
    print_error "First run log file is required"
    return 1
  fi
  
  if [[ ! -f "$first_run" ]]; then
    print_error "First run log file doesn't exist: $first_run"
    return 1
  fi
  
  if [[ -z "$second_run" ]]; then
    print_error "Second run log file is required"
    return 1
  fi
  
  if [[ ! -f "$second_run" ]]; then
    print_error "Second run log file doesn't exist: $second_run"
    return 1
  fi
  
  if [[ -z "$output_report" ]]; then
    print_error "Output report file is required"
    return 1
  fi
  
  # Ensure output directory exists
  local output_dir="$(dirname "$output_report")"
  if ! ensure_directory "$output_dir" 2>/dev/null; then
    print_error "Cannot create output directory: $output_dir"
    return 1
  fi
  
  # Check if output directory is writable
  if [[ ! -w "$output_dir" ]]; then
    print_error "Permission denied: Cannot write to $output_dir"
    return 1
  fi
  
  print_info "Comparing test runs: $first_run and $second_run"
  
  # Extract test results from first run
  local first_run_tests=()
  local first_run_results=()
  
  while read -r line; do
    if [[ "$line" =~ Running\ ([a-zA-Z0-9._]+) ]]; then
      local test_class="${BASH_REMATCH[1]}"
      
      # Read the next line for results
      read -r result_line
      
      if [[ "$result_line" =~ Tests\ run:\ ([0-9]+),\ Failures:\ ([0-9]+),\ Errors:\ ([0-9]+) ]]; then
        local tests="${BASH_REMATCH[1]}"
        local failures="${BASH_REMATCH[2]}"
        local errors="${BASH_REMATCH[3]}"
        
        first_run_tests+=("$test_class")
        
        if [[ "$failures" -eq 0 && "$errors" -eq 0 ]]; then
          first_run_results+=("PASS")
        else
          first_run_results+=("FAIL")
        fi
      fi
    fi
  done < "$first_run"
  
  # Extract test results from second run
  local second_run_tests=()
  local second_run_results=()
  
  while read -r line; do
    if [[ "$line" =~ Running\ ([a-zA-Z0-9._]+) ]]; then
      local test_class="${BASH_REMATCH[1]}"
      
      # Read the next line for results
      read -r result_line
      
      if [[ "$result_line" =~ Tests\ run:\ ([0-9]+),\ Failures:\ ([0-9]+),\ Errors:\ ([0-9]+) ]]; then
        local tests="${BASH_REMATCH[1]}"
        local failures="${BASH_REMATCH[2]}"
        local errors="${BASH_REMATCH[3]}"
        
        second_run_tests+=("$test_class")
        
        if [[ "$failures" -eq 0 && "$errors" -eq 0 ]]; then
          second_run_results+=("PASS")
        else
          second_run_results+=("FAIL")
        fi
      fi
    fi
  done < "$second_run"
  
  # Extract build status
  local first_run_status="FAILURE"
  if grep -q "BUILD SUCCESS" "$first_run"; then
    first_run_status="SUCCESS"
  fi
  
  local second_run_status="FAILURE"
  if grep -q "BUILD SUCCESS" "$second_run"; then
    second_run_status="SUCCESS"
  fi
  
  # Generate comparison report
  {
    echo "# Test Run Comparison"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    echo "## Run Summary"
    echo ""
    echo "| Run | Status | Tests Run | Tests Passed | Tests Failed |"
    echo "|-----|--------|-----------|--------------|--------------|"
    
    # First run summary
    local first_run_passed=0
    local first_run_failed=0
    
    for i in "${!first_run_results[@]}"; do
      if [[ "${first_run_results[$i]}" == "PASS" ]]; then
        first_run_passed=$((first_run_passed + 1))
      else
        first_run_failed=$((first_run_failed + 1))
      fi
    done
    
    local first_run_total=$((first_run_passed + first_run_failed))
    
    # Second run summary
    local second_run_passed=0
    local second_run_failed=0
    
    for i in "${!second_run_results[@]}"; do
      if [[ "${second_run_results[$i]}" == "PASS" ]]; then
        second_run_passed=$((second_run_passed + 1))
      else
        second_run_failed=$((second_run_failed + 1))
      fi
    done
    
    local second_run_total=$((second_run_passed + second_run_failed))
    
    echo "| Run 1 | $first_run_status | $first_run_total | $first_run_passed | $first_run_failed |"
    echo "| Run 2 | $second_run_status | $second_run_total | $second_run_passed | $second_run_failed |"
    echo ""
    
    echo "## Test Differences"
    echo ""
    
    # Find tests with different results
    local has_differences=false
    
    echo "| Test | Run 1 Result | Run 2 Result |"
    echo "|------|--------------|--------------|"
    
    for i in "${!first_run_tests[@]}"; do
      local test="${first_run_tests[$i]}"
      local result1="${first_run_results[$i]}"
      
      # Find in second run
      local result2=""
      for j in "${!second_run_tests[@]}"; do
        if [[ "${second_run_tests[$j]}" == "$test" ]]; then
          result2="${second_run_results[$j]}"
          break
        fi
      done
      
      # If not found in second run, mark as N/A
      if [[ -z "$result2" ]]; then
        result2="N/A"
      fi
      
      # If results differ, add to report
      if [[ "$result1" != "$result2" ]]; then
        has_differences=true
        echo "| $test | $result1 | $result2 |"
      fi
    done
    
    # Check for tests in second run that weren't in first run
    for i in "${!second_run_tests[@]}"; do
      local test="${second_run_tests[$i]}"
      local result2="${second_run_results[$i]}"
      
      # Check if in first run
      local found=false
      for j in "${!first_run_tests[@]}"; do
        if [[ "${first_run_tests[$j]}" == "$test" ]]; then
          found=true
          break
        fi
      done
      
      # If not found in first run, add to report
      if [[ "$found" == "false" ]]; then
        has_differences=true
        echo "| $test | N/A | $result2 |"
      fi
    done
    
    if [[ "$has_differences" == "false" ]]; then
      echo "No differences found between test runs."
    fi
    
    echo ""
    echo "## Conclusion"
    echo ""
    
    if [[ "$has_differences" == "true" ]]; then
      echo "The test runs show different results, indicating potential flakiness."
      echo ""
      echo "Recommended steps:"
      echo ""
      echo "1. **Examine the tests that show differences**"
      echo "2. **Look for timing dependencies, resource contention, or concurrency issues**"
      echo "3. **Run the tests multiple times to establish a pattern**"
      echo "4. **Review the test code for potential flakiness root causes**"
    else
      echo "No differences found between the test runs. This suggests either:"
      echo ""
      echo "1. The tests are stable (not flaky), or"
      echo "2. Both runs experienced the same issues (coincidental consistency)"
      echo ""
      echo "Recommend running the tests several more times to confirm stability."
    fi
    
    echo ""
    echo "---"
    echo "Generated by MVNimble Test Comparison Tool v${MVNIMBLE_VERSION:-0.1.0}"
  } > "$output_report"
  
  # Verify report was created
  if [[ ! -f "$output_report" ]]; then
    print_error "Failed to create comparison report: $output_report"
    return 1
  fi
  
  # Check if report is empty
  if [[ ! -s "$output_report" ]]; then
    print_warning "Generated comparison report is empty: $output_report"
  fi
  
  print_success "Test run comparison complete. Report saved to: $output_report"
  return 0
}

# Categorize flaky tests by failure pattern
# Parameters:
#   $1 - input directory containing test logs
#   $2 - output categorization file (JSON)
categorize_flaky_tests() {
  local input_dir="$1"
  local output_file="$2"
  
  # Parameter validation
  if [[ -z "$input_dir" ]]; then
    print_error "Input directory is required"
    return 1
  fi
  
  if [[ ! -d "$input_dir" ]]; then
    print_error "Input directory doesn't exist: $input_dir"
    return 1
  fi
  
  if [[ -z "$output_file" ]]; then
    print_error "Output file is required"
    return 1
  fi
  
  # Ensure output directory exists
  local output_dir="$(dirname "$output_file")"
  if ! ensure_directory "$output_dir" 2>/dev/null; then
    print_error "Cannot create output directory: $output_dir"
    return 1
  fi
  
  # Check if output directory is writable
  if [[ ! -w "$output_dir" ]]; then
    print_error "Permission denied: Cannot write to $output_dir"
    return 1
  fi
  
  print_info "Categorizing flaky tests in $input_dir"
  
  # Find all log files
  local log_files=()
  for file in "$input_dir"/*.log; do
    if [[ -f "$file" ]]; then
      log_files+=("$file")
    fi
  done
  
  if [[ ${#log_files[@]} -eq 0 ]]; then
    print_error "No log files found in $input_dir"
    return 1
  fi
  
  print_info "Found ${#log_files[@]} log files to analyze"
  
  # Initialize data structure for results
  local tests=()
  local categories=()
  local error_messages=()
  local failure_counts=()
  
  # Process each log file
  for log_file in "${log_files[@]}"; do
    # Extract test failures
    while read -r line; do
      if [[ "$line" =~ ([a-zA-Z0-9._]+)\.([a-zA-Z0-9_]+)\(([a-zA-Z0-9._]+)\) ]]; then
        local test_class="${BASH_REMATCH[3]}"
        local test_method="${BASH_REMATCH[2]}"
        local full_name="$test_class.$test_method"
        
        # Get the error message (from next few lines)
        local error_msg=""
        local line_count=0
        while read -r error_line && [[ $line_count -lt 5 ]]; do
          error_msg="$error_msg $error_line"
          line_count=$((line_count + 1))
        done
        
        # Check if we've seen this test before
        local found=false
        local index=0
        for i in "${!tests[@]}"; do
          if [[ "${tests[$i]}" == "$full_name" ]]; then
            failure_counts[$i]=$((failure_counts[$i] + 1))
            found=true
            index=$i
            break
          fi
        done
        
        # If not found, add it
        if [[ "$found" == "false" ]]; then
          tests+=("$full_name")
          failure_counts+=(1)
          error_messages+=("$error_msg")
          
          # Categorize based on error message
          local category=""
          if [[ "$error_msg" =~ timeout|Timeout|wait|sleep|async|Interrupted ]]; then
            category="TIMING"
          elif [[ "$error_msg" =~ memory|connection|pool|resource|capacity ]]; then
            category="RESOURCE_CONTENTION"
          elif [[ "$error_msg" =~ config|environment|profile|mode|property ]]; then
            category="ENVIRONMENT_DEPENDENCY"
          elif [[ "$error_msg" =~ concurrent|thread|synchronize|lock|atomic|race|ConcurrentModification ]]; then
            category="THREAD_SAFETY"
          else
            category="UNCLASSIFIED"
          fi
          
          categories+=("$category")
        fi
      fi
    done < <(grep -A 5 "<<< FAILURE" "$log_file")
  done
  
  # Generate JSON output
  {
    echo "{"
    echo "  \"analysis_timestamp\": \"$(date '+%Y-%m-%dT%H:%M:%S')\","
    echo "  \"flaky_tests\": ["
    
    for i in "${!tests[@]}"; do
      local comma=","
      if [[ $i -eq $((${#tests[@]} - 1)) ]]; then
        comma=""
      fi
      
      echo "    {"
      echo "      \"test_name\": \"${tests[$i]}\","
      echo "      \"category\": \"${categories[$i]}\","
      echo "      \"failure_count\": ${failure_counts[$i]},"
      echo "      \"error_snippet\": \"${error_messages[$i]}\""
      echo "    }$comma"
    done
    
    echo "  ],"
    echo "  \"summary\": {"
    echo "    \"total_tests\": ${#tests[@]},"
    
    # Count by category
    local timing_count=0
    local resource_count=0
    local env_count=0
    local thread_count=0
    local other_count=0
    
    for category in "${categories[@]}"; do
      case "$category" in
        "TIMING") timing_count=$((timing_count + 1)) ;;
        "RESOURCE_CONTENTION") resource_count=$((resource_count + 1)) ;;
        "ENVIRONMENT_DEPENDENCY") env_count=$((env_count + 1)) ;;
        "THREAD_SAFETY") thread_count=$((thread_count + 1)) ;;
        *) other_count=$((other_count + 1)) ;;
      esac
    done
    
    echo "    \"by_category\": {"
    echo "      \"TIMING\": $timing_count,"
    echo "      \"RESOURCE_CONTENTION\": $resource_count,"
    echo "      \"ENVIRONMENT_DEPENDENCY\": $env_count,"
    echo "      \"THREAD_SAFETY\": $thread_count,"
    echo "      \"UNCLASSIFIED\": $other_count"
    echo "    }"
    echo "  }"
    echo "}"
  } > "$output_file"
  
  # Verify the JSON file was created
  if [[ ! -f "$output_file" ]]; then
    print_error "Failed to create JSON output file: $output_file"
    return 1
  fi
  
  # Validate JSON format if jq is available
  if command -v jq &> /dev/null; then
    if ! jq empty "$output_file" 2>/dev/null; then
      print_error "Generated JSON file is not valid: $output_file"
      return 1
    fi
  else
    # Basic validation if jq isn't available
    if ! grep -q "^{" "$output_file" || ! grep -q "}$" "$output_file"; then
      print_warning "Cannot fully validate JSON format without jq. File may be invalid."
    fi
  fi
  
  # Check if any flaky tests were found
  if [[ ${#tests[@]} -eq 0 ]]; then
    print_warning "No flaky tests identified in the logs"
  fi
  
  print_success "Flaky tests categorized. Results saved to: $output_file"
  return 0
}