#!/bin/bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# test_adr_005_magic_numbers.sh
# Tests for ADR 005: Magic Numbers Elimination
#
# This test suite validates that the codebase follows the magic numbers
# elimination requirements defined in ADR 005.

# Source test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./test.sh
source "${SCRIPT_DIR}/test.sh"

# Source constants module for direct testing
# shellcheck source=../src/lib/modules/constants.sh
source "${SCRIPT_DIR}/../src/lib/modules/constants.sh"

# Test that the constants module exists
test_constants_module_exists() {
  assert_file_exists "${SCRIPT_DIR}/../src/lib/modules/constants.sh" "Constants module should exist"
}

# Test that constants are organized into categories
test_constants_categories() {
  local constants_file="${SCRIPT_DIR}/../src/lib/modules/constants.sh"
  local categories=(
    "Version information"
    "Default"
    "Resource"
    "Performance"
    "Path"
    "color"
    "exit"
  )
  
  # Check if each category appears in the file
  local all_categories_found=true
  for category in "${categories[@]}"; do
    if ! grep -qi "$category" "$constants_file"; then
      echo "Missing constants category: $category"
      all_categories_found=false
    fi
  done
  
  assert_equal "true" "$all_categories_found" "Constants should be organized into logical categories"
}

# Test that constants are declared as readonly
test_constants_readonly() {
  local constants_file="${SCRIPT_DIR}/../src/lib/modules/constants.sh"
  
  # Count constants that don't use readonly
  local non_readonly_count
  non_readonly_count=$(grep -E "^[A-Z][A-Z0-9_]+=.*" "$constants_file" | grep -cv "readonly")
  
  assert_equal 0 "$non_readonly_count" "All constants should be declared as readonly"
}

# Test that constants use the correct naming convention
test_constants_naming_convention() {
  local constants_file="${SCRIPT_DIR}/../src/lib/modules/constants.sh"
  
  # Count constants that don't use UPPERCASE_WITH_UNDERSCORES
  local non_compliant_count
  non_compliant_count=$(grep -E "readonly [a-z]" "$constants_file" | wc -l)
  
  assert_equal 0 "$non_compliant_count" "All constants should use UPPERCASE_WITH_UNDERSCORES naming"
}

# Test that constants have descriptive names
test_constants_descriptive_names() {
  local constants_file="${SCRIPT_DIR}/../src/lib/modules/constants.sh"
  
  # Look for short non-descriptive names (less than 3 characters, excluding scope prefixes)
  local non_descriptive_count
  non_descriptive_count=$(grep -E "readonly [A-Z][A-Z0-9_]{1,2}=" "$constants_file" | wc -l)
  
  assert_equal 0 "$non_descriptive_count" "Constants should have descriptive names, not short abbreviations"
}

# Test that constants are documented with comments
test_constants_documentation() {
  local constants_file="${SCRIPT_DIR}/../src/lib/modules/constants.sh"
  
  # Count constant declarations with inline comments
  local constant_count
  constant_count=$(grep -c "readonly [A-Z]" "$constants_file")
  
  local commented_count
  commented_count=$(grep -E "readonly [A-Z].*#" "$constants_file" | wc -l)
  
  # At least 50% of constants should have inline comments
  local comment_percentage=$((commented_count * 100 / constant_count))
  [[ "$comment_percentage" -ge 50 ]] || return 1
  
  # Check for blocks of comments
  local block_comments
  block_comments=$(grep -c "^# " "$constants_file")
  
  # Should have several block comments for categories
  [[ "$block_comments" -ge 3 ]] || return 1
  
  return 0
}

