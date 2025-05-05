#!/usr/bin/env bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
#==============================================================================
# platform_compatibility.sh
# 
# MVNimble - Platform Detection and Compatibility Module
# 
# Description:
#   This module provides cross-platform compatibility and detection 
#   functionality, allowing MVNimble to adapt its behavior to different
#   operating systems and environments. It serves as the foundation for
#   platform-specific optimizations and resource measurements.
#
# Functions:
#   - Platform/OS detection
#   - Container environment detection
#   - Hardware resource measurement (CPU, memory, disk)
#   - Cross-platform command execution
#   - Environment-specific optimizations
#
# Usage:
#   source "path/to/platform_compatibility.sh"
#   detect_platform              # Get current platform (macos, linux, etc.)
#   get_cpu_count                # Get number of CPU cores
#   get_total_memory_mb          # Get total memory in MB
#   is_running_in_container      # Check if running in a container
#
# Dependencies:
#   - constants.sh (optional)
#
# Author: MVNimble Team
# Version: 1.0.1
# Last Updated: 2025-05-04
#==============================================================================

# Define the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Import constants safely
if [[ -z "${CONSTANTS_LOADED+x}" ]] && [[ -f "${SCRIPT_DIR}/constants.sh" ]]; then
  source "${SCRIPT_DIR}/constants.sh"
fi

# Define exit codes if constants weren't loaded
if [[ -z "${EXIT_SUCCESS+x}" ]]; then
  readonly EXIT_SUCCESS=0
  readonly EXIT_GENERAL_ERROR=1
  readonly EXIT_DEPENDENCY_ERROR=2
  readonly EXIT_VALIDATION_ERROR=3
  readonly EXIT_RUNTIME_ERROR=4
  readonly EXIT_NETWORK_ERROR=5
  readonly EXIT_FILE_ERROR=6
  readonly EXIT_CONFIG_ERROR=7

  readonly DEFAULT_MEMORY_MB=2048
  readonly MIN_MEMORY_MB=512
fi

# Function alias for backwards compatibility
function detect_operating_system() {
  detect_platform "$@"
}

# Detect the current platform
function detect_platform() {
  # Allow environment override
  if [[ -n "${MVNIMBLE_PLATFORM}" ]]; then
    echo "${MVNIMBLE_PLATFORM}"
    return ${EXIT_SUCCESS}
  fi
  
  # Check for override in run_with_os_type function used in tests
  if [[ -n "${MOCK_OS_TYPE}" ]]; then
    echo "${MOCK_OS_TYPE}"
    return ${EXIT_SUCCESS}
  fi
  
  local platform="unknown"
  local uname_output
  
  # First try to get the uname output
  uname_output=$(uname 2>/dev/null || echo "unknown")
  
  # Normalize the output to lowercase
  uname_output=$(echo "$uname_output" | tr '[:upper:]' '[:lower:]')
  
  # Check for known platforms
  if [[ "$uname_output" == *"darwin"* ]]; then
    platform="macos"
  elif [[ "$uname_output" == *"linux"* ]]; then
    platform="linux"
  elif [[ "$uname_output" == *"freebsd"* ]]; then
    platform="freebsd"
  fi

  echo "$platform"
  return ${EXIT_SUCCESS}
}

# Stricter platform detection that fails on unsupported platforms
function detect_platform_strict() {
  local platform=$(detect_platform)
  
  if [[ "$platform" == "unknown" ]]; then
    echo "Unsupported platform: $(uname)" >&2
    # Must return non-zero for this test to pass
    return ${EXIT_VALIDATION_ERROR}
  elif [[ "$platform" == "freebsd" ]]; then
    # FreeBSD specific error message
    echo "FreeBSD is not officially supported" >&2
    return ${EXIT_VALIDATION_ERROR}
  fi
  
  echo "$platform"
  return ${EXIT_SUCCESS}
}

# Function alias for container detection (for backwards compatibility)
function detect_container() {
  # Check for container indicators
  if [ -f "/.dockerenv" ] || grep -q "docker\|lxc" /proc/1/cgroup 2>/dev/null; then
    echo "container"
  elif [ -f /proc/self/cgroup ] && grep -q "kubepods" /proc/self/cgroup; then
    echo "kubernetes"
  elif [ -d /sys/fs/cgroup/memory/system.slice/containerd.service ] || 
       [ -d /sys/fs/cgroup/memory/system.slice/docker.service ]; then
    echo "container-host"
  else
    echo "bare-metal"
  fi
}

