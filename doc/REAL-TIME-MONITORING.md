# MVNimble Real-Time Test Monitoring

The real-time test monitoring feature in MVNimble serves as a "Test Engineering Tricorder" that provides QA engineers with insights into test behavior as it happens. This document explains how to use this powerful feature and interpret its results.

## Overview

The real-time monitoring feature allows you to:

1. Monitor system resources during test execution
2. Track test progress in real-time
3. Identify test flakiness patterns
4. Correlate resource usage with specific tests
5. Generate comprehensive reports with actionable insights

## Usage

### Basic Monitoring

To start real-time monitoring with default settings:

```bash
mvnimble --monitor
```

This will start monitoring with the default interval (5 seconds) and save results to the default directory (`./results`).

### Advanced Options

For more control over monitoring:

```bash
mvnimble --monitor [INTERVAL] --directory DIR --time DURATION
```

Parameters:
- `[INTERVAL]`: Optional sampling interval in seconds (default: 5)
- `--directory DIR`: Results directory (default: ./results)
- `--time DURATION`: Maximum monitoring duration in minutes (default: 60)

### Flakiness Analysis

To add flakiness pattern detection:

```bash
mvnimble --monitor --flaky-analysis
```

This will run additional post-monitoring analysis to identify flaky tests and correlate them with resource usage.

## Interpreting Results

After monitoring completes, several files will be generated in the results directory:

### Main Report

The `test_monitoring_report.md` file contains:
- Session overview with test counts and durations
- Resource utilization statistics (CPU, memory, I/O)
- Test performance analysis
- Actionable recommendations

### Metrics Files

Raw metrics are stored in the `metrics/` subdirectory:
- `system.csv`: System resource metrics
- `jvm.csv`: JVM-specific metrics (if available)
- `tests.csv`: Individual test execution data

### Analysis Reports

When flakiness analysis is enabled:
- `flakiness_analysis.md`: Detailed analysis of flaky test patterns
- `resource_correlation.md`: Correlation between resource usage and specific tests

## Examples

### Monitoring a Maven Test Run

To monitor a Maven test run for 10 minutes with a 2-second sampling interval:

```bash
cd your-maven-project
mvnimble --monitor 2 --time 10
```

Then run your tests in another terminal:

```bash
mvn test
```

### Finding Flaky Tests

To identify flaky tests and correlate them with resource usage:

```bash
mvnimble --monitor --flaky-analysis
mvn test
```

After the tests complete, check the flakiness_analysis.md file for insights.

## Best Practices

1. **Use appropriate sampling intervals**: 
   - For quick tests, use shorter intervals (1-2 seconds)
   - For long-running tests, use longer intervals (5-10 seconds)

2. **Monitor multiple test runs**:
   - Compare results across multiple runs to identify persistent patterns

3. **Analyze resource correlations**:
   - Look for tests that consistently correlate with resource spikes

4. **Combine with optimization**:
   - After identifying issues, use MVNimble's optimization features to address them

## Compatibility

The real-time monitoring feature works across platforms:
- Linux: Full support for all metrics
- macOS: Support for CPU, memory, and JVM metrics
- Container environments: Optimized resource detection for containerized tests

## Troubleshooting

If monitoring doesn't capture expected data:

1. Ensure you're running from the Maven project root
2. Check that you have appropriate permissions
3. For JVM metrics, ensure the `jstat` tool is available
4. For containerized environments, verify container metrics access

## Advanced Configuration

For advanced configurations, refer to the complete MVNimble documentation.

## Report Examples

### Resource Utilization Graph

```
## Resource Utilization

### CPU Usage
* Average: 45%
* Maximum: 87%

### Memory Usage
* Average: 1024MB
* Maximum: 2048MB
```

### Test Flakiness Patterns

```
## Flaky Test Patterns

* com.example.TestB: Failed 3 times
  * Timing Correlation: 2 failures in close proximity
  * Thread Correlation: All failures on thread-2
```

### Recommendations

```
## Recommendations

* CPU Bottleneck: Tests are CPU-bound. Consider reducing parallelism.
* Thread Safety Issue: TestB shows signs of thread safety problems.
* Memory Pressure: Increase heap size or reduce fork count.
```

## Future Enhancements

The real-time monitoring feature is continually improved. Planned enhancements include:
- Graphical visualization of metrics
- Machine learning-based pattern detection
- Automated remediation suggestions
- Integration with CI/CD systems

---
Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
