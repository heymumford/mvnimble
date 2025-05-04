#!/bin/bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# test_adr_000_adr_process.sh
# Tests for ADR 000: ADR Process for QA Empowerment
#
# This test suite validates that the ADR process is correctly implemented
# and that all ADRs follow the specified format and guidelines.

# Source test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./test.sh
source "${SCRIPT_DIR}/test.sh"

# Function to validate ADR file format
function validate_adr_format() {
  local adr_file="$1"
  local adr_title="$(grep "^# ADR [0-9]" "$adr_file" || true)"
  local has_status="$(grep -E "^## Status" "$adr_file" || true)"
  local has_context="$(grep -E "^## Context" "$adr_file" || true)"
  local has_decision="$(grep -E "^## Decision" "$adr_file" || true)"
  local has_consequences="$(grep -E "^## Consequences" "$adr_file" || true)"
  
  # Check if file has a valid ADR title
  if [[ -z "$adr_title" ]]; then
    echo "Missing ADR title in $(basename "$adr_file")"
    return 1
  fi
  
  # Check for required sections
  if [[ -z "$has_status" ]]; then
    echo "Missing Status section in $(basename "$adr_file")"
    return 1
  fi
  
  if [[ -z "$has_context" ]]; then
    echo "Missing Context section in $(basename "$adr_file")"
    return 1
  fi
  
  if [[ -z "$has_decision" ]]; then
    echo "Missing Decision section in $(basename "$adr_file")"
    return 1
  fi
  
  if [[ -z "$has_consequences" ]]; then
    echo "Missing Consequences section in $(basename "$adr_file")"
    return 1
  fi
  
  return 0
}

# Test that ADR directory exists
test_adr_directory_exists() {
  assert_directory_exists "${SCRIPT_DIR}/../doc/adr" "ADR directory should exist"
}

# Test that ADR 000 exists and defines the ADR process
test_adr_000_exists() {
  assert_file_exists "${SCRIPT_DIR}/../doc/adr/000-adr-process-qa-empowerment.md" "ADR 000 file should exist"
}

# Test that ADR format is valid for ADR 000
test_adr_000_format() {
  validate_adr_format "${SCRIPT_DIR}/../doc/adr/000-adr-process-qa-empowerment.md"
}

# Test that all ADRs follow the required format
test_all_adrs_follow_format() {
  # Find all ADR files
  local adr_files=("${SCRIPT_DIR}"/../doc/adr/[0-9]*.md)
  local all_valid=0
  
  for adr_file in "${adr_files[@]}"; do
    if ! validate_adr_format "$adr_file"; then
      all_valid=1
    fi
  done
  
  return $all_valid
}

# Test that ADR file naming follows convention (NNN-kebab-case.md)
test_adr_file_naming_convention() {
  # Find all ADR files
  local adr_files=("${SCRIPT_DIR}"/../doc/adr/[0-9]*.md)
  local all_valid=0
  
  for adr_file in "${adr_files[@]}"; do
    local filename="$(basename "$adr_file")"
    
    # Check if file follows NNN-kebab-case.md pattern
    if ! [[ "$filename" =~ ^[0-9]{3}-[a-z0-9-]+\.md$ ]]; then
      echo "Invalid ADR filename format: $filename"
      all_valid=1
    fi
  done
  
  return $all_valid
}

# Test that ADR numbers are sequential without gaps
test_adr_sequential_numbering() {
  # Get list of ADR numbers
  local adr_files=("${SCRIPT_DIR}"/../doc/adr/[0-9]*.md)
  local numbers=()
  
  for adr_file in "${adr_files[@]}"; do
    local filename="$(basename "$adr_file")"
    local num="${filename:0:3}"
    numbers+=("$num")
  done
  
  # Sort the numbers
  IFS=$'\n' sorted_numbers=($(sort -n <<<"${numbers[*]}"))
  unset IFS
  
  # Check for gaps
  local last_num="-1"
  for num in "${sorted_numbers[@]}"; do
    local expected=$((10#$last_num + 1))
    local num_val=$((10#$num))
    
    # Convert to decimal to avoid octal interpretation of numbers with leading zeros
    if [[ $num_val -ne 0 && $expected -ne $num_val ]]; then
      echo "Gap in ADR numbering: expected $expected, found $num"
      return 1
    fi
    
    last_num="$num"
  done
  
  return 0
}

# Test that ADR status values are valid
test_adr_status_values() {
  local adr_files=("${SCRIPT_DIR}"/../doc/adr/[0-9]*.md)
  local all_valid=0
  
  for adr_file in "${adr_files[@]}"; do
    local filename="$(basename "$adr_file")"
    local status="$(grep -A 1 "^## Status" "$adr_file" | tail -1 | xargs)"
    
    # Check if status is one of the valid options
    case "$status" in
      Proposed|Accepted|Deprecated|Superseded)
        # Valid status
        ;;
      *)
        echo "Invalid ADR status in $filename: $status"
        all_valid=1
        ;;
    esac
  done
  
  return $all_valid
}

# Run the tests if this file is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_all_tests "$(basename "${BASH_SOURCE[0]}")"
fi