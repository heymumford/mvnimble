#!/bin/bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# run_bats_tests.sh
# Comprehensive runner for BATS tests in the MVNimble project
#
# This script provides advanced test execution with filtering,
# reports, and statistics about test coverage and performance.
# It includes support for CI environments and automated testing.

set -e

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BATS_DIR="${SCRIPT_DIR}/bats"
TEST_RESULTS_DIR="${SCRIPT_DIR}/test_results"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
REPORT_FILE="${TEST_RESULTS_DIR}/test_report_${TIMESTAMP}.md"
JSON_REPORT_FILE="${TEST_RESULTS_DIR}/test_report_${TIMESTAMP}.json"
TAP_REPORT_FILE="${TEST_RESULTS_DIR}/test_report_${TIMESTAMP}.tap"
HTML_REPORT_FILE="${TEST_RESULTS_DIR}/test_report_${TIMESTAMP}.html"
JUNIT_REPORT_FILE="${TEST_RESULTS_DIR}/test_report_${TIMESTAMP}.xml"

# Detect CI environment automatically
if [ -n "$CI" ] || [ -n "$GITHUB_ACTIONS" ] || [ -n "$TRAVIS" ] || [ -n "$JENKINS_URL" ]; then
  DEFAULT_CI_MODE=true
else
  DEFAULT_CI_MODE=false
fi

# Define colors directly (avoiding readonly variable conflicts)
LOCAL_COLOR_BLUE='\033[0;34m'
LOCAL_COLOR_GREEN='\033[0;32m'
LOCAL_COLOR_RED='\033[0;31m'
LOCAL_COLOR_YELLOW='\033[0;33m'
LOCAL_COLOR_CYAN='\033[0;36m'
LOCAL_COLOR_BOLD='\033[1m'
LOCAL_COLOR_RESET='\033[0m'

# Parse command-line arguments
TAGS_INCLUDE=""
TAGS_EXCLUDE=""
VERBOSE=false
FAIL_FAST=false
CI_MODE=$DEFAULT_CI_MODE
SHOW_REPORT=true
NON_INTERACTIVE=false
TEST_DIR="${BATS_DIR}"
REPORT_FORMAT="markdown"  # Can be markdown, json, tap, html, or junit

# Display usage information
show_usage() {
    cat << EOF
MVNimble Test Runner

Usage: ${0} [OPTIONS]

Options:
  --tags TAGS            Only run tests with the specified tags (comma-separated)
  --exclude-tags TAGS    Skip tests with the specified tags (comma-separated)
  --test-dir DIR         Test directory to run (default: ${BATS_DIR})
  --verbose, -v          Show verbose output
  --fail-fast, -f        Stop on first test failure
  --ci                   CI mode (machine-readable output, no colors)
  --no-report            Don't generate or display the final report
  --non-interactive      Run in non-interactive mode (auto-install BATS if needed)
  --report FORMAT        Generate a report in the specified format (markdown, json, tap, html, junit)
  --help, -h             Show this help message

Examples:
  ${0} --tags functional,positive
  ${0} --exclude-tags nonfunctional
  ${0} --test-dir "${BATS_DIR}/unit"
  ${0} --verbose --fail-fast
  ${0} --non-interactive
  ${0} --report html

Report bugs to: https://github.com/mvnimble/mvnimble/issues
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --tags)
            TAGS_INCLUDE="${2//,/ }"
            shift 2
            ;;
        --exclude-tags)
            TAGS_EXCLUDE="${2//,/ }"
            shift 2
            ;;
        --test-dir)
            TEST_DIR="$2"
            shift 2
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --fail-fast|-f)
            FAIL_FAST=true
            shift
            ;;
        --ci)
            CI_MODE=true
            shift
            ;;
        --no-report)
            SHOW_REPORT=false
            shift
            ;;
        --report)
            REPORT_FORMAT="$2"
            if [[ ! "$REPORT_FORMAT" =~ ^(markdown|json|tap|html|junit)$ ]]; then
                echo "Invalid report format: $REPORT_FORMAT"
                echo "Valid formats: markdown, json, tap, html, junit"
                exit 1
            fi
            shift 2
            ;;
        --non-interactive)
            NON_INTERACTIVE=true
            shift
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Turn off colors in CI mode
if [ "$CI_MODE" = true ]; then
    LOCAL_COLOR_BLUE=""
    LOCAL_COLOR_GREEN=""
    LOCAL_COLOR_RED=""
    LOCAL_COLOR_YELLOW=""
    LOCAL_COLOR_CYAN=""
    LOCAL_COLOR_BOLD=""
    LOCAL_COLOR_RESET=""
