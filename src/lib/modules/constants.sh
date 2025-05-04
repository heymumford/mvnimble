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
#   configuration, making the codebase more maintainable. Constants are
#   organized by category for clarity.
#
# Usage:
#   source "path/to/constants.sh"
#   # Then use constants like:
#   echo "Default path: ${DEFAULT_REPORT_DIR}"
#   echo "Success exit code: ${EXIT_SUCCESS}"
#
# Constants Defined:
#   - Exit codes
#   - Default values
#   - Color codes (for terminal output)
#   - File paths
#   - Timeout values
#   - Resource thresholds
#
# Dependencies:
#   None - this is a root dependency used by other modules
#
# Author: MVNimble Team
# Version: 1.0.1
# Last Updated: 2025-05-04
#==============================================================================

# Guard to prevent multiple sourcing
if [[ -n "${CONSTANTS_LOADED+x}" ]]; then
  return 0
fi
readonly CONSTANTS_LOADED=true

# This module should only be loaded once
# Flag to indicate constants have been loaded
readonly MVNIMBLE_CONSTANTS_LOADED=true

# =============================================================================
# Version Information
# =============================================================================
# Contains version numbers and compatibility requirements
readonly MVNIMBLE_VERSION="0.1.0"                     # Current MVNimble version
readonly MVNIMBLE_BUILD_DATE="2025-05-03"             # Build date 
readonly MINIMUM_BASH_VERSION="3.2"                   # Minimum required Bash version
readonly MINIMUM_JAVA_VERSION="8"                     # Minimum required Java version
readonly MINIMUM_MVN_VERSION="3.6.0"                  # Minimum required Maven version
readonly MINIMUM_SHELLCHECK_VERSION="0.7.0"           # Minimum ShellCheck version for script validation

# =============================================================================
# Exit Codes
# =============================================================================
# Standardized error codes for consistent error handling
readonly EXIT_SUCCESS=0                               # Successful execution
readonly EXIT_GENERAL_ERROR=1                         # General/unspecified error
readonly EXIT_DEPENDENCY_ERROR=2                      # Missing dependency
readonly EXIT_VALIDATION_ERROR=3                      # Input validation error
readonly EXIT_RUNTIME_ERROR=4                         # Runtime execution error
readonly EXIT_NETWORK_ERROR=5                         # Network connectivity error
readonly EXIT_FILE_ERROR=6                            # File access/permission error
readonly EXIT_CONFIG_ERROR=7                          # Configuration error
readonly EXIT_USER_CANCELED=${EXIT_GENERAL_ERROR}     # User canceled operation (derived)

# =============================================================================
# Default Settings
# =============================================================================
# Default configuration values used throughout the application
readonly DEFAULT_COMMAND_TIMEOUT=120                  # Default command timeout in seconds
readonly DEFAULT_MAX_MINUTES=10                       # Default maximum runtime in minutes
readonly DEFAULT_RETRY_COUNT=3                        # Default number of retry attempts
readonly DEFAULT_RETRY_DELAY=5                        # Default delay between retries in seconds
readonly DEFAULT_LOG_LEVEL="info"                     # Default logging level
readonly DEFAULT_THREAD_COUNT=1                       # Default Maven thread count
readonly DEFAULT_FORK_COUNT=1                         # Default Maven fork count
readonly DEFAULT_TEST_MODE="full"                     # Default test execution mode
readonly DEFAULT_LONG_TIMEOUT=$((DEFAULT_COMMAND_TIMEOUT * 2)) # Long timeout derived from default

# =============================================================================
# Resource Constraints
# =============================================================================
# Memory, CPU, and other resource related constants
readonly MIN_MEMORY_MB=512                            # Minimum memory required in MB
readonly DEFAULT_MEMORY_MB=2048                       # Default memory allocation in MB
readonly MAX_MEMORY_PERCENT=75                        # Maximum percent of system memory to use
readonly MINIMUM_DISK_SPACE_MB=200                    # Minimum required disk space in MB
readonly SECONDS_PER_DAY=86400                        # Seconds in a day (used in calculations)
readonly ESSENTIAL_COMMANDS="awk grep sed cat"        # Essential commands required by MVNimble

