#!/bin/zsh
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# environment.sh
# MVNimble - Environment detection and analysis module
#
# This module provides functions for detecting and analyzing the environment
# where MVNimble is running, including hardware, operating system, container
# detection, and resource limits.

# Determine script directory in a portable way
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Import constants
if [[ -z "${CONSTANTS_LOADED}" ]]; then
  source "${SCRIPT_DIR}/constants.sh"
fi

# ============================================================
# Environment Detection Functions
# ============================================================

# Detect if running in a container
detect_container() {
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
detect_container_limits() {
  local CONTAINER_TYPE=$1
  local LIMITS={}
  
  if [[ "$CONTAINER_TYPE" == "container" || "$CONTAINER_TYPE" == "kubernetes" ]]; then
    # Memory limits
    if [ -f /sys/fs/cgroup/memory/memory.limit_in_bytes ]; then
      local MEM_LIMIT=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)
      # Convert to MB for human readability
      MEM_LIMIT_MB=$((MEM_LIMIT / 1024 / 1024))
      echo "container_memory_limit_mb=$MEM_LIMIT_MB"
    fi
    
    # CPU limits
    if [ -f /sys/fs/cgroup/cpu/cpu.cfs_quota_us ] && [ -f /sys/fs/cgroup/cpu/cpu.cfs_period_us ]; then
      local CPU_QUOTA=$(cat /sys/fs/cgroup/cpu/cpu.cfs_quota_us)
      local CPU_PERIOD=$(cat /sys/fs/cgroup/cpu/cpu.cfs_period_us)
      
      if [ "$CPU_QUOTA" != "-1" ]; then
        # Calculate number of CPUs allowed
        CPU_LIMIT=$(echo "scale=2; $CPU_QUOTA / $CPU_PERIOD" | bc)
        echo "container_cpu_limit=$CPU_LIMIT"
      fi
    fi
    
    # Check for nofile limits (open files)
    if [ -f /proc/self/limits ]; then
      local OPEN_FILES=$(grep "Max open files" /proc/self/limits | awk '{print $4}')
      echo "max_open_files=$OPEN_FILES"
    fi
  fi
}

# Get CPU information
get_cpu_info() {
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS
    CPU_COUNT=$(sysctl -n hw.ncpu)
    CPU_MODEL=$(sysctl -n machdep.cpu.brand_string)
    CPU_MHZ=$(sysctl -n hw.cpufrequency | awk '{print $1 / 1000000}')
  else
    # Linux
    CPU_COUNT=$(grep -c ^processor /proc/cpuinfo)
    CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)
    CPU_MHZ=$(grep "cpu MHz" /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)
  fi
  
  echo "cpu_count=$CPU_COUNT"
  echo "cpu_model=$CPU_MODEL"
  echo "cpu_mhz=$CPU_MHZ"
}

# Get memory information
get_memory_info() {
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS
    MEM_TOTAL_KB=$(($(sysctl -n hw.memsize) / 1024))
    # Memory used is more complex on macOS, approximation:
    MEM_USED_KB=$(vm_stat | perl -ne '/page size of (\d+)/ and $size=$1; /Pages active: (\d+)/ and $active=$1; /Pages wired down: (\d+)/ and $wired=$1; END { print (($active + $wired) * $size) / 1024; }')
    MEM_FREE_KB=$((MEM_TOTAL_KB - MEM_USED_KB))
  else
    # Linux
    MEM_TOTAL_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    MEM_FREE_KB=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    MEM_USED_KB=$((MEM_TOTAL_KB - MEM_FREE_KB))
  fi
  
  # Convert to MB for readability
  MEM_TOTAL_MB=$((MEM_TOTAL_KB / 1024))
  MEM_USED_MB=$((MEM_USED_KB / 1024))
  MEM_FREE_MB=$((MEM_FREE_KB / 1024))
  
  echo "memory_total_mb=$MEM_TOTAL_MB"
  echo "memory_used_mb=$MEM_USED_MB"
  echo "memory_free_mb=$MEM_FREE_MB"
}

