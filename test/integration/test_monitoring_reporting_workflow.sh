#!/usr/bin/env bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# test_monitoring_reporting_workflow.sh
# Integration test for the complete MVNimble workflow:
# 1. Monitor a Maven build
# 2. Analyze the build data
# 3. Generate reports in all formats
#
# Usage:
#   ./test/integration/test_monitoring_reporting_workflow.sh

# Set strict mode
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Test directories
TEST_OUTPUT_DIR="${SCRIPT_DIR}/fixtures/workflow_test_output"
mkdir -p "$TEST_OUTPUT_DIR"

# Sample project directory
SAMPLE_PROJECT="${PROJECT_ROOT}/examples/simple-junit-project"
if [[ ! -d "$SAMPLE_PROJECT" ]]; then
  echo -e "${RED}Error: Sample project not found at ${SAMPLE_PROJECT}${RESET}"
  echo -e "This test requires the simple-junit-project example to be available."
  exit 1
fi

# Define paths for different stages
MONITORING_OUTPUT="${TEST_OUTPUT_DIR}/monitoring"
ANALYSIS_OUTPUT="${TEST_OUTPUT_DIR}/analysis.md"
HTML_REPORT="${TEST_OUTPUT_DIR}/report.html"
MD_REPORT="${TEST_OUTPUT_DIR}/report.md"
JSON_REPORT="${TEST_OUTPUT_DIR}/report.json"

# Remove previous test outputs if they exist
rm -rf "$TEST_OUTPUT_DIR"
mkdir -p "$TEST_OUTPUT_DIR"

echo -e "${BLUE}======= MVNimble Workflow Integration Test =======${RESET}"
echo -e "${YELLOW}Using sample project: ${SAMPLE_PROJECT}${RESET}"
echo -e "${YELLOW}Output directory: ${TEST_OUTPUT_DIR}${RESET}"

# Step 1: Monitor the Maven build
echo -e "\n${BLUE}Step 1: Monitoring Maven build${RESET}"
echo -e "${YELLOW}Command: ${PROJECT_ROOT}/bin/mvnimble monitor -o ${MONITORING_OUTPUT} -- cd ${SAMPLE_PROJECT} && mvn test${RESET}"

# Create monitoring output directory
mkdir -p "$MONITORING_OUTPUT"

# Run Maven in the sample project directory
(cd "$SAMPLE_PROJECT" && "$PROJECT_ROOT/bin/mvnimble" monitor -o "$MONITORING_OUTPUT" -i 2 -m 1 -- mvn test)

# Check if monitoring data was created
if [[ -f "${MONITORING_OUTPUT}/data.json" ]]; then
  echo -e "${GREEN}✓ Monitoring data successfully created${RESET}"
  # Show data file size
  DATA_SIZE=$(du -h "${MONITORING_OUTPUT}/data.json" | cut -f1)
  echo -e "  Monitoring data size: ${DATA_SIZE}"
else
  echo -e "${RED}✗ Failed to create monitoring data${RESET}"
  exit 1
fi

# Step 2: Analyze the build data
echo -e "\n${BLUE}Step 2: Analyzing build data${RESET}"
echo -e "${YELLOW}Command: ${PROJECT_ROOT}/bin/mvnimble analyze -i ${MONITORING_OUTPUT} -o ${ANALYSIS_OUTPUT}${RESET}"

"$PROJECT_ROOT/bin/mvnimble" analyze -i "$MONITORING_OUTPUT" -o "$ANALYSIS_OUTPUT"

# Check if analysis output was created
if [[ -f "$ANALYSIS_OUTPUT" ]]; then
  echo -e "${GREEN}✓ Analysis output successfully created${RESET}"
  # Show analysis file size
  ANALYSIS_SIZE=$(du -h "$ANALYSIS_OUTPUT" | cut -f1)
  echo -e "  Analysis file size: ${ANALYSIS_SIZE}"
else
  echo -e "${RED}✗ Failed to create analysis output${RESET}"
  exit 1
fi

# Step 3: Generate reports in all formats
echo -e "\n${BLUE}Step 3: Generating reports in all formats${RESET}"

# Generate HTML report
echo -e "${YELLOW}Generating HTML report...${RESET}"
"$PROJECT_ROOT/bin/mvnimble-report" -i "${MONITORING_OUTPUT}/data.json" -o "$HTML_REPORT" -f html

if [[ -f "$HTML_REPORT" ]]; then
  echo -e "${GREEN}✓ HTML report successfully created${RESET}"
  # Show HTML file size
  HTML_SIZE=$(du -h "$HTML_REPORT" | cut -f1)
  echo -e "  HTML report size: ${HTML_SIZE}"
else
  echo -e "${RED}✗ Failed to create HTML report${RESET}"
  exit 1
fi

# Generate Markdown report
echo -e "${YELLOW}Generating Markdown report...${RESET}"
"$PROJECT_ROOT/bin/mvnimble-report" -i "${MONITORING_OUTPUT}/data.json" -o "$MD_REPORT" -f markdown

if [[ -f "$MD_REPORT" ]]; then
  echo -e "${GREEN}✓ Markdown report successfully created${RESET}"
  # Show Markdown file size
  MD_SIZE=$(du -h "$MD_REPORT" | cut -f1)
  echo -e "  Markdown report size: ${MD_SIZE}"
else
  echo -e "${RED}✗ Failed to create Markdown report${RESET}"
  exit 1
fi

# Generate JSON report
echo -e "${YELLOW}Generating JSON report...${RESET}"
"$PROJECT_ROOT/bin/mvnimble-report" -i "${MONITORING_OUTPUT}/data.json" -o "$JSON_REPORT" -f json

if [[ -f "$JSON_REPORT" ]]; then
  echo -e "${GREEN}✓ JSON report successfully created${RESET}"
  # Show JSON file size
  JSON_SIZE=$(du -h "$JSON_REPORT" | cut -f1)
  echo -e "  JSON report size: ${JSON_SIZE}"
else
  echo -e "${RED}✗ Failed to create JSON report${RESET}"
  exit 1
fi

# Success message
echo -e "\n${GREEN}All workflow steps completed successfully!${RESET}"
echo -e "Test outputs available in: ${TEST_OUTPUT_DIR}"
echo -e "  Monitoring data: ${MONITORING_OUTPUT}/data.json"
echo -e "  Analysis report: ${ANALYSIS_OUTPUT}"
echo -e "  HTML report: ${HTML_REPORT}"
echo -e "  Markdown report: ${MD_REPORT}"
echo -e "  JSON report: ${JSON_REPORT}"