# MVNimble Project Structure

This document outlines the simplified structure of the MVNimble project, designed to make it more maintainable and accessible to QA engineers.

## Directory Structure

```
mvnimble/
├── bin/                  # User-facing executable scripts
│   ├── mvnimble          # Main entry point script
│   ├── mvnimble-monitor  # Specialized monitoring script
│   └── mvnimble-analyze  # Specialized analysis script
│
├── lib/                  # Core library modules
│   ├── constants.sh      # Global constants and configuration
│   ├── common.sh         # Common utility functions
│   ├── environment.sh    # Environment detection functionality
│   ├── monitor.sh        # Maven build monitoring functionality
│   ├── analyze.sh        # Build analysis and optimization
│   └── report.sh         # Report generation in different formats
│
├── examples/             # Usage examples and sample projects
│   └── simple-junit-project/  # Simple Maven project for testing
│
├── doc/                  # Documentation
│   ├── USAGE.md          # Usage guide
│   ├── INSTALLATION.md   # Installation instructions
│   └── ...               # Additional documentation
│
└── test/                 # Tests
    ├── run_bats_tests.sh # Test runner
    └── bats/             # BATS test files
```

## Core Modules

### Constants Module (`lib/constants.sh`)

Defines global constants used across the application:
- Version information
- Default settings
- Color definitions for output
- Exit codes
- Performance thresholds

### Common Utilities (`lib/common.sh`)

Common functions used by multiple modules:
- Logging functions
- Error handling
- File and path manipulation
- Basic validation functions

### Environment Module (`lib/environment.sh`)

Functionality for detecting and configuring the runtime environment:
- OS detection (macOS/Linux)
- Container detection
- CPU, memory, and disk resources
- JVM version detection
- CI environment detection

### Monitoring Module (`lib/monitor.sh`)

Core functionality for monitoring Maven builds:
- Real-time process monitoring
- Resource usage tracking (CPU, memory, I/O)
- JVM metrics collection
- Timeline generation for build phases

### Analysis Module (`lib/analyze.sh`)

Tools for analyzing build data and suggesting optimizations:
- Build failure analysis
- Test execution pattern analysis
- Maven configuration optimization
- Performance bottleneck identification
- Thread safety analysis

### Reporting Module (`lib/report.sh`)

Report generation in multiple formats:
- Markdown reports
- HTML reports with visualizations
- JSON data for programmatic access
- Templating functionality

## User-Facing Scripts

### Main Entry Point (`bin/mvnimble`)

The main command with all functionality accessible through subcommands:
- `mvnimble monitor` - Monitor Maven builds
- `mvnimble analyze` - Analyze build results
- `mvnimble report` - Generate reports
- `mvnimble verify` - Verify environment

### Specialized Scripts

- `bin/mvnimble-monitor` - Dedicated tool for monitoring Maven builds
- `bin/mvnimble-analyze` - Dedicated tool for analyzing build data

These specialized scripts provide direct access to specific functionality for users who prefer focused tools.

## Development Guidelines

1. **Modularity**: Each shell script should have a single responsibility
2. **Documentation**: Include header comments explaining purpose and usage
3. **Error Handling**: Use proper error handling and exit codes
4. **Testing**: Write BATS tests for all new functionality
5. **Portability**: Maintain compatibility with Bash 3.2+ for macOS support

---
Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license