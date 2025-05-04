#!/usr/bin/env bats

load 'helpers/bats-support/load'
load 'helpers/bats-assert/load'

# Set up test environment
setup() {
  # Load problem simulators - try both possible locations
  if [[ -f "${BATS_TEST_DIRNAME}/../fixtures/problem_simulators/optimization_config_generator.bash" ]]; then
    source "${BATS_TEST_DIRNAME}/../fixtures/problem_simulators/optimization_config_generator.bash"
  else
    source "${BATS_TEST_DIRNAME}/fixtures/problem_simulators/optimization_config_generator.bash"
  fi
  
  # Create test output directory
  TEST_OUTPUT_DIR="$(mktemp -d)"
  
  # Create sample Maven test log with various issues
  SAMPLE_LOG_FILE="${TEST_OUTPUT_DIR}/sample-maven.log"
  cat > "${SAMPLE_LOG_FILE}" << 'EOF'
[INFO] Tests run: 120, Failures: 2, Errors: 1, Skipped: 0, Time elapsed: 125.2 s
[ERROR] java.lang.OutOfMemoryError: Java heap space
[INFO] CPU: 95% utilized during test execution
[ERROR] ConnectException: Connection timed out
[WARNING] Execution time exceeded expected threshold
[ERROR] ConcurrentModificationException at TestClass.testMethod
[WARNING] Slow I/O detected during test execution
[ERROR] Could not resolve dependencies for project
[INFO] Test failed after retry: 3 attempts
EOF
}

# Clean up after tests
teardown() {
  rm -rf "${TEST_OUTPUT_DIR}"
}

@test "optimization_config_generator.bash should exist and be executable" {
  assert [ -x "${BATS_TEST_DIRNAME}/../fixtures/problem_simulators/optimization_config_generator.bash" ]
}

@test "analyze_test_execution should detect bottlenecks correctly" {
  analyze_test_execution "${SAMPLE_LOG_FILE}"
  
  # Check that the expected bottlenecks were detected
  assert [ "$(get_bottleneck cpu)" = "true" ]
  assert [ "$(get_bottleneck memory)" = "true" ]
  assert [ "$(get_bottleneck network)" = "true" ]
  assert [ "$(get_bottleneck thread_safety)" = "true" ]
  assert [ "$(get_bottleneck flaky)" = "true" ]
  assert [ "$(get_bottleneck parallel_execution)" = "true" ]
  assert [ "$(get_bottleneck dependencies)" = "true" ]
  
  # Verify disk bottleneck (which should also be detected)
  assert [ "$(get_bottleneck disk)" = "true" ]
}

@test "generate_settings_xml should create a valid Maven settings file" {
  # Set up environment for test
  analyze_test_execution "${SAMPLE_LOG_FILE}"
  local output_file="${TEST_OUTPUT_DIR}/test-settings.xml"
  
  # Generate settings file
  generate_settings_xml "${output_file}"
  
  # Verify file exists
  assert [ -f "${output_file}" ]
  
  # Verify content contains expected XML elements
  run grep -c "<settings" "${output_file}"
  local count=$output
  assert [ "$count" -eq 1 ]
  
  # Check for memory optimizations (since memory bottleneck was detected)
  run grep -c "Memory optimization" "${output_file}"
  local mem_count=$output
  assert [ "$mem_count" -ge 1 ]
  
  # Check for network optimizations (since network bottleneck was detected)
  run grep -c "Network optimization" "${output_file}"
  local net_count=$output
  assert [ "$net_count" -ge 1 ]
}

@test "generate_pom_snippet should create valid Maven POM configuration" {
  # Set up environment for test
  analyze_test_execution "${SAMPLE_LOG_FILE}"
  local output_file="${TEST_OUTPUT_DIR}/test-pom-snippet.xml"
  
  # Generate POM snippet
  generate_pom_snippet "${output_file}"
  
  # Verify file exists
  assert [ -f "${output_file}" ]
  
  # Verify content contains expected XML elements
  run grep -c "<build>" "${output_file}"
  local build_count=$output
  assert [ "$build_count" -eq 1 ]
  
  # Check for memory optimizations (since memory bottleneck was detected)
  run grep -c "Memory optimization" "${output_file}"
  local mem_count=$output
  assert [ "$mem_count" -ge 1 ]
  
  # Check for CPU optimizations (since CPU bottleneck was detected)
  run grep -c "CPU and parallel execution optimization" "${output_file}"
  local cpu_count=$output
  assert [ "$cpu_count" -ge 1 ]
  
  # Check for thread safety (since thread safety issues were detected)
  run grep -c "Thread safety optimization" "${output_file}"
  local thread_count=$output
  assert [ "$thread_count" -ge 1 ]
}