fi

# Print section header
print_header() {
    local title="$1"
    echo -e "${LOCAL_COLOR_BOLD}${LOCAL_COLOR_BLUE}=== ${title} ===${LOCAL_COLOR_RESET}"
}

# Print success message
print_success() {
    local message="$1"
    echo -e "${LOCAL_COLOR_GREEN}✓ ${message}${LOCAL_COLOR_RESET}"
}

# Print failure message
print_failure() {
    local message="$1"
    echo -e "${LOCAL_COLOR_RED}✗ ${message}${LOCAL_COLOR_RESET}"
}

# Print info message
print_info() {
    local message="$1"
    echo -e "${LOCAL_COLOR_CYAN}${message}${LOCAL_COLOR_RESET}"
}

# Print warning message
print_warning() {
    local message="$1"
    echo -e "${LOCAL_COLOR_YELLOW}${message}${LOCAL_COLOR_RESET}"
}

# Create necessary directories
mkdir -p "$TEST_RESULTS_DIR"

# Check if BATS is installed
check_bats_installed() {
    # First check for bats executable
    if command -v bats >/dev/null 2>&1; then
        return 0
    fi
    
    # Check for bats executable in .local/bin (if it exists)
    if [[ -f "$HOME/.local/bin/bats" ]]; then
        export PATH="$HOME/.local/bin:$PATH"
        return 0
    fi
    
    # Not found
    return 1
}

# Install BATS locally
install_bats() {
    print_info "Installing BATS..."
    
    # Always install to .local/bin in the user's home directory
    INSTALL_PREFIX="$HOME/.local"
    mkdir -p "$INSTALL_PREFIX/bin"
    
    # Create a temporary directory for installation within the project
    TEMP_DIR="${PROJECT_ROOT}/tmp_bats_install"
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    # Clone BATS
    git clone https://github.com/bats-core/bats-core.git
    cd bats-core
    
    # Install to user's local directory
    ./install.sh "$INSTALL_PREFIX"
    
    # Add to PATH
    export PATH="$INSTALL_PREFIX/bin:$PATH"
    print_warning "Please add this line to your shell profile:"
    echo "export PATH=\"$INSTALL_PREFIX/bin:\$PATH\""
    
    # Clean up
    cd "$PROJECT_ROOT"
    rm -rf "$TEMP_DIR"
    
    print_success "BATS installed successfully!"
    return 0
}

# Find all BATS test files
find_bats_tests() {
    local test_dir="$1"
    find "$test_dir" -name "*.bats" | sort
}

# Count tests in a file
count_tests_in_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "0"
        return
    fi
    grep -c "@test" "$file" 2>/dev/null || echo "0"
}

