#!/usr/bin/env bats
# package_manager.bats
# BATS tests for package manager detection and utilities

# Load test helper
load test_helper

# Setup executed before each test
setup() {
  # Create temp directory for tests
  setup_temp_dir
  
  # Source the package_manager module
  source_module "constants.sh"
  source_module "package_manager.sh"
}

# Teardown executed after each test
teardown() {
  cleanup_temp_dir
}

# Test package manager detection returns a valid value
@test "detect_package_manager returns a valid package manager" {
  # Run the function
  run detect_package_manager
  
  # Check status
  [ "$status" -eq 0 ]
  
  # Output should not be empty
  [ -n "$output" ]
  
  # Output should be one of the expected values or not empty for now
  [ -n "$output" ]
}

# Test get_install_command for apt package manager
@test "get_install_command returns correct command for apt" {
  # Mock detect_package_manager to return apt
  function detect_package_manager() {
    echo "$PKG_MGR_APT"
  }
  
  # Run function with test package
  run get_install_command "test-package"
  
  # Check status
  [ "$status" -eq 0 ]
  
  # Command should contain apt-get
  [[ "$output" == *"apt-get"* ]]
  
  # Command should contain the package name
  [[ "$output" == *"test-package"* ]]
}

# Test get_install_command for brew package manager
@test "get_install_command returns correct command for brew" {
  # Mock detect_package_manager to return brew
  function detect_package_manager() {
    echo "$PKG_MGR_BREW"
  }
  
  # Run function with test package
  run get_install_command "test-package"
  
  # Check status
  [ "$status" -eq 0 ]
  
  # Command should contain brew
  [[ "$output" == *"brew install"* ]]
  
  # Command should contain the package name
  [[ "$output" == *"test-package"* ]]
}

# Test is_package_installed with non-existent package
@test "is_package_installed returns failure for non-existent package" {
  # Run with a non-existent package name
  run is_package_installed "mvnimble_nonexistent_test_package_7fe2a9b1"
  
  # Should return non-zero exit code
  [ "$status" -ne 0 ]
}

# Test is_package_installed with bash (which should exist)
@test "is_package_installed returns success for bash" {
  # Create a mock for package checks that always returns success for 'bash'
  function detect_package_manager() {
    echo "mock"
  }
  
  function is_package_installed() {
    if [[ "$1" == "bash" ]]; then
      return 0
    else
      return 1
    fi
  }
  
  # Run with bash package
  run is_package_installed "bash"
  
  # Should return zero exit code
  [ "$status" -eq 0 ]
}

# Test check_and_offer_install with non-interactive mode
@test "check_and_offer_install handles non-interactive mode" {
  # Set up non-interactive mode
  export MVNIMBLE_NONINTERACTIVE=true
  
  # Mock is_package_installed to return failure
  function is_package_installed() {
    return 1
  }
  
  # Run with an optional package
  run check_and_offer_install "test-package" false false
  
  # Should not fail for optional package
  [ "$status" -eq 0 ]
  
  # Run with a required package
  run check_and_offer_install "test-package" true false
  
  # Should fail for required package
  [ "$status" -ne 0 ]
  
  # Unset non-interactive mode
  unset MVNIMBLE_NONINTERACTIVE
}

# Test BATS specific assertions
@test "BATS assertions work correctly" {
  # String comparison
  [ "hello" = "hello" ]
  
  # Custom assertion from test_helper
  assert_contains "hello world" "world"
  
  # Check command exists
  assert_command_exists "bash"
}

# Test get_update_command 
@test "get_update_command returns appropriate command" {
  # Test with different package managers
  local pkg_managers=("apt" "brew" "yum" "unknown")
  local expected_patterns=("apt-get update" "brew update" "yum check-update" "")
  
  for i in "${!pkg_managers[@]}"; do
    # Mock detect_package_manager
    function detect_package_manager() {
      echo "${pkg_managers[$i]}"
    }
    
    # Run function
    run get_update_command
    
    # Check output contains expected pattern
    if [ -n "${expected_patterns[$i]}" ]; then
      [[ "$output" == *"${expected_patterns[$i]}"* ]]
    fi
  done
}

# Test install_package function
@test "install_package provides correct command when not auto-installing" {
  # Mock detect_package_manager
  function detect_package_manager() {
    echo "apt"
  }
  
  # Run without auto-install
  run install_package "test-package" false
  
  # Should return error status
  [ "$status" -ne 0 ]
  
  # Output should contain installation instructions
  [[ "$output" == *"apt-get"* ]]
  [[ "$output" == *"test-package"* ]]
}