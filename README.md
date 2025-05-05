# MVNimble

MVNimble is a lightweight tool that helps QA engineers identify and diagnose flaky tests and build failures in Maven projects. It monitors test execution, collects diagnostic data, and generates reports to make troubleshooting easier.

## Features

- **Test Monitoring**: Tracks test execution and resource usage
- **Flaky Test Detection**: Identifies inconsistently passing tests
- **Build Failure Analysis**: Diagnoses build failures and suggests fixes
- **Resource Correlation**: Links test failures to system resource constraints
- **Reporting**: Generates easy-to-understand reports in multiple formats

## Installation

```bash
# Quick installation
./bin/install/install-simple.sh

# Installation with additional diagnostic tools
./bin/install/install-with-fix.sh
```

## Quick Start

1. Navigate to your Maven project directory
2. Run your tests with MVNimble monitoring:

```bash
mvnimble mvn test
```

3. View the generated report:

```bash
cat mvnimble-results/test_monitoring_report.md
```

## Basic Usage

MVNimble works by running in front of your normal Maven commands:

```bash
# Run tests with monitoring
mvnimble mvn test

# Run a specific test with monitoring
mvnimble mvn -Dtest=SlowTest test

# Run with custom JVM options
mvnimble --jvm-opts="-Xmx2g -XX:+HeapDumpOnOutOfMemoryError" mvn test
```

## Report Types

MVNimble generates reports in multiple formats:

- Markdown (default): `test_monitoring_report.md`
- JSON data: `data.json`
- HTML dashboard: Generate with `mvnimble report --format html`

## More Information

For more detailed information, see:

- [Complete Installation Guide](doc/INSTALLATION.md)
- [Detailed Usage Guide](doc/USAGE.md)
- [Reporting Options](doc/REPORTING.md)
- [Troubleshooting Guide](doc/TROUBLESHOOTING.md)

## Support

If you encounter any issues, please:
1. Check the [Troubleshooting Guide](doc/TROUBLESHOOTING.md)
2. Look through existing GitHub issues
3. Open a new issue with the test output and environment details