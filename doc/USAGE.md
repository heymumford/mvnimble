# MVNimble Usage Guide

This guide explains how to use MVNimble to optimize Maven test execution in different environments.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Core Features](#core-features)
3. [Monitoring Maven Tests](#monitoring-maven-tests)
4. [Optimizing Test Execution](#optimizing-test-execution)
5. [Build Failure Analysis](#build-failure-analysis)
6. [CI/CD Integration](#cicd-integration)
7. [Real-World Examples](#real-world-examples)

## Quick Start

After installation, get started with MVNimble using these basic commands:

```bash
# Basic Maven test monitoring
mvnimble monitor -p /path/to/maven/project

# Analyze Maven build
mvnimble analyze -p /path/to/maven/project

# Auto-optimize Maven test configuration
mvnimble optimize -p /path/to/maven/project

# Generate optimization report
mvnimble report -p /path/to/maven/project -f markdown
```

## Core Features

### Environment Analysis

```bash
# Analyze the current environment
mvnimble env-analyze

# Show resource utilization
mvnimble resources

# Detect container environment
mvnimble detect-container
```

### Test Configuration

```bash
# Generate optimized Maven settings
mvnimble configure -p /path/to/maven/project

# Apply optimized settings to project
mvnimble configure -p /path/to/maven/project --apply

# Export configuration to file
mvnimble configure -p /path/to/maven/project --export=mvn-settings.xml
```

### Performance Testing

```bash
# Run benchmark tests
mvnimble benchmark -p /path/to/maven/project

# Compare configurations
mvnimble benchmark -p /path/to/maven/project --compare=config1.xml,config2.xml
```

## Monitoring Maven Tests

MVNimble provides real-time monitoring of test execution, giving you insights into resource usage, potential bottlenecks, and test behavior.

### Basic Monitoring

```bash
# Monitor a Maven test run with default settings
mvnimble monitor -p /path/to/maven/project

# Monitor specific test classes
mvnimble monitor -p /path/to/maven/project -t "**/LoginTest.java"

# Monitor with increased verbosity
mvnimble monitor -p /path/to/maven/project --verbose
```

### Advanced Monitoring Options

```bash
# Monitor with resource threshold alerts
mvnimble monitor -p /path/to/maven/project --cpu-threshold=80 --memory-threshold=70

# Monitor with custom refresh rate (seconds)
mvnimble monitor -p /path/to/maven/project --refresh=5

# Save monitoring data to file
mvnimble monitor -p /path/to/maven/project --output=monitoring_data.json
```

### Monitoring Dashboard

For an interactive experience, use the monitoring dashboard:

```bash
mvnimble dashboard -p /path/to/maven/project
```

The dashboard provides:
- CPU and memory usage graphs
- Test execution progress
- Thread utilization
- Disk I/O metrics
- Network activity
- JVM memory pools

## Optimizing Test Execution

MVNimble analyzes your test environment and provides targeted optimizations to improve performance.

### Optimization Process

1. **Analysis**: MVNimble analyzes current test performance
2. **Identification**: Bottlenecks and inefficiencies are identified
3. **Recommendation**: Optimized configuration is generated
4. **Validation**: Performance improvements are verified

### Optimization Commands

```bash
# Generate optimization recommendations
mvnimble optimize -p /path/to/maven/project

# Apply optimizations automatically
mvnimble optimize -p /path/to/maven/project --apply

# Optimize for specific environment (container, CI, local)
mvnimble optimize -p /path/to/maven/project --env=container

# Focus on specific optimization areas
mvnimble optimize -p /path/to/maven/project --focus=memory,threads
```

### Key Optimization Areas

1. **Thread Count Optimization**: 
   - MVNimble analyzes CPU cores, available memory, and test characteristics
   - Recommends optimal thread counts for parallel test execution

2. **Memory Settings**:
   - Analyzes memory usage patterns
   - Optimizes JVM heap settings
   - Configures garbage collection for test workloads

3. **Test Grouping**:
   - Identifies tests that can safely run in parallel
   - Groups tests that conflict with each other
   - Optimizes test execution order

4. **Fork Optimization**:
   - Balances JVM reuse with isolation requirements
   - Optimizes fork counts based on memory availability
   - Configures fork timeouts appropriately

## Build Failure Analysis

MVNimble provides tools to diagnose and resolve Maven build failures.

### Analyzing Failed Builds

```bash
# Analyze a failed build
mvnimble analyze-failure -p /path/to/maven/project

# Analyze with log file input
mvnimble analyze-failure --log=build.log

# Generate detailed report
mvnimble analyze-failure -p /path/to/maven/project --report=failures.md
```

### Common Build Failures

MVNimble can help diagnose and resolve common build failures:

1. **Resource Constraints**:
   - Insufficient memory for test execution
   - CPU contention in parallel tests
   - Disk I/O bottlenecks

2. **Test Flakiness**:
   - Timing-sensitive tests
   - Race conditions in parallel execution
   - Resource leaks

3. **Configuration Issues**:
   - Incompatible plugin versions
   - Incorrect dependency management
   - Environment-specific configuration problems

## CI/CD Integration

MVNimble integrates with popular CI/CD systems to optimize test execution in continuous integration environments.

### GitHub Actions Integration

```yaml
steps:
  - name: Checkout code
    uses: actions/checkout@v3
  
  - name: Set up MVNimble
    run: curl -sSL https://get.mvnimble.io | bash
  
  - name: Optimize and run tests
    run: |
      mvnimble optimize -p . --apply --env=ci
      mvn test
```

### Jenkins Integration

```groovy
pipeline {
  agent any
  stages {
    stage('Test') {
      steps {
        sh 'curl -sSL https://get.mvnimble.io | bash'
        sh 'mvnimble optimize -p . --apply --env=ci'
        sh 'mvn test'
      }
    }
  }
}
```

## Real-World Examples

### Medium-sized Java Project

For a project with 500-1000 tests:

```bash
# Analyze the environment
mvnimble env-analyze

# Monitor current performance
mvnimble monitor -p /path/to/project

# Generate and apply optimizations
mvnimble optimize -p /path/to/project --apply

# Verify improvements
mvnimble benchmark -p /path/to/project --before=before.json --after=after.json
```

Typical results:
- 30-50% reduction in test execution time
- More stable test execution
- Reduced resource usage

### Container Environment

For tests running in Docker/Kubernetes:

```bash
# Detect container limits
mvnimble detect-container

# Monitor with container awareness
mvnimble monitor -p /path/to/project --env=container

# Container-specific optimization
mvnimble optimize -p /path/to/project --env=container --apply
```

Typical benefits:
- Prevents test failures due to resource limits
- Optimizes resource utilization within container constraints
- Improves test stability in shared environments

---
Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license