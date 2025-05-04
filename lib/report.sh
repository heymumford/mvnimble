#!/usr/bin/env bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
#==============================================================================
# report.sh
#
# MVNimble - Reporting Module
#
# Description:
#   This module provides functionality for generating various types of reports
#   for Maven test execution, including markdown, HTML, and JSON formats.
#
# Usage:
#   source "path/to/report.sh"
#   generate_json_report "result_dir" "output_file"
#==============================================================================

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source required modules
if [[ -z "${CONSTANTS_LOADED+x}" ]]; then
  source "${SCRIPT_DIR}/constants.sh"
fi
source "${SCRIPT_DIR}/common.sh"

# Main report generation function
# Generates reports in different formats (markdown, html, json)
# Usage: generate_report <input_file> <output_file> <format>
function generate_report() {
  local input_file="$1"
  local output_file="$2"
  local format="$3"
  
  # Input file must exist
  if [[ ! -f "$input_file" ]]; then
    print_error "Input file not found: $input_file"
    return ${EXIT_FILE_ERROR}
  fi
  
  # Create output directory if it doesn't exist
  local output_dir=$(dirname "$output_file")
  if [[ ! -d "$output_dir" ]]; then
    mkdir -p "$output_dir"
    if [[ $? -ne 0 ]]; then
      print_error "Failed to create output directory: $output_dir"
      return ${EXIT_DIRECTORY_ERROR}
    fi
  fi
  
  # Detect input format
  local is_json=false
  if [[ "$input_file" == *".json" ]] || grep -q "^{" "$input_file"; then
    is_json=true
  fi
  
  # Process based on format
  case "$format" in
    json)
      if ! $is_json; then
        # Not a JSON file, need to convert
        local result_dir="$(dirname "$input_file")"
        generate_json_report "$result_dir" "$output_file"
      else
        # Already JSON, just copy
        cp "$input_file" "$output_file"
        print_success "JSON report generated: $output_file"
      fi
      ;;
    
    markdown|md)
      if $is_json; then
        # Input is JSON, generate markdown from it
        generate_markdown_report "$input_file" "$output_file"
      else
        # Input is not JSON, need to convert first
        local result_dir="$(dirname "$input_file")"
        local temp_json="/tmp/mvnimble_temp_$$.json"
        generate_json_report "$result_dir" "$temp_json"
        generate_markdown_report "$temp_json" "$output_file"
        rm -f "$temp_json"
      fi
      ;;
    
    html)
      if $is_json; then
        # Input is JSON, generate HTML from it
        generate_html_report "$(dirname "$input_file")" "$input_file" "$output_file"
      else
        # Input is not JSON, need to convert first
        local result_dir="$(dirname "$input_file")"
        local temp_json="/tmp/mvnimble_temp_$$.json"
        generate_json_report "$result_dir" "$temp_json"
        generate_html_report "$result_dir" "$temp_json" "$output_file"
        rm -f "$temp_json"
      fi
      ;;
    
    *)
      print_error "Unsupported format: $format (must be json, markdown, or html)"
      return ${EXIT_ARGUMENT_ERROR}
      ;;
  esac
  
  return ${EXIT_SUCCESS}
}

