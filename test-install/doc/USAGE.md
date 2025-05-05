# MVNimble Usage Guide

This guide explains how to use MVNimble to optimize your Maven builds and test execution.

## Table of Contents

1. [Overview](#overview)
2. [Basic Usage](#basic-usage)
3. [Using the Project Analyzer](#using-the-project-analyzer)
4. [Command Reference](#command-reference)
5. [Advanced Usage](#advanced-usage)
6. [Output Files](#output-files)
7. [Common Use Cases](#common-use-cases)
8. [Tips and Best Practices](#tips-and-best-practices)

## Overview

MVNimble provides three main functions:

1. **Monitoring** - Collects real-time data during Maven builds
2. **Analysis** - Analyzes collected data to identify bottlenecks
3. **Reporting** - Generates readable reports with optimization suggestions

You can use MVNimble in two ways:
- **Simple Mode**: Using the `mvnimble-project` wrapper script that handles all the details for you
- **Standard Mode**: Using the individual `mvnimble` commands directly

## Basic Usage

### Prerequisites

Before using MVNimble, ensure:

1. MVNimble is properly installed
2. The `mvnimble` command is in your PATH
3. You have a Maven project to analyze

### Quick Start

The simplest way to use MVNimble is with the project analyzer:

```bash
# Analyze a Maven project
mvnimble-project /path/to/maven/project
```

This will:
1. Run `mvn test` on the project
2. Monitor and collect data during the build
3. Analyze the data
4. Generate recommendations

### Monitoring a Maven Build

To monitor a Maven build:

```bash
# Navigate to your Maven project
cd /path/to/maven/project

# Monitor a build with default settings
mvnimble monitor -- mvn clean test

# Monitor with custom settings
mvnimble monitor -o ./custom-results -i 5 -m 30 -- mvn clean verify -T 4
```

### Analyzing Build Results

After monitoring, analyze the results:

```bash
# Analyze with default settings
mvnimble analyze -i ./mvnimble-results

# Analyze with custom options
mvnimble analyze -i ./custom-results -o ./analysis.md -f markdown -p ./pom.xml
```

### Generating Reports

Generate reports from the analysis:

```bash
# Generate an HTML report
mvnimble report -i ./mvnimble-results/data.json -o ./report.html -f html

# Generate a markdown report
mvnimble report -i ./mvnimble-results/data.json -o ./report.md -f markdown
```

## Using the Project Analyzer

The `mvnimble-project` script simplifies using MVNimble by combining the most common commands.

### Basic Project Analyzer Usage

```bash
# Run with defaults (equivalent to running 'mvn test' with monitoring)
mvnimble-project /path/to/maven/project

# Run with clean and verify goals
mvnimble-project /path/to/maven/project --clean --verify

# Set custom output directory
mvnimble-project /path/to/maven/project --output=/path/to/output
```

### Project Analyzer Command Options

The project analyzer supports these commands:

```bash
# Just monitor the build (default)
mvnimble-project /path/to/project monitor

# Analyze previous build results
mvnimble-project /path/to/project analyze

# Generate a report from previous results
mvnimble-project /path/to/project report
```

### Project Analyzer Build Options

```bash
# Run 'mvn clean test'
mvnimble-project /path/to/project --clean

# Run with specific Maven goals
mvnimble-project /path/to/project --verify   # Runs 'mvn verify'
mvnimble-project /path/to/project --package  # Runs 'mvn package'
mvnimble-project /path/to/project --install  # Runs 'mvn install'

# Set Maven thread count
mvnimble-project /path/to/project --threads=4  # Runs with '-T 4'
```

## Command Reference

### mvnimble monitor

Monitors a Maven build in real-time.

```bash
mvnimble monitor [options] -- [maven command]
```

Options:
- `-o, --output DIR` - Specify output directory (default: ./mvnimble-results)
- `-i, --interval SEC` - Set data collection interval in seconds (default: 5)
- `-m, --max-time MIN` - Maximum monitoring time in minutes (default: 60)

### mvnimble analyze

Analyzes build results.

```bash
mvnimble analyze [options]
```

Options:
- `-i, --input DIR` - Specify input directory with monitoring data
- `-o, --output FILE` - Specify output file (default: mvnimble-analysis.md)
- `-f, --format FMT` - Output format: markdown, html, json (default: markdown)
- `-p, --pom FILE` - Path to pom.xml file for configuration analysis

### mvnimble report

Generates reports from build data.

```bash
mvnimble report [options]
```

Options:
- `-i, --input FILE` - Input JSON file with monitoring data
- `-o, --output FILE` - Output file for the report
- `-f, --format FMT` - Output format: markdown, html, json (default: markdown)

### mvnimble verify

Verifies your environment and installation.

```bash
mvnimble verify
```

## Advanced Usage

### Custom Maven Configurations

You can pass any Maven options after the `--` separator:

```bash
# With custom Maven options
mvnimble monitor -- mvn clean test -DskipTests=false -Dmaven.test.failure.ignore=true

# With custom profiles
mvnimble monitor -- mvn test -P integration,performance
```

### Running in CI/CD Pipelines

For CI/CD pipelines, use the non-interactive mode and explicit options:

```bash
mvnimble monitor -o ./ci-results -- mvn clean verify
mvnimble analyze -i ./ci-results -o ./ci-analysis.md -f markdown
```

## Output Files

MVNimble generates these files during monitoring:

- `data.json` - Primary data file with all metrics
- `environment.txt` - Environment information
- `maven_output.log` - Maven command output
- `metrics/` - Directory with raw metrics
  - `system.csv` - System resource metrics
  - `jvm.csv` - JVM metrics
  - `tests.csv` - Test execution metrics
- `test_monitoring_report.md` - Basic monitoring report
- `resource_correlation.md` - Resource usage analysis

## Common Use Cases

### Finding Bottlenecks in Test Execution

```bash
# Monitor test execution
mvnimble-project /path/to/project

# Review the analysis results
cat /path/to/project/mvnimble-results/analysis.md
```

### Optimizing Thread Count

```bash
# Try different thread counts
mvnimble-project /path/to/project --threads=1 --output=./results-t1
mvnimble-project /path/to/project --threads=2 --output=./results-t2
mvnimble-project /path/to/project --threads=4 --output=./results-t4

# Compare the results
cat ./results-t*/duration.txt
```

### Identifying Flaky Tests

```bash
# Run tests multiple times
for i in {1..5}; do
  mvnimble-project /path/to/project --output=./run-$i
done

# Analyze the results
mvnimble analyze -i ./run-1 -o ./flakiness-analysis.md
```

## Tips and Best Practices

1. **Start Simple**: Begin with the `mvnimble-project` wrapper to get familiar with MVNimble
2. **Consistent Comparison**: Always use the same hardware when comparing different runs
3. **Full Builds**: Run with `--clean` for the most accurate results
4. **Multiple Runs**: Perform multiple runs to identify patterns and anomalies
5. **Follow Recommendations**: Implement the suggestions from the analysis reports
6. **Check Environment**: Use `mvnimble verify` to ensure proper setup
7. **Share Reports**: Use the HTML reports to share results with your team

---
Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license