#!/usr/bin/env bash
# report_helpers.bash
# Helper functions for generating test reports

# Define the root project directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

# Directory containing the modules
MODULE_DIR="${PROJECT_ROOT}/src/lib/modules"

# Generate a JSON report from test results
generate_json_report() {
  local test_results_dir="$1"
  local output_file="$2"
  
  # Gather results from test output files
  local total_tests=0
  local total_passed=0
  local total_failed=0
  local total_skipped=0
  local total_duration=0
  
  # Arrays to hold test data
  local test_data=()
  local failed_tests=()
  
  # Tag statistics
  local functional_count=0
  local nonfunctional_count=0
  local positive_count=0
  local negative_count=0
  
  # ADR statistics
  local adr_counts=()
  for i in {0..5}; do
    adr_counts[$i]=0
  done
  
  # Component statistics
  local core_count=0
  local platform_count=0
  local dependency_count=0
  local reporting_count=0
  local package_manager_count=0
  local env_detection_count=0
  
  # Performance data
  local performance_tests=()
  
  # Process each test result file
  for result_file in "${test_results_dir}"/*.result; do
    if [ -f "$result_file" ]; then
      # Parse basic metrics
      local file_status=$(grep "status: " "$result_file" | cut -d' ' -f2)
      local file_passed=$(grep "passed: " "$result_file" | cut -d' ' -f2)
      local file_failed=$(grep "failed: " "$result_file" | cut -d' ' -f2)
      local file_skipped=$(grep "skipped: " "$result_file" | cut -d' ' -f2)
      local file_duration=$(grep "duration: " "$result_file" | cut -d' ' -f2)
      
      # Update totals
      total_passed=$((total_passed + file_passed))
      total_failed=$((total_failed + file_failed))
      total_skipped=$((total_skipped + file_skipped))
      total_duration=$(echo "$total_duration + $file_duration" | bc)
      
      # Process test tags
      local test_file=$(basename "$result_file" .result)
      
      # Parse tags from the test file
      # Use safe grep that won't error if file doesn't exist or pattern not found
      local tag_data=$(grep -A1 "^# @" "${test_file}" 2>/dev/null || echo "")
      
      # Count tags
      if [[ "$tag_data" == *"@functional"* ]]; then
        functional_count=$((functional_count + 1))
      fi
      if [[ "$tag_data" == *"@nonfunctional"* ]]; then
        nonfunctional_count=$((nonfunctional_count + 1))
      fi
      if [[ "$tag_data" == *"@positive"* ]]; then
        positive_count=$((positive_count + 1))
      fi
      if [[ "$tag_data" == *"@negative"* ]]; then
        negative_count=$((negative_count + 1))
      fi
      
      # Count ADR tags
      for i in {0..5}; do
        if [[ "$tag_data" == *"@adr00$i"* ]]; then
          adr_counts[$i]=$((adr_counts[$i] + 1))
        fi
      done
      
      # Count component tags
      if [[ "$tag_data" == *"@core"* ]]; then
        core_count=$((core_count + 1))
      fi
      if [[ "$tag_data" == *"@platform"* ]]; then
        platform_count=$((platform_count + 1))
      fi
      if [[ "$tag_data" == *"@dependency"* ]]; then
        dependency_count=$((dependency_count + 1))
      fi
      if [[ "$tag_data" == *"@reporting"* ]]; then
        reporting_count=$((reporting_count + 1))
      fi
      if [[ "$tag_data" == *"@package-manager"* ]]; then
        package_manager_count=$((package_manager_count + 1))
      fi
      if [[ "$tag_data" == *"@env-detection"* ]]; then
        env_detection_count=$((env_detection_count + 1))
      fi
      
      # Look for performance tests
      if [[ "$tag_data" == *"@performance"* ]]; then
        # Extract test name and execution time
        local test_name=$(grep -A1 "^# @" "${test_file}" | grep "@test" | sed 's/^@test "\(.*\)" {$/\1/')
        performance_tests+=("{\"name\":\"$test_name\",\"time\":$file_duration}")
      fi
      
      # Add to test data array
      test_data+=("{\"name\":\"$test_file\",\"status\":$file_status,\"passed\":$file_passed,\"failed\":$file_failed,\"skipped\":$file_skipped,\"duration\":$file_duration}")
      
      # Add to failed tests if any
      if [ "$file_status" -ne 0 ]; then
        failed_tests+=("$test_file")
      fi
    fi
  done
  
  total_tests=$((total_passed + total_failed + total_skipped))
  
  # Create JSON report
  {
    echo "{"
    echo "  \"summary\": {"
    echo "    \"total\": $total_tests,"
    echo "    \"passed\": $total_passed,"
    echo "    \"failed\": $total_failed,"
    echo "    \"skipped\": $total_skipped,"
    echo "    \"duration\": $total_duration"
    echo "  },"
    echo "  \"tags\": {"
    echo "    \"functional\": $functional_count,"
    echo "    \"nonfunctional\": $nonfunctional_count,"
    echo "    \"positive\": $positive_count,"
    echo "    \"negative\": $negative_count,"
    echo "    \"adrs\": ["
    for i in {0..5}; do
      echo "      { \"id\": \"ADR 00$i\", \"count\": ${adr_counts[$i]} }"
      if [ $i -lt 5 ]; then
        echo ","
      fi
    done
    echo "    ],"
    echo "    \"components\": {"
    echo "      \"core\": $core_count,"
    echo "      \"platform\": $platform_count,"
    echo "      \"dependency\": $dependency_count,"
    echo "      \"reporting\": $reporting_count,"
    echo "      \"package_manager\": $package_manager_count,"
    echo "      \"env_detection\": $env_detection_count"
    echo "    }"
    echo "  },"
    echo "  \"tests\": ["
    for i in "${!test_data[@]}"; do
      echo "    ${test_data[$i]}"
      if [ $i -lt $((${#test_data[@]} - 1)) ]; then
        echo ","
      fi
    done
    echo "  ],"
    echo "  \"failed_tests\": ["
    for i in "${!failed_tests[@]}"; do
      echo "    \"${failed_tests[$i]}\""
      if [ $i -lt $((${#failed_tests[@]} - 1)) ]; then
        echo ","
      fi
    done
    echo "  ],"
    echo "  \"performance\": ["
    for i in "${!performance_tests[@]}"; do
      echo "    ${performance_tests[$i]}"
      if [ $i -lt $((${#performance_tests[@]} - 1)) ]; then
        echo ","
      fi
    done
    echo "  ],"
    echo "  \"ci\": {"
    echo "    \"environment\": \"${CI_ENVIRONMENT:-local}\","
    echo "    \"system\": \"$(uname -s)\","
    echo "    \"platform\": \"$(uname -m)\","
    echo "    \"timestamp\": \"$(date '+%Y-%m-%d %H:%M:%S')\","
    echo "    \"repository\": \"${GITHUB_REPOSITORY:-mvnimble}\","
    echo "    \"branch\": \"${GITHUB_REF:-main}\","
    echo "    \"commit\": \"${GITHUB_SHA:-unknown}\""
    echo "  }"
    echo "}"
  } > "$output_file"
}

# Generate an HTML report from test results
generate_html_report() {
  local test_results_dir="$1"
  local json_report="$2"
  local output_file="$3"
  local template_file="${PROJECT_ROOT}/test/bats/common/templates/report_template.html"
  
  # Read the template
  local template=$(cat "$template_file")
  
  # Parse JSON report data
  local total_tests=$(grep -o '"total": [0-9]*' "$json_report" | grep -o '[0-9]*')
  local passed_tests=$(grep -o '"passed": [0-9]*' "$json_report" | grep -o '[0-9]*' | head -1)
  local failed_tests=$(grep -o '"failed": [0-9]*' "$json_report" | grep -o '[0-9]*' | head -1)
  local skipped_tests=$(grep -o '"skipped": [0-9]*' "$json_report" | grep -o '[0-9]*' | head -1)
  local duration=$(grep -o '"duration": [0-9.]*' "$json_report" | grep -o '[0-9.]*')
  
  # Tag statistics
  local functional_count=$(grep -o '"functional": [0-9]*' "$json_report" | grep -o '[0-9]*')
  local nonfunctional_count=$(grep -o '"nonfunctional": [0-9]*' "$json_report" | grep -o '[0-9]*')
  local positive_count=$(grep -o '"positive": [0-9]*' "$json_report" | grep -o '[0-9]*')
  local negative_count=$(grep -o '"negative": [0-9]*' "$json_report" | grep -o '[0-9]*')
  
  # Calculate percentages
  local functional_percent=0
  local nonfunctional_percent=0
  local positive_percent=0
  local negative_percent=0
  
  if [ "$total_tests" -gt 0 ]; then
    functional_percent=$((functional_count * 100 / total_tests))
    nonfunctional_percent=$((100 - functional_percent))
    positive_percent=$((positive_count * 100 / total_tests))
    negative_percent=$((100 - positive_percent))
  fi
  
  # Extract ADR data
  local adr_rows=""
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
    
    adr_rows="${adr_rows}<tr><td>ADR 00$i</td><td>$adr_desc</td><td>$adr_count</td></tr>"
  done
  
  # Extract component data
  local component_rows=""
  local component_labels=""
  local component_data=""
  
  local core_count=$(grep -o '"core": [0-9]*' "$json_report" | grep -o '[0-9]*')
  local platform_count=$(grep -o '"platform": [0-9]*' "$json_report" | grep -o '[0-9]*')
  local dependency_count=$(grep -o '"dependency": [0-9]*' "$json_report" | grep -o '[0-9]*')
  local reporting_count=$(grep -o '"reporting": [0-9]*' "$json_report" | grep -o '[0-9]*')
  local package_manager_count=$(grep -o '"package_manager": [0-9]*' "$json_report" | grep -o '[0-9]*')
  local env_detection_count=$(grep -o '"env_detection": [0-9]*' "$json_report" | grep -o '[0-9]*')
  
  component_rows="${component_rows}<tr><td>Core</td><td>$core_count</td></tr>"
  component_rows="${component_rows}<tr><td>Platform</td><td>$platform_count</td></tr>"
  component_rows="${component_rows}<tr><td>Dependency</td><td>$dependency_count</td></tr>"
  component_rows="${component_rows}<tr><td>Reporting</td><td>$reporting_count</td></tr>"
  component_rows="${component_rows}<tr><td>Package Manager</td><td>$package_manager_count</td></tr>"
  component_rows="${component_rows}<tr><td>Environment Detection</td><td>$env_detection_count</td></tr>"
  
  component_labels="'Core', 'Platform', 'Dependency', 'Reporting', 'Package Manager', 'Environment Detection'"
  component_data="$core_count, $platform_count, $dependency_count, $reporting_count, $package_manager_count, $env_detection_count"
  
  # Generate failures section if needed
  local failures_section=""
  if [ "$failed_tests" -gt 0 ]; then
    failures_section="<details><summary>Failed Tests</summary><div class=\"details-content\"><table><tr><th>Test</th><th>Error</th></tr>"
    
    # Extract failed tests
    local failed_test_list=$(grep -o '"failed_tests": \[[^]]*\]' "$json_report" | sed 's/"failed_tests": \[\|\]//g' | sed 's/"//g' | sed 's/,//g')
    
    for failed_test in $failed_test_list; do
      local error_message=$(grep -A 10 "not ok" "${test_results_dir}/${failed_test}.result" | head -1)
      failures_section="${failures_section}<tr><td>$failed_test</td><td>$error_message</td></tr>"
    done
    
    failures_section="${failures_section}</table></div></details>"
  fi
  
  # Extract performance data if available
  local performance_labels=""
  local performance_data=""
  local performance_tests=$(grep -o '"performance": \[[^]]*\]' "$json_report" | sed 's/"performance": \[\|\]//g')
  
  if [ -n "$performance_tests" ]; then
    local perf_names=$(echo "$performance_tests" | grep -o '"name":"[^"]*"' | sed 's/"name":"//g' | sed 's/"//g')
    local perf_times=$(echo "$performance_tests" | grep -o '"time":[0-9.]*' | sed 's/"time"://g')
    
    for name in $perf_names; do
      if [ -z "$performance_labels" ]; then
        performance_labels="'$name'"
      else
        performance_labels="$performance_labels, '$name'"
      fi
    done
    
    for time in $perf_times; do
      if [ -z "$performance_data" ]; then
        performance_data="$time"
      else
        performance_data="$performance_data, $time"
      fi
    done
  fi
  
  # Generate test items
  local test_items=""
  local test_files=$(find "${test_results_dir}" -name "*.result" | sort)
  
  for test_file in $test_files; do
    local test_name=$(basename "$test_file" .result)
    local status=$(grep "status: " "$test_file" | cut -d' ' -f2)
    local test_status_icon=""
    
    if [ "$status" -eq 0 ]; then
      test_status_icon="<span class=\"test-status success\">✓</span>"
    else
      test_status_icon="<span class=\"test-status danger\">✗</span>"
    fi
    
    # Get tags for the test
    local test_tags=""
    local tag_data=$(grep -A1 "^# @" "$test_name" 2>/dev/null || echo "")
    
    if [[ "$tag_data" == *"@functional"* ]]; then
      test_tags="${test_tags}<span class=\"tag functional\">functional</span>"
    fi
    if [[ "$tag_data" == *"@nonfunctional"* ]]; then
      test_tags="${test_tags}<span class=\"tag nonfunctional\">nonfunctional</span>"
    fi
    if [[ "$tag_data" == *"@positive"* ]]; then
      test_tags="${test_tags}<span class=\"tag positive\">positive</span>"
    fi
    if [[ "$tag_data" == *"@negative"* ]]; then
      test_tags="${test_tags}<span class=\"tag negative\">negative</span>"
    fi
    
    test_items="${test_items}<div class=\"test-item\">${test_status_icon}<div class=\"test-name\">$test_name</div><div class=\"test-tags\">$test_tags</div></div>"
  done
  
  # Add CI information if available
  local ci_info=""
  if [ -n "$CI" ] || [ -n "$GITHUB_ACTIONS" ]; then
    ci_info="<div class=\"ci-info\">
      <h3>CI Environment</h3>
      <table>
        <tr><td>System</td><td>$(uname -s) $(uname -r) $(uname -m)</td></tr>
        <tr><td>CI System</td><td>${GITHUB_WORKFLOW:-Unknown}</td></tr>"
    
    if [ -n "$GITHUB_REPOSITORY" ]; then
      ci_info="${ci_info}<tr><td>Repository</td><td>$GITHUB_REPOSITORY</td></tr>"
    fi
    
    if [ -n "$GITHUB_REF" ]; then
      ci_info="${ci_info}<tr><td>Branch</td><td>$GITHUB_REF</td></tr>"
    fi
    
    if [ -n "$GITHUB_SHA" ]; then
      ci_info="${ci_info}<tr><td>Commit</td><td>$GITHUB_SHA</td></tr>"
    fi
    
    ci_info="${ci_info}</table></div>"
  fi
  
  # Replace placeholders in the template
  template="${template//\{\{TIMESTAMP\}\}/$(date '+%Y-%m-%d %H:%M:%S')}"
  template="${template//\{\{TOTAL_TESTS\}\}/$total_tests}"
  template="${template//\{\{PASSED_TESTS\}\}/$passed_tests}"
  template="${template//\{\{FAILED_TESTS\}\}/$failed_tests}"
  template="${template//\{\{SKIPPED_TESTS\}\}/$skipped_tests}"
  template="${template//\{\{DURATION\}\}/$duration}"
  
  template="${template//\{\{FUNCTIONAL_COUNT\}\}/$functional_count}"
  template="${template//\{\{NONFUNCTIONAL_COUNT\}\}/$nonfunctional_count}"
  template="${template//\{\{POSITIVE_COUNT\}\}/$positive_count}"
  template="${template//\{\{NEGATIVE_COUNT\}\}/$negative_count}"
  
  template="${template//\{\{FUNCTIONAL_PERCENT\}\}/$functional_percent}"
  template="${template//\{\{NONFUNCTIONAL_PERCENT\}\}/$nonfunctional_percent}"
  template="${template//\{\{POSITIVE_PERCENT\}\}/$positive_percent}"
  template="${template//\{\{NEGATIVE_PERCENT\}\}/$negative_percent}"
  
  template="${template//\{\{ADR_ROWS\}\}/$adr_rows}"
  template="${template//\{\{COMPONENT_ROWS\}\}/$component_rows}"
  template="${template//\{\{COMPONENT_LABELS\}\}/$component_labels}"
  template="${template//\{\{COMPONENT_DATA\}\}/$component_data}"
  
  template="${template//\{\{FAILURES_SECTION\}\}/$failures_section}"
  template="${template//\{\{TEST_ITEMS\}\}/$test_items}"
  template="${template//\{\{CI_INFO\}\}/$ci_info}"
  
  template="${template//\{\{PERFORMANCE_LABELS\}\}/$performance_labels}"
  template="${template//\{\{PERFORMANCE_DATA\}\}/$performance_data}"
  
  # Write the report
  echo "$template" > "$output_file"
}

# Generate a JUnit XML report
generate_junit_report() {
  local test_results_dir="$1"
  local output_file="$2"
  local json_report="$3"
  
  # Parse JSON report data for summary
  local total_tests=$(grep -o '"total": [0-9]*' "$json_report" | grep -o '[0-9]*' | head -1)
  local passed_tests=$(grep -o '"passed": [0-9]*' "$json_report" | grep -o '[0-9]*' | head -1)
  local failed_tests=$(grep -o '"failed": [0-9]*' "$json_report" | grep -o '[0-9]*' | head -1)
  local skipped_tests=$(grep -o '"skipped": [0-9]*' "$json_report" | grep -o '[0-9]*' | head -1)
  local duration=$(grep -o '"duration": [0-9.]*' "$json_report" | grep -o '[0-9.]*' | head -1)
  
  # Start XML file
  {
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo '<testsuites name="MVNimble Tests" tests="'"$total_tests"'" failures="'"$failed_tests"'" errors="0" skipped="'"$skipped_tests"'" time="'"$duration"'">'
    
    # Process each test file as a testsuite
    for result_file in "${test_results_dir}"/*.result; do
      if [ -f "$result_file" ]; then
        local file_name=$(basename "$result_file" .result)
        local file_status=$(grep "status: " "$result_file" | cut -d' ' -f2)
        local file_passed=$(grep "passed: " "$result_file" | cut -d' ' -f2)
        local file_failed=$(grep "failed: " "$result_file" | cut -d' ' -f2)
        local file_skipped=$(grep "skipped: " "$result_file" | cut -d' ' -f2)
        local file_duration=$(grep "duration: " "$result_file" | cut -d' ' -f2)
        local test_count=$((file_passed + file_failed + file_skipped))
        
        if [ "$test_count" -gt 0 ]; then
          echo '  <testsuite name="'"$file_name"'" tests="'"$test_count"'" failures="'"$file_failed"'" errors="0" skipped="'"$file_skipped"'" time="'"$file_duration"'">'
          
          # Extract individual test cases
          local test_output=$(cat "$result_file")
          local test_lines=$(echo "$test_output" | grep -n "^ok\|^not ok" || echo "")
          
          # Process each test case
          if [ -n "$test_lines" ]; then
            echo "$test_lines" | while IFS= read -r line; do
              local line_num=$(echo "$line" | cut -d':' -f1)
              local test_result=$(echo "$line" | cut -d':' -f2)
              local test_name=$(echo "$test_result" | sed -E 's/^(ok|not ok) [0-9]+ - (.*)/\2/' | sed 's/&/\&amp;/g' | sed 's/</\&lt;/g' | sed 's/>/\&gt;/g' | sed 's/"/\&quot;/g' | sed "s/'/\&apos;/g")
              local test_time="0.001" # Default time
              
              # Check if test passed or failed
              if [[ "$test_result" == *"not ok"* ]]; then
                # Failed test
                local error_message=$(sed -n "$((line_num+1)),+5p" "$result_file" | grep -v "^#" | head -1 | sed 's/&/\&amp;/g' | sed 's/</\&lt;/g' | sed 's/>/\&gt;/g' | sed 's/"/\&quot;/g' | sed "s/'/\&apos;/g")
                echo '    <testcase classname="'"$file_name"'" name="'"$test_name"'" time="'"$test_time"'">'
                echo '      <failure message="'"${error_message:-Test failed}"'">'
                
                # Include error details
                local error_details=$(sed -n "$((line_num+1)),+10p" "$result_file" | sed 's/&/\&amp;/g' | sed 's/</\&lt;/g' | sed 's/>/\&gt;/g' | sed 's/"/\&quot;/g' | sed "s/'/\&apos;/g")
                echo "$error_details"
                
                echo '      </failure>'
                echo '    </testcase>'
              elif [[ "$test_result" == *"# SKIP"* ]]; then
                # Skipped test
                local skip_reason=$(echo "$test_result" | sed -E 's/.*# SKIP(.*)$/\1/' | sed 's/&/\&amp;/g' | sed 's/</\&lt;/g' | sed 's/>/\&gt;/g' | sed 's/"/\&quot;/g' | sed "s/'/\&apos;/g")
                echo '    <testcase classname="'"$file_name"'" name="'"$test_name"'" time="'"$test_time"'">'
                echo '      <skipped message="'"${skip_reason:-Test skipped}"'"/>'
                echo '    </testcase>'
              else
                # Passed test
                echo '    <testcase classname="'"$file_name"'" name="'"$test_name"'" time="'"$test_time"'"/>'
              fi
            done
          fi
          
          echo '  </testsuite>'
        fi
      fi
    done
    
    echo '</testsuites>'
  } > "$output_file"
}