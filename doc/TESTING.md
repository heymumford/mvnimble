# MVNimble Testing Guide

This guide provides a comprehensive overview of the MVNimble testing framework for both users and contributors.

## Table of Contents

1. [Testing Framework Overview](#testing-framework-overview)
2. [Running Tests](#running-tests)
3. [Test Organization](#test-organization)
4. [Writing Effective Tests](#writing-effective-tests)
5. [QA Best Practices](#qa-best-practices)
6. [Troubleshooting Test Issues](#troubleshooting-test-issues)
7. [Advanced Testing Techniques](#advanced-testing-techniques)

## Testing Framework Overview

MVNimble uses [BATS (Bash Automated Testing System)](https://github.com/bats-core/bats-core) as its primary testing framework. The testing approach follows these principles:

- **Comprehensive Coverage**: Every component and ADR has corresponding tests
- **Structured Taxonomy**: Tests are categorized by type, approach, and component
- **Isolation**: Tests are designed to run independently without side effects
- **Cross-Platform**: Tests validate behavior across Linux and macOS environments

## Running Tests

### Basic Test Execution

```bash
# Run all tests
./test/run_bats_tests.sh

# Run tests in a specific directory
./test/run_bats_tests.sh --test-dir ./test/bats/functional/

# Run a specific test file
./test/run_bats_tests.sh --test-dir ./test/bats/functional/adr001_shell_architecture.bats
```

### Testing with Tags

```bash
# Run only functional tests
./test/run_bats_tests.sh --tags functional

# Run positive functional tests
./test/run_bats_tests.sh --tags functional,positive

# Exclude certain test categories
./test/run_bats_tests.sh --exclude-tags slow,integration
```

### Generating Reports

```bash
# Generate markdown report
./test/run_bats_tests.sh --report markdown

# Generate JSON report
./test/run_bats_tests.sh --report json

# Generate TAP output
./test/run_bats_tests.sh --report tap
```

## Test Organization

MVNimble tests are organized along several dimensions:

### By Type
- **Functional**: Verify specific behaviors and features
- **Non-functional**: Test performance, usability, and other quality attributes

### By Approach
- **Positive**: Verify correct behavior with valid inputs
- **Negative**: Ensure appropriate handling of invalid inputs

### By Component
- **Unit**: Individual module tests
- **Integration**: Tests that verify interactions between components
- **Validation**: End-to-end testing of complete features
- **ADR-specific**: Tests that verify architectural decisions

## Writing Effective Tests

### Test Structure

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

### Best Practices

1. **Follow AAA Pattern**: Arrange, Act, Assert
2. **One Assertion Per Test**: Focus on testing one specific behavior
3. **Descriptive Test Names**: Clearly describe what the test verifies
4. **Proper Setup/Teardown**: Ensure test isolation with proper cleanup
5. **Meaningful Tags**: Use tags to categorize tests appropriately
6. **Proper Error Messages**: Include helpful failure messages

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