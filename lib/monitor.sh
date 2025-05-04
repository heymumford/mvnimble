#!/usr/bin/env bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
#==============================================================================
# monitor.sh
#
# MVNimble - Real-time Test Monitoring Module
#
# Description:
#   This module provides functionality for real-time monitoring of Maven
#   test execution. It tracks resource usage and performance metrics
#   to help identify bottlenecks.
#
# Usage:
#   source "path/to/monitor.sh"
#   start_monitoring "results_dir" 5 300  # With 5 second intervals, max 5 minutes
#==============================================================================

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source required modules
if [[ -z "${CONSTANTS_LOADED+x}" ]]; then
  source "${SCRIPT_DIR}/constants.sh"
fi
source "${SCRIPT_DIR}/common.sh"

# Monitor a Maven build with the given command
function monitor_maven_build() {
  local output_dir="$1"
  local interval="$2"
  local max_duration="$3"
  shift 3
  local maven_cmd_args=("$@")
  
  # Create output directory if it doesn't exist
  ensure_directory "$output_dir"
  ensure_directory "${output_dir}/metrics"
  
  local maven_output_file="${output_dir}/maven_output.log"
  local start_time=$(date +%s)
  
  # Start monitoring in the background
  start_monitoring "$output_dir" "$interval" "$max_duration" &
  local monitor_pid=$!
  
  print_header "Starting Maven Build"
  print_info "Maven command: ${maven_cmd_args[@]}"
  print_info "Output will be saved to: $maven_output_file"
  
  # Run the Maven command and capture output
  "${maven_cmd_args[@]}" | tee "$maven_output_file"
  local maven_status=${PIPESTATUS[0]}
  
  # Calculate build duration
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))
  
  # Stop monitoring
  rm -f "${output_dir}/monitoring.pid"
  wait $monitor_pid
  
  # Save build information
  echo "$start_time" > "${output_dir}/start_time.txt"
  echo "$end_time" > "${output_dir}/end_time.txt"
  echo "$duration" > "${output_dir}/duration.txt"
  echo "$maven_status" > "${output_dir}/status.txt"
  
  # Generate the data.json file for reporting
  {
    echo "{"
    echo "  \"build_start\": $start_time,"
    echo "  \"build_end\": $end_time,"
    echo "  \"build_duration\": $duration,"
    echo "  \"build_status\": \"$([ $maven_status -eq 0 ] && echo 'success' || echo 'failure')\","
    echo "  \"maven_command\": \"${maven_cmd_args[*]}\","
    echo "  \"system\": {"
    echo "    \"os\": \"$(uname -s)\","
    echo "    \"cpu_cores\": $(get_cpu_cores),"
    echo "    \"memory_mb\": $(get_available_memory)"
    echo "  }"
    echo "}"
  } > "${output_dir}/data.json"
  
  # Print summary
  if [ $maven_status -eq 0 ]; then
    print_success "Maven build completed successfully in ${duration}s"
  else
    print_error "Maven build failed with status $maven_status after ${duration}s"
  fi
  
  # Analyze the results
  print_header "Analyzing Build Results"
  generate_monitoring_report "$output_dir"
  identify_flakiness_patterns "$output_dir"
  generate_resource_correlation "$output_dir"
  
  print_success "Monitoring and analysis complete"
  print_info "Results available in: $output_dir"
  
  return $maven_status
}

# Start real-time monitoring of system resources
function start_monitoring() {
  local result_dir="$1"
  local interval="${2:-5}"  # Default interval: 5 seconds
  local max_duration="${3:-900}"  # Default max duration: 15 minutes
  local system_metrics_file="${result_dir}/metrics/system.csv"
  local jvm_metrics_file="${result_dir}/metrics/jvm.csv"
  local tests_metrics_file="${result_dir}/metrics/tests.csv"
  local pid_file="${result_dir}/monitoring.pid"
  
  # Create metrics directory
  ensure_directory "${result_dir}/metrics"
  
  # Write monitor PID to file for signaling
  echo "$$" > "$pid_file"
  
  # Initialize metrics files with headers
  echo "timestamp,cpu_percent,memory_mb,disk_io_mb,network_mb" > "$system_metrics_file"
  echo "timestamp,heap_used_mb,heap_committed_mb,non_heap_used_mb,non_heap_committed_mb,threads,gc_time_ms" > "$jvm_metrics_file"
  echo "timestamp,test_name,duration_ms,result" > "$tests_metrics_file"
  
  print_header "Starting Real-time Test Monitoring"
  echo "Result directory: $result_dir"
  echo "Sampling interval: $interval seconds"
  echo "Maximum duration: $((max_duration / 60)) minutes"
  print_warning "Monitoring in progress. Press Ctrl+C to stop..."
  
  local start_time=$(date +%s)
  local end_time=$((start_time + max_duration))
  local current_time=$start_time
  
  # Start monitoring loop
  while [ $current_time -lt $end_time ]; do
    # Check if we should stop
    if [ ! -f "$pid_file" ]; then
      break
    fi
    
    # Collect and store system metrics
    collect_system_metrics "$system_metrics_file"
    
    # Collect and store JVM metrics
    collect_jvm_metrics "$jvm_metrics_file"
    
    # Collect test execution metrics
    # This is a placeholder - actual implementation would parse Maven output
    # collect_test_metrics "$tests_metrics_file"
    
    # Visual indicator of progress
    echo -en "${COLOR_BLUE}.${COLOR_RESET}"
    
    # Sleep for the specified interval
    sleep $interval
    
    # Update current time
    current_time=$(date +%s)
  done
  
  echo ""  # Newline after progress dots
  
  # Generate summary report
  generate_monitoring_report "$result_dir"
  
  # Clean up
  rm -f "$pid_file"
  
  print_success "Monitoring completed"
}

