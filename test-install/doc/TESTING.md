# MVNimble Testing Guide

This guide provides a comprehensive overview of the MVNimble testing framework for both users and contributors.

## Table of Contents

1. [Testing Framework Overview](#testing-framework-overview)
2. [Simplified Test Structure](#simplified-test-structure)
3. [Running Tests](#running-tests)
4. [Test Organization](#test-organization)
5. [Writing Effective Tests](#writing-effective-tests)
6. [QA Best Practices](#qa-best-practices)
7. [Troubleshooting Test Issues](#troubleshooting-test-issues)
8. [Advanced Testing Techniques](#advanced-testing-techniques)

## Testing Framework Overview

MVNimble uses [BATS (Bash Automated Testing System)](https://github.com/bats-core/bats-core) as its primary testing framework. The testing approach follows these principles:

- **Modularity**: Tests organized by functionality, making it easy to find relevant tests
- **Isolation**: Tests are designed to run independently without side effects
- **Simplicity**: Testing structure is straightforward and easy to understand
- **Cross-Platform**: Tests validate behavior across Linux and macOS environments

## Simplified Test Structure

MVNimble now uses a simplified test structure organized by functional module rather than test type, making it easier to locate and maintain related tests:

```
test/
├── simplified/             # Simplified test structure
│   ├── common/             # Common test utilities and helpers
│   │   ├── helpers.bash    # Common helper functions
│   │   └── fixtures/       # Test fixtures
│   │
│   ├── core/               # Tests for core functionality
│   │   ├── common_test.bats    # Tests for common utilities
│   │   ├── constants_test.bats # Tests for constants
│   │   └── environment_test.bats # Tests for environment detection
│   │
│   ├── monitor/            # Tests for monitoring functionality
│   │   └── monitor_test.bats  # Tests for Maven build monitoring
│   │
│   ├── analyze/            # Tests for build analysis functionality
│   │   └── analyze_test.bats  # Tests for build analysis
│   │
│   └── report/             # Tests for reporting functionality
│       └── report_test.bats   # Tests for report generation
│
├── bats/                   # Legacy test structure (for reference)
│
├── run_simplified_tests.sh # Script to run the simplified tests
└── run_bats_tests.sh       # Script to run legacy tests
```

## Running Tests

MVNimble provides two test runners to support both the simplified and legacy test structures:

### Simplified Test Runner

```bash
# Run all tests
./test/run_simplified_tests.sh

# Run tests for a specific module
./test/run_simplified_tests.sh --dir simplified/core

# Run a specific test file
./test/run_simplified_tests.sh --file simplified/core/constants_test.bats

# Show verbose output
./test/run_simplified_tests.sh --verbose

# Stop on first test failure
./test/run_simplified_tests.sh --fail-fast
```

### Legacy Test Runner

```bash
# Run all tests
./test/run_bats_tests.sh

# Run tests in a specific directory
./test/run_bats_tests.sh --test-dir ./test/bats/functional/

# Run a specific test file
./test/run_bats_tests.sh --test-dir ./test/bats/functional/adr001_shell_architecture.bats

# Run tests with specific tags
./test/run_bats_tests.sh --tags functional,positive

# Exclude certain test categories
./test/run_bats_tests.sh --exclude-tags slow,integration

# Generate reports
./test/run_bats_tests.sh --report markdown
```

## Test Organization

MVNimble tests are organized in two different ways:

### Simplified Organization (Recommended)
- **By Module**: Tests are grouped by the functionality they verify
  - **Core**: Tests for common utilities, constants, and environment detection
  - **Monitor**: Tests for Maven build monitoring functionality
  - **Analyze**: Tests for build analysis and optimization
  - **Report**: Tests for report generation and formatting

### Legacy Organization
- **By Type**
  - **Functional**: Verify specific behaviors and features
  - **Non-functional**: Test performance, usability, and other quality attributes

- **By Approach**
  - **Positive**: Verify correct behavior with valid inputs
  - **Negative**: Ensure appropriate handling of invalid inputs

- **By Component**
  - **Unit**: Individual module tests
  - **Integration**: Tests that verify interactions between components
  - **Validation**: End-to-end testing of complete features
  - **ADR-specific**: Tests that verify architectural decisions

## Writing Effective Tests

### Simplified Test Structure

```bash
#!/usr/bin/env bats
# Tests for the example.sh module

# Load the test helpers
load ../common/helpers

# Setup test environment
setup() {
  # Call the common setup function
  load_libs
  
  # Create a temporary directory for test artifacts
  TEST_TEMP_DIR="$(mktemp -d)"
  export TEST_TEMP_DIR
  
  # Load the module for testing
  load_module "example"
}

# Clean up after tests
teardown() {
  # Call the common teardown function
  if [ -n "$TEST_TEMP_DIR" ] && [ -d "$TEST_TEMP_DIR" ]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# A simple test case
@test "example function exists" {
  # Check that the function is defined
  declare -f example_function
}

# A test with assertions
@test "example function returns correct result" {
  # Arrange - set up test conditions
  local input="test-input"
  
  # Act - execute the function being tested
  result=$(example_function "$input")
  
  # Assert - verify the expected outcome
  [ "$result" = "expected output" ]
}
```

### Legacy Test Structure

```bash
#!/usr/bin/env bats

# Load test helpers
load '../test_helper.bash'

# Setup is run before each test
setup() {
  # Create test environment
  create_test_environment
}

# Teardown is run after each test
teardown() {
  # Clean up test environment
  remove_test_environment
}

# Test with taxonomy tags
@test "verify feature works correctly @test.functional @test.positive" {
  # Arrange - set up test conditions
  local input="test-input"
  
  # Act - execute the function being tested
  run function_under_test "$input"
  
  # Assert - verify the expected outcome
  assert_success
  assert_output "expected output"
}
```

### Helper Functions

The simplified test structure includes several helper functions in `test/simplified/common/helpers.bash`:

- `load_module "module_name"` - Load a specific module for testing
- `create_test_fixture "filename" "content"` - Create a test fixture file
- `assert_command_exists "command"` - Verify that a command is available
- `run_with_timeout "timeout" "command"` - Run a command with a timeout
- `create_mock_maven_output "type"` - Create a mock Maven output file
- `create_mock_environment "type"` - Create a mock environment
- `create_mock_maven_project` - Create a mock Maven project for testing

### Best Practices

1. **Follow AAA Pattern**: Arrange, Act, Assert
2. **One Assertion Per Test**: Focus on testing one specific behavior
3. **Descriptive Test Names**: Clearly describe what the test verifies
4. **Proper Setup/Teardown**: Ensure test isolation with proper cleanup
5. **Use Helper Functions**: Leverage the helper functions for common operations
6. **Test by Module**: Group related tests by the module they test
7. **Proper Error Messages**: Include helpful failure messages

## QA Best Practices

### Environment Analysis

When testing Maven projects with MVNimble:

1. **Baseline Metrics**: Establish baseline performance before optimization
2. **Controlled Variables**: Change one parameter at a time
3. **Resource Monitoring**: Monitor CPU, memory, I/O, and network usage
4. **Documentation**: Document findings and optimization results

### Test Optimization Techniques

1. **Proper Parallelization**: Balance thread count with available resources
2. **Resource Allocation**: Optimize memory settings based on test needs
3. **Test Grouping**: Group tests by execution time and dependencies
4. **JVM Reuse**: Configure fork counts to balance stability and speed

## Troubleshooting Test Issues

### Common Test Problems

1. **Non-deterministic Failures**: Tests that fail intermittently
2. **Resource Leaks**: Tests that don't properly clean up resources
3. **Timing Issues**: Tests that depend on specific timing
4. **Platform-Specific Behavior**: Tests that work on one platform but not another

### Troubleshooting Approaches

1. **Increase Verbosity**: Run tests with increased logging
   ```bash
   ./test/run_bats_tests.sh --verbose
   ```

2. **Isolate Failures**: Run specific failing tests
   ```bash
   ./test/run_bats_tests.sh --test-dir path/to/failing/test.bats
   ```

3. **Debug Mode**: Run tests in debug mode
   ```bash
   ./test/run_bats_tests.sh --debug
   ```

## Advanced Testing Techniques

### Mocking

The test helper provides utilities for mocking external commands:

```bash
# Mock a command with expected output
mock_command "external_command" "expected output"

# Mock a command that should succeed
mock_command_success "external_command"

# Mock a command that should fail
mock_command_failure "external_command" 1
```

### Test Fixtures

- Store test fixtures in `test/bats/fixtures/`
- Use the `load_fixture` helper to load fixture data
- Create fixture generators for complex test data

### Performance Testing

- Use the performance test harness in `test/bats/nonfunctional/performance/`
- Measure execution time and resource usage
- Compare results against established baselines

---
Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license