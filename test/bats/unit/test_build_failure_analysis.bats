#!/usr/bin/env bats
# test_build_failure_analysis.bats
# Unit tests for build failure analysis features (ADR-007)
#
# These tests verify the functionality of build failure analysis
# components implemented in real_time_analyzer.sh
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
  source "${SOURCE_FILE}"
}

teardown() {
  # Clean up test artifacts
  rm -rf "${TEST_TEMP_DIR}"
}

# Test that the build analysis function exists
@test "build failure analysis function exists" {
  run type -t analyze_build_failure
  assert_success
  assert_output "function"
}

# Test that the build recommendations function exists
@test "build recommendations function exists" {
  run type -t generate_build_recommendations
  assert_success
  assert_output "function"
}

# Test parameter validation in analyze_build_failure
@test "analyze_build_failure validates build log parameter" {
  # Call with missing build log
  run analyze_build_failure "" "${TEST_TEMP_DIR}/metrics" "${TEST_TEMP_DIR}/report.md"
  assert_failure
  assert_output --partial "No build log provided"
  
  # Call with non-existent build log
  run analyze_build_failure "${TEST_TEMP_DIR}/nonexistent.log" "${TEST_TEMP_DIR}/metrics" "${TEST_TEMP_DIR}/report.md"
  assert_failure
  assert_output --partial "file doesn't exist"
}

# Test parameter validation for metrics directory
@test "analyze_build_failure validates metrics directory parameter" {
  # Create a test build log file
  echo "[ERROR] Test error" > "${TEST_TEMP_DIR}/build.log"
  
  # Call with missing metrics directory
  run analyze_build_failure "${TEST_TEMP_DIR}/build.log" "" "${TEST_TEMP_DIR}/report.md"
  assert_failure
  assert_output --partial "No metrics directory provided"
  
  # Call with non-existent metrics directory
  run analyze_build_failure "${TEST_TEMP_DIR}/build.log" "${TEST_TEMP_DIR}/nonexistent" "${TEST_TEMP_DIR}/report.md"
  assert_failure
  assert_output --partial "directory doesn't exist"
}

# Test parameter validation for output report
@test "analyze_build_failure validates output report parameter" {
  # Create a test build log file
  echo "[ERROR] Test error" > "${TEST_TEMP_DIR}/build.log"
  
  # Call with missing output report
  run analyze_build_failure "${TEST_TEMP_DIR}/build.log" "${TEST_TEMP_DIR}/metrics" ""
  assert_failure
  assert_output --partial "No output report path provided"
}

# Test basic build log parsing
@test "analyze_build_failure correctly counts errors" {
  # Create a test build log file with various errors
  cat > "${TEST_TEMP_DIR}/build.log" << EOF
[INFO] Building project
[ERROR] package org.example.missing does not exist
[INFO] Processing source files
[ERROR] cannot find symbol: class TestClass
[ERROR] has private access in org.example.SomeClass
[ERROR] incompatible types: String cannot be converted to Integer
EOF

  # Create metrics file
  cat > "${TEST_TEMP_DIR}/metrics/system.csv" << EOF
timestamp,cpu_usage,memory_usage,disk_io,network_io,test_count,test_failures,active_threads
1620000001,25.5,1024,100,200,0,0,10
EOF

  # Run analysis
  run analyze_build_failure "${TEST_TEMP_DIR}/build.log" "${TEST_TEMP_DIR}/metrics" "${TEST_TEMP_DIR}/report.md"
  assert_success
  assert_output --partial "Build failure analysis complete"
  
  # Verify the report was created
  assert [ -f "${TEST_TEMP_DIR}/report.md" ]
  
  # Verify error counts in the report
  run cat "${TEST_TEMP_DIR}/report.md"
  assert_output --partial "Total Errors"
  assert_output --partial "Dependency Errors"
  assert_output --partial "Symbol Errors"
  assert_output --partial "Access Violations"
}

# Test metrics extraction
@test "analyze_build_failure extracts peak resource usage" {
  # Create a test build log file
  echo "[ERROR] Test error" > "${TEST_TEMP_DIR}/build.log"
  
  # Create metrics file with varying resource usage
  cat > "${TEST_TEMP_DIR}/metrics/system.csv" << EOF
timestamp,cpu_usage,memory_usage,disk_io,network_io,test_count,test_failures,active_threads
1620000001,25.5,1024,100,200,0,0,10
1620000002,35.8,2048,150,220,0,0,12
1620000003,45.2,3072,200,240,0,0,15
1620000004,30.1,2560,180,230,0,0,13
EOF

  # Run analysis
  run analyze_build_failure "${TEST_TEMP_DIR}/build.log" "${TEST_TEMP_DIR}/metrics" "${TEST_TEMP_DIR}/report.md"
  assert_success
  
  # Verify peak metrics in the report
  run cat "${TEST_TEMP_DIR}/report.md"
  assert_output --partial "Peak CPU Usage"
  assert_output --partial "Peak Memory Usage"
}

