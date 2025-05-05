#!/usr/bin/env bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
#==============================================================================
# environment_unified.sh
# 
# MVNimble - Unified Environment Detection and Analysis Module
# 
# Description:
#   This consolidated module provides all environment detection and analysis
#   functionality, including hardware, operating system, container detection,
#   and resource limits. It serves as the single source of truth for all
#   environment-related functionality, replacing the separate environment.sh 
#   and environment_detection.sh modules.
#
# Functions:
#   - Environment detection (OS, container, VM)
#   - Resource analysis (CPU, memory, disk, network)
#   - JVM/Maven environment examination
#   - Container-specific optimizations
#
# Usage:
#   source "path/to/environment_unified.sh"
#   detect_operating_system    # Get current OS
#   analyze_environment ./results  # Full environment analysis
#
# Dependencies:
#   - constants.sh
#   - platform_compatibility.sh
#
# Author: MVNimble Team
# Version: 1.1.0
# Last Updated: 2025-05-04
#==============================================================================

# Determine script directory in a portable way
SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

# Import dependencies
if [[ -z "${CONSTANTS_LOADED+x}" ]]; then
  if [[ -f "${SCRIPT_DIR}/constants.sh" ]]; then
    source "${SCRIPT_DIR}/constants.sh"
  fi
fi

if [[ -f "${SCRIPT_DIR}/platform_compatibility.sh" ]]; then
  source "${SCRIPT_DIR}/platform_compatibility.sh"
fi

# ============================================================
# Environment Detection Functions
# ============================================================

# Function alias for script compatibility
# Note: We implement this directly rather than calling detect_platform
# to avoid dependency issues when sourcing
## Detects the operating system of the current environment
#
# This function determines the current operating system platform
# using various detection methods. It supports environment variable
# overrides for testing and CI purposes.
#
# Supported platforms:
# - macos: macOS/Darwin systems
# - linux: Linux distributions
# - freebsd: FreeBSD systems
# - unknown: If the platform cannot be determined
#
# Returns:
#   A string indicating the detected platform: "macos", "linux", "freebsd", or "unknown"
#
# Environment variables:
#   MVNIMBLE_PLATFORM: Manually override platform detection
#   MOCK_OS_TYPE: Used for testing to simulate different platforms
#
# Examples:
#   platform=$(detect_operating_system)
#   if [[ "$platform" == "macos" ]]; then
#     # macOS-specific operations
#   fi
function detect_operating_system() {
  # Allow environment override
  if [[ -n "${MVNIMBLE_PLATFORM}" ]]; then
    echo "${MVNIMBLE_PLATFORM}"
    return 0
  fi
  
  # Check for override in run_with_os_type function used in tests
  if [[ -n "${MOCK_OS_TYPE}" ]]; then
    echo "${MOCK_OS_TYPE}"
    return 0
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
  return 0
}

# Function alias for container detection (for backward compatibility)
## Alias for detect_container function
#
# This is a backward compatibility wrapper for detect_container
# from platform_compatibility.sh
#
# Parameters:
#   All parameters are passed through to detect_container
#
# Returns:
#   The result from detect_container
#
# See Also:
#   detect_container in platform_compatibility.sh
function detect_container_environment() {
  detect_container "$@"
}

# Function alias for container resource limits (for backward compatibility)
## Identifies resource limits for container environments
#
# This function determines the CPU, memory, and other resource limits
# set for the current container environment. It's a compatibility wrapper
# that converts the output format of detect_container_limits to maintain
# backward compatibility.
#
# Parameters:
#   $1 - container_type: The type of container ("docker", "kubernetes", etc.)
#
# Returns:
#   Multi-line string with resource limits, one per line:
#   - container_cpu_limit=X
#   - container_memory_limit_mb=X
#   - container_swap_limit_mb=X
#   - etc.
#
# Example:
#   limits=$(identify_container_resource_limits "docker")
#   memory_limit=$(echo "$limits" | grep "memory_limit" | cut -d= -f2)
function identify_container_resource_limits() {
  local container_type="$1"
  local result=$(detect_container_limits "$container_type")
  
  # Convert comma-separated format to newline format for backward compatibility
  result=$(echo "$result" | tr ',' '\n')
  
  echo -e "$result"
}

# ============================================================
# Resource Information Functions
# ============================================================

