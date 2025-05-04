#!/usr/bin/env bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# environment_detection.sh
# MVNimble - Environment detection and analysis module
#
# This module provides functions for detecting and analyzing the environment
# where MVNimble is running, including hardware, operating system, container
# detection, and resource limits.

# Source constants and platform compatibility module
SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
if [[ -z "${CONSTANTS_LOADED+x}" ]]; then
  source "${SCRIPT_DIR}/constants.sh"
fi
source "${SCRIPT_DIR}/platform_compatibility.sh"

# Function alias for script compatibility
function detect_operating_system() {
  detect_platform "$@"
}

# Function alias for container detection
# Uses the implementation from environment.sh to avoid duplication
function detect_container_environment() {
  # Source environment.sh if detect_container is not available
  if ! type detect_container >/dev/null 2>&1; then
    source "${SCRIPT_DIR}/environment.sh"
  fi
  
  # Call the canonical implementation
  detect_container "$@"
}

# Function alias for container resource limits
# Uses the implementation from environment.sh to avoid duplication
function identify_container_resource_limits() {
  # Source environment.sh if detect_container_limits is not available
  if ! type detect_container_limits >/dev/null 2>&1; then
    source "${SCRIPT_DIR}/environment.sh"
  fi
  
  # Call the canonical implementation and format the output
  local container_type="$1"
  local result=$(detect_container_limits "$container_type")
  
  # Convert comma-separated format to newline format for backward compatibility
  result=$(echo "$result" | tr ',' '\n')
  
  echo -e "$result"
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
  if [[ "$(detect_operating_system)" == "linux" ]] && [ -f /proc/diskstats ]; then
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
}

# Measure network latency in containerized environments
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

# Identify JVM environment details
function identify_jvm_environment() {
  local jvm_info=""
  
  if command -v java >/dev/null 2>&1; then
    local java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
    local java_home="${JAVA_HOME:-Unknown}"
    local jvm_arch=$(java -XshowSettings:properties -version 2>&1 | grep sun.arch.data.model | awk '{print $3}')
    
    jvm_info="java_version=${java_version}\njava_home=${java_home}\njvm_arch=${jvm_arch}\n"
  else
    jvm_info="java_available=false\n"
  fi
  
  echo -e "$jvm_info"
}

# Identify Maven environment details
function identify_maven_environment() {
  local maven_info=""
  
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
      
      maven_info="maven_version=${mvn_version}\nmaven_fork_count=${fork_count}\nmaven_threads=${thread_count}\n"
    else
      maven_info="maven_version=${mvn_version}\npom_available=false\n"
    fi
  else
    maven_info="maven_available=false\n"
  fi
  
  echo -e "$maven_info"
}

# Main function to analyze the environment and detect key characteristics
function analyze_runtime_environment() {
  local result_dir="$1"
  
  echo -e "${COLOR_BOLD}${COLOR_BLUE}=== Environment Analysis ===${COLOR_RESET}"
  
  # Detect environment type
  local env_type=$(detect_container_environment)
  echo -e "Environment type: ${COLOR_BOLD}${env_type}${COLOR_RESET}"
  
  # Get CPU info using platform-compatible functions
  local cpu_count=$(get_cpu_count)
  local cpu_model=$(get_cpu_model)
  echo -e "CPU: ${cpu_model} (${cpu_count} cores)"
  
  # Get memory info using platform-compatible functions
  local mem_total=$(get_total_memory_mb)
  local mem_free=$(get_free_memory_mb)
  echo -e "Memory: ${mem_total}MB total, ${mem_free}MB available"
  
  # Get JVM info
  local jvm_info=$(identify_jvm_environment)
  local java_version=$(echo "$jvm_info" | grep "java_version" | cut -d= -f2)
  echo -e "Java: ${java_version}"
  
  # Get Maven info
  local mvn_info=$(identify_maven_environment)
  local mvn_version=$(echo "$mvn_info" | grep "maven_version" | cut -d= -f2)
  echo -e "Maven: ${mvn_version}"
  
  # Container-specific analysis
  local container_limits=""
  if [[ "$env_type" != "bare-metal" ]]; then
    echo -e "\n${COLOR_BOLD}${COLOR_CYAN}Container-Specific Analysis:${COLOR_RESET}"
    container_limits=$(identify_container_resource_limits "$env_type")
    
    if echo "$container_limits" | grep -q "container_memory_limit"; then
      local mem_limit=$(echo "$container_limits" | grep "container_memory_limit_mb" | cut -d= -f2)
      echo -e "Container memory limit: ${COLOR_BOLD}${mem_limit}MB${COLOR_RESET}"
      
      # Check if container memory is significantly less than host memory
      if (( mem_limit < mem_total / 2 )); then
        echo -e "${COLOR_YELLOW}Warning: Container memory limit (${mem_limit}MB) is less than 50% of host memory (${mem_total}MB)${COLOR_RESET}"
      fi
    fi
    
    if echo "$container_limits" | grep -q "container_cpu_limit"; then
      local cpu_limit=$(echo "$container_limits" | grep "container_cpu_limit" | cut -d= -f2)
      echo -e "Container CPU limit: ${COLOR_BOLD}${cpu_limit} cores${COLOR_RESET}"
      
      # Check if container CPU is significantly less than host CPU
      if (( $(echo "$cpu_limit < $cpu_count / 2" | bc -l) )); then
        echo -e "${COLOR_YELLOW}Warning: Container CPU limit (${cpu_limit}) is less than 50% of host CPUs (${cpu_count})${COLOR_RESET}"
      fi
    fi
    
    # Network latency analysis for containers
    local network_info=$(measure_network_latency "$env_type")
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
    echo "cpu_count=$cpu_count"
    echo "cpu_model=$cpu_model"
    echo "cpu_mhz=$(get_cpu_speed_mhz)"
    echo ""
    echo "Memory Information:"
    echo "memory_total_mb=$mem_total"
    echo "memory_used_mb=$(( mem_total - mem_free ))"
    echo "memory_free_mb=$mem_free"
    echo ""
    echo "JVM Information:"
    echo -e "$jvm_info"
    echo ""
    echo "Maven Information:"
    echo -e "$mvn_info"
    echo ""
    
    # Disk and I/O information
    echo "Disk and I/O Information:"
    echo -e "$(collect_disk_io_information)"
    echo ""
    
    if [[ "$env_type" != "bare-metal" ]]; then
      echo "Container Limits:"
      echo -e "$container_limits"
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
  echo "env_type=${env_type},cpu_count=${cpu_count},mem_total=${mem_total},mem_free=${mem_free}"
}