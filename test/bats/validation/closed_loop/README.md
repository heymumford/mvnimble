# Closed-Loop Validation Suite

This component implements validation tests that verify MVNimble's recommendations lead to actual improvements in test performance and stability.

## Overview

The Closed-Loop Validation Suite creates test projects with known bottlenecks, runs MVNimble to generate recommendations, applies those recommendations, and measures the actual improvement. It then compares the actual improvement against MVNimble's predicted improvement to validate the accuracy of the recommendations.

## Components

- **closed_loop_validation.sh**: Main implementation of the closed-loop validation framework
- **closed_loop_test.bats**: BATS tests for the closed-loop validation components
- **scenarios/**: Directory containing test scenarios with different bottlenecks
- **reports/**: Directory containing validation reports and results

## Test Scenario Categories

The validation suite tests MVNimble's handling of the following bottleneck types:

1. **CPU Bottlenecks**: Tests with varying levels of CPU consumption
2. **Memory Bottlenecks**: Tests with varying levels of memory usage
3. **I/O Bottlenecks**: Tests with varying levels of disk and network I/O
4. **Thread Contention**: Tests with varying levels of thread contention
5. **Multivariate**: Tests with combinations of different bottleneck types

For each category, we have scenarios at different severity levels (low, medium, high).

## Validation Process

1. **Create Test Projects**: Create Maven test projects with specific bottlenecks
2. **Baseline Measurement**: Measure test performance without any optimizations
3. **MVNimble Analysis**: Run MVNimble to generate recommendations
4. **Apply Recommendations**: Apply MVNimble's recommended changes
5. **Measure Improvement**: Measure the actual improvement in test performance
6. **Compare Results**: Compare actual improvement with MVNimble's predictions
7. **Reporting**: Generate detailed reports on recommendation accuracy

## Integration with MVNimble

This validation suite is part of MVNimble's comprehensive testing framework as outlined in ADR-008. It provides objective metrics to measure the effectiveness of MVNimble's recommendations in real-world scenarios.

---
Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
