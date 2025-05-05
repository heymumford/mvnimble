# MVNimble Guide for QA Engineers

This guide explains how to use MVNimble to improve your QA workflows for Maven-based Java projects.

## Why Use MVNimble?

As a QA engineer, MVNimble helps you:

1. **Find flaky tests** that sometimes pass and sometimes fail
2. **Understand test failures** by linking them to system resource issues
3. **Diagnose build failures** with clear, actionable recommendations
4. **Generate helpful reports** to share with developers
5. **Save time** with automated test analysis

## Getting Started

### Installation

```bash
# Simple installation
./install-simple.sh

# Or with additional diagnostic tools
./install-with-fix.sh
```

### First Test Run

Navigate to your Maven project and run:

```bash
# Basic test monitoring
mvnimble mvn test

# View generated report
cat mvnimble-results/test_monitoring_report.md
```

## Common QA Tasks

### Finding Flaky Tests

Run tests multiple times to identify inconsistent behavior:

```bash
# Run tests 5 times and identify flaky ones
mvnimble --detect-flaky=5 mvn test
```

MVNimble will identify which tests pass sometimes and fail other times.

### Analyzing Slow Tests

Find and understand why certain tests are running slowly:

```bash
# Run tests with performance analysis
mvnimble --analyze-slow mvn test

# View results
cat mvnimble-results/test_monitoring_report.md
```

The report will highlight slow tests and their resource usage.

### Understanding Test Resource Usage

See how tests use CPU, memory, and I/O resources:

```bash
# Run with detailed resource monitoring
mvnimble --detailed-resources mvn test

# Check resource correlation
cat mvnimble-results/resource_correlation.md
```

### Investigating Build Failures

When builds fail, get a clear diagnosis:

```bash
# Run build with analysis
mvnimble mvn compile
```

If the build fails, MVNimble will generate a `build_failure_analysis.md` file with details.

## Creating Useful Reports for Developers

### Generate HTML Reports

For developer-friendly reports:

```bash
# After running tests
mvnimble report --format html
```

Open `mvnimble-results/report.html` in a browser.

### Focus on Specific Problems

Create targeted reports:

```bash
# Focus on memory issues
mvnimble report --focus memory

# Focus on specific tests
mvnimble report --focus-test SlowTest,FailingTest
```

### Including Test History

Compare current results with previous runs:

```bash
# Generate report with history
mvnimble report --with-history
```

## Best Practices for QA Teams

### Daily Test Monitoring

Add MVNimble to your daily testing:

```bash
# Morning test run with full analysis
mvnimble mvn test

# Save the results with date stamp
cp -r mvnimble-results "test-results-$(date +%Y-%m-%d)"
```

### Documenting Test Issues

When you file a bug about test failures:

1. Run the test with MVNimble: `mvnimble mvn -Dtest=ProblemTest test`
2. Attach the `resource_correlation.md` file to your bug report
3. Include the exact MVNimble command you used
4. Note any patterns you've observed across multiple runs

### CI Integration

Add MVNimble to your CI pipeline:

```bash
# In your CI script
./install-simple.sh
mvnimble mvn test
mvnimble report --format html --format json
```

Then archive the `mvnimble-results` directory as a CI artifact.

## Interpreting MVNimble Results

### Understanding Failure Categories

MVNimble classifies test failures into categories:

1. **Resource-related**: Memory, CPU, or I/O problems
2. **Timing-related**: Race conditions or timeout issues
3. **Configuration-related**: Environment or setup problems
4. **Code-related**: Actual bugs in the application code

### Resource Correlation Indicators

Key indicators in resource reports:

- **HIGH CPU**: Test is computationally expensive
- **MEMORY GROWTH**: Potential memory leak
- **I/O WAIT SPIKES**: Disk or network bottlenecks
- **THREAD CONTENTION**: Concurrency issues

### Action Items from Reports

For each test issue, MVNimble suggests next steps:

1. For **flaky tests**: Increase runs, isolate the test, check for resource constraints
2. For **slow tests**: Profile resource usage, check for blocking operations
3. For **build failures**: Check dependencies, verify environment configuration

## Advanced Features

### Custom Test Monitoring

Monitor specific aspects of tests:

```bash
# Focus on memory usage
mvnimble --monitor-memory mvn test

# Focus on thread behavior
mvnimble --monitor-threads mvn test
```

### Integration with Other Tools

Combine MVNimble with other testing tools:

```bash
# Use with JaCoCo for coverage
mvnimble mvn jacoco:prepare-agent test jacoco:report

# Use with Surefire reports
mvnimble --surefire-integration mvn test
```

### Automating Routine Analysis

Create simple scripts for common tasks:

```bash
# Example: daily-test.sh
#!/bin/bash
mvnimble --detect-flaky=3 mvn test
mvnimble report --format html --format markdown
echo "Tests completed - see mvnimble-results for details"
```