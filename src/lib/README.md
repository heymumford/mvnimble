# MVNimble Source Library

This directory contains the source code for MVNimble, organized in a modular structure:

## Directory Structure

- **core/**: Core functionality and utilities
  - Main entry point script
  - Common utilities
  - Constants and configuration
  - Environment detection
  
- **analysis/**: Build and test analysis functionality
  - Test analysis and optimization
  - Flaky test detection
  
- **monitoring/**: Real-time monitoring functionality
  - Build monitoring
  - Resource tracking
  - Thread visualization
  
- **reporting/**: Report generation and output
  - Report formatters
  - Data visualization
  - XML processing
  
- **testing/**: Testing utilities and helpers
  - BATS integration
  - Shellcheck wrappers

## Module Design

Each module follows these principles:
1. Single responsibility
2. Clear documentation
3. Consistent error handling
4. Proper dependency management
5. Cross-platform compatibility

## Usage

Most components are not intended to be used directly but are leveraged by the main `mvnimble` command.

For development and contribution guidelines, see [CONTRIBUTING.md](../../doc/CONTRIBUTING.md).