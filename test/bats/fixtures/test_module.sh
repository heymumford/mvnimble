#!/bin/bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# test_module.sh - Test module
#
# This file intentionally contains examples of both good and bad bash practices
# related to function declaration in shell scripts. It is used by the MVNimble
# test suite to validate various shell scripting standards and practices.
#
# ANTIPATTERN: Inconsistent function declaration style
# - Shell scripts allow functions to be declared with or without the 'function' keyword
# - Mixing these styles in a single codebase creates inconsistency and maintenance challenges
# - The style using 'function' keyword is more explicit, enhancing readability
# - MVNimble ADR (Architecture Decision Record) 001 specifies using the 'function' keyword consistently
#
# ANTIPATTERN: Missing local variable declarations
# - Variables not declared with 'local' leak into the global scope
# - This can lead to unexpected behavior and difficult-to-trace bugs
#
# CORRECT PATTERN: 
# - Consistent use of 'function' keyword for all function declarations
# - All function-scoped variables declared with 'local' keyword
# - Clear function purpose and concise documentation

# Source constants
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/constants.sh"

# ANTIPATTERN: Inconsistently declared function (missing 'function' keyword)
# This violates MVNimble's shell architecture standards which require
# the explicit use of the 'function' keyword for all function declarations.
incorrect_function() {
  # INTENTIONAL BAD PRACTICE: No 'function' keyword in declaration
  # INTENTIONAL BAD PRACTICE: No 'local' keyword for variable scoping
  message="This will pollute the namespace"
  echo "This is incorrect: $message"
  return 0
}

# CORRECT PATTERN: Properly declared function with 'function' keyword
# This follows MVNimble shell architecture standards for consistent
# function declarations and proper variable scoping.
function correct_function() {
  # Variables correctly scoped with 'local' keyword
  local message="This is correct"
  echo "$message"
  return 0
}
