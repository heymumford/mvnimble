# MVNimble QA Guidelines for Beginners

This guide is designed to help novice QA engineers understand how to use MVNimble effectively for test automation and performance optimization.

## Table of Contents

1. [Introduction to Testing with MVNimble](#introduction-to-testing-with-mvnimble)
2. [Understanding Test Types](#understanding-test-types)
3. [Bash Automated Testing Basics](#bash-automated-testing-basics)
4. [Creating Your First Test](#creating-your-first-test)
5. [Running and Analyzing Tests](#running-and-analyzing-tests)
6. [Common Patterns and Best Practices](#common-patterns-and-best-practices)
7. [Troubleshooting Tests](#troubleshooting-tests)
8. [Next Steps for Growth](#next-steps-for-growth)

## Introduction to Testing with MVNimble

### What is Automated Testing?

Automated testing involves creating scripts that automatically verify the functionality of software. MVNimble provides a robust framework for testing bash scripts and Maven projects.

### Why Test Bash Scripts?

Bash scripts are critical components of DevOps pipelines and system automation. Proper testing ensures:

1. **Reliability**: Your scripts work consistently in different environments
2. **Correctness**: Functions and commands produce expected outputs
3. **Error Handling**: Scripts properly handle edge cases and errors
4. **Maintainability**: Changes don't break existing functionality

### MVNimble's Testing Approach

MVNimble uses the Bash Automated Testing System (BATS) with enhancements for:

- Test categorization (functional/non-functional, positive/negative)
- Environment simulation (Linux, macOS, container)
- Advanced reporting with visualizations
- CI/CD integration

## Understanding Test Types

MVNimble's test taxonomy helps organize tests for maximum effectiveness:

### Functional vs. Non-functional Tests

**Functional Tests** verify that specific functions work as expected:
- Input/output validation
- Command execution
- Data processing
- Error handling

```bash
# Example functional test
@test "isValidVersion should accept valid semantic version" {
  run isValidVersion "1.2.3"
  [ "$status" -eq 0 ]
}
```

**Non-functional Tests** check qualities like:
- Performance (execution time)
- Resource usage (memory, CPU)
- Compatibility (across operating systems)
- Security

```bash
# Example non-functional test
@test "analyzeProject should complete in under 500ms" {
  run time_function analyzeProject "test-project"
  [ $(echo "$output < 0.5" | bc) -eq 1 ]
}
```

### Positive vs. Negative Tests

**Positive Tests** verify expected behavior with valid inputs:
```bash
@test "parseConfig should correctly read valid config" {
  run parseConfig "valid-config.json"
  [ "$status" -eq 0 ]
  [ -n "$output" ]
}
```

**Negative Tests** verify proper handling of invalid inputs or error conditions:
```bash
@test "parseConfig should fail gracefully with invalid config" {
  run parseConfig "invalid-config.json"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Invalid config format"* ]]
}
```

## Bash Automated Testing Basics

### BATS Core Concepts

BATS is a testing framework that:
- Uses familiar TAP (Test Anything Protocol) output format
- Provides a simple syntax for writing tests
- Offers fixtures and setup/teardown capabilities
- Supports special functions like `run` and assertions

### Key BATS Commands

```bash
# Run a test
run some_command

# Check exit status of previous command
[ "$status" -eq 0 ]  # Should be successful (status 0)
[ "$status" -eq 1 ]  # Should fail (status 1)

# Check output of previous command
[[ "$output" == "expected output" ]]
[[ "$output" =~ pattern ]]
```

### Setting Up Test Environments

MVNimble provides helper functions for setting up test environments:

```bash
# Load test helper
load test_helper

# Setup before each test
setup() {
  # Create temporary test directory
  TEST_DIR="$(mktemp -d)"
  
  # Initialize test environment
  initialize_test_env "$TEST_DIR"
}

# Teardown after each test
teardown() {
  # Clean up test directory
  rm -rf "$TEST_DIR"
}
```

## Creating Your First Test

Follow these steps to create your first MVNimble test:

### 1. Create a New Test File

Test files should:
- End with `.bats` extension
- Have a descriptive name
- Be placed in the appropriate directory based on type

Example: `test/bats/functional/config_parser.bats`

### 2. Add Required Headers

```bash
#!/usr/bin/env bats
# config_parser.bats - Tests for the config parser module

# Load common test helper
load ../test_helper
```

### 3. Write Your First Test

```bash
# @functional @positive
@test "parseConfig should correctly read valid config" {
  # Create a test config file
  echo '{"version": "1.0", "mode": "standard"}' > "$TEST_DIR/config.json"
  
  # Run the function being tested
  run parseConfig "$TEST_DIR/config.json"
  
  # Verify results
  [ "$status" -eq 0 ]
  [[ "$output" == *"version: 1.0"* ]]
  [[ "$output" == *"mode: standard"* ]]
}
```

### 4. Add More Tests

```bash
# @functional @negative
@test "parseConfig should handle missing file" {
  # Run with non-existent file
  run parseConfig "/path/to/nonexistent/file.json"
  
  # Verify proper error handling
  [ "$status" -eq 1 ]
  [[ "$output" == *"File not found"* ]]
}

# @functional @negative
@test "parseConfig should reject invalid JSON" {
  # Create invalid JSON file
  echo '{not valid json' > "$TEST_DIR/invalid.json"
  
  # Run with invalid file
  run parseConfig "$TEST_DIR/invalid.json"
  
  # Verify proper error handling
  [ "$status" -eq 1 ]
  [[ "$output" == *"Invalid JSON format"* ]]
}
```

## Running and Analyzing Tests

### Running Your Tests

```bash
# Run your specific test file
./test/run_bats_tests.sh --test-dir test/bats/functional/config_parser.bats

# Run all functional tests
./test/run_bats_tests.sh --tags functional

# Run positive tests only
./test/run_bats_tests.sh --tags positive
```

### Understanding Test Reports

MVNimble generates comprehensive reports that help you understand test results:

1. **Summary Section**: Shows overall pass/fail statistics
2. **Test Categories**: Breakdown by test type
3. **Failures Section**: Details on failed tests
4. **Coverage Analysis**: Identifies untested components

### Debugging Failed Tests

When tests fail:

1. Read the error message carefully
2. Check the test's assertions to understand what was expected
3. Use the `--verbose` flag for more detailed output:
   ```bash
   ./test/run_bats_tests.sh --verbose --test-dir path/to/failing/test.bats
   ```
4. Add debug output to your test:
   ```bash
   @test "My failing test" {
     run some_function
     echo "DEBUG: Status = $status"
     echo "DEBUG: Output = $output"
     [ "$status" -eq 0 ]
   }
   ```

## Common Patterns and Best Practices

### Mocking External Commands

MVNimble provides utilities for mocking external commands:

```bash
# Mock a command to return specific output
mock_command "uname" 0 "Darwin"

# Mock a command to fail
mock_command "curl" 22 "curl: (22) HTTP 404 Not Found"

# Test with mocked command
@test "detectPlatform should identify macOS" {
  # Mock the uname command to simulate macOS
  mock_command "uname" 0 "Darwin"
  
  # Run the function
  run detectPlatform
  
  # Verify it detected macOS
  [ "$status" -eq 0 ]
  [[ "$output" == "macos" ]]
}
```

### Testing Environment Variables

```bash
@test "should respect custom Maven home" {
  # Save original state
  local original_maven_home="$MAVEN_HOME"
  
  # Set test environment variable
  export MAVEN_HOME="/custom/maven/path"
  
  # Run test
  run getMavenHome
  
  # Restore original state
  export MAVEN_HOME="$original_maven_home"
  
  # Verify result
  [ "$status" -eq 0 ]
  [[ "$output" == "/custom/maven/path" ]]
}
```

### Testing File Operations

```bash
@test "should create config file if missing" {
  # Ensure test directory exists
  mkdir -p "$TEST_DIR"
  
  # Run initialization function
  run initializeConfig "$TEST_DIR"
  
  # Verify config was created
  [ -f "$TEST_DIR/config.json" ]
  
  # Verify file contents
  [[ "$(cat "$TEST_DIR/config.json")" == *"version"* ]]
}
```

### Using Test Fixtures

MVNimble provides pre-made fixtures for common scenarios:

```bash
@test "should parse Maven output correctly" {
  # Load fixture with sample Maven output
  local maven_output=$(cat "$FIXTURES_DIR/maven/successful_build.log")
  
  # Process the fixture data
  run parseMavenOutput "$maven_output"
  
  # Verify results
  [ "$status" -eq 0 ]
  [[ "$output" == *"Tests run: 42, Failures: 0"* ]]
}
```

## Troubleshooting Tests

### Common BATS Issues

1. **Command not found errors**:
   - Check your PATH
   - Ensure functions are loaded before testing
   - Use `type -f function_name` to verify function exists

2. **Quote-related issues**:
   - Be careful with quoting in assertions
   - Use `[[ ]]` for string comparisons 
   - Use single quotes for regex patterns

3. **Setup/teardown problems**:
   - Ensure cleanup happens in teardown
   - Check that setup properly initializes environment
   - Verify no global state leaks between tests

### MVNimble-Specific Troubleshooting

1. **Path-related Issues**:
   - Always use `$TEST_DIR` for temporary files
   - Avoid hardcoded paths in tests

2. **Environment Detection Issues**:
   - Use environment helpers to mock specific platforms
   - Check `environment_helpers.bash` for available mocks

3. **Test Categorization Issues**:
   - Ensure tags are properly formatted (`@functional`, not `@Functional`)
   - Place tags on the line above the `@test` declaration

## Next Steps for Growth

As you become more comfortable with MVNimble testing, consider these next steps:

1. **Expand Test Coverage**:
   - Review the test taxonomy to identify gaps
   - Add tests for edge cases and error conditions
   - Create performance tests for critical operations

2. **Learn Advanced Features**:
   - Study the test helper functions
   - Create custom assertions for your project
   - Explore CI integration options

3. **Contribute to MVNimble**:
   - Fix bugs in existing tests
   - Improve test documentation
   - Add new test cases for features

4. **Share Your Knowledge**:
   - Document patterns you find useful
   - Create examples for other QA engineers
   - Mentor others on effective testing practices

Remember: Good tests lead to robust software. Take your time, be thorough, and focus on creating tests that will catch real issues.

---
Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
