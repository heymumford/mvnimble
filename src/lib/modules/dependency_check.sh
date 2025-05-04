#!/bin/bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# dependency_check.sh
# MVNimble - Dependency validation and environment checks
#
# This module provides functions to verify that all required
# dependencies and environment conditions are met before running
# MVNimble operations.

# Source constants and package manager module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=constants.sh
if [[ -z "${CONSTANTS_LOADED+x}" ]]; then
  source "${SCRIPT_DIR}/constants.sh"
fi
# shellcheck source=package_manager.sh
source "${SCRIPT_DIR}/package_manager.sh"

# Verify shell environment
verify_shell_environment() {
  # Check for bash
  if [ -z "$BASH_VERSION" ]; then
    echo "WARNING: MVNimble is designed for bash shell." >&2
    echo "Current shell doesn't appear to be bash. You may encounter issues." >&2
    return 0  # Continue execution with a warning
  fi
  
  # Check bash version
  local bash_major_version="${BASH_VERSINFO[0]}"
  local bash_minor_version="${BASH_VERSINFO[1]}"
  
  if [ "$bash_major_version" -lt 3 ] || { [ "$bash_major_version" -eq 3 ] && [ "$bash_minor_version" -lt 2 ]; }; then
    echo "WARNING: MVNimble works best with bash 3.2 or higher." >&2
    echo "Current version: $BASH_VERSION" >&2
    echo "You may encounter issues with some features." >&2
    # Continue execution with a warning
  fi
  
  return 0
}

