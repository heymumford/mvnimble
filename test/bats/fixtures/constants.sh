#!/bin/bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# constants.sh - Test constants for fixtures

# Color codes for output
COLOR_RED="31"
COLOR_GREEN="32"
COLOR_YELLOW="33"
COLOR_BLUE="34"
COLOR_MAGENTA="35"
COLOR_CYAN="36"
COLOR_RESET="0"

# Exit codes
EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_INVALID_ARGS=2
EXIT_DEPENDENCY_MISSING=3
EXIT_PERMISSION_DENIED=4

# Default values
DEFAULT_TIMEOUT=30
DEFAULT_RETRIES=3
DEFAULT_THREADS=4

# Test-specific constants
TEST_PROJECT_DIR="/tmp/test-project"
TEST_CONFIG_FILE="config.json"
TEST_LOG_FILE="test.log"