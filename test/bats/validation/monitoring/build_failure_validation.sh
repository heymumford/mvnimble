#!/usr/bin/env bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# build_failure_validation.sh
# Validation tests for MVNimble's build failure analysis capabilities
#
# This script validates the build failure analysis functionality
# through various test scenarios.
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
RESULTS_DIR="${ROOT_DIR}/results/validation/build_failure"
mkdir -p "${RESULTS_DIR}"

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

# Create test Maven errors
create_test_maven_errors() {
  local error_file="$1"
  
  cat > "$error_file" << EOF
[INFO] Scanning for projects...
[INFO] 
[INFO] ----------------------< io.checkvox:CheckvoxApp >-----------------------
[INFO] Building Checkvox 0.1.0-SNAPSHOT
[INFO]   from pom.xml
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- enforcer:3.3.0:enforce (enforce) @ CheckvoxApp ---
[INFO] Rule 0: org.apache.maven.enforcer.rules.version.RequireMavenVersion passed
[INFO] Rule 1: org.apache.maven.enforcer.rules.version.RequireJavaVersion passed
[ERROR] /Users/vorthruna/Code/Checkvox/src/test/java/io/checkvox/domain/converter/ContextTypeConverterTest.java:[15,34] package io.checkvox.test.dimension does not exist
[ERROR] /Users/vorthruna/Code/Checkvox/src/test/java/io/checkvox/domain/converter/ContextTypeConverterTest.java:[16,34] package io.checkvox.test.dimension does not exist
[ERROR] /Users/vorthruna/Code/Checkvox/src/test/java/io/checkvox/domain/entity/DomainContextClassifierPropertyBasedTest.java:[17,32] package net.jqwik.api.statistics does not exist
[ERROR] /Users/vorthruna/Code/Checkvox/src/test/java/io/checkvox/domain/entity/DomainContextClassifierComprehensiveTest.java:[341,32] planningApproach has private access in io.checkvox.domain.entity.DomainContextClassifier.ProcessTemplate
[ERROR] /Users/vorthruna/Code/Checkvox/src/test/java/io/checkvox/domain/entity/DomainContextClassifierIntegrationTest.java:[98,37] incompatible types: java.util.List<io.checkvox.domain.entity.Tag> cannot be converted to java.util.Set<io.checkvox.domain.entity.Tag>
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  4.482 s
[INFO] Finished at: 2025-05-04T09:44:33-04:00
[INFO] ------------------------------------------------------------------------
EOF
}

# Create test metrics
create_test_metrics() {
  local metrics_dir="$1"
  
  mkdir -p "$metrics_dir"
  
  # Create system metrics
  cat > "${metrics_dir}/system.csv" << EOF
timestamp,cpu_usage,memory_usage,disk_io,network_io,test_count,test_failures,active_threads
1620000001,6.73,5644,0,0,194,43,30
1620000002,15.8,5800,10,5,194,43,32
1620000003,25.4,6100,15,10,194,43,35
EOF

  # Create JVM metrics
  cat > "${metrics_dir}/jvm.csv" << EOF
timestamp,heap_used,heap_committed,heap_max,non_heap_used,gc_count,gc_time,loaded_classes
1620000001,1024,2048,4096,512,5,120,1500
1620000002,1536,2048,4096,600,8,250,1600
1620000003,1800,2048,4096,650,12,350,1700
EOF
}

