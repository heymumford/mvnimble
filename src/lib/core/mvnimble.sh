#!/usr/bin/env bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# mvnimble.sh - Main entry point for MVNimble
#
# This script provides Maven test optimization functionality.
#
# Author: MVNimble Team
# Version: 1.0.0

# Define the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Import modules
source "${SCRIPT_DIR}/modules/constants.sh"
source "${SCRIPT_DIR}/modules/common.sh"
source "${SCRIPT_DIR}/modules/dependency_check.sh"
source "${SCRIPT_DIR}/modules/environment_unified.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/modules/platform_compatibility.sh"
source "${SCRIPT_DIR}/modules/test_analysis.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/modules/reporting.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/modules/real_time_analyzer.sh" 2>/dev/null || true

# Display usage information
function show_usage() {
  cat <<EOT
Usage: mvnimble [options]

MVNimble ${MVNIMBLE_VERSION} - Maven test optimization utility

Options:
  -h, --help                 Show this help message and exit
  -o, --optimize             Run optimization analysis on Maven tests
  -m, --monitor [INTERVAL]   Enable real-time test monitoring (with optional interval in seconds)
  -d, --directory DIR        Specify result directory (default: ${DEFAULT_REPORT_DIR})
  -t, --time DURATION        Maximum monitoring duration in minutes (default: 60)
  -f, --flaky-analysis       Run flakiness analysis after monitoring
  -b, --build-analysis       Enable build failure analysis
  -v, --version              Display version information and exit

Examples:
  mvnimble --monitor         Start real-time monitoring with default settings
  mvnimble -m 10 -d ./results  Monitor with 10s interval, save to ./results
  mvnimble -m -t 30          Monitor for maximum 30 minutes
  mvnimble -m -b             Monitor with build failure analysis
  mvnimble -o                Run optimization analysis only
EOT
}

# Main function
function main() {
  local monitor_mode=false
  local optimize_mode=false
  local flaky_analysis=false
  local build_analysis=false
  local result_dir="${DEFAULT_REPORT_DIR}"
  local monitor_interval=5
  local max_duration=60 # minutes
  
  echo "MVNimble ${MVNIMBLE_VERSION}"
  echo "Maven test optimization utility"
  
  # Parse command line arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        show_usage
        return ${EXIT_SUCCESS}
        ;;
      -v|--version)
        echo "MVNimble version ${MVNIMBLE_VERSION} (${MVNIMBLE_BUILD_DATE})"
        return ${EXIT_SUCCESS}
        ;;
      -m|--monitor)
        monitor_mode=true
        shift
        # Check if next argument is a number (interval)
        if [[ $# -gt 0 ]] && [[ "$1" =~ ^[0-9]+$ ]]; then
          monitor_interval="$1"
          shift
        fi
        ;;
      -o|--optimize)
        optimize_mode=true
        shift
        ;;
      -d|--directory)
        if [[ $# -lt 2 ]]; then
          echo -e "${COLOR_RED}Error: --directory requires a path argument${COLOR_RESET}"
          return ${EXIT_VALIDATION_ERROR}
        fi
        result_dir="$2"
        shift 2
        ;;
      -t|--time)
        if [[ $# -lt 2 ]]; then
          echo -e "${COLOR_RED}Error: --time requires a duration argument${COLOR_RESET}"
          return ${EXIT_VALIDATION_ERROR}
        fi
        max_duration="$2"
        shift 2
        ;;
      -f|--flaky-analysis)
        flaky_analysis=true
        shift
        ;;
      -b|--build-analysis)
        build_analysis=true
        shift
        ;;
      *)
        echo -e "${COLOR_RED}Error: Unknown option $1${COLOR_RESET}"
        show_usage
        return ${EXIT_VALIDATION_ERROR}
        ;;
    esac
  done
  
  # Create results directory if it doesn't exist
  mkdir -p "${result_dir}"
  
  # Check for valid Maven project
  if [ ! -f "pom.xml" ]; then
    echo -e "${COLOR_RED}Error: No pom.xml found in current directory${COLOR_RESET}"
    echo "MVNimble must be run from the root of a Maven project"
    return ${EXIT_VALIDATION_ERROR}
  fi
  
  # Execute selected mode
  if [ "$monitor_mode" = true ]; then
    echo -e "${COLOR_BOLD}${COLOR_BLUE}Starting real-time test monitoring...${COLOR_RESET}"
    # Convert minutes to seconds for max_duration
    local max_seconds=$((max_duration * 60))
    start_real_time_monitoring "${result_dir}" "${monitor_interval}" "${max_seconds}"
    
    # Run flakiness analysis if requested
    if [ "$flaky_analysis" = true ]; then
      identify_flakiness_patterns "${result_dir}"
      generate_resource_correlation "${result_dir}"
    fi
    
    # Run build failure analysis if requested
    if [ "$build_analysis" = true ]; then
      # Check if maven_output.log exists for analysis
      if [ -f "${result_dir}/maven_output.log" ]; then
        analyze_build_failure "${result_dir}/maven_output.log" "${result_dir}/metrics" "${result_dir}/build_failure_analysis.md"
        generate_build_recommendations "${result_dir}/maven_output.log" "${result_dir}/metrics" "${result_dir}/build_recommendations.md"
      else
        echo -e "${COLOR_YELLOW}No Maven output log found for build analysis.${COLOR_RESET}"
        echo -e "To enable build analysis, redirect Maven output to ${result_dir}/maven_output.log"
      fi
    fi
  elif [ "$optimize_mode" = true ]; then
    echo -e "${COLOR_BOLD}${COLOR_BLUE}Running optimization analysis...${COLOR_RESET}"
    # Call optimization functionality here
    echo -e "${COLOR_YELLOW}Optimization analysis not yet implemented${COLOR_RESET}"
  else
    # If no mode specified, show usage
    show_usage
  fi
  
  return ${EXIT_SUCCESS}
}

# Execute main if script is not being sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi