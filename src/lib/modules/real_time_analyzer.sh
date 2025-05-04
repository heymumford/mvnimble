#!/usr/bin/env bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# real_time_analyzer.sh
# MVNimble - Real-time test analysis and monitoring module
#
# This module provides real-time monitoring and analysis of Maven tests,
# generating insights into performance bottlenecks and resource utilization.

# Define the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Import modules (if present)
[ -f "${SCRIPT_DIR}/constants.sh" ] && source "${SCRIPT_DIR}/constants.sh"
[ -f "${SCRIPT_DIR}/platform_compatibility.sh" ] && source "${SCRIPT_DIR}/platform_compatibility.sh"
[ -f "${SCRIPT_DIR}/environment_unified.sh" ] && source "${SCRIPT_DIR}/environment_unified.sh"
[ -f "${SCRIPT_DIR}/test_analysis.sh" ] && source "${SCRIPT_DIR}/test_analysis.sh"

# Define color constants if not already defined
if [ -z "${COLOR_GREEN+x}" ]; then
  COLOR_GREEN='\033[0;32m'
  COLOR_YELLOW='\033[0;33m'
  COLOR_RED='\033[0;31m'
  COLOR_BLUE='\033[0;34m'
  COLOR_CYAN='\033[0;36m'
  COLOR_BOLD='\033[1m'
  COLOR_RESET='\033[0m'
fi

# ============================================================
# Helper Functions
# ============================================================

# Format duration in seconds to a human-readable format
format_duration() {
  local seconds=$1
  local days=$((seconds / 86400))
  local hours=$(( (seconds % 86400) / 3600 ))
  local minutes=$(( (seconds % 3600) / 60 ))
  local remaining_seconds=$((seconds % 60))
  
  if [ $days -gt 0 ]; then
    echo "${days}d ${hours}h ${minutes}m ${remaining_seconds}s"
  elif [ $hours -gt 0 ]; then
    echo "${hours}h ${minutes}m ${remaining_seconds}s"
  elif [ $minutes -gt 0 ]; then
    echo "${minutes}m ${remaining_seconds}s"
  else
    echo "${remaining_seconds}s"
  fi
}

# Use get_total_memory_mb from platform_compatibility.sh

# ============================================================
# Core Functions
# ============================================================

# Start real-time monitoring of a test session
start_real_time_monitoring() {
  local result_dir="$1"
  local interval="${2:-5}" # Default sampling interval in seconds
  local max_duration="${3:-3600}" # Default max monitoring duration (1 hour)
  
  echo -e "\n${COLOR_BOLD}${COLOR_BLUE}=== Starting Real-time Test Monitoring ===${COLOR_RESET}"
  echo -e "Result directory: ${result_dir}"
  echo -e "Sampling interval: ${interval} seconds"
  echo -e "Maximum duration: $((max_duration / 60)) minutes"
  
  # Create required directories
  mkdir -p "${result_dir}/metrics"
  
  # Create metrics files with headers
  echo "timestamp,cpu_percent,memory_mb,disk_io_mb,network_mb" > "${result_dir}/metrics/system.csv"
  echo "timestamp,heap_used_mb,heap_committed_mb,non_heap_used_mb,non_heap_committed_mb,threads,gc_time_ms" > "${result_dir}/metrics/jvm.csv"
  echo "timestamp,test_name,duration,result,thread_id" > "${result_dir}/metrics/tests.csv"
  
  # Record start time
  local start_time=$(date +%s)
  local check_interval=1 # Check for termination every second
  local cycle_count=0
  local monitoring_pid=""
  
  # Start monitoring in background
  (
    # Capture JVM metrics if jcmd or jstat is available
    local has_jvm_tools=false
    if command -v jcmd >/dev/null 2>&1 || command -v jstat >/dev/null 2>&1; then
      has_jvm_tools=true
    fi
    
    # Main monitoring loop
    while true; do
      local current_time=$(date +%s)
      local elapsed=$((current_time - start_time))
      
      # Check if we've reached the maximum duration
      if [ $elapsed -ge $max_duration ]; then
        break
      fi
      
      # Only collect metrics on interval boundaries
      if [ $((elapsed % interval)) -eq 0 ]; then
        # System metrics
        local cpu_percent=0
        local memory_mb=0
        local disk_io_mb=0
        local network_mb=0
        
        # Get CPU usage
        if [[ "$(uname)" == "Darwin" ]]; then
          # macOS
          cpu_percent=$(top -l 1 -n 0 | grep "CPU usage" | awk '{print $3}' | tr -d '%')
        else
          # Linux
          cpu_percent=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
        fi
        
        # Get memory usage
        if [[ "$(uname)" == "Darwin" ]]; then
          # macOS
          memory_mb=$(vm_stat | grep "Pages active" | awk '{print $3}' | tr -d '.' | awk '{print int($1 * 4096 / 1024 / 1024)}')
        else
          # Linux
          memory_mb=$(free -m | grep Mem | awk '{print $3}')
        fi
        
        # Get disk I/O (if available)
        if [[ "$(uname)" == "Darwin" ]]; then
          # macOS - simplified placeholder
          disk_io_mb=0
        elif [ -f /proc/diskstats ]; then
          # Linux with /proc/diskstats
          disk_io_mb=$(grep -w "sda" /proc/diskstats 2>/dev/null | awk '{print ($6 + $10) * 512 / 1024 / 1024}' || echo "0")
        else
          disk_io_mb=0
        fi
        
        # Get network I/O (if available)
        if [[ "$(uname)" == "Darwin" ]]; then
          # macOS - simplified placeholder
          network_mb=0
        elif [ -d /sys/class/net ]; then
          # Linux with sysfs
          network_mb=$(find /sys/class/net -type l -not -path "*virtual*" -exec cat {}/statistics/rx_bytes \; 2>/dev/null | awk '{sum += $1} END {print sum / 1024 / 1024}' || echo "0")
        else
          network_mb=0
        fi
        
        # Record system metrics
        echo "${current_time},${cpu_percent},${memory_mb},${disk_io_mb},${network_mb}" >> "${result_dir}/metrics/system.csv"
        
        # JVM metrics if tools are available
        if [ "$has_jvm_tools" = true ]; then
          local heap_used=0
          local heap_committed=0
          local non_heap_used=0
          local non_heap_committed=0
          local threads=0
          local gc_time=0
          
          # Find Java processes
          local java_pids=$(pgrep java 2>/dev/null || echo "")
          
          if [ -n "$java_pids" ]; then
            local main_pid=$(echo "$java_pids" | head -1)
            
            if command -v jcmd >/dev/null 2>&1; then
              # Use jcmd if available
              local jvm_data=$(jcmd $main_pid GC.heap_info 2>/dev/null || echo "")
              if [ -n "$jvm_data" ]; then
                heap_used=$(echo "$jvm_data" | grep "used" | head -1 | awk '{print $3 / 1024 / 1024}')
                heap_committed=$(echo "$jvm_data" | grep "committed" | head -1 | awk '{print $3 / 1024 / 1024}')
                
                # Get thread count
                threads=$(jcmd $main_pid Thread.print 2>/dev/null | grep "tid=" | wc -l)
                
                # Get GC time (approximate)
                gc_time=$(jcmd $main_pid GC.time_info 2>/dev/null | grep "Total time" | awk '{print $4}' || echo "0")
              fi
            elif command -v jstat >/dev/null 2>&1; then
              # Fallback to jstat
              local jstat_data=$(jstat -gc $main_pid 2>/dev/null || echo "")
              if [ -n "$jstat_data" ]; then
                heap_used=$(echo "$jstat_data" | tail -1 | awk '{print ($3 + $4 + $6 + $8) / 1024}')
                heap_committed=$(echo "$jstat_data" | tail -1 | awk '{print ($5 + $7 + $9) / 1024}')
                
                # Get thread count (approximate)
                threads=$(ps -p $main_pid -L | wc -l)
                
                # Get GC time (approximate from stat data)
                gc_time=$(echo "$jstat_data" | tail -1 | awk '{print ($16 + $18) * 1000}')
              fi
            fi
            
            # Record JVM metrics
            echo "${current_time},${heap_used},${heap_committed},${non_heap_used},${non_heap_committed},${threads},${gc_time}" >> "${result_dir}/metrics/jvm.csv"
          fi
        fi
        
        # Extract test information from Maven output if available
        local maven_log="${result_dir}/maven_output.log"
        if [ -f "$maven_log" ]; then
          # Look for newly completed tests
          local test_updates=$(grep -n "Running .*" "$maven_log" 2>/dev/null || true)
          local test_results=$(grep -n "Tests run:" "$maven_log" 2>/dev/null || true)
          
          if [ -n "$test_updates" ] && [ -n "$test_results" ]; then
            local last_processed_line=$(cat "${result_dir}/.last_processed_line" 2>/dev/null || echo "0")
            
            # Process new test results
            while IFS= read -r result_line; do
              local line_num=$(echo "$result_line" | cut -d: -f1)
              
              # Only process new lines
              if [ "$line_num" -gt "$last_processed_line" ]; then
                local test_output=$(echo "$result_line" | sed 's/^[0-9]*://')
                local test_status="SUCCESS"
                
                # Extract test information
                if echo "$test_output" | grep -q "Failures: [1-9]"; then
                  test_status="FAILURE"
                elif echo "$test_output" | grep -q "Errors: [1-9]"; then
                  test_status="ERROR"
                fi
                
                # Find the corresponding test name
                local test_name=""
                local prev_running_line=$(echo "$test_updates" | awk -v line="$line_num" '$1 < line' | tail -1)
                if [ -n "$prev_running_line" ]; then
                  test_name=$(echo "$prev_running_line" | sed 's/^[0-9]*:Running //')
                  test_name=$(echo "$test_name" | tr -d '\r\n')
                fi
                
                # Extract test duration
                local test_duration=0
                if echo "$test_output" | grep -q "Time elapsed:"; then
                  test_duration=$(echo "$test_output" | grep -o "Time elapsed: [0-9.]* sec" | awk '{print $3}')
                fi
                
                # Only record if we have a test name
                if [ -n "$test_name" ]; then
                  # Generate a thread ID (using line number as proxy)
                  local thread_id="t-${line_num}"
                  echo "${current_time},${test_name},${test_duration},${test_status},${thread_id}" >> "${result_dir}/metrics/tests.csv"
                fi
              fi
            done <<<"$test_results"
            
            # Record the last processed line
            echo "$line_num" > "${result_dir}/.last_processed_line"
          fi
        fi
        
        # Print a progress indicator
        echo -ne "${COLOR_BLUE}.${COLOR_RESET}"
      fi
      
      # Sleep briefly before checking again
      sleep $check_interval
    done
    
    echo -e "\n${COLOR_GREEN}Monitoring complete.${COLOR_RESET}"
  ) &
  monitoring_pid=$!
  
  # Wait for user to press Ctrl+C or for max duration to elapse
  echo -e "${COLOR_YELLOW}Monitoring in progress. Press Ctrl+C to stop...${COLOR_RESET}"
  
  # Handle cleanup on exit
  trap 'kill $monitoring_pid 2>/dev/null || true; echo -e "\n${COLOR_YELLOW}Monitoring stopped by user.${COLOR_RESET}"; calculate_monitoring_summary "$result_dir" "$start_time"' INT TERM EXIT
  
  # Wait for the background process to finish
  wait $monitoring_pid
  
  # Calculate and display summary
  calculate_monitoring_summary "$result_dir" "$start_time"
}

