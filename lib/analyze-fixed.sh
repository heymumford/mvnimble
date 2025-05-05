#!/usr/bin/env bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
#==============================================================================
# analyze.sh
#
# MVNimble - Test Analysis and Optimization Module
#
# Description:
#   This module provides functionality for analyzing Maven test patterns and
#   optimizing test configurations for better performance.
#
# Usage:
#   source "path/to/analyze.sh"
#   analyze_build_failure "maven_output.log" "metrics_dir" "report_file"
#==============================================================================

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source required modules
if [[ -z "${CONSTANTS_LOADED+x}" ]]; then
  source "${SCRIPT_DIR}/constants.sh"
fi
source "${SCRIPT_DIR}/common.sh"

# Basic XML utility functions for fallback mode
xml_generate_surefire_config() {
  local fork_count="$1"
  local reuse_forks="$2"
  local arg_line="$3"
  local parallel="$4"
  local thread_count="$5"
  
  cat << EOF
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-surefire-plugin</artifactId>
  <configuration>
    <forkCount>${fork_count}</forkCount>
    <reuseForks>${reuse_forks}</reuseForks>
    <argLine>${arg_line}</argLine>
    <parallel>${parallel}</parallel>
    <threadCount>${thread_count}</threadCount>
  </configuration>
</plugin>
EOF
}

# Detect test frameworks used in the project
xml_detect_test_frameworks() {
  local pom_file="$1"
  local junit5="false"
  local testng="false"
  local custom_dimensions="false"
  
  if grep -q "junit-jupiter" "$pom_file" || grep -q "junit-jupiter-api" "$pom_file"; then
    junit5="true"
  fi
  
  if grep -q "<artifactId>testng</artifactId>" "$pom_file"; then
    testng="true"
  fi
  
  if grep -q "test.dimension" "$pom_file"; then
    custom_dimensions="true"
  fi
  
  echo "junit5=${junit5},testng=${testng},custom_dimensions=${custom_dimensions}"
}

# Simple function to check if element exists
xml_element_exists() {
  local pom_file="$1"
  local xpath="$2"
  local element_name=$(basename "$xpath")
  
  grep -q "<${element_name}>" "$pom_file"
  return $?
}

# Extract Maven settings from POM file
xml_get_maven_settings() {
  local pom_file="$1"
  local fork_count="1.0C"
  local maven_threads="1"
  local fork_memory="256M"
  
  if grep -q "<jvm.fork.count>" "$pom_file"; then
    fork_count=$(grep -o "<jvm.fork.count>[^<]*</jvm.fork.count>" "$pom_file" | 
               sed 's/<jvm.fork.count>\(.*\)<\/jvm.fork.count>/\1/' | 
               head -1 || echo "1.0C")
  fi
  
  if grep -q "<maven.threads>" "$pom_file"; then
    maven_threads=$(grep -o "<maven.threads>[^<]*</maven.threads>" "$pom_file" | 
                  sed 's/<maven.threads>\(.*\)<\/maven.threads>/\1/' | 
                  head -1 || echo "1")
  fi
  
  if grep -q "<jvm.fork.memory>" "$pom_file"; then
    fork_memory=$(grep -o "<jvm.fork.memory>[^<]*</jvm.fork.memory>" "$pom_file" | 
                sed 's/<jvm.fork.memory>\(.*\)<\/jvm.fork.memory>/\1/' | 
                head -1 || echo "256M")
  fi
  
  echo "fork_count=${fork_count},threads=${maven_threads},memory=${fork_memory}"
}