# Get I/O information
get_io_info() {
  # This is more complex and platform-dependent
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS - limited I/O stats
    DISK_USAGE=$(df -h / | tail -1)
    DISK_TOTAL=$(echo "$DISK_USAGE" | awk '{print $2}')
    DISK_USED=$(echo "$DISK_USAGE" | awk '{print $3}')
    DISK_FREE=$(echo "$DISK_USAGE" | awk '{print $4}')
  else
    # Linux
    DISK_USAGE=$(df -h / | tail -1)
    DISK_TOTAL=$(echo "$DISK_USAGE" | awk '{print $2}')
    DISK_USED=$(echo "$DISK_USAGE" | awk '{print $3}')
    DISK_FREE=$(echo "$DISK_USAGE" | awk '{print $4}')
    
    # Try to get I/O stats if available
    if [ -f /proc/diskstats ]; then
      IO_STATS=$(grep -w "sda" /proc/diskstats 2>/dev/null || true)
      if [ -n "$IO_STATS" ]; then
        # Extract read/write stats
        IO_READ=$(echo "$IO_STATS" | awk '{print $6}')
        IO_WRITE=$(echo "$IO_STATS" | awk '{print $10}')
        echo "io_read_ops=$IO_READ"
        echo "io_write_ops=$IO_WRITE"
      fi
    fi
  fi
  
  echo "disk_total=$DISK_TOTAL"
  echo "disk_used=$DISK_USED"
  echo "disk_free=$DISK_FREE"
}

# Measure network latency
measure_network_latency() {
  local ENV_TYPE=$1
  
  if [[ "$ENV_TYPE" == "container" || "$ENV_TYPE" == "kubernetes" ]]; then
    echo -e "\n${BOLD}${CYAN}Network Latency Analysis:${NC}"
    
    # Check if we can determine the host machine for the container
    HOST_IP=""
    
    # Try to get host machine's IP address using common gateway address
    if [ -f /proc/net/route ]; then
      HOST_IP=$(grep -v 00000000 /proc/net/route | head -1 | awk '{print $3}' | 
                awk '{ sub(/^/, ""); print }' | 
                awk '{for(i=0;i<length($0);i+=2)x=x substr($0,length($0)-i-1,2);print x}' | 
                awk '{print "0x"$1}' | tr 'a-z' 'A-Z' | xargs printf '%d.%d.%d.%d\n' | 
                sed -E 's/([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)/\4.\3.\2.\1/')
    fi
    
    # If not found, try to get default gateway
    if [ -z "$HOST_IP" ] && command -v ip > /dev/null; then
      HOST_IP=$(ip route | grep default | head -1 | awk '{print $3}')
    fi
    
    # Measure latency to host if we found an IP
    if [ -n "$HOST_IP" ]; then
      echo -e "Testing network latency to host: ${HOST_IP}"
      
      # Check if ping is available
      if command -v ping > /dev/null; then
        PING_RESULT=$(ping -c 5 "$HOST_IP" 2>/dev/null || echo "Error")
        if [[ "$PING_RESULT" != "Error" ]]; then
          AVG_LATENCY=$(echo "$PING_RESULT" | grep "avg" | awk -F'/' '{print $5}')
          echo -e "Average latency to host: ${BOLD}${AVG_LATENCY} ms${NC}"
          echo "host_latency_ms=$AVG_LATENCY"
        else
          echo -e "${YELLOW}Could not ping host, trying HTTP latency test${NC}"
        fi
      fi
      
      # Try to measure HTTP latency as backup
      if command -v curl > /dev/null; then
        # Try to connect to common ports
        for PORT in 80 8080 443; do
          HTTP_LATENCY=$(curl -o /dev/null -s -w "%{time_connect}\n" "http://${HOST_IP}:${PORT}" 2>/dev/null || echo "Error")
          if [[ "$HTTP_LATENCY" != "Error" ]]; then
            HTTP_MS=$(echo "$HTTP_LATENCY * 1000" | bc)
            echo -e "HTTP connection latency (port ${PORT}): ${BOLD}${HTTP_MS} ms${NC}"
            echo "http_latency_ms=$HTTP_MS"
            break
          fi
        done
      fi
    else
      echo -e "${YELLOW}Could not determine host IP to measure network latency${NC}"
    fi
    
    # Try to check external connectivity
    echo -e "\nTesting external network connectivity..."
    if command -v curl > /dev/null; then
      EXTERNAL_LATENCY=$(curl -o /dev/null -s -w "%{time_connect}\n" "https://maven.apache.org" 2>/dev/null || echo "Error")
      if [[ "$EXTERNAL_LATENCY" != "Error" ]]; then
        EXTERNAL_MS=$(echo "$EXTERNAL_LATENCY * 1000" | bc)
        echo -e "External connection latency: ${BOLD}${EXTERNAL_MS} ms${NC}"
        echo "external_latency_ms=$EXTERNAL_MS"
      else
        echo -e "${YELLOW}Could not measure external connectivity${NC}"
      fi
    else
      echo -e "${YELLOW}curl not available to test network connectivity${NC}"
    fi
  fi
}

