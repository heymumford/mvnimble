#!/usr/bin/env bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
#==============================================================================
# constants.sh
#
# MVNimble - Global Constants and Configuration Module
#
# Description:
#   This module defines all global constants and configuration values used 
#   throughout MVNimble. It eliminates magic numbers and centralizes 
#   configuration, making the codebase more maintainable.
#
# Usage:
#   source "path/to/constants.sh"
#   echo "Default path: ${DEFAULT_REPORT_DIR}"
#==============================================================================

# Guard to prevent multiple sourcing
if [[ -n "${CONSTANTS_LOADED+x}" ]]; then
  return 0
fi
readonly CONSTANTS_LOADED=true

# Version Information
readonly MVNIMBLE_VERSION="0.1.0"                     # Current MVNimble version
readonly MVNIMBLE_BUILD_DATE="2025-05-04"             # Build date 
readonly MINIMUM_BASH_VERSION="3.2"                   # Minimum required Bash version
readonly MINIMUM_JAVA_VERSION="8"                     # Minimum required Java version
readonly MINIMUM_MVN_VERSION="3.6.0"                  # Minimum required Maven version

# Exit Codes
readonly EXIT_SUCCESS=0                               # Successful execution
readonly EXIT_GENERAL_ERROR=1                         # General/unspecified error
readonly EXIT_DEPENDENCY_ERROR=2                      # Missing dependency
readonly EXIT_VALIDATION_ERROR=3                      # Input validation error
readonly EXIT_RUNTIME_ERROR=4                         # Runtime execution error
readonly EXIT_USER_CANCELED=${EXIT_GENERAL_ERROR}     # User canceled operation

# Default Settings
readonly DEFAULT_COMMAND_TIMEOUT=120                  # Default command timeout in seconds
readonly DEFAULT_MAX_MINUTES=10                       # Default maximum runtime in minutes
readonly DEFAULT_RETRY_COUNT=3                        # Default number of retry attempts
readonly DEFAULT_RETRY_DELAY=5                        # Default delay between retries in seconds
readonly DEFAULT_THREAD_COUNT=1                       # Default Maven thread count
readonly DEFAULT_FORK_COUNT=1                         # Default Maven fork count

# Resource Constraints
readonly MIN_MEMORY_MB=512                            # Minimum memory required in MB
readonly DEFAULT_MEMORY_MB=2048                       # Default memory allocation in MB
readonly MAX_MEMORY_PERCENT=75                        # Maximum percent of system memory to use

# Performance Thresholds
readonly CPU_HIGH_THRESHOLD=85                        # CPU usage % considered high
readonly CPU_MEDIUM_THRESHOLD=50                      # CPU usage % considered medium
readonly MEMORY_HIGH_THRESHOLD=80                     # Memory usage % considered high
readonly MEMORY_MEDIUM_THRESHOLD=60                   # Memory usage % considered medium

# Terminal Colors
readonly COLOR_RESET="\033[0m"                        # Reset all attributes
readonly COLOR_RED="\033[0;31m"                       # Red text
readonly COLOR_GREEN="\033[0;32m"                     # Green text
readonly COLOR_YELLOW="\033[0;33m"                    # Yellow text
readonly COLOR_BLUE="\033[0;34m"                      # Blue text
readonly COLOR_MAGENTA="\033[0;35m"                   # Magenta text
readonly COLOR_CYAN="\033[0;36m"                      # Cyan text
readonly COLOR_BOLD="\033[1m"                         # Bold text

# File and Path Constants
readonly DEFAULT_CONFIG_FILE="mvnimble.config"        # Default configuration file name
readonly DEFAULT_REPORT_DIR="./results"               # Default directory for reports
readonly DEFAULT_LOG_FILE="mvnimble.log"              # Default log file name
readonly TEMP_FILE_PREFIX="mvnimble-tmp"              # Prefix for temporary files