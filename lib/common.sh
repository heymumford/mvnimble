#!/usr/bin/env bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
#==============================================================================
# common.sh
#
# MVNimble - Common Utility Functions Module
#
# Description:
#   This module provides core utility functions that are used throughout 
#   MVNimble, including logging, error handling, and other common operations.
#
# Usage:
#   source "path/to/common.sh"
#   log_info "Starting process"
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

# Print an info message
function print_info() {
  local message="$1"
  echo -e "${COLOR_BLUE}${message}${COLOR_RESET}"
}

# Print a header
function print_header() {
  local message="$1"
  echo -e "${COLOR_BOLD}${COLOR_BLUE}=== ${message} ===${COLOR_RESET}"
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

# Check if a file exists
function file_exists() {
  local file="$1"
  [[ -f "$file" ]]
}

# Check if a directory exists
function directory_exists() {
  local dir="$1"
  [[ -d "$dir" ]]
}

# Get available memory in MB
function get_available_memory() {
  local mem_total
  
  if is_macos; then
    # macOS
    mem_total=$(sysctl -n hw.memsize 2>/dev/null)
    mem_total=$((mem_total / 1024 / 1024)) # Convert to MB
  elif is_linux; then
    # Linux
    mem_total=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')
    mem_total=$((mem_total / 1024)) # Convert from KB to MB
  else
    # Fallback
    mem_total=${DEFAULT_MEMORY_MB}
  fi
  
  echo "${mem_total:-${DEFAULT_MEMORY_MB}}"
}

# Get CPU cores count
function get_cpu_cores() {
  local cpu_count
  
  if is_macos; then
    # macOS
    cpu_count=$(sysctl -n hw.ncpu 2>/dev/null)
  elif is_linux; then
    # Linux
    cpu_count=$(nproc 2>/dev/null || grep -c processor /proc/cpuinfo 2>/dev/null)
  else
    # Fallback
    cpu_count=1
  fi
  
  echo "${cpu_count:-1}"
}

# Generate a timestamp in YYYY-MM-DD_HH-MM-SS format
function get_timestamp() {
  date +"%Y-%m-%d_%H-%M-%S"
}

# Clean up temporary files
function cleanup_temp_files() {
  local prefix="${1:-${TEMP_FILE_PREFIX}}"
  rm -f /tmp/${prefix}* 2>/dev/null || true
}

# Validate Maven project
function validate_maven_project() {
  if [ ! -f "pom.xml" ]; then
    print_error "No pom.xml found in current directory"
    print_info "MVNimble must be run from the root of a Maven project"
    return ${EXIT_VALIDATION_ERROR}
  fi
  return ${EXIT_SUCCESS}
}