#!/bin/bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# test_constants.sh
# Non-readonly version of constants for testing

# Guard to prevent multiple sourcing - indicate that constants are loaded
CONSTANTS_LOADED=true

# Version information
MVNIMBLE_VERSION="0.1.0"
MVNIMBLE_BUILD_DATE="2025-05-02"

# Color codes for terminal output
COLOR_RED="31"
COLOR_GREEN="32"
COLOR_YELLOW="33"
COLOR_BLUE="34" 
COLOR_MAGENTA="35"
COLOR_CYAN="36"
COLOR_RESET="0"

# Exit codes
EXIT_SUCCESS=0
EXIT_GENERAL_ERROR=1
EXIT_DEPENDENCY_ERROR=2
EXIT_VALIDATION_ERROR=3
EXIT_RUNTIME_ERROR=4
EXIT_NETWORK_ERROR=5
EXIT_FILE_ERROR=6
EXIT_CONFIG_ERROR=7
EXIT_USER_CANCELED=${EXIT_GENERAL_ERROR}

# For backward compatibility
EXIT_FAILURE=${EXIT_GENERAL_ERROR}
EXIT_INVALID_ARGS=${EXIT_VALIDATION_ERROR}
EXIT_DEPENDENCY_MISSING=${EXIT_DEPENDENCY_ERROR}
EXIT_PERMISSION_DENIED=${EXIT_FILE_ERROR}

# Default values
DEFAULT_TIMEOUT=30
DEFAULT_RETRIES=3
DEFAULT_THREADS=4
DEFAULT_MEMORY="1024m"
DEFAULT_MEMORY_MB=2048
MIN_MEMORY_MB=512

# File and directory paths
MVNIMBLE_USER_CONFIG_DIR="${HOME}/.config/mvnimble"
MVNIMBLE_USER_CONFIG_FILE="${MVNIMBLE_USER_CONFIG_DIR}/config.json"
MVNIMBLE_CACHE_DIR="${HOME}/.cache/mvnimble"
MVNIMBLE_LOG_DIR="${HOME}/.local/share/mvnimble/logs"

# Required commands
REQUIRED_COMMANDS=("java" "mvn" "grep" "awk" "sed")