# Extract Maven Surefire configuration
xml_extract_surefire_config() {
  local pom_file="$1"
  local fork_count="Not specified (defaults to 1)"
  local reuse_forks="Not specified (defaults to true)"
  local arg_line="Not specified"
  
  if grep -q "<artifactId>maven-surefire-plugin</artifactId>" "$pom_file"; then
    if grep -q "<forkCount>" "$pom_file"; then
      fork_count=$(grep -o "<forkCount>[^<]*</forkCount>" "$pom_file" | 
                  sed 's/<forkCount>\(.*\)<\/forkCount>/\1/' | 
                  head -1 || echo "Not specified (defaults to 1)")
    fi
    
    if grep -q "<reuseForks>" "$pom_file"; then
      reuse_forks=$(grep -o "<reuseForks>[^<]*</reuseForks>" "$pom_file" | 
                   sed 's/<reuseForks>\(.*\)<\/reuseForks>/\1/' | 
                   head -1 || echo "Not specified (defaults to true)")
    fi
    
    if grep -q "<argLine>" "$pom_file"; then
      arg_line=$(grep -o "<argLine>[^<]*</argLine>" "$pom_file" | 
                sed 's/<argLine>\(.*\)<\/argLine>/\1/' | 
                head -1 || echo "Not specified")
    fi
  fi
  
  echo "fork_count=${fork_count},reuse_forks=${reuse_forks},arg_line=${arg_line}"
}

# Analyze build data and generate reports
function analyze_build_data() {
  local input_dir="$1"
  local output_file="$2"
  local format="${3:-markdown}"
  local pom_file="${4:-pom.xml}"
  
  # Validate input
  if [[ ! -d "$input_dir" ]]; then
    print_error "Input directory not found: $input_dir"
    return ${EXIT_FILE_ERROR}
  fi
  
  # Check for required data files
  local maven_output="${input_dir}/maven_output.log"
  local metrics_dir="${input_dir}/metrics"
  local data_file="${input_dir}/data.json"
  
  if [[ ! -f "$maven_output" ]]; then
    print_warning "Maven output file not found: $maven_output"
    # Create an empty file to prevent errors
    touch "$maven_output"
  fi
  
  if [[ ! -d "$metrics_dir" ]]; then
    print_warning "Metrics directory not found: $metrics_dir"
    # Create directory to prevent errors
    mkdir -p "$metrics_dir"
  fi
  
  print_header "Analyzing Build Data"
  
  # Run build failure analysis
  local failure_report="${input_dir}/build_failure_analysis.md"
  analyze_build_failure "$maven_output" "$metrics_dir" "$failure_report"
  
  # Generate build recommendations
  local recommendations_report="${input_dir}/build_recommendations.md"
  generate_build_recommendations "$maven_output" "$metrics_dir" "$recommendations_report"
  
  # Analyze POM file if it exists
  local pom_report="${input_dir}/pom_analysis.md"
  if [[ -f "$pom_file" ]]; then
    analyze_pom_file "$pom_file" "$pom_report"
  else
    print_warning "POM file not found: $pom_file"
  fi
  
  # Combine all reports into a single analysis based on format
  case "$format" in
    markdown)
      combine_markdown_reports "$input_dir" "$output_file"
      ;;
    html)
      # Convert markdown to HTML
      combine_markdown_reports "$input_dir" "${input_dir}/temp_report.md"
      markdown_to_html "${input_dir}/temp_report.md" "$output_file"
      rm -f "${input_dir}/temp_report.md"
      ;;
    json)
      # Create JSON report
      combine_json_reports "$input_dir" "$output_file"
      ;;
    *)
      print_error "Unsupported format: $format"
      print_info "Supported formats: markdown, html, json"
      return ${EXIT_INVALID_ARGS}
      ;;
  esac
  
  print_success "Analysis complete! Results saved to: $output_file"
  return ${EXIT_SUCCESS}
}