# Parse tag metadata from test files
parse_tag_metadata() {
    local test_dir="$1"
    local metadata=()
    
    local test_files
    test_files=$(find_bats_tests "$test_dir")
    
    for file in $test_files; do
        if [[ ! -f "$file" ]]; then
            continue
        fi
        
        local file_name=$(basename "$file")
        local tests_count=$(count_tests_in_file "$file")
        
        # Skip if no tests found
        if [[ "$tests_count" -eq 0 ]]; then
            continue
        fi
        
        # Extract all tag lines from the file
        local tag_lines=$(grep -n "^# @" "$file" 2>/dev/null | cut -d':' -f1)
        
        # Get all test definition lines
        local test_lines=$(grep -n "@test" "$file" 2>/dev/null | cut -d':' -f1)
        
        # Process each test
        for test_line in $test_lines; do
            local test_name=$(sed -n "${test_line}p" "$file" 2>/dev/null | grep -o '"[^"]*"' | sed 's/"//g')
            
            # Find closest tag line before this test
            local closest_tag_line=0
            for tag_line in $tag_lines; do
                if [ "$tag_line" -lt "$test_line" ] && [ "$tag_line" -gt "$closest_tag_line" ]; then
                    closest_tag_line=$tag_line
                fi
            done
            
            # Get tags for this test
            local tags=""
            if [ "$closest_tag_line" -gt 0 ]; then
                tags=$(sed -n "${closest_tag_line}p" "$file" 2>/dev/null | grep -o '@[a-zA-Z0-9_-]*' || echo "")
            fi
            
            metadata+=("$file|$test_name|$tags")
        done
    done
    
    echo "${metadata[@]}"
}

# Run a single test file and capture results
run_test_file() {
    local file="$1"
    local tmp_output=$(mktemp)
    local start_time=$(date +%s.%N)
    
    # Run the test with BATS
    if [ "$CI_MODE" = true ]; then
        BATS_FLAGS="--tap"
    elif [ "$VERBOSE" = true ]; then
        BATS_FLAGS="--verbose"
    else
        BATS_FLAGS="--pretty"
    fi
    
    # Add fail-fast flag if specified
    if [ "$FAIL_FAST" = true ]; then
        BATS_FLAGS="$BATS_FLAGS --fail-fast"
    fi
    
    # Set BATS_TAGS environment variables for filtering
    export BATS_TAGS_INCLUDE="$TAGS_INCLUDE"
    export BATS_TAGS_EXCLUDE="$TAGS_EXCLUDE"
    
    # Run the test
    if bats $BATS_FLAGS "$file" > "$tmp_output" 2>&1; then
        local status=0
    else
        local status=$?
    fi
    
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc)
    
    # Parse the output
    local passed=$(grep -c "^ok " "$tmp_output" || echo 0)
    local failed=$(grep -c "^not ok " "$tmp_output" || echo 0)
    local skipped=$(grep -c "# skip" "$tmp_output" || echo 0)
    
    # Print the output in non-CI mode
    if [ "$CI_MODE" != true ]; then
        cat "$tmp_output"
    fi
    
    # Save the output and metadata
    local result_file="${TEST_RESULTS_DIR}/$(basename "$file").result"
    echo "status: $status" > "$result_file"
    echo "passed: $passed" >> "$result_file"
    echo "failed: $failed" >> "$result_file"
    echo "skipped: $skipped" >> "$result_file"
    echo "duration: $duration" >> "$result_file"
    cat "$tmp_output" >> "$result_file"
    
    # Clean up
    rm "$tmp_output"
    
    # Return test status
    return $status
}