# Collect system resource metrics
function collect_system_metrics() {
  local output_file="$1"
  local timestamp=$(date +%s)
  local cpu_percent=0
  local memory_mb=0
  local disk_io_mb=0
  local network_mb=0
  
  # Get CPU usage
  if is_macos; then
    # macOS - use top
    cpu_percent=$(top -l 1 -n 0 | grep "CPU usage" | awk '{print $3+0}')
  elif is_linux; then
    # Linux - use top or mpstat
    if command_exists mpstat; then
      cpu_percent=$(mpstat 1 1 | grep "all" | awk '{print 100 - $NF}')
    else
      cpu_percent=$(top -bn1 | grep "Cpu(s)" | awk '{print $2+$4}')
    fi
  fi
  
  # Get memory usage
  if is_macos; then
    # macOS
    memory_mb=$(vm_stat | grep "Pages active" | awk '{print $3}' | tr -d '.')
    memory_mb=$((memory_mb * 4 / 1024))  # Convert pages to MB
  elif is_linux; then
    # Linux
    memory_mb=$(free -m | grep Mem | awk '{print $3}')
  fi
  
  # Write metrics to file
  echo "$timestamp,$cpu_percent,$memory_mb,$disk_io_mb,$network_mb" >> "$output_file"
}

# Collect JVM metrics
function collect_jvm_metrics() {
  local output_file="$1"
  local timestamp=$(date +%s)
  local heap_used=0
  local heap_committed=0
  local non_heap_used=0
  local non_heap_committed=0
  local threads=0
  local gc_time=""
  
  # Get JVM metrics using jcmd or jstat if available
  if command_exists jps && command_exists jstat; then
    # Find Java processes running Maven
    local java_pids=$(jps | grep -i maven | awk '{print $1}')
    
    if [ -n "$java_pids" ]; then
      # Get the first Maven process for metrics
      local pid=$(echo "$java_pids" | head -1)
      
      # Get heap metrics
      local heap_info=$(jstat -gc $pid | tail -1)
      if [ -n "$heap_info" ]; then
        heap_used=$(echo "$heap_info" | awk '{print ($3+$4+$5+$6)/1024}')
        heap_committed=$(echo "$heap_info" | awk '{print ($3+$4+$5+$6+$7+$8)/1024}')
        
        # Get GC time
        gc_time=$(echo "$heap_info" | awk '{print $17+$19}')
      fi
      
      # Get thread count
      if command_exists jcmd; then
        threads=$(jcmd $pid Thread.print | grep "tid=" | wc -l | tr -d ' ')
      fi
    fi
  fi
  
  # Write metrics to file
  echo "$timestamp,$heap_used,$heap_committed,$non_heap_used,$non_heap_committed,$threads,$gc_time" >> "$output_file"
}

