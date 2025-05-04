#!/usr/bin/env bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# monitoring_validation.sh
# Validation tests for MVNimble's real-time test monitoring capabilities
#
# This script validates the "Test Engineering Tricorder" functionality
# by running various monitoring scenarios and verifying their results.
#
# Author: MVNimble Team
# Version: 1.0.0

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"

# Import common testing functions
source "${ROOT_DIR}/src/lib/modules/constants.sh"
source "${ROOT_DIR}/src/lib/modules/common.sh"
source "${ROOT_DIR}/test/bats/common/environment_helpers.bash"

# Define output directory
RESULTS_DIR="${ROOT_DIR}/results/validation/monitoring"
mkdir -p "${RESULTS_DIR}"

# Define test project path (use simple-junit-project from examples)
TEST_PROJECT="${ROOT_DIR}/examples/simple-junit-project"

# Initialize validation results
VALIDATION_SCORE=0
TOTAL_VALIDATIONS=0

# Log validation results
log_validation() {
  local name="$1"
  local result="$2"
  local expected="$3"
  local score="$4"
  local max_score="$5"
  local description="$6"
  
  VALIDATION_SCORE=$((VALIDATION_SCORE + score))
  TOTAL_VALIDATIONS=$((TOTAL_VALIDATIONS + max_score))
  
  echo "[$name] $description: $result (Expected: $expected, Score: $score/$max_score)" >> "${RESULTS_DIR}/validation_results.log"
  
  if [ "$score" -eq "$max_score" ]; then
    echo -e "${COLOR_GREEN}✓ $name: $description - Passed${COLOR_RESET}"
  else
    echo -e "${COLOR_RED}✗ $name: $description - Failed${COLOR_RESET}"
    echo -e "  Expected: ${COLOR_YELLOW}$expected${COLOR_RESET}"
    echo -e "  Actual:   ${COLOR_YELLOW}$result${COLOR_RESET}"
  fi
}

# Test Scenario 1: Basic Monitoring
test_basic_monitoring() {
  echo -e "\n${COLOR_BOLD}${COLOR_BLUE}=== Scenario 1: Basic Monitoring ===${COLOR_RESET}"
  local scenario_dir="${RESULTS_DIR}/basic_monitoring"
  mkdir -p "$scenario_dir"
  
  # Run Maven tests with monitoring
  echo -e "${COLOR_CYAN}Running Maven tests with basic monitoring...${COLOR_RESET}"
  
  # If we're not in a Maven project directory, use the test project
  if [ ! -f "pom.xml" ]; then
    cd "${TEST_PROJECT}" || {
      echo -e "${COLOR_RED}Error: Could not change to test project directory${COLOR_RESET}"
      return 1
    }
  fi
  
  # Run the monitoring for a short time (30 seconds max)
  "${ROOT_DIR}/src/lib/mvnimble.sh" --monitor 1 --time 1 --directory "$scenario_dir"
  
  # Validate results
  if [ -f "${scenario_dir}/test_monitoring_report.md" ]; then
    log_validation "BASIC_REPORT" "exists" "exists" 1 1 "Monitoring report was generated"
  else
    log_validation "BASIC_REPORT" "missing" "exists" 0 1 "Monitoring report was not generated"
  fi
  
  # Check for system metrics
  if [ -f "${scenario_dir}/metrics/system.csv" ]; then
    local metrics_count=$(wc -l < "${scenario_dir}/metrics/system.csv")
    if [ "$metrics_count" -gt 1 ]; then
      log_validation "SYSTEM_METRICS" "$metrics_count" ">1" 1 1 "System metrics were collected"
    else
      log_validation "SYSTEM_METRICS" "$metrics_count" ">1" 0 1 "No system metrics were collected"
    fi
  else
    log_validation "SYSTEM_METRICS" "missing" "exists" 0 1 "System metrics file was not created"
  fi
  
  # Check for resource graphs or data
  if grep -q "## Resource Utilization" "${scenario_dir}/test_monitoring_report.md"; then
    log_validation "RESOURCE_SECTION" "exists" "exists" 1 1 "Resource utilization section exists in report"
  else
    log_validation "RESOURCE_SECTION" "missing" "exists" 0 1 "Resource utilization section missing from report"
  fi
}

