# MVNimble Reporting Guide

MVNimble generates several types of reports to help you understand test performance and diagnose issues.

## Available Report Formats

| Format | Command | Purpose |
|--------|---------|---------|
| Markdown | Default | Human-readable summary of test results |
| JSON | `--format json` | Structured data for programmatic analysis |
| HTML | `--format html` | Interactive dashboard with visualizations |
| TAP | `--format tap` | Test Anything Protocol format for CI integration |

## Viewing Reports

After running tests with MVNimble, reports are automatically generated in the `mvnimble-results` directory:

```bash
# View default markdown report
cat mvnimble-results/test_monitoring_report.md

# Generate HTML report from existing data
mvnimble report --format html

# Generate JSON report from existing data
mvnimble report --format json
```

## Understanding Report Sections

### 1. Test Summary

Shows overall test statistics:
- Total tests run
- Pass/fail counts
- Test duration
- System resource overview

### 2. Failing Tests

Lists all failing tests with:
- Test name
- Error message
- Failure type classification
- Resource usage during failure

### 3. Slow Tests

Lists tests that took longer than expected:
- Test name
- Duration
- Comparison to average duration
- Resource usage correlation

### 4. Resource Correlation

Links test behavior to system resources:
- CPU usage during test execution
- Memory consumption patterns
- I/O activity correlation
- Thread contention analysis

### 5. Recommendations

Provides actionable suggestions:
- Potential fixes for failing tests
- Optimization ideas for slow tests
- JVM configuration suggestions
- Test isolation recommendations

## Report Examples

### Example: Identifying Memory-Related Failures

```
## Resource Correlation for UploadTest.testLargeFileUpload

This test failed with OutOfMemoryError during heap allocation.

Resource Analysis:
- Memory: 92% usage (CRITICAL) at time of failure
- Heap allocation rate: 25MB/sec (HIGH)
- GC activity: 15 collections in 30 seconds before failure

Recommendation:
- Increase heap size with --jvm-opts="-Xmx2g"
- Check for memory leaks in FileBufferManager class
```

### Example: Thread Contention Issue

```
## Resource Correlation for ConcurrentTest.testParallelProcessing

This test is flaky, passing 3/5 runs.

Resource Analysis:
- Thread count: Peaks at 42 threads
- Thread contention: HIGH on DatabaseConnectionPool
- Deadlock detected between threads T24 and T36

Recommendation:
- Review thread synchronization in DatabaseConnectionPool
- Consider increasing connection pool size
- Add timeout to prevent deadlock condition
```

## Using Reports for QA Work

1. **When filing bugs**:
   - Attach the `data.json` file for complete information
   - Include relevant sections from `test_monitoring_report.md`
   - Highlight specific resource correlations that explain the failure

2. **When investigating flaky tests**:
   - Compare reports from multiple runs
   - Look for resource patterns that differ between passing/failing runs
   - Focus on thread activity and contention sections

3. **For performance optimization**:
   - Use the slow tests section to prioritize optimization work
   - Look at resource usage to identify bottlenecks
   - Try suggested JVM options and compare before/after reports

## Customizing Reports

You can customize report generation:

```bash
# Generate report with only specific sections
mvnimble report --format html --sections summary,failing,recommendations

# Change output location
mvnimble report --format json --output-file ./my-reports/test-results.json

# Include custom metrics in report
mvnimble report --format markdown --include-metrics cpu,memory,threads
```