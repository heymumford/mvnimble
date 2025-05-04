#!/usr/bin/env bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
#==============================================================================
# environment.sh
#
# MVNimble - Environment Detection Module
#
# Description:
#   This module provides functionality for detecting and analyzing the
#   execution environment, including operating system, resources,
#   and execution context.
#
# Usage:
#   source "path/to/environment.sh"
#   detect_environment
#==============================================================================

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source required modules
if [[ -z "${CONSTANTS_LOADED+x}" ]]; then
  source "${SCRIPT_DIR}/constants.sh"
fi
source "${SCRIPT_DIR}/common.sh"

# These functions are now provided by common.sh:
# - is_macos()
# - is_linux() 
# - get_cpu_cores()
# - get_available_memory()

# Get operating system type
function get_os_type() {
  if is_macos; then
    echo "macOS"
  elif is_linux; then
    echo "Linux"
  else
    echo "Unknown"
  fi
}

# Detect the current environment
function detect_environment() {
  local env_type="unknown"
  local cpu_count=$(get_cpu_cores)
  local total_memory=$(get_available_memory)
  local disk_space=$(get_free_disk_space)
  
  # Check for container environment
  if is_container_environment; then
    env_type="container"
  elif is_ci_environment; then
    env_type="ci"
  elif is_kubernetes_environment; then
    env_type="kubernetes"
  elif is_laptop_environment; then
    env_type="laptop"
  elif is_server_environment; then
    env_type="server"
  else
    env_type="desktop"
  fi
  
  echo "env_type=${env_type},cpu_count=${cpu_count},total_memory=${total_memory},disk_space=${disk_space}"
}

# Get free disk space in MB
function get_free_disk_space() {
  local free_space=0
  
  if is_macos; then
    # macOS
    free_space=$(df -m . | awk 'NR==2 {print $4}')
  elif is_linux; then
    # Linux
    free_space=$(df -m . | awk 'NR==2 {print $4}')
  else
    # Fallback
    free_space=1000
  fi
  
  echo "$free_space"
}

# Check if running in a container
function is_container_environment() {
  # Check for Docker
  if [ -f "/.dockerenv" ] || grep -q 'docker\|lxc' /proc/1/cgroup 2>/dev/null; then
    return 0
  fi
  
  # Check for container hints in /proc/self/cgroup
  if [ -f "/proc/self/cgroup" ] && grep -q 'docker\|lxc\|kubepods' /proc/self/cgroup 2>/dev/null; then
    return 0
  fi
  
  return 1
}

# Check if running in Kubernetes
function is_kubernetes_environment() {
  # Check for Kubernetes service account
  if [ -f "/var/run/secrets/kubernetes.io/serviceaccount/token" ]; then
    return 0
  fi
  
  # Check for Kubernetes environment variables
  if [[ -n "${KUBERNETES_SERVICE_HOST+x}" ]]; then
    return 0
  fi
  
  # Check for kubepods in cgroup
  if [ -f "/proc/self/cgroup" ] && grep -q 'kubepods' /proc/self/cgroup 2>/dev/null; then
    return 0
  fi
  
  return 1
}

# Check if running in CI
function is_ci_environment() {
  # Check for common CI environment variables
  if [[ -n "${CI+x}" || -n "${GITHUB_ACTIONS+x}" || -n "${JENKINS_URL+x}" || -n "${TRAVIS+x}" || -n "${GITLAB_CI+x}" ]]; then
    return 0
  fi
  
  return 1
}

# Check if running on a laptop
function is_laptop_environment() {
  if is_macos; then
    # Check for battery on macOS
    if system_profiler SPPowerDataType 2>/dev/null | grep -q "Battery Information"; then
      return 0
    fi
  elif is_linux; then
    # Check for battery on Linux
    if [ -d "/sys/class/power_supply" ] && ls /sys/class/power_supply/ | grep -q "BAT"; then
      return 0
    fi
  fi
  
  return 1
}

# Check if running on a server
function is_server_environment() {
  # Simple heuristic: high CPU count and memory
  local cpu_count=$(get_cpu_cores)
  local memory_gb=$(($(get_available_memory) / 1024))
  
  if [ "$cpu_count" -ge 8 ] && [ "$memory_gb" -ge 16 ] && ! is_laptop_environment; then
    return 0
  fi
  
  return 1
}

# Generate environment report
function generate_environment_report() {
  local result_dir="$1"
  local env_report="${result_dir}/environment.txt"
  
  # Create result directory if needed
  ensure_directory "$result_dir"
  
  # Detect environment
  local env_info=$(detect_environment)
  local env_type=$(echo "$env_info" | cut -d',' -f1 | cut -d'=' -f2)
  local cpu_count=$(echo "$env_info" | cut -d',' -f2 | cut -d'=' -f2)
  local memory_mb=$(echo "$env_info" | cut -d',' -f3 | cut -d'=' -f2)
  local disk_space=$(echo "$env_info" | cut -d',' -f4 | cut -d'=' -f2)
  
  # Operating system info
  local os_type=$(get_os_type)
  local os_version="$(uname -r)"
  
  # Java environment info
  local java_version=""
  if command_exists java; then
    java_version=$(java -version 2>&1 | grep version | awk '{print $3}' | tr -d '"')
  fi
  
  # Maven info
  local maven_version=""
  if command_exists mvn; then
    maven_version=$(mvn -version 2>&1 | grep "Apache Maven" | awk '{print $3}')
  fi
  
  # Generate the report
  {
    echo "MVNimble Environment Report"
    echo "=========================="
    echo ""
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "Environment Type: $env_type"
    echo "OS Type: $os_type"
    echo "OS Version: $os_version"
    echo "CPU Cores: $cpu_count"
    echo "Memory: ${memory_mb}MB"
    echo "Free Disk Space: ${disk_space}MB"
    echo ""
    echo "Java Version: $java_version"
    echo "Maven Version: $maven_version"
    echo ""
  } > "$env_report"
  
  print_success "Environment report generated: $env_report"
}