# Get CPU information
## Retrieves comprehensive CPU information for the current system
#
# This function collects various CPU metrics including core count,
# model information, and clock speed. It uses platform-specific
# implementations from platform_compatibility.sh.
#
# Returns:
#   Multi-line string with CPU information in key=value format:
#   - cpu_count=X (number of CPU cores/threads)
#   - cpu_model=X (CPU model name)
#   - cpu_mhz=X (CPU clock speed in MHz)
#
# Example:
#   cpu_info=$(get_cpu_info)
#   cpu_cores=$(echo "$cpu_info" | grep "cpu_count" | cut -d= -f2)
#   echo "System has $cpu_cores CPU cores"
#
# Dependencies:
#   - get_cpu_count() from platform_compatibility.sh
#   - get_cpu_model() from platform_compatibility.sh
#   - get_cpu_speed_mhz() from platform_compatibility.sh
function get_cpu_info() {
  local cpu_count=$(get_cpu_count)
  local cpu_model=$(get_cpu_model)
  local cpu_mhz=$(get_cpu_speed_mhz)
  
  echo "cpu_count=$cpu_count"
  echo "cpu_model=$cpu_model"
  echo "cpu_mhz=$cpu_mhz"
}

# Get memory information
## Retrieves memory statistics for the current system
#
# This function collects information about system memory including
# total available memory, free memory, and calculates used memory.
# It uses platform-specific implementations for accurate results
# across different operating systems.
#
# Returns:
#   Multi-line string with memory information in key=value format:
#   - memory_total_mb=X (total physical memory in MB)
#   - memory_used_mb=X (currently used memory in MB)
#   - memory_free_mb=X (available memory in MB)
#
# Example:
#   mem_info=$(get_memory_info)
#   free_mem=$(echo "$mem_info" | grep "memory_free_mb" | cut -d= -f2)
#   echo "System has $free_mem MB of free memory"
#
# Dependencies:
#   - get_total_memory_mb() from platform_compatibility.sh
#   - get_free_memory_mb() from platform_compatibility.sh
function get_memory_info() {
  local mem_total_mb=$(get_total_memory_mb)
  local mem_free_mb=$(get_free_memory_mb)
  local mem_used_mb=$((mem_total_mb - mem_free_mb))
  
  echo "memory_total_mb=$mem_total_mb"
  echo "memory_used_mb=$mem_used_mb"
  echo "memory_free_mb=$mem_free_mb"
}

# This function is now implemented in platform_compatibility.sh

