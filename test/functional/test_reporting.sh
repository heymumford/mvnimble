#!/usr/bin/env bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# test_reporting.sh
# Test script for MVNimble reporting functionality
# Tests all three report formats (HTML, Markdown, JSON)
#
# Usage:
#   ./test/functional/test_reporting.sh
#
# This test verifies:
# - Generation of HTML reports
# - Generation of Markdown reports
# - Generation of JSON reports
# - Content verification of each report type

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

# Test data file
TEST_DATA="${SCRIPT_DIR}/fixtures/data.json"

# If test data doesn't exist in the fixtures directory, try the e2e directory
if [[ ! -f "$TEST_DATA" ]]; then
  ALTERNATE_DATA="${PROJECT_ROOT}/test_e2e/data.json"
  if [[ -f "$ALTERNATE_DATA" ]]; then
    mkdir -p "$(dirname "$TEST_DATA")"
    cp "$ALTERNATE_DATA" "$TEST_DATA"
  fi
fi

# Output directory and files
OUTPUT_DIR="${SCRIPT_DIR}/fixtures/output"
mkdir -p "$OUTPUT_DIR"

HTML_REPORT="${OUTPUT_DIR}/report.html"
MD_REPORT="${OUTPUT_DIR}/report.md"
JSON_REPORT="${OUTPUT_DIR}/report.json"

# Check if test data exists
if [[ ! -f "$TEST_DATA" ]]; then
  echo -e "${RED}Error: Test data file not found at ${TEST_DATA}${RESET}"
  exit 1
fi

# Clean up previous reports
rm -f "$HTML_REPORT" "$MD_REPORT" "$JSON_REPORT"

echo -e "${BLUE}======= MVNimble Reporting Test =======${RESET}"
echo -e "${YELLOW}Testing with data: ${TEST_DATA}${RESET}"

# Test main script report command
echo -e "\n${BLUE}Testing main mvnimble report command:${RESET}"
"$PROJECT_ROOT/bin/mvnimble" report -i "$TEST_DATA" -o "$HTML_REPORT" -f html
if [[ -f "$HTML_REPORT" ]]; then
  echo -e "${GREEN}✓ HTML report generated successfully${RESET}"
  HTML_SIZE=$(du -h "$HTML_REPORT" | cut -f1)
  echo -e "  Report size: ${HTML_SIZE}"
else
  echo -e "${RED}✗ HTML report failed to generate${RESET}"
  exit 1
fi

# Test specialized report script (markdown)
echo -e "\n${BLUE}Testing specialized mvnimble-report script (markdown):${RESET}"
"$PROJECT_ROOT/bin/mvnimble-report" -i "$TEST_DATA" -o "$MD_REPORT" -f markdown
if [[ -f "$MD_REPORT" ]]; then
  echo -e "${GREEN}✓ Markdown report generated successfully${RESET}"
  MD_SIZE=$(du -h "$MD_REPORT" | cut -f1)
  echo -e "  Report size: ${MD_SIZE}"
  
  # Check for key sections in markdown
  if grep -q "System Information" "$MD_REPORT" && grep -q "Darwin" "$MD_REPORT"; then
    echo -e "${GREEN}✓ Markdown report contains system information${RESET}"
  else
    echo -e "${RED}✗ Markdown report missing system information${RESET}"
    exit 1
  fi
else
  echo -e "${RED}✗ Markdown report failed to generate${RESET}"
  exit 1
fi

# Test specialized report script (JSON)
echo -e "\n${BLUE}Testing specialized mvnimble-report script (JSON):${RESET}"
"$PROJECT_ROOT/bin/mvnimble-report" -i "$TEST_DATA" -o "$JSON_REPORT" -f json
if [[ -f "$JSON_REPORT" ]]; then
  echo -e "${GREEN}✓ JSON report generated successfully${RESET}"
  JSON_SIZE=$(du -h "$JSON_REPORT" | cut -f1)
  echo -e "  Report size: ${JSON_SIZE}"
  
  # Check for valid JSON
  if jq . "$JSON_REPORT" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ JSON report is valid JSON${RESET}"
  else
    echo -e "${RED}✗ JSON report is not valid JSON${RESET}"
    exit 1
  fi
else
  echo -e "${RED}✗ JSON report failed to generate${RESET}"
  exit 1
fi

echo -e "\n${GREEN}All reporting tests passed!${RESET}"
echo -e "Reports generated in: ${OUTPUT_DIR}"
echo -e "  HTML: ${HTML_REPORT}"
echo -e "  Markdown: ${MD_REPORT}"
echo -e "  JSON: ${JSON_REPORT}"