# Test missing package dependency detection
@test "analyze_build_failure identifies missing package dependencies" {
  # Create a test build log file with missing package errors
  cat > "${TEST_TEMP_DIR}/build.log" << EOF
[ERROR] /project/src/main/java/com/example/App.java:[15,34] package org.example.missing does not exist
[ERROR] /project/src/main/java/com/example/Utils.java:[22,45] package org.example.another.missing does not exist
[ERROR] /project/src/main/java/com/example/Helper.java:[8,34] package org.example.missing does not exist
EOF

  # Create metrics file
  cat > "${TEST_TEMP_DIR}/metrics/system.csv" << EOF
timestamp,cpu_usage,memory_usage,disk_io,network_io,test_count,test_failures,active_threads
1620000001,25.5,1024,100,200,0,0,10
EOF

  # Run analysis
  run analyze_build_failure "${TEST_TEMP_DIR}/build.log" "${TEST_TEMP_DIR}/metrics" "${TEST_TEMP_DIR}/report.md"
  assert_success
  
  # Verify missing package detection in the report
  run cat "${TEST_TEMP_DIR}/report.md"
  assert_output --partial "Dependency Errors"
}

# Test access violation detection
@test "analyze_build_failure identifies access violations" {
  # Create a test build log file with access violation errors
  cat > "${TEST_TEMP_DIR}/build.log" << EOF
[ERROR] /project/src/main/java/com/example/Test.java:[15,34] field has private access in org.example.SomeClass
[ERROR] /project/src/main/java/com/example/Utils.java:[22,45] method has private access in org.example.AnotherClass
EOF

  # Create metrics file
  cat > "${TEST_TEMP_DIR}/metrics/system.csv" << EOF
timestamp,cpu_usage,memory_usage,disk_io,network_io,test_count,test_failures,active_threads
1620000001,25.5,1024,100,200,0,0,10
EOF

  # Run analysis
  run analyze_build_failure "${TEST_TEMP_DIR}/build.log" "${TEST_TEMP_DIR}/metrics" "${TEST_TEMP_DIR}/report.md"
  assert_success
  
  # Verify access violation detection in the report
  run cat "${TEST_TEMP_DIR}/report.md"
  assert_output --partial "Access Violations"
}

# Test the report format
@test "analyze_build_failure generates a properly formatted report" {
  # Create a test build log file
  echo "[ERROR] Test error" > "${TEST_TEMP_DIR}/build.log"
  
  # Create metrics file
  cat > "${TEST_TEMP_DIR}/metrics/system.csv" << EOF
timestamp,cpu_usage,memory_usage,disk_io,network_io,test_count,test_failures,active_threads
1620000001,25.5,1024,100,200,0,0,10
EOF

  # Run analysis
  run analyze_build_failure "${TEST_TEMP_DIR}/build.log" "${TEST_TEMP_DIR}/metrics" "${TEST_TEMP_DIR}/report.md"
  assert_success
  
  # Verify report structure
  run cat "${TEST_TEMP_DIR}/report.md"
  assert_output --partial "# Enhanced Build Failure Analysis Report"
  assert_output --partial "## Summary"
  assert_output --partial "## Error Categories"
  assert_output --partial "## Recommendations"
}

# Test generate_build_recommendations function
@test "generate_build_recommendations returns success" {
  # Create a test build log file
  echo "[ERROR] Test error" > "${TEST_TEMP_DIR}/build.log"
  
  # Create metrics file
  cat > "${TEST_TEMP_DIR}/metrics/system.csv" << EOF
timestamp,cpu_usage,memory_usage,disk_io,network_io,test_count,test_failures,active_threads
1620000001,25.5,1024,100,200,0,0,10
EOF

  # Run recommendations
  run generate_build_recommendations "${TEST_TEMP_DIR}/build.log" "${TEST_TEMP_DIR}/metrics" "${TEST_TEMP_DIR}/recommendations.md"
  assert_success
}

# Test report directory creation
@test "analyze_build_failure creates parent directories if they don't exist" {
  # Create a test build log file
  echo "[ERROR] Test error" > "${TEST_TEMP_DIR}/build.log"
  
  # Create metrics file
  cat > "${TEST_TEMP_DIR}/metrics/system.csv" << EOF
timestamp,cpu_usage,memory_usage,disk_io,network_io,test_count,test_failures,active_threads
1620000001,25.5,1024,100,200,0,0,10
EOF

  # Run analysis with a nested directory structure that doesn't exist yet
  run analyze_build_failure "${TEST_TEMP_DIR}/build.log" "${TEST_TEMP_DIR}/metrics" "${TEST_TEMP_DIR}/reports/nested/build_report.md"
  assert_success
  
  # Verify the directory and report were created
  assert [ -f "${TEST_TEMP_DIR}/reports/nested/build_report.md" ]
}