# Analyze Maven build failure
function analyze_build_failure() {
  local maven_output="$1"
  local metrics_dir="$2"
  local report_file="$3"
  
  # Skip if Maven output doesn't exist
  if [[ ! -f "$maven_output" ]]; then
    print_error "Maven output file not found: $maven_output"
    return ${EXIT_FILE_ERROR}
  fi
  
  # Create report directory if needed
  ensure_directory "$(dirname "$report_file")"
  
  print_header "Analyzing Build Failure"
  
  # Extract test failures
  local failures=$(grep -A 5 "<<< FAILURE!" "$maven_output" || echo "")
  local errors=$(grep -A 5 "<<< ERROR!" "$maven_output" || echo "")
  local compilation_errors=$(grep -A 2 "COMPILATION ERROR" "$maven_output" || echo "")
  
  # Extract resource usage from metrics
  local cpu_usage="N/A"
  local memory_usage="N/A"
  local gc_activity="N/A"
  
  if [[ -d "$metrics_dir" && -f "${metrics_dir}/system.csv" ]]; then
    # Get peak CPU usage
    cpu_usage=$(awk -F',' 'NR>1 {if ($2>max) max=$2} END {print max}' "${metrics_dir}/system.csv")
    
    # Get peak memory usage
    memory_usage=$(awk -F',' 'NR>1 {if ($3>max) max=$3} END {print max}' "${metrics_dir}/system.csv")
    
    # Get GC activity
    if [[ -f "${metrics_dir}/jvm.csv" ]]; then
      gc_activity=$(awk -F',' 'NR>1 {if ($7!="") sum+=$7} END {print sum}' "${metrics_dir}/jvm.csv")
    fi
  fi
  
  # Generate the report
  {
    echo "# Build Failure Analysis Report"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    if [[ -n "$compilation_errors" ]]; then
      echo "## Compilation Errors"
      echo ""
      echo "The build failed due to compilation errors:"
      echo ""
      echo '```'
      grep -A 20 "COMPILATION ERROR" "$maven_output" | head -n 20
      echo '```'
      echo ""
      echo "### Recommendations"
      echo ""
      echo "1. Fix the compilation errors before proceeding"
      echo "2. Check for syntax issues in the identified files"
      echo "3. Ensure all dependencies are available"
      echo ""
    elif [[ -n "$failures" || -n "$errors" ]]; then
      echo "## Test Failures"
      echo ""
      echo "The build failed due to test failures:"
      echo ""
      echo '```'
      grep -A 20 "<<< FAILURE\|<<< ERROR" "$maven_output" | head -n 20
      echo '```'
      echo ""
      echo "### Resource Usage"
      echo ""
      echo "* Peak CPU Usage: ${cpu_usage}%"
      echo "* Peak Memory Usage: ${memory_usage}MB"
      echo "* GC Activity: ${gc_activity}ms"
      echo ""
      echo "### Recommendations"
      echo ""
      echo "1. Examine the failed tests for logical errors"
      echo "2. Check for environment-specific issues"
      echo "3. Look for resource constraints if tests are timing out"
      echo ""
    else
      echo "## Analysis Summary"
      echo ""
      echo "No specific build failures detected. This could be due to:"
      echo ""
      echo "* The build succeeded without errors"
      echo "* The error pattern is not recognized by this analyzer"
      echo "* The Maven output log is incomplete"
      echo ""
    fi
    
    echo ""
    echo "---"
    echo "Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license"
  } > "$report_file"
  
  print_success "Build failure analysis report generated: $report_file"
  return ${EXIT_SUCCESS}
}