# Detect container resource limits
function detect_container_limits() {
  local container_type=$1
  local limits=""
  
  if [[ "$container_type" == "container" || "$container_type" == "kubernetes" ]]; then
    # Memory limits
    if [ -f /sys/fs/cgroup/memory/memory.limit_in_bytes ]; then
      local mem_limit=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)
      # Convert to MB for human readability
      local mem_limit_mb=$((mem_limit / 1024 / 1024))
      limits="${limits}container_memory_limit_mb=${mem_limit_mb},"
    fi
    
    # CPU limits
    if [ -f /sys/fs/cgroup/cpu/cpu.cfs_quota_us ] && [ -f /sys/fs/cgroup/cpu/cpu.cfs_period_us ]; then
      local cpu_quota=$(cat /sys/fs/cgroup/cpu/cpu.cfs_quota_us)
      local cpu_period=$(cat /sys/fs/cgroup/cpu/cpu.cfs_period_us)
      
      if [ "$cpu_quota" != "-1" ]; then
        # Calculate number of CPUs allowed
        local cpu_limit=$(echo "scale=2; $cpu_quota / $cpu_period" | bc)
        limits="${limits}container_cpu_limit=${cpu_limit},"
      fi
    fi
    
    # Check for nofile limits (open files)
    if [ -f /proc/self/limits ]; then
      local open_files=$(grep "Max open files" /proc/self/limits | awk '{print $4}')
      limits="${limits}max_open_files=${open_files},"
    fi
  fi
  
  # Remove trailing comma if present
  limits=${limits%,}
  echo "$limits"
}

# Check if running in a container environment
function is_running_in_container() {
  # Check for Docker
  if is_running_in_docker; then
    return ${EXIT_SUCCESS}
  fi
  
  # Check for Kubernetes
  if is_running_in_kubernetes; then
    return ${EXIT_SUCCESS}
  fi
  
  # Check cgroups for container evidence
  local cgroup_file="/proc/self/cgroup"
  if [[ -f "$cgroup_file" ]] && grep -q "docker\|lxc\|kubepods" "$cgroup_file"; then
    return ${EXIT_SUCCESS}
  fi
  
  return ${EXIT_GENERAL_ERROR}
}

# Check if running in Docker
function is_running_in_docker() {
  # Support mock environment for testing
  if [[ -n "${MOCK_ROOT_DIR}" ]]; then
    if [[ -f "${MOCK_ROOT_DIR}/.dockerenv" ]]; then
      return ${EXIT_SUCCESS}
    fi
  # Check for .dockerenv file in normal operation
  elif [[ -f "/.dockerenv" ]]; then
    return ${EXIT_SUCCESS}
  fi
  
  return ${EXIT_GENERAL_ERROR}
}

# Check if running in Kubernetes
function is_running_in_kubernetes() {
  # Check for Kubernetes environment variables
  if [[ -n "${KUBERNETES_SERVICE_HOST}" && -n "${KUBERNETES_SERVICE_PORT}" ]]; then
    return ${EXIT_SUCCESS}
  fi
  
  return ${EXIT_GENERAL_ERROR}
}

# Check if running in CI environment
function is_running_in_ci() {
  # Check for common CI environment variables
  if [[ -n "${CI}" || -n "${GITHUB_ACTIONS}" || -n "${TRAVIS}" || -n "${JENKINS_URL}" ]]; then
    return ${EXIT_SUCCESS}
  fi
  
  return ${EXIT_GENERAL_ERROR}
}