# Calculate and display monitoring summary
calculate_monitoring_summary() {
  local result_dir="$1"
  local start_time="$2"
  
  # Calculate elapsed time
  local current_time=$(date +%s)
  local elapsed=$((current_time - start_time))
  
  # Collect basic statistics
  local system_metrics="${result_dir}/metrics/system.csv"
  local peak_cpu=0
  local avg_cpu=0
  local peak_memory=0
  local avg_memory=0
  
  if [ -f "$system_metrics" ] && [ $(wc -l < "$system_metrics") -gt 1 ]; then
    peak_cpu=$(tail -n +2 "$system_metrics" | cut -d, -f2 | sort -nr | head -1)
    avg_cpu=$(tail -n +2 "$system_metrics" | cut -d, -f2 | awk '{ sum += $1 } END { if (NR > 0) print sum / NR; else print 0 }')
    peak_memory=$(tail -n +2 "$system_metrics" | cut -d, -f3 | sort -nr | head -1)
    avg_memory=$(tail -n +2 "$system_metrics" | cut -d, -f3 | awk '{ sum += $1 } END { if (NR > 0) print sum / NR; else print 0 }')
  fi
  
  # Collect test statistics if available
  local test_metrics="${result_dir}/metrics/tests.csv"
  local test_count=0
  local test_failures=0
  
  if [ -f "$test_metrics" ] && [ $(wc -l < "$test_metrics") -gt 1 ]; then
    test_count=$(tail -n +2 "$test_metrics" | wc -l)
    test_failures=$(grep -c ",FAILURE," "$test_metrics" || echo 0)
  fi
  
  # Display summary
  echo -e "\n${COLOR_BOLD}${COLOR_GREEN}Monitoring completed.${COLOR_RESET}"
  echo -e "Total monitoring duration: $(format_duration $elapsed)"
  echo -e "Peak CPU usage: ${peak_cpu}%"
  echo -e "Average CPU usage: ${avg_cpu}%"
  echo -e "Peak memory usage: ${peak_memory} MB"
  echo -e "Average memory usage: ${avg_memory} MB"
  
  if [ "$test_count" -gt 0 ]; then
    echo -e "Tests monitored: $test_count"
    echo -e "Test failures: $test_failures"
  fi
  
  echo -e "All metrics saved to: ${result_dir}/metrics/"
}

