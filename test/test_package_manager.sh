#!/bin/bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# test_package_manager.sh
# Tests for package manager detection and utilities

# Source test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./test.sh
source "${SCRIPT_DIR}/test.sh"

# Source the module to test
# shellcheck source=../src/lib/modules/package_manager.sh
source "${SCRIPT_DIR}/../src/lib/modules/package_manager.sh"

# Test that package manager detection returns a valid value
test_detect_package_manager() {
  local result
  result=$(detect_package_manager)
  
  # It should return a non-empty string
  [[ -n "$result" ]] || return 1
  
  # It should be one of the expected values
  case "$result" in
    "$PKG_MGR_APT"|"$PKG_MGR_BREW"|"$PKG_MGR_YUM"|"$PKG_MGR_DNF"|"$PKG_MGR_PACMAN"|"$PKG_MGR_ZYPPER"|"$PKG_MGR_UNKNOWN")
      # Valid result
      return 0
      ;;
    *)
      echo "Unexpected package manager detected: $result"
      return 1
      ;;
  esac
}

# Test that get_install_command returns the correct command for different package managers
test_get_install_command() {
  local apt_cmd brew_cmd test_pkg="test-package"
  
  apt_cmd=$(FUNCTION_OVERRIDE_detect_package_manager="$PKG_MGR_APT" get_install_command "$test_pkg")
  assert_contains "apt-get" "$apt_cmd" "APT command should contain apt-get"
  assert_contains "$test_pkg" "$apt_cmd" "APT command should contain the package name"
  
  brew_cmd=$(FUNCTION_OVERRIDE_detect_package_manager="$PKG_MGR_BREW" get_install_command "$test_pkg")
  assert_contains "brew" "$brew_cmd" "Brew command should contain brew"
  assert_contains "$test_pkg" "$brew_cmd" "Brew command should contain the package name"
  
  return 0
}

# Mock functions for testing
FUNCTION_OVERRIDE_detect_package_manager=""
detect_package_manager() {
  if [ -n "$FUNCTION_OVERRIDE_detect_package_manager" ]; then
    echo "$FUNCTION_OVERRIDE_detect_package_manager"
  else
    # Call the real function
    # shellcheck source=../src/lib/modules/package_manager.sh
    source "${SCRIPT_DIR}/../src/lib/modules/package_manager.sh"
    command detect_package_manager
  fi
}

# Test is_package_installed with an intentionally non-existent package
test_is_package_installed_nonexistent() {
  # Choose a package name that is very unlikely to exist
  local nonexistent_pkg="mvnimble_nonexistent_test_package_7fe2a9b1"
  
  # It should return false (non-zero)
  if is_package_installed "$nonexistent_pkg"; then
    echo "is_package_installed incorrectly reported that $nonexistent_pkg is installed"
    return 1
  fi
  
  return 0
}

# Test that package manager detection meets ADR-003 requirements
test_adr_003_package_manager_detection() {
  # Verify that detect_package_manager exists and returns a value
  local pkg_manager
  pkg_manager=$(detect_package_manager)
  
  assert_not_equal "" "$pkg_manager" "Package manager detection should return a value"
  
  # Verify that get_install_command provides appropriate instructions
  local install_cmd
  install_cmd=$(get_install_command "shellcheck")
  
  assert_not_equal "" "$install_cmd" "Install command should be provided"
  assert_contains "shellcheck" "$install_cmd" "Install command should include the package name"
  
  return 0
}

# Run the tests if this file is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_all_tests "$(basename "${BASH_SOURCE[0]}")"
fi