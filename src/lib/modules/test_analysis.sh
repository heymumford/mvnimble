#!/usr/bin/env bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# test_analysis.sh
# MVNimble - Test analysis and optimization module
#
# This module provides functions for analyzing Maven test patterns,
# optimizing test configurations, and analyzing test performance.
#
# Author: MVNimble Team
# Version: 1.0.0

# Define the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Import modules
if [[ -z "${CONSTANTS_LOADED+x}" ]]; then
  source "${SCRIPT_DIR}/constants.sh"
fi
source "${SCRIPT_DIR}/platform_compatibility.sh"

# ============================================================
# Maven Test Pattern Analysis Functions
# ============================================================

# Detect test dimensions used in the project
detect_test_dimensions() {
  # Check for various test dimension frameworks
  if [ -f "pom.xml" ]; then
    # Check for JUnit Jupiter
    if grep -q "junit-jupiter" pom.xml; then
      echo "junit5=true"
    else
      echo "junit5=false"
    fi
    
    # Check for custom test dimensions
    if grep -q "test.dimension" pom.xml; then
      echo "custom_dimensions=true"
      
      # Extract dimension types
      DIMENSION_PATTERNS=$(grep -A 30 "<profile>" pom.xml | grep "test.dimension=" | sort | uniq | cut -d= -f2 | cut -d'<' -f1 | tr -d ' ')
      echo "dimension_patterns=$DIMENSION_PATTERNS"
    else
      echo "custom_dimensions=false"
    fi
    
    # Check for TestNG
    if grep -q "<artifactId>testng</artifactId>" pom.xml; then
      echo "testng=true"
    else
      echo "testng=false"
    fi
  fi
}

# Function to get Maven settings from pom.xml
get_maven_settings() {
  if grep -q "<jvm.fork.count>" pom.xml; then
    ORIGINAL_FORK_COUNT=$(grep -E "<jvm.fork.count>" pom.xml | grep -oE "[0-9.]+C?" || echo "1.0C")
  else
    ORIGINAL_FORK_COUNT="1.0C"
  fi
  
  if grep -q "<maven.threads>" pom.xml; then
    ORIGINAL_MAVEN_THREADS=$(grep -E "<maven.threads>" pom.xml | grep -oE "[0-9]+" | head -1 || echo "1")
  else
    ORIGINAL_MAVEN_THREADS="1"
  fi
  
  if grep -q "<jvm.fork.memory>" pom.xml; then
    ORIGINAL_FORK_MEMORY=$(grep -E "<jvm.fork.memory>" pom.xml | grep -oE "[0-9]+M?" || echo "256M")
  else
    ORIGINAL_FORK_MEMORY="256M"
  fi
  
  echo "fork_count=$ORIGINAL_FORK_COUNT,threads=$ORIGINAL_MAVEN_THREADS,memory=$ORIGINAL_FORK_MEMORY"
}

# Update pom.xml with specific settings
update_pom() {
  local fork_count=$1
  local threads=$2
  local heap_size=$3
  
  # Create a backup if it doesn't exist
  if [[ ! -f "pom.xml.mvnimblebackup" ]]; then
    cp pom.xml pom.xml.mvnimblebackup
  fi
  
  # Update pom.xml
  if grep -q "<jvm.fork.count>" pom.xml; then
    sed -i.tmp "s/<jvm.fork.count>[^<]*<\/jvm.fork.count>/<jvm.fork.count>${fork_count}<\/jvm.fork.count>/" pom.xml
  fi
  
  if grep -q "<maven.threads>" pom.xml; then
    sed -i.tmp "s/<maven.threads>[^<]*<\/maven.threads>/<maven.threads>${threads}<\/maven.threads>/" pom.xml
  fi
  
  if grep -q "<jvm.fork.memory>" pom.xml; then
    sed -i.tmp "s/<jvm.fork.memory>[^<]*<\/jvm.fork.memory>/<jvm.fork.memory>${heap_size}M<\/jvm.fork.memory>/" pom.xml
  fi
  
  rm -f pom.xml.tmp
}

# Restore original pom.xml
restore_pom() {
  if [ -f "pom.xml.mvnimblebackup" ]; then
    cp pom.xml.mvnimblebackup pom.xml
    echo -e "${COLOR_GREEN}Restored original pom.xml settings${COLOR_RESET}"
  fi
}

