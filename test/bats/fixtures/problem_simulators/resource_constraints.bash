#!/usr/bin/env bash
# resource_constraints.bash
# Test doubles to simulate various resource constraints in test environments
#
# This file INTENTIONALLY creates problematic resource constraint scenarios to allow
# MVNimble to detect and diagnose performance issues in Maven test environments.
# Each simulation reproduces realistic resource limitation patterns that commonly
# occur in CI/CD environments, containerized builds, and shared build infrastructure.
#
# ANTIPATTERNS IMPLEMENTED:
#
# 1. CPU Constraints
#    - Simulates high CPU load conditions with controlled intensity
#    - Creates throttled CPU environments similar to container CPU limits
#    - Tests application behavior under processing power constraints
#
# 2. Memory Constraints
#    - Simulates memory pressure by allocating large blocks of memory
#    - Creates scenarios with specific memory limitations
#    - Tests application resilience to memory constraints and OOM conditions
#
# 3. Disk I/O Constraints
#    - Simulates disk I/O bottlenecks and limited throughput
#    - Creates slow storage conditions common in virtualized environments
#    - Tests application behavior with constrained storage performance
#
# 4. File Descriptor Limitations
#    - Simulates reaching system file descriptor limits
#    - Creates scenarios where file operations fail due to resource exhaustion
#    - Tests application handling of "too many open files" conditions
#
# 5. Combination Resource Constraints
#    - Simulates realistic multi-resource constraints
#    - Creates compound bottleneck scenarios often seen in real environments
#    - Tests application behavior under complex resource limitation patterns
#
# EDUCATIONAL PURPOSE:
# These simulations are designed to help users understand how system resource
# constraints affect build and test performance. They provide controlled
# environments for diagnosing and fixing resource-related issues in Maven 
# builds, enabling the development of more resilient build processes.

# Load test helpers
source "${BATS_TEST_DIRNAME:-$(dirname "$0")/..}/test_helper.bash"

# ------------------------------------------------------------------------------
# CPU CONSTRAINT SIMULATION
# ------------------------------------------------------------------------------

# Simulates high CPU load by running CPU-intensive calculations in background
simulate_high_cpu_load() {
  local intensity="${1:-75}"  # Default to 75% CPU load
  local duration="${2:-10}"   # Default to 10 seconds
  local cores="${3:-1}"       # Default to 1 core
  
  # Validate parameters
  if [[ "$intensity" -lt 1 || "$intensity" -gt 100 ]]; then
    echo "Error: CPU load intensity must be between 1-100" >&2
    return 1
  fi
  
  echo "Simulating ${intensity}% CPU load on ${cores} cores for ${duration} seconds..."
  
  # Function to create CPU load with specified intensity
  create_cpu_load() {
    local intensity="$1"
    local duration="$2"
    local end_time=$(($(date +%s) + duration))
    
    # Calculate work/sleep ratio to achieve target intensity
    local work_time=$((intensity))
    local sleep_time=$((100 - intensity))
    
    # Very small sleep time causes issues, set minimum
    if [[ "$sleep_time" -lt 5 ]]; then
      sleep_time=5
    fi
    
    # Convert to milliseconds and adjust
    work_time=$((work_time * 10))
    sleep_time=$((sleep_time * 10))
    
    while [[ $(date +%s) -lt $end_time ]]; do
      # Do CPU-intensive work
      for i in {1..10000}; do
        echo "scale=10; a(1)*4" | bc -l >/dev/null 2>&1
        
        # Check if we should stop (early termination)
        if [[ $(date +%s) -ge $end_time ]]; then
          break
        fi
      done
      
      # Sleep proportionally to target intensity
      if [[ "$sleep_time" -gt 0 ]]; then
        sleep 0.$sleep_time
      fi
    done
  }
  
  # Start background load generators
  for ((i=1; i<=cores; i++)); do
    create_cpu_load "$intensity" "$duration" &
  done
  
  # Return PIDs for potential cleanup
  jobs -p
}

# Stop simulated CPU load
stop_high_cpu_load() {
  local pids="$@"
  
  if [[ -z "$pids" ]]; then
    # Get all background jobs if no specific PIDs provided
    pids=$(jobs -p)
  fi
  
  for pid in $pids; do
    kill -9 "$pid" 2>/dev/null || true
  done
}