# Generate a comprehensive monitoring report
generate_monitoring_report() {
  local result_dir="$1"
  
  echo -e "\n${COLOR_BOLD}${COLOR_BLUE}=== Generating Comprehensive Monitoring Report ===${COLOR_RESET}"
  local report_file="${result_dir}/test_monitoring_report.md"

  # Get test session information
  local session_start=$(head -n 2 "${result_dir}/metrics/system.csv" 2>/dev/null | tail -1 | cut -d, -f1 2>/dev/null || echo "$(date +%s)")
  local session_end=$(tail -1 "${result_dir}/metrics/system.csv" 2>/dev/null | cut -d, -f1 2>/dev/null || echo "$(date +%s)")
  local elapsed=$((session_end - session_start))
  local formatted_duration=$(format_duration $elapsed)
  
  # Extract system metrics if available
  local peak_cpu=0
  local avg_cpu=0
  local peak_memory=0
  local avg_memory=0
  local system_metrics="${result_dir}/metrics/system.csv"
  
  if [ -f "$system_metrics" ] && [ $(wc -l < "$system_metrics") -gt 1 ]; then
    peak_cpu=$(tail -n +2 "$system_metrics" | cut -d, -f2 | sort -nr | head -1)
    avg_cpu=$(tail -n +2 "$system_metrics" | cut -d, -f2 | awk '{ sum += $1 } END { if (NR > 0) print sum / NR; else print 0 }')
    peak_memory=$(tail -n +2 "$system_metrics" | cut -d, -f3 | sort -nr | head -1)
    avg_memory=$(tail -n +2 "$system_metrics" | cut -d, -f3 | awk '{ sum += $1 } END { if (NR > 0) print sum / NR; else print 0 }')
  fi
  
  # Extract test metrics if available
  local test_count=0
  local test_failures=0
  local failure_rate=0
  local test_data="${result_dir}/metrics/tests.csv"
  
  if [ -f "$test_data" ] && [ $(wc -l < "$test_data") -gt 1 ]; then
    test_count=$(wc -l < "$test_data")
    test_count=$((test_count - 1)) # Subtract header
    test_failures=$(grep -c ",FAILURE," "$test_data" || echo 0)
    
    if [ "$test_count" -gt 0 ]; then
      failure_rate=$(echo "scale=2; $test_failures * 100 / $test_count" | bc 2>/dev/null || echo 0)
    fi
  fi
  
  # Extract JVM metrics if available
  local avg_heap=0
  local max_heap=0
  local total_gc_time=0
  local jvm_metrics="${result_dir}/metrics/jvm.csv"
  
  if [ -f "$jvm_metrics" ] && [ $(wc -l < "$jvm_metrics") -gt 1 ]; then
    avg_heap=$(tail -n +2 "$jvm_metrics" | cut -d, -f2 | awk '{ sum += $1 } END { if (NR > 0) print sum / NR; else print 0 }')
    max_heap=$(tail -n +2 "$jvm_metrics" | cut -d, -f2 | sort -nr | head -1)
    total_gc_time=$(tail -1 "$jvm_metrics" | cut -d, -f7)
  fi
  
  # Analyze slow tests
  local avg_duration=0
  local max_duration=0
  local slow_tests=""
  local slow_count=0
  
  if [ -f "$test_data" ] && [ $(wc -l < "$test_data") -gt 1 ]; then
    avg_duration=$(tail -n +2 "$test_data" | cut -d, -f3 | awk '{ sum += $1 } END { if (NR > 0) print sum / NR; else print 0 }')
    max_duration=$(tail -n +2 "$test_data" | cut -d, -f3 | sort -nr | head -1)
    
    # Define slow tests as taking more than 2x the average time
    local slow_threshold=$(echo "$avg_duration * 2" | bc 2>/dev/null || echo 10)
    slow_count=$(awk -F, -v threshold="$slow_threshold" 'NR>1 && $3 > threshold {count++} END {print count}' "$test_data")
    
    # Get top 5 slowest tests
    slow_tests=$(tail -n +2 "$test_data" | sort -t, -k3 -nr | head -5 | awk -F, '{print "* " $2 " (" $3 "s)"}')
  fi
  
  # Look for build errors in Maven logs
  local build_log="${result_dir}/maven_output.log"
  local compilation_errors=0
  local dependency_errors=0
  local test_errors=0
  
  if [ -f "$build_log" ]; then
    compilation_errors=$(grep -c "COMPILATION ERROR" "$build_log" || echo 0)
    dependency_errors=$(grep -c "dependencies.*not found\|package.*does not exist" "$build_log" || echo 0)
    test_errors=$(grep -c "Tests run:.*Failures:" "$build_log" || echo 0)
  fi
  
  # Generate the report
  {
    echo "# MVNimble Test Monitoring Report"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    echo "## Session Overview"
    echo ""
    echo "* **Start Time**: $(date -r $session_start '+%Y-%m-%d %H:%M:%S')"
    echo "* **End Time**: $(date -r $session_end '+%Y-%m-%d %H:%M:%S')"
    echo "* **Duration**: $formatted_duration"
    echo "* **Tests Completed**: $test_count"
    echo "* **Test Failures**: $test_failures ($failure_rate% failure rate)"
    echo ""
    
    echo "## Resource Utilization"
    echo ""
    echo "### CPU Usage"
    echo ""
    echo "* **Average**: ${avg_cpu}%"
    echo "* **Maximum**: ${peak_cpu}%"
    echo ""
    
    echo "### Memory Usage"
    echo ""
    echo "* **Average**: ${avg_memory}MB"
    echo "* **Maximum**: ${peak_memory}MB"
    echo ""
    
    # Include JVM metrics if available
    if [ -f "$jvm_metrics" ] && [ $(wc -l < "$jvm_metrics") -gt 1 ]; then
      echo "### JVM Metrics"
      echo ""
      echo "* **Average Heap Usage**: ${avg_heap}MB"
      echo "* **Maximum Heap Usage**: ${max_heap}MB"
      echo "* **Total GC Time**: ${total_gc_time}ms"
      echo ""
    fi
    
    # Include test performance if we have test data
    if [ -f "$test_data" ] && [ $(wc -l < "$test_data") -gt 1 ]; then
      echo "## Test Performance Analysis"
      echo ""
      echo "### Test Duration Statistics"
      echo ""
      echo "* **Average Test Duration**: ${avg_duration}s"
      echo "* **Maximum Test Duration**: ${max_duration}s"
      echo "* **Slow Tests** (>2x average): $slow_count"
      echo ""
      
      if [ -n "$slow_tests" ]; then
        echo "### Top 5 Slowest Tests"
        echo ""
        echo "$slow_tests"
        echo ""
      fi
      
      # Include failure information if we have failures
      if [ "$test_failures" -gt 0 ]; then
        echo "### Test Failures"
        echo ""
        echo "Failed tests:"
        grep ",FAILURE," "$test_data" | cut -d, -f2 | while read -r test; do
          echo "* $test"
        done
        echo ""
      fi
    else
      echo "## Test Performance Analysis"
      echo ""
      echo "No detailed test metrics available."
      echo ""
    fi
    
    # Include build issue summary if available
    if [ -f "$build_log" ]; then
      echo "## Build Issues Summary"
      echo ""
      echo "* **Compilation Errors**: $compilation_errors"
      echo "* **Dependency Issues**: $dependency_errors"
      echo "* **Test Errors**: $test_errors"
      echo ""
      
      # Extract specific error messages if available
      if [ "$compilation_errors" -gt 0 ]; then
        echo "### Compilation Error Details"
        echo ""
        grep -A 5 "COMPILATION ERROR" "$build_log" | grep "ERROR" | grep -v "COMPILATION ERROR" | head -10 | while read -r error; do
          echo "* $error"
        done
        echo ""
      fi
      
      if [ "$dependency_errors" -gt 0 ]; then
        echo "### Dependency Issues"
        echo ""
        grep "dependencies.*not found\|package.*does not exist" "$build_log" | head -10 | while read -r error; do
          echo "* $error"
        done
        echo ""
      fi
    fi
    
    echo "## Performance Recommendations"
    echo ""
    
    # Generate CPU recommendations
    if [ "$(echo "$peak_cpu > 80" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
      echo "* **CPU Bottleneck**: Tests are CPU-bound. Consider reducing parallelism or upgrading CPU resources."
    elif [ "$(echo "$peak_cpu < 30" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
      echo "* **CPU Underutilization**: CPU resources are underutilized. Consider increasing parallelism to improve throughput."
    fi
    
    # Generate memory recommendations
    local total_mem=$(get_total_memory_mb 2>/dev/null || echo 8192)
    if [ "$(echo "$peak_memory > $total_mem * 0.8" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
      echo "* **Memory Pressure**: Tests approaching memory limits. Consider increasing available memory or optimizing memory usage."
    fi
    
    # Generate test optimization recommendations
    if [ "$slow_count" -gt 0 ] && [ "$test_count" -gt 0 ]; then
      local slow_percentage=$(echo "scale=2; $slow_count * 100 / $test_count" | bc 2>/dev/null || echo 0)
      if [ "$(echo "$slow_percentage > 10" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
        echo "* **Test Optimization**: ${slow_percentage}% of tests are significantly slower than average. Consider optimizing these tests first."
      fi
    fi
    
    # Add GC recommendations if applicable
    if [ -f "$jvm_metrics" ] && [ "$(echo "$total_gc_time > 1000" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
      local gc_percentage=$(echo "scale=2; $total_gc_time / 1000 * 100 / $elapsed" | bc 2>/dev/null || echo 0)
      if [ "$(echo "$gc_percentage > 10" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
        echo "* **Garbage Collection Overhead**: GC is consuming ${gc_percentage}% of execution time. Consider tuning JVM memory settings."
      fi
    fi
    
    echo ""
    echo "## Next Steps"
    echo ""
    echo "1. Review test logs for specific error patterns in failing tests"
    echo "2. Consider implementing the performance recommendations above"
    echo "3. Run MVNimble with optimization analysis to get specific JVM and Maven configuration recommendations"
    echo ""
    
    echo "---"
    echo "Report generated by MVNimble Test Engineering Tricorder"
    
  } > "$report_file"
  
  echo -e "${COLOR_GREEN}Comprehensive monitoring report generated: ${report_file}${COLOR_RESET}"
}

# Analyze build failure from logs and metrics
analyze_build_failure() {
  local build_log="$1"
  local metrics_dir="$2"
  local output_report="$3"
  
  echo -e "\n${COLOR_BOLD}${COLOR_BLUE}=== Build Failure Analysis ===${COLOR_RESET}"

  # Validate inputs
  if [ ! -f "$build_log" ]; then
    echo -e "${COLOR_YELLOW}Build log file not found: $build_log${COLOR_RESET}"
    # Generate basic empty report
    {
      echo "# Build Failure Analysis Report"
      echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
      echo ""
      echo "No build log available for analysis."
      echo ""
    } > "$output_report"
    echo -e "${COLOR_YELLOW}Created empty report due to missing build log${COLOR_RESET}"
    return 1
  fi
  
  # Extract build information
  local build_timestamp=$(head -n 20 "$build_log" | grep -o "Finished at: [0-9-]\+ [0-9:]\+" | head -1 | sed 's/Finished at: //')
  if [ -z "$build_timestamp" ]; then
    build_timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  fi
  
  # Extract project information
  local project_name=$(grep -o "Building .*" "$build_log" | head -1 | sed 's/Building //')
  if [ -z "$project_name" ]; then
    project_name="Unknown Project"
  fi
  
  # Count total errors and warnings
  local error_count=$(grep -c "\[ERROR\]" "$build_log" || echo 0)
  local warning_count=$(grep -c "\[WARNING\]" "$build_log" || echo 0)
  
  # Identify build phases that executed
  local phases=()
  if grep -q "validate" "$build_log"; then phases+=("validate"); fi
  if grep -q "compile" "$build_log"; then phases+=("compile"); fi
  if grep -q "test-compile" "$build_log"; then phases+=("test-compile"); fi
  if grep -q "test" "$build_log"; then phases+=("test"); fi
  if grep -q "package" "$build_log"; then phases+=("package"); fi
  if grep -q "verify" "$build_log"; then phases+=("verify"); fi
  if grep -q "install" "$build_log"; then phases+=("install"); fi
  
  # Determine failure phase
  local failure_phase="unknown"
  for phase in validate compile test-compile test package verify install; do
    if grep -q "Failed to execute goal.*$phase" "$build_log"; then
      failure_phase=$phase
      break
    fi
  done
  
  # Categorize errors
  local compilation_errors=$(grep -c "COMPILATION ERROR" "$build_log" || echo 0)
  local dependency_errors=$(grep -c "dependencies.*not found\|package.*does not exist\|Could not resolve dependencies\|Cannot resolve reference\|could not be resolved" "$build_log" || echo 0)
  local test_failures=$(grep -o "Tests run:.*Failures: [0-9]*" "$build_log" | grep -o "Failures: [0-9]*" | grep -o "[0-9]*" | tr -d '\n' | sed 's/^$/0/')
  local test_errors=$(grep -o "Tests run:.*Errors: [0-9]*" "$build_log" | grep -o "Errors: [0-9]*" | grep -o "[0-9]*" | tr -d '\n' | sed 's/^$/0/')
  local plugin_errors=$(grep -c "Plugin.*not found\|Error executing plugin\|Plugin.*execution not covered by lifecycle" "$build_log" || echo 0)
  local memory_errors=$(grep -c "OutOfMemoryError\|GC overhead limit exceeded\|Java heap space" "$build_log" || echo 0)
  
  # Extract specific error messages
  local compiler_errors=$(grep -A 5 "COMPILATION ERROR" "$build_log" | grep "ERROR" | grep -v "COMPILATION ERROR" | head -10)
  local dependency_messages=$(grep -B 2 -A 2 "dependencies.*not found\|package.*does not exist\|Could not resolve dependencies" "$build_log" | head -10)
  local plugin_messages=$(grep -B 2 -A 2 "Plugin.*not found\|Error executing plugin" "$build_log" | head -5)
  
  # Extract test failure details
  local test_failure_details=$(grep -A 5 "<<< FAILURE!" "$build_log" | head -20)
  
  # Extract resource metrics if available
  local peak_cpu=0
  local peak_memory=0
  local system_metrics="${metrics_dir}/system.csv"
  
  if [ -f "$system_metrics" ] && [ $(wc -l < "$system_metrics") -gt 1 ]; then
    peak_cpu=$(tail -n +2 "$system_metrics" | cut -d, -f2 | sort -nr | head -1)
    peak_memory=$(tail -n +2 "$system_metrics" | cut -d, -f3 | sort -nr | head -1)
  fi
  
  # Generate primary failure reason
  local primary_reason=""
  if [ "$compilation_errors" -gt 0 ]; then
    primary_reason="Compilation Errors"
  elif [ "$dependency_errors" -gt 0 ]; then
    primary_reason="Dependency Resolution Issues"
  elif [ "$test_failures" -gt 0 ] || [ "$test_errors" -gt 0 ]; then
    primary_reason="Test Failures"
  elif [ "$plugin_errors" -gt 0 ]; then
    primary_reason="Plugin Execution Errors"
  elif [ "$memory_errors" -gt 0 ]; then
    primary_reason="Memory Issues"
  else
    primary_reason="Unknown Build Failure"
  fi
  
  # Generate recommendations based on error type
  local recommendations=()
  
  if [ "$compilation_errors" -gt 0 ]; then
    recommendations+=("* Fix the compilation errors identified in the error details section")
    recommendations+=("* Ensure your code follows the language syntax and all required packages are imported")
    recommendations+=("* Check for typographical errors in identifiers and keywords")
  fi
  
  if [ "$dependency_errors" -gt 0 ]; then
    recommendations+=("* Check your project's dependencies and ensure all required libraries are in your pom.xml")
    recommendations+=("* Verify dependency versions are compatible with your project")
    recommendations+=("* Run 'mvn dependency:tree' to analyze the dependency hierarchy")
    recommendations+=("* Consider adding explicit dependencies for transitively imported packages")
  fi
  
  if [ "$test_failures" -gt 0 ] || [ "$test_errors" -gt 0 ]; then
    recommendations+=("* Investigate failing tests and fix the underlying issues")
    recommendations+=("* Run individual failing tests with 'mvn test -Dtest=TestClassName'")
    recommendations+=("* Look for environmental factors that might cause test failures")
  fi
  
  if [ "$plugin_errors" -gt 0 ]; then
    recommendations+=("* Verify plugin versions and configurations in your build file")
    recommendations+=("* Ensure all required plugins are declared in your build configuration")
  fi
  
  if [ "$memory_errors" -gt 0 ]; then
    recommendations+=("* Increase Java heap size with MAVEN_OPTS=\"-Xmx4g\"")
    recommendations+=("* Reduce parallelism with -DforkCount=1 -DreuseForks=true")
    recommendations+=("* Consider splitting large test suites into smaller runs")
  fi
  
  # If CPU or memory usage is high
  if [ "$(echo "$peak_cpu > 90" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
    recommendations+=("* Reduce CPU load by decreasing parallelism in your build")
    recommendations+=("* Consider running on a machine with more CPU resources")
  fi
  
  local total_mem=$(get_total_memory_mb 2>/dev/null || echo 8192)
  if [ "$(echo "$peak_memory > $total_mem * 0.9" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
    recommendations+=("* Increase available memory or reduce memory consumption")
    recommendations+=("* Configure memory limits for Maven and JVM more conservatively")
  fi
  
  # Write the analysis report
  {
    echo "# Build Failure Analysis Report"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    echo "## Overview"
    echo ""
    echo "* **Project**: $project_name"
    echo "* **Build Time**: $build_timestamp"
    echo "* **Error Count**: $error_count"
    echo "* **Warning Count**: $warning_count"
    echo "* **Primary Failure Reason**: $primary_reason"
    echo "* **Failed Phase**: $failure_phase"
    echo ""
    
    echo "## Error Breakdown"
    echo ""
    echo "* **Compilation Errors**: $compilation_errors"
    echo "* **Dependency Issues**: $dependency_errors"
    echo "* **Test Failures**: $test_failures"
    echo "* **Test Errors**: $test_errors"
    echo "* **Plugin Errors**: $plugin_errors"
    echo "* **Memory Issues**: $memory_errors"
    echo ""
    
    if [ -n "$compiler_errors" ]; then
      echo "## Compilation Error Details"
      echo ""
      echo '```'
      echo "$compiler_errors"
      echo '```'
      echo ""
    fi
    
    if [ -n "$dependency_messages" ]; then
      echo "## Dependency Issues"
      echo ""
      echo '```'
      echo "$dependency_messages"
      echo '```'
      echo ""
    fi
    
    if [ -n "$plugin_messages" ]; then
      echo "## Plugin Errors"
      echo ""
      echo '```'
      echo "$plugin_messages"
      echo '```'
      echo ""
    fi
    
    if [ -n "$test_failure_details" ]; then
      echo "## Test Failure Details"
      echo ""
      echo '```'
      echo "$test_failure_details"
      echo '```'
      echo ""
    fi
    
    echo "## Resource Utilization"
    echo ""
    echo "* **Peak CPU Usage**: ${peak_cpu}%"
    echo "* **Peak Memory Usage**: ${peak_memory}MB"
    echo "* **Total System Memory**: ${total_mem}MB"
    echo ""
    
    echo "## Recommendations"
    echo ""
    for recommendation in "${recommendations[@]}"; do
      echo "$recommendation"
    done
    echo ""
    
    echo "## Next Steps"
    echo ""
    echo "1. Address the primary failure reason: $primary_reason"
    echo "2. Fix errors in sequence, starting with compilation and dependency issues"
    echo "3. Run the build with more detailed logging for troubleshooting: 'mvn -X clean install'"
    echo "4. Consider running with Maven Batch Mode for cleaner output: 'mvn -B clean install'"
    echo ""
    
    echo "---"
    echo "Report generated by MVNimble Test Engineering Tricorder"
    
  } > "$output_report"
  
  echo -e "${COLOR_GREEN}Build failure analysis complete${COLOR_RESET}"
  echo -e "Report generated: $output_report"
}

# Enhanced build failure analysis with detailed categorization and advanced metrics
function enhanced_build_failure_analysis() {
  local build_log="$1"
  local metrics_dir="$2"
  local output_report="$3"
  local detailed="${4:-true}"  # Option to enable detailed analysis
  
  # First perform the standard analysis as a baseline
  analyze_build_failure "$build_log" "$metrics_dir" "$output_report"
  local base_status=$?
  
  # If detailed analysis is enabled and the standard analysis succeeded
  if [[ "$detailed" == "true" && $base_status -eq 0 ]]; then
    # Append enhanced analysis sections to the report
    local report_temp="${output_report}.enhanced.tmp"
    
    # Preserve original report
    cp "$output_report" "$report_temp"
    
    # Add enhanced analysis sections
    {
      echo ""
      echo "## Enhanced Analysis"
      echo ""
      echo "This section contains advanced diagnostic information based on additional metrics and patterns."
      echo ""
      
      # Add time-based correlation analysis if we have timestamps
      if grep -q "timestamp" "${metrics_dir}/system.csv" 2>/dev/null; then
        echo "### Time-Based Correlation Analysis"
        echo ""
        echo "Examining temporal patterns in resource utilization and failure events:"
        echo ""
        
        # Check if we can find temporal patterns in test failures and resource spikes
        local failure_times=$(grep -o "Tests run:.*Failures: [1-9]" "$build_log" | 
                           grep -o -n "Failures: [1-9]" | cut -d: -f1)
        
        if [ -n "$failure_times" ]; then
          echo "* Identified $(echo "$failure_times" | wc -l | tr -d ' ') potential failure clusters"
          echo "* Analyzing resource metrics around these failure points"
          echo ""
        else
          echo "* No clear temporal failure patterns detected"
          echo ""
        fi
      fi
      
      # Add dependency analysis if we detected issues
      if grep -q "dependency" "$output_report"; then
        echo "### Dependency Conflict Analysis"
        echo ""
        echo "Detecting potential library version conflicts and dependency resolution issues:"
        echo ""
        
        # Extract dependency conflicts from log
        local conflicts=$(grep -A 2 "Conflict" "$build_log" | grep -v "^--$" || echo "None detected")
        
        if [ "$conflicts" != "None detected" ]; then
          echo "Detected dependency conflicts:"
          echo '```'
          echo "$conflicts"
          echo '```'
          echo ""
        else
          echo "* No explicit dependency conflicts detected"
          echo ""
        fi
      fi
      
      echo "### Future Investigation Suggestions"
      echo ""
      echo "Based on this failure analysis, consider investigating:"
      echo ""
      echo "* Test flakiness patterns with repeated test runs"
      echo "* External dependency stability with connection monitoring"
      echo "* Resource usage optimization opportunities"
      echo "* Configuration parameter fine-tuning"
      echo ""
      
    } >> "$report_temp"
    
    # Replace original report with enhanced version
    mv "$report_temp" "$output_report"
  fi
  
  return $base_status
}

# Generate advanced recommendations based on build failure patterns
generate_enhanced_build_recommendations() {
  local build_log="$1"
  local metrics_dir="$2"
  local output_report="$3"
  
  echo -e "${COLOR_CYAN}Generating detailed build recommendations...${COLOR_RESET}"
  
  # Validate inputs
  if [ ! -f "$build_log" ]; then
    echo -e "${COLOR_YELLOW}Build log file not found: $build_log${COLOR_RESET}"
    # Generate basic empty report
    {
      echo "# Build Optimization Recommendations"
      echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
      echo ""
      echo "No build log available for analysis."
      echo ""
    } > "$output_report"
    echo -e "${COLOR_YELLOW}Created empty recommendations due to missing build log${COLOR_RESET}"
    return 1
  fi
  
  # Extract project information
  local project_name=$(grep -o "Building .*" "$build_log" | head -1 | sed 's/Building //')
  if [ -z "$project_name" ]; then
    project_name="Unknown Project"
  fi
  
  # Analyze build times
  local build_times=$(grep "Time:" "$build_log" | grep -o "[0-9]\+\.[0-9]\+ s" | tr -d 's' | tr -d ' ')
  local total_build_time=$(grep "Total time:" "$build_log" | grep -o "[0-9]\+\.[0-9]\+ s" | head -1 | tr -d 's' | tr -d ' ')
  if [ -z "$total_build_time" ]; then
    total_build_time="unknown"
  fi
  
  # Identify slow plugins
  local plugin_times=()
  while read -r plugin_line; do
    local plugin_name=$(echo "$plugin_line" | awk '{print $1}')
    local plugin_time=$(echo "$plugin_line" | grep -o "[0-9]\+\.[0-9]\+ s" | head -1 | tr -d 's' | tr -d ' ')
    if [ -n "$plugin_name" ] && [ -n "$plugin_time" ]; then
      if [ "$(echo "$plugin_time > 1.0" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
        plugin_times+=("* **$plugin_name**: ${plugin_time}s")
      fi
    fi
  done < <(grep "maven-.*-plugin:\|jacoco:\|spotless:\|kotlin:" "$build_log" | grep "Time:")
  
  # Extract resource metrics if available
  local peak_cpu=0
  local avg_cpu=0
  local peak_memory=0
  local avg_memory=0
  local system_metrics="${metrics_dir}/system.csv"
  
  if [ -f "$system_metrics" ] && [ $(wc -l < "$system_metrics") -gt 1 ]; then
    peak_cpu=$(tail -n +2 "$system_metrics" | cut -d, -f2 | sort -nr | head -1)
    avg_cpu=$(tail -n +2 "$system_metrics" | cut -d, -f2 | awk '{ sum += $1 } END { if (NR > 0) print sum / NR; else print 0 }')
    peak_memory=$(tail -n +2 "$system_metrics" | cut -d, -f3 | sort -nr | head -1)
    avg_memory=$(tail -n +2 "$system_metrics" | cut -d, -f3 | awk '{ sum += $1 } END { if (NR > 0) print sum / NR; else print 0 }')
  fi
  
  # Check if tests were run and analyze test execution
  local test_count=0
  local test_time=0
  local test_line=$(grep "Tests run:" "$build_log" | head -1)
  if [ -n "$test_line" ]; then
    test_count=$(echo "$test_line" | grep -o "Tests run: [0-9]*" | grep -o "[0-9]*")
    test_time=$(grep "maven-surefire-plugin:.*test" "$build_log" | grep -o "[0-9]\+\.[0-9]\+ s" | head -1 | tr -d 's' | tr -d ' ')
  fi
  
  # Check for dependency issues
  local has_dependency_issues=$(grep -c "Could not resolve dependencies\|package .* does not exist" "$build_log" || echo 0)
  
  # Check for memory issues
  local has_memory_issues=$(grep -c "OutOfMemoryError\|GC overhead\|Java heap space" "$build_log" || echo 0)
  
  # Check for parallelism information
  local threads_info=$(grep -o "-T [0-9C].*" "$build_log" | head -1 || echo "")
  local surefire_forks=$(grep -o "forkCount=[0-9C].*" "$build_log" | head -1 || echo "")
  if [ -z "$threads_info" ]; then
    threads_info="default (1 thread)"
  fi
  if [ -z "$surefire_forks" ]; then
    surefire_forks="default (1 fork)"
  fi
  
  # Create recommendations
  local build_recommendations=()
  local parallelism_recommendations=()
  local memory_recommendations=()
  local test_recommendations=()
  local dependency_recommendations=()
  
  # Basic optimizations everyone should consider
  build_recommendations+=("* **Use Maven Build Cache**: Enable the Maven build cache to speed up successive builds")
  build_recommendations+=("* **Enable Incremental Compilation**: Use compiler plugin with incremental compilation")
  build_recommendations+=("* **Skip Tests When Appropriate**: Use -DskipTests or -Dmaven.test.skip=true for quick builds")
  
  # Parallelism recommendations
  if [ "$peak_cpu" -lt 50 ]; then
    parallelism_recommendations+=("* **Increase Build Parallelism**: Run Maven with '-T 2C' to use more CPU cores")
    parallelism_recommendations+=("* **Increase Test Parallelism**: Configure Surefire plugin with more forks: -DforkCount=2C")
  elif [ "$peak_cpu" -gt 90 ]; then
    parallelism_recommendations+=("* **CPU Saturation Detected**: Consider reducing build parallelism to reduce contention")
  else
    parallelism_recommendations+=("* **Current Parallelism**: Your build is using a balanced amount of CPU resources")
  fi
  
  # Memory recommendations
  local total_mem=$(get_total_memory_mb 2>/dev/null || echo 8192)
  if [ "$(echo "$peak_memory > $total_mem * 0.8" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
    memory_recommendations+=("* **Memory Pressure Detected**: Your build is using ${peak_memory}MB (${total_mem}MB available)")
    memory_recommendations+=("* **Increase JVM Heap Size**: Consider using MAVEN_OPTS=\"-Xmx${total_mem}m\"")
  fi
  
  if [ "$has_memory_issues" -gt 0 ]; then
    memory_recommendations+=("* **Memory Errors Detected**: Increase Java heap size with MAVEN_OPTS=\"-Xmx4g\"")
    memory_recommendations+=("* **Reduce Test Memory Usage**: Configure surefire with -DforkCount=1 -DreuseForks=true")
  fi
  
  # Test recommendations
  if [ "$test_count" -gt 100 ] && [ "$(echo "$test_time > 30.0" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
    test_recommendations+=("* **Large Test Suite**: Consider partitioning tests or running them in parallel")
    test_recommendations+=("* **Test Categorization**: Use JUnit categories or TestNG groups to organize tests")
  fi
  
  # Dependency recommendations
  if [ "$has_dependency_issues" -gt 0 ]; then
    dependency_recommendations+=("* **Dependency Issues Detected**: Ensure all dependencies are correctly declared")
    dependency_recommendations+=("* **Dependency Analysis**: Run 'mvn dependency:analyze' to find undeclared dependencies")
    dependency_recommendations+=("* **Dependency Tree**: Run 'mvn dependency:tree' to visualize your dependency hierarchy")
  fi
  
  # Write the recommendations report
  {
    echo "# Build Optimization Recommendations"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    echo "## Project Overview"
    echo ""
    echo "* **Project**: $project_name"
    echo "* **Total Build Time**: ${total_build_time}s"
    if [ "$test_count" -gt 0 ]; then
      echo "* **Tests Executed**: $test_count"
      echo "* **Test Execution Time**: ${test_time}s"
    fi
    echo "* **Maven Parallelism**: $threads_info"
    echo "* **Test Forks**: $surefire_forks"
    echo ""
    
    echo "## Resource Utilization"
    echo ""
    echo "* **Peak CPU Usage**: ${peak_cpu}%"
    echo "* **Average CPU Usage**: ${avg_cpu}%"
    echo "* **Peak Memory Usage**: ${peak_memory}MB"
    echo "* **Average Memory Usage**: ${avg_memory}MB"
    echo ""
    
    if [ ${#plugin_times[@]} -gt 0 ]; then
      echo "## Slow Build Plugins"
      echo ""
      echo "The following plugins are taking significant time in your build:"
      echo ""
      for plugin_time in "${plugin_times[@]}"; do
        echo "$plugin_time"
      done
      echo ""
    fi
    
    echo "## General Build Optimizations"
    echo ""
    for recommendation in "${build_recommendations[@]}"; do
      echo "$recommendation"
    done
    echo ""
    
    if [ ${#parallelism_recommendations[@]} -gt 0 ]; then
      echo "## Parallelism Optimizations"
      echo ""
      for recommendation in "${parallelism_recommendations[@]}"; do
        echo "$recommendation"
      done
      echo ""
    fi
    
    if [ ${#memory_recommendations[@]} -gt 0 ]; then
      echo "## Memory Optimizations"
      echo ""
      for recommendation in "${memory_recommendations[@]}"; do
        echo "$recommendation"
      done
      echo ""
    fi
    
    if [ ${#test_recommendations[@]} -gt 0 ]; then
      echo "## Test Execution Optimizations"
      echo ""
      for recommendation in "${test_recommendations[@]}"; do
        echo "$recommendation"
      done
      echo ""
    fi
    
    if [ ${#dependency_recommendations[@]} -gt 0 ]; then
      echo "## Dependency Management"
      echo ""
      for recommendation in "${dependency_recommendations[@]}"; do
        echo "$recommendation"
      done
      echo ""
    fi
    
    echo "## Maven Configuration Examples"
    echo ""
    echo "### Speed up builds with parallel execution:"
    echo '```'
    echo "# Run with 2x CPU cores"
    echo "mvn -T 2C clean install"
    echo ""
    echo "# Run with 4 threads"
    echo "mvn -T 4 clean install"
    echo '```'
    echo ""
    
    echo "### Configure JVM memory:"
    echo '```'
    echo "# Set Maven memory options"
    echo "export MAVEN_OPTS=\"-Xmx4g -Xms1g\""
    echo "mvn clean install"
    echo ""
    echo "# Configure test execution memory"
    echo "mvn clean test -DargLine=\"-Xmx2g -Xms1g\""
    echo '```'
    echo ""
    
    echo "### Optimize test execution:"
    echo '```'
    echo "# Run tests with controlled parallelism"
    echo "mvn clean test -DforkCount=2 -DreuseForks=true"
    echo ""
    echo "# Skip tests for faster builds during development"
    echo "mvn clean install -DskipTests"
    echo ""
    echo "# Run specific tests only"
    echo "mvn test -Dtest=YourTestClass"
    echo '```'
    echo ""
    
    echo "---"
    echo "Report generated by MVNimble Test Engineering Tricorder"
    
  } > "$output_report"
  
  echo -e "${COLOR_GREEN}Build recommendations generated${COLOR_RESET}"
  echo -e "Recommendations saved to: $output_report"
}

# Identify test flakiness patterns from test execution data
identify_flakiness_patterns() {
  local result_dir="$1"
  local test_history_file="$2" # Optional historical test data
  
  echo -e "\n${COLOR_BOLD}${COLOR_BLUE}=== Flakiness Pattern Analysis ===${COLOR_RESET}"
  
  # Check if we have test data
  if [ ! -f "${result_dir}/metrics/tests.csv" ] || [ $(wc -l < "${result_dir}/metrics/tests.csv") -le 1 ]; then
    echo -e "${COLOR_YELLOW}Insufficient test data for flakiness analysis.${COLOR_RESET}"
    return
  fi
  
  # Use test history file if provided, otherwise use current metrics
  local analysis_file="${result_dir}/metrics/tests.csv"
  if [ -n "$test_history_file" ] && [ -f "$test_history_file" ]; then
    analysis_file="$test_history_file"
    echo -e "Using historical test data for analysis: $test_history_file"
  fi
  
  # Extract test failures
  local failure_count=$(grep -c ",FAILURE," "$analysis_file" || echo 0)
  if [ "$failure_count" -eq 0 ]; then
    echo -e "${COLOR_GREEN}No test failures detected. No flakiness analysis needed.${COLOR_RESET}"
    
    # Generate empty flakiness report
    local flakiness_report="${result_dir}/flakiness_analysis.md"
    {
      echo "# Test Flakiness Analysis"
      echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
      echo ""
      echo "## Overview"
      echo ""
      echo "No test failures were detected in this run. No flakiness analysis could be performed."
      echo ""
    } > "$flakiness_report"
    
    echo -e "\nFlakiness analysis report generated: ${flakiness_report}"
    return
  fi
  
  # Extract failed tests
  local failed_tests=$(grep ",FAILURE," "$analysis_file" | cut -d, -f2 | sort | uniq)
  
  # Count failures per test
  local test_failure_counts=()
  for test in $failed_tests; do
    local count=$(grep ",${test}," "$analysis_file" | grep -c ",FAILURE," || echo 0)
    test_failure_counts+=("$test:$count")
  done
  
  # Sort by failure count
  IFS=$'\n' test_failure_counts=($(sort -t: -k2 -nr <<<"${test_failure_counts[*]}"))
  unset IFS
  
  # Analyze failure patterns for each test
  local test_patterns=()
  for entry in "${test_failure_counts[@]}"; do
    local test_name=$(echo "$entry" | cut -d: -f1)
    local fail_count=$(echo "$entry" | cut -d: -f2)
    
    # Check for time-based correlation (failures occurring close together)
    local timing_correlated=$(grep ",${test_name}," "$analysis_file" | grep ",FAILURE," | cut -d, -f1 | sort -n | 
      awk 'BEGIN {count=0; prev=0} {if (NR>1 && $1 - prev < 300) count++; prev=$1} END {print count}')
    
    # Check for thread-based correlation (failures on the same thread)
    local thread_counts=$(grep ",${test_name}," "$analysis_file" | grep ",FAILURE," | cut -d, -f5 | sort | uniq -c | sort -nr)
    local thread_issue=0
    local thread_id=""
    if [ -n "$thread_counts" ]; then
      local top_thread=$(echo "$thread_counts" | head -1)
      thread_id=$(echo "$top_thread" | awk '{print $2}')
      local thread_count=$(echo "$top_thread" | awk '{print $1}')
      
      # If more than 70% of failures occur on the same thread, it's likely a thread issue
      if [ "$(echo "scale=2; $thread_count * 100 / $fail_count > 70" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
        thread_issue=1
      fi
    fi
    
    # Analyze time patterns
    local time_pattern_issue=0
    local time_pattern=""
    
    # Extract failure times and check for patterns (time of day, etc.)
    local failure_timestamps=$(grep ",${test_name}," "$analysis_file" | grep ",FAILURE," | cut -d, -f1)
    local time_groups=""
    
    if [ -n "$failure_timestamps" ]; then
      # Convert timestamps to hour of day and count occurrences
      local hour_counts=$(echo "$failure_timestamps" | while read -r ts; do 
        date -r "$ts" '+%H' 2>/dev/null || echo "00"
      done | sort | uniq -c | sort -nr)
      
      # If more than 50% of failures occur during the same hour, it might be a time-related issue
      local top_hour=$(echo "$hour_counts" | head -1)
      local hour_val=$(echo "$top_hour" | awk '{print $2}')
      local hour_count=$(echo "$top_hour" | awk '{print $1}')
      
      if [ "$(echo "scale=2; $hour_count * 100 / $fail_count > 50" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
        time_pattern_issue=1
        # Convert hour to readable time range
        time_pattern="between ${hour_val}:00 and ${hour_val}:59"
      fi
    fi
    
    # Construct pattern analysis
    local patterns=()
    
    if [ "$timing_correlated" -gt 1 ]; then
      patterns+=("* **Time Correlation**: Multiple failures occur in close time proximity (within minutes)")
      patterns+=("* **Potential Cause**: Resource contention, race conditions, or environment instability")
    fi
    
    if [ "$thread_issue" -eq 1 ]; then
      patterns+=("* **Thread Correlation**: Failures predominantly occur on thread '$thread_id'")
      patterns+=("* **Potential Cause**: Thread safety issues or concurrency bugs")
    fi
    
    if [ "$time_pattern_issue" -eq 1 ]; then
      patterns+=("* **Time Pattern**: Failures predominantly occur $time_pattern")
      patterns+=("* **Potential Cause**: Time-sensitive logic, resource availability at specific times")
    fi
    
    if [ "$fail_count" -gt 1 ]; then
      patterns+=("* **Frequency**: Test failed $fail_count times")
      if [ "$(echo "scale=2; $fail_count > 2" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
        patterns+=("* **High Flakiness**: This test shows a pattern of repeated failures")
      fi
    fi
    
    # Add the test and its patterns to the array
    test_patterns+=("$test_name:${patterns[*]}")
  done
  
  # Generate recommendations based on patterns
  local recommendations=()
  
  if [ "$(echo "$failure_count > 5" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
    recommendations+=("* Implement automatic test retry for flaky tests (e.g., with Maven Surefire's rerunFailingTestsCount)")
  fi
  
  if grep -q "Thread Correlation" <<<"${test_patterns[*]}"; then
    recommendations+=("* Review thread safety in your test and production code")
    recommendations+=("* Check for shared mutable state between tests")
    recommendations+=("* Consider using thread-local variables for test data")
  fi
  
  if grep -q "Time Correlation" <<<"${test_patterns[*]}"; then
    recommendations+=("* Verify test isolation and cleanup procedures")
    recommendations+=("* Check for resource leaks between test runs")
    recommendations+=("* Consider using dedicated test resources instead of shared ones")
  fi
  
  recommendations+=("* For repeatedly failing tests, create targeted debugging runs with -Dtest=TestClassName")
  recommendations+=("* Add additional logging to help diagnose intermittent failures")
  
  # Generate the flakiness report
  local flakiness_report="${result_dir}/flakiness_analysis.md"
  {
    echo "# Test Flakiness Analysis Report"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    echo "## Overview"
    echo ""
    echo "* **Total Test Failures**: $failure_count"
    echo "* **Unique Failing Tests**: $(echo "$failed_tests" | wc -w)"
    echo ""
    echo "This report analyzes test failures to identify potential flaky tests and patterns in their failure behavior."
    echo ""
    
    echo "## Identified Flaky Tests"
    echo ""
    for entry in "${test_failure_counts[@]}"; do
      local test_name=$(echo "$entry" | cut -d: -f1)
      local fail_count=$(echo "$entry" | cut -d: -f2)
      
      echo "### $test_name"
      echo "Failed $fail_count times"
      echo ""
      
      # Find the patterns for this test
      local test_pattern=""
      for pattern_entry in "${test_patterns[@]}"; do
        local pattern_test=$(echo "$pattern_entry" | cut -d: -f1)
        if [ "$pattern_test" = "$test_name" ]; then
          test_pattern=$(echo "$pattern_entry" | cut -d: -f2-)
          break
        fi
      done
      
      echo "#### Failure Patterns"
      echo ""
      if [ -n "$test_pattern" ]; then
        echo "$test_pattern" | tr ' ' '\n' | sed 's/^\*/\n*/g' | grep '^\*'
      else
        echo "No specific patterns detected."
      fi
      echo ""
      
      echo "#### Test Execution Details"
      echo ""
      echo "| Run Time | Result | Thread |"
      echo "|----------|--------|--------|"
      grep ",${test_name}," "$analysis_file" | head -5 | while IFS=, read -r timestamp name duration result thread; do
        local readable_time=$(date -r "$timestamp" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "$timestamp")
        echo "| $readable_time | $result | $thread |"
      done
      echo ""
    done
    
    echo "## Flakiness Patterns and Root Causes"
    echo ""
    echo "Based on the analysis, the following patterns have been identified:"
    echo ""
    
    if grep -q "Thread Correlation" <<<"${test_patterns[*]}"; then
      echo "### Thread-related Issues"
      echo ""
      echo "Several tests show failures correlated with specific threads, suggesting potential concurrency problems:"
      echo ""
      echo "* Possible race conditions between tests or within test logic"
      echo "* Shared mutable state that isn't properly synchronized"
      echo "* Thread safety issues in the implementation code"
      echo ""
    fi
    
    if grep -q "Time Correlation" <<<"${test_patterns[*]}"; then
      echo "### Timing-related Issues"
      echo ""
      echo "Tests showing failures in close time proximity may indicate:"
      echo ""
      echo "* Resource contention or depletion"
      echo "* Environment instability at certain times"
      echo "* Timing dependencies in tests (sleep-based waits instead of proper synchronization)"
      echo ""
    fi
    
    if grep -q "Time Pattern" <<<"${test_patterns[*]}"; then
      echo "### Time-of-day Patterns"
      echo ""
      echo "Some tests fail more frequently at specific times, which may indicate:"
      echo ""
      echo "* Time-zone related issues"
      echo "* Daily maintenance or backup jobs affecting resources"
      echo "* Load patterns affecting system performance"
      echo ""
    fi
    
    echo "## Recommendations"
    echo ""
    for recommendation in "${recommendations[@]}"; do
      echo "$recommendation"
    echo ""
    done
    
    echo "## Best Practices for Addressing Flaky Tests"
    echo ""
    echo "1. **Improve Test Isolation**"
    echo "   * Ensure each test has its own resources and data"
    echo "   * Implement proper setup and teardown procedures"
    echo "   * Avoid shared state between tests"
    echo ""
    echo "2. **Handle Asynchronous Operations**"
    echo "   * Replace fixed delays (Thread.sleep) with proper waiting mechanisms"
    echo "   * Use explicit waits with reasonable timeouts"
    echo "   * Consider tools like Awaitility for testing asynchronous code"
    echo ""
    echo "3. **Address Concurrency Issues**"
    echo "   * Review code for thread safety problems"
    echo "   * Use thread-safe collections and proper synchronization"
    echo "   * Consider testing in a single-threaded environment first"
    echo ""
    echo "4. **Implement Test Retries**"
    echo "   * Configure Maven Surefire to automatically retry failing tests"
    echo "   * Mark known flaky tests for automatic retry"
    echo "   * Use tools like JUnit's @RepeatedTest or TestNG's retryAnalyzer"
    echo ""
    
    echo "---"
    echo "Report generated by MVNimble Test Engineering Tricorder"
    
  } > "$flakiness_report"
  
  echo -e "\nFlakiness analysis report generated: ${flakiness_report}"
}

# Generate a resource correlation analysis to identify bottlenecks
generate_resource_correlation() {
  local result_dir="$1"
  
  echo -e "\n${COLOR_BOLD}${COLOR_BLUE}=== Resource Correlation Analysis ===${COLOR_RESET}"
  
  # Define input files
  local system_metrics="${result_dir}/metrics/system.csv"
  local test_metrics="${result_dir}/metrics/tests.csv"
  local jvm_metrics="${result_dir}/metrics/jvm.csv"
  local maven_log="${result_dir}/maven_output.log"
  
  # Check if we have enough data
  if [ ! -f "$system_metrics" ] || [ $(wc -l < "$system_metrics") -lt 10 ]; then
    echo -e "${COLOR_YELLOW}Insufficient system metrics for correlation analysis.${COLOR_RESET}"
    
    # Generate a basic report explaining the lack of data
    local correlation_report="${result_dir}/resource_correlation.md"
    {
      echo "# Resource Correlation Analysis"
      echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
      echo ""
      echo "## Overview"
      echo ""
      echo "Insufficient system metrics data is available for a comprehensive correlation analysis."
      echo "At least 10 data points are required to generate meaningful correlations."
      echo ""
      echo "### Recommendations"
      echo ""
      echo "* Run longer test sessions to collect more metrics data"
      echo "* Ensure the metrics collection interval is appropriate (5-10 seconds is recommended)"
      echo "* Verify that the system metrics collection module is functioning correctly"
      echo ""
    } > "$correlation_report"
    
    echo -e "\nBasic resource correlation report generated: ${correlation_report}"
    return 1
  fi
  
  # Extract system metrics
  local timestamps=$(tail -n +2 "$system_metrics" | cut -d, -f1)
  local cpu_values=$(tail -n +2 "$system_metrics" | cut -d, -f2)
  local memory_values=$(tail -n +2 "$system_metrics" | cut -d, -f3)
  local disk_io_values=$(tail -n +2 "$system_metrics" | cut -d, -f4 2>/dev/null || echo "")
  local network_io_values=$(tail -n +2 "$system_metrics" | cut -d, -f5 2>/dev/null || echo "")
  
  # Calculate basic statistics for system metrics
  local avg_cpu=$(echo "$cpu_values" | awk '{ sum += $1 } END { if (NR > 0) print sum / NR; else print 0 }')
  local avg_memory=$(echo "$memory_values" | awk '{ sum += $1 } END { if (NR > 0) print sum / NR; else print 0 }')
  local peak_cpu=$(echo "$cpu_values" | sort -nr | head -1)
  local peak_memory=$(echo "$memory_values" | sort -nr | head -1)
  
  # Calculate CPU volatility (standard deviation)
  local cpu_stddev=$(echo "$cpu_values" | awk -v avg="$avg_cpu" '{ sum += ($1 - avg)^2 } END { if (NR > 1) print sqrt(sum / (NR-1)); else print 0 }')
  
  # Calculate memory growth rate (if possible)
  local memory_start=$(echo "$memory_values" | head -1)
  local memory_end=$(echo "$memory_values" | tail -1)
  local memory_growth=0
  if [ -n "$memory_start" ] && [ -n "$memory_end" ]; then
    memory_growth=$(echo "scale=2; $memory_end - $memory_start" | bc 2>/dev/null || echo 0)
  fi
  
  # Detect resource bottlenecks
  local cpu_bottleneck=0
  local memory_bottleneck=0
  local io_bottleneck=0
  
  if [ "$(echo "$peak_cpu > 90" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
    cpu_bottleneck=1
  fi
  
  # Get total memory in MB
  local total_memory=$(get_total_memory_mb 2>/dev/null || echo 8192)
  if [ "$(echo "$peak_memory > $total_memory * 0.85" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
    memory_bottleneck=1
  fi
  
  # Check for disk I/O bottlenecks if available
  if [ -n "$disk_io_values" ] && [ $(echo "$disk_io_values" | grep -c "^[0-9]" || echo 0) -gt 0 ]; then
    local peak_disk_io=$(echo "$disk_io_values" | sort -nr | head -1)
    if [ "$(echo "$peak_disk_io > 80" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
      io_bottleneck=1
    fi
  fi
  
  # Analyze JVM metrics if available
  local jvm_analysis=""
  if [ -f "$jvm_metrics" ] && [ $(wc -l < "$jvm_metrics") -gt 1 ]; then
    local heap_values=$(tail -n +2 "$jvm_metrics" | cut -d, -f2)
    local gc_times=$(tail -n +2 "$jvm_metrics" | cut -d, -f7)
    
    local avg_heap=$(echo "$heap_values" | awk '{ sum += $1 } END { if (NR > 0) print sum / NR; else print 0 }')
    local peak_heap=$(echo "$heap_values" | sort -nr | head -1)
    local total_gc_time=$(echo "$gc_times" | tail -1)
    
    # Check for GC pressure
    local gc_pressure=0
    if [ -n "$total_gc_time" ] && [ "$(echo "$total_gc_time > 2000" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
      gc_pressure=1
    fi
    
    # Calculate heap growth rate
    local heap_start=$(echo "$heap_values" | head -1)
    local heap_end=$(echo "$heap_values" | tail -1)
    local heap_growth=0
    if [ -n "$heap_start" ] && [ -n "$heap_end" ]; then
      heap_growth=$(echo "scale=2; $heap_end - $heap_start" | bc 2>/dev/null || echo 0)
    fi
    
    # Create JVM analysis section
    jvm_analysis="
## JVM Resource Analysis

* **Average Heap Usage**: ${avg_heap}MB
* **Peak Heap Usage**: ${peak_heap}MB
* **Heap Growth**: ${heap_growth}MB over the session
* **Total GC Time**: ${total_gc_time}ms

"
    
    if [ "$gc_pressure" -eq 1 ]; then
      jvm_analysis="${jvm_analysis}
### Garbage Collection Pressure Detected

Significant time is being spent on garbage collection, which may be affecting performance:

* **GC Time**: ${total_gc_time}ms
* **Potential Impact**: Increased response times, reduced throughput
* **Recommendation**: Consider increasing heap size or optimizing object allocation patterns
"
    fi
    
    if [ "$(echo "$heap_growth > 100" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
      jvm_analysis="${jvm_analysis}
### Memory Leak Indicator

A steady increase in heap usage over time may indicate memory leaks:

* **Heap Growth Rate**: ${heap_growth}MB during the test session
* **Potential Impact**: Out of memory errors in longer runs
* **Recommendation**: Profile the application to identify objects that aren't being released
"
    fi
  fi
  
  # Correlate test failures with resource spikes if test data is available
  local test_correlation=""
  if [ -f "$test_metrics" ] && [ $(wc -l < "$test_metrics") -gt 1 ]; then
    local failed_tests=$(grep ",FAILURE," "$test_metrics" | cut -d, -f2 | sort | uniq)
    local failure_count=$(echo "$failed_tests" | wc -w)
    
    if [ "$failure_count" -gt 0 ]; then
      test_correlation="
## Test Failure Resource Correlation

We analyzed ${failure_count} failing tests to identify potential resource-related causes:

"
      
      for test in $failed_tests; do
        # Get timestamps of test failures
        local failure_times=$(grep ",${test},.*,FAILURE," "$test_metrics" | cut -d, -f1)
        
        # Check if we can correlate failure times with resource spikes
        local resource_correlated=0
        local correlation_type=""
        
        for failure_time in $failure_times; do
          # Look for resource metrics within 30 seconds of the failure
          local window_start=$(echo "$failure_time - 30" | bc)
          local window_end=$(echo "$failure_time + 30" | bc)
          
          # Check for CPU spikes around failure time
          local cpu_spike=$(awk -v start="$window_start" -v end="$window_end" -F',' '
            $1 >= start && $1 <= end && $2 > 80 {print $2; exit}
          ' "$system_metrics")
          
          if [ -n "$cpu_spike" ]; then
            resource_correlated=1
            correlation_type="CPU spike (${cpu_spike}%)"
            break
          fi
          
          # Check for memory spikes around failure time
          local mem_spike=$(awk -v start="$window_start" -v end="$window_end" -F',' '
            $1 >= start && $1 <= end && $3 > avg_memory * 1.3 {print $3; exit}
          ' "$system_metrics")
          
          if [ -n "$mem_spike" ]; then
            resource_correlated=1
            correlation_type="Memory spike (${mem_spike}MB)"
            break
          fi
          
          # Check for GC events around failure time if JVM metrics available
          if [ -f "$jvm_metrics" ]; then
            local gc_event=$(awk -v start="$window_start" -v end="$window_end" -F',' '
              $1 >= start && $1 <= end && $7 > 200 {print $7; exit}
            ' "$jvm_metrics")
            
            if [ -n "$gc_event" ]; then
              resource_correlated=1
              correlation_type="GC event (${gc_event}ms)"
              break
            fi
          fi
        done
        
        # Add correlation findings for this test
        if [ "$resource_correlated" -eq 1 ]; then
          test_correlation="${test_correlation}
### ${test}

* **Resource Correlation**: Yes
* **Correlation Type**: ${correlation_type}
* **Analysis**: This test failure correlates with resource pressure
* **Recommendation**: Consider optimizing resource usage or increasing available resources
"
        else
          test_correlation="${test_correlation}
### ${test}

* **Resource Correlation**: No
* **Analysis**: This test failure does not appear to be related to resource constraints
* **Recommendation**: Look for logical errors, data dependencies, or race conditions
"
        fi
      done
    fi
  fi
  
  # Analyze build phase timing if Maven log is available
  local build_timing=""
  if [ -f "$maven_log" ]; then
    # Extract build phases and their timing
    local phase_times=()
    while read -r phase_line; do
      local phase_name=$(echo "$phase_line" | awk '{print $2}' | sed 's/:.*//')
      local phase_time=$(echo "$phase_line" | grep -o "[0-9]\+\.[0-9]\+ s" | tr -d 's' | tr -d ' ')
      
      if [ -n "$phase_name" ] && [ -n "$phase_time" ]; then
        phase_times+=("$phase_name:$phase_time")
      fi
    done < <(grep "maven-.*-plugin:" "$maven_log" | grep "Time:")
    
    # Sort by execution time
    IFS=$'\n' phase_times=($(sort -t: -k2 -nr <<<"${phase_times[*]}"))
    unset IFS
    
    if [ ${#phase_times[@]} -gt 0 ]; then
      build_timing="
## Build Phase Resource Analysis

The following build phases were analyzed for resource correlation:

| Phase | Duration (s) | CPU Correlation | Memory Correlation |
|-------|--------------|-----------------|-------------------|
"
      
      for entry in "${phase_times[@]:0:5}"; do
        local phase=$(echo "$entry" | cut -d: -f1)
        local duration=$(echo "$entry" | cut -d: -f2)
        
        # Look for phase in Maven log to get approximate timestamp
        local phase_mention=$(grep -n "$phase" "$maven_log" | head -1 | cut -d: -f1)
        local phase_cpu="Low"
        local phase_memory="Low"
        
        if [ -n "$phase_mention" ]; then
          # Get approximate time range by counting lines in log file
          local total_lines=$(wc -l < "$maven_log")
          local relative_position=$(echo "scale=2; $phase_mention / $total_lines" | bc)
          
          # Estimate position in metrics timeline
          local metrics_count=$(wc -l < "$system_metrics")
          local metric_position=$(echo "scale=0; $relative_position * $metrics_count" | bc | sed 's/\..*$//')
          
          # Get metrics around that position (5 samples before and after)
          local range_start=$(echo "$metric_position - 5" | bc)
          local range_end=$(echo "$metric_position + 5" | bc)
          
          if [ "$range_start" -lt 2 ]; then range_start=2; fi
          if [ "$range_end" -gt "$metrics_count" ]; then range_end=$metrics_count; fi
          
          # Extract CPU and memory in that range
          local phase_cpu_values=$(sed -n "${range_start},${range_end}p" "$system_metrics" | cut -d, -f2)
          local phase_memory_values=$(sed -n "${range_start},${range_end}p" "$system_metrics" | cut -d, -f3)
          
          # Calculate averages
          local phase_avg_cpu=$(echo "$phase_cpu_values" | awk '{ sum += $1 } END { if (NR > 0) print sum / NR; else print 0 }')
          local phase_avg_memory=$(echo "$phase_memory_values" | awk '{ sum += $1 } END { if (NR > 0) print sum / NR; else print 0 }')
          
          # Determine correlation level
          if [ "$(echo "$phase_avg_cpu > 70" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
            phase_cpu="High (${phase_avg_cpu}%)"
          elif [ "$(echo "$phase_avg_cpu > 40" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
            phase_cpu="Medium (${phase_avg_cpu}%)"
          else
            phase_cpu="Low (${phase_avg_cpu}%)"
          fi
          
          if [ "$(echo "$phase_avg_memory > $total_memory * 0.7" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
            phase_memory="High (${phase_avg_memory}MB)"
          elif [ "$(echo "$phase_avg_memory > $total_memory * 0.4" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
            phase_memory="Medium (${phase_avg_memory}MB)"
          else
            phase_memory="Low (${phase_avg_memory}MB)"
          fi
        fi
        
        build_timing="${build_timing}
| $phase | $duration | $phase_cpu | $phase_memory |"
      done
      
      build_timing="${build_timing}

### Build Phase Recommendations

"
      
      # Add recommendations based on build phase analysis
      local has_recommendations=0
      
      if echo "$build_timing" | grep -q "High (.*%)" || echo "$build_timing" | grep -q "Medium (.*%)"; then
        build_timing="${build_timing}
* **CPU-Intensive Phases**: Some build phases show high CPU utilization. Consider:
  * Running these phases with reduced parallelism
  * Optimizing the relevant code or configuration
  * Allocating more CPU resources for these phases
"
        has_recommendations=1
      fi
      
      if echo "$build_timing" | grep -q "High (.*MB)" || echo "$build_timing" | grep -q "Medium (.*MB)"; then
        build_timing="${build_timing}
* **Memory-Intensive Phases**: Some build phases show high memory utilization. Consider:
  * Increasing available memory for the build
  * Configuring memory limits for specific plugins
  * Breaking large modules into smaller ones
"
        has_recommendations=1
      fi
      
      if [ "$has_recommendations" -eq 0 ]; then
        build_timing="${build_timing}
* No significant resource issues detected in build phases
"
      fi
    fi
  fi
  
  # Generate comprehensive recommendations based on all findings
  local cpu_recommendations=""
  local memory_recommendations=""
  local io_recommendations=""
  local general_recommendations=""
  
  if [ "$cpu_bottleneck" -eq 1 ]; then
    cpu_recommendations="
### CPU Optimization Recommendations

* **Reduce Build Parallelism**: Use '-T 1C' or '-T 1' to limit concurrent processes
* **Optimize CPU-Intensive Tests**: Profile and optimize tests that consume large amounts of CPU
* **Distribute Build**: Consider using a distributed build system or more powerful hardware
* **Selective Execution**: Run only necessary tests for your changes
* **CPU Isolation**: Ensure no other CPU-intensive processes are running during builds
"
  elif [ "$(echo "$avg_cpu < 30" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
    cpu_recommendations="
### CPU Utilization Recommendations

* **Increase Parallelism**: CPU resources are underutilized. Use '-T 2C' or '-T 2' to increase concurrency
* **Batch Operations**: Run more operations in parallel to better utilize available CPU
* **Pipeline Optimization**: Structure your build to maximize parallel execution of tasks
"
  fi
  
  if [ "$memory_bottleneck" -eq 1 ]; then
    memory_recommendations="
### Memory Optimization Recommendations

* **Increase Heap Size**: Set `MAVEN_OPTS=\"-Xmx${total_memory}m -XX:MaxMetaspaceSize=512m\"`
* **Memory Leak Hunting**: Use Java profilers to identify potential memory leaks
* **Reduce Memory-Intensive Operations**: Configure large operations to use less memory
* **Incremental Builds**: Use incremental compilation to reduce memory pressure
* **JVM Tuning**: Adjust GC algorithm using `-XX:+UseG1GC` for large heap sizes
"
  fi
  
  if [ "$io_bottleneck" -eq 1 ]; then
    io_recommendations="
### I/O Optimization Recommendations

* **Use SSD Storage**: Move build directories to faster storage if possible
* **Local Repository Optimization**: Clean and optimize your Maven local repository
* **Reduce I/O Operations**: Minimize file operations during builds
* **Network Dependency Caching**: Use a local artifact repository like Nexus or Artifactory
* **I/O Profiling**: Use I/O profiling tools to identify bottlenecks
"
  fi
  
  # General recommendations that apply in most cases
  general_recommendations="
### General Performance Recommendations

* **Build Caching**: Enable incremental builds and build caching
* **Optimize Test Execution**: Use test categories to selectively run tests
* **Dependency Management**: Regularly update and clean dependencies
* **Run Regular System Maintenance**: Keep the build environment optimized
* **Monitoring**: Continue monitoring resource usage to identify trends over time
"
  
  # Generate the full correlation report
  local correlation_report="${result_dir}/resource_correlation.md"
  {
    echo "# Resource Correlation Analysis"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    echo "## Executive Summary"
    echo ""
    echo "This report analyzes system resource utilization during the build and test process, identifying correlations between resource constraints and build/test performance."
    echo ""
    
    if [ "$cpu_bottleneck" -eq 1 ]; then
      echo "* **CPU Bottleneck Detected**: Peak CPU usage reached ${peak_cpu}%, which may be limiting build performance"
    fi
    
    if [ "$memory_bottleneck" -eq 1 ]; then
      echo "* **Memory Pressure Detected**: Peak memory usage reached ${peak_memory}MB out of ${total_memory}MB available"
    fi
    
    if [ "$io_bottleneck" -eq 1 ]; then
      echo "* **I/O Bottleneck Detected**: High disk or network I/O activity may be limiting performance"
    fi
    
    if [ "$cpu_bottleneck" -eq 0 ] && [ "$memory_bottleneck" -eq 0 ] && [ "$io_bottleneck" -eq 0 ]; then
      echo "* **No Critical Resource Bottlenecks Detected**: System resources appear sufficient for the current build and test workload"
    fi
    
    echo ""
    
    echo "## System Resource Utilization"
    echo ""
    echo "### CPU Utilization"
    echo ""
    echo "* **Average CPU Usage**: ${avg_cpu}%"
    echo "* **Peak CPU Usage**: ${peak_cpu}%"
    echo "* **CPU Volatility**: ${cpu_stddev}% (standard deviation)"
    echo ""
    
    echo "### Memory Utilization"
    echo ""
    echo "* **Average Memory Usage**: ${avg_memory}MB"
    echo "* **Peak Memory Usage**: ${peak_memory}MB"
    echo "* **Total Available Memory**: ${total_memory}MB"
    echo "* **Memory Growth**: ${memory_growth}MB over the session"
    echo ""
    
    # Add JVM analysis if available
    if [ -n "$jvm_analysis" ]; then
      echo "$jvm_analysis"
    fi
    
    # Add test correlation if available
    if [ -n "$test_correlation" ]; then
      echo "$test_correlation"
    fi
    
    # Add build phase timing if available
    if [ -n "$build_timing" ]; then
      echo "$build_timing"
    fi
    
    echo "## System Resource Trends"
    echo ""
    echo "### Resource Usage Patterns"
    echo ""
    
    # Analyze CPU patterns
    if [ "$(echo "$cpu_stddev > 20" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
      echo "* **High CPU Volatility**: CPU usage varies significantly (${cpu_stddev}% std dev)"
      echo "  * This suggests CPU-bound operations occurring in bursts"
      echo "  * Potential for optimization by distributing CPU load more evenly"
    else
      echo "* **Stable CPU Utilization**: CPU usage is relatively consistent"
      echo "  * This suggests a balanced workload without excessive bursts"
    fi
    
    # Analyze memory patterns
    if [ "$(echo "$memory_growth > 100" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
      echo "* **Increasing Memory Trend**: Memory usage grew by ${memory_growth}MB during the session"
      echo "  * This may indicate memory leaks or accumulating resources"
      echo "  * Longer runs may eventually lead to out-of-memory conditions"
    elif [ "$(echo "$memory_growth < -100" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
      echo "* **Decreasing Memory Trend**: Memory usage decreased by ${memory_growth#-}MB during the session"
      echo "  * This indicates good memory cleanup or explicit GC activity"
    else
      echo "* **Stable Memory Usage**: Memory usage remained relatively constant"
      echo "  * This suggests proper resource management and garbage collection"
    fi
    
    echo ""
    
    echo "## Resource Optimization Recommendations"
    echo ""
    
    # Add specific recommendation sections
    if [ -n "$cpu_recommendations" ]; then
      echo "$cpu_recommendations"
    fi
    
    if [ -n "$memory_recommendations" ]; then
      echo "$memory_recommendations"
    fi
    
    if [ -n "$io_recommendations" ]; then
      echo "$io_recommendations"
    fi
    
    echo "$general_recommendations"
    
    echo ""
    echo "## Maven Configuration Examples"
    echo ""
    
    echo "### Optimizing CPU Usage"
    echo '```bash'
    if [ "$cpu_bottleneck" -eq 1 ]; then
      echo "# Reduce parallelism for CPU-constrained environments"
      echo "mvn '-T 1C' clean install"
      echo ""
      echo "# Disable parallel test execution"
      echo "mvn -DforkCount=1 clean test"
    else
      echo "# Increase parallelism for better CPU utilization"
      echo "mvn '-T 2C' clean install"
      echo ""
      echo "# Parallelize test execution"
      echo "mvn -DforkCount=2C clean test"
    fi
    echo '```'
    echo ""
    
    echo "### Optimizing Memory Usage"
    echo '```bash'
    if [ "$memory_bottleneck" -eq 1 ]; then
      echo "# Increase Java heap size"
      echo "export MAVEN_OPTS=\"-Xmx${total_memory}m -XX:MaxMetaspaceSize=512m -XX:+UseG1GC\""
      echo ""
      echo "# Reduce memory pressure in tests"
      echo "mvn -DforkCount=1 -DreuseForks=true clean test"
    else
      local suggested_mem=$(echo "scale=0; $total_memory * 0.7" | bc)
      echo "# Allocate optimal memory"
      echo "export MAVEN_OPTS=\"-Xmx${suggested_mem}m -XX:MaxMetaspaceSize=256m\""
      echo ""
      echo "# Balance memory usage across forks"
      echo "mvn -DforkCount=2 -DreuseForks=true clean test"
    fi
    echo '```'
    echo ""
    
    echo "### Optimizing Build Caching"
    echo '```bash'
    echo "# Enable incremental compilation"
    echo "mvn -T 2C -Dmaven.compiler.incremental=true clean install"
    echo ""
    echo "# Use offline mode when dependencies are already resolved"
    echo "mvn -o clean install"
    echo '```'
    echo ""
    
    echo "---"
    echo "Report generated by MVNimble Test Engineering Tricorder"
    
  } > "$correlation_report"
  
  echo -e "${COLOR_GREEN}Resource correlation analysis report generated: ${correlation_report}${COLOR_RESET}"
}

# Function to generate build recommendations (alias for enhanced version)
function generate_build_recommendations() {
  # Pass all arguments to the enhanced version and return its exit code
  generate_enhanced_build_recommendations "$@"
  return $?
}