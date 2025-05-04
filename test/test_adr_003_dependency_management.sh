#!/bin/bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# test_adr_003_dependency_management.sh
# Tests for ADR 003: Dependency Management
#
# This test suite validates that the dependency management 
# system meets the requirements defined in ADR 003.

# Source test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./test.sh
source "${SCRIPT_DIR}/test.sh"

# Source dependency_check module for direct function testing
# shellcheck source=../src/lib/modules/dependency_check.sh
source "${SCRIPT_DIR}/../src/lib/modules/dependency_check.sh"

# Source package_manager module for direct function testing
# shellcheck source=../src/lib/modules/package_manager.sh
source "${SCRIPT_DIR}/../src/lib/modules/package_manager.sh"

# Test that the dependency_check module exists
test_dependency_check_module_exists() {
  assert_file_exists "${SCRIPT_DIR}/../src/lib/modules/dependency_check.sh" "Dependency check module should exist"
}

# Test that the package manager detection function exists and works
test_package_manager_detection() {
  # This function should return something
  local pkg_manager
  pkg_manager=$(detect_package_manager)
  
  assert_not_equal "" "$pkg_manager" "Package manager detection should return a value"
  
  # It should be one of the expected values
  local valid_manager=false
  case "$pkg_manager" in
    "$PKG_MGR_APT"|"$PKG_MGR_BREW"|"$PKG_MGR_YUM"|"$PKG_MGR_DNF"|"$PKG_MGR_PACMAN"|"$PKG_MGR_ZYPPER"|"$PKG_MGR_UNKNOWN")
      valid_manager=true
      ;;
    *)
      valid_manager=false
      ;;
  esac
  
  assert_equal "true" "$valid_manager" "Package manager should be a valid known type"
}

# Test that the get_install_command function exists and works
test_get_install_command() {
  # Function should return an installation command
  local install_cmd
  install_cmd=$(get_install_command "test-package")
  
  assert_not_equal "" "$install_cmd" "Install command should not be empty"
  assert_contains "test-package" "$install_cmd" "Install command should include package name"
}

# Test essential commands verification
test_verify_essential_commands() {
  # We need to mock the ESSENTIAL_COMMANDS variable to test with a known command
  # Store original value to restore later
  local original_commands="$ESSENTIAL_COMMANDS"
  
  # Test with a command that should exist
  ESSENTIAL_COMMANDS="echo"
  local result
  if verify_essential_commands > /dev/null 2>&1; then
    result=0
  else
    result=1
  fi
  assert_equal 0 "$result" "Verification should pass with essential command 'echo'"
  
  # Test with a command that should not exist (using a deliberately invalid name)
  ESSENTIAL_COMMANDS="thiscmdreallyshouldnotexistzzxxyy"
  if verify_essential_commands > /dev/null 2>&1; then
    result=0
  else
    result=1
  fi
  assert_equal 1 "$result" "Verification should fail with nonexistent command"
  
  # Restore original value
  ESSENTIAL_COMMANDS="$original_commands"
}

# Test Java version verification
test_verify_java_installation() {
  # We need to mock parts of the verification to test failure cases
  # First, save the original function
  if declare -f command > /dev/null; then
    eval "original_command() { $(declare -f command | tail -n +3)"
  fi
  
  # Next, create a mock command function that returns false for java
  command() {
    if [[ "$2" == "java" ]]; then
      return 1
    else
      original_command "$@"
    fi
  }
  
  # Test that verification fails when java is "not installed"
  local result
  if verify_java_installation > /dev/null 2>&1; then
    result=0
  else
    result=1
  fi
  assert_equal 1 "$result" "Java verification should fail when java isn't available"
  
  # Restore original command function
  if declare -f original_command > /dev/null; then
    eval "command() { $(declare -f original_command | tail -n +3)"
    unset -f original_command
  fi
  
  # Now test with real java if it's available on the system
  if command -v java > /dev/null 2>&1; then
    if verify_java_installation > /dev/null 2>&1; then
      result=0
    else
      result=1
    fi
    assert_equal 0 "$result" "Java verification should pass with installed java"
  fi
}

# Test system resources verification
test_verify_system_resources() {
  # This should pass on most systems
  local result
  if verify_system_resources > /dev/null 2>&1; then
    result=0
  else
    result=1
  fi
  assert_equal 0 "$result" "System resource verification should pass on test system"
}

