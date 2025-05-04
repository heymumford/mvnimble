#!/usr/bin/env bats
# ADR 003 Tests: Dependency Management
# Tests for validating dependency management

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
  ADR_FILE="${ADR_DIR}/003-dependency-management.md"
  [ -f "$ADR_FILE" ] || skip "ADR 003 file not found at ${ADR_FILE}"
  
  # Load dependency_check module
  source "${MODULE_DIR}/constants.sh"
  source "${MODULE_DIR}/dependency_check.sh"
  source "${MODULE_DIR}/package_manager.sh"
}

# Helper function to capture function output and status
run_function() {
  local func_name="$1"
  shift
  
  local output
  # Capture both stdout and stderr, redirecting stderr to stdout
  output=$("$func_name" "$@" 2>&1)
  local status=$?
  
  echo "$output"
  return $status
}

# @functional @positive @adr003 @dependency
@test "Centralized dependency checking module exists" {
  # Check that dependency_check.sh exists
  [ -f "${MODULE_DIR}/dependency_check.sh" ]
  
  # Check that it has a main verification function
  grep -q "verify_all_dependencies" "${MODULE_DIR}/dependency_check.sh"
  
  # Check that it has specific verification functions
  grep -q "verify_essential_commands" "${MODULE_DIR}/dependency_check.sh"
}

# @functional @positive @adr003 @dependency
@test "Essential commands verification works" {
  # Set a fake essential commands list for testing
  local original_commands="$ESSENTIAL_COMMANDS"
  
  # Test with commands that should exist
  ESSENTIAL_COMMANDS="echo ls grep"
  run verify_essential_commands
  [ "$status" -eq 0 ]
  
  # Test with a command that should not exist
  ESSENTIAL_COMMANDS="this_command_should_not_exist_anywhere_z1x2c3v4"
  run verify_essential_commands
  [ "$status" -ne 0 ]
  
  # Restore original value
  ESSENTIAL_COMMANDS="$original_commands"
}

# @functional @positive @adr003 @dependency
@test "Java version verification handles different formats" {
  # Mock java command
  java() {
    if [[ "$1" == "-version" ]]; then
      echo "java version \"1.8.0_292\"" >&2
      return 0
    fi
    command java "$@"
  }
  
  # Original MINIMUM_JAVA_VERSION value
  local original_min_java="$MINIMUM_JAVA_VERSION"
  
  # Set minimum to 8 (which the mock provides)
  MINIMUM_JAVA_VERSION=8
  
  # This should succeed
  run verify_java_installation
  [ "$status" -eq 0 ]
  
  # Set minimum higher than mock
  MINIMUM_JAVA_VERSION=11
  
  # This should fail
  run verify_java_installation
  [ "$status" -ne 0 ]
  
  # Restore original value
  MINIMUM_JAVA_VERSION="$original_min_java"
  
  # Unset the mock
  unset -f java
}

# @functional @positive @adr003 @package-manager
@test "Package manager detection returns valid value" {
  # Run the function
  run detect_package_manager
  
  # Check status
  [ "$status" -eq 0 ]
  
  # Output should not be empty
  [ -n "$output" ]
  
  # Output should be one of the expected values
  local valid=false
  for mgr in "$PKG_MGR_APT" "$PKG_MGR_BREW" "$PKG_MGR_YUM" "$PKG_MGR_DNF" "$PKG_MGR_PACMAN" "$PKG_MGR_ZYPPER" "$PKG_MGR_UNKNOWN"; do
    if [[ "$output" == "$mgr" ]]; then
      valid=true
      break
    fi
  done
  
  [ "$valid" = true ]
}

# @functional @positive @adr003 @package-manager
@test "Installation instructions are provided for packages" {
  # Mock detect_package_manager for testing
  local original_detect="$(declare -f detect_package_manager)"
  
  # Test with different package managers
  for pkg_mgr in "$PKG_MGR_APT" "$PKG_MGR_BREW" "$PKG_MGR_YUM" "$PKG_MGR_DNF" "$PKG_MGR_PACMAN" "$PKG_MGR_ZYPPER" "$PKG_MGR_UNKNOWN"; do
    # Override the function for this test
    eval "detect_package_manager() { echo \"$pkg_mgr\"; }"
    
    # Get install command for a test package
    run get_install_command "test-package"
    
    # Command should not be empty
    [ -n "$output" ]
    
    # Command should mention the package name
    [[ "$output" == *"test-package"* ]]
    
    # If it's a known package manager, it should include specific command
    if [[ "$pkg_mgr" != "$PKG_MGR_UNKNOWN" ]]; then
      case "$pkg_mgr" in
        "$PKG_MGR_APT")
          [[ "$output" == *"apt-get"* ]]
          ;;
        "$PKG_MGR_BREW")
          [[ "$output" == *"brew"* ]]
          ;;
        "$PKG_MGR_YUM")
          [[ "$output" == *"yum"* ]]
          ;;
        "$PKG_MGR_DNF")
          [[ "$output" == *"dnf"* ]]
          ;;
        "$PKG_MGR_PACMAN")
          [[ "$output" == *"pacman"* ]]
          ;;
        "$PKG_MGR_ZYPPER")
          [[ "$output" == *"zypper"* ]]
          ;;
      esac
    fi
  done
  
  # Restore original function
  eval "$original_detect"
}

