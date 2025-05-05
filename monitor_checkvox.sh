#!/usr/bin/env bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# Monitor Checkvox Test Execution
# This script runs MVNimble real-time monitoring on the Checkvox project

# Set the Checkvox project directory
CHECKVOX_DIR="/Users/vorthruna/Code/checkvox"
MVNIMBLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="${MVNIMBLE_DIR}/results/checkvox"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
RESET='\033[0m'

# Create results directory
mkdir -p "${RESULTS_DIR}"

echo -e "${BOLD}${BLUE}MVNimble Test Engineering Tricorder${RESET}"
echo -e "${BLUE}Running real-time monitoring on Checkvox project${RESET}"
echo -e "Checkvox location: ${CHECKVOX_DIR}"
echo -e "Results directory: ${RESULTS_DIR}"
echo ""

# First, let's start the monitoring in the background
(
  cd "${CHECKVOX_DIR}" || {
    echo -e "${RED}Error: Could not change to Checkvox directory${RESET}"
    exit 1
  }
  
  # Source the real-time analyzer directly
  source "${MVNIMBLE_DIR}/src/lib/modules/constants.sh"
  source "${MVNIMBLE_DIR}/src/lib/modules/common.sh"
  source "${MVNIMBLE_DIR}/src/lib/modules/environment_detection.sh"
  source "${MVNIMBLE_DIR}/src/lib/modules/platform_compatibility.sh"
  source "${MVNIMBLE_DIR}/src/lib/modules/test_analysis.sh"
  source "${MVNIMBLE_DIR}/src/lib/modules/real_time_analyzer.sh"
  
  # Start monitoring with 2-second interval for 15 minutes max
  start_real_time_monitoring "${RESULTS_DIR}" 2 900
) &
MONITOR_PID=$!

# Give the monitoring a moment to start
sleep 2

# Now run the Checkvox tests
echo -e "${BOLD}${GREEN}Starting Checkvox test execution...${RESET}"
(
  cd "${CHECKVOX_DIR}" || {
    echo -e "${RED}Error: Could not change to Checkvox directory${RESET}"
    exit 1
  }
  
  # Run Maven tests
  # We'll use a subset of tests to keep it manageable
  mvn test -DforkCount=1 -Dgroups="UnitTest" -DexcludedGroups="SlowTest,IntegrationTest,PerformanceTest" > "${RESULTS_DIR}/maven_output.log"
  TEST_STATUS=$?
  
  if [ $TEST_STATUS -eq 0 ]; then
    echo -e "${GREEN}Checkvox tests completed successfully${RESET}"
  else
    echo -e "${RED}Checkvox tests failed with status $TEST_STATUS${RESET}"
  fi
  
  # Signal monitoring to stop
  rm -f "${RESULTS_DIR}/monitoring.pid"
)

# Wait for monitoring to complete
wait $MONITOR_PID

# Run flakiness analysis
echo -e "\n${BOLD}${BLUE}Running flakiness analysis...${RESET}"
(
  cd "${CHECKVOX_DIR}" || exit 1
  source "${MVNIMBLE_DIR}/src/lib/modules/constants.sh"
  source "${MVNIMBLE_DIR}/src/lib/modules/real_time_analyzer.sh"
  identify_flakiness_patterns "${RESULTS_DIR}"
  generate_resource_correlation "${RESULTS_DIR}"
)

# Run build failure analysis
echo -e "\n${BOLD}${BLUE}Running build failure analysis...${RESET}"
(
  cd "${CHECKVOX_DIR}" || {
    echo -e "${RED}Error: Could not change to Checkvox directory${RESET}"
    exit 1
  }
  
  source "${MVNIMBLE_DIR}/src/lib/modules/constants.sh"
  source "${MVNIMBLE_DIR}/src/lib/modules/real_time_analyzer.sh"
  
  # Check if maven output log exists
  if [ ! -f "${RESULTS_DIR}/maven_output.log" ]; then
    echo -e "${YELLOW}Warning: Maven output log not found. Cannot analyze build failure.${RESET}"
    exit 0
  fi
  
  # Check if metrics directory exists
  if [ ! -d "${RESULTS_DIR}/metrics" ]; then
    echo -e "${YELLOW}Warning: Metrics directory not found. Cannot analyze resource usage.${RESET}"
    mkdir -p "${RESULTS_DIR}/metrics"
  fi
  
  # Run analysis
  echo -e "${GREEN}Analyzing build output from: ${RESULTS_DIR}/maven_output.log${RESET}"
  if analyze_build_failure "${RESULTS_DIR}/maven_output.log" "${RESULTS_DIR}/metrics" "${RESULTS_DIR}/build_failure_analysis.md"; then
    echo -e "${GREEN}Build failure analysis completed successfully${RESET}"
  else
    echo -e "${RED}Build failure analysis failed${RESET}"
  fi
  
  # Generate recommendations
  echo -e "${GREEN}Generating build recommendations...${RESET}"
  if generate_build_recommendations "${RESULTS_DIR}/maven_output.log" "${RESULTS_DIR}/metrics" "${RESULTS_DIR}/build_recommendations.md"; then
    echo -e "${GREEN}Build recommendations generated successfully${RESET}"
  else
    echo -e "${RED}Failed to generate build recommendations${RESET}"
  fi
)

echo -e "\n${BOLD}${GREEN}Monitoring and analysis complete${RESET}"
echo -e "Results available in: ${RESULTS_DIR}"
echo -e "Report files:"
echo -e "  - ${RESULTS_DIR}/test_monitoring_report.md"
echo -e "  - ${RESULTS_DIR}/flakiness_analysis.md (if flaky tests detected)"
echo -e "  - ${RESULTS_DIR}/resource_correlation.md"
echo -e "  - ${RESULTS_DIR}/build_failure_analysis.md"
echo -e "  - ${RESULTS_DIR}/build_recommendations.md"