# Generate build recommendations based on analysis
function generate_build_recommendations() {
  local maven_output="$1"
  local metrics_dir="$2"
  local report_file="$3"
  
  # Create report directory if needed
  ensure_directory "$(dirname "$report_file")"
  
  print_header "Generating Build Recommendations"
  
  # Extract system information
  local cpu_cores=$(get_cpu_cores)
  local memory_mb=$(get_available_memory)
  local os_type=$(get_os_type)
  
  # Calculate recommended settings
  local recommended_threads=$((cpu_cores * 2))
  local recommended_fork_count="$cpu_cores"
  local recommended_memory=$((memory_mb / 4))  # 25% of available memory
  
  # Generate the report
  {
    echo "# Build Optimization Recommendations"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "## System Information"
    echo ""
    echo "* OS: $os_type"
    echo "* CPU Cores: $cpu_cores"
    echo "* Available Memory: ${memory_mb}MB"
    echo ""
    echo "## Maven Configuration Recommendations"
    echo ""
    echo "### Command Line Options"
    echo ""
    echo "```bash"
    echo "mvn -T ${recommended_threads} clean test"
    echo "```"
    echo ""
    echo "### Surefire Configuration"
    echo ""
    
    # Generate surefire config
    echo "```xml"
    xml_generate_surefire_config "$recommended_fork_count" "true" "-Xmx${recommended_memory}m" "classes" "$recommended_fork_count"
    echo "```"
    echo ""
    echo "## Performance Optimization Tips"
    echo ""
    echo "1. Group tests by category to enable parallel execution"
    echo "2. Avoid test interdependencies"
    echo "3. Use \`\\@Category\` annotations for better test organization"
    echo "4. Consider using JUnit 5 for improved parallel test execution"
    echo ""
    echo "---"
    echo "Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license"
  } > "$report_file"
  
  print_success "Build recommendations report generated: $report_file"
  return ${EXIT_SUCCESS}
}

# Analyze a POM file and provide recommendations
function analyze_pom_file() {
  local pom_file="$1"
  local output_file="$2"
  
  # Validate input
  if [[ ! -f "$pom_file" ]]; then
    print_error "POM file not found: $pom_file"
    return ${EXIT_FILE_ERROR}
  fi
  
  # Create output directory if needed
  ensure_directory "$(dirname "$output_file")"
  
  # Generate the report
  {
    echo "# Maven POM Analysis"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "## POM Configuration Analysis"
    echo ""
    echo "### Maven Surefire Configuration"
    echo ""
    
    # Extract surefire config
    local surefire_config=$(xml_extract_surefire_config "$pom_file")
    local fork_count=$(echo "$surefire_config" | grep -o "fork_count=.*" | cut -d',' -f1 | cut -d'=' -f2)
    local reuse_forks=$(echo "$surefire_config" | grep -o "reuse_forks=.*" | cut -d',' -f1 | cut -d'=' -f2)
    local arg_line=$(echo "$surefire_config" | grep -o "arg_line=.*" | cut -d',' -f1 | cut -d'=' -f2)
    
    if [[ "$fork_count" != "Not specified (defaults to 1)" ]]; then
      echo "Maven Surefire Plugin configuration found."
      echo "* Fork Count: $fork_count"
      echo "* Reuse Forks: $reuse_forks"
      echo "* JVM Args: $arg_line"
    else
      echo "No Maven Surefire Plugin configuration found."
    fi
    
    echo ""
    echo "### Dependency Analysis"
    echo ""
    
    # Extract framework info
    local frameworks=$(xml_detect_test_frameworks "$pom_file")
    local junit5=$(echo "$frameworks" | grep -o "junit5=.*" | cut -d',' -f1 | cut -d'=' -f2)
    
    if [[ "$junit5" == "true" ]]; then
      echo "* JUnit: Enabled"
      echo "  * Version: JUnit 5 (Jupiter)"
    elif grep -q "<artifactId>junit</artifactId>" "$pom_file"; then
      echo "* JUnit: Enabled"
      echo "  * Version: JUnit 4"
    else
      echo "* JUnit: Not found"
    fi
    
    if grep -q "testng" "$pom_file"; then
      echo "* TestNG: Enabled"
    else
      echo "* TestNG: Not found"
    fi
    
    if grep -q "mockito" "$pom_file"; then
      echo "* Mockito: Enabled"
    else
      echo "* Mockito: Not found"
    fi
    
    echo ""
    echo "## Recommendations"
    echo ""
    echo "Based on the POM analysis, consider the following optimizations:"
    echo ""
    
    # Generate system-specific recommendations
    local cpu_cores=$(get_cpu_cores)
    local recommended_fork_count=$((cpu_cores > 1 ? cpu_cores : 1))
    
    echo "1. **Parallelism**: Configure Maven Surefire Plugin for parallel execution"
    echo "   \`\`\`xml"
    echo "   <forkCount>${recommended_fork_count}</forkCount>"
    echo "   <reuseForks>true</reuseForks>"
    echo "   <parallel>classes</parallel>"
    echo "   <threadCount>${recommended_fork_count}</threadCount>"
    echo "   \`\`\`"
    echo ""
    echo "2. **Memory Settings**: Optimize JVM memory allocation"
    echo "   \`\`\`xml"
    echo "   <argLine>-Xmx1024m -XX:+UseG1GC</argLine>"
    echo "   \`\`\`"
    echo ""
    echo "3. **Test Organization**: Group tests by category to enable selective execution"
    echo "   \`\`\`xml"
    echo "   <groups>UnitTest,FastTest</groups>"
    echo "   <excludedGroups>IntegrationTest,SlowTest</excludedGroups>"
    echo "   \`\`\`"
    echo ""
    
    echo "---"
    echo "Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license"
  } > "$output_file"
  
  print_success "POM analysis report generated: $output_file"
  return ${EXIT_SUCCESS}
}