# Run tests with a specific configuration and analyze resource usage
run_test_with_monitoring() {
  local fork_count=$1
  local threads=$2
  local heap_size=$3
  local test_pattern=$4
  local result_dir=$5
  local is_thread_safety_test=${6:-false}
  
  local config_name="fork${fork_count//./}_t${threads}_m${heap_size}"
  local log_file="${result_dir}/test_${config_name}.log"
  
  echo -e "\n${COLOR_YELLOW}Testing configuration: Forks=${fork_count}, Threads=${threads}, Heap=${heap_size}MB${COLOR_RESET}"
  
  # Update pom.xml with this configuration
  update_pom "$fork_count" "$threads" "${heap_size}"
  
  # Prepare test command
  local mvn_cmd="mvn clean test"
  if [ -n "$test_pattern" ]; then
    mvn_cmd="${mvn_cmd} -Dtest=${test_pattern}"
  fi
  
  if [ -n "$TARGET_DIMENSION" ]; then
    mvn_cmd="${mvn_cmd} -Dgroups=test.dimension=${TARGET_DIMENSION}"
  fi
  
  # Skip non-essential plugins to speed up execution
  mvn_cmd="${mvn_cmd} -Djacoco.skip=true -Dcheckstyle.skip=true -Dpmd.skip=true -Dspotbugs.skip=true"
  
  # Start monitoring in background
  local monitor_file="${result_dir}/monitor_${config_name}.log"
  (
    # Record stats every second for up to 180 seconds or until test completes
    for i in {1..180}; do
      if [ -f "${log_file}.running" ]; then
        # CPU usage for Java processes
        echo "TIME: $(date +%s)" >> "$monitor_file"
        echo "CPU: $(ps -C java -o %cpu | tail -n +2 | awk '{sum+=$1} END {print sum}')" >> "$monitor_file"
        echo "MEM: $(ps -C java -o rss | tail -n +2 | awk '{sum+=$1} END {print sum/1024}')" >> "$monitor_file"
        
        # I/O stats if available
        if [ -f /proc/diskstats ]; then
          grep -w "sda" /proc/diskstats >> "$monitor_file" 2>/dev/null || true
        fi
        
        echo "---" >> "$monitor_file"
        sleep 1
      else
        break
      fi
    done
  ) &
  MONITOR_PID=$!
  
  # Create a marker file to signal monitoring
  touch "${log_file}.running"
  
  # Run the test and time it
  echo -e "Running: ${COLOR_CYAN}${mvn_cmd}${COLOR_RESET}"
  START_TIME=$(date +%s.%N)
  
  ${mvn_cmd} > "$log_file" 2>&1
  TEST_STATUS=$?
  
  END_TIME=$(date +%s.%N)
  # Remove the marker file
  rm -f "${log_file}.running"
  
  # Calculate elapsed time
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS doesn't support the same date arithmetic
    ELAPSED=$(perl -e "printf \"%.2f\", $END_TIME - $START_TIME")
  else
    ELAPSED=$(echo "$END_TIME - $START_TIME" | bc)
  fi
  
  # Wait for monitoring to finish
  if kill -0 $MONITOR_PID 2>/dev/null; then
    kill $MONITOR_PID
  fi
  
  # Analyze test results
  TESTS_RUN=$(grep -E "Tests run: [0-9]+" "$log_file" | awk '{sum+=$3} END {print sum}')
  TESTS_FAILED=$(grep -E "Tests run: [0-9]+" "$log_file" | awk '{sum+=$5} END {print sum}')
  
  # Extract peak resource usage
  if [ -f "$monitor_file" ]; then
    PEAK_CPU=$(grep "CPU:" "$monitor_file" | cut -d' ' -f2 | sort -nr | head -1)
    PEAK_MEM=$(grep "MEM:" "$monitor_file" | cut -d' ' -f2 | sort -nr | head -1)
  else
    PEAK_CPU="N/A"
    PEAK_MEM="N/A"
  fi
  
  if [ $TEST_STATUS -eq 0 ]; then
    echo -e "${COLOR_GREEN}Tests completed successfully in ${COLOR_BOLD}${ELAPSED}${COLOR_RESET}${COLOR_GREEN} seconds${COLOR_RESET}"
  else
    echo -e "${COLOR_RED}Tests failed in ${COLOR_BOLD}${ELAPSED}${COLOR_RESET}${COLOR_RED} seconds${COLOR_RESET}"
  fi
  
  echo -e "Tests run: ${TESTS_RUN}, Tests failed: ${TESTS_FAILED}"
  echo -e "Peak CPU: ${PEAK_CPU}%, Peak Memory: ${PEAK_MEM} MB"
  
  # Skip recording thread safety test runs in the main results
  if [[ "$is_thread_safety_test" != "true" ]]; then
    # Record results to CSV
    echo "${fork_count},${threads},${heap_size},${ELAPSED},${TESTS_RUN},${TESTS_FAILED},${PEAK_CPU},${PEAK_MEM},${TEST_STATUS}" >> "${result_dir}/results.csv"
  fi
  
  # Give system time to recover
  sleep 3
  
  # Return key metrics for analysis
  echo "time=${ELAPSED},status=${TEST_STATUS},peak_cpu=${PEAK_CPU},peak_mem=${PEAK_MEM}"
}

