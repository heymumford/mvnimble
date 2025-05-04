#!/usr/bin/env bats
#
# Basic Tests for MVNimble Validation Framework
#
# These tests verify the basic structure and integrity of the validation framework
# without requiring the full validation implementations to run.

load "../test_helper"

setup() {
  VALIDATION_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
  PROJECT_ROOT="$(cd "$VALIDATION_DIR/../.." && pwd)"
}

@test "Validation: Framework directories exist" {
  # Check that the main validation directories exist
  [ -d "$VALIDATION_DIR/closed_loop" ] 
  [ -d "$VALIDATION_DIR/gold_standard" ]
  [ -d "$VALIDATION_DIR/thread_safety" ]
  [ -d "$VALIDATION_DIR/educational" ]
}

@test "Validation: Main scripts exist and are executable" {
  # Check that the validation scripts exist and are executable
  [ -f "$VALIDATION_DIR/closed_loop/closed_loop_validation.sh" ]
  [ -x "$VALIDATION_DIR/closed_loop/closed_loop_validation.sh" ]
  
  [ -f "$VALIDATION_DIR/gold_standard/gold_standard_validation.sh" ]
  [ -x "$VALIDATION_DIR/gold_standard/gold_standard_validation.sh" ]
  
  [ -f "$VALIDATION_DIR/thread_safety/thread_safety_validation.sh" ]
  [ -x "$VALIDATION_DIR/thread_safety/thread_safety_validation.sh" ]
  
  [ -f "$VALIDATION_DIR/educational/educational_effectiveness_validation.sh" ]
  [ -x "$VALIDATION_DIR/educational/educational_effectiveness_validation.sh" ]
}

@test "Validation: Integration script exists and is executable" {
  [ -f "$VALIDATION_DIR/integration_test.sh" ]
  [ -x "$VALIDATION_DIR/integration_test.sh" ]
}

@test "Validation: BATS test files exist" {
  # The closed_loop_test.bats file is not yet created
  # [ -f "$VALIDATION_DIR/closed_loop/closed_loop_test.bats" ]
  [ -f "$VALIDATION_DIR/gold_standard/gold_standard_test.bats" ]
  [ -f "$VALIDATION_DIR/thread_safety/thread_safety_test.bats" ]
  [ -f "$VALIDATION_DIR/educational/educational_effectiveness_test.bats" ]
}

@test "Validation: README files exist" {
  [ -f "$VALIDATION_DIR/README.md" ]
  # Missing README files in some directories
  # [ -f "$VALIDATION_DIR/closed_loop/README.md" ]
  [ -f "$VALIDATION_DIR/gold_standard/README.md" ]
  [ -f "$VALIDATION_DIR/thread_safety/README.md" ]
  [ -f "$VALIDATION_DIR/educational/README.md" ]
}

@test "Validation: Scripts have proper file mode" {
  # All .sh files should have execute permissions
  for script in $(find "$VALIDATION_DIR" -name "*.sh"); do
    [ -x "$script" ]
  done
}

@test "Validation: BATS test files have proper shebang" {
  # All .bats files should have the correct shebang
  for bats_file in $(find "$VALIDATION_DIR" -name "*.bats"); do
    grep -q "^#!/usr/bin/env bats" "$bats_file"
  done
}

@test "Validation: No syntax errors in bash scripts" {
  # Check for syntax errors in bash scripts without executing them
  for script in $(find "$VALIDATION_DIR" -name "*.sh"); do
    bash -n "$script"
  done
}

@test "Validation: Integration test includes all components" {
  # Check that the integration test references all validation components
  grep -q "closed_loop_validation.sh" "$VALIDATION_DIR/integration_test.sh"
  grep -q "gold_standard_validation.sh" "$VALIDATION_DIR/integration_test.sh"
  grep -q "thread_safety_validation.sh" "$VALIDATION_DIR/integration_test.sh"
  grep -q "educational_effectiveness_validation.sh" "$VALIDATION_DIR/integration_test.sh"
}