# Combine multiple markdown reports into one
function combine_markdown_reports() {
  local input_dir="$1"
  local output_file="$2"
  
  # Create output directory if needed
  ensure_directory "$(dirname "$output_file")"
  
  # Start with a header
  {
    echo "# MVNimble Build Analysis Report"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "## Table of Contents"
    echo ""
    echo "1. [Build Overview](#build-overview)"
    echo "2. [Performance Analysis](#performance-analysis)"
    echo "3. [Build Failure Analysis](#build-failure-analysis)"
    echo "4. [Maven Configuration Analysis](#maven-configuration-analysis)"
    echo "5. [Optimization Recommendations](#optimization-recommendations)"
    echo ""
    
    # Add build overview section
    echo "## Build Overview"
    echo ""
    
    # Include data from monitoring report
    if [[ -f "${input_dir}/test_monitoring_report.md" ]]; then
      grep -A 5 "## Session Overview" "${input_dir}/test_monitoring_report.md" | tail -n +2
    else
      echo "No monitoring data available."
    fi
    
    echo ""
    
    # Add performance analysis section
    echo "## Performance Analysis"
    echo ""
    
    # Include resource utilization data
    if [[ -f "${input_dir}/test_monitoring_report.md" ]]; then
      grep -A 20 "## Resource Utilization" "${input_dir}/test_monitoring_report.md" | tail -n +2 | head -n 20
    else
      echo "No performance data available."
    fi
    
    echo ""
    
    # Add build failure analysis section
    echo "## Build Failure Analysis"
    echo ""
    
    # Include build failure analysis
    if [[ -f "${input_dir}/build_failure_analysis.md" ]]; then
      grep -v "^# Build Failure Analysis Report" "${input_dir}/build_failure_analysis.md" | grep -v "^Generated:" | grep -v "^---" | grep -v "^Copyright"
    else
      echo "No build failure analysis available."
    fi
    
    echo ""
    
    # Add Maven configuration analysis section
    echo "## Maven Configuration Analysis"
    echo ""
    
    # Include POM analysis
    if [[ -f "${input_dir}/pom_analysis.md" ]]; then
      grep -A 100 "^## POM Configuration Analysis" "${input_dir}/pom_analysis.md" | grep -v "^## Recommendations" | grep -v "^# Maven POM Analysis" | grep -v "^Generated:" | grep -v "^---" | grep -v "^Copyright"
    else
      echo "No POM configuration analysis available."
    fi
    
    echo ""
    
    # Add optimization recommendations section
    echo "## Optimization Recommendations"
    echo ""
    
    # Include build recommendations
    if [[ -f "${input_dir}/build_recommendations.md" ]]; then
      grep -A 100 "^## Maven Configuration Recommendations" "${input_dir}/build_recommendations.md" | grep -v "^# Build Optimization Recommendations" | grep -v "^Generated:" | grep -v "^---" | grep -v "^Copyright"
    else
      echo "No build recommendations available."
    fi
    
    # Include POM recommendations
    if [[ -f "${input_dir}/pom_analysis.md" ]]; then
      grep -A 100 "^## Recommendations" "${input_dir}/pom_analysis.md" | grep -v "^---" | grep -v "^Copyright"
    fi
    
    echo ""
    echo "---"
    echo "Analysis generated by MVNimble Test Engineering Tricorder v${MVNIMBLE_VERSION}"
    echo ""
    echo "---"
    echo "Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license"
  } > "$output_file"
  
  print_success "Combined report generated: $output_file"
  return ${EXIT_SUCCESS}
}