# Get JVM information
get_jvm_info() {
  if command -v java >/dev/null 2>&1; then
    JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
    JAVA_HOME="${JAVA_HOME:-Unknown}"
    JVM_ARCH=$(java -XshowSettings:properties -version 2>&1 | grep sun.arch.data.model | awk '{print $3}')
    
    echo "java_version=$JAVA_VERSION"
    echo "java_home=$JAVA_HOME"
    echo "jvm_arch=$JVM_ARCH"
  else
    echo "java_available=false"
  fi
}

# Get Maven information
get_maven_info() {
  if command -v mvn >/dev/null 2>&1; then
    MVN_VERSION=$(mvn --version | head -1 | awk '{print $3}')
    
    # Try to extract current Maven settings from pom.xml
    if [ -f "pom.xml" ]; then
      # Extract fork count and threads if available
      if grep -q "<jvm.fork.count>" pom.xml; then
        FORK_COUNT=$(grep -E "<jvm.fork.count>" pom.xml | grep -oE "[0-9.]+C?" | head -1)
      else
        FORK_COUNT="Not specified"
      fi
      
      if grep -q "<maven.threads>" pom.xml; then
        THREADS=$(grep -E "<maven.threads>" pom.xml | grep -oE "[0-9]+" | head -1)
      else
        THREADS="Not specified"
      fi
      
      echo "maven_version=$MVN_VERSION"
      echo "maven_fork_count=$FORK_COUNT"
      echo "maven_threads=$THREADS"
    else
      echo "maven_version=$MVN_VERSION"
      echo "pom_available=false"
    fi
  else
    echo "maven_available=false"
  fi
}

