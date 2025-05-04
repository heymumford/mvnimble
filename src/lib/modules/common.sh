#!/usr/bin/env bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
#==============================================================================
# common.sh
#
# MVNimble - Common Utility Functions Module
#
# Description:
#   This module provides core utility functions that are used throughout 
#   MVNimble. It includes essential functionality like logging, error handling,
#   input validation, and other common operations needed by multiple modules.
#
# Functions:
#   - Logging (debug, info, warning, error)
#   - Input validation and sanitization
#   - File operations
#   - String manipulation
#   - Error handling
#
# Usage:
#   source "path/to/common.sh"
#   log_info "Starting process"
#   validate_input "$user_input"
#   handle_error "$error_code" "$error_message"
#
# Dependencies:
#   - constants.sh
#
# Author: MVNimble Team
# Version: 1.0.1
# Last Updated: 2025-05-04
#==============================================================================

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source constants module
if [[ -z "${CONSTANTS_LOADED+x}" ]]; then
  source "${SCRIPT_DIR}/constants.sh"
fi

# Print a message to standard output
function print_message() {
  local message="$1"
  echo "$message"
}

# Print a message to standard error
function print_error() {
  local message="$1"
  echo -e "${COLOR_RED}Error: ${message}${COLOR_RESET}" >&2
}

# Print a warning message
function print_warning() {
  local message="$1"
  echo -e "${COLOR_YELLOW}Warning: ${message}${COLOR_RESET}" >&2
}

# Print a success message
function print_success() {
  local message="$1"
  echo -e "${COLOR_GREEN}${message}${COLOR_RESET}"
}

# Check if a command exists
function command_exists() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1
}

# Get the operating system type
function get_os_type() {
  local os
  os="$(uname -s)"
  echo "$os"
}

# Check if running on macOS
function is_macos() {
  [[ "$(get_os_type)" == "Darwin" ]]
}

# Check if running on Linux
function is_linux() {
  [[ "$(get_os_type)" == "Linux" ]]
}

# Create directory if it doesn't exist
function ensure_directory() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
  fi
}