# Generate a JUnit XML report
generate_junit_report() {
    local test_results_dir="$1"
    local output_file="$2"
    
    # First generate JSON for consistent data
    generate_json_report "$test_results_dir" "$JSON_REPORT_FILE"
    
    # Parse JSON report data for summary
    local total_tests=$(grep -o '"total": [0-9]*' "$JSON_REPORT_FILE" | grep -o '[0-9]*' | head -1)
    local passed_tests=$(grep -o '"passed": [0-9]*' "$JSON_REPORT_FILE" | grep -o '[0-9]*' | head -1)
    local failed_tests=$(grep -o '"failed": [0-9]*' "$JSON_REPORT_FILE" | grep -o '[0-9]*' | head -1)
    local skipped_tests=$(grep -o '"skipped": [0-9]*' "$JSON_REPORT_FILE" | grep -o '[0-9]*' | head -1)
    local duration=$(grep -o '"duration": [0-9.]*' "$JSON_REPORT_FILE" | grep -o '[0-9.]*' | head -1)
    
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

# Generate a detailed test report
generate_test_report() {
    local test_dir="$1"
    local tag_metadata=($2)
    
    # Source the report helpers
    source "${PROJECT_ROOT}/test/bats/common/report_helpers.bash"
    
    # For CI "all" format, generate all report types
    if [ "$REPORT_FORMAT" = "all" ]; then
        print_info "Generating all report formats for CI compatibility"
        
        # Generate JSON report
        generate_json_report "$TEST_RESULTS_DIR" "$JSON_REPORT_FILE"
        
        # Generate HTML report
        generate_html_report "$TEST_RESULTS_DIR" "$JSON_REPORT_FILE" "$HTML_REPORT_FILE"
        
        # Generate TAP report
        generate_tap_report "$TEST_RESULTS_DIR" "$TAP_REPORT_FILE"
        
        # Generate JUnit report
        generate_junit_report "$TEST_RESULTS_DIR" "$JUNIT_REPORT_FILE" "$JSON_REPORT_FILE"
        
        # Generate Markdown report
        generate_markdown_report "$JSON_REPORT_FILE" "$REPORT_FILE"
        
        # Export results to CI platform if in CI mode
        if [ "$CI_MODE" = true ]; then
            # Source the CI export helper
            source "${PROJECT_ROOT}/test/bats/common/ci_export.bash"
            export_ci_results "$JSON_REPORT_FILE" "$JUNIT_REPORT_FILE" "$TEST_RESULTS_DIR"
        fi
        
        echo "$HTML_REPORT_FILE"
        return
    fi
    
    # Generate report based on format
    case "$REPORT_FORMAT" in
        json)
            generate_json_report "$TEST_RESULTS_DIR" "$JSON_REPORT_FILE"
            
            # Export results to CI platform if in CI mode
            if [ "$CI_MODE" = true ]; then
                # Also generate JUnit for CI compatibility
                generate_junit_report "$TEST_RESULTS_DIR" "$JUNIT_REPORT_FILE" "$JSON_REPORT_FILE"
                
                # Source the CI export helper and export results
                source "${PROJECT_ROOT}/test/bats/common/ci_export.bash"
                export_ci_results "$JSON_REPORT_FILE" "$JUNIT_REPORT_FILE" "$TEST_RESULTS_DIR"
            fi
            
            echo "$JSON_REPORT_FILE"
            ;;
        html)
            # First generate the JSON report, then use it to create the HTML report
            generate_json_report "$TEST_RESULTS_DIR" "$JSON_REPORT_FILE"
            generate_html_report "$TEST_RESULTS_DIR" "$JSON_REPORT_FILE" "$HTML_REPORT_FILE"
            
            # Export results to CI platform if in CI mode
            if [ "$CI_MODE" = true ]; then
                # Also generate JUnit for CI compatibility
                generate_junit_report "$TEST_RESULTS_DIR" "$JUNIT_REPORT_FILE" "$JSON_REPORT_FILE"
                
                # Source the CI export helper and export results
                source "${PROJECT_ROOT}/test/bats/common/ci_export.bash"
                export_ci_results "$JSON_REPORT_FILE" "$JUNIT_REPORT_FILE" "$TEST_RESULTS_DIR"
            fi
            
            echo "$HTML_REPORT_FILE"
            ;;
        tap)
            # Generate TAP report
            generate_tap_report "$TEST_RESULTS_DIR" "$TAP_REPORT_FILE"
            
            # Export results to CI platform if in CI mode
            if [ "$CI_MODE" = true ]; then
                # Generate JSON and JUnit for CI compatibility
                generate_json_report "$TEST_RESULTS_DIR" "$JSON_REPORT_FILE"
                generate_junit_report "$TEST_RESULTS_DIR" "$JUNIT_REPORT_FILE" "$JSON_REPORT_FILE"
                
                # Source the CI export helper and export results
                source "${PROJECT_ROOT}/test/bats/common/ci_export.bash"
                export_ci_results "$JSON_REPORT_FILE" "$JUNIT_REPORT_FILE" "$TEST_RESULTS_DIR"
            fi
            
            echo "$TAP_REPORT_FILE"
            ;;
        junit)
            # Generate JSON report for data
            generate_json_report "$TEST_RESULTS_DIR" "$JSON_REPORT_FILE"
            
            # Generate JUnit XML report
            generate_junit_report "$TEST_RESULTS_DIR" "$JUNIT_REPORT_FILE" "$JSON_REPORT_FILE"
            
            # Export results to CI platform if in CI mode
            if [ "$CI_MODE" = true ]; then
                # Source the CI export helper and export results
                source "${PROJECT_ROOT}/test/bats/common/ci_export.bash"
                export_ci_results "$JSON_REPORT_FILE" "$JUNIT_REPORT_FILE" "$TEST_RESULTS_DIR"
            fi
            
            echo "$JUNIT_REPORT_FILE"
            ;;
        markdown|*)
            # Generate JSON first for consistent data
            generate_json_report "$TEST_RESULTS_DIR" "$JSON_REPORT_FILE"
            
            # Generate Markdown report
            generate_markdown_report "$JSON_REPORT_FILE" "$REPORT_FILE"
            
            # Export results to CI platform if in CI mode
            if [ "$CI_MODE" = true ]; then
                # Also generate JUnit for CI compatibility
                generate_junit_report "$TEST_RESULTS_DIR" "$JUNIT_REPORT_FILE" "$JSON_REPORT_FILE"
                
                # Source the CI export helper and export results
                source "${PROJECT_ROOT}/test/bats/common/ci_export.bash"
                export_ci_results "$JSON_REPORT_FILE" "$JUNIT_REPORT_FILE" "$TEST_RESULTS_DIR"
            fi
            
            echo "$REPORT_FILE"
            ;;
    esac
}