# Measure network latency
## Analyzes network connectivity and latency in container environments
#
# This function performs detailed network latency analysis specifically
# for containerized environments (Docker, Kubernetes). It measures latency
# to the host machine and external endpoints, providing valuable data
# for diagnosing network-related performance issues in Maven builds.
#
# The function attempts multiple measurement approaches, adjusting based
# on available tools (ping, curl) and connection types.
#
# Parameters:
#   $1 - env_type: Environment type ("container", "kubernetes", etc.)
#                  Analysis is only performed for container environments
#
# Returns:
#   Multi-line string with network metrics in key=value format:
#   - host_latency_ms=X (latency to host in milliseconds)
#   - http_latency_ms=X (HTTP connection latency in milliseconds)
#   - external_latency_ms=X (external connection latency in milliseconds)
#
# Side Effects:
#   Prints detailed network analysis information to stdout when run in
#   container environments
#
# Example:
#   network_data=$(measure_network_latency "container")
#   if echo "$network_data" | grep -q "external_latency_ms"; then
#     external_latency=$(echo "$network_data" | grep "external_latency_ms" | cut -d= -f2)
#     echo "External network latency: $external_latency ms"
#   fi
#
# Dependencies:
#   - ping and/or curl commands
#   - bc for floating point calculations
function measure_network_latency() {
  local env_type="$1"
  local network_info=""
  local host_ip=""
  local ping_result
  local avg_latency
  local http_latency
  local http_ms
  local port
  local external_latency
  local external_ms
  
  if [[ "$env_type" == "container" || "$env_type" == "kubernetes" ]]; then
    echo -e "\n${COLOR_BOLD}${COLOR_CYAN}Network Latency Analysis:${COLOR_RESET}"
    
    # Check if we can determine the host machine for the container
    
    # Try to get host machine's IP address using common gateway address
    if [ -f /proc/net/route ]; then
      host_ip=$(grep -v 00000000 /proc/net/route | head -1 | awk '{print $3}' | 
                awk '{ sub(/^/, ""); print }' | 
                awk '{for(i=0;i<length($0);i+=2)x=x substr($0,length($0)-i-1,2);print x}' | 
                awk '{print "0x"$1}' | tr 'a-z' 'A-Z' | xargs printf '%d.%d.%d.%d\n' | 
                sed -E 's/([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)/\4.\3.\2.\1/')
    fi
    
    # If not found, try to get default gateway
    if [ -z "$host_ip" ] && command -v ip > /dev/null; then
      host_ip=$(ip route | grep default | head -1 | awk '{print $3}')
    fi
    
    # Measure latency to host if we found an IP
    if [ -n "$host_ip" ]; then
      echo -e "Testing network latency to host: ${host_ip}"
      
      # Check if ping is available
      if command -v ping > /dev/null; then
        ping_result=$(ping -c 5 "$host_ip" 2>/dev/null || echo "Error")
        if [[ "$ping_result" != "Error" ]]; then
          avg_latency=$(echo "$ping_result" | grep "avg" | awk -F'/' '{print $5}')
          echo -e "Average latency to host: ${COLOR_BOLD}${avg_latency} ms${COLOR_RESET}"
          network_info="${network_info}host_latency_ms=${avg_latency}\n"
        else
          echo -e "${COLOR_YELLOW}Could not ping host, trying HTTP latency test${COLOR_RESET}"
        fi
      fi
      
      # Try to measure HTTP latency as backup
      if command -v curl > /dev/null; then
        # Try to connect to common ports
        for port in 80 8080 443; do
          http_latency=$(curl -o /dev/null -s -w "%{time_connect}\n" "http://${host_ip}:${port}" 2>/dev/null || echo "Error")
          if [[ "$http_latency" != "Error" ]]; then
            http_ms=$(echo "$http_latency * 1000" | bc)
            echo -e "HTTP connection latency (port ${port}): ${COLOR_BOLD}${http_ms} ms${COLOR_RESET}"
            network_info="${network_info}http_latency_ms=${http_ms}\n"
            break
          fi
        done
      fi
    else
      echo -e "${COLOR_YELLOW}Could not determine host IP to measure network latency${COLOR_RESET}"
    fi
    
    # Try to check external connectivity
    echo -e "\nTesting external network connectivity..."
    if command -v curl > /dev/null; then
      external_latency=$(curl -o /dev/null -s -w "%{time_connect}\n" "https://maven.apache.org" 2>/dev/null || echo "Error")
      if [[ "$external_latency" != "Error" ]]; then
        external_ms=$(echo "$external_latency * 1000" | bc)
        echo -e "External connection latency: ${COLOR_BOLD}${external_ms} ms${COLOR_RESET}"
        network_info="${network_info}external_latency_ms=${external_ms}\n"
      else
        echo -e "${COLOR_YELLOW}Could not measure external connectivity${COLOR_RESET}"
      fi
    else
      echo -e "${COLOR_YELLOW}curl not available to test network connectivity${COLOR_RESET}"
    fi
  fi
  
  echo -e "$network_info"
}

# ============================================================
# Runtime Environment Functions
# ============================================================

# This function is now implemented in platform_compatibility.sh

# Function alias for JVM environment detection
## Alias for the get_jvm_info function (for backward compatibility)
#
# This function provides backward compatibility for code that uses
# the identify_jvm_environment name. It directly passes all arguments
# to get_jvm_info in platform_compatibility.sh.
#
# Parameters:
#   All parameters are passed through to get_jvm_info
#
# Returns:
#   The result from get_jvm_info, containing JVM details
#
# See Also:
#   get_jvm_info in platform_compatibility.sh
function identify_jvm_environment() {
  get_jvm_info "$@"
}