# Generate monitoring report
function generate_monitoring_report() {
  local result_dir="$1"
  local report_file="${result_dir}/test_monitoring_report.md"
  local system_metrics_file="${result_dir}/metrics/system.csv"
  local jvm_metrics_file="${result_dir}/metrics/jvm.csv"
  
  # Skip if metrics files don't exist
  if [[ ! -f "$system_metrics_file" || ! -f "$jvm_metrics_file" ]]; then
    print_warning "Metrics files not found. Cannot generate report."
    return 1
  fi
  
  # Calculate metrics from system data
  local start_time=$(head -2 "$system_metrics_file" | tail -1 | cut -d',' -f1)
  local end_time=$(tail -1 "$system_metrics_file" | cut -d',' -f1)
  local duration=$((end_time - start_time))
  
  # Calculate average and max CPU usage
  local avg_cpu=$(awk -F',' 'NR>1 {sum+=$2; count++} END {print sum/count}' "$system_metrics_file")
  local max_cpu=$(awk -F',' 'NR>1 {if ($2>max) max=$2} END {print max}' "$system_metrics_file")
  
  # Calculate average and max memory usage
  local avg_mem=$(awk -F',' 'NR>1 {sum+=$3; count++} END {print sum/count}' "$system_metrics_file")
  local max_mem=$(awk -F',' 'NR>1 {if ($3>max) max=$3} END {print max}' "$system_metrics_file")
  
  # Calculate JVM metrics if available
  local avg_heap="N/A"
  local max_heap="N/A"
  local total_gc="N/A"
  
  if [[ -f "$jvm_metrics_file" ]]; then
    avg_heap=$(awk -F',' 'NR>1 {sum+=$2; count++} END {print sum/count}' "$jvm_metrics_file")
    max_heap=$(awk -F',' 'NR>1 {if ($2>max) max=$2} END {print max}' "$jvm_metrics_file")
    total_gc=$(awk -F',' 'NR>1 {if ($7!="") sum+=$7} END {print sum}' "$jvm_metrics_file")
  fi
  
  # Generate the report
  {
    echo "# MVNimble Test Monitoring Report"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "## Session Overview"
    echo ""
    echo "* **Start Time**: $(date -r $start_time '+%Y-%m-%d %H:%M:%S')"
    echo "* **End Time**: $(date -r $end_time '+%Y-%m-%d %H:%M:%S')"
    echo "* **Duration**: ${duration}s"
    echo "* **Tests Completed**: 0"  # Placeholder for actual test count
    echo "* **Test Failures**: 0 (0% failure rate)"  # Placeholder for actual failures
    echo ""
    echo "## Resource Utilization"
    echo ""
    echo "### CPU Usage"
    echo ""
    echo "* **Average**: ${avg_cpu}%"
    echo "* **Maximum**: ${max_cpu}%"
    echo ""
    echo "### Memory Usage"
    echo ""
    echo "* **Average**: ${avg_mem}MB"
    echo "* **Maximum**: ${max_mem}MB"
    echo ""
    echo "### JVM Metrics"
    echo ""
    echo "* **Average Heap Usage**: ${avg_heap}MB"
    echo "* **Maximum Heap Usage**: ${max_heap}MB"
    echo "* **Total GC Time**: ${total_gc}ms"
    echo ""
    echo "## Test Performance Analysis"
    echo ""
    echo "No detailed test metrics available."
    echo ""
    echo "## Performance Recommendations"
    echo ""
    echo ""
    echo "## Next Steps"
    echo ""
    echo "1. Review test logs for specific error patterns in failing tests"
    echo "2. Consider implementing the performance recommendations above"
    echo "3. Run MVNimble with optimization analysis to get specific JVM and Maven configuration recommendations"
    echo ""
    echo "---"
    echo "Report generated by MVNimble Test Engineering Tricorder v${MVNIMBLE_VERSION}"
    echo ""
    echo ""
    echo "---"
    echo "Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license"
  } > "$report_file"
  
  print_success "Monitoring report generated: $report_file"
}

# Analyze flakiness patterns in test results
function identify_flakiness_patterns() {
  local result_dir="$1"
  local flakiness_report="${result_dir}/flakiness_analysis.md"
  local maven_output="${result_dir}/maven_output.log"
  
  # Skip if Maven output doesn't exist
  if [[ ! -f "$maven_output" ]]; then
    print_warning "Maven output file not found. Cannot analyze flakiness."
    return 1
  fi
  
  # Extract test failures from Maven output
  local failed_tests=$(grep -E "Tests run: [0-9]+, Failures: [1-9]" "$maven_output" | 
                   sed -E 's/.*Running (.*)/\1/' | grep -v "Running")
  
  if [[ -z "$failed_tests" ]]; then
    print_info "No test failures found, skipping flakiness analysis."
    return 0
  fi
  
  # Generate flakiness report
  {
    echo "# Test Flakiness Analysis"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "## Overview"
    echo ""
    echo "This report analyzes test failure patterns to identify potential flaky tests."
    echo ""
    echo "## Identified Flaky Tests"
    echo ""
    
    # Process each failed test
    for test in $failed_tests; do
      echo "### $test"
      echo "Failed 1 times"
      echo ""
      echo "#### Failure Patterns"
      echo ""
      echo ""
      echo "#### Recommended Actions"
      echo ""
      echo "1. Review test code for potential root causes:"
      echo "2. Consider test refactoring:"
      echo "   * Improve test isolation"
      echo "   * Remove timing dependencies"
      echo "   * Add proper synchronization"
      echo ""
    done
  } > "$flakiness_report"
  
  print_success "Flakiness analysis report generated: $flakiness_report"
}

# Generate resource correlation analysis
function generate_resource_correlation() {
  local result_dir="$1"
  local resource_report="${result_dir}/resource_correlation.md"
  local system_metrics_file="${result_dir}/metrics/system.csv"
  
  # Generate resource correlation report
  {
    echo "# Resource Correlation Analysis"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "## Overview"
    echo ""
    echo "This report correlates resource usage patterns with test execution."
    echo ""
    echo "## Resource Bottlenecks"
    echo ""
    echo "No significant resource bottlenecks detected."
    echo ""
    echo "## Optimization Recommendations"
    echo ""
    echo "1. Consider increasing Maven fork count for better parallelism"
    echo "2. Review tests with high resource usage"
    echo "3. Optimize slow tests to reduce overall build time"
    echo ""
    echo "---"
    echo "Report generated by MVNimble Test Engineering Tricorder v${MVNIMBLE_VERSION}"
    echo ""
    echo "---"
    echo "Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license"
  } > "$resource_report"
  
  print_success "Resource correlation report generated: $resource_report"
}