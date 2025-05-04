#!/usr/bin/env bash
# ci_export.bash
# Helper functions for exporting test results to CI platforms
#
# This script includes functions to format and export test results
# to various CI platforms like GitHub Actions, Jenkins, Travis, etc.

# Load test helper
load ../test_helper

# Export test results to GitHub Actions
github_actions_export() {
  local json_report="$1"
  local result_dir="$2"
  
  # Parse JSON report data
  local total_tests=$(grep -o '"total": [0-9]*' "$json_report" | grep -o '[0-9]*' | head -1)
  local passed_tests=$(grep -o '"passed": [0-9]*' "$json_report" | grep -o '[0-9]*' | head -1)
  local failed_tests=$(grep -o '"failed": [0-9]*' "$json_report" | grep -o '[0-9]*' | head -1)
  local skipped_tests=$(grep -o '"skipped": [0-9]*' "$json_report" | grep -o '[0-9]*' | head -1)
  local duration=$(grep -o '"duration": [0-9.]*' "$json_report" | grep -o '[0-9.]*' | head -1)
  
  # Generate GitHub Actions annotations for failed tests
  if [ "$failed_tests" -gt 0 ]; then
    # Extract failed tests
    local failed_test_list=$(grep -o '"failed_tests": \[[^]]*\]' "$json_report" | sed 's/"failed_tests": \[\|\]//g' | sed 's/"//g' | sed 's/,/ /g')
    
    for failed_test in $failed_test_list; do
      # Get error message from result file
      if [ -f "${result_dir}/${failed_test}.result" ]; then
        local error_line=$(grep -n "not ok" "${result_dir}/${failed_test}.result" | head -1 | cut -d':' -f1)
        local error_message=$(sed -n "$((error_line+1)),+5p" "${result_dir}/${failed_test}.result" | grep -v "^#" | head -1)
        
        # Get file name and line number if available
        local file_name=""
        local line_number=""
        if [[ "$error_message" =~ ([^:]+):([0-9]+) ]]; then
          file_name="${BASH_REMATCH[1]}"
          line_number="${BASH_REMATCH[2]}"
        else
          file_name="$failed_test"
        fi
        
        # Generate GitHub Actions error annotation
        if [ -n "$line_number" ]; then
          echo "::error file=${file_name},line=${line_number}::${error_message}"
        else
          echo "::error file=${file_name}::${error_message}"
        fi
      fi
    done
  fi
  
  # Generate GitHub Actions summary
  if [ -n "$GITHUB_STEP_SUMMARY" ]; then
    {
      echo "## MVNimble Test Summary"
      echo
      echo "| Type | Count |"
      echo "|------|-------|"
      echo "| ✅ Passed | $passed_tests |"
      echo "| ❌ Failed | $failed_tests |"
      echo "| ⏭️ Skipped | $skipped_tests |"
      echo "| **Total** | **$total_tests** |"
      echo "| ⏱️ Duration | $(printf "%.2f" $duration) seconds |"
      
      # Show functional/non-functional split
      local functional_count=$(grep -o '"functional": [0-9]*' "$json_report" | grep -o '[0-9]*')
      local nonfunctional_count=$(grep -o '"nonfunctional": [0-9]*' "$json_report" | grep -o '[0-9]*')
      
      if [ -n "$functional_count" ] && [ -n "$nonfunctional_count" ]; then
        echo
        echo "### Test Types"
        echo
        echo "| Category | Count |"
        echo "|----------|-------|"
        echo "| Functional | $functional_count |"
        echo "| Non-functional | $nonfunctional_count |"
      fi
      
      # Show ADR coverage
      echo
      echo "### ADR Coverage"
      echo
      echo "| ADR | Description | Tests |"
      echo "|-----|-------------|-------|"
      
      for i in {0..5}; do
        local adr_count=$(grep -o "\"id\": \"ADR 00$i\", \"count\": [0-9]*" "$json_report" | grep -o '[0-9]*$')
        local adr_desc=""
        case $i in
          0) adr_desc="ADR Process for QA Empowerment" ;;
          1) adr_desc="Shell Script Architecture" ;;
          2) adr_desc="Bash Compatibility" ;;
          3) adr_desc="Dependency Management" ;;
          4) adr_desc="Cross-Platform Compatibility" ;;
          5) adr_desc="Magic Numbers Elimination" ;;
        esac
        
        echo "| ADR 00$i | $adr_desc | ${adr_count:-0} |"
      done
      
      # List failed tests if any
      if [ "$failed_tests" -gt 0 ]; then
        echo
        echo "### Failed Tests"
        echo
        
        local failed_test_list=$(grep -o '"failed_tests": \[[^]]*\]' "$json_report" | sed 's/"failed_tests": \[\|\]//g' | sed 's/"//g' | sed 's/,/ /g')
        
        for failed_test in $failed_test_list; do
          echo "#### $failed_test"
          echo
          echo "```"
          grep -A 10 "not ok" "${result_dir}/${failed_test}.result" | head -10
          echo "```"
          echo
        done
      fi
    } >> "$GITHUB_STEP_SUMMARY"
  fi
}

# Export test results to Jenkins
jenkins_export() {
  local junit_report="$1"
  
  # For Jenkins, just using the JUnit XML report is usually sufficient
  # as Jenkins has built-in support for parsing JUnit XML.
  # This function can be extended if additional Jenkins-specific formatting is needed.
  
  # Ensure junit_report exists
  if [ -f "$junit_report" ]; then
    echo "JUnit report generated for Jenkins: $junit_report"
  else
    echo "Error: JUnit report not found for Jenkins export: $junit_report"
    return 1
  fi
}

# Export test results to Travis CI
travis_export() {
  local json_report="$1"
  local result_dir="$2"
  
  # Parse JSON report data
  local total_tests=$(grep -o '"total": [0-9]*' "$json_report" | grep -o '[0-9]*' | head -1)
  local passed_tests=$(grep -o '"passed": [0-9]*' "$json_report" | grep -o '[0-9]*' | head -1)
  local failed_tests=$(grep -o '"failed": [0-9]*' "$json_report" | grep -o '[0-9]*' | head -1)
  
  # Format for Travis fold
  echo -e "travis_fold:start:mvnimble_test_results"
  echo "MVNimble Test Results: $passed_tests/$total_tests tests passed"
  
  # List any failed tests
  if [ "$failed_tests" -gt 0 ]; then
    echo "Failed tests:"
    
    local failed_test_list=$(grep -o '"failed_tests": \[[^]]*\]' "$json_report" | sed 's/"failed_tests": \[\|\]//g' | sed 's/"//g' | sed 's/,/ /g')
    
    for failed_test in $failed_test_list; do
      echo "- $failed_test:"
      grep -A 5 "not ok" "${result_dir}/${failed_test}.result" | head -5
      echo
    done
  fi
  
  echo -e "travis_fold:end:mvnimble_test_results"
}

# Export test results based on detected CI environment
export_ci_results() {
  local json_report="$1"
  local junit_report="$2"
  local result_dir="$3"
  
  # Detect CI environment and use appropriate export function
  if [ -n "$GITHUB_ACTIONS" ]; then
    github_actions_export "$json_report" "$result_dir"
  elif [ -n "$JENKINS_URL" ]; then
    jenkins_export "$junit_report"
  elif [ -n "$TRAVIS" ]; then
    travis_export "$json_report" "$result_dir"
  else
    echo "No CI environment detected or unsupported CI system"
    return 1
  fi
}