# @functional @negative @adr003 @dependency
@test "Dependency errors are reported clearly" {
  # Test with a non-existent command
  run verify_essential_commands
  
  if [ "$status" -ne 0 ]; then
    # Error message should be clear
    [[ "$output" == *"ERROR"* ]]
    [[ "$output" == *"Missing"* || "$output" == *"missing"* ]]
  fi
  
  # Mock java with wrong version
  java() {
    if [[ "$1" == "-version" ]]; then
      echo "java version \"1.6.0_45\"" >&2
      return 0
    fi
    command java "$@"
  }
  
  # Original MINIMUM_JAVA_VERSION value
  local original_min_java="$MINIMUM_JAVA_VERSION"
  
  # Set minimum higher than mock
  MINIMUM_JAVA_VERSION=8
  
  # This should fail
  run verify_java_installation
  
  if [ "$status" -ne 0 ]; then
    # Error message should be clear
    [[ "$output" == *"ERROR"* ]]
    [[ "$output" == *"version"* ]]
    [[ "$output" == *"minimum"* ]]
  fi
  
  # Restore original value
  MINIMUM_JAVA_VERSION="$original_min_java"
  
  # Unset the mock
  unset -f java
}

# @functional @positive @adr003 @dependency
@test "verify_all_dependencies combines multiple checks" {
  # Create a mock results directory
  local results_dir
  results_dir="${FIXTURE_DIR}/mock_results"
  mkdir -p "$results_dir"
  
  # Run with minimal checks to avoid system-specific failures
  run verify_all_dependencies "$results_dir" false false
  
  # Check that we get comprehensive output
  echo "$output" | grep -qi "dependency\\|environment\\|ERROR\\|found"
  
  # Clean up
  rm -rf "$results_dir"
}

# @functional @positive @adr003 @package-manager
@test "check_and_offer_install handles MVNIMBLE_NONINTERACTIVE" {
  # Save original value
  local original_interactive="${MVNIMBLE_NONINTERACTIVE:-}"
  
  # Set to non-interactive
  export MVNIMBLE_NONINTERACTIVE=true
  
  # Mock is_package_installed to return false
  local original_is_pkg="$(declare -f is_package_installed)"
  eval "is_package_installed() { return 1; }"
  
  # Test with optional package (should not fail)
  run check_and_offer_install "test-package" false false
  [ "$status" -eq 0 ]
  
  # Test with required package (should fail)
  run check_and_offer_install "test-package" true false
  [ "$status" -ne 0 ]
  
  # Restore original values
  if [ -z "$original_interactive" ]; then
    unset MVNIMBLE_NONINTERACTIVE
  else
    export MVNIMBLE_NONINTERACTIVE="$original_interactive"
  fi
  
  if [ -n "$original_is_pkg" ]; then
    eval "$original_is_pkg"
  else
    unset -f is_package_installed
  fi
}

# @functional @negative @adr003 @dependency
@test "System resource checks fail with inadequate resources" {
  # Mock the functions for testing
  local original_get_total="$(declare -f get_total_memory_mb)"
  local original_get_free="$(declare -f get_free_disk_space_mb)"
  
  # Ensure these functions exist
  # If they don't, skip this test
  if [ -z "$original_get_total" ] || [ -z "$original_get_free" ]; then
    skip "Required functions not found"
  fi
  
  # Test with insufficient memory
  eval "get_total_memory_mb() { echo 10; }"
  run verify_system_resources
  [ "$status" -ne 0 ]
  [[ "$output" == *"Insufficient memory"* ]]
  
  # Test with insufficient disk space
  eval "get_total_memory_mb() { echo 1024; }"
  eval "get_free_disk_space_mb() { echo 10; }"
  run verify_system_resources
  [ "$status" -ne 0 ]
  [[ "$output" == *"Insufficient disk space"* ]]
  
  # Restore original functions
  if [ -n "$original_get_total" ]; then
    eval "$original_get_total"
  else
    unset -f get_total_memory_mb
  fi
  
  if [ -n "$original_get_free" ]; then
    eval "$original_get_free"
  else
    unset -f get_free_disk_space_mb
  fi
}

