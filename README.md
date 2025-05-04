# MVNimble: Maven Test Optimization Utility

<p align="center">
  <img src="doc/assets/mvnimble-logo.png" alt="MVNimble Logo" width="250"/>
</p>

<p align="center">
  <strong>Intelligent test cycle optimization for Maven projects</strong>
</p>

<p align="center">
  <a href="https://github.com/mvnimble/mvnimble/actions/workflows/ci-tests.yml">
    <img src="https://github.com/mvnimble/mvnimble/actions/workflows/ci-tests.yml/badge.svg" alt="CI Tests">
  </a>
  <a href="https://opensource.org/licenses/MIT">
    <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT">
  </a>
  <a href="https://github.com/mvnimble/mvnimble/releases">
    <img src="https://img.shields.io/github/v/release/mvnimble/mvnimble" alt="Latest Release">
  </a>
  <a href="https://github.com/mvnimble/mvnimble/stargazers">
    <img src="https://img.shields.io/github/stars/mvnimble/mvnimble" alt="Stars">
  </a>
</p>

---

## 🚀 Overview

MVNimble is an intelligent Maven test optimization tool that automatically detects and resolves performance bottlenecks in Maven builds across different environments. It helps you run your tests faster, more reliably, and with better resource utilization.

### Why MVNimble?

- **Save Time**: Reduce your test execution time by up to 60% through smart parallelization and resource optimization
- **Improve Reliability**: Detect flaky tests, thread safety issues, and environmental dependencies
- **Simplify CI/CD**: Optimize your continuous integration pipeline with environment-specific configurations
- **Get Insights**: Generate detailed reports to understand your test performance and resource utilization

## ✨ Key Features

- **📊 Environment Analysis** - Automatically detects your runtime environment (bare metal, container, or VM)
- **🔍 Resource Binding Detection** - Identifies whether your tests are CPU-bound, memory-bound, or I/O-bound
- **⚙️ Intelligent Configuration** - Recommends optimal Maven settings based on your specific environment
- **🧵 Thread Safety Analysis** - Detects concurrency issues in your test suite
- **🚀 Performance Optimization** - Provides specific recommendations to speed up your tests
- **📈 Visual Reporting** - Generates interactive HTML reports with detailed metrics and charts

## 📋 Table of Contents

- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [Usage Examples](#-usage-examples)
- [Documentation](#-documentation)
- [Testing](#-testing)
- [Contributing](#-contributing)
- [License](#-license)

## 📥 Installation

### Prerequisites

- Bash 3.2+ (MacOS or Linux)
- Java 8+ and Maven 3.x for Maven project analysis

### Quick Installation

```bash
# Clone the repository
git clone https://github.com/mvnimble/mvnimble.git

# Run the installer (includes automatic testing)
cd mvnimble
./install.sh
```

### Installation Options

```bash
# Skip automatic tests during installation
./install.sh --skip-tests

# Run only specific test categories
./install.sh --test-tags functional,positive

# Generate detailed test report during installation
./install.sh --test-report
```

For detailed installation instructions, see our [Installation Guide](./doc/INSTALLATION.md).

## 🏃 Quick Start

```bash
# Navigate to your Maven project directory
cd your-maven-project

# Monitor a build in real-time to detect bottlenecks
mvnimble monitor -- mvn clean test

# Analyze build results
mvnimble analyze -i ./mvnimble-results

# Generate a report in HTML format
mvnimble report -i ./mvnimble-results/data.json -o ./report.html -f html
```

## 📊 Usage Examples

### Basic Usage

```bash
# Monitor Maven test execution in real-time
mvnimble monitor -- mvn clean test

# Analyze build results and get optimization recommendations
mvnimble analyze -i ./mvnimble-results

# Verify your environment is properly configured
mvnimble verify
```

### Advanced Usage

```bash
# Monitor with custom settings
mvnimble monitor -o ./custom-results -i 10 -m 30 -- mvn clean test

# Use specialized monitoring script
mvnimble-monitor -o ./results -- mvn clean test

# Use specialized analysis script with HTML output
mvnimble-analyze -i ./results -o ./analysis.html -f html -p ./custom-pom.xml
```

For more usage examples, see our [Usage Guide](./doc/USAGE.md).

## 📚 Documentation

Complete documentation is available in the [doc directory](./doc/README.md). Key documents include:

- [Installation Guide](./doc/INSTALLATION.md) - How to install MVNimble
- [Usage Guide](./doc/USAGE.md) - How to use MVNimble effectively
- [Reporting Guide](./doc/REPORTING.md) - How to generate and use reports
- [Testing Guide](./doc/TESTING.md) - Testing approach and best practices
- [Troubleshooting Guide](./doc/TROUBLESHOOTING.md) - Solutions to common issues
- [Developer Guide](./doc/DEVELOPER-GUIDE.md) - For MVNimble developers
- [Contributing Guide](./doc/CONTRIBUTING.md) - How to contribute to MVNimble

## 🧪 Testing

MVNimble includes a comprehensive test suite using BATS (Bash Automated Testing System):

```bash
# Run all tests
./test/run_bats_tests.sh

# Run tests with specific tags
./test/run_bats_tests.sh --tags functional,positive

# Generate a test report in markdown format
./test/run_bats_tests.sh --report markdown

# Run a quick test summary
./test/test_summary.sh
```

Our tests are organized by category (functional vs. nonfunctional) and scenario (positive vs. negative). For more details on our testing approach, see [Testing Documentation](./doc/TESTING.md).

## 👥 Contributing

We welcome contributions of all kinds! Please see our [Contributing Guide](./doc/CONTRIBUTING.md) for details on:

- Setting up your development environment
- Coding conventions and standards
- The pull request process
- How to report bugs
- How to suggest new features

## 📄 License

MVNimble is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Made with ❤️ by the MVNimble team
</p>

---
Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