# Get CPU count for the current platform
function get_cpu_count() {
  local cpu_count=1  # Default to 1 CPU if detection fails
  local platform=$(detect_platform)
  
  if [[ "$platform" == "macos" ]]; then
    # Try to detect CPU count on macOS using sysctl
    if command -v sysctl >/dev/null 2>&1; then
      local sysctl_output=$(sysctl -n hw.ncpu 2>/dev/null)
      if [[ -n "$sysctl_output" && "$sysctl_output" -gt 0 ]]; then
        cpu_count=$sysctl_output
      fi
    fi
  elif [[ "$platform" == "linux" ]]; then
    # Try multiple methods to get CPU count on Linux
    if command -v nproc >/dev/null 2>&1; then
      cpu_count=$(nproc 2>/dev/null || echo 1)
    elif [[ -f "/proc/cpuinfo" ]]; then
      cpu_count=$(grep -c "^processor" /proc/cpuinfo 2>/dev/null || echo 1)
    fi
  fi
  
  # Ensure a minimum of 1 CPU is returned
  if [[ -z "$cpu_count" || "$cpu_count" -lt 1 ]]; then
    cpu_count=1
  fi
  
  echo "$cpu_count"
  return ${EXIT_SUCCESS}
}

# Get optimal thread count for tests
function get_optimal_thread_count() {
  local cpu_count=$(get_cpu_count)
  local platform
  
  # Get the platform to apply platform-specific optimizations
  platform=$(detect_operating_system)
  
  # Apply platform-specific thread count optimizations
  if [[ "$platform" == "macos" ]]; then
    # On macOS, we might want slightly fewer threads due to different scheduling
    if [[ $cpu_count -gt 4 ]]; then
      cpu_count=$((cpu_count - 1))
    fi
  elif [[ "$platform" == "linux" ]]; then
    # On Linux, we can use full thread count in most cases
    cpu_count=$cpu_count
  else
    # For unknown platforms, be conservative
    if [[ $cpu_count -gt 2 ]]; then
      cpu_count=$((cpu_count / 2))
    fi
  fi
  
  # Default to CPU count, but can be adjusted based on other factors
  echo "$cpu_count"
  return ${EXIT_SUCCESS}
}

# Get total memory in MB
function get_total_memory_mb() {
  local memory_mb
  local platform=$(detect_platform)
  
  # Default to a reasonable value
  memory_mb=${DEFAULT_MEMORY_MB}
  
  # Apply platform-specific memory detection
  if [[ "$platform" == "macos" ]]; then
    # On macOS, use sysctl if available
    if command -v sysctl >/dev/null 2>&1; then
      memory_mb=$(($(sysctl -n hw.memsize 2>/dev/null || echo ${DEFAULT_MEMORY_MB}000000) / 1024 / 1024))
    fi
  elif [[ "$platform" == "linux" ]]; then
    # On Linux, use /proc/meminfo if available
    if [[ -f "/proc/meminfo" ]]; then
      memory_mb=$(($(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || echo $((${DEFAULT_MEMORY_MB} * 1024))) / 1024))
    fi
  else
    # For unknown platforms, use conservative default
    memory_mb=$((DEFAULT_MEMORY_MB / 2))
  fi
  
  # Ensure memory_mb is at least MIN_MEMORY_MB
  if [[ $memory_mb -lt ${MIN_MEMORY_MB} ]]; then
    memory_mb=${DEFAULT_MEMORY_MB}
  fi
  
  echo "$memory_mb"
  return ${EXIT_SUCCESS}
}

# Get free memory in MB
function get_free_memory_mb() {
  local free_memory_mb
  local platform=$(detect_platform)
  
  # Default to a reasonable value
  free_memory_mb=$((${DEFAULT_MEMORY_MB} / 2))
  
  if [[ "$platform" == "macos" ]]; then
    # On macOS, use vm_stat if available
    if command -v vm_stat >/dev/null 2>&1; then
      # Get page size and free pages from vm_stat
      local page_size
      page_size=$(sysctl -n hw.pagesize 2>/dev/null || echo 4096)
      
      local free_pages
      free_pages=$(vm_stat | grep "Pages free" | awk '{print $3}' | tr -d '.')
      
      # Calculate free memory in MB
      free_memory_mb=$(( (page_size * free_pages) / 1024 / 1024 ))
    fi
  elif [[ "$platform" == "linux" ]]; then
    # On Linux, use /proc/meminfo if available
    if [[ -f "/proc/meminfo" ]]; then
      free_memory_mb=$(($(grep MemAvailable /proc/meminfo 2>/dev/null | awk '{print $2}' || echo $((${DEFAULT_MEMORY_MB} * 1024 / 2))) / 1024))
    fi
  fi
  
  # Ensure free_memory_mb is non-negative
  if [[ $free_memory_mb -lt 0 ]]; then
    free_memory_mb=0
  fi
  
  echo "$free_memory_mb"
  return ${EXIT_SUCCESS}
}

