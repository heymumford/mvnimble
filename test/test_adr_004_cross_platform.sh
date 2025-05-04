#!/bin/bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# test_adr_004_cross_platform.sh
# Tests for ADR 004: Cross-Platform Compatibility
#
# This test suite validates that the codebase follows the cross-platform
# compatibility requirements defined in ADR 004.

# Source test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./test.sh
source "${SCRIPT_DIR}/test.sh"

# Source platform_compatibility module for direct testing
# shellcheck source=../src/lib/modules/platform_compatibility.sh
source "${SCRIPT_DIR}/../src/lib/modules/platform_compatibility.sh"

# Test that the platform compatibility module exists
test_platform_compatibility_module_exists() {
  assert_file_exists "${SCRIPT_DIR}/../src/lib/modules/platform_compatibility.sh" "Platform compatibility module should exist"
}

# Test platform detection function
test_detect_operating_system() {
  # Function should return one of the supported platforms
  local platform
  platform=$(detect_operating_system)
  
  # Result should not be empty
  assert_not_equal "" "$platform" "Platform detection should return a value"
  
  # Result should be a valid platform
  local is_valid=false
  case "$platform" in
    macos|linux|unknown)
      is_valid=true
      ;;
    *)
      is_valid=false
      ;;
  esac
  
  assert_equal "true" "$is_valid" "Platform detection should return a valid platform"
}

# Test CPU information abstraction
test_cpu_information_abstraction() {
  # CPU count function
  local cpu_count
  cpu_count=$(get_cpu_count)
  
  # Should return a positive number
  assert_not_equal "" "$cpu_count" "CPU count should not be empty"
  [[ "$cpu_count" -gt 0 ]] || return 1
  
  # CPU model function
  local cpu_model
  cpu_model=$(get_cpu_model)
  
  # Should return a non-empty string
  assert_not_equal "" "$cpu_model" "CPU model should not be empty"
  
  # CPU speed function
  local cpu_speed
  cpu_speed=$(get_cpu_speed_mhz)
  
  # Should return a positive number
  assert_not_equal "" "$cpu_speed" "CPU speed should not be empty"
  
  return 0
}

# Test memory information abstraction
test_memory_information_abstraction() {
  # Total memory function
  local total_memory
  total_memory=$(get_total_memory_mb)
  
  # Should return a positive number
  assert_not_equal "" "$total_memory" "Total memory should not be empty"
  [[ "$total_memory" -gt 0 ]] || return 1
  
  # Free memory function
  local free_memory
  free_memory=$(get_free_memory_mb)
  
  # Should return a positive number
  assert_not_equal "" "$free_memory" "Free memory should not be empty"
  [[ "$free_memory" -ge 0 ]] || return 1
  
  # Free memory should not exceed total memory
  [[ "$free_memory" -le "$total_memory" ]] || return 1
  
  return 0
}

# Test disk space abstraction
test_disk_space_abstraction() {
  # Free disk space function
  local free_space
  free_space=$(get_free_disk_space_mb)
  
  # Should return a positive number
  assert_not_equal "" "$free_space" "Free disk space should not be empty"
  [[ "$free_space" -ge 0 ]] || return 1
  
  return 0
}

# Test elapsed time calculation abstraction
test_elapsed_time_calculation() {
  # Calculate elapsed time with known values
  local start_time=100
  local end_time=150
  local elapsed
  elapsed=$(calculate_elapsed_time "$start_time" "$end_time")
  
  # Should return the correct difference
  assert_not_equal "" "$elapsed" "Elapsed time should not be empty"
  
  # On Linux with bc, the result will be exactly 50
  # On macOS with perl, the result will be close to 50 due to floating-point rounding
  # We'll check that it's between 49.9 and 50.1 to accommodate both
  local is_valid=false
  if (( $(echo "$elapsed >= 49.9 && $elapsed <= 50.1" | bc -l) )); then
    is_valid=true
  fi
  
  assert_equal "true" "$is_valid" "Elapsed time calculation should return approximate expected value"
  
  return 0
}

# Test file editing abstraction
test_file_editing_abstraction() {
  # Create a temporary file
  local tmp_file
  tmp_file=$(mktemp)
  
  # Write test content
  echo "This is a test string to replace" > "$tmp_file"
  
  # Use modify_file_in_place to replace text
  modify_file_in_place "$tmp_file" "test string" "replacement string"
  
  # Verify replacement worked
  local content
  content=$(cat "$tmp_file")
  
  assert_contains "replacement string" "$content" "File modification should replace text correctly"
  
  # Clean up
  rm -f "$tmp_file"
  
  return 0
}

# Test container detection abstraction
test_container_detection_abstraction() {
  # Function should return a valid environment type
  local env_type
  
  # We don't have direct access to detect_container_environment since it's in another module,
  # so we'll check that the function exists in the environment_detection.sh module
  local detection_module="${SCRIPT_DIR}/../src/lib/modules/environment_detection.sh"
  assert_file_exists "$detection_module" "Environment detection module should exist"
  
  # Check for container detection function
  local has_container_detection=false
  if grep -q "detect_container_environment" "$detection_module"; then
    has_container_detection=true
  fi
  
  assert_equal "true" "$has_container_detection" "Container detection function should exist"
  
  # Check that it has the required container detection signs
  local has_required_checks=true
  local required_patterns=(
    "/.dockerenv"
    "docker|lxc"
    "kubepods"
  )
  
  for pattern in "${required_patterns[@]}"; do
    if ! grep -q "$pattern" "$detection_module"; then
      echo "Missing container detection pattern: $pattern"
      has_required_checks=false
    fi
  done
  
  assert_equal "true" "$has_required_checks" "Container detection should check for required indicators"
  
  return 0
}

