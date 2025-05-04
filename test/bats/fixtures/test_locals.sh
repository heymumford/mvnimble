#!/bin/bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# test_locals.sh - Test module for local variables
#
# This file intentionally contains examples of both good and bad bash practices
# related to variable scoping. It is used by various tests to validate MVNimble's
# ability to detect and report on potential issues in shell scripts.
#
# ANTIPATTERN: Non-local variable declarations in functions
# - Variables declared without 'local' keyword pollute the global namespace
# - These variables persist after function calls, potentially causing side effects
# - They can accidentally overwrite important global variables
# - This creates difficulties in debugging, maintaining, and reusing code
#
# CORRECT PATTERN: Proper use of 'local' variables
# - Variables declared with 'local' are scoped to the function only
# - They do not affect or interfere with variables outside the function
# - This creates more predictable, modular, and maintainable code

# Source constants
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/constants.sh"

# ANTIPATTERN: Function with non-local variables
# This function demonstrates the problematic pattern of using variables
# without the 'local' keyword, which causes them to persist in the global
# scope even after the function returns.
function bad_function() {
  # INTENTIONAL BAD PRACTICE: These variables will pollute the global namespace
  message="This will pollute the namespace"
  count=5
  echo "$message repeated $count times"
  return 0
}

# CORRECT PATTERN: Function using local variables properly
# This function demonstrates the correct pattern of using the 'local' keyword
# to scope variables to the function, preventing namespace pollution.
function good_function() {
  local message="This is properly scoped"
  local count=3
  echo "$message repeated $count times"
  return 0
}
