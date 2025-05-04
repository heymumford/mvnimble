# MVNimble Reporting Guide

MVNimble provides comprehensive reporting capabilities that help you understand your test execution, diagnose performance bottlenecks, and optimize your Maven builds. This guide explains how to use the reporting features effectively.

## Report Types

MVNimble supports the following report formats:

- **Markdown** - Text-based reports suitable for documentation or GitHub
- **HTML** - Interactive visual reports with charts and formatting
- **JSON** - Machine-readable data for integration with other tools

## Basic Usage

### Generating Reports

After running a monitored Maven build, you can generate a report using the collected data:

```bash
# Generate a markdown report (default)
mvnimble report -i ./mvnimble-results/data.json -o ./report.md -f markdown

# Generate an HTML report
mvnimble report -i ./mvnimble-results/data.json -o ./report.html -f html

# Generate a JSON report
mvnimble report -i ./mvnimble-results/data.json -o ./report.json -f json
```

### Report Command Options

```
Usage: mvnimble report [options]

Generate reports from collected monitoring data

Options:
  -i, --input FILE    Input JSON file with monitoring data
  -o, --output FILE   Output file for the report
  -f, --format FMT    Output format: markdown, html, json (default: markdown)

Example:
  mvnimble report -i ./results/data.json -o ./report.html -f html
```

## Report Content

### Build Monitoring Reports

Build monitoring reports include:

- **Build Summary** - Status, duration, and command information
- **Test Results** - Total, passed, failed, and skipped tests
- **Failure Details** - Information about build or test failures
- **System Information** - OS, CPU, memory, and environment details

### Analysis Reports

Analysis reports include:

- **Resource Binding Analysis** - CPU, memory, and I/O bottleneck detection
- **Optimization Recommendations** - Environment-specific configuration suggestions
- **Performance Metrics** - Execution time and resource utilization
- **Visualizations** - Charts showing performance data (HTML reports only)

## Examples

### Workflow Example

This example shows a complete workflow from monitoring to reporting:

```bash
# Step 1: Monitor a Maven build
mvnimble monitor -o ./results -- mvn clean test

# Step 2: Analyze the build results
mvnimble analyze -i ./results -o ./analysis.md

# Step 3: Generate a detailed HTML report
mvnimble report -i ./results/data.json -o ./report.html -f html
```

### Sharing Reports

Reports can be easily shared with your team:

```bash
# Generate an HTML report for sharing
mvnimble report -i ./mvnimble-results/data.json -o ./public/report.html -f html

# Include reports in CI/CD pipelines
mvnimble report -i ./mvnimble-results/data.json -o ./artifacts/report.json -f json
```

## Integration with Other Tools

The JSON reports can be integrated with other tools in your development workflow:

- **CI/CD Pipelines** - Archive reports as build artifacts
- **Dashboards** - Extract metrics for visualization
- **Trend Analysis** - Track performance changes over time
- **Custom Tools** - Process the JSON data for specific needs

## Report Customization

MVNimble includes some basic styling and templates for reports. For more advanced customization, you can:

1. Use the JSON output format and build your own visualization
2. Modify the report templates in the project's source code

## Troubleshooting

If you encounter issues with report generation:

1. Verify the input data exists and is valid JSON
2. Check write permissions for the output directory
3. For HTML reports, ensure the report is being viewed in a modern browser

For more help, see the [Troubleshooting Guide](./TROUBLESHOOTING.md).

---

Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license