# Main function to analyze the environment and detect key characteristics
analyze_environment() {
  local RESULT_DIR=$1
  
  echo -e "${BOLD}${BLUE}=== Environment Analysis ===${NC}"
  
  # Detect environment type
  ENV_TYPE=$(detect_container)
  echo -e "Environment type: ${BOLD}${ENV_TYPE}${NC}"
  
  # Get CPU info
  CPU_INFO=$(get_cpu_info)
  CPU_COUNT=$(echo "$CPU_INFO" | grep "cpu_count" | cut -d= -f2)
  CPU_MODEL=$(echo "$CPU_INFO" | grep "cpu_model" | cut -d= -f2-)
  echo -e "CPU: ${CPU_MODEL} (${CPU_COUNT} cores)"
  
  # Get memory info
  MEM_INFO=$(get_memory_info)
  MEM_TOTAL=$(echo "$MEM_INFO" | grep "memory_total_mb" | cut -d= -f2)
  MEM_FREE=$(echo "$MEM_INFO" | grep "memory_free_mb" | cut -d= -f2)
  echo -e "Memory: ${MEM_TOTAL}MB total, ${MEM_FREE}MB available"
  
  # Get JVM info
  JVM_INFO=$(get_jvm_info)
  JAVA_VERSION=$(echo "$JVM_INFO" | grep "java_version" | cut -d= -f2)
  echo -e "Java: ${JAVA_VERSION}"
  
  # Get Maven info
  MVN_INFO=$(get_maven_info)
  MVN_VERSION=$(echo "$MVN_INFO" | grep "maven_version" | cut -d= -f2)
  echo -e "Maven: ${MVN_VERSION}"
  
  # Container-specific analysis
  if [[ "$ENV_TYPE" != "bare-metal" ]]; then
    echo -e "\n${BOLD}${CYAN}Container-Specific Analysis:${NC}"
    CONTAINER_LIMITS=$(detect_container_limits "$ENV_TYPE")
    
    if echo "$CONTAINER_LIMITS" | grep -q "container_memory_limit"; then
      MEM_LIMIT=$(echo "$CONTAINER_LIMITS" | grep "container_memory_limit_mb" | cut -d= -f2)
      echo -e "Container memory limit: ${BOLD}${MEM_LIMIT}MB${NC}"
      
      # Check if container memory is significantly less than host memory
      if (( MEM_LIMIT < MEM_TOTAL / 2 )); then
        echo -e "${YELLOW}Warning: Container memory limit (${MEM_LIMIT}MB) is less than 50% of host memory (${MEM_TOTAL}MB)${NC}"
      fi
    fi
    
    if echo "$CONTAINER_LIMITS" | grep -q "container_cpu_limit"; then
      CPU_LIMIT=$(echo "$CONTAINER_LIMITS" | grep "container_cpu_limit" | cut -d= -f2)
      echo -e "Container CPU limit: ${BOLD}${CPU_LIMIT} cores${NC}"
      
      # Check if container CPU is significantly less than host CPU
      if (( $(echo "$CPU_LIMIT < $CPU_COUNT / 2" | bc -l) )); then
        echo -e "${YELLOW}Warning: Container CPU limit (${CPU_LIMIT}) is less than 50% of host CPUs (${CPU_COUNT})${NC}"
      fi
    fi
    
    # Network latency analysis for containers
    NETWORK_INFO=$(measure_network_latency "$ENV_TYPE")
  fi
  
  # Write environment info to file for later analysis
  mkdir -p "${RESULT_DIR}"
  ENV_FILE="${RESULT_DIR}/environment.txt"
  
  echo "MVNimble Environment Analysis" > "$ENV_FILE"
  echo "=============================" >> "$ENV_FILE"
  echo "Date: $(date)" >> "$ENV_FILE"
  echo "Environment Type: $ENV_TYPE" >> "$ENV_FILE"
  echo "" >> "$ENV_FILE"
  echo "CPU Information:" >> "$ENV_FILE"
  echo "$CPU_INFO" >> "$ENV_FILE"
  echo "" >> "$ENV_FILE"
  echo "Memory Information:" >> "$ENV_FILE"
  echo "$MEM_INFO" >> "$ENV_FILE"
  echo "" >> "$ENV_FILE"
  echo "JVM Information:" >> "$ENV_FILE"
  echo "$JVM_INFO" >> "$ENV_FILE"
  echo "" >> "$ENV_FILE"
  echo "Maven Information:" >> "$ENV_FILE"
  echo "$MVN_INFO" >> "$ENV_FILE"
  echo "" >> "$ENV_FILE"
  
  if [[ "$ENV_TYPE" != "bare-metal" ]]; then
    echo "Container Limits:" >> "$ENV_FILE"
    echo "$CONTAINER_LIMITS" >> "$ENV_FILE"
    echo "" >> "$ENV_FILE"
    
    if [ -n "$NETWORK_INFO" ]; then
      echo "Network Information:" >> "$ENV_FILE"
      echo "$NETWORK_INFO" >> "$ENV_FILE"
      echo "" >> "$ENV_FILE"
    fi
  fi
  
  echo -e "Environment analysis saved to: ${BOLD}${ENV_FILE}${NC}"
  echo
  
  # Return a JSON-like string with key environment characteristics
  echo "env_type=$ENV_TYPE,cpu_count=$CPU_COUNT,mem_total=$MEM_TOTAL,mem_free=$MEM_FREE"
}