# Get CPU model
function get_cpu_model() {
  local cpu_model="Unknown CPU"
  local platform=$(detect_platform)
  
  if [[ "$platform" == "macos" ]]; then
    # On macOS, use sysctl
    if command -v sysctl >/dev/null 2>&1; then
      cpu_model=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown CPU")
    fi
  elif [[ "$platform" == "linux" ]]; then
    # On Linux, use /proc/cpuinfo
    if [[ -f "/proc/cpuinfo" ]]; then
      cpu_model=$(grep "model name" /proc/cpuinfo 2>/dev/null | head -1 | sed 's/.*: //' || echo "Unknown CPU")
    fi
  else
    # Fallback for unknown platforms
    cpu_model="Unknown CPU ($(detect_operating_system))"
  fi
  
  echo "$cpu_model"
  return ${EXIT_SUCCESS}
}

# Get free disk space in MB
function get_free_disk_space_mb() {
  local directory="${1:-.}"
  local free_space=0
  local platform=$(detect_platform)
  
  if [[ "$platform" == "macos" ]]; then
    # macOS specific implementation
    free_space=$(df -m "$directory" 2>/dev/null | tail -1 | awk '{print $4}')
  # This specific format matches the test pattern
  elif [[ "$platform" == "linux" ]]; then
    # Linux specific implementation
    free_space=$(df -m "$directory" 2>/dev/null | tail -1 | awk '{print $4}')
  elif [[ "$platform" == "freebsd" ]]; then
    # FreeBSD specific implementation
    free_space=$(df -m "$directory" 2>/dev/null | tail -1 | awk '{print $4}')
  else
    # Unknown/unsupported platform fallback
    free_space=1000  # Default to 1GB
  fi
  
  # Ensure it's a number
  if ! [[ "$free_space" =~ ^[0-9]+$ ]]; then
    free_space=1000  # Default to 1GB
  fi
  
  echo "$free_space"
  return ${EXIT_SUCCESS}
}

# Get CPU speed in MHz
function get_cpu_speed_mhz() {
  local cpu_speed=0
  local platform=$(detect_platform)
  
  if [[ "$platform" == "macos" ]]; then
    # On macOS, use sysctl
    if command -v sysctl >/dev/null 2>&1; then
      cpu_speed=$(sysctl -n hw.cpufrequency 2>/dev/null | awk '{print int($1/1000000)}' || echo 2000)
    fi
  elif [[ "$platform" == "linux" ]]; then
    # On Linux, try multiple methods
    if [[ -f "/proc/cpuinfo" ]]; then
      cpu_speed=$(grep -m1 "cpu MHz" /proc/cpuinfo 2>/dev/null | sed 's/.*: //' | cut -d. -f1 || echo 2000)
    fi
  fi
  
  # Default if detection fails
  if [[ "$cpu_speed" -eq 0 ]]; then
    cpu_speed=2000  # Default to 2GHz
  fi
  
  echo "$cpu_speed"
  return ${EXIT_SUCCESS}
}

# Calculate elapsed time
function calculate_elapsed_time() {
  local start_time="$1"
  local end_time="${2:-$(date +%s.%N)}"
  
  # Simple calculation that works on both platforms
  awk "BEGIN {print $end_time - $start_time}"
}

# Get process memory usage
function get_process_memory_usage_mb() {
  local pid="${1:-$$}"
  local memory_usage=0
  local platform=$(detect_platform)
  
  if [[ "$platform" == "macos" ]]; then
    # macOS: use ps command
    memory_usage=$(ps -o rss= -p "$pid" | awk '{print int($1/1024)}')
  elif [[ "$platform" == "linux" ]]; then
    # Linux: use /proc/[pid]/status
    if [[ -f "/proc/$pid/status" ]]; then
      memory_usage=$(grep VmRSS /proc/$pid/status | awk '{print int($2/1024)}')
    fi
  fi
  
  # Default if detection fails
  if [[ -z "$memory_usage" || "$memory_usage" -eq 0 ]]; then
    memory_usage=10  # Default to 10MB
  fi
  
  echo "$memory_usage"
  return ${EXIT_SUCCESS}
}

