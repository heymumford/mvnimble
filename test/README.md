# MVNimble Testing

This directory contains the comprehensive test suite for MVNimble. The tests are organized into different categories to provide thorough validation of all MVNimble functionality.

## Test Structure

```
test/
├── bats/                    # BATS automated tests
│   ├── common/              # Common test helpers and utilities
│   ├── functional/          # Functional tests using BATS
│   ├── integration/         # Integration tests using BATS  
│   ├── unit/                # Unit tests using BATS
│   └── validation/          # Validation tests for specific features
├── functional/              # Functional tests using shell scripts
│   ├── fixtures/            # Test fixtures for functional tests
│   └── test_reporting.sh    # Test for report generation
├── integration/             # Integration tests using shell scripts
│   ├── fixtures/            # Test fixtures for integration tests
│   └── test_monitoring_reporting_workflow.sh  # End-to-end workflow test
├── README.md                # This file
├── run_bats_tests.sh        # Script to run BATS tests
├── test_helper.bash         # Helper functions for tests
├── test_results/            # Directory for test results
└── test_summary.sh          # Script to generate test summary
```

## Test Categories

### Unit Tests

Unit tests focus on testing individual functions and modules in isolation. They verify that each component of MVNimble works correctly on its own.

### Functional Tests

Functional tests verify that specific features of MVNimble work as expected. These tests focus on the behavior of individual features like monitoring, analysis, and reporting.

### Integration Tests

Integration tests verify that different components of MVNimble work correctly together. These tests simulate real-world usage patterns and ensure that the entire workflow functions properly.

### Validation Tests

Validation tests verify that MVNimble meets specific requirements and performs correctly in various scenarios. These tests focus on validating the tool's behavior under different conditions.

## Running Tests

### Running All Tests

To run all tests, use the `run_bats_tests.sh` script:

```bash
./test/run_bats_tests.sh
```

### Running Specific Tests

To run specific tests, use the `--test-dir` option:

```bash
# Run a specific BATS test file
./test/run_bats_tests.sh --test-dir ./test/bats/functional/adr001_shell_architecture.bats

# Run a specific shell script test
./test/functional/test_reporting.sh
```

### Filtering Tests by Tag

Tests can be filtered by tags using the `--tags` option:

```bash
./test/run_bats_tests.sh --tags functional,positive
```

### Generating Test Reports

To generate a test report, use the `--report` option:

```bash
./test/run_bats_tests.sh --report markdown
```

## Test Fixtures

Test fixtures are used to provide consistent input data for tests. These fixtures include:

- Sample Maven projects
- Monitoring data samples
- Expected output files

## Test Results

Test results are stored in the `test_results` directory. These include:

- Individual test results in `.result` files
- Test reports in various formats (markdown, JSON, TAP)
- Test summaries

## Adding New Tests

When adding new tests, follow these guidelines:

1. Place the test in the appropriate category directory
2. Use consistent naming conventions (test_*.sh for shell scripts, *.bats for BATS tests)
3. Add fixtures to the appropriate fixtures directory
4. Document the test purpose and usage
5. Ensure the test is executable
6. Update the test documentation if needed

---

Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license