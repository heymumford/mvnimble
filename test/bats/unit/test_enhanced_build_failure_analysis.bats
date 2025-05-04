#!/usr/bin/env bats
# test_enhanced_build_failure_analysis.bats
# Unit tests for enhanced build failure analysis features
#
# These tests verify the enhanced functionality of build failure analysis
# including detailed error categorization and recommendations
#
# Author: MVNimble Team
# Version: 1.0.0

load "../test_helper.bash"
load "../helpers/bats-assert/load.bash"

# Define assert_success and assert_failure if they don't exist
assert_success() {
  if [ "$status" -ne 0 ]; then
    echo "Expected success (status 0), got status: $status" >&2
    return 1
  fi
  return 0
}

assert_failure() {
  if [ "$status" -eq 0 ]; then
    echo "Expected failure (non-zero status), got status: $status" >&2
    return 1
  fi
  return 0
}

# Define assert command
assert() {
  if ! "$@"; then
    echo "Assertion failed: $*" >&2
    return 1
  fi
  return 0
}

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
SOURCE_FILE="${ROOT_DIR}/src/lib/modules/real_time_analyzer.sh"
TEST_TEMP_DIR="${BATS_TEST_TMPDIR}"

setup() {
  # Create temporary directory for test artifacts
  mkdir -p "${TEST_TEMP_DIR}/metrics"
  
  # Source the module to test
  source "${ROOT_DIR}/src/lib/modules/constants.sh"
  source "${ROOT_DIR}/src/lib/modules/common.sh"
  source "${SOURCE_FILE}"
}

teardown() {
  # Clean up test artifacts
  rm -rf "${TEST_TEMP_DIR}"
}

# Test for enhanced error categorization
@test "categorize_build_errors provides detailed error categories" {
  # Create a test build log file with various error types
  cat > "${TEST_TEMP_DIR}/build.log" << EOF
[ERROR] /project/src/main/java/com/example/App.java:[15,34] package org.example.missing does not exist
[ERROR] /project/src/main/java/com/example/Utils.java:[22,45] cannot find symbol: class TestClass
[ERROR] /project/src/main/java/com/example/Helper.java:[8,34] has private access in org.example.SomeClass
[ERROR] /project/src/test/java/com/example/AppTest.java:[42,15] incompatible types: String cannot be converted to Integer
[ERROR] /project/src/main/java/com/example/App.java:[10,5] non-static method cannot be referenced from a static context
[ERROR] /project/src/main/java/com/example/Config.java:[25,12] variable userId might not have been initialized
[ERROR] Java heap space
[ERROR] Out of memory: Java heap space
[ERROR] Tests run: 5, Failures: 2, Errors: 1, Skipped: 0
EOF

  # Run the enhanced categorization
  run categorize_build_errors "${TEST_TEMP_DIR}/build.log"
  assert_success
  
  # Output should have detailed error categories
  assert_output --partial "DEPENDENCY_ERRORS="
  assert_output --partial "SYMBOL_ERRORS="
  assert_output --partial "ACCESS_ERRORS="
  assert_output --partial "TYPE_ERRORS="
  assert_output --partial "CONTEXT_ERRORS="
  assert_output --partial "INITIALIZATION_ERRORS="
  assert_output --partial "MEMORY_ERRORS="
  assert_output --partial "TEST_FAILURES="
  
  # Check that each category has the correct count
  assert_output --regexp "DEPENDENCY_ERRORS=[\"']?1[\"']?"
  assert_output --regexp "SYMBOL_ERRORS=[\"']?1[\"']?"
  assert_output --regexp "ACCESS_ERRORS=[\"']?1[\"']?"
  assert_output --regexp "TYPE_ERRORS=[\"']?1[\"']?"
  assert_output --regexp "CONTEXT_ERRORS=[\"']?1[\"']?"
  assert_output --regexp "INITIALIZATION_ERRORS=[\"']?1[\"']?"
  assert_output --regexp "MEMORY_ERRORS=[\"']?2[\"']?"
  assert_output --regexp "TEST_FAILURES=[\"']?3[\"']?"
}