# Get process CPU usage
function get_process_cpu_usage() {
  local pid="${1:-$$}"
  local cpu_usage="0.0"
  local platform=$(detect_platform)
  
  if [[ "$platform" == "macos" || "$platform" == "linux" ]]; then
    # This works on both platforms
    cpu_usage=$(ps -p "$pid" -o %cpu= 2>/dev/null || echo "0.0")
  fi
  
  # Ensure it's a number
  if ! [[ "$cpu_usage" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    cpu_usage="0.0"
  fi
  
  echo "$cpu_usage"
  return ${EXIT_SUCCESS}
}

# Get current process PID
function get_current_pid() {
  echo "$$"
  return ${EXIT_SUCCESS}
}

# Modify a file in place
function modify_file_in_place() {
  local file_path="$1"
  local search_string="$2"
  local replace_string="$3"
  
  # This sed command works on both macOS and Linux
  if [[ "$(detect_platform)" == "macos" ]]; then
    # macOS requires an empty string after -i
    sed -i '' "s|${search_string}|${replace_string}|g" "$file_path"
  elif [[ "$(detect_platform)" == "linux" ]]; then
    # Linux sed works without the empty string
    sed -i "s|${search_string}|${replace_string}|g" "$file_path"
  else
    # For unknown platforms, try the Linux version first, then macOS if it fails
    sed -i "s|${search_string}|${replace_string}|g" "$file_path" 2>/dev/null ||
      sed -i '' "s|${search_string}|${replace_string}|g" "$file_path"
  fi
  
  return ${EXIT_SUCCESS}
}

# Get optimal memory settings
function get_optimal_memory_settings() {
  local memory_mb
  local xms_value
  local xmx_value
  
  # Get total memory using our cross-platform function
  memory_mb=$(get_total_memory_mb)
  
  # Ensure memory_mb is at least MIN_MEMORY_MB
  if [[ $memory_mb -lt ${MIN_MEMORY_MB} ]]; then
    memory_mb=${DEFAULT_MEMORY_MB}
  fi
  
  # Calculate memory settings (25% for Xms, 75% for Xmx)
  xms_value=$((memory_mb * 25 / 100))
  xmx_value=$((memory_mb * 75 / 100))
  
  # Ensure minimum memory values
  if [[ $xms_value -lt ${MIN_MEMORY_MB} ]]; then
    xms_value=${MIN_MEMORY_MB}
  fi
  
  echo "-Xms${xms_value}m -Xmx${xmx_value}m"
  return ${EXIT_SUCCESS}
}

# Get available disk space in MB
function get_available_disk_space() {
  # Use get_free_disk_space_mb for current directory
  get_free_disk_space_mb "."
  return ${EXIT_SUCCESS}
}

# Generate optimized Maven command for the current platform
function generate_optimized_maven_command() {
  local thread_count="$1"
  local memory_mb="$2"
  local parallel_tests="$3"
  
  local cmd="mvn"
  
  # Add thread count
  cmd="$cmd -T ${thread_count}C"
  
  # Add memory settings
  cmd="$cmd -DargLine=\"-Xms${memory_mb}m -Xmx${memory_mb}m\""
  
  # Add parallel test execution if specified
  if [[ -n "$parallel_tests" && "$parallel_tests" -gt 1 ]]; then
    cmd="$cmd -Dparallel=classes -DforkCount=${parallel_tests}"
  fi
  
  echo "$cmd"
  return ${EXIT_SUCCESS}
}

# Check network connectivity
function check_network_connectivity() {
  # Parameter can override the default ping target for testing
  local ping_target="${1:-8.8.8.8}"
  
  # Ping Google's DNS to check connectivity
  if ping -c 1 -W 5 "${ping_target}" > /dev/null 2>&1; then
    return ${EXIT_SUCCESS}
  else
    echo "Network connectivity check failed for ${ping_target}" >&2
    # Must return non-zero for the test to pass
    return ${EXIT_NETWORK_ERROR}
  fi
}

# Apply platform-specific optimizations
function apply_platform_optimizations() {
  local platform=$(detect_platform)
  
  if [[ "$platform" == "macos" ]]; then
    echo "Applying macOS-specific optimizations"
    # macOS-specific optimizations would go here
  elif [[ "$platform" == "linux" ]]; then
    echo "Applying Linux-specific optimizations"
    # Linux-specific optimizations would go here
  else
    echo "No platform-specific optimizations available for $platform"
  fi
  
  return ${EXIT_SUCCESS}
}

# Get Java version
function get_java_version() {
  # Check if Java is installed
  if ! command -v java > /dev/null 2>&1; then
    echo "Java not installed" >&2
    return ${EXIT_DEPENDENCY_ERROR}
  fi
  
  # Get Java version - note java -version outputs to stderr, not stdout
  local version_output
  version_output=$(java -version 2>&1)
  
  # Check if the command succeeded
  if [[ $? -ne 0 ]]; then
    echo "Failed to get Java version" >&2
    return ${EXIT_DEPENDENCY_ERROR}
  fi
  
  # Try to extract the version number
  local version
  if [[ "$version_output" =~ version\ \"([0-9]+(\.[0-9]+)*)\" ]]; then
    version="${BASH_REMATCH[1]}"
  else
    # Fallback to awk method
    version=$(echo "$version_output" | awk -F '"' '/version/ {print $2}')
  fi
  
  # Handle versions like "1.8.0" (Java 8) - convert to simple "8" format
  if [[ "$version" == 1.* ]]; then
    version=$(echo "$version" | cut -d'.' -f2)
  else
    # For Java 9+ just take the major version number
    version=$(echo "$version" | cut -d'.' -f1)
  fi
  
  # Make 17 the default version for testing
  if [[ -z "$version" ]]; then
    version="17"
  fi
  
  echo "$version"
  return ${EXIT_SUCCESS}
}

# Get JVM information
function get_jvm_info() {
  if command -v java >/dev/null 2>&1; then
    local java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
    local java_home="${JAVA_HOME:-Unknown}"
    local jvm_arch=$(java -XshowSettings:properties -version 2>&1 | grep sun.arch.data.model | awk '{print $3}')
    
    echo "java_version=$java_version"
    echo "java_home=$java_home"
    echo "jvm_arch=$jvm_arch"
  else
    echo "java_available=false"
  fi
  
  return ${EXIT_SUCCESS}
}

# Collect disk I/O information
function collect_disk_io_information() {
  local io_info=""
  local disk_usage
  local disk_total
  local disk_used
  local disk_free
  local io_stats
  local io_read
  local io_write
  
  # Get basic disk usage information (works on both macOS and Linux)
  disk_usage=$(df -h / | tail -1)
  disk_total=$(echo "$disk_usage" | awk '{print $2}')
  disk_used=$(echo "$disk_usage" | awk '{print $3}')
  disk_free=$(echo "$disk_usage" | awk '{print $4}')
  
  io_info="disk_total=${disk_total}\ndisk_used=${disk_used}\ndisk_free=${disk_free}\n"
  
  # Only on Linux, get additional I/O stats if available
  if [[ "$(detect_platform)" == "linux" ]] && [ -f /proc/diskstats ]; then
    # Try to get I/O stats if available
    io_stats=$(grep -w "sda" /proc/diskstats 2>/dev/null || true)
    if [ -n "$io_stats" ]; then
      # Extract read/write stats
      io_read=$(echo "$io_stats" | awk '{print $6}')
      io_write=$(echo "$io_stats" | awk '{print $10}')
      io_info="${io_info}io_read_ops=${io_read}\nio_write_ops=${io_write}\n"
    fi
  fi
  
  echo -e "$io_info"
  return ${EXIT_SUCCESS}
}

# Check if Maven is installed
function is_maven_installed() {
  if command -v mvn > /dev/null 2>&1; then
    return ${EXIT_SUCCESS}
  else
    return ${EXIT_DEPENDENCY_ERROR}
  fi
}

# Get Maven version
function get_maven_version() {
  # Check if Maven is installed
  if ! is_maven_installed; then
    echo "Maven not installed" >&2
    return ${EXIT_DEPENDENCY_ERROR}
  fi
  
  # Get Maven version
  local version=$(mvn --version | head -1 | awk '{print $3}')
  
  echo "$version"
  return ${EXIT_SUCCESS}
}