# Simulates CPU throttling through cgroup restrictions (Linux only)
simulate_cpu_throttling() {
  local limit="${1:-50}"  # Default to 50% CPU limit
  
  # Check if running on Linux with cgroups
  if ! grep -q cgroup /proc/mounts 2>/dev/null; then
    echo "Error: CPU throttling simulation requires Linux with cgroups" >&2
    return 1
  fi
  
  # Create temporary cgroup
  local cgroup_dir="/sys/fs/cgroup/cpu/mvnimble_test"
  
  echo "Simulating CPU throttling (${limit}% limit)..."
  
  # Clean up any existing cgroup
  if [[ -d "$cgroup_dir" ]]; then
    rmdir "$cgroup_dir" 2>/dev/null || true
  fi
  
  # Create cgroup and set CPU limit
  mkdir -p "$cgroup_dir" 2>/dev/null || true
  
  # Calculate quota based on period
  local period=100000
  local quota=$((period * limit / 100))
  
  # Set CPU limit
  echo "$period" > "$cgroup_dir/cpu.cfs_period_us" 2>/dev/null || true
  echo "$quota" > "$cgroup_dir/cpu.cfs_quota_us" 2>/dev/null || true
  
  # Add current process to cgroup
  echo $$ > "$cgroup_dir/tasks" 2>/dev/null || true
  
  # Return the cgroup directory for cleanup
  echo "$cgroup_dir"
}

# Stop CPU throttling simulation
stop_cpu_throttling() {
  local cgroup_dir="${1:-/sys/fs/cgroup/cpu/mvnimble_test}"
  
  if [[ -d "$cgroup_dir" ]]; then
    # Move process back to root cgroup
    echo $$ > /sys/fs/cgroup/cpu/tasks 2>/dev/null || true
    # Remove cgroup
    rmdir "$cgroup_dir" 2>/dev/null || true
  fi
}

# Function to mock /proc/cpuinfo with fewer cores
mock_limited_cpu_cores() {
  local cores="${1:-1}"  # Default to 1 core
  local temp_file=$(mktemp)
  
  # Generate mock cpuinfo with specified number of cores
  for ((i=0; i<cores; i++)); do
    cat << EOF >> "$temp_file"
processor : $i
vendor_id : MockCPU
model name : Mock CPU @ 2.20GHz
cpu MHz : 2200.000
cache size : 28160 KB
physical id : 0
siblings : $cores
core id : $i
cpu cores : $cores
EOF
    # Add separator except for last entry
    if [[ $i -lt $((cores-1)) ]]; then
      echo "" >> "$temp_file"
    fi
  done
  
  # Mock the command to use our fake cpuinfo
  mock_command "cat" 0 "$(cat "$temp_file")" "/proc/cpuinfo"
  
  # Clean up
  rm -f "$temp_file"
}

# ------------------------------------------------------------------------------
# MEMORY CONSTRAINT SIMULATION
# ------------------------------------------------------------------------------

# Simulates memory pressure by allocating large chunks of memory
simulate_memory_pressure() {
  local percentage="${1:-80}"  # Default to 80% of available memory
  local duration="${2:-10}"    # Default to 10 seconds
  
  # Get total available memory in KB
  local total_mem
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS
    total_mem=$(sysctl -n hw.memsize 2>/dev/null || echo 0)
    total_mem=$((total_mem / 1024))  # Convert bytes to KB
  else
    # Linux
    total_mem=$(grep MemAvailable /proc/meminfo 2>/dev/null | awk '{print $2}')
    # If MemAvailable is not present, use free memory
    if [[ -z "$total_mem" ]]; then
      total_mem=$(grep MemFree /proc/meminfo 2>/dev/null | awk '{print $2}')
    fi
  fi
  
  # Calculate how much memory to allocate in KB
  local allocate=$((total_mem * percentage / 100))
  
  echo "Simulating memory pressure (${percentage}% of available memory for ${duration} seconds)..."
  
  # Function to allocate memory
  allocate_memory() {
    local amount="$1"
    local duration="$2"
    local end_time=$(($(date +%s) + duration))
    
    # Allocate memory using shell arrays (less efficient but portable)
    local array=()
    local chunk_size=1024  # Allocate in 1MB chunks
    local chunks=$((amount / chunk_size))
    
    for ((i=0; i<chunks; i++)); do
      array+=("$(dd if=/dev/zero bs=1024 count=$chunk_size 2>/dev/null)")
      # Print progress
      if [[ $((i % 10)) -eq 0 ]]; then
        echo -n "." >&2
      fi
    done
    
    echo "Memory allocated: $((chunks * chunk_size))KB" >&2
    
    # Hold the memory for specified duration
    sleep "$duration"
  }
  
  # Run in background
  allocate_memory "$allocate" "$duration" &
  
  # Return PID for cleanup
  echo $!
}

