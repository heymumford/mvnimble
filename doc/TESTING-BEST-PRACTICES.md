# MVNimble Testing Best Practices

This document outlines best practices for testing MVNimble and Bash scripts in general. Following these guidelines will help ensure your tests are robust, maintainable, and effective.

## Table of Contents

1. [General Testing Principles](#general-testing-principles)
2. [Bash Testing Specifics](#bash-testing-specifics)
3. [Test Organization](#test-organization)
4. [Effective Test Writing](#effective-test-writing)
5. [Environment Considerations](#environment-considerations)
6. [Performance Testing](#performance-testing)
7. [Continuous Integration](#continuous-integration)
8. [Mocking Strategies](#mocking-strategies)
9. [Common Pitfalls](#common-pitfalls)

## General Testing Principles

### 1. Test Early, Test Often

- Write tests as you develop, not after
- Use the test-driven development (TDD) approach when possible:
  1. Write a failing test
  2. Write code to make the test pass
  3. Refactor while keeping tests passing

### 2. Test for Correctness

- Focus on functionality first
- Ensure scripts handle the expected range of inputs
- Verify that outputs match expectations
- Test both success and failure paths

### 3. Isolate Tests

- Each test should focus on a single functionality
- Tests should not depend on other tests
- Use setup and teardown to create clean environments

### 4. Make Tests Readable

- Choose clear, descriptive test names
- Follow a consistent naming pattern
- Comment complex test setups or assertions

### 5. Keep Tests Fast

- Tests should execute quickly
- Avoid unnecessary file operations or network calls
- Use mocks for external dependencies

## Bash Testing Specifics

### 1. Test Shell Functions Individually

```bash
# Good: Testing a single function
@test "parseVersion should extract major version" {
  run parseVersion "v1.2.3"
  [ "$status" -eq 0 ]
  [[ "$output" == "1" ]]
}
```

### 2. Test Exit Codes

```bash
# Testing success exit code
@test "validInput should return success" {
  run validateInput "valid-input"
  [ "$status" -eq 0 ]
}

# Testing failure exit code
@test "invalidInput should return error" {
  run validateInput ""
  [ "$status" -eq 1 ]
}
```

### 3. Test Output Carefully

```bash
# Exact match for simple output
@test "getVersion should return exact version" {
  run getVersion
  [ "$output" = "1.2.3" ]
}

# Pattern match for complex output
@test "getStatus should include key information" {
  run getStatus
  [[ "$output" == *"CPU usage:"* ]]
  [[ "$output" == *"Memory available:"* ]]
}
```

### 4. Handle Quoting Correctly

```bash
# Use single quotes for regex patterns
@test "output should match pattern" {
  run getLogData
  [[ "$output" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2} ]]
}

# Use double quotes for variable expansion
@test "should handle spaces in paths" {
  local test_path="$TEST_DIR/path with spaces"
  mkdir -p "$test_path"
  run processPath "$test_path"
  [ "$status" -eq 0 ]
}
```

## Test Organization

### 1. Follow MVNimble's Test Taxonomy

Organize tests by their purpose and scenario:

```bash
# @functional @positive
@test "parseConfig should correctly read valid config" {
  # Test with valid config
}

# @functional @negative
@test "parseConfig should handle invalid config" {
  # Test with invalid config
}

# @nonfunctional @performance
@test "parseConfig should complete in under 50ms" {
  # Test performance
}
```

### 2. Group Related Tests in Files

- Group tests for a single module or functionality
- Name files descriptively (e.g., `config_parser.bats`, `version_utils.bats`)
- Use directories to categorize test types:
  - `functional/`: Core functionality tests
  - `nonfunctional/`: Performance, compatibility tests
  - `integration/`: Tests that span multiple components

### 3. Use Appropriate Tags

Tags help filter and categorize tests:

```bash
# Core functionality tags
@test "@core @functional validate input" { ... }

# Component-specific tags
@test "@platform @macos detect macOS version" { ... }

# ADR-related tags
@test "@adr002 @bash-compatibility ensure POSIX compliance" { ... }
```

## Effective Test Writing

### 1. Use Setup and Teardown

```bash
# Setup runs before each test
setup() {
  # Create a clean test environment
  TEST_DIR="$(mktemp -d)"
  export TEST_CONFIG="$TEST_DIR/config.json"
  
  # Initialize with test data
  echo '{"version":"1.0"}' > "$TEST_CONFIG"
}

# Teardown runs after each test
teardown() {
  # Clean up test artifacts
  rm -rf "$TEST_DIR"
  unset TEST_CONFIG
}
```

### 2. Use Descriptive Test Names

```bash
# Bad: Vague name
@test "config test" { ... }

# Good: Descriptive name
@test "parseConfig should handle UTF-8 characters in JSON" { ... }
```

### 3. Follow the Arrange-Act-Assert Pattern

```bash
@test "processFile should extract metadata" {
  # Arrange: Set up the test data
  echo "Title: Test Document" > "$TEST_DIR/test.txt"
  echo "Author: Jane Doe" >> "$TEST_DIR/test.txt"
  
  # Act: Run the function being tested
  run processFile "$TEST_DIR/test.txt"
  
  # Assert: Verify the results
  [ "$status" -eq 0 ]
  [[ "$output" == *"title=\"Test Document\""* ]]
  [[ "$output" == *"author=\"Jane Doe\""* ]]
}
```

### 4. Test Edge Cases

```bash
# Test empty input
@test "parseArgs should handle empty input" {
  run parseArgs ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"No arguments provided"* ]]
}

# Test boundary conditions
@test "setThreadCount should enforce maximum thread limit" {
  run setThreadCount 9999
  [ "$status" -eq 0 ]
  [[ "$output" == "$MAX_THREADS" ]]
}

# Test special characters
@test "escapeString should handle special characters" {
  run escapeString "file with spaces & special chars"
  [ "$status" -eq 0 ]
  [[ "$output" == "file\ with\ spaces\ \&\ special\ chars" ]]
}
```

## Environment Considerations

### 1. Use Environment Helpers

MVNimble provides helpers to simulate different environments:

```bash
# Test behavior on macOS
@test "should detect macOS correctly" {
  mock_macos_environment
  run detectPlatform
  [ "$status" -eq 0 ]
  [[ "$output" == *"macos"* ]]
}

# Test behavior on Linux
@test "should detect Linux correctly" {
  mock_linux_environment
  run detectPlatform
  [ "$status" -eq 0 ]
  [[ "$output" == *"linux"* ]]
}

# Test behavior in containers
@test "should detect container environment" {
  mock_container_environment
  run detectEnvironment
  [ "$status" -eq 0 ]
  [[ "$output" == *"container"* ]]
}
```

### 2. Handle Environment Variables

```bash
# Save environment state
setup() {
  # Save original environment
  ORIGINAL_PATH="$PATH"
  ORIGINAL_HOME="$HOME"
  
  # Set controlled environment
  export PATH="/test/bin:$PATH"
  export HOME="$TEST_DIR/home"
}

# Restore environment state
teardown() {
  # Restore original environment
  export PATH="$ORIGINAL_PATH"
  export HOME="$ORIGINAL_HOME"
}
```

### 3. Use Portable Commands

```bash
# Bad: Non-portable commands
@test "bad portable command example" {
  # Linux-specific command
  run readlink -f "$TEST_FILE"
}

# Good: Use portable alternatives
@test "good portable command example" {
  # Portable alternative via a helper function
  run getAbsolutePath "$TEST_FILE"
}
```

## Performance Testing

### 1. Test Execution Time

```bash
@test "analyzeProject should complete in under 200ms" {
  # Create test project
  mkdir -p "$TEST_DIR/project/src"
  touch "$TEST_DIR/project/pom.xml"
  
  # Measure execution time
  start_time=$(date +%s.%N)
  run analyzeProject "$TEST_DIR/project"
  end_time=$(date +%s.%N)
  
  # Calculate duration in milliseconds
  duration=$(echo "($end_time - $start_time) * 1000" | bc)
  
  # Assert it completes within threshold
  [ "$status" -eq 0 ]
  [ $(echo "$duration < 200" | bc) -eq 1 ]
}
```

### 2. Test Resource Usage

```bash
@test "processLargeFile should use reasonable memory" {
  # Create large test file
  create_large_test_file "$TEST_DIR/large.txt" 10000
  
  # Run with memory tracking
  run track_memory processLargeFile "$TEST_DIR/large.txt"
  
  # Assert memory usage is below threshold (e.g., 50MB)
  [ "$status" -eq 0 ]
  [ $(echo "$output < 50" | bc) -eq 1 ]
}
```

### 3. Test Scaling Performance

```bash
@test "parallel processing should scale linearly" {
  local single_thread_time
  local multi_thread_time
  
  # Measure single-threaded performance
  run time_execution processData --threads 1
  single_thread_time="$output"
  
  # Measure multi-threaded performance
  run time_execution processData --threads 4
  multi_thread_time="$output"
  
  # Scaling factor should be at least 2x with 4 threads
  scaling_factor=$(echo "$single_thread_time / $multi_thread_time" | bc)
  [ $(echo "$scaling_factor > 2.0" | bc) -eq 1 ]
}
```

## Continuous Integration

### 1. Use CI-Compatible Tests

Ensure tests work in headless environments:

```bash
# Avoid tests that assume user interaction
@test "should process without user input" {
  # Run non-interactively
  run processData --non-interactive
  
  # Check it completed without prompting
  [ "$status" -eq 0 ]
}
```

### 2. Tag Slow Tests

```bash
# @slow tests can be skipped in quick CI runs
@test "@slow exhaustive validation" {
  run validateAll --exhaustive
  [ "$status" -eq 0 ]
}
```

### 3. Configure for CI-Specific Output

```bash
# Run tests with appropriate CI options
./test/run_bats_tests.sh --ci --report junit
```

## Mocking Strategies

### 1. Mock External Commands

```bash
@test "should handle curl failure gracefully" {
  # Mock curl to simulate network failure
  mock_command "curl" 28 "curl: (28) Connection timed out"
  
  # Test error handling
  run downloadData "https://example.com/data.json"
  
  # Verify proper error handling
  [ "$status" -eq 2 ]
  [[ "$output" == *"Network error"* ]]
}
```

### 2. Mock File Operations

```bash
@test "should detect missing configuration" {
  # Ensure config file doesn't exist
  rm -f "$TEST_DIR/config.json"
  
  # Test detection of missing config
  run loadConfig "$TEST_DIR/config.json"
  
  # Verify appropriate error
  [ "$status" -eq 1 ]
  [[ "$output" == *"Configuration file not found"* ]]
}
```

### 3. Simulate Environment Conditions

```bash
@test "should handle low disk space" {
  # Mock df to simulate low disk space
  mock_command "df" 0 "Filesystem 1K-blocks Used Available Use% Mounted on\n/dev/sda1 10000 9900 100 99% /"
  
  # Test low disk space detection
  run checkDiskSpace
  
  # Verify warning is issued
  [ "$status" -eq 0 ]
  [[ "$output" == *"Warning: Low disk space"* ]]
}
```

## Common Pitfalls

### 1. Avoid Test Interdependence

```bash
# Bad: Tests depend on each other
@test "first test creates data" {
  createTestData "$SHARED_FILE"
  [ -f "$SHARED_FILE" ]
}

@test "second test uses data from first test" {
  # This will fail if tests run out of order or in isolation
  [ -f "$SHARED_FILE" ]
  run processData "$SHARED_FILE"
}

# Good: Each test is self-contained
@test "should process data correctly" {
  # Create test data within this test
  local test_file="$TEST_DIR/data.txt"
  createTestData "$test_file"
  
  # Process the data
  run processData "$test_file"
  
  # Verify results
  [ "$status" -eq 0 ]
}
```

### 2. Beware of Cleanup Issues

```bash
# Bad: Manual cleanup
@test "bad cleanup example" {
  TMP_FILE=$(mktemp)
  run processFile "$TMP_FILE"
  
  # Cleanup might be skipped if test fails
  rm -f "$TMP_FILE"
}

# Good: Use teardown for cleanup
setup() {
  TEST_FILES=()
}

teardown() {
  # Clean up all test files
  for file in "${TEST_FILES[@]}"; do
    rm -f "$file"
  done
}

@test "good cleanup example" {
  local tmp_file=$(mktemp)
  TEST_FILES+=("$tmp_file")
  
  run processFile "$tmp_file"
  [ "$status" -eq 0 ]
  
  # No cleanup needed here - teardown handles it
}
```

### 3. Watch for Output Formatting Issues

```bash
# Bad: Brittle output check
@test "brittle output check" {
  run getStatus
  [ "$output" = "Status: OK (100%)" ]  # Spaces, case, or format might change
}

# Good: Robust output check
@test "robust output check" {
  run getStatus
  [ "$status" -eq 0 ]
  [[ "$output" =~ [Ss]tatus:.*OK ]]  # More flexible pattern match
}
```

### 4. Be Careful with Temporary Files

```bash
# Bad: Potential conflicts in temp files
@test "bad temp file example" {
  echo "test data" > /tmp/test-data.txt
  run processFile "/tmp/test-data.txt"
  rm -f /tmp/test-data.txt
}

# Good: Use unique temporary files
@test "good temp file example" {
  local tmp_file=$(mktemp)
  echo "test data" > "$tmp_file"
  run processFile "$tmp_file"
  rm -f "$tmp_file"
}
```

---

By following these best practices, you'll create a more robust, maintainable test suite for MVNimble. Remember that good tests lead to good software, and investing time in proper testing pays off in reduced bugs and improved code quality.

---
Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