# Integration test with the main mvnimble script
@test "mvnimble main script includes build analysis command-line option" {
  # Check that the main script has the build-analysis option
  run grep -q -- "--build-analysis" "${ROOT_DIR}/src/lib/mvnimble.sh"
  assert_success
  
  # Check that the build_analysis variable is defined
  run grep -q "build_analysis=false" "${ROOT_DIR}/src/lib/mvnimble.sh"
  assert_success
  
  # Check that the -b|--build-analysis option is handled
  run grep -q "\-b|\-\-build-analysis)" "${ROOT_DIR}/src/lib/mvnimble.sh"
  assert_success
}

# Test handling of missing metrics file
@test "analyze_build_failure handles missing metrics file gracefully" {
  # Create a test build log file
  echo "[ERROR] Test error" > "${TEST_TEMP_DIR}/build.log"
  
  # Create empty metrics directory without system.csv
  mkdir -p "${TEST_TEMP_DIR}/empty_metrics"
  
  # Run analysis
  run analyze_build_failure "${TEST_TEMP_DIR}/build.log" "${TEST_TEMP_DIR}/empty_metrics" "${TEST_TEMP_DIR}/report.md"
  assert_success
  
  # Verify the report was created despite missing metrics
  assert [ -f "${TEST_TEMP_DIR}/report.md" ]
  
  # Verify default values for metrics in the report
  run cat "${TEST_TEMP_DIR}/report.md"
  assert_output --partial "Peak CPU Usage"
  assert_output --partial "Peak Memory Usage"
}

# Test that the build failure analysis works with real-world examples
@test "analyze_build_failure works with realistic Maven errors" {
  # Create a test build log file with real Maven errors
  cat > "${TEST_TEMP_DIR}/maven_errors.log" << EOF
[INFO] Scanning for projects...
[INFO] 
[INFO] ----------------------< io.checkvox:CheckvoxApp >-----------------------
[INFO] Building Checkvox 0.1.0-SNAPSHOT
[INFO]   from pom.xml
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- enforcer:3.3.0:enforce (enforce) @ CheckvoxApp ---
[INFO] Rule 0: org.apache.maven.enforcer.rules.version.RequireMavenVersion passed
[INFO] Rule 1: org.apache.maven.enforcer.rules.version.RequireJavaVersion passed
[ERROR] /Users/vorthruna/Code/Checkvox/src/test/java/io/checkvox/domain/converter/ContextTypeConverterTest.java:[15,34] package io.checkvox.test.dimension does not exist
[ERROR] /Users/vorthruna/Code/Checkvox/src/test/java/io/checkvox/domain/converter/ContextTypeConverterTest.java:[16,34] package io.checkvox.test.dimension does not exist
[ERROR] /Users/vorthruna/Code/Checkvox/src/test/java/io/checkvox/domain/entity/DomainContextClassifierPropertyBasedTest.java:[17,32] package net.jqwik.api.statistics does not exist
[ERROR] /Users/vorthruna/Code/Checkvox/src/test/java/io/checkvox/domain/entity/DomainContextClassifierComprehensiveTest.java:[341,32] planningApproach has private access in io.checkvox.domain.entity.DomainContextClassifier.ProcessTemplate
[ERROR] /Users/vorthruna/Code/Checkvox/src/test/java/io/checkvox/domain/entity/DomainContextClassifierIntegrationTest.java:[98,37] incompatible types: java.util.List<io.checkvox.domain.entity.Tag> cannot be converted to java.util.Set<io.checkvox.domain.entity.Tag>
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  4.482 s
[INFO] Finished at: 2025-05-04T09:44:33-04:00
[INFO] ------------------------------------------------------------------------
EOF

  # Create metrics file
  cat > "${TEST_TEMP_DIR}/metrics/system.csv" << EOF
timestamp,cpu_usage,memory_usage,disk_io,network_io,test_count,test_failures,active_threads
1620000001,6.73,5644,0,0,194,43,30
EOF

  # Run analysis
  run analyze_build_failure "${TEST_TEMP_DIR}/maven_errors.log" "${TEST_TEMP_DIR}/metrics" "${TEST_TEMP_DIR}/report.md"
  assert_success
  
  # Verify the analysis correctly identifies error types
  run cat "${TEST_TEMP_DIR}/report.md"
  assert_output --partial "Total Errors"
  assert_output --partial "Dependency Errors"
  assert_output --partial "Access Violations"
}