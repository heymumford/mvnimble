#!/bin/bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# test_adr_001_shell_architecture.sh
# Tests for ADR 001: Shell Script Architecture
#
# This test suite validates that the shell script architecture meets
# the requirements defined in ADR 001, including:
# - Module-based organization
# - Clear module interfaces
# - Dependency management
# - Platform abstraction
# - Error handling strategy

# Source test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./test.sh
source "${SCRIPT_DIR}/test.sh"

# Required modules according to ADR-001
REQUIRED_MODULES=(
  "constants.sh"
  "dependency_check.sh"
  "environment_detection.sh"
  "platform_compatibility.sh" 
  "test_analysis.sh"
  "reporting.sh"
)

# Test that all required modules exist
test_required_modules_exist() {
  local all_exist=0
  local modules_dir="${SCRIPT_DIR}/../src/lib/modules"
  
  for module in "${REQUIRED_MODULES[@]}"; do
    if [[ ! -f "${modules_dir}/${module}" ]]; then
      echo "Required module not found: ${module}"
      all_exist=1
    fi
  done
  
  return $all_exist
}

# Test that each module declares its dependencies at the top
test_modules_declare_dependencies() {
  local all_valid=0
  local modules_dir="${SCRIPT_DIR}/../src/lib/modules"
  
  for module in "${modules_dir}"/*.sh; do
    local module_name="$(basename "$module")"
    
    # Skip constants.sh as it shouldn't have dependencies
    if [[ "$module_name" == "constants.sh" ]]; then
      continue
    fi
    
    # Check if module sources its dependencies at the top
    if ! grep -q "source.*constants.sh" "$module" && ! grep -q "source.*\".*constants.sh\"" "$module"; then
      echo "Module ${module_name} does not declare dependency on constants.sh"
      all_valid=1
    fi
  done
  
  return $all_valid
}

# Test that functions use local variables to prevent namespace pollution
test_functions_use_local_variables() {
  local all_valid=0
  local modules_dir="${SCRIPT_DIR}/../src/lib/modules"
  
  for module in "${modules_dir}"/*.sh; do
    local module_name="$(basename "$module")"
    
    # Extract functions from the module
    local functions
    functions=$(grep -E '^function [a-zA-Z0-9_]+\(\)' "$module" | sed 's/function \([a-zA-Z0-9_]*\)().*/\1/')
    
    for func in $functions; do
      # Skip empty functions or functions with no variables
      local func_body
      func_body=$(sed -n "/function $func(/,/^}/p" "$module")
      
      # Count variable assignments that don't use local
      local non_local_vars
      non_local_vars=$(echo "$func_body" | grep -E '^\s*[a-zA-Z0-9_]+=.*' | grep -v "^\s*local" | wc -l)
      
      if [[ "$non_local_vars" -gt 0 ]]; then
        echo "Function $func in $module_name has non-local variables"
        all_valid=1
      fi
    done
  done
  
  return $all_valid
}

# Test main script's module loading mechanism
test_main_script_loads_modules() {
  local main_script="${SCRIPT_DIR}/../src/lib/mvnimble.sh"
  
  assert_file_exists "$main_script" "Main script should exist"
  
  # Check if main script sources the required modules
  local sources_modules=false
  if grep -q "source.*constants.sh" "$main_script" || grep -q "source.*modules/constants.sh" "$main_script"; then
    sources_modules=true
  fi
  
  assert_equal "true" "$sources_modules" "Main script should source modules"
}

# Test that error handling follows the pattern defined in ADR-001
test_error_handling_pattern() {
  local modules_dir="${SCRIPT_DIR}/../src/lib/modules"
  local all_valid=0
  
  for module in "${modules_dir}"/*.sh; do
    local module_name="$(basename "$module")"
    
    # Check for functions that return error codes
    local error_returns
    error_returns=$(grep -E '\s+return [1-9][0-9]*' "$module" | wc -l)
    
    # Check for error messages to stderr
    local stderr_messages
    stderr_messages=$(grep -E 'echo.*>&2' "$module" | wc -l)
    
    if [[ "$error_returns" -gt 0 && "$stderr_messages" -eq 0 ]]; then
      echo "Module $module_name has error returns but no stderr messages"
      all_valid=1
    fi
  done
  
  return $all_valid
}

# Test function declaration pattern compliance
test_function_declaration_pattern() {
  local modules_dir="${SCRIPT_DIR}/../src/lib/modules"
  local all_valid=0
  
  for module in "${modules_dir}"/*.sh; do
    local module_name="$(basename "$module")"
    
    # Count functions that don't follow the pattern 'function name() {'
    local non_compliant
    non_compliant=$(grep -E '^[a-zA-Z0-9_]+\(\)' "$module" | grep -v "^function" | wc -l)
    
    if [[ "$non_compliant" -gt 0 ]]; then
      echo "Module $module_name has $non_compliant functions not using 'function name()' pattern"
      all_valid=1
    fi
  done
  
  return $all_valid
}

# Test that modules have proper header comments
test_modules_have_header_comments() {
  local modules_dir="${SCRIPT_DIR}/../src/lib/modules"
  local all_valid=0
  
  for module in "${modules_dir}"/*.sh; do
    local module_name="$(basename "$module")"
    
    # Check for header comment
    local has_header=false
    if head -5 "$module" | grep -q "^# "; then
      has_header=true
    fi
    
    if [[ "$has_header" != "true" ]]; then
      echo "Module $module_name is missing a header comment"
      all_valid=1
    fi
  done
  
  return $all_valid
}

# Test platform-specific code is isolated in platform_compatibility module
test_platform_specific_code_isolation() {
  local platform_module="${SCRIPT_DIR}/../src/lib/modules/platform_compatibility.sh"
  local other_modules=("${SCRIPT_DIR}/../src/lib/modules/"*.sh)
  local all_valid=0
  
  assert_file_exists "$platform_module" "Platform compatibility module should exist"
  
  # Platform-specific markers to look for
  local platform_markers=(
    "uname"
    "Darwin"
    "Linux"
    "sysctl"
    "/proc"
  )
  
  for module in "${other_modules[@]}"; do
    local module_name="$(basename "$module")"
    
    # Skip the platform module itself and environment_detection module which should have platform detection
    if [[ "$module_name" == "platform_compatibility.sh" || "$module_name" == "environment_detection.sh" ]]; then
      continue
    fi
    
    # Check for platform-specific code
    local platform_specific=false
    for marker in "${platform_markers[@]}"; do
      if grep -qE "[^a-zA-Z0-9_]$marker[^a-zA-Z0-9_]" "$module"; then
        echo "Module $module_name contains platform-specific code: $marker"
        platform_specific=true
        all_valid=1
      fi
    done
  done
  
  return $all_valid
}

# Run the tests if this file is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_all_tests "$(basename "${BASH_SOURCE[0]}")"
fi