# Test for build phase detection
@test "detect_build_phase identifies Maven build phases" {
  # Create a test build log with different phases
  cat > "${TEST_TEMP_DIR}/build.log" << EOF
[INFO] --- enforcer:3.3.0:enforce (enforce) @ CheckvoxApp ---
[INFO] Rule 0: org.apache.maven.enforcer.rules.version.RequireMavenVersion passed
[INFO] 
[INFO] --- resources:3.3.1:resources (default-resources) @ CheckvoxApp ---
[INFO] Copying 10 resources from src/main/resources to target/classes
[INFO] 
[INFO] --- compiler:3.14.0:compile (default-compile) @ CheckvoxApp ---
[ERROR] /project/src/main/java/com/example/App.java:[15,34] package org.example.missing does not exist
[INFO] 
[INFO] --- resources:3.3.1:testResources (default-testResources) @ CheckvoxApp ---
[INFO] Copying 5 resources from src/test/resources to target/test-classes
[INFO] 
[INFO] --- compiler:3.14.0:testCompile (default-testCompile) @ CheckvoxApp ---
[ERROR] /project/src/test/java/com/example/AppTest.java:[42,15] incompatible types
[INFO] 
[INFO] --- surefire:3.0.0:test (default-test) @ CheckvoxApp ---
[ERROR] Tests run: 5, Failures: 2, Errors: 1, Skipped: 0
EOF

  # Run the phase detection
  run detect_build_phase "${TEST_TEMP_DIR}/build.log"
  assert_success
  
  # Output should have detected phases with their timing
  assert_output --partial "VALIDATION_PHASE="
  assert_output --partial "COMPILATION_PHASE="
  assert_output --partial "TEST_COMPILATION_PHASE="
  assert_output --partial "TEST_EXECUTION_PHASE="
  
  # Check that each phase has a boolean value
  assert_output --regexp "VALIDATION_PHASE=[\"']?true[\"']?"
  assert_output --regexp "COMPILATION_PHASE=[\"']?true[\"']?"
  assert_output --regexp "TEST_COMPILATION_PHASE=[\"']?true[\"']?"
  assert_output --regexp "TEST_EXECUTION_PHASE=[\"']?true[\"']?"
  assert_output --regexp "PACKAGING_PHASE=[\"']?false[\"']?"
}

# Test for enhanced build recommendations
@test "generate_enhanced_build_recommendations provides actionable suggestions" {
  # Create a test build log with various issues
  cat > "${TEST_TEMP_DIR}/build.log" << EOF
[ERROR] /project/src/main/java/com/example/App.java:[15,34] package org.example.missing does not exist
[ERROR] /project/src/main/java/com/example/Utils.java:[22,45] package org.another.missing does not exist
[ERROR] Java heap space
[ERROR] Out of memory: Java heap space
[ERROR] Tests run: 15, Failures: 8, Errors: 3, Skipped: 0
EOF

  # Create metrics file with high memory usage
  cat > "${TEST_TEMP_DIR}/metrics/system.csv" << EOF
timestamp,cpu_usage,memory_usage,disk_io,network_io,test_count,test_failures,active_threads
1620000001,25.5,1024,100,200,0,0,10
1620000002,35.8,2048,150,220,0,0,12
1620000003,85.2,7168,200,240,0,0,25
1620000004,30.1,2560,180,230,0,0,13
EOF

  # Run the recommendations generator
  run generate_enhanced_build_recommendations "${TEST_TEMP_DIR}/build.log" "${TEST_TEMP_DIR}/metrics" "${TEST_TEMP_DIR}/recommendations.md"
  assert_success
  
  # Verify the recommendations file was created
  assert [ -f "${TEST_TEMP_DIR}/recommendations.md" ]
  
  # Check content of recommendations file
  run cat "${TEST_TEMP_DIR}/recommendations.md"
  
  # Should include dependency recommendations section
  assert_output --partial "## Dependency Recommendations"
  
  # Should include memory recommendations section
  assert_output --partial "## Memory Recommendations"
  
  # Should include test recommendations section
  assert_output --partial "## Test Recommendations"
  
  # Should include infrastructure recommendations section
  assert_output --partial "## Build Infrastructure Recommendations"
}

