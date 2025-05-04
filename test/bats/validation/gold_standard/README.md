# Gold Standard Validation Suite

This component implements validation tests that verify MVNimble's recommendations against expert-derived optimal configurations for various test scenarios.

## Overview

The Gold Standard Validation Suite serves as a benchmark to ensure that MVNimble's recommendations meet or exceed the quality of configurations determined by testing experts. It creates a comprehensive set of test scenarios with known bottlenecks and expert-defined optimal configurations, runs MVNimble against these scenarios, and compares the recommendations to measure accuracy.

## Components

- **gold_standard_validation.sh**: Main implementation of the gold standard validation framework
- **gold_standard_test.bats**: BATS tests for the gold standard validation components
- **scenarios/**: Directory containing all gold standard test scenarios
- **reports/**: Directory containing validation reports and results

## Test Scenario Categories

The validation suite includes scenarios in the following categories:

1. **CPU-bound**: Tests with varying levels of CPU constraints
2. **Memory-bound**: Tests with varying levels of memory usage
3. **IO-bound**: Tests with varying levels of file IO operations
4. **Network-bound**: Tests with varying levels of network operations
5. **Thread Safety**: Tests with thread safety issues at different severity levels
6. **Multivariate**: Tests with combinations of different constraint types

For each category, we have scenarios at different constraint levels (low, medium, high).

## Expert Recommendations

Each test scenario includes expert-derived recommendations that represent optimal configurations determined by testing experts. These serve as the "gold standard" against which MVNimble's recommendations are compared.

## Validation Process

1. **Setup**: Creates a standard set of test scenarios across all categories
2. **Execution**: Runs MVNimble against each scenario to generate recommendations
3. **Comparison**: Compares MVNimble's recommendations with expert recommendations
4. **Reporting**: Generates detailed reports showing match scores and validations

## Running the Validation Suite

```bash
# Run the full validation suite
./gold_standard_validation.sh

# Run the BATS tests for validation components
bats gold_standard_test.bats
```

## Validation Metrics

- **Comparison Score**: A value between 0.0 and 1.0 indicating how closely MVNimble's recommendations match expert recommendations
- **Validation Threshold**: The minimum score required to pass validation (default: 0.85 or 85% match)
- **Passing Percentage**: The percentage of scenarios where MVNimble's recommendations meet or exceed the validation threshold

## Integration with MVNimble

This validation suite is part of MVNimble's comprehensive testing framework as outlined in ADR-008. It provides objective metrics to measure the quality of MVNimble's diagnostic capabilities and improvement recommendations.

## Reports

The validation process generates the following reports:

- **Individual Scenario Reports**: Detailed reports for each test scenario
- **Summary Report**: A comprehensive overview of validation results across all categories
- **Improvement Recommendations**: Suggestions for improving MVNimble's recommendations based on validation results

---
Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