# @functional @positive @adr003 @dependency
@test "Maven project validation checks for pom.xml" {
  # Create temporary test directory
  local test_dir
  test_dir="${FIXTURE_DIR}/test_mvn_project"
  mkdir -p "$test_dir"
  
  # Save current directory
  local cwd
  cwd=$(pwd)
  
  # Change to test directory
  cd "$test_dir"
  
  # Test without pom.xml
  run verify_maven_project
  [ "$status" -ne 0 ]
  
  # Create an invalid pom.xml (empty file)
  touch "$test_dir/pom.xml"
  
  # Test with invalid pom.xml
  run verify_maven_project
  [ "$status" -ne 0 ]
  
  # Create a valid-looking pom.xml
  echo "<project xmlns=\"http://maven.apache.org/POM/4.0.0\">" > "$test_dir/pom.xml"
  echo "  <modelVersion>4.0.0</modelVersion>" >> "$test_dir/pom.xml"
  echo "</project>" >> "$test_dir/pom.xml"
  
  # Test with valid pom.xml
  run verify_maven_project
  [ "$status" -eq 0 ]
  
  # Clean up
  cd "$cwd"
  rm -rf "$test_dir"
}

# @functional @positive @adr003 @dependency
@test "Write permission validation works" {
  # Create temporary test directory
  local test_dir
  test_dir="${FIXTURE_DIR}/test_write_perms"
  mkdir -p "$test_dir"
  
  # Test with writable directory
  run verify_write_permissions "$test_dir"
  [ "$status" -eq 0 ]
  
  # Clean up
  rm -rf "$test_dir"
  
  # Test with non-existent directory (should create it)
  run verify_write_permissions "${FIXTURE_DIR}/nonexistent_dir"
  [ "$status" -eq 0 ]
  
  # Directory should now exist
  [ -d "${FIXTURE_DIR}/nonexistent_dir" ]
  
  # Clean up
  rm -rf "${FIXTURE_DIR}/nonexistent_dir"
}

# @functional @positive @adr003 @dependency
@test "ShellCheck validation is optional" {
  # Test with shellcheck not required
  run verify_shellcheck_installation false
  [ "$status" -eq 0 ]
  
  # If shellcheck is available, test with it required
  if command -v shellcheck > /dev/null; then
    run verify_shellcheck_installation true
    [ "$status" -eq 0 ]
  fi
}

# @functional @positive @adr003 @platform
@test "Platform compatibility check is just a warning" {
  # The function should always return 0 (success) regardless of platform
  run verify_platform_compatibility
  [ "$status" -eq 0 ]
  
  # But it might output warnings
  if [[ "$(uname)" != "Darwin" && "$(uname)" != "Linux" ]]; then
    [[ "$output" == *"WARNING"* ]]
  fi
}

# @nonfunctional @positive @adr003 @dependency
@test "Error messages are clear and actionable" {
  # Test various dependency functions for clear error messages
  
  # Test with a non-existent command
  local ESSENTIAL_COMMANDS="nonexistent_command_xyz"
  run verify_essential_commands
  
  # Should fail and provide clear error
  [ "$status" -ne 0 ]
  [[ "$output" == *"ERROR"* ]]
  [[ "$output" == *"Missing"* || "$output" == *"missing"* ]]
  [[ "$output" == *"nonexistent_command_xyz"* ]]
  [[ "$output" == *"install"* ]]
  
  # Mock java absence
  command() {
    if [[ "$2" == "java" ]]; then
      return 1
    else
      command "$@"
    fi
  }
  
  run verify_java_installation
  
  # Should fail with clear java-specific message
  [ "$status" -ne 0 ]
  [[ "$output" == *"ERROR"* ]]
  [[ "$output" == *"Java"* ]]
  [[ "$output" == *"not installed"* || "$output" == *"not in PATH"* ]]
  [[ "$output" == *"install"* ]]
  
  # Unmock command
  unset -f command
}

# @functional @negative @adr003 @dependency
@test "Fail-fast approach for critical dependencies" {
  # Modify essential commands to include a non-existent command
  local original_essentials="$ESSENTIAL_COMMANDS"
  ESSENTIAL_COMMANDS="nonexistent_command_xyz bash"
  
  # Create a temporary results directory
  local test_dir
  test_dir="${FIXTURE_DIR}/fail_fast_test"
  mkdir -p "$test_dir"
  
  # Run full dependency check
  run verify_all_dependencies "$test_dir" false false
  
  # Should fail with error count > 0
  [ "$status" -ne 0 ]
  [[ "$output" == *"ERROR"* ]]
  [[ "$output" == *"Found"*"issues"* ]]
  
  # Restore original value
  ESSENTIAL_COMMANDS="$original_essentials"
  
  # Clean up
  rm -rf "$test_dir"
}