# =============================================================================
# Performance Thresholds
# =============================================================================
# Thresholds used for performance analysis and optimization
readonly CPU_HIGH_THRESHOLD=85                        # CPU usage % considered high
readonly CPU_MEDIUM_THRESHOLD=50                      # CPU usage % considered medium
readonly MEMORY_HIGH_THRESHOLD=80                     # Memory usage % considered high
readonly MEMORY_MEDIUM_THRESHOLD=60                   # Memory usage % considered medium
readonly NETWORK_TIMEOUT_SECONDS=30                   # Network operation timeout
readonly QUICK_RUN_THRESHOLD=5                        # Threshold for quick test runs in seconds

# =============================================================================
# Package Manager Constants
# =============================================================================
# Constants related to system package managers
readonly PKG_MGR_APT="apt"                            # Debian/Ubuntu package manager
readonly PKG_MGR_BREW="brew"                          # macOS package manager
readonly PKG_MGR_YUM="yum"                            # CentOS/RHEL package manager
readonly PKG_MGR_DNF="dnf"                            # Fedora package manager
readonly PKG_MGR_PACMAN="pacman"                      # Arch Linux package manager
readonly PKG_MGR_ZYPPER="zypper"                      # openSUSE package manager
readonly PKG_MGR_UNKNOWN="unknown"                    # Unknown/unsupported package manager

# =============================================================================
# Terminal Colors
# =============================================================================
# ANSI color codes for terminal output formatting
readonly COLOR_RESET="\033[0m"                        # Reset all attributes
readonly COLOR_RED="\033[0;31m"                       # Red text
readonly COLOR_GREEN="\033[0;32m"                     # Green text
readonly COLOR_YELLOW="\033[0;33m"                    # Yellow text
readonly COLOR_BLUE="\033[0;34m"                      # Blue text
readonly COLOR_MAGENTA="\033[0;35m"                   # Magenta text
readonly COLOR_CYAN="\033[0;36m"                      # Cyan text
readonly COLOR_WHITE="\033[0;37m"                     # White text
readonly COLOR_BOLD="\033[1m"                         # Bold text
readonly COLOR_DIM="\033[2m"                          # Dim text
readonly COLOR_UNDERLINE="\033[4m"                    # Underlined text

# =============================================================================
# Derived Terminal Colors
# =============================================================================
# Colors derived from base color constants
readonly COLOR_BOLD_RED="${COLOR_BOLD}${COLOR_RED}"   # Bold red text (derived)
readonly COLOR_BOLD_GREEN="${COLOR_BOLD}${COLOR_GREEN}" # Bold green text (derived)
readonly COLOR_BOLD_YELLOW="${COLOR_BOLD}${COLOR_YELLOW}" # Bold yellow text (derived)
readonly COLOR_BOLD_BLUE="${COLOR_BOLD}${COLOR_BLUE}" # Bold blue text (derived)

# =============================================================================
# Derived Timeout Values
# =============================================================================
# Timeout values derived from base constants
readonly EXTENDED_TIMEOUT=$((DEFAULT_COMMAND_TIMEOUT * 2)) # Extended timeout for long operations
readonly SHORT_TIMEOUT=$((DEFAULT_COMMAND_TIMEOUT / 4))    # Short timeout for quick operations

# =============================================================================
# File and Path Constants
# =============================================================================
# Default file paths and configuration locations
readonly DEFAULT_CONFIG_FILE="mvnimble.config"        # Default configuration file name
readonly DEFAULT_REPORT_DIR="./results"               # Default directory for reports
readonly DEFAULT_LOG_FILE="mvnimble.log"              # Default log file name
readonly TEMP_FILE_PREFIX="mvnimble-tmp"              # Prefix for temporary files
readonly POM_BACKUP_SUFFIX=".mvnimble.bak"            # Suffix for pom.xml backups