# Get Maven information
## Detects Maven configuration and version information
#
# This function identifies the installed Maven version and extracts
# key Maven configuration parameters from the project's pom.xml
# that are relevant to build and test performance, such as fork count
# and thread settings.
#
# Returns:
#   Multi-line string with Maven information in key=value format:
#   - maven_version=X (version of installed Maven)
#   - maven_fork_count=X (JVM fork count setting from pom.xml)
#   - maven_threads=X (thread count setting from pom.xml)
#   OR
#   - maven_version=X, pom_available=false (if no pom.xml found)
#   OR
#   - maven_available=false (if Maven is not installed)
#
# Example:
#   maven_info=$(get_maven_info)
#   if echo "$maven_info" | grep -q "maven_available=false"; then
#     echo "Maven is not installed on this system"
#   else
#     mvn_version=$(echo "$maven_info" | grep "maven_version" | cut -d= -f2)
#     echo "Maven version: $mvn_version"
#   fi
#
# Dependencies:
#   - mvn command must be in PATH for full functionality
#   - pom.xml in current directory for extracting configuration
function get_maven_info() {
  if command -v mvn >/dev/null 2>&1; then
    local mvn_version=$(mvn --version | head -1 | awk '{print $3}')
    
    # Try to extract current Maven settings from pom.xml
    if [ -f "pom.xml" ]; then
      # Extract fork count and threads if available
      local fork_count="Not specified"
      local thread_count="Not specified"
      
      if grep -q "<jvm.fork.count>" pom.xml; then
        fork_count=$(grep -E "<jvm.fork.count>" pom.xml | grep -oE "[0-9.]+C?" | head -1)
      fi
      
      if grep -q "<maven.threads>" pom.xml; then
        thread_count=$(grep -E "<maven.threads>" pom.xml | grep -oE "[0-9]+" | head -1)
      fi
      
      echo "maven_version=$mvn_version"
      echo "maven_fork_count=$fork_count"
      echo "maven_threads=$thread_count"
    else
      echo "maven_version=$mvn_version"
      echo "pom_available=false"
    fi
  else
    echo "maven_available=false"
  fi
}

# Function alias for Maven environment detection
## Alias for the get_maven_info function (for backward compatibility)
#
# This function provides backward compatibility for code that uses
# the identify_maven_environment name. It directly passes all arguments
# to get_maven_info.
#
# Parameters:
#   All parameters are passed through to get_maven_info
#
# Returns:
#   The result from get_maven_info, containing Maven details
#
# See Also:
#   get_maven_info
function identify_maven_environment() {
  get_maven_info "$@"
}

# ============================================================
# Main Analysis Functions
# ============================================================