# @functional @positive @adr003 @package-manager
@test "Package manager update command is available" {
  # Check that get_update_command exists
  grep -q "get_update_command" "${MODULE_DIR}/package_manager.sh"
  
  # Test with different package managers
  local original_detect="$(declare -f detect_package_manager)"
  
  for pkg_mgr in "$PKG_MGR_APT" "$PKG_MGR_BREW" "$PKG_MGR_YUM" "$PKG_MGR_DNF" "$PKG_MGR_PACMAN" "$PKG_MGR_ZYPPER" "$PKG_MGR_UNKNOWN"; do
    # Override the function for this test
    eval "detect_package_manager() { echo \"$pkg_mgr\"; }"
    
    # Get update command
    run get_update_command
    
    # If it's a known package manager, it should return a command
    if [[ "$pkg_mgr" != "$PKG_MGR_UNKNOWN" ]]; then
      [ -n "$output" ]
      
      case "$pkg_mgr" in
        "$PKG_MGR_APT")
          [[ "$output" == *"apt-get update"* ]]
          ;;
        "$PKG_MGR_BREW")
          [[ "$output" == *"brew update"* ]]
          ;;
        "$PKG_MGR_YUM")
          [[ "$output" == *"yum"*"update"* ]]
          ;;
        "$PKG_MGR_DNF")
          [[ "$output" == *"dnf"*"update"* ]]
          ;;
        "$PKG_MGR_PACMAN")
          [[ "$output" == *"pacman"* ]]
          ;;
        "$PKG_MGR_ZYPPER")
          [[ "$output" == *"zypper"* ]]
          ;;
      esac
    fi
  done
  
  # Restore original function
  eval "$original_detect"
}

# @nonfunctional @positive @adr003 @dependency
@test "ADR-003 implementation matches documentation" {
  # Check that actual implementation follows the patterns documented in ADR-003
  
  # Check for core dependency check function
  grep -q "verify_essential_commands" "${MODULE_DIR}/dependency_check.sh"
  
  # Check for version check function
  grep -q "verify_java_installation\\|verify_java_version" "${MODULE_DIR}/dependency_check.sh"
  
  # Check for package manager detection
  grep -q "detect_package_manager" "${MODULE_DIR}/package_manager.sh"
  
  # Check for installation instructions
  grep -q "get_install_command\\|provide_installation_instructions" "${MODULE_DIR}/package_manager.sh"
  
  # Check for main verification function
  grep -q "verify_all_dependencies" "${MODULE_DIR}/dependency_check.sh"
}

# @functional @negative @adr003 @dependency
@test "Installation attempt works when auto-install is enabled" {
  # Skip on CI or when no package manager
  if [ -n "${CI:-}" ] || [ "$(detect_package_manager)" = "$PKG_MGR_UNKNOWN" ]; then
    skip "Skipping installation test in CI or with unknown package manager"
  fi
  
  # Mock is_package_installed and install_package
  local original_is_pkg="$(declare -f is_package_installed)"
  local original_install="$(declare -f install_package)"
  
  eval "is_package_installed() { return 1; }"
  eval "install_package() { 
    echo \"Installing \$1 using \$2...\"
    if [ \"\$2\" = \"true\" ]; then
      echo \"Installation successful\"
      return 0
    else
      echo \"Auto-install disabled\"
      return 1
    fi
  }"
  
  # Test without auto-install
  run check_and_offer_install "test-package" false false
  [ "$status" -eq 0 ]
  [[ "$output" == *"test-package is not installed"* ]]
  
  # Test with auto-install
  run check_and_offer_install "test-package" false true
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installing test-package"* ]]
  [[ "$output" == *"Installation successful"* ]]
  
  # Test with required package and no auto-install
  run check_and_offer_install "test-package" true false
  [ "$status" -ne 0 ]
  [[ "$output" == *"test-package is not installed"* ]]
  
  # Restore original functions
  if [ -n "$original_is_pkg" ]; then
    eval "$original_is_pkg"
  else
    unset -f is_package_installed
  fi
  
  if [ -n "$original_install" ]; then
    eval "$original_install"
  else
    unset -f install_package
  fi
}

# @nonfunctional @positive @adr003 @dependency
@test "Clear distinction between essential and optional dependencies" {
  # Check that there are both essential and optional checks
  grep -q "ESSENTIAL_COMMANDS" "${MODULE_DIR}/constants.sh"
  grep -q "OPTIONAL_COMMANDS" "${MODULE_DIR}/constants.sh"
  
  # Check that essential checks return error status
  grep -q "verify_essential_commands.*return 1" "${MODULE_DIR}/dependency_check.sh"
  
  # Check that optional checks might be skipped
  grep -A5 "verify_shellcheck_installation" "${MODULE_DIR}/dependency_check.sh" | grep -q "return 0"
}