# Test Scenario 1: Basic Error Detection
test_basic_error_detection() {
  echo -e "\n${COLOR_BOLD}${COLOR_BLUE}=== Scenario 1: Basic Error Detection ===${COLOR_RESET}"
  local scenario_dir="${RESULTS_DIR}/basic_detection"
  mkdir -p "$scenario_dir"
  
  # Create test files
  create_test_maven_errors "${scenario_dir}/maven_output.log"
  create_test_metrics "${scenario_dir}/metrics"
  
  # Source the module
  source "${ROOT_DIR}/src/lib/modules/real_time_analyzer.sh"
  
  # Run the analysis
  analyze_build_failure "${scenario_dir}/maven_output.log" "${scenario_dir}/metrics" "${scenario_dir}/build_analysis.md"
  
  # Validate results
  if [ -f "${scenario_dir}/build_analysis.md" ]; then
    log_validation "ANALYSIS_REPORT" "exists" "exists" 1 1 "Build analysis report was generated"
  else
    log_validation "ANALYSIS_REPORT" "missing" "exists" 0 1 "Build analysis report was not generated"
  fi
  
  # Check for error detection
  if grep -q "Total Errors: 5" "${scenario_dir}/build_analysis.md"; then
    log_validation "ERROR_COUNT" "5" "5" 1 1 "Correctly identified 5 errors"
  else
    error_count=$(grep -o "Total Errors: [0-9]*" "${scenario_dir}/build_analysis.md" | grep -o "[0-9]*")
    log_validation "ERROR_COUNT" "$error_count" "5" 0 1 "Failed to identify correct number of errors"
  fi
  
  # Check for missing packages detection
  if grep -q "Missing Package Dependencies: 3" "${scenario_dir}/build_analysis.md"; then
    log_validation "MISSING_PACKAGES" "3" "3" 1 1 "Correctly identified 3 missing package errors"
  else
    missing_packages=$(grep -o "Missing Package Dependencies: [0-9]*" "${scenario_dir}/build_analysis.md" | grep -o "[0-9]*")
    log_validation "MISSING_PACKAGES" "$missing_packages" "3" 0 1 "Failed to identify correct number of missing packages"
  fi
}

# Test Scenario 2: Resource Usage Correlation
test_resource_correlation() {
  echo -e "\n${COLOR_BOLD}${COLOR_BLUE}=== Scenario 2: Resource Usage Correlation ===${COLOR_RESET}"
  local scenario_dir="${RESULTS_DIR}/resource_correlation"
  mkdir -p "$scenario_dir"
  
  # Create test files with high resource usage
  create_test_maven_errors "${scenario_dir}/maven_output.log"
  
  # Create metrics directory
  mkdir -p "${scenario_dir}/metrics"
  
  # Create system metrics with a memory spike
  cat > "${scenario_dir}/metrics/system.csv" << EOF
timestamp,cpu_usage,memory_usage,disk_io,network_io,test_count,test_failures,active_threads
1620000001,25.5,1024,100,200,0,0,10
1620000002,35.8,2048,150,220,0,0,12
1620000003,85.2,8192,200,240,0,0,25
1620000004,30.1,2560,180,230,0,0,13
EOF
  
  # Source the module
  source "${ROOT_DIR}/src/lib/modules/real_time_analyzer.sh"
  
  # Run the analysis
  analyze_build_failure "${scenario_dir}/maven_output.log" "${scenario_dir}/metrics" "${scenario_dir}/build_analysis.md"
  
  # Validate results
  if grep -q "Peak CPU Usage: 85.2%" "${scenario_dir}/build_analysis.md"; then
    log_validation "PEAK_CPU" "85.2%" "85.2%" 1 1 "Correctly identified peak CPU usage"
  else
    peak_cpu=$(grep -o "Peak CPU Usage: [0-9.]*%" "${scenario_dir}/build_analysis.md" | grep -o "[0-9.]*")
    log_validation "PEAK_CPU" "${peak_cpu}%" "85.2%" 0 1 "Failed to identify correct peak CPU usage"
  fi
  
  if grep -q "Peak Memory Usage: 8192MB" "${scenario_dir}/build_analysis.md"; then
    log_validation "PEAK_MEMORY" "8192MB" "8192MB" 1 1 "Correctly identified peak memory usage"
  else
    peak_memory=$(grep -o "Peak Memory Usage: [0-9]*MB" "${scenario_dir}/build_analysis.md" | grep -o "[0-9]*")
    log_validation "PEAK_MEMORY" "${peak_memory}MB" "8192MB" 0 1 "Failed to identify correct peak memory usage"
  fi
}

