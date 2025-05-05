# MVNimble Usage Guide

This guide explains how to use MVNimble to monitor and analyze your Maven tests.

## Basic Commands

MVNimble works as a wrapper around your Maven commands:

```bash
mvnimble mvn [your-regular-maven-commands]
```

For example:

```bash
# Run all tests with monitoring
mvnimble mvn test

# Run a specific test
mvnimble mvn -Dtest=MySpecificTest test

# Run with a specific profile
mvnimble mvn -P integration-tests test
```

## Command Options

MVNimble provides several options for monitoring:

| Option | Description | Example |
|--------|-------------|---------|
| `--jvm-opts` | Set custom JVM options | `mvnimble --jvm-opts="-Xmx2g" mvn test` |
| `--monitor-only` | Only collect metrics, don't analyze | `mvnimble --monitor-only mvn test` |
| `--detect-flaky` | Run tests multiple times to find flaky tests | `mvnimble --detect-flaky=5 mvn test` |
| `--timeout` | Set maximum test execution time | `mvnimble --timeout=10m mvn test` |
| `--output-dir` | Change the output directory | `mvnimble --output-dir=./my-results mvn test` |

## Analyzing Test Results

After running tests, MVNimble automatically generates a report in the `mvnimble-results` directory:

```bash
# View the default Markdown report
cat mvnimble-results/test_monitoring_report.md

# Generate HTML report
mvnimble report --format html
```

## Finding Flaky Tests

To identify flaky tests, run tests multiple times:

```bash
# Run tests 5 times to find flaky behavior
mvnimble --detect-flaky=5 mvn test
```

MVNimble will identify tests that pass in some runs but fail in others.

## Understanding Resource Correlation

MVNimble automatically correlates resource usage with test failures:

1. **CPU Spikes**: Identifies when high CPU usage coincides with test failures
2. **Memory Issues**: Detects memory-related failures
3. **I/O Bottlenecks**: Shows when disk or network I/O might be causing problems

View this information in the `resource_correlation.md` file:

```bash
cat mvnimble-results/resource_correlation.md
```

## Diagnosing Build Failures

When a build fails, MVNimble helps diagnose the problem:

```bash
# Run build and diagnose any failures
mvnimble mvn compile
```

If the build fails, check the generated analysis:

```bash
cat mvnimble-results/build_failure_analysis.md
```

## Tips for QA Engineers

1. **Always check resource correlation** when tests fail inconsistently
2. **Run with --detect-flaky=3** as a first step when investigating flaky tests
3. **Use --jvm-opts** to test with different memory settings
4. **Compare reports** from different runs to spot patterns
5. **Include MVNimble reports** when reporting issues to developers

## Common Workflows

### Finding Memory-Related Issues

```bash
# First with default settings
mvnimble mvn test

# Then with more memory
mvnimble --jvm-opts="-Xmx2g" mvn test

# Compare the results
diff mvnimble-results/resource_correlation.md previous-run/resource_correlation.md
```

### CI Integration

Add MVNimble to your CI pipeline:

```bash
# In your CI script
./install-simple.sh
mvnimble mvn test
mvnimble report --format html

# Archive the results
cp -r mvnimble-results $ARTIFACT_DIR
```