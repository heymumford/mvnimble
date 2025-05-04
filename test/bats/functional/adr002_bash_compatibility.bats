#!/usr/bin/env bats
# ADR 002 Tests: Bash Compatibility
# Tests for validating bash 3.2 compatibility

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
  ADR_FILE="${ADR_DIR}/002-bash-compatibility.md"
  [ -f "$ADR_FILE" ] || skip "ADR 002 file not found at ${ADR_FILE}"
}

# Helper function to search for a pattern in module files
search_modules_for_pattern() {
  local pattern="$1"
  local exclude_file="${2:-}"
  local count=0
  
  # Get list of all modules
  local modules=("${MODULE_DIR}"/*.sh)
  
  for module in "${modules[@]}"; do
    # Skip the excluded file if specified
    if [ -n "$exclude_file" ] && [[ "$(basename "$module")" == "$exclude_file" ]]; then
      continue
    fi
    
    # Check for pattern, excluding comments
    if grep -v "^#" "$module" | grep -q "$pattern"; then
      # Record match
      echo "Found in $(basename "$module"): $(grep -v "^#" "$module" | grep "$pattern" | head -1)"
      count=$((count + 1))
    fi
  done
  
  return $count
}

# Helper function to check a function's body for a pattern
function_body_has_pattern() {
  local module="$1"
  local func_name="$2"
  local pattern="$3"
  
  # Extract function body
  local func_body
  func_body=$(sed -n "/function $func_name(/,/^}/p" "$module")
  
  echo "$func_body" | grep -q "$pattern"
}

# @functional @positive @adr002 @core
@test "MINIMUM_BASH_VERSION constant is defined in constants.sh" {
  local constants_file="${MODULE_DIR}/constants.sh"
  
  # Check that the file exists
  [ -f "$constants_file" ]
  
  # Check for MINIMUM_BASH_VERSION constant
  grep -q "MINIMUM_BASH_VERSION" "$constants_file"
  
  # Check that it's set to 3.2 per ADR 002
  grep -q "MINIMUM_BASH_VERSION=\"3\.2\"" "$constants_file" ||
    grep -q "MINIMUM_BASH_VERSION=3\.2" "$constants_file"
}

# @functional @positive @adr002 @core
@test "Bash version detection is implemented" {
  local dependency_file="${MODULE_DIR}/dependency_check.sh"
  
  # Check that the file exists
  [ -f "$dependency_file" ]
  
  # Check for bash version detection
  grep -q "BASH_VERSION" "$dependency_file"
  
  # Check for BASH_VERSINFO usage
  grep -q "BASH_VERSINFO" "$dependency_file"
  
  # Check that it compares against the minimum version
  grep -q "MINIMUM_BASH_VERSION" "$dependency_file" ||
    grep -q "bash_major_version" "$dependency_file" ||
    grep -q "bash_minor_version" "$dependency_file"
}

# @functional @negative @adr002 @core
@test "No bash 4+ associative arrays are used" {
  # Look for declare -A (associative arrays)
  run search_modules_for_pattern "declare -A"
  
  # Should not find any
  [ "$status" -eq 0 ]
}

# @functional @negative @adr002 @core
@test "No bash 4+ case modifications are used" {
  # Look for case modification patterns
  run search_modules_for_pattern '${[a-zA-Z0-9_]+\^}'
  [ "$status" -eq 0 ]
  
  run search_modules_for_pattern '${[a-zA-Z0-9_]+,}'
  [ "$status" -eq 0 ]
  
  run search_modules_for_pattern '${[a-zA-Z0-9_]+^^}'
  [ "$status" -eq 0 ]
  
  run search_modules_for_pattern '${[a-zA-Z0-9_]+,,}'
  [ "$status" -eq 0 ]
}

# @functional @negative @adr002 @core
@test "No bash 4+ mapfile or readarray builtin is used" {
  # Look for mapfile and readarray
  run search_modules_for_pattern "mapfile "
  [ "$status" -eq 0 ]
  
  run search_modules_for_pattern "readarray "
  [ "$status" -eq 0 ]
}

# @functional @negative @adr002 @core
@test "No bash 4+ redirection operator is used" {
  # Look for &>> redirection
  run search_modules_for_pattern "&>>"
  [ "$status" -eq 0 ]
}

# @functional @positive @adr002 @core
@test "POSIX command substitution is used" {
  # Look for backtick command substitution
  run search_modules_for_pattern '\`[^`]*\`'
  
  # Should not find any backticks for command substitution
  [ "$status" -eq 0 ]
  
  # At least some modules should use $(command) substitution
  local modules=("${MODULE_DIR}"/*.sh)
  local found_command_subst=false
  
  for module in "${modules[@]}"; do
    if grep -q "\$(.*)" "$module"; then
      found_command_subst=true
      break
    fi
  done
  
  [ "$found_command_subst" = true ]
}

# @functional @positive @adr002 @core
@test "Bash 3.2 compatible string operations are used" {
  # Check for string operations done using tr/sed/awk instead of bash 4+ features
  local modules=("${MODULE_DIR}"/*.sh)
  local found_compatible_ops=false
  
  for module in "${modules[@]}"; do
    # Look for string operations using tr, sed, or awk
    if grep -E "tr ['\"][]a-zA-Z[:space:][:lower:][:upper:]]['\"] ['\"][]a-zA-Z[:space:][:lower:][:upper:]]['\"]" "$module" ||
       grep -E "sed.*s/.*/.*/[gI]" "$module" ||
       grep -E "awk.*gsub" "$module"; then
      found_compatible_ops=true
      break
    fi
  done
  
  [ "$found_compatible_ops" = true ]
}

# @functional @positive @adr002 @core
@test "Shebang lines follow ADR-002 recommendation" {
  local modules=("${MODULE_DIR}"/*.sh)
  
  for module in "${modules[@]}"; do
    # Skip specific files that might use zsh for special needs
    local basename_module
    basename_module=$(basename "$module")
    if [[ "$basename_module" == "environment_detection.sh" || 
          "$basename_module" == "platform_compatibility.sh" ]]; then
      continue
    }
    
    # Get the first line
    local shebang
    shebang=$(head -1 "$module")
    
    # Check if it follows ADR-002 recommendation
    [[ "$shebang" == "#!/bin/bash" || "$shebang" == "#!/usr/bin/env bash" ]]
  done
}

# @functional @positive @adr002 @core
@test "Fallback path detection pattern is present" {
  # Check for fallback path detection pattern somewhere in the codebase
  local modules=("${MODULE_DIR}"/*.sh "${MAIN_SCRIPT}")
  local found_fallback=false
  
  for file in "${modules[@]}"; do
    if [ -f "$file" ]; then
      if grep -q "BASH_SOURCE\[0\]:-" "$file" || 
         grep -q "readlink -f" "$file" || 
         grep -q "$(cd \"$(dirname \"\${BASH_SOURCE\[0\]}\")\" && pwd)" "$file"; then
        found_fallback=true
        break
      fi
    fi
  done
  
  [ "$found_fallback" = true ]
}

# @functional @positive @adr002 @core
@test "String operations use POSIX alternatives" {
  # Check for POSIX string operations
  local modules=("${MODULE_DIR}"/*.sh)
  local found_tr_alternative=false
  local found_sed_alternative=false
  
  for module in "${modules[@]}"; do
    # Check for tr for case conversion
    if grep -q "tr .*\[:lower:\].*\[:upper:\]" "$module" || 
       grep -q "tr .*\[:upper:\].*\[:lower:\]" "$module"; then
      found_tr_alternative=true
    fi
    
    # Check for sed string manipulation
    if grep -q "sed" "$module" && grep -q "s/" "$module"; then
      found_sed_alternative=true
    fi
  done
  
  # At least one of the alternatives should be found
  [ "$found_tr_alternative" = true -o "$found_sed_alternative" = true ]
}

# @functional @negative @adr002 @core
@test "No bash arrays with negative indices" {
  # Look for negative array indices
  run search_modules_for_pattern "\\[-[0-9]\\]"
  
  # Should not find any
  [ "$status" -eq 0 ]
}

# @functional @positive @adr002 @dependency
@test "Bash version warning is displayed when needed" {
  local dependency_file="${MODULE_DIR}/dependency_check.sh"
  
  # Check that the file exists
  [ -f "$dependency_file" ]
  
  # Check for bash version warning
  grep -q "WARNING: MVNimble works best with bash" "$dependency_file" ||
    grep -q "WARNING.*bash.*version" "$dependency_file"
  
  # Check that it reports the current version
  grep -q "BASH_VERSION" "$dependency_file"
}

# @nonfunctional @positive @adr002 @core
@test "Scripts use basic conditional constructs when possible" {
  # Check usage of [ vs [[ - both should be used where appropriate
  local modules=("${MODULE_DIR}"/*.sh)
  local single_bracket_count=0
  local double_bracket_count=0
  
  for module in "${modules[@]}"; do
    # Count single bracket usage
    single_bracket_count=$((single_bracket_count + $(grep -c " \[ " "$module")))
    
    # Count double bracket usage
    double_bracket_count=$((double_bracket_count + $(grep -c " \[\[ " "$module")))
  done
  
  # There should be at least some single brackets for POSIX compatibility
  [ "$single_bracket_count" -gt 0 ]
  
  # And some double brackets for more complex conditions
  [ "$double_bracket_count" -gt 0 ]
}

# @functional @negative @adr002 @core
@test "Create function using bash 4+ features to verify it's rejected" {
  # Create a temporary module file
  local temp_module
  temp_module="${FIXTURE_DIR}/test_bash4_features.sh"
  
  # Create a module with bash 4+ features
  cat > "$temp_module" << 'EOF'
#!/bin/bash
# test_bash4_features.sh - Test module with bash 4+ features

# Using associative array (bash 4+)
function test_associative_array() {
  declare -A config
  config["memory"]="256"
  config["threads"]="4"
  echo "${config["memory"]}"
}

# Using uppercase conversion (bash 4+)
function test_case_conversion() {
  local input="test string"
  local upper="${input^^}"
  echo "$upper"
}

# Using readarray (bash 4+)
function test_readarray() {
  local data="line1
line2
line3"
  readarray -t lines <<< "$data"
  echo "${lines[0]}"
}

# Using alternative approach for bash 3.2 compatibility
function test_compatible_array() {
  local config_keys=("memory" "threads")
  local config_values=("256" "4")
  local memory="${config_values[0]}"
  echo "$memory"
}

# Using compatible case conversion with tr
function test_compatible_case_conversion() {
  local input="test string"
  local upper
  upper=$(echo "$input" | tr '[:lower:]' '[:upper:]')
  echo "$upper"
}

# Using compatible readarray alternative
function test_compatible_readarray() {
  local data="line1
line2
line3"
  local lines
  lines=()
  while IFS= read -r line; do
    lines+=("$line")
  done <<< "$data"
  echo "${lines[0]}"
}
EOF
  
  # Function to check for bash 4+ features
  check_bash4_features() {
    local module_file="$1"
    
    # Check for associative arrays
    if grep -q "declare -A" "$module_file"; then
      return 1
    fi
    
    # Check for case modification
    if grep -q "\\^\\^\\|,," "$module_file"; then
      return 1
    fi
    
    # Check for readarray/mapfile
    if grep -q "readarray\\|mapfile" "$module_file"; then
      return 1
    fi
    
    return 0
  }
  
  # Should fail the check
  run check_bash4_features "$temp_module"
  [ "$status" -eq 1 ]
  
  # Now check specific functions
  function_has_bash4_features() {
    local module_file="$1"
    local func_name="$2"
    local has_features=0
    
    # Extract function body
    local func_body
    func_body=$(sed -n "/function $func_name(/,/^}/p" "$module_file")
    
    # Check for bash 4+ features
    if echo "$func_body" | grep -q "declare -A\\|\\^\\^\\|,,\\|readarray\\|mapfile"; then
      has_features=1
    fi
    
    return $has_features
  }
  
  # The test functions with bash 4+ features should fail
  run function_has_bash4_features "$temp_module" "test_associative_array"
  [ "$status" -eq 1 ]
  
  run function_has_bash4_features "$temp_module" "test_case_conversion"
  [ "$status" -eq 1 ]
  
  run function_has_bash4_features "$temp_module" "test_readarray"
  [ "$status" -eq 1 ]
  
  # The compatible versions should pass
  run function_has_bash4_features "$temp_module" "test_compatible_array"
  [ "$status" -eq 0 ]
  
  run function_has_bash4_features "$temp_module" "test_compatible_case_conversion"
  [ "$status" -eq 0 ]
  
  run function_has_bash4_features "$temp_module" "test_compatible_readarray"
  [ "$status" -eq 0 ]
}

# @nonfunctional @positive @adr002 @core
@test "Shell compatibility warning is graceful" {
  local dependency_file="${MODULE_DIR}/dependency_check.sh"
  
  # Check that shell warnings are graceful and not fatal
  if grep -q "verify_shell_environment" "$dependency_file"; then
    # Extract the function
    local func_body
    func_body=$(sed -n "/function verify_shell_environment/,/^}/p" "$dependency_file")
    
    # Check that warnings return 0 (continue execution)
    echo "$func_body" | grep -q "return 0"
    
    # Check that it doesn't exit the script
    ! echo "$func_body" | grep -q "exit [1-9]"
  fi
}

# @functional @negative @adr002 @core
@test "Create incompatible shebang line to verify it's rejected" {
  # Create a temporary module file
  local temp_module
  temp_module="${FIXTURE_DIR}/test_shebang.sh"
  
  # Create a module with different shebang lines
  for shebang in "#!/bin/sh" "#!/usr/bin/zsh" "#!/usr/bin/bash" "#! /bin/bash"; do
    echo "$shebang" > "$temp_module"
    echo "# Test module" >> "$temp_module"
    echo "echo 'Hello'" >> "$temp_module"
    
    # Function to check shebang compliance
    validate_shebang() {
      local module_file="$1"
      local shebang_line
      shebang_line=$(head -1 "$module_file")
      
      [[ "$shebang_line" == "#!/bin/bash" || "$shebang_line" == "#!/usr/bin/env bash" ]]
    }
    
    # Should fail validation for non-compliant shebang
    if [[ "$shebang" != "#!/bin/bash" && "$shebang" != "#!/usr/bin/env bash" ]]; then
      run validate_shebang "$temp_module"
      [ "$status" -ne 0 ]
    else
      run validate_shebang "$temp_module"
      [ "$status" -eq 0 ]
    fi
  done
}

# @nonfunctional @positive @adr002 @core
@test "ADR-002 recommendations align with file implementations" {
  # Extract recommendations from ADR-002
  local adr_recommendations=$(sed -n '/Implementation Notes/,$p' "$ADR_FILE")
  
  # Check that at least some of the recommendations are implemented
  local recommendations=(
    "BASH_VERSION"
    "bash_major_version"
    "bash_minor_version"
    "tr '[:lower:]' '[:upper:]'"
    "SCRIPT_PATH="
    "readlink -f"
  )
  
  local found_count=0
  
  for rec in "${recommendations[@]}"; do
    for module in "${MODULE_DIR}"/*.sh; do
      if grep -q "$rec" "$module"; then
        ((found_count++))
        break
      fi
    done
  done
  
  # At least 3 recommendations should be implemented
  [ "$found_count" -ge 3 ]
}

# @functional @positive @adr002 @dependency
@test "Bash 3.2 compatibility is enforced in dependency checks" {
  local dependency_file="${MODULE_DIR}/dependency_check.sh"
  
  # Check that verify_shell_environment exists
  grep -q "verify_shell_environment" "$dependency_file"
  
  # Check that it's called in verify_all_dependencies
  if grep -q "verify_all_dependencies" "$dependency_file"; then
    local func_body
    func_body=$(sed -n "/function verify_all_dependencies/,/^}/p" "$dependency_file")
    
    # Should call verify_shell_environment
    echo "$func_body" | grep -q "verify_shell_environment"
  fi
}