# Convert markdown to HTML (simplified version)
function markdown_to_html() {
  local markdown_file="$1"
  local html_file="$2"
  
  # Create output directory if needed
  ensure_directory "$(dirname "$html_file")"
  
  # Simple markdown to HTML conversion
  {
    echo "<!DOCTYPE html>"
    echo "<html lang=\"en\">"
    echo "<head>"
    echo "  <meta charset=\"UTF-8\">"
    echo "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"
    echo "  <title>MVNimble Build Analysis Report</title>"
    echo "  <style>"
    echo "    body { font-family: Arial, sans-serif; margin: 0; padding: 20px; color: #333; max-width: 1000px; margin: 0 auto; }"
    echo "    h1, h2, h3 { color: #2c3e50; }"
    echo "    h1 { border-bottom: 1px solid #ddd; padding-bottom: 10px; }"
    echo "    h2 { margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; }"
    echo "    pre, code { background: #f8f9fa; border-radius: 3px; padding: 2px 5px; }"
    echo "    pre { padding: 15px; overflow-x: auto; }"
    echo "    pre code { padding: 0; }"
    echo "    table { border-collapse: collapse; width: 100%; margin: 20px 0; }"
    echo "    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }"
    echo "    th { background-color: #f2f2f2; }"
    echo "    tr:nth-child(even) { background-color: #f9f9f9; }"
    echo "    a { color: #3498db; text-decoration: none; }"
    echo "    a:hover { text-decoration: underline; }"
    echo "    .container { max-width: 1000px; margin: 0 auto; }"
    echo "    .toc { background: #f8f9fa; padding: 15px; border-radius: 5px; }"
    echo "    footer { margin-top: 50px; text-align: center; font-size: 12px; color: #7f8c8d; }"
    echo "  </style>"
    echo "</head>"
    echo "<body>"
    echo "  <div class=\"container\">"
    echo "    <h1>MVNimble Build Analysis Report</h1>"
    echo "  </div>"
    echo "  <footer>"
    echo "    Analysis generated by MVNimble Test Engineering Tricorder v${MVNIMBLE_VERSION}"
    echo "    <br>"
    echo "    Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license"
    echo "  </footer>"
    echo "</body>"
    echo "</html>"
  } > "$html_file"
  
  print_success "HTML report generated: $html_file"
  return ${EXIT_SUCCESS}
}

# Create a JSON report combining all analysis data
function combine_json_reports() {
  local input_dir="$1"
  local output_file="$2"
  
  # Create output directory if needed
  ensure_directory "$(dirname "$output_file")"
  
  # Generate a simplified JSON report
  {
    echo "{"
    echo "  \"timestamp\": \"$(date +%s)\","
    echo "  \"date\": \"$(date '+%Y-%m-%d %H:%M:%S')\","
    echo "  \"build_info\": {},"
    echo "  \"analysis\": {"
    echo "    \"has_failures\": $(if [[ -f "${input_dir}/build_failure_analysis.md" && $(grep -c "Build failed" "${input_dir}/build_failure_analysis.md") -gt 0 ]]; then echo "true"; else echo "false"; fi),"
    echo "    \"has_pom_analysis\": $(if [[ -f "${input_dir}/pom_analysis.md" ]]; then echo "true"; else echo "false"; fi),"
    echo "    \"has_recommendations\": $(if [[ -f "${input_dir}/build_recommendations.md" ]]; then echo "true"; else echo "false"; fi)"
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