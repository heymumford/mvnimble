#!/usr/bin/env bash
# MVNimble Checkvox Monitoring Script
# Monitors and analyzes the Checkvox project using the simplified MVNimble structure

# Set strict mode
set -e

# Get directory paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CHECKVOX_DIR="/Users/vorthruna/Code/Checkvox"
RESULTS_DIR="${PROJECT_ROOT}/results/checkvox"

# Colors for output
COLOR_RED="\033[0;31m"
COLOR_GREEN="\033[0;32m"
COLOR_BLUE="\033[0;34m"
COLOR_YELLOW="\033[0;33m"
COLOR_BOLD="\033[1m"
COLOR_RESET="\033[0m"

# Print styled message
print_header() {
  echo -e "${COLOR_BOLD}${COLOR_BLUE}=== $1 ===${COLOR_RESET}"
}

print_success() {
  echo -e "${COLOR_GREEN}✓ $1${COLOR_RESET}"
}

print_error() {
  echo -e "${COLOR_RED}✗ $1${COLOR_RESET}"
}

print_warning() {
  echo -e "${COLOR_YELLOW}! $1${COLOR_RESET}"
}

print_info() {
  echo -e "${COLOR_BLUE}$1${COLOR_RESET}"
}

# Check if Checkvox directory exists
if [ ! -d "$CHECKVOX_DIR" ]; then
  print_error "Checkvox directory not found at: $CHECKVOX_DIR"
  exit 1
fi

# Create results directory
mkdir -p "${RESULTS_DIR}"

# Print header
print_header "MVNimble Test Engineering Tricorder"
print_info "Running real-time monitoring on Checkvox project"
print_info "Checkvox location: ${CHECKVOX_DIR}"
print_info "Results directory: ${RESULTS_DIR}"
echo

# Run monitoring using the simplified mvnimble structure
print_header "Starting MVNimble Monitoring"

# Change to Checkvox directory
cd "$CHECKVOX_DIR" || {
  print_error "Could not change to Checkvox directory"
  exit 1
}

# Run the monitor command with Maven test 
print_info "Running: mvnimble monitor -o ${RESULTS_DIR} -- mvn test -DforkCount=1 -Dgroups=\"UnitTest\" -DexcludedGroups=\"SlowTest,IntegrationTest,PerformanceTest\""

# Use the mvnimble script from our bin directory
"${SCRIPT_DIR}/mvnimble" monitor -o "${RESULTS_DIR}" -i 2 -m 15 -- mvn test -DforkCount=1 -Dgroups="UnitTest" -DexcludedGroups="SlowTest,IntegrationTest,PerformanceTest"

# Check if monitoring was successful
if [ $? -eq 0 ]; then
  print_success "Checkvox test monitoring completed successfully"
else
  print_error "Checkvox test monitoring failed"
  exit 1
fi

# Run analysis on the collected data
print_header "Analyzing Build Results"

# Use the analyze script from our bin directory
"${SCRIPT_DIR}/mvnimble" analyze -i "${RESULTS_DIR}" -o "${RESULTS_DIR}/analysis.md" -f markdown -p "${CHECKVOX_DIR}/pom.xml"

# Check if analysis was successful
if [ $? -eq 0 ]; then
  print_success "Checkvox test analysis completed successfully"
else
  print_error "Checkvox test analysis failed"
  exit 1
fi

# Generate an HTML report
print_header "Generating HTML Report"

# Use the report command to generate an HTML report
"${SCRIPT_DIR}/mvnimble" report -i "${RESULTS_DIR}/data.json" -o "${RESULTS_DIR}/report.html" -f html

# Check if report generation was successful
if [ $? -eq 0 ]; then
  print_success "HTML report generated successfully"
else
  print_error "HTML report generation failed"
  exit 1
fi

# Final summary
print_header "Monitoring and Analysis Complete"
print_info "Results available in: ${RESULTS_DIR}"
print_info "Report files:"
print_info "  - ${RESULTS_DIR}/analysis.md (Build Analysis)"
print_info "  - ${RESULTS_DIR}/report.html (HTML Report)"
print_info "  - ${RESULTS_DIR}/data.json (Raw Data)"

echo
print_success "MVNimble has successfully monitored and analyzed the Checkvox build"