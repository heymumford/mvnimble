# MVNimble Simplified Test Structure

This directory contains a simplified test structure for MVNimble, designed to make it more maintainable and accessible to QA engineers.

## Directory Structure

```
simplified/
├── common/             # Common test utilities and helpers
│   ├── helpers.bash    # Common helper functions
│   └── fixtures/       # Test fixtures
│
├── core/               # Tests for core functionality
│   ├── common_test.bats    # Tests for common utilities
│   ├── constants_test.bats # Tests for constants
│   └── environment_test.bats # Tests for environment detection
│
├── monitor/            # Tests for monitoring functionality
│   └── monitor_test.bats  # Tests for Maven build monitoring
│
├── analyze/            # Tests for build analysis functionality
│   └── analyze_test.bats  # Tests for build analysis
│
└── report/             # Tests for reporting functionality
    └── report_test.bats   # Tests for report generation
```

## Test Categories

Tests are organized by module rather than by type (unit/functional/integration), making it easier to find related tests.

## Running Tests

To run all tests:

```bash
./test/run_tests.sh
```

To run tests for a specific module:

```bash
./test/run_tests.sh --dir simplified/core
```

## Adding New Tests

1. Create a new .bats file in the appropriate module directory
2. Add test cases using the BATS syntax
3. Use the common helpers for setup and teardown

## Testing Conventions

- Each test file should focus on a single module or functionality
- Keep test cases small and focused on a single aspect
- Use descriptive test names that explain what is being tested
- Leverage the common helper functions for setup and teardown