# Verify essential commands are available
verify_essential_commands() {
  local missing_commands=()
  
  for cmd in $ESSENTIAL_COMMANDS; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing_commands+=("$cmd")
    fi
  done
  
  if [ ${#missing_commands[@]} -gt 0 ]; then
    echo "ERROR: Missing essential commands: ${missing_commands[*]}" >&2
    echo "Please install these utilities before running MVNimble." >&2
    return 1
  fi
  
  return 0
}

# Verify Java installation
verify_java_installation() {
  if ! command -v java >/dev/null 2>&1; then
    echo "ERROR: Java is not installed or not in PATH" >&2
    echo "MVNimble requires Java $MINIMUM_JAVA_VERSION or higher" >&2
    echo "Please install Java and ensure it's available in your PATH" >&2
    return 1
  fi
  
  # Get Java version
  local java_version
  java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
  
  # For Java 1.8, convert to 8
  if [[ "$java_version" == "1."* ]]; then
    java_version=$(echo "$java_version" | cut -d'.' -f2)
  fi
  
  # Check version against minimum
  if [[ -z "$java_version" || "$java_version" -lt "$MINIMUM_JAVA_VERSION" ]]; then
    echo "ERROR: Java version $java_version is below minimum required version $MINIMUM_JAVA_VERSION" >&2
    echo "Please upgrade Java to version $MINIMUM_JAVA_VERSION or higher" >&2
    return 1
  fi
  
  return 0
}

# Verify Maven installation
verify_maven_installation() {
  if ! command -v mvn >/dev/null 2>&1; then
    echo "ERROR: Maven is not installed or not in PATH" >&2
    echo "MVNimble requires Maven to analyze and optimize test execution" >&2
    echo "Please install Maven and ensure it's available in your PATH" >&2
    return 1
  fi
  
  # Check Maven version (simplified version check)
  local mvn_version
  mvn_version=$(mvn --version | head -1 | awk '{print $3}')
  
  # Basic version check - we're looking for at least 3.x
  if [[ ! "$mvn_version" =~ ^3\. ]]; then
    echo "WARNING: Maven version $mvn_version may not be compatible with MVNimble" >&2
    echo "Recommended Maven version is $MINIMUM_MVN_VERSION or higher" >&2
    echo "Continuing, but you may encounter issues..." >&2
  fi
  
  return 0
}

# Verify ShellCheck installation or install it
verify_shellcheck_installation() {
  # ShellCheck is optional, so just return success if not explicitly required
  if [ "${1:-false}" != "true" ]; then
    return 0
  fi
  
  # Offer to install if not already installed
  if ! command -v shellcheck >/dev/null 2>&1; then
    echo "ShellCheck is required for script validation but is not installed." >&2
    install_shellcheck false
    if ! command -v shellcheck >/dev/null 2>&1; then
      return 1
    fi
  fi
  
  # Verify version if installed
  local version
  version=$(shellcheck --version | grep "version:" | awk '{print $2}')
  
  # Compare version components
  local major minor patch
  major=$(echo "$version" | cut -d. -f1)
  minor=$(echo "$version" | cut -d. -f2)
  patch=$(echo "$version" | cut -d. -f3)
  
  local min_major min_minor min_patch
  min_major=$(echo "$MINIMUM_SHELLCHECK_VERSION" | cut -d. -f1)
  min_minor=$(echo "$MINIMUM_SHELLCHECK_VERSION" | cut -d. -f2)
  min_patch=$(echo "$MINIMUM_SHELLCHECK_VERSION" | cut -d. -f3)
  
  if [ "$major" -lt "$min_major" ] || 
     { [ "$major" -eq "$min_major" ] && [ "$minor" -lt "$min_minor" ]; } || 
     { [ "$major" -eq "$min_major" ] && [ "$minor" -eq "$min_minor" ] && [ "$patch" -lt "$min_patch" ]; }; then
    echo "WARNING: ShellCheck version $version is below recommended version $MINIMUM_SHELLCHECK_VERSION" >&2
    echo "Continuing, but you may encounter issues..." >&2
  fi
  
  return 0
}

# Verify bashate installation or install it
verify_bashate_installation() {
  # Bashate is optional, so just return success if not explicitly required
  if [ "${1:-false}" != "true" ]; then
    return 0
  fi
  
  # Offer to install if not already installed
  install_bashate
  
  return 0
}

# Verify system resources
verify_system_resources() {
  # Check available memory
  local memory_total_mb
  
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS
    memory_total_mb=$(($(sysctl -n hw.memsize) / 1024 / 1024))
  else
    # Linux
    memory_total_mb=$(($(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024))
  fi
  
  if [[ "$memory_total_mb" -lt "$MIN_MEMORY_MB" ]]; then
    echo "ERROR: Insufficient memory available: ${memory_total_mb}MB" >&2
    echo "MVNimble requires at least ${MIN_MEMORY_MB}MB of RAM" >&2
    return 1
  fi
  
  # Check available disk space
  local disk_space_mb
  
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS
    disk_space_mb=$(df -m . | tail -1 | awk '{print $4}')
  else
    # Linux
    disk_space_mb=$(df -m . | tail -1 | awk '{print $4}')
  fi
  
  if [[ "$disk_space_mb" -lt "$MINIMUM_DISK_SPACE_MB" ]]; then
    echo "ERROR: Insufficient disk space: ${disk_space_mb}MB available" >&2
    echo "MVNimble requires at least ${MINIMUM_DISK_SPACE_MB}MB of free disk space" >&2
    return 1
  fi
  
  return 0
}

# Verify Maven project
verify_maven_project() {
  # Check for pom.xml in the current directory
  if [[ ! -f "pom.xml" ]]; then
    echo "ERROR: No pom.xml found in the current directory" >&2
    echo "MVNimble must be run from the root of a Maven project" >&2
    return 1
  fi
  
  # Check if pom.xml is a valid Maven project file
  if ! grep -q "<project" pom.xml; then
    echo "ERROR: pom.xml does not appear to be a valid Maven project file" >&2
    echo "Make sure you're running MVNimble from a valid Maven project directory" >&2
    return 1
  fi
  
  return 0
}

# Verify write permissions
verify_write_permissions() {
  local dir="$1"
  
  if [[ ! -d "$dir" ]]; then
    if ! mkdir -p "$dir" 2>/dev/null; then
      echo "ERROR: Cannot create directory: $dir" >&2
      echo "MVNimble requires write permission to create output files" >&2
      return 1
    fi
  elif [[ ! -w "$dir" ]]; then
    echo "ERROR: Cannot write to directory: $dir" >&2
    echo "MVNimble requires write permission to create output files" >&2
    return 1
  fi
  
  return 0
}

# Verify platform compatibility
verify_platform_compatibility() {
  local platform
  platform="$(uname)"
  
  case "$platform" in
    Darwin|Linux)
      # Supported platforms
      ;;
    *)
      echo "WARNING: Untested platform: $platform" >&2
      echo "MVNimble is designed for macOS and Linux environments" >&2
      echo "You may encounter compatibility issues on this platform" >&2
      ;;
  esac
  
  return 0
}

# Main function to run all dependency checks
verify_all_dependencies() {
  local results_dir="$1"
  local check_shellcheck="${2:-false}" 
  local check_bashate="${3:-false}"
  local errors=0
  
  # Run all verification checks
  verify_shell_environment || true  # Just warnings, continue anyway
  verify_essential_commands || ((errors++))
  verify_java_installation || ((errors++))
  verify_maven_installation || ((errors++))
  verify_system_resources || ((errors++))
  verify_maven_project || ((errors++))
  verify_write_permissions "$results_dir" || ((errors++))
  verify_platform_compatibility || true # Just a warning
  
  # Optional checks
  verify_shellcheck_installation "$check_shellcheck" || true # Optional
  verify_bashate_installation "$check_bashate" || true # Optional
  
  # Return results
  if [[ "$errors" -gt 0 ]]; then
    echo "ERROR: Found $errors dependency or environment issues that must be fixed" >&2
    return 1
  fi
  
  return 0
}