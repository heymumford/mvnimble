# MVNimble Usage Guide

This guide provides comprehensive instructions for using MVNimble to optimize Maven test execution in different environments.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Basic Commands](#basic-commands)
3. [Analyzing Maven Projects](#analyzing-maven-projects)
4. [Optimization Modes](#optimization-modes)
5. [Report Generation](#report-generation)
6. [Advanced Usage](#advanced-usage)
7. [CI/CD Integration](#cicd-integration)
8. [Practical Examples](#practical-examples)
9. [Configuration](#configuration)

## Getting Started

After [installing MVNimble](./INSTALLATION.md), verify it's working correctly:

```bash
# Show version and basic information
mvnimble --version

# Display help and available commands
mvnimble --help
```

## Basic Commands

MVNimble provides several core commands for different use cases:

```bash
# Quick analysis of a Maven project
mvnimble --quick

# Detailed analysis with recommendations
mvnimble --analyze

# Thread safety analysis
mvnimble --thread-safety

# Generate an optimization report
mvnimble --report

# Apply recommended optimizations
mvnimble --optimize
```

## Analyzing Maven Projects

Navigate to your Maven project directory and run MVNimble to analyze it:

```bash
cd your-maven-project

# Run a quick analysis
mvnimble --quick

# Run a comprehensive analysis
mvnimble --analyze
```

The analysis will:
1. Detect your environment (local, container, CI)
2. Analyze your Maven project structure
3. Identify test performance bottlenecks
4. Suggest optimization strategies

## Optimization Modes

MVNimble provides several optimization modes for different scenarios:

### Quick Mode

```bash
# Fast analysis with basic recommendations
mvnimble --quick
```

Best for: Initial assessment, small projects, quick feedback

### Deep Analysis

```bash
# Comprehensive analysis with detailed recommendations
mvnimble --analyze --deep
```

Best for: Complex projects, persistent performance issues, thorough optimization

### Thread Safety Analysis

```bash
# Analyze tests for thread safety issues
mvnimble --thread-safety
```

Best for: Troubleshooting parallel test failures, preparing for CI environments

### Environment-Specific Optimization

```bash
# Optimize for container environments
mvnimble --optimize --container

# Optimize for CI environments
mvnimble --optimize --ci

# Optimize for local development
mvnimble --optimize --local
```

## Report Generation

MVNimble can generate detailed reports in various formats:

```bash
# Generate HTML report
mvnimble --report html

# Generate JSON report
mvnimble --report json

# Generate Markdown report
mvnimble --report markdown

# Specify output location
mvnimble --report html --output ./performance-report.html
```

Report contents include:
- Environment detection results
- Resource utilization metrics
- Bottleneck identification
- Thread safety analysis
- Optimization recommendations
- Performance comparison charts

## Advanced Usage

### Custom Maven Commands

```bash
# Use a specific Maven command
mvnimble --maven-cmd "/path/to/mvn"

# Pass options to Maven
mvnimble --maven-opts "-DskipTests=false -Dtest=TestClass"
```

### Multiple Projects

```bash
# Analyze multiple projects
mvnimble --analyze --projects path/to/project1,path/to/project2

# Compare projects
mvnimble --compare --projects path/to/project1,path/to/project2
```

### Profile Management

```bash
# Save current optimization as a profile
mvnimble --save-profile "ci-optimal"

# Apply a saved profile
mvnimble --apply-profile "ci-optimal"

# List available profiles
mvnimble --list-profiles
```

## CI/CD Integration

MVNimble integrates with popular CI/CD systems:

### GitHub Actions

```yaml
steps:
  - name: Optimize Maven Tests
    run: |
      curl -s https://raw.githubusercontent.com/mvnimble/mvnimble/main/install.sh | bash
      mvnimble --ci --optimize --report html
      
  - name: Run Optimized Tests
    run: mvn test
```

### Jenkins

```groovy
pipeline {
    agent any
    stages {
        stage('Optimize Tests') {
            steps {
                sh '''
                    curl -s https://raw.githubusercontent.com/mvnimble/mvnimble/main/install.sh | bash
                    mvnimble --ci --optimize --report html
                '''
            }
        }
        stage('Run Tests') {
            steps {
                sh 'mvn test'
            }
        }
    }
}
```

### Travis CI

```yaml
before_script:
  - curl -s https://raw.githubusercontent.com/mvnimble/mvnimble/main/install.sh | bash
  - mvnimble --ci --optimize
  
script:
  - mvn test
```

## Practical Examples

### Example 1: Quick Assessment

For a rapid assessment of your project's test performance:

```bash
cd your-maven-project
mvnimble --quick
```

Output:
```
MVNimble Quick Analysis Results:
✓ Environment: Local workstation (8 cores, 16GB RAM)
✓ Maven project detected: medium size (423 tests)
✓ Resource binding: CPU-bound tests
✓ Thread safety: 4 potential issues detected
✓ Recommendation: 6 parallel threads (optimal for CPU-bound workload)

Quick fix: mvn -T 6 test
```

### Example 2: Thread Safety Troubleshooting

When experiencing intermittent test failures in CI:

```bash
mvnimble --thread-safety --deep
```

Output:
```
Thread Safety Analysis Results:
✓ 15 tests analyzed for thread safety
✗ 3 tests showing non-deterministic behavior
✗ 2 tests failing only in parallel execution

Problematic tests:
- com.example.UserServiceTest.testConcurrentUserCreation
  Issue: Shared static resource without synchronization
  Fix: Add proper synchronization to UserService.counter

- com.example.DatabaseTest.testConnection
  Issue: Connection pool exhaustion
  Fix: Mock database connection or use test-specific pool

Apply fixes with: mvnimble --fix-thread-safety
```

### Example 3: Optimizing for CI Environment

When setting up a new CI pipeline:

```bash
mvnimble --optimize --ci --report html
```

Output:
```
CI Environment Optimization:
✓ CI environment detected: GitHub Actions (2 cores)
✓ Memory constraints detected: 7GB available
✓ Disk I/O: SSD, high performance
✓ Network: Limited bandwidth

Optimization applied:
- Maven fork count set to 2
- JVM memory reduced to 768MB per fork
- Reuse test JVMs enabled
- Thread safety fixes applied to 2 tests

Report saved to: mvnimble-report.html
```

### Example 4: Comparing Configurations

To find the optimal Maven configuration for your project:

```bash
mvnimble --benchmark --iterations 5
```

Output:
```
Benchmark Results (5 iterations per config):

Configuration | Avg Time  | Memory  | Pass Rate
--------------|-----------|---------|----------
T=1 (serial)  | 3m 45s    | 1.2GB   | 100%
T=2           | 2m 12s    | 2.3GB   | 100%
T=4           | 1m 38s    | 4.1GB   | 98.5%
T=6           | 1m 24s    | 5.8GB   | 96.2%
T=8           | 1m 26s    | 7.2GB   | 92.1%

✓ Recommendation: T=4 (optimal balance of speed and stability)
```

## Configuration

MVNimble can be configured using:

### Command Line Options

See all available options with:
```bash
mvnimble --help
```

### Configuration File

Create a `.mvnimble.conf` file in your project directory:

```ini
# MVNimble Configuration
default_mode=analyze
parallel_threads=4
memory_per_thread=512m
report_format=html
save_history=true
```

### Environment Variables

```bash
# Set environment variables
export MVNIMBLE_THREADS=4
export MVNIMBLE_MEMORY=768m
export MVNIMBLE_REPORT=html

# Then run without arguments
mvnimble
```

---
Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
