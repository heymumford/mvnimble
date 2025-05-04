#!/bin/bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# test_error_handling.sh - Test module for error handling

# Source constants
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/constants.sh"

# Function with incomplete error handling (returns errors but no messages)
function incomplete_error_handling() {
  if [ ! -f "$1" ]; then
    return 1
  fi
  
  cat "$1"
  return 0
}

# Function with proper error handling
function proper_error_handling() {
  if [ ! -f "$1" ]; then
    echo "Error: File does not exist: $1" >&2
    return 1
  fi
  
  cat "$1"
  return 0
}