# Test Scenario 3: Command Line Integration
test_command_line_integration() {
  echo -e "\n${COLOR_BOLD}${COLOR_BLUE}=== Scenario 3: Command Line Integration ===${COLOR_RESET}"
  local scenario_dir="${RESULTS_DIR}/command_line"
  mkdir -p "$scenario_dir"
  
  # Check for build-analysis option in mvnimble.sh
  if grep -q "\-b|\-\-build-analysis)" "${ROOT_DIR}/src/lib/mvnimble.sh"; then
    log_validation "CLI_OPTION" "exists" "exists" 1 1 "Command line option for build analysis exists"
  else
    log_validation "CLI_OPTION" "missing" "exists" 0 1 "Command line option for build analysis is missing"
  fi
  
  # Check for build_analysis variable
  if grep -q "build_analysis=false" "${ROOT_DIR}/src/lib/mvnimble.sh"; then
    log_validation "CLI_VARIABLE" "exists" "exists" 1 1 "build_analysis variable is defined"
  else
    log_validation "CLI_VARIABLE" "missing" "exists" 0 1 "build_analysis variable is missing"
  fi
  
  # Check for function call in the main script
  if grep -q "analyze_build_failure" "${ROOT_DIR}/src/lib/mvnimble.sh"; then
    log_validation "FUNCTION_CALL" "exists" "exists" 1 1 "analyze_build_failure is called in main script"
  else
    log_validation "FUNCTION_CALL" "missing" "exists" 0 1 "analyze_build_failure call is missing in main script"
  fi
}

# Test Scenario 4: Recommendations
test_recommendations() {
  echo -e "\n${COLOR_BOLD}${COLOR_BLUE}=== Scenario 4: Build Recommendations ===${COLOR_RESET}"
  local scenario_dir="${RESULTS_DIR}/recommendations"
  mkdir -p "$scenario_dir"
  
  # Create test files
  create_test_maven_errors "${scenario_dir}/maven_output.log"
  create_test_metrics "${scenario_dir}/metrics"
  
  # Source the module
  source "${ROOT_DIR}/src/lib/modules/real_time_analyzer.sh"
  
  # Run recommendations
  generate_build_recommendations "${scenario_dir}/maven_output.log" "${scenario_dir}/metrics" "${scenario_dir}/recommendations.md"
  
  # Check if function returns success
  if [ $? -eq 0 ]; then
    log_validation "RECOMMENDATIONS_FUNCTION" "success" "success" 1 1 "Recommendations function returns success"
  else
    log_validation "RECOMMENDATIONS_FUNCTION" "failure" "success" 0 1 "Recommendations function failed"
  fi
}

# Run all validation tests or a specific one
run_validation() {
  local scenario="${1:-all}"
  local validation_start=$(date +%s)
  
  # Clean up previous results
  rm -f "${RESULTS_DIR}/validation_results.log"
  echo "MVNimble Build Failure Analysis Validation" > "${RESULTS_DIR}/validation_results.log"
  echo "==========================================" >> "${RESULTS_DIR}/validation_results.log"
  echo "Date: $(date)" >> "${RESULTS_DIR}/validation_results.log"
  echo "" >> "${RESULTS_DIR}/validation_results.log"
  
  # Intro message
  echo -e "${COLOR_BOLD}${COLOR_BLUE}Running MVNimble Build Failure Analysis Validation${COLOR_RESET}"
  echo -e "Results will be saved to: ${COLOR_BOLD}${RESULTS_DIR}${COLOR_RESET}"
  
  # Run selected test scenarios
  case "$scenario" in
    "detection")
      test_basic_error_detection
      ;;
    "resources")
      test_resource_correlation
      ;;
    "cli")
      test_command_line_integration
      ;;
    "recommendations")
      test_recommendations
      ;;
    "all"|"")
      test_basic_error_detection
      test_resource_correlation
      test_command_line_integration
      test_recommendations
      ;;
    *)
      echo -e "${COLOR_RED}Error: Invalid scenario '$scenario'${COLOR_RESET}"
      echo "Available scenarios: detection, resources, cli, recommendations, all"
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
  
  return 0
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