#!/usr/bin/env bash
# Script to run MVNimble on the Checkvox project
# Uses the symlink-free installation we created

set -e

# Path configurations
MVNIMBLE_INSTALL_DIR="/Users/vorthruna/Code/mvnimble/test-install"
CHECKVOX_PROJECT_DIR="/Users/vorthruna/Code/checkvox"
RESULTS_DIR="${CHECKVOX_PROJECT_DIR}/mvnimble-results"

# Ensure results directory exists
mkdir -p "$RESULTS_DIR"

# Print header with color
echo -e "\033[1;34m=== Running MVNimble on Checkvox ===\033[0m"
echo -e "\033[0;33mInstallation directory: ${MVNIMBLE_INSTALL_DIR}\033[0m"
echo -e "\033[0;33mProject directory: ${CHECKVOX_PROJECT_DIR}\033[0m"
echo -e "\033[0;33mResults will be saved to: ${RESULTS_DIR}\033[0m"

# Run monitoring
echo -e "\n\033[1;34m=== Step 1: Monitoring Maven Build ===\033[0m"
"${MVNIMBLE_INSTALL_DIR}/bin/mvnimble" monitor \
  --output "${RESULTS_DIR}" \
  --interval 5 \
  --max-time 10 \
  -- mvn clean test -DskipITs

# Run analysis on the monitoring results
echo -e "\n\033[1;34m=== Step 2: Analyzing Build Results ===\033[0m"
"${MVNIMBLE_INSTALL_DIR}/bin/mvnimble" analyze \
  --input "${RESULTS_DIR}" \
  --output "${RESULTS_DIR}/analysis.md" \
  --format markdown \
  --pom "${CHECKVOX_PROJECT_DIR}/pom.xml"

# Generate report
echo -e "\n\033[1;34m=== Step 3: Generating Report ===\033[0m"
"${MVNIMBLE_INSTALL_DIR}/bin/mvnimble" report \
  --input "${RESULTS_DIR}/data.json" \
  --output "${RESULTS_DIR}/report" \
  --format "markdown,html"

echo -e "\n\033[1;32m✓ Analysis complete!\033[0m"
echo -e "\033[0;33mResults are available in: ${RESULTS_DIR}\033[0m"
echo -e "\033[0;33mView the HTML report at: ${RESULTS_DIR}/report.html\033[0m"
echo -e "\033[0;33mView the Markdown report at: ${RESULTS_DIR}/report.md\033[0m"