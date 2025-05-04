# MVNimble Reporting

This document provides a comprehensive guide to MVNimble's reporting capabilities. It covers how to generate and use the different report formats, describes the available commands, and includes examples.

## Quick Start

```bash
# Generate an HTML report from monitoring data
mvnimble report -i ./results/data.json -o ./report.html -f html

# Generate a Markdown report from monitoring data
mvnimble report -i ./results/data.json -o ./report.md -f markdown

# Generate a JSON report from monitoring data
mvnimble report -i ./results/data.json -o ./report.json -f json

# Use the specialized report script
mvnimble-report -i ./results/data.json -o ./report.html -f html
```

## Report Commands

MVNimble provides two ways to generate reports:

1. **Main Command**: `mvnimble report`
2. **Specialized Script**: `mvnimble-report`

### Main Report Command

```bash
mvnimble report [options]
```

Options:
- `-i, --input FILE` - Input JSON file with monitoring data
- `-o, --output FILE` - Output file for the report
- `-f, --format FMT` - Output format: markdown, html, json (default: markdown)

### Specialized Report Script

```bash
mvnimble-report [options]
```

Options:
- `-i, --input FILE` - Input JSON file with monitoring data
- `-o, --output FILE` - Output file for the report
- `-f, --format FMT` - Output format: markdown, html, json (default: markdown)

## Report Formats

MVNimble supports three report formats:

### HTML Reports

HTML reports provide interactive, visual representations of your build data. They include:

- Build summary information
- Test results and statistics
- System information
- Visual styling and formatting
- Color-coded status indicators

HTML reports are ideal for sharing with team members or including in documentation.

### Markdown Reports

Markdown reports provide a clean, text-based representation of your build data. They include:

- Build summary information
- Test results and statistics
- System information
- Properly formatted Markdown
- GitHub-compatible syntax

Markdown reports are ideal for including in GitHub READMEs, wikis, or other documentation.

### JSON Reports

JSON reports provide a machine-readable representation of your build data. They include:

- Raw build data in JSON format
- Complete system information
- Test result statistics
- Properly formatted JSON

JSON reports are ideal for programmatic access or integration with other tools.

## Report Content

Reports contain the following information:

1. **Build Summary**
   - Build status (success/failure)
   - Build duration
   - Maven command used

2. **Test Results**
   - Total tests executed
   - Passed tests
   - Failed tests
   - Skipped tests

3. **System Information**
   - Operating system
   - CPU information
   - Memory information
   - MVNimble version

4. **Detailed Information**
   - Failed test details (if any)
   - Performance metrics
   - Resource utilization

## Workflow Example

Here's a complete workflow example showing how to monitor a build and generate reports:

```bash
# Step 1: Monitor a Maven build
mvnimble monitor -o ./results -- mvn clean test

# Step 2: Analyze the build data
mvnimble analyze -i ./results -o ./analysis.md

# Step 3: Generate reports in different formats
mvnimble report -i ./results/data.json -o ./report.html -f html
mvnimble report -i ./results/data.json -o ./report.md -f markdown
mvnimble report -i ./results/data.json -o ./report.json -f json
```

## Testing Reporting Functionality

To test the reporting functionality, you can use the provided test scripts:

```bash
# Run the functional test for reporting
./test/functional/test_reporting.sh

# Run the integration test for the complete workflow
./test/integration/test_monitoring_reporting_workflow.sh
```

These tests verify that all report formats are generated correctly and contain the expected information.

## Troubleshooting

If you encounter issues with report generation:

1. **No Data Found**: Ensure the input JSON file exists and contains valid data
2. **Empty Reports**: Check that the monitoring data includes the required information
3. **Permission Issues**: Ensure you have write permissions for the output directory
4. **Format Errors**: Verify that you're using a supported format (html, markdown, json)

## Further Information

For more detailed information on reporting, see:

- [Reporting Guide](./doc/REPORTING.md) - Comprehensive documentation on MVNimble reporting
- [Usage Guide](./doc/USAGE.md) - General usage information for MVNimble
- [Test README](./test/README.md) - Information on testing MVNimble functionality

---

Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license