# Generate different test configurations based on environment
generate_test_configs() {
  local env_info=$1
  local env_type=$(echo "$env_info" | cut -d',' -f1 | cut -d'=' -f2)
  local cpu_count=$(echo "$env_info" | cut -d',' -f2 | cut -d'=' -f2)
  local mem_total=$(echo "$env_info" | cut -d',' -f3 | cut -d'=' -f2)
  local mode=$2
  local configs=()
  
  # Base configurations to test
  if [[ "$mode" == "quick" ]]; then
    # Quick mode - few configs
    configs=(
      "0.5C:$((cpu_count)):$((mem_total / 4))"
      "1.0C:$((cpu_count)):$((mem_total / 3))"
      "2.0C:$((cpu_count / 2)):$((mem_total / 2))"
    )
  elif [[ "$mode" == "container" ]]; then
    # Container focus - test memory-sensitive configs
    configs=(
      "0.25C:$((cpu_count)):$((mem_total / 8))"
      "0.25C:$((cpu_count)):$((mem_total / 6))"
      "0.25C:$((cpu_count)):$((mem_total / 4))"
      "0.5C:$((cpu_count / 2)):$((mem_total / 6))"
      "0.5C:$((cpu_count / 2)):$((mem_total / 4))"
      "0.5C:$((cpu_count / 2)):$((mem_total / 3))"
    )
  else
    # Full mode - comprehensive testing
    configs=(
      "0.25C:$((cpu_count)):$((mem_total / 8))"
      "0.25C:$((cpu_count * 2)):$((mem_total / 6))"
      "0.5C:$((cpu_count / 2)):$((mem_total / 6))"
      "0.5C:$((cpu_count)):$((mem_total / 4))"
      "0.5C:$((cpu_count * 2)):$((mem_total / 4))"
      "1.0C:$((cpu_count / 2)):$((mem_total / 4))"
      "1.0C:$((cpu_count)):$((mem_total / 3))"
      "1.0C:$((cpu_count * 2)):$((mem_total / 3))"
      "2.0C:$((cpu_count / 2)):$((mem_total / 3))"
      "2.0C:$((cpu_count)):$((mem_total / 2))"
    )
  fi
  
  # Container-specific adjustments
  if [[ "$env_type" == "container" || "$env_type" == "kubernetes" ]]; then
    # Add more conservative memory configurations for containers
    configs+=(
      "0.25C:$((cpu_count / 2)):$((mem_total / 10))"
      "0.25C:$((cpu_count / 2)):$((mem_total / 12))"
    )
  fi
  
  echo "${configs[@]}"
}

# ============================================================
# Thread Safety Analysis Functions
# ============================================================