# Generate a JSON report from test results
function generate_json_report() {
  local result_dir="$1"
  local output_file="$2"
  
  # Create report directory if needed
  ensure_directory "$(dirname "$output_file")"
  
  # Calculate overall metrics
  local total_tests=0
  local passed_tests=0
  local failed_tests=0
  local skipped_tests=0
  local total_duration=0
  local failed_test_files=""
  
  # Process each result file
  for result_file in "${result_dir}"/*.result; do
    if [ -f "$result_file" ]; then
      local file_status=$(grep "status: " "$result_file" 2>/dev/null | cut -d' ' -f2)
      local file_passed=$(grep "passed: " "$result_file" 2>/dev/null | cut -d' ' -f2)
      local file_failed=$(grep "failed: " "$result_file" 2>/dev/null | cut -d' ' -f2)
      local file_skipped=$(grep "skipped: " "$result_file" 2>/dev/null | cut -d' ' -f2)
      local file_duration=$(grep "duration: " "$result_file" 2>/dev/null | cut -d' ' -f2)
      
      # Skip invalid files
      if [[ -z "$file_status" || -z "$file_passed" || -z "$file_failed" || -z "$file_skipped" || -z "$file_duration" ]]; then
        continue
      fi
      
      # Add to total counts
      total_tests=$((total_tests + file_passed + file_failed + file_skipped))
      passed_tests=$((passed_tests + file_passed))
      failed_tests=$((failed_tests + file_failed))
      skipped_tests=$((skipped_tests + file_skipped))
      total_duration=$(echo "$total_duration + $file_duration" | bc)
      
      # Add to failed test list if needed
      if [[ -n "$file_failed" && "$file_failed" != "0" ]]; then
        failed_test_files="${failed_test_files},\"$(basename "$result_file" .result)\""
      fi
    fi
  done
  
  # Remove leading comma if present
  if [[ -n "$failed_test_files" ]]; then
    failed_test_files=$(echo "$failed_test_files" | sed 's/^,//')
  fi
  
  # Generate JSON report
  {
    echo "{"
    echo "  \"timestamp\": \"$(date +%s)\","
    echo "  \"date\": \"$(date '+%Y-%m-%d %H:%M:%S')\","
    echo "  \"summary\": {"
    echo "    \"total\": $total_tests,"
    echo "    \"passed\": $passed_tests,"
    echo "    \"failed\": $failed_tests,"
    echo "    \"skipped\": $skipped_tests,"
    echo "    \"duration\": $total_duration"
    echo "  },"
    echo "  \"failed_tests\": [$failed_test_files],"
    
    # Add categories and tags here (simplified)
    echo "  \"categories\": {"
    echo "    \"functional\": 0,"
    echo "    \"nonfunctional\": 0,"
    echo "    \"positive\": 0,"
    echo "    \"negative\": 0"
    echo "  },"
    
    echo "  \"system\": {"
    echo "    \"os\": \"$(uname -s)\","
    echo "    \"cpu_cores\": $(get_cpu_cores),"
    echo "    \"memory_mb\": $(get_available_memory),"
    echo "    \"version\": \"${MVNIMBLE_VERSION}\""
    echo "  }"
    echo "}"
  } > "$output_file"
  
  print_success "JSON report generated: $output_file"
  return ${EXIT_SUCCESS}
}

# Generate a Markdown report
function generate_markdown_report() {
  local json_report="$1"
  local output_file="$2"
  
  # Skip if JSON report doesn't exist
  if [[ ! -f "$json_report" ]]; then
    print_error "JSON report not found: $json_report"
    return ${EXIT_FILE_ERROR}
  fi
  
  # Create report directory if needed
  ensure_directory "$(dirname "$output_file")"
  
  # Check if it's a build monitoring report or a test result report
  local is_build_report=false
  if grep -q '"build_status"' "$json_report"; then
    is_build_report=true
  fi
  
  # Set default values
  local timestamp=$(date +%s)
  local date=$(date '+%Y-%m-%d %H:%M:%S')
  local total_tests="0"
  local passed_tests="0"
  local failed_tests="0"
  local skipped_tests="0"
  local duration="0"
  local build_status=""
  local maven_command=""
  
  if [[ "$is_build_report" == "true" ]]; then
    # Parse build monitoring report
    local build_start=$(grep -o '"build_start": [0-9]*' "$json_report" | grep -o '[0-9]*')
    local build_end=$(grep -o '"build_end": [0-9]*' "$json_report" | grep -o '[0-9]*')
    duration=$(grep -o '"build_duration": [0-9.]*' "$json_report" | grep -o '[0-9.]*')
    build_status=$(grep -o '"build_status": "[^"]*"' "$json_report" | cut -d'"' -f4)
    maven_command=$(grep -o '"maven_command": "[^"]*"' "$json_report" | cut -d'"' -f4)
    
    # Convert timestamp to readable date if available
    if [[ -n "$build_start" ]]; then
      timestamp=$build_start
      date=$(date -r "$build_start" '+%Y-%m-%d %H:%M:%S')
    fi
    
    # Set test counts based on build status
    if [[ "$build_status" == "success" ]]; then
      passed_tests="1"
      total_tests="1"
    elif [[ "$build_status" == "failure" ]]; then
      failed_tests="1"
      total_tests="1"
    fi
  else
    # Parse test result report (original format)
    timestamp=$(grep -o '"timestamp": "[^"]*"' "$json_report" | cut -d'"' -f4)
    date=$(grep -o '"date": "[^"]*"' "$json_report" | cut -d'"' -f4)
    total_tests=$(grep -o '"total": [0-9]*' "$json_report" | grep -o '[0-9]*')
    passed_tests=$(grep -o '"passed": [0-9]*' "$json_report" | grep -o '[0-9]*')
    failed_tests=$(grep -o '"failed": [0-9]*' "$json_report" | grep -o '[0-9]*')
    skipped_tests=$(grep -o '"skipped": [0-9]*' "$json_report" | grep -o '[0-9]*')
    duration=$(grep -o '"duration": [0-9.]*' "$json_report" | grep -o '[0-9.]*')
  fi
  
  # Generate Markdown report
  {
    echo "# MVNimble Test Report"
    echo
    echo "Generated: $date"
    echo
    echo "## Summary"
    echo
    echo "* Total Tests: $total_tests"
    echo "* Passed: $passed_tests"
    echo "* Failed: $failed_tests"
    echo "* Skipped: $skipped_tests"
    echo "* Duration: $(printf "%.2f" $duration) seconds"
    echo
    
    # Add failed tests details
    if [[ -n "$failed_tests" && "$failed_tests" != "0" ]]; then
      echo "## Failed Tests"
      echo
      
      if [[ "$is_build_report" == "true" && "$build_status" == "failure" ]]; then
        echo "### Maven Build Failure"
        echo
        echo "The Maven build failed. Check the detailed build logs for more information."
        echo
      else
        # Extract failed tests from original format
        local failed_test_list=$(grep -o '"failed_tests": \[[^]]*\]' "$json_report" | sed 's/"failed_tests": \[\|\]//g' | sed 's/"//g' | sed 's/,/ /g')
        
        if [[ -n "$failed_test_list" ]]; then
          for failed_test in $failed_test_list; do
            echo "### $failed_test"
            echo
            # Optionally add detailed failure information if available
            echo
          done
        else
          echo "No detailed information available for failed tests."
          echo
        fi
      fi
    fi
    
    # Performance metrics
    echo "## Performance Metrics"
    echo
    echo "* Total Execution Time: $(printf "%.2f" $duration) seconds"
    
    if [ "$total_tests" -gt 0 ]; then
      echo "* Average Test Time: $(printf "%.4f" $(echo "$duration / $total_tests" | bc -l)) seconds"
    else
      echo "* Average Test Time: N/A (no tests executed)"
    fi
    echo
    
    # System information
    echo "## System Information"
    echo
    
    # Extract system data based on JSON format
    local os=""
    local cpu_cores=""
    local memory_mb=""
    local mvnimble_version="${MVNIMBLE_VERSION}"
    
    if [[ "$is_build_report" == "true" ]]; then
      # System section is nested in build report - use simpler grep to extract values
      os=$(grep -o '"os": "[^"]*"' "$json_report" | head -1 | cut -d'"' -f4)
      cpu_cores=$(grep -o '"cpu_cores": [0-9]*' "$json_report" | head -1 | grep -o '[0-9]*')
      memory_mb=$(grep -o '"memory_mb": [0-9]*' "$json_report" | head -1 | grep -o '[0-9]*')
    else
      # Original format with system data directly in JSON root
      os=$(grep -o '"os": "[^"]*"' "$json_report" | cut -d'"' -f4)
      cpu_cores=$(grep -o '"cpu_cores": [0-9]*' "$json_report" | grep -o '[0-9]*')
      memory_mb=$(grep -o '"memory_mb": [0-9]*' "$json_report" | grep -o '[0-9]*')
      mvnimble_version=$(grep -o '"version": "[^"]*"' "$json_report" | cut -d'"' -f4)
    fi
    
    echo "* OS: $os"
    echo "* CPU Cores: $cpu_cores"
    echo "* Available Memory: ${memory_mb}MB"
    echo "* MVNimble Version: $mvnimble_version"
    
    # Add build-specific information if available
    if [[ -n "$maven_command" ]]; then
      echo "* Maven Command: $maven_command"
    fi
    if [[ -n "$build_status" ]]; then
      echo "* Build Status: $build_status"
    fi
    
    echo
    echo "---"
    echo "Report generated by MVNimble Test Engineering Tricorder v${MVNIMBLE_VERSION}"
    echo
    echo "---"
    echo "Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license"
  } > "$output_file"
  
  print_success "Markdown report generated: $output_file"
  return ${EXIT_SUCCESS}
}

# Generate an HTML report
function generate_html_report() {
  local result_dir="$1"
  local json_report="$2"
  local output_file="$3"
  
  # Skip if JSON report doesn't exist
  if [[ ! -f "$json_report" ]]; then
    print_error "JSON report not found: $json_report"
    return ${EXIT_FILE_ERROR}
  fi
  
  # Create report directory if needed
  ensure_directory "$(dirname "$output_file")"
  
  # Parse JSON report data based on format
  # First, check if it's a build monitoring report or a test result report
  local is_build_report=false
  if grep -q '"build_status"' "$json_report"; then
    is_build_report=true
  fi
  
  # Set default values
  local date=$(date '+%Y-%m-%d %H:%M:%S')
  local total_tests="0"
  local passed_tests="0"
  local failed_tests="0"
  local skipped_tests="0"
  local duration="0"
  local build_status=""
  local maven_command=""
  
  if [[ "$is_build_report" == "true" ]]; then
    # Parse build monitoring report
    local build_start=$(grep -o '"build_start": [0-9]*' "$json_report" | grep -o '[0-9]*')
    local build_end=$(grep -o '"build_end": [0-9]*' "$json_report" | grep -o '[0-9]*')
    duration=$(grep -o '"build_duration": [0-9.]*' "$json_report" | grep -o '[0-9.]*')
    build_status=$(grep -o '"build_status": "[^"]*"' "$json_report" | cut -d'"' -f4)
    maven_command=$(grep -o '"maven_command": "[^"]*"' "$json_report" | cut -d'"' -f4)
    
    # Convert timestamp to readable date if available
    if [[ -n "$build_start" ]]; then
      date=$(date -r "$build_start" '+%Y-%m-%d %H:%M:%S')
    fi
    
    # Set test counts based on build status
    if [[ "$build_status" == "success" ]]; then
      passed_tests="1"
      total_tests="1"
    elif [[ "$build_status" == "failure" ]]; then
      failed_tests="1"
      total_tests="1"
    fi
  else
    # Parse test result report (original format)
    date=$(grep -o '"date": "[^"]*"' "$json_report" | cut -d'"' -f4)
    total_tests=$(grep -o '"total": [0-9]*' "$json_report" | grep -o '[0-9]*')
    passed_tests=$(grep -o '"passed": [0-9]*' "$json_report" | grep -o '[0-9]*')
    failed_tests=$(grep -o '"failed": [0-9]*' "$json_report" | grep -o '[0-9]*')
    skipped_tests=$(grep -o '"skipped": [0-9]*' "$json_report" | grep -o '[0-9]*')
    duration=$(grep -o '"duration": [0-9.]*' "$json_report" | grep -o '[0-9.]*')
  fi
  
  # Calculate pass rate (for chart)
  local pass_rate=0
  if [[ -n "$total_tests" && "$total_tests" != "0" ]]; then
    pass_rate=$(echo "scale=2; ($passed_tests * 100) / $total_tests" | bc)
  fi
  
  # Generate HTML report
  {
    echo "<!DOCTYPE html>"
    echo "<html lang=\"en\">"
    echo "<head>"
    echo "  <meta charset=\"UTF-8\">"
    echo "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"
    echo "  <title>MVNimble Test Report</title>"
    echo "  <style>"
    echo "    body { font-family: Arial, sans-serif; margin: 0; padding: 20px; color: #333; }"
    echo "    h1, h2 { color: #2c3e50; }"
    echo "    .container { max-width: 1200px; margin: 0 auto; }"
    echo "    .summary { display: flex; justify-content: space-between; margin-bottom: 30px; }"
    echo "    .summary-card { background: #f8f9fa; border-radius: 8px; padding: 15px; min-width: 150px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }"
    echo "    .passed { color: #27ae60; }"
    echo "    .failed { color: #e74c3c; }"
    echo "    .skipped { color: #f39c12; }"
    echo "    .big-number { font-size: 24px; font-weight: bold; margin: 10px 0; }"
    echo "    table { width: 100%; border-collapse: collapse; margin-bottom: 30px; }"
    echo "    th, td { text-align: left; padding: 12px; border-bottom: 1px solid #ddd; }"
    echo "    th { background-color: #f2f2f2; }"
    echo "    tr:hover { background-color: #f5f5f5; }"
    echo "    footer { margin-top: 50px; text-align: center; font-size: 12px; color: #7f8c8d; }"
    echo "  </style>"
    echo "</head>"
    echo "<body>"
    echo "  <div class=\"container\">"
    echo "    <h1>MVNimble Test Report</h1>"
    echo "    <p>Generated: $date</p>"
    echo ""
    echo "    <h2>Summary</h2>"
    echo "    <div class=\"summary\">"
    echo "      <div class=\"summary-card\">"
    echo "        <h3>Total Tests</h3>"
    echo "        <div class=\"big-number\">$total_tests</div>"
    echo "      </div>"
    echo "      <div class=\"summary-card\">"
    echo "        <h3>Passed</h3>"
    echo "        <div class=\"big-number passed\">$passed_tests</div>"
    echo "      </div>"
    echo "      <div class=\"summary-card\">"
    echo "        <h3>Failed</h3>"
    echo "        <div class=\"big-number failed\">$failed_tests</div>"
    echo "      </div>"
    echo "      <div class=\"summary-card\">"
    echo "        <h3>Skipped</h3>"
    echo "        <div class=\"big-number skipped\">$skipped_tests</div>"
    echo "      </div>"
    echo "      <div class=\"summary-card\">"
    echo "        <h3>Duration</h3>"
    echo "        <div class=\"big-number\">$(printf "%.2f" $duration)s</div>"
    echo "      </div>"
    echo "    </div>"
    
    # Add failed tests section
    if [[ -n "$failed_tests" && "$failed_tests" != "0" ]]; then
      echo "    <h2>Failed Tests</h2>"
      echo "    <table>"
      echo "      <tr>"
      echo "        <th>Test</th>"
      echo "        <th>Error</th>"
      echo "      </tr>"
      
      if [[ "$is_build_report" == "true" && "$build_status" == "failure" ]]; then
        echo "      <tr>"
        echo "        <td>Maven Build</td>"
        echo "        <td>The Maven build failed. Check the detailed build logs for more information.</td>"
        echo "      </tr>"
        
        # If we have maven command, show it
        if [[ -n "$maven_command" ]]; then
          echo "      <tr>"
          echo "        <td>Command</td>"
          echo "        <td><code>$maven_command</code></td>"
          echo "      </tr>"
        fi
      else
        # Extract failed tests from original format
        local failed_test_list=$(grep -o '"failed_tests": \[[^]]*\]' "$json_report" | sed 's/"failed_tests": \[\|\]//g' | sed 's/"//g' | sed 's/,/ /g')
        
        if [[ -n "$failed_test_list" ]]; then
          for failed_test in $failed_test_list; do
            echo "      <tr>"
            echo "        <td>$failed_test</td>"
            echo "        <td>See test logs for details</td>"
            echo "      </tr>"
          done
        else
          echo "      <tr>"
          echo "        <td colspan=\"2\">No detailed information available for failed tests.</td>"
          echo "      </tr>"
        fi
      fi
      
      echo "    </table>"
    fi
    
    echo "    <h2>System Information</h2>"
    echo "    <table>"
    
    # Extract system data based on JSON format
    local os=""
    local cpu_cores=""
    local memory_mb=""
    local mvnimble_version="${MVNIMBLE_VERSION}"
    
    if [[ "$is_build_report" == "true" ]]; then
      # System section is nested in build report - use simpler grep to extract values
      os=$(grep -o '"os": "[^"]*"' "$json_report" | head -1 | cut -d'"' -f4)
      cpu_cores=$(grep -o '"cpu_cores": [0-9]*' "$json_report" | head -1 | grep -o '[0-9]*')
      memory_mb=$(grep -o '"memory_mb": [0-9]*' "$json_report" | head -1 | grep -o '[0-9]*')
    else
      # Original format with system data directly in JSON root
      os=$(grep -o '"os": "[^"]*"' "$json_report" | cut -d'"' -f4)
      cpu_cores=$(grep -o '"cpu_cores": [0-9]*' "$json_report" | grep -o '[0-9]*')
      memory_mb=$(grep -o '"memory_mb": [0-9]*' "$json_report" | grep -o '[0-9]*')
      mvnimble_version=$(grep -o '"version": "[^"]*"' "$json_report" | cut -d'"' -f4)
    fi
    
    echo "      <tr><td>OS</td><td>$os</td></tr>"
    echo "      <tr><td>CPU Cores</td><td>$cpu_cores</td></tr>"
    echo "      <tr><td>Available Memory</td><td>${memory_mb}MB</td></tr>"
    echo "      <tr><td>MVNimble Version</td><td>$mvnimble_version</td></tr>"
    
    # Add build-specific information if available
    if [[ -n "$maven_command" ]]; then
      echo "      <tr><td>Maven Command</td><td>$maven_command</td></tr>"
    fi
    if [[ -n "$build_status" ]]; then
      # Color-code the build status
      local status_color="#27ae60"
      if [[ "$build_status" == "failure" ]]; then
        status_color="#e74c3c"
      fi
      echo "      <tr><td>Build Status</td><td style=\"color: $status_color; font-weight: bold;\">$build_status</td></tr>"
    fi
    
    echo "    </table>"
    
    echo "    <footer>"
    echo "      Report generated by MVNimble Test Engineering Tricorder v${MVNIMBLE_VERSION}<br>"
    echo "      Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license"
    echo "    </footer>"
    echo "  </div>"
    echo "</body>"
    echo "</html>"
  } > "$output_file"
  
  print_success "HTML report generated: $output_file"
  return ${EXIT_SUCCESS}
}