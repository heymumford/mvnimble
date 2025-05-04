#!/usr/bin/env bats
# Tests for the constants.sh module

# Load the test helpers
load ../common/helpers

# Setup test environment
setup() {
  # Call the common setup function
  load_libs
  
  # Create a temporary directory for test artifacts
  TEST_TEMP_DIR="$(mktemp -d)"
  export TEST_TEMP_DIR
  
  # Load the constants module for testing
  load_module "constants"
}

# Clean up after tests
teardown() {
  # Call the common teardown function
  if [ -n "$TEST_TEMP_DIR" ] && [ -d "$TEST_TEMP_DIR" ]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# Test that version constant is defined
@test "MVNIMBLE_VERSION is defined" {
  # Verify that the version constant is defined
  [ -n "$MVNIMBLE_VERSION" ]
}

# Test that version follows semantic versioning
@test "MVNIMBLE_VERSION follows semantic versioning format" {
  # Check that it matches the pattern X.Y.Z
  [[ "$MVNIMBLE_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

# Test that exit codes are defined
@test "Exit codes are properly defined" {
  # Verify that basic exit codes are defined
  [ -n "$EXIT_SUCCESS" ]
  [ -n "$EXIT_FAILURE" ]
  [ -n "$EXIT_INVALID_ARGS" ]
  
  # Verify that the values are different
  [ "$EXIT_SUCCESS" -ne "$EXIT_FAILURE" ]
  [ "$EXIT_SUCCESS" -ne "$EXIT_INVALID_ARGS" ]
  [ "$EXIT_FAILURE" -ne "$EXIT_INVALID_ARGS" ]
}

# Test that colors are defined for terminal output
@test "Terminal colors are defined" {
  # Verify that color constants are defined
  [ -n "$COLOR_RED" ]
  [ -n "$COLOR_GREEN" ]
  [ -n "$COLOR_YELLOW" ]
  [ -n "$COLOR_BLUE" ]
  [ -n "$COLOR_RESET" ]
}

# Test that default values are defined
@test "Default configuration values are defined" {
  # Verify that configuration defaults are defined
  [ -n "$DEFAULT_OUTPUT_DIR" ]
  [ -n "$DEFAULT_MONITOR_INTERVAL" ]
  [ -n "$DEFAULT_MAX_MONITOR_TIME" ]
}

# Test that threshold values are defined
@test "Performance threshold values are defined" {
  # Verify that threshold constants are defined
  [ -n "$CPU_USAGE_THRESHOLD" ]
  [ -n "$MEMORY_USAGE_THRESHOLD" ]
  [ -n "$SLOW_TEST_THRESHOLD" ]
}

# Test that configuration file paths are defined
@test "Configuration file paths are defined" {
  # Verify that configuration file path constants are defined
  [ -n "$USER_CONFIG_FILE" ]
  [ -n "$SYSTEM_CONFIG_FILE" ]
}

# Test that file paths are absolute
@test "File paths are absolute" {
  # Verify that file paths are absolute
  [[ "$USER_CONFIG_FILE" = /* ]]
  [[ "$SYSTEM_CONFIG_FILE" = /* ]]
  [[ "$DEFAULT_OUTPUT_DIR" = /* ]] || [[ "$DEFAULT_OUTPUT_DIR" = ./* ]]
}