# Function to limit available memory using cgroups (Linux only)
simulate_memory_limit() {
  local limit_mb="${1:-512}"  # Default to 512MB limit
  
  # Check if running on Linux with cgroups
  if ! grep -q cgroup /proc/mounts 2>/dev/null; then
    echo "Error: Memory limit simulation requires Linux with cgroups" >&2
    return 1
  fi
  
  # Create temporary cgroup
  local cgroup_dir="/sys/fs/cgroup/memory/mvnimble_test"
  
  echo "Simulating memory limit (${limit_mb}MB)..."
  
  # Clean up any existing cgroup
  if [[ -d "$cgroup_dir" ]]; then
    rmdir "$cgroup_dir" 2>/dev/null || true
  fi
  
  # Create cgroup and set memory limit
  mkdir -p "$cgroup_dir" 2>/dev/null || true
  
  # Convert MB to bytes
  local limit_bytes=$((limit_mb * 1024 * 1024))
  
  # Set memory limit
  echo "$limit_bytes" > "$cgroup_dir/memory.limit_in_bytes" 2>/dev/null || true
  
  # Add current process to cgroup
  echo $$ > "$cgroup_dir/tasks" 2>/dev/null || true
  
  # Return the cgroup directory for cleanup
  echo "$cgroup_dir"
}

# Stop memory limit simulation
stop_memory_limit() {
  local cgroup_dir="${1:-/sys/fs/cgroup/memory/mvnimble_test}"
  
  if [[ -d "$cgroup_dir" ]]; then
    # Move process back to root cgroup
    echo $$ > /sys/fs/cgroup/memory/tasks 2>/dev/null || true
    # Remove cgroup
    rmdir "$cgroup_dir" 2>/dev/null || true
  fi
}

# Mock limited memory for detection functions
mock_limited_memory() {
  local total_mb="${1:-1024}"  # Default to 1GB total memory
  local free_mb="${2:-256}"    # Default to 256MB free memory
  
  # Convert to KB for proc format
  local total_kb=$((total_mb * 1024))
  local free_kb=$((free_mb * 1024))
  local used_kb=$((total_kb - free_kb))
  
  # Create mock memory info
  local meminfo=$(cat << EOF
MemTotal:       ${total_kb} kB
MemFree:        ${free_kb} kB
MemAvailable:   ${free_kb} kB
Buffers:        0 kB
Cached:         0 kB
SwapCached:     0 kB
Active:         ${used_kb} kB
Inactive:       0 kB
EOF
)
  
  # Mock the command to use our fake meminfo
  mock_command "cat" 0 "$meminfo" "/proc/meminfo"
  
  # For macOS, also mock sysctl
  if [[ "$(uname)" == "Darwin" ]]; then
    mock_command "sysctl" 0 "hw.memsize: $((total_mb * 1024 * 1024))" "-n hw.memsize"
    mock_command "sysctl" 0 "hw.usermem: $((free_mb * 1024 * 1024))" "-n hw.usermem"
  fi
}

# ------------------------------------------------------------------------------
# DISK I/O CONSTRAINT SIMULATION
# ------------------------------------------------------------------------------