# Test that other modules use constants instead of literals
test_modules_use_constants() {
  local modules_dir="${SCRIPT_DIR}/../src/lib/modules"
  local constants_file="${modules_dir}/constants.sh"
  local all_modules_use_constants=true
  
  # Skip constants module itself
  for module in "${modules_dir}"/*.sh; do
    local module_name="$(basename "$module")"
    
    if [[ "$module_name" == "constants.sh" ]]; then
      continue
    fi
    
    # Check if the module sources constants.sh
    local sources_constants=false
    if grep -q "source.*constants.sh" "$module" || grep -q "source.*\".*constants.sh\"" "$module"; then
      sources_constants=true
    fi
    
    if [[ "$sources_constants" != "true" ]]; then
      echo "Module $module_name does not source constants.sh"
      all_modules_use_constants=false
    fi
  done
  
  assert_equal "true" "$all_modules_use_constants" "All modules should source the constants module"
}

# Test that no hardcoded color values exist outside constants.sh
test_no_hardcoded_color_values() {
  local modules_dir="${SCRIPT_DIR}/../src/lib/modules"
  local all_valid=0
  
  # Pattern for ANSI color codes
  local ansi_pattern='\033\[[0-9;]+m'
  
  for module in "${modules_dir}"/*.sh; do
    local module_name="$(basename "$module")"
    
    # Skip constants module itself
    if [[ "$module_name" == "constants.sh" ]]; then
      continue
    fi
    
    # Check for hardcoded ANSI color codes
    if grep -Eq "$ansi_pattern" "$module"; then
      echo "Module $module_name has hardcoded ANSI color values"
      all_valid=1
    fi
  done
  
  return $all_valid
}

# Test that required constants are defined
test_required_constants_defined() {
  # List of constants that should definitely exist
  local required_constants=(
    "MVNIMBLE_VERSION"
    "MINIMUM_BASH_VERSION"
    "DEFAULT_MODE"
    "COLOR_RESET"
    "EXIT_SUCCESS"
    "EXIT_GENERAL_ERROR"
  )
  
  local all_defined=true
  
  for const in "${required_constants[@]}"; do
    if ! (set -o posix; set) | grep -q "^$const="; then
      echo "Required constant $const is not defined"
      all_defined=false
    fi
  done
  
  assert_equal "true" "$all_defined" "All required constants should be defined"
}

# Test that constants have appropriate types (numeric or string)
test_constants_appropriate_types() {
  local all_valid=0
  
  # Test numeric constants
  local numeric_constants=(
    "MINIMUM_JAVA_VERSION"
    "DEFAULT_MAX_MINUTES"
    "MIN_MEMORY_MB"
    "EXIT_SUCCESS"
    "EXIT_GENERAL_ERROR"
  )
  
  for const in "${numeric_constants[@]}"; do
    local value
    value=${!const}
    
    # Check if value exists and is numeric
    if [[ -z "$value" ]]; then
      echo "Numeric constant $const is not defined"
      all_valid=1
    elif ! [[ "$value" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
      echo "Constant $const should be numeric but has value: $value"
      all_valid=1
    fi
  done
  
  # Test string constants that should contain specific patterns
  if [[ ! "$MVNIMBLE_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "MVNIMBLE_VERSION should follow semantic versioning pattern"
    all_valid=1
  fi
  
  # Test color constants
  local color_constants=(
    "COLOR_BLUE"
    "COLOR_GREEN"
    "COLOR_RED"
    "COLOR_RESET"
  )
  
  for const in "${color_constants[@]}"; do
    local value
    value=${!const}
    
    # Check if value exists and is an ANSI code
    if [[ -z "$value" ]]; then
      echo "Color constant $const is not defined"
      all_valid=1
    elif ! [[ "$value" =~ ^\\\033\[ ]]; then
      echo "Color constant $const should be an ANSI escape code but has value: $value"
      all_valid=1
    fi
  done
  
  return $all_valid
}

# Test that there are no magic numbers in code
test_no_magic_numbers_in_code() {
  local modules_dir="${SCRIPT_DIR}/../src/lib/modules"
  local all_valid=0
  
  # Patterns for magic numbers (excluding allowed contexts)
  local patterns=(
    '[^A-Za-z0-9_"][ ]*[0-9]{3,}[^0-9A-Za-z_]'  # 3+ digit numbers
    'exit [1-9][0-9]*'  # Numeric exit codes
    'sleep [0-9]+'  # Sleep durations
  )
  
  for module in "${modules_dir}"/*.sh; do
    local module_name="$(basename "$module")"
    
    # Skip constants module itself
    if [[ "$module_name" == "constants.sh" ]]; then
      continue
    fi
    
    # Check for magic numbers
    for pattern in "${patterns[@]}"; do
      # Exclude comments, constant definitions, and variables
      if grep -v "^#" "$module" | grep -v "readonly [A-Z]" | grep -v "local [a-z]" | grep -Eq "$pattern"; then
        echo "Module $module_name may have magic numbers matching: $pattern"
        all_valid=1
      fi
    done
  done
  
  return $all_valid
}

# Test that derived constants are used where appropriate
test_derived_constants() {
  local constants_file="${SCRIPT_DIR}/../src/lib/modules/constants.sh"
  
  # Look for examples of derived constants
  local has_derived_constants=false
  if grep -q "$(" "$constants_file"; then
    has_derived_constants=true
  fi
  
  assert_equal "true" "$has_derived_constants" "Constants module should use derived constants where appropriate"
}

# Run the tests if this file is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_all_tests "$(basename "${BASH_SOURCE[0]}")"
fi