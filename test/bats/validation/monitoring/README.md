# Real-Time Test Monitoring Validation

This directory contains validation tests for MVNimble's real-time test monitoring capabilities.
The tests verify that the "Test Engineering Tricorder" functionality works as expected
by monitoring actual Maven test runs and analyzing their behavior.

## Validation Scenarios

1. **Basic Monitoring** - Verifies that basic monitoring capabilities work
2. **Resource Correlation** - Tests the ability to correlate resource usage with specific tests
3. **Flakiness Detection** - Validates flakiness pattern detection capabilities
4. **Cross-platform Compatibility** - Ensures monitoring works on different platforms

## Running Tests

To run all monitoring validation tests:

```bash
./monitoring_validation.sh
```

To run a specific test scenario:

```bash
./monitoring_validation.sh [scenario_name]
```

## Validation Metrics

- **Completeness**: Does monitoring capture all relevant metrics?
- **Accuracy**: Are the metrics accurate and reliable?
- **Insights Quality**: How valuable are the generated insights?
- **Performance Impact**: Does monitoring significantly impact test performance?

## Dependencies

- Java 8+ 
- Maven 3.6.0+
- `jstat` tool available (for JVM metrics)

---
Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
