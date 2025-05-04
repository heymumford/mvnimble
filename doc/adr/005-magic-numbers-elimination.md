# ADR 005: Magic Numbers Elimination

## Status

Accepted

## Context

MVNimble contains numerous numeric and string constants throughout the codebase, including:

1. **Timeout Values**: Maximum time durations for various operations
2. **Threshold Values**: Numeric thresholds for performance analysis
3. **Default Settings**: Default values for memory, threads, forks, etc.
4. **ANSI Color Codes**: Terminal color formatting sequences
5. **File Paths**: Default paths for storage
6. **Version Information**: Version numbers and compatibility requirements

These "magic numbers" and literals scattered throughout the code create several problems:

1. **Reduced Maintainability**: Changes require finding and updating values in multiple places
2. **Inconsistency Risk**: Different parts of the code might use different values
3. **Lack of Documentation**: The meaning and purpose of hardcoded values isn't always clear
4. **Testing Difficulties**: Hardcoded values complicate unit testing
5. **Configuration Challenges**: Updating defaults requires code changes

We need a systematic approach to eliminate magic numbers and string literals.

## Decision

We will implement a centralized constants management system with the following components:

1. **Dedicated Constants Module**: Create a `constants.sh` module that serves as a central repository for all constants used throughout the codebase.

2. **Categorized Constants**: Organize constants into logical categories:
   - Version Information
   - Default Settings
   - Resource Constraints
   - Performance Thresholds
   - Path Constants
   - Terminal Formatting
   - File Format Constants

3. **Readonly Declaration**: Declare all constants as readonly to prevent accidental modification.

4. **Descriptive Naming**: Use UPPERCASE_WITH_UNDERSCORES naming convention with descriptive names that make the purpose clear.

5. **Inclusion Pattern**: Each module that needs constants will source the constants module.

6. **Documentation**: Each constant or group of related constants will include a brief comment explaining its purpose.

7. **Derived Constants**: Where appropriate, derive values from other constants rather than duplicating values.

## Consequences

### Positive

- **Improved Maintainability**: Change constants in one place
- **Self-Documenting Code**: Constants with descriptive names make code more readable
- **Consistency**: Same values used throughout the codebase
- **Easier Testing**: Tests can override constants for specific test scenarios
- **Simplified Configuration**: Clearer path to making settings configurable

### Negative

- **Loading Overhead**: Small performance impact from sourcing the constants module
- **Dependency Management**: Need to ensure constants module is available

### Neutral

- **Development Discipline**: Requires discipline to use constants instead of literals
- **Naming Conventions**: Need to maintain consistent naming conventions

## Implementation Notes

1. **Constants Module Structure**:
```bash
#!/bin/bash
# constants.sh
# MVNimble - Global constants and configuration values
#
# This module defines all global constants used throughout MVNimble,
# eliminating magic numbers and centralizing configuration values.

# Version information
readonly MVNIMBLE_VERSION="1.0.0"
readonly MVNIMBLE_RELEASE_DATE="2025-05-02"

# Default analysis settings
readonly DEFAULT_MODE="full"               # Default analysis mode
readonly DEFAULT_MAX_MINUTES=30            # Default maximum analysis time
readonly DEFAULT_FORK_COUNT="1.0C"         # Default Maven fork count
readonly DEFAULT_THREAD_COUNT=1            # Default Maven thread count 
readonly DEFAULT_MEMORY_MB=256             # Default Maven memory allocation

# Resource constraints
readonly MIN_MEMORY_MB=128                 # Minimum memory per fork
readonly MAX_MEMORY_PERCENTAGE=80          # Max % of system memory to use
readonly MONITORING_INTERVAL_SECONDS=1     # Resource monitoring interval
readonly MAX_MONITORING_DURATION=180       # Maximum monitoring time in seconds

# Performance analysis thresholds
readonly MEMORY_HIGH_SENSITIVITY=15        # % improvement to consider memory binding high
readonly MEMORY_MEDIUM_SENSITIVITY=5       # % improvement to consider memory binding medium
readonly CPU_HIGH_SENSITIVITY=15           # % improvement to consider CPU binding high
readonly CPU_MEDIUM_SENSITIVITY=5          # % improvement to consider CPU binding medium
readonly IO_HIGH_THRESHOLD=50              # % CPU utilization below which to consider I/O bound
readonly IO_MEDIUM_THRESHOLD=80            # % CPU utilization below which to consider partially I/O bound
readonly EFFICIENCY_THRESHOLD=1.1          # Multiplier for considering "efficient" configurations

# Path constants
readonly DEFAULT_RESULTS_DIR="results"     # Default location for results
readonly TEMP_FILE_PREFIX="mvnimble-tmp"   # Prefix for temporary files

# File backup constants
readonly POM_BACKUP_SUFFIX=".mvnimblebackup" # Suffix for pom.xml backup

# Terminal color definitions
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_BOLD='\033[1m'
readonly COLOR_RESET='\033[0m'             # Reset (no color)
```

2. **Usage in Other Modules**:
```bash
#!/bin/bash
# environment_detection.sh

# Source constants
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/constants.sh"

function analyze_runtime_environment() {
  echo -e "${COLOR_BOLD}${COLOR_BLUE}=== Environment Analysis ===${COLOR_RESET}"
  
  # Use constants
  if [[ "$memory_mb" -lt "$MIN_MEMORY_MB" ]]; then
    echo "Warning: Available memory is below recommended minimum" >&2
  fi
  
  # ...
}
```

3. **Derived Constants Example**:
```bash
# Base timeout value
readonly BASE_TIMEOUT_SECONDS=30

# Derived timeouts
readonly NETWORK_TIMEOUT_SECONDS=$((BASE_TIMEOUT_SECONDS * 2))
readonly MAVEN_TIMEOUT_SECONDS=$((BASE_TIMEOUT_SECONDS * 10))
readonly QUICK_TEST_TIMEOUT_SECONDS=$((BASE_TIMEOUT_SECONDS / 2))
```

---
Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