# Test process monitoring abstraction
test_process_monitoring_abstraction() {
  # Test get_current_pid
  local pid
  pid=$(get_current_pid)
  
  # Should return a positive number
  assert_not_equal "" "$pid" "Current PID should not be empty"
  [[ "$pid" -gt 0 ]] || return 1
  
  # Test get_process_memory_usage_mb with own PID
  local mem_usage
  mem_usage=$(get_process_memory_usage_mb "$pid")
  
  # Should return a positive number
  assert_not_equal "" "$mem_usage" "Memory usage should not be empty"
  [[ "$mem_usage" -ge 0 ]] || return 1
  
  # Test get_process_cpu_usage with own PID
  local cpu_usage
  cpu_usage=$(get_process_cpu_usage "$pid")
  
  # Should return a number (potentially 0 if idle)
  assert_not_equal "" "$cpu_usage" "CPU usage should not be empty"
  
  return 0
}

# Test available platform information
test_available_platform_information() {
  # Get a list of all platform information functions
  local platform_funcs
  platform_funcs=$(grep -E "^function get_" "${SCRIPT_DIR}/../src/lib/modules/platform_compatibility.sh" | awk '{print $2}' | cut -d'(' -f1)
  
  # Each function should return a non-empty value
  for func in $platform_funcs; do
    # Skip non-information functions
    if [[ "$func" == "get_current_pid" ]]; then
      continue
    fi
    
    local value
    if [[ "$func" == *"_mb" ]]; then
      # Functions that take a parameter, use own PID for testing
      local pid
      pid=$(get_current_pid)
      value=$("$func" "$pid")
    else
      # Functions without parameters
      value=$("$func")
    fi
    
    assert_not_equal "" "$value" "Function $func should return a non-empty value"
  done
  
  return 0
}

# Test environment-specific code isolation
test_environment_specific_code_isolation() {
  local modules_dir="${SCRIPT_DIR}/../src/lib/modules"
  local platform_module="${modules_dir}/platform_compatibility.sh"
  local env_detection_module="${modules_dir}/environment_detection.sh"
  local all_valid=0
  
  # Platform-specific checks that should be isolated
  local platform_checks=(
    "uname.*Darwin"
    "sysctl -n"
    "/proc/cpuinfo"
    "/proc/meminfo"
  )
  
  # Check each module except platform_compatibility.sh and environment_detection.sh
  for module in "${modules_dir}"/*.sh; do
    local module_name="$(basename "$module")"
    
    # Skip the platform and environment detection modules
    if [[ "$module_name" == "platform_compatibility.sh" || "$module_name" == "environment_detection.sh" ]]; then
      continue
    fi
    
    # Check for platform-specific code outside of allowed modules
    for check in "${platform_checks[@]}"; do
      if grep -q "$check" "$module"; then
        echo "Module $module_name has platform-specific code: $check"
        all_valid=1
      fi
    done
  done
  
  return $all_valid
}

# Test fallback mechanisms for commands
test_fallback_mechanisms() {
  # Check several functions for fallbacks between platforms
  local platform_module="${SCRIPT_DIR}/../src/lib/modules/platform_compatibility.sh"
  
  # Look for conditional structures that switch between platforms
  local has_darwin_conditionals=false
  if grep -q "\$(detect_operating_system).*==.*macos" "$platform_module"; then
    has_darwin_conditionals=true
  fi
  
  assert_equal "true" "$has_darwin_conditionals" "Platform compatibility should have MacOS-specific conditionals"
  
  # Look for secondary method fallbacks (e.g. perl vs bc)
  local has_fallbacks=false
  if grep -q "command -v perl" "$platform_module" || 
     grep -q "command -v bc" "$platform_module" || 
     grep -q "command -v readlink" "$platform_module"; then
    has_fallbacks=true
  fi
  
  assert_equal "true" "$has_fallbacks" "Platform compatibility should have command fallbacks"
  
  return 0
}

# Test environment variable override capability
test_environment_variable_overrides() {
  local modules=("${SCRIPT_DIR}/../src/lib/modules/platform_compatibility.sh" "${SCRIPT_DIR}/../src/lib/modules/environment_detection.sh")
  local supports_overrides=false
  
  for module in "${modules[@]}"; do
    # Look for environment variable usage with fallbacks
    if grep -q "SCRIPT_DIR=.*:-" "$module" || grep -q "\${.*:-" "$module"; then
      supports_overrides=true
      break
    fi
  done
  
  assert_equal "true" "$supports_overrides" "Modules should support environment variable overrides"
  
  return 0
}

# Run the tests if this file is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_all_tests "$(basename "${BASH_SOURCE[0]}")"
fi