# Test for correlation between errors and phases
@test "correlate_errors_with_phases links errors to build phases" {
  # Create a test build log with errors in different phases
  cat > "${TEST_TEMP_DIR}/build.log" << EOF
[INFO] --- enforcer:3.3.0:enforce (enforce) @ CheckvoxApp ---
[INFO] Rule 0: org.apache.maven.enforcer.rules.version.RequireMavenVersion passed
[ERROR] Rule 2: org.apache.maven.enforcer.rules.dependency.DependencyConvergence failed
[INFO] 
[INFO] --- compiler:3.14.0:compile (default-compile) @ CheckvoxApp ---
[ERROR] /project/src/main/java/com/example/App.java:[15,34] package org.example.missing does not exist
[INFO] 
[INFO] --- compiler:3.14.0:testCompile (default-testCompile) @ CheckvoxApp ---
[ERROR] /project/src/test/java/com/example/AppTest.java:[42,15] incompatible types
[INFO] 
[INFO] --- surefire:3.0.0:test (default-test) @ CheckvoxApp ---
[ERROR] Tests run: 5, Failures: 2, Errors: 1, Skipped: 0
EOF

  # Run the correlation
  run correlate_errors_with_phases "${TEST_TEMP_DIR}/build.log"
  assert_success
  
  # Should map errors to phases
  assert_output --partial "VALIDATION_ERRORS="
  assert_output --partial "COMPILATION_ERRORS="
  assert_output --partial "TEST_COMPILATION_ERRORS="
  assert_output --partial "TEST_EXECUTION_ERRORS="
  
  # Check error counts by phase
  assert_output --regexp "VALIDATION_ERRORS=[\"']?1[\"']?"
  assert_output --regexp "COMPILATION_ERRORS=[\"']?1[\"']?"
  assert_output --regexp "TEST_COMPILATION_ERRORS=[\"']?1[\"']?"
  assert_output --regexp "TEST_EXECUTION_ERRORS=[\"']?4[\"']?" # 3 failures + 1 error = 4
}

# Test for enhanced build failure analysis report
@test "enhanced_build_failure_analysis generates comprehensive report" {
  # Create test files
  cat > "${TEST_TEMP_DIR}/build.log" << EOF
[INFO] --- enforcer:3.3.0:enforce (enforce) @ CheckvoxApp ---
[ERROR] Rule 2: org.apache.maven.enforcer.rules.dependency.DependencyConvergence failed
[INFO] 
[INFO] --- compiler:3.14.0:compile (default-compile) @ CheckvoxApp ---
[ERROR] /project/src/main/java/com/example/App.java:[15,34] package org.example.missing does not exist
[ERROR] /project/src/main/java/com/example/Utils.java:[22,45] cannot find symbol: class TestClass
[INFO] 
[INFO] --- compiler:3.14.0:testCompile (default-testCompile) @ CheckvoxApp ---
[ERROR] /project/src/test/java/com/example/AppTest.java:[42,15] incompatible types
[ERROR] Java heap space
EOF

  # Create metrics file
  cat > "${TEST_TEMP_DIR}/metrics/system.csv" << EOF
timestamp,cpu_usage,memory_usage,disk_io,network_io,test_count,test_failures,active_threads
1620000001,25.5,1024,100,200,0,0,10
1620000002,75.8,6144,150,220,0,0,12
EOF

  # Run the enhanced analysis
  run enhanced_build_failure_analysis "${TEST_TEMP_DIR}/build.log" "${TEST_TEMP_DIR}/metrics" "${TEST_TEMP_DIR}/enhanced_report.md"
  assert_success
  
  # Verify the report was created
  assert [ -f "${TEST_TEMP_DIR}/enhanced_report.md" ]
  
  # Check content of report
  run cat "${TEST_TEMP_DIR}/enhanced_report.md"
  
  # Should include error categorization
  assert_output --partial "## Error Categories"
  
  # Should include build phase analysis
  assert_output --partial "## Build Phase Analysis"
  
  # Should include resource correlation
  assert_output --partial "## Resource Correlation"
  
  # Should include actionable recommendations
  assert_output --partial "## Recommendations"
  
  # Should include key sections
  assert_output --partial "## Summary"
}