# Test Scenario 2: Resource Correlation
test_resource_correlation() {
  echo -e "\n${COLOR_BOLD}${COLOR_BLUE}=== Scenario 2: Resource Correlation ===${COLOR_RESET}"
  local scenario_dir="${RESULTS_DIR}/resource_correlation"
  mkdir -p "$scenario_dir"
  
  # Run Maven tests with monitoring and resource correlation
  echo -e "${COLOR_CYAN}Running Maven tests with resource correlation analysis...${COLOR_RESET}"
  
  # If we're not in a Maven project directory, use the test project
  if [ ! -f "pom.xml" ]; then
    cd "${TEST_PROJECT}" || {
      echo -e "${COLOR_RED}Error: Could not change to test project directory${COLOR_RESET}"
      return 1
    }
  fi
  
  # Run the monitoring with flakiness analysis
  "${ROOT_DIR}/src/lib/mvnimble.sh" --monitor 1 --time 1 --flaky-analysis --directory "$scenario_dir"
  
  # Validate results
  if [ -f "${scenario_dir}/resource_correlation.md" ]; then
    log_validation "CORRELATION_REPORT" "exists" "exists" 1 1 "Resource correlation report was generated"
  else
    log_validation "CORRELATION_REPORT" "missing" "exists" 0 1 "Resource correlation report was not generated"
  fi
  
  # Check for correlation analysis
  if [ -f "${scenario_dir}/resource_correlation.md" ]; then
    if grep -q "## Analysis and Recommendations" "${scenario_dir}/resource_correlation.md"; then
      log_validation "CORRELATION_ANALYSIS" "exists" "exists" 1 1 "Correlation analysis section exists"
    else
      log_validation "CORRELATION_ANALYSIS" "missing" "exists" 0 1 "Correlation analysis section missing"
    fi
  fi
}

# Test Scenario 3: Flakiness Detection
test_flakiness_detection() {
  echo -e "\n${COLOR_BOLD}${COLOR_BLUE}=== Scenario 3: Flakiness Detection ===${COLOR_RESET}"
  local scenario_dir="${RESULTS_DIR}/flakiness_detection"
  mkdir -p "$scenario_dir"
  
  # For this test, we need to simulate some flaky tests
  # We'll do this by creating a simulated test history file
  local test_metrics="${scenario_dir}/metrics"
  mkdir -p "$test_metrics"
  
  # Create a simulated tests.csv file with flaky test patterns
  cat > "${test_metrics}/tests.csv" <<EOT
timestamp,test_name,duration,result,thread_id
1620000001,com.example.TestA,2.5,SUCCESS,thread-1
1620000002,com.example.TestB,1.5,FAILURE,thread-2
1620000003,com.example.TestC,3.0,SUCCESS,thread-1
1620000004,com.example.TestB,1.6,SUCCESS,thread-1
1620000005,com.example.TestD,4.2,SUCCESS,thread-3
1620000006,com.example.TestB,1.4,FAILURE,thread-2
1620000007,com.example.TestE,0.9,SUCCESS,thread-1
1620000008,com.example.TestB,1.7,SUCCESS,thread-3
1620000009,com.example.TestF,2.2,FAILURE,thread-2
1620000010,com.example.TestB,1.5,FAILURE,thread-2
EOT

  # Create a simulated system.csv file
  cat > "${test_metrics}/system.csv" <<EOT
timestamp,cpu_usage,memory_usage,disk_io,network_io,test_count,test_failures,active_threads
1620000001,15,1024,100,200,1,0,3
1620000002,25,1100,120,210,2,1,3
1620000003,20,1150,130,220,3,1,3
1620000004,30,1200,140,230,4,1,3
1620000005,45,1300,150,240,5,1,3
1620000006,40,1250,160,250,6,2,3
1620000007,35,1200,170,260,7,2,3
1620000008,30,1150,180,270,8,2,3
1620000009,25,1100,190,280,9,3,3
1620000010,20,1050,200,290,10,4,3
EOT

  # Now run the flakiness analysis on our simulated data
  cd "${ROOT_DIR}" || return
  # Run the source directly since we're not running a real test
  source "${ROOT_DIR}/src/lib/modules/real_time_analyzer.sh"
  identify_flakiness_patterns "$scenario_dir"
  
  # Validate results
  if [ -f "${scenario_dir}/flakiness_analysis.md" ]; then
    log_validation "FLAKINESS_REPORT" "exists" "exists" 1 1 "Flakiness analysis report was generated"
  else
    log_validation "FLAKINESS_REPORT" "missing" "exists" 0 1 "Flakiness analysis report was not generated"
  fi
  
  # Check if TestB was identified as flaky
  if [ -f "${scenario_dir}/flakiness_analysis.md" ]; then
    if grep -q "TestB" "${scenario_dir}/flakiness_analysis.md"; then
      log_validation "FLAKY_TEST_DETECTION" "detected" "detected" 1 1 "Correctly identified TestB as flaky"
    else
      log_validation "FLAKY_TEST_DETECTION" "not detected" "detected" 0 1 "Failed to identify TestB as flaky"
    fi
  fi
}