# Simulates slow disk I/O by throttling disk operations
simulate_slow_disk() {
  local read_rate="${1:-1024}"   # Default to 1MB/s read rate
  local write_rate="${2:-1024}"  # Default to 1MB/s write rate
  local temp_dir="${3:-$(mktemp -d)}"
  
  echo "Simulating slow disk I/O (read: ${read_rate}KB/s, write: ${write_rate}KB/s)..."
  
  # Create temp mount point
  mkdir -p "$temp_dir"
  
  # Check if we have necessary tools
  if ! command -v ionice >/dev/null 2>&1; then
    echo "Warning: ionice not available, using basic I/O simulation" >&2
    
    # Simple wrapper functions to simulate slow I/O
    cat() {
      local src="$1"
      local size=$(stat -c %s "$src" 2>/dev/null || stat -f %z "$src")
      local chunks=$((size / 4096 + 1))
      
      command cat "$@" | while read -n 4096 chunk; do
        echo -n "$chunk"
        sleep 0.$(printf "%03d" $((4096 * 1000 / read_rate)))
      done
    }
    
    cp() {
      local src="$1"
      local dst="$2"
      local size=$(stat -c %s "$src" 2>/dev/null || stat -f %z "$src")
      
      command dd if="$src" of="$dst" bs=4k status=none
      sleep 0.$(printf "%03d" $((size * 1000 / write_rate)))
    }
    
    export -f cat
    export -f cp
    
    return 0
  fi
  
  # Use ionice to set I/O priority to lowest
  ionice -c 3 -p $$ >/dev/null 2>&1
  
  # Return the temp directory
  echo "$temp_dir"
}

# Stop slow disk simulation
stop_slow_disk() {
  local temp_dir="$1"
  
  # Reset I/O priority
  if command -v ionice >/dev/null 2>&1; then
    ionice -c 2 -n 0 -p $$ >/dev/null 2>&1
  fi
  
  # Clean up temp directory
  if [[ -n "$temp_dir" && -d "$temp_dir" ]]; then
    rm -rf "$temp_dir"
  fi
  
  # Unset any function overrides
  unset -f cat cp 2>/dev/null || true
}

# Mock disk space issues
mock_disk_space_issues() {
  local free_space_mb="${1:-100}"  # Default to 100MB free
  
  # Create mock df output
  local df_output="Filesystem 1K-blocks Used Available Use% Mounted on"
  
  # Add root filesystem with limited space
  df_output+=$'\n'"/ $((free_space_mb * 1024 + 5000000)) 5000000 $((free_space_mb * 1024)) $((100 - free_space_mb / 50))% /"
  
  # Mock df command
  mock_command "df" 0 "$df_output"
  
  # Also mock disk space check function in MVNimble
  if type -t check_disk_space >/dev/null; then
    # If the function exists, add a mock version
    eval "original_check_disk_space=$(declare -f check_disk_space)"
    
    check_disk_space() {
      echo "Available disk space: ${free_space_mb}MB"
      if [[ "$free_space_mb" -lt 500 ]]; then
        echo "WARNING: Low disk space" >&2
        return 2
      elif [[ "$free_space_mb" -lt 1000 ]]; then
        echo "Warning: Disk space is less than recommended" >&2
        return 1
      fi
      return 0
    }
    
    export -f check_disk_space
  fi
}

# Restore original disk space check
restore_disk_space_check() {
  if [[ -n "$original_check_disk_space" ]]; then
    eval "$original_check_disk_space"
    export -f check_disk_space
    unset original_check_disk_space
  fi
}

# ------------------------------------------------------------------------------
# TEST EXECUTION HELPERS
# ------------------------------------------------------------------------------

# Function to measure execution time with resource constraints
measure_execution_with_constraints() {
  local cmd="$1"
  local constraint_type="$2"
  local constraint_level="$3"
  local cleanup_cmd=""
  
  # Apply constraint based on type
  case "$constraint_type" in
    cpu_load)
      local pids=$(simulate_high_cpu_load "$constraint_level")
      cleanup_cmd="stop_high_cpu_load $pids"
      ;;
    memory_pressure)
      local pid=$(simulate_memory_pressure "$constraint_level")
      cleanup_cmd="kill -9 $pid 2>/dev/null || true"
      ;;
    slow_disk)
      local temp_dir=$(simulate_slow_disk "$constraint_level")
      cleanup_cmd="stop_slow_disk $temp_dir"
      ;;
    *)
      echo "Unknown constraint type: $constraint_type" >&2
      return 1
      ;;
  esac
  
  # Measure execution time
  local start_time=$(date +%s.%N)
  
  # Execute the command
  eval "$cmd"
  local status=$?
  
  # Calculate execution time
  local end_time=$(date +%s.%N)
  local duration=$(echo "$end_time - $start_time" | bc)
  
  # Clean up
  if [[ -n "$cleanup_cmd" ]]; then
    eval "$cleanup_cmd"
  fi
  
  # Return results
  echo "$duration"
  return $status
}

