#!/usr/bin/env bash
# MVNimble Simplified Test Runner
# Runs tests in the simplified test structure

# Ensure script fails on error
set -e

# Get directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SIMPLIFIED_TEST_DIR="${SCRIPT_DIR}/simplified"
TEST_RESULTS_DIR="${SCRIPT_DIR}/test_results"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
REPORT_FILE="${TEST_RESULTS_DIR}/test_report_${TIMESTAMP}.md"

# Define colors for output
COLOR_RED="\033[0;31m"
COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_BLUE="\033[0;34m"
COLOR_CYAN="\033[0;36m"
COLOR_BOLD="\033[1m"
COLOR_RESET="\033[0m"

# Parse command-line arguments
VERBOSE=false
FAIL_FAST=false
TEST_DIR="${SIMPLIFIED_TEST_DIR}"

# Print styled message
print_header() {
  echo -e "${COLOR_BOLD}${COLOR_BLUE}=== $1 ===${COLOR_RESET}"
}

print_success() {
  echo -e "${COLOR_GREEN}✓ $1${COLOR_RESET}"
}

print_failure() {
  echo -e "${COLOR_RED}✗ $1${COLOR_RESET}"
}

print_warning() {
  echo -e "${COLOR_YELLOW}! $1${COLOR_RESET}"
}

print_info() {
  echo -e "${COLOR_CYAN}$1${COLOR_RESET}"
}

# Display usage information
show_usage() {
  cat << EOF
MVNimble Simplified Test Runner

Usage: ${0} [OPTIONS]

Options:
  --dir DIR        Test directory to run (default: ${SIMPLIFIED_TEST_DIR})
  --file FILE      Run a specific test file
  --verbose, -v    Show verbose output
  --fail-fast, -f  Stop on first test failure
  --help, -h       Show this help message

Examples:
  ${0} --dir simplified/core
  ${0} --file simplified/core/constants_test.bats
  ${0} --verbose
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)
      if [[ "$2" = /* ]]; then
        TEST_DIR="$2"
      else
        TEST_DIR="${SCRIPT_DIR}/$2"
      fi
      shift 2
      ;;
    --file)
      if [[ "$2" = /* ]]; then
        TEST_FILE="$2"
      else
        TEST_FILE="${SCRIPT_DIR}/$2"
      fi
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

# Create necessary directories
mkdir -p "$TEST_RESULTS_DIR"

# Check if BATS is installed
check_bats_installed() {
  if command -v bats >/dev/null 2>&1; then
    return 0
  fi
  
  if [[ -f "$HOME/.local/bin/bats" ]]; then
    export PATH="$HOME/.local/bin:$PATH"
    return 0
  fi
  
  return 1
}

# Install BATS locally
install_bats() {
  print_info "Installing BATS..."
  
  # Install to .local/bin in the user's home directory
  INSTALL_PREFIX="$HOME/.local"
  mkdir -p "$INSTALL_PREFIX/bin"
  
  # Create a temporary directory for installation
  TEMP_DIR=$(mktemp -d)
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

# Find test files
find_test_files() {
  local search_dir="$1"
  if [ -n "$TEST_FILE" ]; then
    if [ -f "$TEST_FILE" ]; then
      echo "$TEST_FILE"
    else
      print_warning "Test file not found: $TEST_FILE"
      return 1
    fi
  else
    find "$search_dir" -name "*_test.bats" | sort
  fi
}

# Run a single test file
run_test_file() {
  local test_file="$1"
  local file_name=$(basename "$test_file")
  local result_file="${TEST_RESULTS_DIR}/${file_name}.result"
  
  print_info "Running $file_name..."
  
  # Set BATS flags based on options
  if [ "$VERBOSE" = true ]; then
    BATS_FLAGS="--verbose"
  else
    BATS_FLAGS="--pretty"
  fi
  
  # Add fail-fast flag if specified
  if [ "$FAIL_FAST" = true ]; then
    BATS_FLAGS="$BATS_FLAGS --fail-fast"
  fi
  
  # Run the test with BATS
  if bats $BATS_FLAGS "$test_file" | tee "$result_file"; then
    return 0
  else
    return 1
  fi
}

# Generate a test report
generate_test_report() {
  local test_results_dir="$1"
  local output_file="$2"
  
  {
    echo "# MVNimble Test Report"
    echo
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo
    
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    
    # Process each result file
    for result_file in "${test_results_dir}"/*.result; do
      if [ -f "$result_file" ]; then
        local file_name=$(basename "$result_file" .result)
        local file_passed=$(grep -c "^ok " "$result_file" || echo 0)
        local file_failed=$(grep -c "^not ok " "$result_file" || echo 0)
        
        total_tests=$((total_tests + file_passed + file_failed))
        passed_tests=$((passed_tests + file_passed))
        failed_tests=$((failed_tests + file_failed))
      fi
    done
    
    echo "## Summary"
    echo
    echo "* Total Tests: $total_tests"
    echo "* Passed: $passed_tests"
    echo "* Failed: $failed_tests"
    echo
    
    # List failed tests if any
    if [ "$failed_tests" -gt 0 ]; then
      echo "## Failed Tests"
      echo
      
      for result_file in "${test_results_dir}"/*.result; do
        if [ -f "$result_file" ]; then
          local file_name=$(basename "$result_file" .result)
          
          # Check for failures in this file
          if grep -q "^not ok " "$result_file"; then
            echo "### $file_name"
            echo
            echo '```'
            grep -n -A 2 "^not ok " "$result_file"
            echo '```'
            echo
          fi
        fi
      done
    fi
    
  } > "$output_file"
  
  echo "$output_file"
}

# Main function
main() {
  print_header "MVNimble Simplified Test Runner"
  
  # Check if BATS is installed
  if ! check_bats_installed; then
    print_warning "BATS (Bash Automated Testing System) is required but not installed."
    
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
  
  # Check BATS version
  BATS_VERSION=$(bats --version | grep -o "[0-9][0-9.]*")
  print_info "Using BATS version $BATS_VERSION"
  
  # Find test files
  TEST_FILES=$(find_test_files "$TEST_DIR")
  TEST_COUNT=$(echo "$TEST_FILES" | wc -l | tr -d ' ')
  
  if [ "$TEST_COUNT" -eq 0 ]; then
    print_warning "No test files found in ${TEST_DIR}"
    exit 0
  fi
  
  print_info "Found ${TEST_COUNT} test files"
  
  # Clean previous test results
  rm -f "${TEST_RESULTS_DIR}"/*.result
  
  # Run tests
  print_header "Running Tests"
  
  ALL_PASSED=true
  
  for test_file in $TEST_FILES; do
    if ! run_test_file "$test_file"; then
      ALL_PASSED=false
      
      # Stop on first failure if fail-fast is enabled
      if [ "$FAIL_FAST" = true ]; then
        print_failure "Test failed. Stopping due to --fail-fast option."
        break
      fi
    fi
  done
  
  # Generate test report
  REPORT_FILE=$(generate_test_report "$TEST_RESULTS_DIR" "$REPORT_FILE")
  
  # Print summary
  print_header "Test Results"
  
  if [ "$ALL_PASSED" = true ]; then
    print_success "All tests passed!"
  else
    print_failure "Some tests failed. See the report for details."
  fi
  
  print_info "Report: $REPORT_FILE"
  
  # Exit with appropriate status
  if [ "$ALL_PASSED" = true ]; then
    exit 0
  else
    exit 1
  fi
}

# Run the script
main