# Analyze thread safety of tests
analyze_thread_safety() {
  local result_dir=$1
  local thread_safety=$2
  local test_pattern=$3
  local cpu_count=$4
  
  if [[ "$thread_safety" != "true" ]]; then
    return
  fi
  
  echo -e "\n${COLOR_BOLD}${COLOR_BLUE}=== Thread Safety Analysis ===${COLOR_RESET}"
  
  # First run with single thread to establish baseline
  echo -e "Running baseline test with minimal threading..."
  update_pom "0.25C" "1" "1024"
  
  # Create baseline test pattern
  local BASELINE_PATTERN="*Test"
  if [ -n "$test_pattern" ]; then
    BASELINE_PATTERN="$test_pattern"
  fi
  
  # Run baseline test
  run_test_with_monitoring "0.25C" "1" "1024" "$BASELINE_PATTERN" "$result_dir" true
  local BASELINE_LOG="${result_dir}/baseline_test.log"
  mv "${result_dir}/test_fork0.25C_t1_m1024.log" "$BASELINE_LOG"
  
  # Now run with high parallelism
  echo -e "\n${COLOR_BOLD}${COLOR_CYAN}Running tests with high parallelism to detect thread issues...${COLOR_RESET}"
  run_test_with_monitoring "1.0C" "$((cpu_count * 2))" "1024" "$BASELINE_PATTERN" "$result_dir" true
  local PARALLEL_LOG="${result_dir}/parallel_test.log"
  mv "${result_dir}/test_fork1.0C_t${cpu_count * 2}_m1024.log" "$PARALLEL_LOG"
  
  # Compare results to identify thread safety issues
  echo -e "\n${COLOR_BOLD}${COLOR_CYAN}Analyzing thread safety issues...${COLOR_RESET}"
  
  # Extract passing tests from baseline
  local BASELINE_PASSING=$(grep -E "Tests run: [0-9]+, Failures: 0, Errors: 0, Skipped: [0-9]+" "$BASELINE_LOG" | \
                       sed -E 's/.*Running (.*)/\1/' | grep -v "Running" || echo "")
  
  # Extract failing tests from parallel run
  local PARALLEL_FAILING=$(grep -E "Tests run: [0-9]+, Failures: [1-9][0-9]*, Errors: [0-9]+, Skipped: [0-9]+" "$PARALLEL_LOG" | \
                       sed -E 's/.*Running (.*)/\1/' | grep -v "Running" || echo "")
  
  # Find tests that passed in baseline but failed in parallel
  local THREAD_UNSAFE_TESTS=""
  for test in $PARALLEL_FAILING; do
    if echo "$BASELINE_PASSING" | grep -q "$test"; then
      THREAD_UNSAFE_TESTS="$THREAD_UNSAFE_TESTS $test"
    fi
  done
  
  # Check common thread safety exceptions
  local COMMON_EXCEPTIONS=$(grep -E "ConcurrentModificationException|IllegalStateException|IndexOutOfBoundsException|NullPointerException" "$PARALLEL_LOG" | \
                        sort | uniq -c | sort -nr || echo "")
  
  # Analyze thread safety findings
  if [ -n "$THREAD_UNSAFE_TESTS" ]; then
    echo -e "${COLOR_YELLOW}Detected ${#THREAD_UNSAFE_TESTS[@]} potentially thread-unsafe tests:${COLOR_RESET}"
    for test in $THREAD_UNSAFE_TESTS; do
      echo -e "- $test"
    done
    
    echo -e "\n${COLOR_BOLD}Common thread safety exceptions:${COLOR_RESET}"
    if [ -n "$COMMON_EXCEPTIONS" ]; then
      echo -e "$COMMON_EXCEPTIONS"
    else
      echo -e "No common thread safety exceptions found"
    fi
    
    echo -e "\n${COLOR_BOLD}${COLOR_CYAN}Thread Safety Recommendations:${COLOR_RESET}"
    echo -e "1. Consider using thread-local variables for non-shared state"
    echo -e "2. Implement proper synchronization for shared resources"
    echo -e "3. Use concurrent collections (ConcurrentHashMap, CopyOnWriteArrayList) for shared collections"
    echo -e "4. Make test setup and teardown methods thread-safe"
    echo -e "5. Avoid static mutable fields in test classes"
    
    # Save thread safety report
    local THREAD_SAFETY_REPORT="${result_dir}/thread_safety_report.txt"
    echo "Thread Safety Analysis Report" > "$THREAD_SAFETY_REPORT"
    echo "===============================" >> "$THREAD_SAFETY_REPORT"
    echo "Date: $(date)" >> "$THREAD_SAFETY_REPORT"
    echo "" >> "$THREAD_SAFETY_REPORT"
    echo "Thread-Unsafe Tests:" >> "$THREAD_SAFETY_REPORT"
    for test in $THREAD_UNSAFE_TESTS; do
      echo "- $test" >> "$THREAD_SAFETY_REPORT"
    done
    echo "" >> "$THREAD_SAFETY_REPORT"
    echo "Common Exceptions:" >> "$THREAD_SAFETY_REPORT"
    echo "$COMMON_EXCEPTIONS" >> "$THREAD_SAFETY_REPORT"
    
    echo -e "\nDetailed thread safety report saved to: ${COLOR_BOLD}${THREAD_SAFETY_REPORT}${COLOR_RESET}"
  else
    echo -e "${COLOR_GREEN}Good news! No thread safety issues detected.${COLOR_RESET}"
    echo -e "Your tests appear to be thread-safe and can safely be run in parallel."
  fi
}