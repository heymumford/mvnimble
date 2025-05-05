# MVNimble Simplified Structure

This document explains the simplified structure of MVNimble, designed to be more maintainable and accessible for QA engineers.

## Overview

MVNimble has been restructured to follow a more straightforward organization that emphasizes modularity and clarity. The restructuring was guided by these principles:

1. **Simplicity**: Make the codebase easy to understand and navigate
2. **Modularity**: Organize code by functionality rather than architectural layers
3. **Accessibility**: Optimize for QA engineers who need to use and extend the tool
4. **Maintainability**: Ensure code is easy to modify and enhance

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
    ├── simplified/       # New simplified test structure
    └── bats/             # Legacy test structure (for reference)
```

## Core Modules

### `bin/mvnimble`

The main entry point script that provides access to all MVNimble functionality:

```bash
# Monitor a Maven build
mvnimble monitor -- mvn clean test

# Analyze build results
mvnimble analyze -i ./results

# Generate a report
mvnimble report -i ./results/data.json -o ./report.html -f html

# Verify environment
mvnimble verify
```

### `bin/mvnimble-monitor`

A specialized script focused solely on monitoring Maven builds:

```bash
mvnimble-monitor -o ./results -- mvn clean test
```

### `bin/mvnimble-analyze`

A specialized script focused solely on analyzing build data:

```bash
mvnimble-analyze -i ./results -o ./analysis.html -f html
```

### `lib/constants.sh`

Defines global constants used across the application:
- Version information
- Default settings
- Color definitions for output
- Exit codes
- Performance thresholds

### `lib/common.sh`

Common utility functions:
- Logging functions
- Error handling
- File and path manipulation
- Basic validation functions

### `lib/environment.sh`

Environment detection and configuration:
- OS detection (macOS/Linux)
- Container detection
- CPU, memory, and disk resources
- JVM version detection
- CI environment detection

### `lib/monitor.sh`

Maven build monitoring:
- Real-time process monitoring
- Resource usage tracking (CPU, memory, I/O)
- JVM metrics collection
- Timeline generation for build phases

### `lib/analyze.sh`

Build analysis and optimization:
- Build failure analysis
- Test execution pattern analysis
- Maven configuration optimization
- Performance bottleneck identification
- Thread safety analysis

### `lib/report.sh`

Report generation:
- Markdown reports
- HTML reports with visualizations
- JSON data for programmatic access
- Templating functionality

## Comparison with Previous Structure

The previous structure followed a strict clean architecture approach with multiple layers:

```
mvnimble/
├── src/
│   ├── lib/
│   │   ├── mvnimble.sh
│   │   ├── generate_report.sh
│   │   └── modules/
│   │       ├── common.sh
│   │       ├── constants.sh
│   │       ├── dependency_check.sh
│   │       ├── environment.sh
│   │       ├── environment_detection.sh
│   │       ├── environment_unified.sh
│   │       ├── package_manager.sh
│   │       ├── platform_compatibility.sh
│   │       ├── real_time_analyzer.sh
│   │       ├── reporting.sh
│   │       └── shellcheck_wrapper.sh
│   └── completion/
│       └── _mvnimble
└── test/
    └── bats/
        ├── functional/
        ├── nonfunctional/
        ├── unit/
        └── validation/
```

The simplified structure:

1. Flattens the architecture to reduce navigation complexity
2. Organizes code by functionality rather than architectural layer
3. Provides dedicated scripts for specific tasks
4. Simplifies the test structure for better maintainability

## Benefits of the New Structure

1. **Easier Onboarding**: New team members can quickly understand the codebase organization
2. **Improved Maintainability**: Related functionality is grouped together
3. **Better Testability**: Tests are organized by functionality for clearer coverage
4. **Enhanced Usability**: Specialized scripts make common tasks more accessible
5. **Simplified Dependencies**: Reduced complexity in module relationships

## Migration Notes

The new structure maintains backward compatibility while providing a clearer organization:

1. **User-Facing Scripts**: The main `mvnimble` script is still available but now has additional specialized companions
2. **Library Structure**: The core functionality is now organized in a flat structure by module
3. **Testing**: The new simplified test structure coexists with the legacy test structure
4. **Documentation**: Updated to reflect the new organization while preserving important information

## Next Steps

To take full advantage of the simplified structure:

1. Use the specialized scripts for specific tasks
2. Follow the new organization when adding new functionality
3. Write tests using the simplified test structure
4. Refer to the updated documentation for guidance