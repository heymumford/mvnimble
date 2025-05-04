#!/bin/bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# shellcheck_wrapper.sh
# MVNimble - ShellCheck integration utilities
#
# This module provides functions for running ShellCheck on shell scripts
# and handling ShellCheck installation if needed.

# Source constants and package manager utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=constants.sh
source "${SCRIPT_DIR}/constants.sh"
# shellcheck source=package_manager.sh
source "${SCRIPT_DIR}/package_manager.sh"

# Check if ShellCheck is installed
is_shellcheck_installed() {
  command -v shellcheck >/dev/null 2>&1
  return $?
}

# Get ShellCheck version
get_shellcheck_version() {
  if ! is_shellcheck_installed; then
    echo "0.0.0"
    return 1
  fi
  
  local version
  version=$(shellcheck --version | grep "version:" | awk '{print $2}')
  echo "$version"
}

# Check if ShellCheck version meets minimum requirement
check_shellcheck_version() {
  local min_version="$1"
  local current_version
  
  current_version=$(get_shellcheck_version)
  
  # Simple version comparison for format like 0.7.0
  local current_major current_minor current_patch
  local min_major min_minor min_patch
  
  # Extract components of current version
  current_major=$(echo "$current_version" | cut -d. -f1)
  current_minor=$(echo "$current_version" | cut -d. -f2)
  current_patch=$(echo "$current_version" | cut -d. -f3)
  
  # Extract components of minimum version
  min_major=$(echo "$min_version" | cut -d. -f1)
  min_minor=$(echo "$min_version" | cut -d. -f2)
  min_patch=$(echo "$min_version" | cut -d. -f3)
  
  # Compare versions
  if [ "$current_major" -lt "$min_major" ]; then
    return 1
  elif [ "$current_major" -eq "$min_major" ] && [ "$current_minor" -lt "$min_minor" ]; then
    return 1
  elif [ "$current_major" -eq "$min_major" ] && [ "$current_minor" -eq "$min_minor" ] && [ "$current_patch" -lt "$min_patch" ]; then
    return 1
  fi
  
  return 0
}

# Run ShellCheck on a file with standard options
run_shellcheck() {
  local file="$1"
  local severity="${2:-style}"  # Default to style (info) level
  
  # Ensure ShellCheck is installed
  if ! is_shellcheck_installed; then
    echo "ShellCheck is not installed. Cannot validate shell scripts." >&2
    install_shellcheck false
    return 1
  fi
  
  # Check if file exists
  if [ ! -f "$file" ]; then
    echo "File not found: $file" >&2
    return 1
  fi
  
  # Run ShellCheck with specified severity
  shellcheck -S "$severity" "$file"
  return $?
}

# Run ShellCheck on all .sh files in a directory recursively
run_shellcheck_recursive() {
  local dir="$1"
  local severity="${2:-style}"
  local exclude_pattern="${3:-}"
  local files_checked=0
  local files_with_issues=0
  
  # Ensure ShellCheck is installed
  if ! is_shellcheck_installed; then
    echo "ShellCheck is not installed. Cannot validate shell scripts." >&2
    install_shellcheck false
    return 1
  fi
  
  # Check if directory exists
  if [ ! -d "$dir" ]; then
    echo "Directory not found: $dir" >&2
    return 1
  fi
  
  echo "Running ShellCheck on shell scripts in $dir..."
  
  # Find all .sh files, excluding any that match the exclude pattern
  while IFS= read -r -d '' file; do
    # Skip excluded files
    if [ -n "$exclude_pattern" ] && echo "$file" | grep -q "$exclude_pattern"; then
      echo "Skipping excluded file: $file"
      continue
    fi
    
    echo "Checking: $file"
    run_shellcheck "$file" "$severity"
    if [ $? -ne 0 ]; then
      ((files_with_issues++))
    fi
    ((files_checked++))
  done < <(find "$dir" -type f -name "*.sh" -print0)
  
  # Print summary
  echo "ShellCheck completed: $files_checked files checked, $files_with_issues files with issues"
  
  if [ "$files_with_issues" -gt 0 ]; then
    return 1
  else
    return 0
  fi
}

# Self-validate this script and dependent modules
self_validate() {
  local severity="${1:-style}"
  
  echo "Self-validating MVNimble shell scripts..."
  
  # Ensure ShellCheck is installed
  if ! is_shellcheck_installed; then
    echo "ShellCheck is not installed. Cannot validate shell scripts." >&2
    install_shellcheck true
    if [ $? -ne 0 ]; then
      return 1
    fi
  fi
  
  # Get the src/lib directory
  local lib_dir
  lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  
  # Run ShellCheck on all shell scripts in the src/lib directory
  run_shellcheck_recursive "$lib_dir" "$severity"
  return $?
}