# Main function to analyze the environment and detect key characteristics
## Performs comprehensive environment analysis for Maven optimization
#
# This is the main entry point function for environment analysis. It collects
# a complete set of system information relevant to Maven build performance,
# including hardware resources, JVM settings, container limits, and network
# characteristics.
#
# The function displays a summary of key findings to the console and
# also writes detailed analysis to a file for later reference or programmatic use.
# For containerized environments, it performs additional container-specific
# analysis including resource limits and network latency.
#
# Parameters:
#   $1 - result_dir: Directory to save analysis results
#
# Returns:
#   A comma-separated string with key environment metrics:
#   env_type=X,cpu_count=X,mem_total=X,mem_free=X
#
# Side Effects:
#   - Creates a detailed environment.txt file in the specified results directory
#   - Prints analysis summary to stdout with colored formatting
#
# Example:
#   env_summary=$(analyze_environment "./results")
#   # Parse specific values from the summary
#   cpu_count=$(echo "$env_summary" | grep -o "cpu_count=[0-9]*" | cut -d= -f2)
#   
#   # Or read the full analysis file
#   cat ./results/environment.txt
#
# Dependencies:
#   - All resource detection functions in this module
#   - platform_compatibility.sh functions
#   - collect_disk_io_information from platform_compatibility.sh
function analyze_environment() {
  local result_dir="$1"
  
  echo -e "${COLOR_BOLD}${COLOR_BLUE}=== Environment Analysis ===${COLOR_RESET}"
  
  # Detect environment type
  local env_type=$(detect_container)
  echo -e "Environment type: ${COLOR_BOLD}${env_type}${COLOR_RESET}"
  
  # Get CPU info
  local cpu_info=$(get_cpu_info)
  local cpu_count=$(echo "$cpu_info" | grep "cpu_count" | cut -d= -f2)
  local cpu_model=$(echo "$cpu_info" | grep "cpu_model" | cut -d= -f2-)
  echo -e "CPU: ${cpu_model} (${cpu_count} cores)"
  
  # Get memory info
  local mem_info=$(get_memory_info)
  local mem_total=$(echo "$mem_info" | grep "memory_total_mb" | cut -d= -f2)
  local mem_free=$(echo "$mem_info" | grep "memory_free_mb" | cut -d= -f2)
  echo -e "Memory: ${mem_total}MB total, ${mem_free}MB available"
  
  # Get JVM info
  local jvm_info=$(get_jvm_info)
  local java_version=$(echo "$jvm_info" | grep "java_version" | cut -d= -f2)
  echo -e "Java: ${java_version}"
  
  # Get Maven info
  local mvn_info=$(get_maven_info)
  local mvn_version=$(echo "$mvn_info" | grep "maven_version" | cut -d= -f2)
  echo -e "Maven: ${mvn_version}"
  
  # Container-specific analysis
  local container_limits=""
  local network_info=""
  if [[ "$env_type" != "bare-metal" ]]; then
    echo -e "\n${COLOR_BOLD}${COLOR_CYAN}Container-Specific Analysis:${COLOR_RESET}"
    container_limits=$(detect_container_limits "$env_type")
    
    if echo "$container_limits" | grep -q "container_memory_limit"; then
      local mem_limit=$(echo "$container_limits" | grep -o "container_memory_limit_mb=[0-9]*" | cut -d= -f2)
      echo -e "Container memory limit: ${COLOR_BOLD}${mem_limit}MB${COLOR_RESET}"
      
      # Check if container memory is significantly less than host memory
      if (( mem_limit < mem_total / 2 )); then
        echo -e "${COLOR_YELLOW}Warning: Container memory limit (${mem_limit}MB) is less than 50% of host memory (${mem_total}MB)${COLOR_RESET}"
      fi
    fi
    
    if echo "$container_limits" | grep -q "container_cpu_limit"; then
      local cpu_limit=$(echo "$container_limits" | grep -o "container_cpu_limit=[0-9.]*" | cut -d= -f2)
      echo -e "Container CPU limit: ${COLOR_BOLD}${cpu_limit} cores${COLOR_RESET}"
      
      # Check if container CPU is significantly less than host CPU
      if (( $(echo "$cpu_limit < $cpu_count / 2" | bc -l) )); then
        echo -e "${COLOR_YELLOW}Warning: Container CPU limit (${cpu_limit}) is less than 50% of host CPUs (${cpu_count})${COLOR_RESET}"
      fi
    fi
    
    # Network latency analysis for containers
    network_info=$(measure_network_latency "$env_type")
  fi
  
  # Write environment info to file for later analysis
  mkdir -p "${result_dir}"
  local env_file="${result_dir}/environment.txt"
  
  {
    echo "MVNimble Environment Analysis"
    echo "============================="
    echo "Date: $(date)"
    echo "Environment Type: $env_type"
    echo ""
    echo "CPU Information:"
    echo "$cpu_info"
    echo ""
    echo "Memory Information:"
    echo "$mem_info"
    echo ""
    echo "JVM Information:"
    echo "$jvm_info"
    echo ""
    echo "Maven Information:"
    echo "$mvn_info"
    echo ""
    
    # Disk and I/O information
    echo "Disk and I/O Information:"
    echo -e "$(collect_disk_io_information)"
    echo ""
    
    if [[ "$env_type" != "bare-metal" ]]; then
      echo "Container Limits:"
      echo "$container_limits" | tr ',' '\n'
      echo ""
      
      if [ -n "$network_info" ]; then
        echo "Network Information:"
        echo -e "$network_info"
        echo ""
      fi
    fi
  } > "$env_file"
  
  echo -e "Environment analysis saved to: ${COLOR_BOLD}${env_file}${COLOR_RESET}"
  echo
  
  # Return a JSON-like string with key environment characteristics
  echo "env_type=$env_type,cpu_count=$cpu_count,mem_total=$mem_total,mem_free=$mem_free"
}

# Function alias for analyze_environment (for backward compatibility)
## Alias for analyze_environment function (for backward compatibility)
#
# This function provides backward compatibility for code that uses
# the analyze_runtime_environment name. It directly passes all arguments
# to analyze_environment.
#
# Parameters:
#   All parameters are passed through to analyze_environment
#
# Returns:
#   The result from analyze_environment
#
# See Also:
#   analyze_environment
function analyze_runtime_environment() {
  analyze_environment "$@"
}