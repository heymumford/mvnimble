# MVNimble Test Taxonomy

This document defines the test taxonomy used across the MVNimble test suite. 
Each test should be categorized using these standardized tags to enable precise test selection and reporting.

## Primary Test Categories

Each test must be tagged with exactly one tag from each of these two primary categories:

### By Purpose

- **@functional**: Tests that verify specific functionality works as expected
- **@nonfunctional**: Tests that verify quality attributes (performance, usability, compatibility)

### By Scenario

- **@positive**: Tests that verify correct behavior with valid inputs
- **@negative**: Tests that verify error handling with invalid inputs

## Secondary Test Categories

Tests should also be tagged with exactly one tag from each of these secondary categories, as applicable:

### By Component

- **@core**: Tests for core functionality 
- **@reporting**: Tests for report generation
- **@dependency**: Tests for dependency management
- **@package-manager**: Tests for Maven and package management functionality
- **@platform**: Tests for platform-specific functionality
- **@env-detection**: Tests for environment detection

### By ADR

- **@adr000**: Tests for ADR 000 - ADR Process for QA Empowerment
- **@adr001**: Tests for ADR 001 - Shell Script Architecture
- **@adr002**: Tests for ADR 002 - Bash Compatibility
- **@adr003**: Tests for ADR 003 - Dependency Management
- **@adr004**: Tests for ADR 004 - Cross-Platform Compatibility
- **@adr005**: Tests for ADR 005 - Magic Numbers Elimination

## Test Performance Categories

For performance-related tests only:

- **@fast**: Tests that should complete in < 100ms
- **@medium**: Tests that may take 100ms - 1s
- **@slow**: Tests that may take > 1s

## Environment-Specific Tags

For environment-specific tests:

- **@macos**: Tests that only run on macOS
- **@linux**: Tests that only run on Linux
- **@container**: Tests that verify container-specific behavior

## Examples

```bash
# @functional @positive @core @adr001 @fast
@test "Core modules exist and are loadable" {
  # Test implementation
}

# @nonfunctional @negative @platform @adr004 @slow
@test "Handle unsupported platforms gracefully" {
  # Test implementation
}
```

## Test Naming Conventions

Test names should follow these patterns to ensure clarity:

1. **Functional Positive Tests**: "Should {expected behavior} when {condition}"
   - Example: "Should load all modules when script is executed"

2. **Functional Negative Tests**: "Should fail with {expected error} when {invalid condition}"
   - Example: "Should fail with clear error when required dependency is missing"

3. **Nonfunctional Tests**: "Should {quality attribute} {expectation}"
   - Example: "Should complete dependency check within 500ms"

## Directory Structure

```
test/
├── bats/
│   ├── common/           # Common test helper functions
│   ├── fixtures/         # Test fixtures and mock data
│   ├── functional/       # Functional tests by ADR
│   │   ├── adr000_*.bats
│   │   ├── adr001_*.bats
│   │   └── ...
│   ├── nonfunctional/    # Nonfunctional tests
│   │   ├── performance/
│   │   ├── compatibility/
│   │   └── ...
│   ├── platform/         # Platform-specific tests
│   ├── test_constants.sh # Non-readonly constants
│   ├── test_helper.bash  # Main test helper
│   └── test_tags.bash    # Tag filtering
├── run_bats_tests.sh     # Advanced test runner
└── test_summary.sh       # Simplified test runner
```

## Running Tests By Category

The test runner allows filtering by these tags:

```bash
# Run all functional tests
./test/run_bats_tests.sh --tags functional

# Run positive ADR-001 tests
./test/run_bats_tests.sh --tags positive,adr001

# Exclude slow tests
./test/run_bats_tests.sh --exclude-tags slow

# Run only platform tests for macOS
./test/run_bats_tests.sh --tags platform,macos
```
EOF < /dev/null

---
Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