# Test version validation capability
test_version_validation() {
  # Create a test version comparison
  local current_version="1.2.3"
  local min_version="1.0.0"
  
  # Extract and compare using similar logic from dependency_check.sh
  local current_major current_minor current_patch
  current_major=$(echo "$current_version" | cut -d. -f1)
  current_minor=$(echo "$current_version" | cut -d. -f2)
  current_patch=$(echo "$current_version" | cut -d. -f3)
  
  local min_major min_minor min_patch
  min_major=$(echo "$min_version" | cut -d. -f1)
  min_minor=$(echo "$min_version" | cut -d. -f2)
  min_patch=$(echo "$min_version" | cut -d. -f3)
  
  # Versions are compared by cascading comparison of components
  local version_ok=1
  if [ "$current_major" -gt "$min_major" ]; then
    version_ok=0
  elif [ "$current_major" -eq "$min_major" ] && [ "$current_minor" -gt "$min_minor" ]; then
    version_ok=0
  elif [ "$current_major" -eq "$min_major" ] && [ "$current_minor" -eq "$min_minor" ] && [ "$current_patch" -ge "$min_patch" ]; then
    version_ok=0
  fi
  
  assert_equal 0 "$version_ok" "Version comparison should handle semver correctly"
  
  # Test with older version
  current_version="0.9.0"
  current_major=$(echo "$current_version" | cut -d. -f1)
  current_minor=$(echo "$current_version" | cut -d. -f2)
  current_patch=$(echo "$current_version" | cut -d. -f3)
  
  version_ok=1
  if [ "$current_major" -gt "$min_major" ]; then
    version_ok=0
  elif [ "$current_major" -eq "$min_major" ] && [ "$current_minor" -gt "$min_minor" ]; then
    version_ok=0
  elif [ "$current_major" -eq "$min_major" ] && [ "$current_minor" -eq "$min_minor" ] && [ "$current_patch" -ge "$min_patch" ]; then
    version_ok=0
  fi
  
  assert_equal 1 "$version_ok" "Version comparison should fail for older versions"
}

# Test the is_package_installed function
test_is_package_installed() {
  # Test with a package that should definitely not exist
  local result
  if is_package_installed "mvnimble_nonexistent_test_package_7fe2a9b1" > /dev/null 2>&1; then
    result=0
  else
    result=1
  fi
  assert_equal 1 "$result" "Non-existent package should not be reported as installed"
  
  # Test with bash which should be installed on any system running these tests
  if is_package_installed "bash" > /dev/null 2>&1 || is_package_installed "bash-default" > /dev/null 2>&1; then
    result=0
  else
    result=1
  fi
  assert_equal 0 "$result" "Bash should be reported as installed"
}

# Test the check_and_offer_install function
test_check_and_offer_install() {
  # Test with non-interactive mode to avoid blocking test
  local old_noninteractive="${MVNIMBLE_NONINTERACTIVE}"
  export MVNIMBLE_NONINTERACTIVE=true
  
  # Should not fail with optional package
  local result
  if check_and_offer_install "mvnimble_nonexistent_test_package_7fe2a9b1" false false > /dev/null 2>&1; then
    result=0
  else
    result=1
  fi
  assert_equal 0 "$result" "Optional package check should not fail"
  
  # Should fail with required package
  if check_and_offer_install "mvnimble_nonexistent_test_package_7fe2a9b1" true false > /dev/null 2>&1; then
    result=0
  else
    result=1
  fi
  assert_equal 1 "$result" "Required package check should fail"
  
  # Restore original value
  if [ -z "$old_noninteractive" ]; then
    unset MVNIMBLE_NONINTERACTIVE
  else
    export MVNIMBLE_NONINTERACTIVE="$old_noninteractive"
  fi
}

# Test installation instructions generation
test_installation_instructions() {
  # Test with a common package
  local pkg="shellcheck"
  local pkg_manager
  pkg_manager=$(detect_package_manager)
  
  # Get install command
  local install_cmd
  install_cmd=$(get_install_command "$pkg")
  
  # Verify command is appropriate for current package manager
  case "$pkg_manager" in
    apt)
      assert_contains "apt-get" "$install_cmd" "APT install command should use apt-get"
      ;;
    brew)
      assert_contains "brew install" "$install_cmd" "Brew install command should use brew install"
      ;;
    yum)
      assert_contains "yum" "$install_cmd" "YUM install command should use yum"
      ;;
    dnf)
      assert_contains "dnf" "$install_cmd" "DNF install command should use dnf"
      ;;
    pacman)
      assert_contains "pacman" "$install_cmd" "Pacman install command should use pacman"
      ;;
    zypper)
      assert_contains "zypper" "$install_cmd" "Zypper install command should use zypper"
      ;;
    *)
      # For unknown package managers, check for generic guidance
      assert_contains "system's package manager" "$install_cmd" "Unknown package manager should give generic guidance"
      ;;
  esac
  
  # Always check that the package name is included
  assert_contains "$pkg" "$install_cmd" "Install command should include package name"
}

# Test comprehensive verification with all dependencies
test_verify_all_dependencies() {
  # Create a temporary directory for testing
  local tmp_dir
  tmp_dir=$(mktemp -d)
  
  # Test verification with minimal checks (false for shellcheck and bashate checks)
  local result
  if verify_all_dependencies "$tmp_dir" false false > /dev/null 2>&1; then
    result=0
  else
    result=1
  fi
  
  # Should fail because it's not a Maven project directory
  assert_equal 1 "$result" "Verification should fail in a non-Maven directory"
  
  # Clean up temp directory
  rm -rf "$tmp_dir"
}

# Run the tests if this file is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_all_tests "$(basename "${BASH_SOURCE[0]}")"
fi