@test "generate_maven_opts should create a valid shell script with JVM options" {
  # Set up environment for test
  analyze_test_execution "${SAMPLE_LOG_FILE}"
  local output_file="${TEST_OUTPUT_DIR}/test-maven-opts.sh"
  
  # Generate Maven opts script
  generate_maven_opts "${output_file}"
  
  # Verify file exists and is executable
  assert [ -f "${output_file}" ]
  assert [ -x "${output_file}" ]
  
  # Verify content contains expected settings
  run grep -c "Memory optimization" "${output_file}"
  local mem_count=$output
  assert [ "$mem_count" -ge 1 ]
  
  # Check for network optimizations (since network bottleneck was detected)
  run grep -c "Network optimization" "${output_file}"
  local net_count=$output
  assert [ "$net_count" -ge 1 ]
}

@test "generate_multimodule_strategy should create a valid strategy document" {
  # Generate strategy document
  local output_file="${TEST_OUTPUT_DIR}/test-multimodule-strategy.md"
  generate_multimodule_strategy "${output_file}"
  
  # Verify file exists
  assert [ -f "${output_file}" ]
  
  # Verify content contains expected sections
  run grep -c "# Multimodule Build Optimization Strategy" "${output_file}"
  local title_count=$output
  assert [ "$title_count" -eq 1 ]
  
  # Check for build order section
  run grep -c "## Build Order Optimization" "${output_file}"
  local order_count=$output
  assert [ "$order_count" -eq 1 ]
  
  # Check for implementation plan
  run grep -c "## Implementation Plan" "${output_file}"
  local plan_count=$output
  assert [ "$plan_count" -eq 1 ]
}

@test "generate_optimization_summary should create a comprehensive report" {
  # Set up environment for test
  analyze_test_execution "${SAMPLE_LOG_FILE}"
  local output_file="${TEST_OUTPUT_DIR}/test-optimization-summary.md"
  
  # Generate summary report
  generate_optimization_summary "${output_file}"
  
  # Verify file exists
  assert [ -f "${output_file}" ]
  
  # Verify content contains expected sections
  run grep -c "# MVNimble Test Optimization Summary" "${output_file}"
  local title_count=$output
  assert [ "$title_count" -eq 1 ]
  
  # Check for detected bottlenecks section
  run grep -c "## Detected Bottlenecks" "${output_file}"
  local bottlenecks_count=$output
  assert [ "$bottlenecks_count" -eq 1 ]
  
  # Check for implementation plan
  run grep -c "## Implementation Plan" "${output_file}"
  local plan_count=$output
  assert [ "$plan_count" -eq 1 ]
  
  # Check that CPU bottleneck is mentioned
  run grep -c "CPU Utilization" "${output_file}"
  local cpu_count=$output
  assert [ "$cpu_count" -eq 1 ]
  
  # Check that Memory bottleneck is mentioned
  run grep -c "Memory Constraints" "${output_file}"
  local mem_count=$output
  assert [ "$mem_count" -eq 1 ]
}

@test "generate_mvnimble_config should create all expected files" {
  # Generate complete configuration set
  local output_dir="${TEST_OUTPUT_DIR}/mvnimble_configs"
  generate_mvnimble_config "${SAMPLE_LOG_FILE}" "${output_dir}"
  
  # Verify all expected files exist
  assert [ -f "${output_dir}/optimized-settings.xml" ]
  assert [ -f "${output_dir}/pom-snippet.xml" ]
  assert [ -f "${output_dir}/maven-opts.sh" ]
  assert [ -f "${output_dir}/multimodule-strategy.md" ]
  assert [ -f "${output_dir}/optimization-summary.md" ]
  
  # Verify executable permission on maven-opts.sh
  assert [ -x "${output_dir}/maven-opts.sh" ]
}

@test "help message should be displayed when no arguments provided" {
  # Redirect stdout to a file
  run "${BATS_TEST_DIRNAME}/../fixtures/problem_simulators/optimization_config_generator.bash"
  
  # Check for usage information in output
  assert_output --partial "Usage:"
  assert_output --partial "test_log_file"
  assert_output --partial "output_directory"
}