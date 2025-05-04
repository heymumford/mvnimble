#!/usr/bin/env bats
# ADR 005 Tests: Magic Numbers Elimination
# Tests for validating magic numbers elimination

load ../test_helper
load ../test_tags
load ../common/adr_helpers

# Setup function run before each test
setup() {
  # Get the project root and module directories
  PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
  MODULE_DIR="${PROJECT_ROOT}/src/lib/modules"
  MAIN_SCRIPT="${PROJECT_ROOT}/src/lib/mvnimble.sh"
  ADR_DIR="${PROJECT_ROOT}/doc/adr"
  
  # Set the ADR file path
  ADR_FILE="${ADR_DIR}/005-magic-numbers-elimination.md"
  [ -f "$ADR_FILE" ] || skip "ADR 005 file not found at ${ADR_FILE}"
  
  # Load constants module
  source "${MODULE_DIR}/constants.sh"
}

# Helper function to search for a pattern in module files
search_modules_for_pattern() {
  local pattern="$1"
  local exclude_file="${2:-}"
  local exclude_comment="${3:-false}"
  local count=0
  
  # Get list of all modules
  local modules=("${MODULE_DIR}"/*.sh)
  
  for module in "${modules[@]}"; do
    # Skip the excluded file if specified
    if [ -n "$exclude_file" ] && [[ "$(basename "$module")" == "$exclude_file" ]]; then
      continue
    fi
    
    # Determine grep pattern based on whether to exclude comments
    local grep_pattern
    if [ "$exclude_comment" = true ]; then
      grep_pattern="grep -v \"^#\""
    else
      grep_pattern="cat"
    fi
    
    # Check for pattern
    if bash -c "$grep_pattern \"$module\" | grep -q \"$pattern\""; then
      # Record match
      echo "Found in $(basename "$module"): $(bash -c "$grep_pattern \"$module\" | grep \"$pattern\" | head -1")"
      count=$((count + 1))
    fi
  done
  
  return $count
}

# Helper function to check if a variable is used in a file
variable_is_used() {
  local variable="$1"
  local file="$2"
  
  # Look for the variable being used (not just defined)
  # Exclude the definition line, which will start with "readonly"
  grep -v "readonly.*$variable" "$file" | grep -q "$variable"
}

# @functional @positive @adr005 @core
@test "Dedicated constants module exists" {
  local constants_file="${MODULE_DIR}/constants.sh"
  
  # Check that the constants file exists
  [ -f "$constants_file" ]
  
  # Check that it declares constants as readonly
  grep -q "readonly" "$constants_file"
}

# @functional @positive @adr005 @core
@test "Constants are organized into logical categories" {
  local constants_file="${MODULE_DIR}/constants.sh"
  
  # Categories to look for as defined in ADR 005
  local categories=(
    "Version"
    "Default"
    "Resource"
    "Performance"
    "Path"
    "File"
    "Color"
    "Exit"
  )
  
  # Check for each category
  for category in "${categories[@]}"; do
    # Check if the category exists in comments
    grep -q "# .*$category" "$constants_file"
  done
}

# @functional @positive @adr005 @core
@test "Constants are declared as readonly" {
  local constants_file="${MODULE_DIR}/constants.sh"
  
  # Get count of all capitalized variable declarations
  local all_constants
  all_constants=$(grep -c -E "^readonly [A-Z][A-Z0-9_]+" "$constants_file")
  
  # Check that constants exist
  [ "$all_constants" -gt 0 ]
  
  # Check if any constants are not defined as readonly
  local non_readonly_constants
  non_readonly_constants=$(grep -c -E "^[A-Z][A-Z0-9_]+=.*" "$constants_file" | 
                          grep -v "^readonly")
  
  # Should be none
  [ "$non_readonly_constants" -eq 0 ]
}

# @functional @positive @adr005 @core
@test "Constants follow UPPERCASE_WITH_UNDERSCORES naming convention" {
  local constants_file="${MODULE_DIR}/constants.sh"
  
  # Check for constants not following the naming convention
  local invalid_constants
  invalid_constants=$(grep -c -E "^readonly [a-z]" "$constants_file")
  
  # Should be none
  [ "$invalid_constants" -eq 0 ]
  
  # All constants should be UPPERCASE_WITH_UNDERSCORES
  local valid_constants
  valid_constants=$(grep -c -E "^readonly [A-Z][A-Z0-9_]+" "$constants_file")
  
  # Should be several
  [ "$valid_constants" -gt 0 ]
}

# @functional @positive @adr005 @core
@test "Constants have descriptive names" {
  local constants_file="${MODULE_DIR}/constants.sh"
  
  # Check for short, non-descriptive constants (less than 5 characters)
  local short_constants
  short_constants=$(grep -E "^readonly [A-Z][A-Z0-9_]{1,3}=" "$constants_file" | 
                   grep -v "^readonly [A-Z][A-Z0-9_]*_[A-Z0-9_]+=" | wc -l)
  
  # Should be few or none (allow some exceptions for very common abbreviations)
  [ "$short_constants" -le 2 ]
}

# @functional @positive @adr005 @core
@test "Constants have descriptive comments" {
  local constants_file="${MODULE_DIR}/constants.sh"
  
  # Check for constants with inline comments
  local commented_constants
  commented_constants=$(grep -c -E "^readonly [A-Z][A-Z0-9_]+.*#" "$constants_file")
  
  # Get total number of constants
  local total_constants
  total_constants=$(grep -c -E "^readonly [A-Z][A-Z0-9_]+" "$constants_file")
  
  # At least 30% should have comments
  [ "$commented_constants" -ge $(($total_constants * 3 / 10)) ]
}

# @functional @positive @adr005 @core
@test "Other modules source the constants module" {
  local constants_file="${MODULE_DIR}/constants.sh"
  
  # Get list of all modules
  local modules=("${MODULE_DIR}"/*.sh)
  
  for module in "${modules[@]}"; do
    # Skip constants.sh itself
    if [[ "$(basename "$module")" == "constants.sh" ]]; then
      continue
    fi
    
    # Check if module sources constants.sh
    grep -q "source.*constants.sh" "$module" ||
      grep -q "source.*\".*constants.sh\"" "$module"
  done
}

# @functional @negative @adr005 @core
@test "No hardcoded color values outside constants.sh" {
  # Look for ANSI color codes outside constants.sh
  run search_modules_for_pattern "\\\\033\\[" "constants.sh" true
  
  # Should not find any
  [ "$status" -eq 0 ]
}

# @functional @positive @adr005 @core
@test "Required constants are defined" {
  # List of essential constants that should be defined
  local essential_constants=(
    "MVNIMBLE_VERSION"
    "COLOR_RESET"
    "EXIT_SUCCESS"
    "EXIT_GENERAL_ERROR"
  )
  
  # Check each constant
  for const in "${essential_constants[@]}"; do
    # Check that the constant is declared
    grep -q "readonly $const=" "${MODULE_DIR}/constants.sh"
    
    # Check that the value is not empty
    grep -q "readonly $const=\"\"" "${MODULE_DIR}/constants.sh" && return 1
    grep -q "readonly $const=$" "${MODULE_DIR}/constants.sh" && return 1
  done
}

# @functional @positive @adr005 @core
@test "Constants have appropriate types" {
  # Check numeric constants
  local numeric_constants=(
    "DEFAULT_MAX_MINUTES"
    "MIN_MEMORY_MB"
    "EXIT_SUCCESS"
    "EXIT_GENERAL_ERROR"
  )
  
  # Check each constant
  for const in "${numeric_constants[@]}"; do
    if grep -q "readonly $const=" "${MODULE_DIR}/constants.sh"; then
      # Extract the value
      local value
      value=$(grep "readonly $const=" "${MODULE_DIR}/constants.sh" | 
             sed -E "s/readonly $const=\"?([0-9.]+)\"?.*/\\1/")
      
      # Check that it's numeric
      [[ "$value" =~ ^[0-9]+(\.[0-9]+)?$ ]]
    fi
  done
  
  # Check string constants
  local string_constants=(
    "MVNIMBLE_VERSION"
    "DEFAULT_MODE"
  )
  
  # Check each constant
  for const in "${string_constants[@]}"; do
    if grep -q "readonly $const=" "${MODULE_DIR}/constants.sh"; then
      # Extract the value
      local value
      value=$(grep "readonly $const=" "${MODULE_DIR}/constants.sh" | 
             sed -E "s/readonly $const=\"([^\"]+)\".*/\\1/")
      
      # Check that it's not empty
      [ -n "$value" ]
    fi
  done
}

# @functional @negative @adr005 @core
@test "No magic numbers in code outside constants.sh" {
  # Look for numeric literals that should be constants
  # Target numbers that appear to be thresholds, timeouts, etc.
  
  # List of patterns that might indicate magic numbers
  local patterns=(
    "[^0-9A-Za-z_][0-9]{3,}[^0-9A-Za-z_]"  # 3+ digit numbers
    "timeout [0-9]+"  # Timeout values
    "sleep [0-9]+"  # Sleep durations
    "exit [1-9]"  # Exit codes
  )
  
  # Check modules for these patterns
  for pattern in "${patterns[@]}"; do
    # Skip constants.sh and exclude comments and variable names
    run search_modules_for_pattern "$pattern" "constants.sh" true
    
    # Allow a few exceptions (up to 3 per pattern) for cases where literals make sense
    [ "$status" -le 3 ]
  done
}

# @functional @positive @adr005 @core
@test "Derived constants are used where appropriate" {
  local constants_file="${MODULE_DIR}/constants.sh"
  
  # Look for constants defined in terms of other constants
  local derived_constants
  derived_constants=$(grep -c -E "readonly [A-Z][A-Z0-9_]+=.*\$[A-Z][A-Z0-9_]+" "$constants_file")
  
  # Should find at least one
  [ "$derived_constants" -ge 1 ]
}

# @functional @positive @adr005 @core
@test "Constants are used consistently throughout the codebase" {
  local constants_file="${MODULE_DIR}/constants.sh"
  
  # Get a subset of constants to check
  local constants_to_check=(
    "MVNIMBLE_VERSION"
    "COLOR_RESET"
    "EXIT_SUCCESS"
    "EXIT_GENERAL_ERROR"
  )
  
  # Check that each constant is used in at least one other file
  for const in "${constants_to_check[@]}"; do
    # Verify constant exists
    if ! grep -q "readonly $const=" "$constants_file"; then
      continue
    fi
    
    # Look for usage in other files
    local usage_found=false
    for module in "${MODULE_DIR}"/*.sh "${MAIN_SCRIPT}"; do
      # Skip constants.sh itself
      if [[ "$(basename "$module")" == "constants.sh" ]]; then
        continue
      fi
      
      if [ -f "$module" ] && variable_is_used "$const" "$module"; then
        usage_found=true
        break
      fi
    done
    
    # At least one of the checked constants should be used
    if [ "$usage_found" = true ]; then
      return 0
    fi
  done
  
  # If none of the constants are used, test fails
  return 1
}

# @functional @negative @adr005 @core
@test "Creating code with magic numbers is rejected" {
  # Create a temporary module file
  local temp_module
  temp_module="${FIXTURE_DIR}/test_magic_numbers.sh"
  
  # Create a module with magic numbers
  cat > "$temp_module" << 'EOF'
#!/bin/bash
# test_magic_numbers.sh - Test module with magic numbers

# Source constants
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/constants.sh"

# Function with magic numbers (bad)
function test_with_magic_numbers() {
  # Wait for 30 seconds
  sleep 30
  
  # Check if value exceeds threshold
  if [ "$1" -gt 500 ]; then
    return 1
  fi
  
  # 86400 is seconds in a day
  local day_seconds=86400
  echo "$((day_seconds / 6))"
  
  # Exit with custom code
  exit 5
}

# Function using constants (good)
function test_with_constants() {
  # Wait for the configured time
  sleep "$DEFAULT_TEST_TIMEOUT"
  
  # Check if value exceeds threshold
  if [ "$1" -gt "$MAX_TEST_VALUE" ]; then
    return "$EXIT_TEST_ERROR"
  fi
  
  # Use the seconds-per-day constant
  echo "$((SECONDS_PER_DAY / 6))"
  
  # Exit with standard code
  exit "$EXIT_TEST_COMPLETE"
}
EOF
  
  # Function to check for magic numbers
  check_magic_numbers() {
    local module_file="$1"
    
    # Look for numeric literals that should be constants
    if grep -v "^#" "$module_file" | 
       grep -E "[^0-9A-Za-z_][0-9]{3,}[^0-9A-Za-z_]|sleep [0-9]+|exit [1-9]" | 
       grep -v "SECONDS_PER_DAY" | 
       grep -v "DEFAULT_" | 
       grep -v "MAX_" | 
       grep -v "EXIT_" > /dev/null; then
      # Found magic numbers
      return 1
    fi
    
    return 0
  }
  
  # Should fail validation
  run check_magic_numbers "$temp_module"
  [ "$status" -eq 1 ]
  
  # Check individual functions
  check_function_magic_numbers() {
    local module_file="$1"
    local func_name="$2"
    
    # Extract function body
    local func_body
    func_body=$(sed -n "/function $func_name(/,/^}/p" "$module_file")
    
    # Look for magic numbers
    if echo "$func_body" | 
       grep -E "[^0-9A-Za-z_][0-9]{3,}[^0-9A-Za-z_]|sleep [0-9]+|exit [1-9]" | 
       grep -v "SECONDS_PER_DAY" | 
       grep -v "DEFAULT_" | 
       grep -v "MAX_" | 
       grep -v "EXIT_" > /dev/null; then
      # Found magic numbers
      return 1
    fi
    
    return 0
  }
  
  # Bad function should fail
  run check_function_magic_numbers "$temp_module" "test_with_magic_numbers"
  [ "$status" -eq 1 ]
  
  # Good function should pass
  run check_function_magic_numbers "$temp_module" "test_with_constants"
  [ "$status" -eq 0 ]
  
  # Clean up
  rm -f "$temp_module"
}

# @nonfunctional @positive @adr005 @core
@test "Constants have clear, descriptive naming" {
  local constants_file="${MODULE_DIR}/constants.sh"
  
  # Get list of constants
  local constants
  constants=$(grep -E "^readonly [A-Z][A-Z0-9_]+" "$constants_file" | 
             sed -E "s/readonly ([A-Z][A-Z0-9_]+)=.*/\\1/")
  
  # Check a sample of constants for clear naming
  local descriptive_count=0
  local total_checked=0
  
  # Take a sample of constants to check
  for const in $constants; do
    # Skip already checked
    if [ "$total_checked" -ge 10 ]; then
      break
    fi
    
    # Increment check counter
    ((total_checked++))
    
    # Check if the name is descriptive
    local has_category=false
    
    # Look for category prefixes or suffixes
    if [[ "$const" == *"_DIR"* || 
          "$const" == *"_FILE"* || 
          "$const" == *"_PATH"* || 
          "$const" == *"_COLOR"* || 
          "$const" == *"_EXIT"* || 
          "$const" == *"_VERSION"* || 
          "$const" == *"_MB"* || 
          "$const" == *"_THRESHOLD"* || 
          "$const" == *"_TIMEOUT"* || 
          "$const" == *"_COUNT"* || 
          "$const" == *"_DEFAULT"* || 
          "$const" == *"_MIN"* || 
          "$const" == *"_MAX"* ]]; then
      has_category=true
    fi
    
    # Check if it has multiple words (for descriptiveness)
    local has_multiple_words=false
    if [[ "$const" == *"_"* ]]; then
      has_multiple_words=true
    fi
    
    # Increment if descriptive
    if [ "$has_category" = true ] || [ "$has_multiple_words" = true ]; then
      ((descriptive_count++))
    fi
  done
  
  # At least 70% should be descriptive
  [ "$descriptive_count" -ge $(($total_checked * 7 / 10)) ]
}

# @nonfunctional @positive @adr005 @core
@test "Constants module is well-documented" {
  local constants_file="${MODULE_DIR}/constants.sh"
  
  # Check for a header comment
  local has_header
  has_header=$(head -5 "$constants_file" | grep -c "^#")
  
  # Should have at least 3 lines of header comments
  [ "$has_header" -ge 3 ]
  
  # Check for category comments
  local category_comments
  category_comments=$(grep -c "^# " "$constants_file")
  
  # Should have several category comments
  [ "$category_comments" -ge 5 ]
  
  # Check that the file explains its purpose
  head -10 "$constants_file" | grep -q "constant\\|configuration\\|value"
}

# @functional @positive @adr005 @core
@test "Main script sources the constants module" {
  # Check that the main script exists
  [ -f "$MAIN_SCRIPT" ]
  
  # Check that it sources constants.sh
  grep -q "source.*constants.sh" "$MAIN_SCRIPT" ||
    grep -q "source.*\".*constants.sh\"" "$MAIN_SCRIPT"
}

# @functional @positive @adr005 @core
@test "Version information is properly defined" {
  # Check that version information is defined
  grep -q "readonly MVNIMBLE_VERSION=" "${MODULE_DIR}/constants.sh"
  
  # Check that the version follows semantic versioning
  local version
  version=$(grep "readonly MVNIMBLE_VERSION=" "${MODULE_DIR}/constants.sh" | 
           sed -E "s/readonly MVNIMBLE_VERSION=\"([0-9]+\.[0-9]+\.[0-9]+)\".*/\\1/")
  
  [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

# @functional @positive @adr005 @core
@test "Exit codes are properly defined" {
  # Check that exit codes are defined
  grep -q "readonly EXIT_SUCCESS=" "${MODULE_DIR}/constants.sh"
  grep -q "readonly EXIT_GENERAL_ERROR=" "${MODULE_DIR}/constants.sh"
  
  # Check their values
  [ "$EXIT_SUCCESS" -eq 0 ]
  [ "$EXIT_GENERAL_ERROR" -ne 0 ]
  
  # Check uniqueness - each exit code should have a different value
  local exit_codes
  exit_codes=$(grep -E "readonly EXIT_[A-Z_]+=[0-9]+" "${MODULE_DIR}/constants.sh" | 
              sed -E "s/readonly EXIT_[A-Z_]+=([0-9]+).*/\\1/" | sort)
  
  # Count unique values
  local unique_codes
  unique_codes=$(echo "$exit_codes" | uniq | wc -l)
  
  # Count total values
  local total_codes
  total_codes=$(echo "$exit_codes" | wc -l)
  
  # All exit codes should be unique
  [ "$unique_codes" -eq "$total_codes" ]
}

# @functional @positive @adr005 @core
@test "Terminal color definitions are complete" {
  # Check that color definitions exist
  grep -q "readonly COLOR_" "${MODULE_DIR}/constants.sh"
  
  # Check for essential colors
  grep -q "readonly COLOR_RESET=" "${MODULE_DIR}/constants.sh"
  
  # Check that we have at least 4 colors defined
  local color_count
  color_count=$(grep -c "readonly COLOR_" "${MODULE_DIR}/constants.sh")
  
  [ "$color_count" -ge 4 ]
}

# @nonfunctional @positive @adr005 @core
@test "ADR-005 implementation matches documentation" {
  # Extract key points from ADR-005
  grep -A20 "## Decision" "$ADR_FILE" | grep -E "^\s*[0-9]+\."
  
  # Check for dedicated constants module
  [ -f "${MODULE_DIR}/constants.sh" ]
  
  # Check for readonly declaration
  grep -q "readonly" "${MODULE_DIR}/constants.sh"
  
  # Check for UPPERCASE naming
  grep -q "readonly [A-Z]" "${MODULE_DIR}/constants.sh"
  
  # Check for module inclusion pattern
  grep -q "source" "${MODULE_DIR}/constants.sh"
  
  # Check for documentation
  grep -q "^# " "${MODULE_DIR}/constants.sh"
}