#!/usr/bin/env bash
# Script to run MVNimble on the Checkvox project using the simplified installation

set -e

# Path configurations
MVNIMBLE_INSTALL_DIR="/Users/vorthruna/Code/mvnimble/test-install"
MONITOR_SCRIPT="${MVNIMBLE_INSTALL_DIR}/bin/monitor-checkvox.sh"

# Print header with color
echo -e "\033[1;34m=== Running MVNimble on Checkvox ===\033[0m"
echo -e "\033[0;33mInstallation directory: ${MVNIMBLE_INSTALL_DIR}\033[0m"
echo -e "\033[0;33mMonitor script: ${MONITOR_SCRIPT}\033[0m"

# Check if the script exists
if [ ! -f "$MONITOR_SCRIPT" ]; then
  echo -e "\033[0;31mError: Monitor script not found at ${MONITOR_SCRIPT}\033[0m"
  exit 1
fi

# Make sure the script is executable
chmod +x "$MONITOR_SCRIPT"

# Run the monitor script
echo -e "\n\033[1;34m=== Running the monitor-checkvox.sh script ===\033[0m"
"$MONITOR_SCRIPT"

echo -e "\n\033[1;32m✓ Checkvox analysis complete!\033[0m"
echo -e "\033[0;33mResults are available in: ${MVNIMBLE_INSTALL_DIR}/results/checkvox\033[0m"
echo -e "\033[0;33mView the HTML report at: ${MVNIMBLE_INSTALL_DIR}/results/checkvox/report.html\033[0m"
echo -e "\033[0;33mView the analysis at: ${MVNIMBLE_INSTALL_DIR}/results/checkvox/analysis.md\033[0m"