# Generate a TAP report
generate_tap_report() {
    local test_results_dir="$1"
    local output_file="$2"
    
    {
        echo "TAP version 13"
        
        # Combine all TAP outputs for total count
        local total_tests=0
        for result_file in "${test_results_dir}"/*.result; do
            if [ -f "$result_file" ]; then
                local file_passed=$(grep "passed: " "$result_file" | cut -d' ' -f2)
                local file_failed=$(grep "failed: " "$result_file" | cut -d' ' -f2)
                local file_skipped=$(grep "skipped: " "$result_file" | cut -d' ' -f2)
                local test_count=$((file_passed + file_failed + file_skipped))
                total_tests=$((total_tests + test_count))
            fi
        done
        
        echo "1..$total_tests"
        
        # Include all test results
        local test_number=1
        for result_file in "${test_results_dir}"/*.result; do
            if [ -f "$result_file" ]; then
                local file_name=$(basename "$result_file" .result)
                
                # Include passed tests
                for i in $(seq 1 $(grep "passed: " "$result_file" | cut -d' ' -f2)); do
                    echo "ok $test_number - $file_name #$i"
                    test_number=$((test_number + 1))
                done
                
                # Include failed tests
                for i in $(seq 1 $(grep "failed: " "$result_file" | cut -d' ' -f2)); do
                    echo "not ok $test_number - $file_name #$i"
                    test_number=$((test_number + 1))
                done
                
                # Include skipped tests
                for i in $(seq 1 $(grep "skipped: " "$result_file" | cut -d' ' -f2)); do
                    echo "ok $test_number - $file_name #$i # SKIP"
                    test_number=$((test_number + 1))
                done
            fi
        done
    } > "$output_file"
}

# Generate a Markdown report
generate_markdown_report() {
    local json_report="$1"
    local output_file="$2"
    
    # Parse JSON report data
    local total_tests=$(grep -o '"total": [0-9]*' "$json_report" | grep -o '[0-9]*' | head -1)
    local passed_tests=$(grep -o '"passed": [0-9]*' "$json_report" | grep -o '[0-9]*' | head -1)
    local failed_tests=$(grep -o '"failed": [0-9]*' "$json_report" | grep -o '[0-9]*' | head -1)
    local skipped_tests=$(grep -o '"skipped": [0-9]*' "$json_report" | grep -o '[0-9]*' | head -1)
    local duration=$(grep -o '"duration": [0-9.]*' "$json_report" | grep -o '[0-9.]*' | head -1)
    
    # Generate Markdown report
    {
        echo "# MVNimble Test Report"
        echo
        echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo
        echo "## Summary"
        echo
        echo "* Total Tests: $total_tests"
        echo "* Passed: $passed_tests"
        echo "* Failed: $failed_tests"
        echo "* Skipped: $skipped_tests"
        echo "* Duration: $(printf "%.2f" $duration) seconds"
        echo
        
        # Tag statistics
        echo "## Test Tags"
        echo
        
        local functional_count=$(grep -o '"functional": [0-9]*' "$json_report" | grep -o '[0-9]*')
        local nonfunctional_count=$(grep -o '"nonfunctional": [0-9]*' "$json_report" | grep -o '[0-9]*')
        local positive_count=$(grep -o '"positive": [0-9]*' "$json_report" | grep -o '[0-9]*')
        local negative_count=$(grep -o '"negative": [0-9]*' "$json_report" | grep -o '[0-9]*')
        
        echo "### By Category"
        echo
        echo "* Functional Tests: $functional_count"
        echo "* Non-Functional Tests: $nonfunctional_count"
        echo "* Positive Tests: $positive_count"
        echo "* Negative Tests: $negative_count"
        echo
        
        echo "### By ADR"
        echo
        for i in {0..5}; do
            local adr_count=$(grep -o "\"id\": \"ADR 00$i\", \"count\": [0-9]*" "$json_report" | grep -o '[0-9]*$')
            echo "* ADR 00$i: ${adr_count:-0} tests"
        done
        echo
        
        echo "### By Component"
        echo
        local components=("core" "platform" "dependency" "reporting" "package_manager" "env_detection")
        local component_names=("Core" "Platform" "Dependency" "Reporting" "Package Manager" "Environment Detection")
        
        for i in "${!components[@]}"; do
            local comp_count=$(grep -o "\"${components[$i]}\": [0-9]*" "$json_report" | grep -o '[0-9]*')
            echo "* ${component_names[$i]}: ${comp_count:-0} tests"
        done
        echo
        
        # Failed tests details
        if [ "$failed_tests" -gt 0 ]; then
            echo "## Failed Tests"
            echo
            
            # Extract failed tests
            local failed_test_list=$(grep -o '"failed_tests": \[[^]]*\]' "$json_report" | sed 's/"failed_tests": \[\|\]//g' | sed 's/"//g' | sed 's/,/ /g')
            
            for failed_test in $failed_test_list; do
                echo "### $failed_test"
                echo
                echo '```'
                grep -A 20 "not ok " "${TEST_RESULTS_DIR}/${failed_test}.result" | head -n 20
                echo '```'
                echo
            done
        fi
        
        # Test coverage analysis
        echo "## Coverage Analysis"
        echo
        
        # Check for ADRs without tests
        local untested_adrs=()
        for i in {0..5}; do
            local adr_count=$(grep -o "\"id\": \"ADR 00$i\", \"count\": [0-9]*" "$json_report" | grep -o '[0-9]*$')
            if [ -z "$adr_count" ] || [ "$adr_count" -eq 0 ]; then
                untested_adrs+=("ADR 00$i")
            fi
        done
        
        if [ ${#untested_adrs[@]} -gt 0 ]; then
            echo "### Untested ADRs"
            echo
            for adr in "${untested_adrs[@]}"; do
                echo "* $adr"
            done
            echo
        fi
        
        # Calculate test balance metrics
        echo "### Test Balance"
        echo
        
        if [ "$total_tests" -gt 0 ]; then
            local functional_percent=$((functional_count * 100 / total_tests))
            local positive_percent=$((positive_count * 100 / total_tests))
            
            echo "* Functional/Non-Functional: $functional_percent% / $((100 - functional_percent))%"
            echo "* Positive/Negative: $positive_percent% / $((100 - positive_percent))%"
        else
            echo "* No tests were executed"
        fi
        echo
        
        echo "## Performance Metrics"
        echo
        echo "* Total Execution Time: $(printf "%.2f" $duration) seconds"
        
        if [ "$total_tests" -gt 0 ]; then
            echo "* Average Test Time: $(printf "%.4f" $(echo "$duration / $total_tests" | bc -l)) seconds"
        else
            echo "* Average Test Time: N/A (no tests executed)"
        fi
        echo
        
        # CI Environment Information
        if [ "$CI_MODE" = true ]; then
            echo "## CI Environment"
            echo
            echo "* System: $(uname -s) $(uname -r) $(uname -m)"
            if [ -n "$GITHUB_ACTIONS" ]; then
                echo "* CI: GitHub Actions"
                echo "* Repository: $GITHUB_REPOSITORY"
                echo "* Branch: $GITHUB_REF"
                echo "* Commit: $GITHUB_SHA"
            elif [ -n "$TRAVIS" ]; then
                echo "* CI: Travis CI"
                echo "* Repository: $TRAVIS_REPO_SLUG"
                echo "* Branch: $TRAVIS_BRANCH"
                echo "* Commit: $TRAVIS_COMMIT"
            elif [ -n "$JENKINS_URL" ]; then
                echo "* CI: Jenkins"
                echo "* Job: $JOB_NAME"
                echo "* Build: $BUILD_NUMBER"
            else
                echo "* CI: Unknown CI system"
            fi
            echo
        fi
        
    } > "$output_file"
}

# Print the final report summary
print_report_summary() {
    local report_file="$1"
    
    if [ "$SHOW_REPORT" = false ]; then
        return 0
    fi
    
    print_header "Test Report Summary"
    
    # Count total failures from all test files
    local total_failures=0
    for result_file in "${TEST_RESULTS_DIR}"/*.result; do
        if [ -f "$result_file" ]; then
            local file_failed=$(grep "failed: " "$result_file" | cut -d' ' -f2)
            if [[ "$file_failed" =~ ^[0-9]+$ ]]; then
                total_failures=$((total_failures + file_failed))
            fi
        fi
    done
    
    # Count total tests run
    local total_tests="$TOTAL_RUNS"
    echo "Total Tests: $total_tests"
    
    # Calculate passed tests (total minus failures)
    local passed_tests=$((total_tests - total_failures))
    if [ "$passed_tests" -gt 0 ]; then
        print_success "Passed: $passed_tests"
    fi
    
    if [ "$total_failures" -gt 0 ]; then
        print_failure "Failed: $total_failures"
    fi
    
    echo
    
    if [ "$total_failures" -gt 0 ]; then
        print_failure "Some tests failed. See the detailed report for more information."
        echo "Report: $report_file"
    else
        print_success "All tests passed!"
        echo "Report: $report_file"
    fi
}

# Auto-enable non-interactive mode in CI environments
setup_ci_environment() {
    if [ "$CI_MODE" = true ] && [ "$NON_INTERACTIVE" != true ]; then
        print_info "CI environment detected. Enabling non-interactive mode automatically."
        NON_INTERACTIVE=true
    fi
    
    # Set appropriate defaults for CI
    if [ "$CI_MODE" = true ]; then
        # In CI, we want to save all report formats to provide maximum compatibility
        if [ "$REPORT_FORMAT" = "markdown" ]; then
            print_info "Setting report format to html,json,junit for CI compatibility"
            REPORT_FORMAT="all"
        fi
        
        # Make sure fail-fast is disabled in CI unless explicitly enabled
        if [ "$FAIL_FAST" != true ]; then
            print_info "Disabling fail-fast mode for comprehensive CI testing"
            FAIL_FAST=false
        fi
        
        # Set verbose output by default for CI
        if [ "$VERBOSE" != true ]; then
            VERBOSE=true
        fi
    fi
}

# Main function
main() {
    print_header "MVNimble Test Runner"
    
    # Set up CI environment if needed
    setup_ci_environment
    
    # Handle tag filters display
    if [ -n "$TAGS_INCLUDE" ]; then
        print_info "Only running tests with tags: ${TAGS_INCLUDE}"
    fi
    
    if [ -n "$TAGS_EXCLUDE" ]; then
        print_info "Excluding tests with tags: ${TAGS_EXCLUDE}"
    fi
    
    # Check if BATS is installed
    if ! check_bats_installed; then
        print_warning "BATS (Bash Automated Testing System) is required but not installed."
        
        if [ "$CI_MODE" = true ]; then
            # In CI environments, attempt automatic installation
            print_info "CI mode detected, attempting automatic BATS installation..."
            if ! install_bats; then
                print_failure "BATS installation failed in CI environment. Please update your CI configuration."
                exit 1
            fi
        elif [ "$NON_INTERACTIVE" = true ]; then
            print_info "Non-interactive mode: Installing BATS automatically..."
            if ! install_bats; then
                print_failure "BATS installation failed. Please install manually and try again."
                exit 1
            fi
        else
            print_info "Would you like to install BATS now? [Y/n]"
            read -r install_response
            
            if [[ ! "$install_response" =~ ^([nN][oO]|[nN])$ ]]; then
                if ! install_bats; then
                    print_failure "BATS installation failed. Please install manually and try again."
                    exit 1
                fi
            else
                print_failure "BATS is required to run tests. Exiting."
                exit 1
            fi
        fi
    fi
    
    # Check BATS version
    BATS_VERSION=$(bats --version | grep -o "[0-9][0-9.]*")
    print_info "Using BATS version $BATS_VERSION"
    
    # Find all test files
    if [[ ! -d "$TEST_DIR" ]]; then
        print_warning "Test directory $TEST_DIR does not exist"
        exit 0
    fi
    
    TEST_FILES=$(find_bats_tests "$TEST_DIR")
    TEST_COUNT=$(echo "$TEST_FILES" | wc -l | tr -d ' ')
    
    if [ "$TEST_COUNT" -eq 0 ]; then
        print_warning "No BATS test files found in ${TEST_DIR}"
        exit 0
    fi
    
    print_info "Found ${TEST_COUNT} BATS test files"
    
    # Parse tag metadata for reporting
    TAG_METADATA=$(parse_tag_metadata "$TEST_DIR")
    
    # Clean previous test results
    rm -f "${TEST_RESULTS_DIR}"/*.result
    
    # Run tests
    print_header "Running Tests"
    
    ALL_PASSED=true
    TOTAL_RUNS=0
    
    for test_file in $TEST_FILES; do
        file_name=$(basename "$test_file")
        print_info "Running $file_name..."
        
        if run_test_file "$test_file"; then
            TOTAL_RUNS=$((TOTAL_RUNS + 1))
        else
            ALL_PASSED=false
            TOTAL_RUNS=$((TOTAL_RUNS + 1))
            
            # Stop on first failure if fail-fast is enabled
            if [ "$FAIL_FAST" = true ]; then
                print_failure "Test failed. Stopping due to --fail-fast option."
                break
            fi
        fi
    done
    
    # Generate detailed report
    REPORT_FILE=$(generate_test_report "$TEST_DIR" "$TAG_METADATA")
    
    # Print report summary
    print_report_summary "$REPORT_FILE"
    
    # Exit with appropriate status
    if [ "$ALL_PASSED" = true ]; then
        exit 0
    else
        exit 1
    fi
}

# Run the script
main