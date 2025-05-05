#!/usr/bin/env bash
# MVNimble Demo Script
# Demonstrates the usage of MVNimble with a simple Maven project

# Ensure script fails on error
set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
EXAMPLE_PROJECT="$SCRIPT_DIR/simple-junit-project"
RESULTS_DIR="$SCRIPT_DIR/results"

# Make sure MVNimble is in the PATH
export PATH="$PROJECT_ROOT/bin:$PATH"

# Print styled header
function print_header() {
  echo -e "\n\033[1;34m=== $1 ===\033[0m\n"
}

# Cleanup previous results
rm -rf "$RESULTS_DIR"
mkdir -p "$RESULTS_DIR"

# Navigate to the example project
cd "$EXAMPLE_PROJECT"

print_header "Running MVNimble Demo"
echo "Using example project: $EXAMPLE_PROJECT"
echo "Results will be saved to: $RESULTS_DIR"

# Step 1: Verify the environment
print_header "Step 1: Verifying Environment"
mvnimble verify

# Step 2: Monitor a Maven build
print_header "Step 2: Monitoring Maven Build"
echo "Running: mvnimble monitor -o $RESULTS_DIR -- mvn clean test"
mvnimble monitor -o "$RESULTS_DIR" -- mvn clean test

# Step 3: Analyze the build results
print_header "Step 3: Analyzing Build Results"
echo "Running: mvnimble analyze -i $RESULTS_DIR -o $RESULTS_DIR/analysis.md"
mvnimble analyze -i "$RESULTS_DIR" -o "$RESULTS_DIR/analysis.md"

# Step 4: Generate an HTML report
print_header "Step 4: Generating HTML Report"
echo "Running: mvnimble report -i $RESULTS_DIR/data.json -o $RESULTS_DIR/report.html -f html"
mvnimble report -i "$RESULTS_DIR/data.json" -o "$RESULTS_DIR/report.html" -f html

print_header "Demo Complete"
echo "Results are available in: $RESULTS_DIR"
echo "- Analysis: $RESULTS_DIR/analysis.md"
echo "- Report: $RESULTS_DIR/report.html"
echo ""
echo "Try the specialized scripts as well:"
echo "- mvnimble-monitor -o ./results -- mvn clean test"
echo "- mvnimble-analyze -i ./results -o ./analysis.html -f html"