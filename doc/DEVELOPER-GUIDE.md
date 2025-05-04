# MVNimble Developer Guide

This guide provides information for developers working on MVNimble's codebase or integrating MVNimble into their own projects.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Core Modules](#core-modules)
3. [Development Workflow](#development-workflow)
4. [CI/CD Integration](#cicd-integration)
5. [Project Roadmap](#project-roadmap)

## Architecture Overview

MVNimble follows a modular shell script architecture designed for extensibility and cross-platform compatibility.

### Architectural Principles

1. **Modularity**: Functionality is divided into focused modules
2. **Abstraction**: Platform-specific details are abstracted away
3. **Testability**: All components designed for automated testing
4. **Portability**: Works across Linux, macOS, and container environments

### High-Level Architecture

```
MVNimble
├── Core Engine (mvnimble.sh)
│   ├── Command Processor
│   ├── Plugin System
│   └── Configuration Manager
├── Environment Modules
│   ├── Environment Detection
│   ├── Resource Analysis
│   └── Platform Compatibility
├── Optimization Modules
│   ├── Test Analysis
│   ├── Configuration Generator
│   └── Performance Benchmarking
└── Utilities
    ├── Reporting
    ├── Logging
    └── Package Management
```

## Core Modules

### Environment Detection (environment_unified.sh)

The environment detection module provides cross-platform detection of:
- Operating system and version
- Container environment (Docker, Kubernetes)
- Resource limits (CPU, memory)
- Hardware capabilities

Key functions:
- `detect_operating_system()`: Identifies the current OS
- `detect_container()`: Detects if running in container environment
- `get_cpu_info()`: Retrieves CPU information
- `get_memory_info()`: Retrieves memory information

### Platform Compatibility (platform_compatibility.sh)

This module abstracts platform-specific implementations and ensures cross-platform compatibility:
- Provides unified interfaces for OS-specific commands
- Handles differences between GNU and BSD utilities
- Ensures consistent behavior across environments

Key functions:
- `get_cpu_count()`: Platform-independent CPU count retrieval
- `get_free_memory_mb()`: Platform-independent memory information
- `collect_disk_io_information()`: Unified disk I/O statistics

### Test Analysis (test_analysis.sh)

This module analyzes Maven test execution:
- Parses Maven test output
- Identifies performance bottlenecks
- Detects flaky tests
- Measures test parallelization efficiency

Key functions:
- `analyze_test_output()`: Processes Maven test logs
- `identify_slow_tests()`: Finds the slowest tests
- `detect_flaky_tests()`: Identifies inconsistently failing tests
- `measure_parallelism_efficiency()`: Evaluates parallel execution

### Reporting (reporting.sh)

The reporting module generates formatted reports:
- Creates HTML, Markdown, JSON reports
- Visualizes test performance
- Generates optimization recommendations
- Provides actionable insights

Key functions:
- `generate_report()`: Creates reports in different formats
- `format_recommendations()`: Formats optimization suggestions
- `create_visualization()`: Generates performance visualizations

## Development Workflow

### Local Development

1. Clone the repository:
   ```bash
   git clone https://github.com/mvnimble/mvnimble.git
   cd mvnimble
   ```

2. Run tests:
   ```bash
   ./test/run_bats_tests.sh
   ```

3. Make changes and test them:
   ```bash
   # Run specific tests related to your changes
   ./test/run_bats_tests.sh --test-dir ./test/bats/your-feature

   # Run shellcheck on your changes
   shellcheck src/lib/modules/your-module.sh
   ```

4. Commit and push changes:
   ```bash
   git add .
   git commit -m "Describe your changes"
   git push origin your-branch
   ```

### Development Best Practices

1. **Test-Driven Development**:
   - Write tests before implementing features
   - Ensure all tests pass before submitting PRs
   - Test both positive and negative scenarios

2. **Code Quality**:
   - Run shellcheck on all scripts
   - Adhere to the coding conventions in [CONTRIBUTING.md](./CONTRIBUTING.md)
   - Document all functions and complex logic

3. **Cross-Platform Testing**:
   - Test on both Linux and macOS
   - Verify container environment behavior
   - Ensure compatibility with CI environments

## CI/CD Integration

MVNimble includes configurations for common CI/CD systems:

### GitHub Actions

We use GitHub Actions for our CI pipeline. The workflow configuration is at `.github/workflows/ci-tests.yml`:

```yaml
name: CI Tests

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:
    inputs:
      test_tags:
        description: 'Tags to test (comma-separated)'
        required: false
        default: ''

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Install BATS
        run: |
          git clone https://github.com/bats-core/bats-core.git
          cd bats-core
          ./install.sh $HOME
      
      - name: Run tests
        run: |
          ./test/run_bats_tests.sh ${{ github.event.inputs.test_tags && format('--tags {0}', github.event.inputs.test_tags) || '' }}
      
      - name: Generate report
        run: |
          ./test/run_bats_tests.sh --report markdown
```

### Other CI/CD Systems

Configuration examples are available for:
- Jenkins
- GitLab CI
- CircleCI
- Azure DevOps

See the `ci-config-examples/` directory for detailed configurations.

## Project Roadmap

### Current Development Focus

1. **Enhanced Container Support**:
   - Kubernetes-specific optimizations
   - Container resource limit awareness
   - Ephemeral container detection

2. **Advanced Test Analytics**:
   - Machine learning for test optimization
   - Historical performance tracking
   - Predictive optimization

3. **Expanded Platform Support**:
   - Windows/WSL compatibility
   - Cloud-native environment detection
   - CI/CD system auto-detection

### Future Directions

1. **Plugin System**:
   - User-extendable plugins
   - Integration with test frameworks
   - Custom optimization strategies

2. **Enhanced Reporting**:
   - Interactive dashboard
   - Trend analysis
   - Team collaboration features

3. **Integration Ecosystem**:
   - IDE plugins
   - CI/CD native integrations
   - APM tool connections

---
Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license