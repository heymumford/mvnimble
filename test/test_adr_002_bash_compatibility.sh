#!/bin/bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# test_adr_002_bash_compatibility.sh
# Tests for ADR 002: Bash Compatibility
#
# This test suite validates that the codebase follows the Bash 3.2
# compatibility requirements defined in ADR 002.

# Source test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./test.sh
source "${SCRIPT_DIR}/test.sh"

# Test bash version detection mechanism
test_bash_version_detection() {
  local dep_check="${SCRIPT_DIR}/../src/lib/modules/dependency_check.sh"
  
  assert_file_exists "$dep_check" "Dependency check module should exist"
  
  # Check if the script verifies bash version
  local has_version_check=false
  if grep -q "BASH_VERSION" "$dep_check" && grep -q "BASH_VERSINFO" "$dep_check"; then
    has_version_check=true
  fi
  
  assert_equal "true" "$has_version_check" "Dependency check should verify bash version"
  
  # Check if the MINIMUM_BASH_VERSION constant is defined
  local constants="${SCRIPT_DIR}/../src/lib/modules/constants.sh"
  assert_file_exists "$constants" "Constants module should exist"
  
  local has_min_version=false
  if grep -q "MINIMUM_BASH_VERSION" "$constants"; then
    has_min_version=true
  fi
  
  assert_equal "true" "$has_min_version" "MINIMUM_BASH_VERSION should be defined in constants.sh"
}

# Test for avoidance of bash 4+ features
test_no_bash4_features() {
  local modules_dir="${SCRIPT_DIR}/../src/lib/modules"
  local all_valid=0
  
  # Bash 4+ features to check for
  local bash4_features=(
    # Associative arrays
    "declare -A"
    # Case modification expansions
    '${[a-zA-Z0-9_]+\^}'
    '${[a-zA-Z0-9_]+,}'
    # Builtin commands
    "mapfile "
    "readarray "
    # Redirection
    "&>>"
  )
  
  for module in "${modules_dir}"/*.sh; do
    local module_name="$(basename "$module")"
    
    for feature in "${bash4_features[@]}"; do
      if grep -q "$feature" "$module"; then
        echo "Module $module_name uses bash 4+ feature: $feature"
        all_valid=1
      fi
    done
  done
  
  return $all_valid
}

# Test use of POSIX-compatible syntax
test_posix_compatible_syntax() {
  local modules_dir="${SCRIPT_DIR}/../src/lib/modules"
  local all_valid=0
  
  for module in "${modules_dir}"/*.sh; do
    local module_name="$(basename "$module")"
    
    # Check if backticks are used for command substitution
    if grep -q '\`[^`]*\`' "$module"; then
      echo "Module $module_name uses backticks instead of \$(command)"
      all_valid=1
    fi
  done
  
  return $all_valid
}

# Test appropriate use of test constructs
test_appropriate_test_constructs() {
  local modules_dir="${SCRIPT_DIR}/../src/lib/modules"
  local all_valid=0
  
  for module in "${modules_dir}"/*.sh; do
    local module_name="$(basename "$module")"
    
    # Skip environment_detection.sh due to its shell requirements
    if [[ "$module_name" == "environment_detection.sh" ]]; then
      continue
    fi
    
    # Count double bracket tests
    local double_bracket_count
    double_bracket_count=$(grep -c "\[\[ " "$module")
    
    # Count single bracket tests
    local single_bracket_count
    single_bracket_count=$(grep -c " \[ " "$module")
    
    # Ensure script uses both styles appropriately
    # This is a heuristic - we expect at least some single brackets for POSIX compatibility
    if [[ "$double_bracket_count" -gt 0 && "$single_bracket_count" -eq 0 ]]; then
      echo "Module $module_name uses double brackets but no single brackets - may not be optimal for POSIX compatibility"
      all_valid=1
    fi
  done
  
  return $all_valid
}

# Test that scripts use proper shebang line
test_proper_shebang() {
  local modules_dir="${SCRIPT_DIR}/../src/lib/modules"
  local all_valid=0
  
  for module in "${modules_dir}"/*.sh; do
    local module_name="$(basename "$module")"
    
    # Skip specific files that might use zsh for special needs
    if [[ "$module_name" == "environment_detection.sh" || "$module_name" == "platform_compatibility.sh" ]]; then
      continue
    fi
    
    # Get the first line
    local shebang
    shebang=$(head -1 "$module")
    
    # Check if it follows ADR-002 recommendation
    if [[ "$shebang" != "#!/bin/bash" && "$shebang" != "#!/usr/bin/env bash" ]]; then
      echo "Module $module_name has non-standard shebang: $shebang"
      all_valid=1
    fi
  done
  
  return $all_valid
}

# Test that a fallback path detection mechanism is present
test_fallback_path_detection() {
  local modules_dir="${SCRIPT_DIR}/../src/lib/modules"
  local all_valid=0
  local has_fallback=false
  
  # Pattern for script path detection with fallback
  local pattern1="BASH_SOURCE\[0\]:-"
  local pattern2="readlink -f"
  
  # Check each module
  for module in "${modules_dir}"/*.sh; do
    local module_name="$(basename "$module")"
    
    # Look for fallback patterns
    if grep -q "$pattern1" "$module" || grep -q "$pattern2" "$module"; then
      has_fallback=true
      break
    fi
  done
  
  # Also check main script
  local main_script="${SCRIPT_DIR}/../src/lib/mvnimble.sh"
  if [[ -f "$main_script" ]]; then
    if grep -q "$pattern1" "$main_script" || grep -q "$pattern2" "$main_script"; then
      has_fallback=true
    fi
  fi
  
  assert_equal "true" "$has_fallback" "At least one script should have fallback script path detection"
}

# Test string operation alternatives (instead of bash-specific ones)
test_string_operation_alternatives() {
  local modules_dir="${SCRIPT_DIR}/../src/lib/modules"
  local all_valid=0
  
  # String patterns to look for
  local pattern_tr="tr '[:lower:]' '[:upper:]'"
  local pattern_sed="sed"
  local pattern_bash4_upper='${.*^^}'
  local pattern_bash4_lower='${.*,,}'
  
  # Track if we found POSIX alternatives
  local has_tr_alternative=false
  
  # Check each module
  for module in "${modules_dir}"/*.sh; do
    local module_name="$(basename "$module")"
    
    # Check for bash 4 case conversion (should not be there)
    if grep -q "$pattern_bash4_upper" "$module" || grep -q "$pattern_bash4_lower" "$module"; then
      echo "Module $module_name uses bash 4+ case conversion"
      all_valid=1
    fi
    
    # Look for POSIX alternatives (at least one module should have them)
    if grep -q "$pattern_tr" "$module" || grep -q "$pattern_sed" "$module"; then
      has_tr_alternative=true
    fi
  done
  
  # Check that at least some module uses POSIX alternatives
  if [[ "$has_tr_alternative" != "true" ]]; then
    echo "No module uses POSIX alternatives for string manipulation"
    all_valid=1
  fi
  
  return $all_valid
}

# Run the tests if this file is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_all_tests "$(basename "${BASH_SOURCE[0]}")"
fi