# Test for memory issue detection
@test "detect_memory_issues identifies memory-related problems" {
  # Create a test build log with memory issues
  cat > "${TEST_TEMP_DIR}/build.log" << EOF
[ERROR] Java heap space
[ERROR] GC overhead limit exceeded
[ERROR] OutOfMemoryError: Java heap space
[ERROR] OutOfMemoryError: GC overhead limit exceeded
[ERROR] OutOfMemoryError: Metaspace
[ERROR] Out of memory: Kill process or sacrifice child
EOF

  # Run memory issue detection
  run detect_memory_issues "${TEST_TEMP_DIR}/build.log"
  assert_success
  
  # Should identify different types of memory issues
  assert_output --partial "HEAP_SPACE_ERRORS="
  assert_output --partial "GC_OVERHEAD_ERRORS="
  assert_output --partial "METASPACE_ERRORS="
  assert_output --partial "SYSTEM_OOM_ERRORS="
  
  # Check counts for each type
  assert_output --regexp "HEAP_SPACE_ERRORS=[\"']?2[\"']?"
  assert_output --regexp "GC_OVERHEAD_ERRORS=[\"']?2[\"']?"
  assert_output --regexp "METASPACE_ERRORS=[\"']?1[\"']?"
  assert_output --regexp "SYSTEM_OOM_ERRORS=[\"']?1[\"']?"
}

# Test for dependency issue detection
@test "analyze_dependency_issues extracts missing dependencies" {
  # Create a test build log with dependency issues
  cat > "${TEST_TEMP_DIR}/build.log" << EOF
[ERROR] /project/src/main/java/com/example/App.java:[15,34] package org.example.missing does not exist
[ERROR] /project/src/main/java/com/example/Utils.java:[22,45] package org.another.missing does not exist
[ERROR] package com.google.common.collect does not exist
[ERROR] /project/src/main/java/com/example/Config.java:[5,12] static import only from classes and interfaces
[ERROR] /project/src/main/java/com/example/App.java:[8,34] cannot find symbol: class Foo
[ERROR] Rule 2: org.apache.maven.enforcer.rules.dependency.DependencyConvergence failed
EOF

  # Run dependency analysis
  run analyze_dependency_issues "${TEST_TEMP_DIR}/build.log"
  assert_success
  
  # Should extract missing packages
  assert_output --partial "MISSING_PACKAGES="
  assert_output --partial "org.example.missing"
  assert_output --partial "org.another.missing"
  assert_output --partial "com.google.common.collect"
  
  # Should count dependency convergence issues
  assert_output --regexp "CONVERGENCE_ISSUES=[\"']?1[\"']?"
  
  # Should identify related libraries
  assert_output --partial "LIKELY_DEPENDENCIES="
  # Guava should be identified from com.google.common.collect
  assert_output --partial "com.google.guava:guava"
}

# Test for the complete build failure analysis workflow
@test "complete build failure analysis workflow works end-to-end" {
  # Create test files
  cat > "${TEST_TEMP_DIR}/build.log" << EOF
[INFO] --- enforcer:3.3.0:enforce (enforce) @ CheckvoxApp ---
[ERROR] Rule 2: org.apache.maven.enforcer.rules.dependency.DependencyConvergence failed
[INFO] 
[INFO] --- compiler:3.14.0:compile (default-compile) @ CheckvoxApp ---
[ERROR] /project/src/main/java/com/example/App.java:[15,34] package org.example.missing does not exist
[ERROR] /project/src/main/java/com/example/Utils.java:[22,45] cannot find symbol: class TestClass
[INFO] 
[INFO] --- compiler:3.14.0:testCompile (default-testCompile) @ CheckvoxApp ---
[ERROR] /project/src/test/java/com/example/AppTest.java:[42,15] incompatible types
[ERROR] Java heap space
EOF

  # Create metrics file
  cat > "${TEST_TEMP_DIR}/metrics/system.csv" << EOF
timestamp,cpu_usage,memory_usage,disk_io,network_io,test_count,test_failures,active_threads
1620000001,25.5,1024,100,200,0,0,10
1620000002,75.8,6144,150,220,0,0,12
EOF

  # Run the complete workflow
  run analyze_build_failure "${TEST_TEMP_DIR}/build.log" "${TEST_TEMP_DIR}/metrics" "${TEST_TEMP_DIR}/report.md"
  assert_success
  run generate_enhanced_build_recommendations "${TEST_TEMP_DIR}/build.log" "${TEST_TEMP_DIR}/metrics" "${TEST_TEMP_DIR}/recommendations.md"
  assert_success
  
  # Both files should exist
  assert [ -f "${TEST_TEMP_DIR}/report.md" ]
  assert [ -f "${TEST_TEMP_DIR}/recommendations.md" ]
  
  # Check that the report has a recommendations section
  run grep -q "Recommendations" "${TEST_TEMP_DIR}/report.md"
  assert_success
}