# Function to run a command with multiple constraints
run_with_constraints() {
  local cmd="$1"
  shift
  
  # Parse constraints
  local constraints=()
  local cleanup_cmds=()
  
  while [[ $# -gt 0 ]]; do
    local constraint_type="$1"
    local constraint_level="$2"
    shift 2
    
    case "$constraint_type" in
      cpu_load)
        local pids=$(simulate_high_cpu_load "$constraint_level")
        cleanup_cmds+=("stop_high_cpu_load $pids")
        ;;
      cpu_cores)
        mock_limited_cpu_cores "$constraint_level"
        cleanup_cmds+=("mock_command \"cat\" 0 \"$(cat /proc/cpuinfo 2>/dev/null || echo 'processor : 0')\" \"/proc/cpuinfo\"")
        ;;
      memory_pressure)
        local pid=$(simulate_memory_pressure "$constraint_level")
        cleanup_cmds+=("kill -9 $pid 2>/dev/null || true")
        ;;
      memory_limit)
        local cgroup_dir=$(simulate_memory_limit "$constraint_level" 2>/dev/null || echo "")
        if [[ -n "$cgroup_dir" ]]; then
          cleanup_cmds+=("stop_memory_limit $cgroup_dir")
        fi
        ;;
      slow_disk)
        local temp_dir=$(simulate_slow_disk "$constraint_level")
        cleanup_cmds+=("stop_slow_disk $temp_dir")
        ;;
      disk_space)
        mock_disk_space_issues "$constraint_level"
        cleanup_cmds+=("restore_disk_space_check")
        ;;
      *)
        echo "Unknown constraint type: $constraint_type" >&2
        # Clean up any previous constraints
        for cleanup_cmd in "${cleanup_cmds[@]}"; do
          eval "$cleanup_cmd"
        done
        return 1
        ;;
    esac
  done
  
  # Run the command
  eval "$cmd"
  local status=$?
  
  # Clean up all constraints
  for cleanup_cmd in "${cleanup_cmds[@]}"; do
    eval "$cleanup_cmd" || true
  done
  
  return $status
}

# Helper to create a realistic performance profile of test execution under constraints
generate_performance_profile() {
  local cmd="$1"
  local output_file="${2:-performance_profile.csv}"
  
  echo "Constraint Type,Constraint Level,Execution Time (s),Status" > "$output_file"
  
  # Test with various constraints
  
  # Baseline (no constraints)
  echo "Measuring baseline performance..."
  local baseline=$(measure_execution_with_constraints "$cmd" "cpu_load" "0")
  echo "None,0,$baseline,0" >> "$output_file"
  
  # CPU Load constraints
  for load in 30 50 70 90; do
    echo "Measuring with ${load}% CPU load..."
    local time=$(measure_execution_with_constraints "$cmd" "cpu_load" "$load")
    local status=$?
    echo "CPU Load,$load,$time,$status" >> "$output_file"
  done
  
  # Memory pressure constraints
  for pressure in 50 70 85; do
    echo "Measuring with ${pressure}% memory pressure..."
    local time=$(measure_execution_with_constraints "$cmd" "memory_pressure" "$pressure")
    local status=$?
    echo "Memory Pressure,$pressure,$time,$status" >> "$output_file"
  done
  
  # Disk I/O constraints
  for rate in 5120 1024 512; do
    echo "Measuring with ${rate}KB/s disk I/O..."
    local time=$(measure_execution_with_constraints "$cmd" "slow_disk" "$rate")
    local status=$?
    echo "Slow Disk,$rate,$time,$status" >> "$output_file"
  done
  
  echo "Performance profile generated: $output_file"
}