# Test Scenario 4: Cross-platform Compatibility
test_cross_platform() {
  echo -e "\n${COLOR_BOLD}${COLOR_BLUE}=== Scenario 4: Cross-platform Compatibility ===${COLOR_RESET}"
  local scenario_dir="${RESULTS_DIR}/cross_platform"
  mkdir -p "$scenario_dir"
  
  # Get platform information
  local os_type=$(uname)
  echo -e "Testing compatibility on ${COLOR_CYAN}$os_type${COLOR_RESET}"
  
  # Run platform-specific test
  # Here we're just checking that the monitoring functions work on this platform
  source "${ROOT_DIR}/src/lib/modules/real_time_analyzer.sh"
  
  local platform_success=false
  
  # Create a temp test directory
  mkdir -p "${scenario_dir}/metrics"
  touch "${scenario_dir}/metrics/system.csv"
  
  # Try to capture system metrics for this platform
  if capture_system_metrics "${scenario_dir}/metrics/system.csv" "$$"; then
    if [ -s "${scenario_dir}/metrics/system.csv" ]; then
      platform_success=true
    fi
  fi
  
  if $platform_success; then
    log_validation "PLATFORM_SUPPORT" "$os_type" "$os_type" 1 1 "Monitoring functions work on $os_type"
  else
    log_validation "PLATFORM_SUPPORT" "unsupported" "$os_type" 0 1 "Monitoring functions don't work on $os_type"
  fi
}

# Run all validation tests or a specific one
run_validation() {
  local scenario="${1:-all}"
  local validation_start=$(date +%s)
  
  # Clean up previous results
  rm -f "${RESULTS_DIR}/validation_results.log"
  echo "MVNimble Real-time Monitoring Validation" > "${RESULTS_DIR}/validation_results.log"
  echo "=======================================" >> "${RESULTS_DIR}/validation_results.log"
  echo "Date: $(date)" >> "${RESULTS_DIR}/validation_results.log"
  echo "" >> "${RESULTS_DIR}/validation_results.log"
  
  # Intro message
  echo -e "${COLOR_BOLD}${COLOR_BLUE}Running MVNimble Real-time Monitoring Validation${COLOR_RESET}"
  echo -e "Results will be saved to: ${COLOR_BOLD}${RESULTS_DIR}${COLOR_RESET}"
  
  # Run selected test scenarios
  case "$scenario" in
    "basic")
      test_basic_monitoring
      ;;
    "correlation")
      test_resource_correlation
      ;;
    "flakiness")
      test_flakiness_detection
      ;;
    "platform")
      test_cross_platform
      ;;
    "all"|"")
      test_basic_monitoring
      test_resource_correlation
      test_flakiness_detection
      test_cross_platform
      ;;
    *)
      echo -e "${COLOR_RED}Error: Invalid scenario '$scenario'${COLOR_RESET}"
      echo "Available scenarios: basic, correlation, flakiness, platform, all"
      return 1
      ;;
  esac
  
  # Calculate overall score
  local percentage=0
  if [ "$TOTAL_VALIDATIONS" -gt 0 ]; then
    percentage=$((VALIDATION_SCORE * 100 / TOTAL_VALIDATIONS))
  fi
  
  # Log final results
  echo "" >> "${RESULTS_DIR}/validation_results.log"
  echo "Overall Validation Score: $VALIDATION_SCORE/$TOTAL_VALIDATIONS ($percentage%)" >> "${RESULTS_DIR}/validation_results.log"
  
  local validation_end=$(date +%s)
  local validation_duration=$((validation_end - validation_start))
  echo "Validation Duration: ${validation_duration}s" >> "${RESULTS_DIR}/validation_results.log"
  
  # Print summary
  echo -e "\n${COLOR_BOLD}${COLOR_BLUE}Validation Results Summary${COLOR_RESET}"
  echo -e "Tested scenarios: $scenario"
  if [ "$percentage" -ge 90 ]; then
    echo -e "${COLOR_GREEN}Overall Validation Score: $VALIDATION_SCORE/$TOTAL_VALIDATIONS ($percentage%)${COLOR_RESET}"
  elif [ "$percentage" -ge 75 ]; then
    echo -e "${COLOR_YELLOW}Overall Validation Score: $VALIDATION_SCORE/$TOTAL_VALIDATIONS ($percentage%)${COLOR_RESET}"
  else
    echo -e "${COLOR_RED}Overall Validation Score: $VALIDATION_SCORE/$TOTAL_VALIDATIONS ($percentage%)${COLOR_RESET}"
  fi
  
  echo -e "Detailed results saved to: ${COLOR_BOLD}${RESULTS_DIR}/validation_results.log${COLOR_RESET}"
}

# Main function
main() {
  local scenario="${1:-all}"
  run_validation "$scenario"
}

# Execute main if script is not being sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi