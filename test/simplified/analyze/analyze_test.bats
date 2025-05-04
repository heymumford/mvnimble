#!/usr/bin/env bats
# Tests for the analyze.sh module

# Load the test helpers
load ../common/helpers

# Setup test environment
setup() {
  # Call the common setup function
  load_libs
  
  # Create a temporary directory for test artifacts
  TEST_TEMP_DIR="$(mktemp -d)"
  export TEST_TEMP_DIR
  
  # Load required modules
  load_module "constants"
  load_module "common"
  load_module "analyze"
}

# Clean up after tests
teardown() {
  # Call the common teardown function
  if [ -n "$TEST_TEMP_DIR" ] && [ -d "$TEST_TEMP_DIR" ]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# Test that analyze_build_data function exists
@test "analyze_build_data function exists" {
  # Check that the function is defined
  declare -f analyze_build_data
}

# Test build failure analysis
@test "analyzer detects build failures" {
  # Create a mock Maven output with a failure
  local maven_output=$(create_mock_maven_output "failure")
  
  # Run the analyzer
  analyze_build_failure "$maven_output" "${TEST_TEMP_DIR}/failure_analysis.json"
  
  # Check that the failure was analyzed
  [ -f "${TEST_TEMP_DIR}/failure_analysis.json" ]
  grep -q '"status": "failure"' "${TEST_TEMP_DIR}/failure_analysis.json"
  grep -q '"failure_type": "test"' "${TEST_TEMP_DIR}/failure_analysis.json"
}

# Test resource bottleneck detection
@test "analyzer detects resource bottlenecks" {
  # Create mock resource metrics
  mkdir -p "${TEST_TEMP_DIR}/metrics"
  
  # Create CPU usage metric with high values
  for i in {1..10}; do
    echo "$(date +%s),$((80 + i)),0.5,2.3" >> "${TEST_TEMP_DIR}/metrics/cpu_usage.log"
  done
  
  # Create memory usage metric with normal values
  for i in {1..10}; do
    echo "$(date +%s),60,4096,2048" >> "${TEST_TEMP_DIR}/metrics/memory_usage.log"
  done
  
  # Run the analyzer
  detect_resource_bottlenecks "${TEST_TEMP_DIR}/metrics" "${TEST_TEMP_DIR}/bottleneck_analysis.json"
  
  # Check that the bottleneck was detected
  [ -f "${TEST_TEMP_DIR}/bottleneck_analysis.json" ]
  grep -q '"bottlenecks": \["cpu"\]' "${TEST_TEMP_DIR}/bottleneck_analysis.json"
}

# Test POM file analysis
@test "analyzer provides POM file recommendations" {
  # Create a mock Maven project
  local project_dir=$(create_mock_maven_project)
  
  # Run the POM analyzer
  analyze_maven_config "${project_dir}/pom.xml" "${TEST_TEMP_DIR}/pom_analysis.json"
  
  # Check that the analysis was done
  [ -f "${TEST_TEMP_DIR}/pom_analysis.json" ]
  grep -q '"recommendations"' "${TEST_TEMP_DIR}/pom_analysis.json"
}

# Test slow test detection
@test "analyzer identifies slow tests" {
  # Create mock test execution data
  cat > "${TEST_TEMP_DIR}/test_times.json" <<EOF
{
  "tests": [
    {
      "name": "com.example.FastTest",
      "time": 0.035
    },
    {
      "name": "com.example.SlowTest",
      "time": 3.5
    },
    {
      "name": "com.example.MediumTest",
      "time": 0.8
    }
  ]
}
EOF
  
  # Run the slow test analyzer
  identify_slow_tests "${TEST_TEMP_DIR}/test_times.json" "${TEST_TEMP_DIR}/slow_tests.json" 1.0
  
  # Check that slow tests were identified
  [ -f "${TEST_TEMP_DIR}/slow_tests.json" ]
  grep -q '"slow_tests": \["com.example.SlowTest"\]' "${TEST_TEMP_DIR}/slow_tests.json"
}

# Test performance trend analysis
@test "analyzer detects performance trends" {
  # Create historical performance data
  cat > "${TEST_TEMP_DIR}/historical_data.json" <<EOF
[
  {
    "date": "2025-05-01",
    "build_duration": 125,
    "test_count": 150
  },
  {
    "date": "2025-05-02",
    "build_duration": 130,
    "test_count": 155
  },
  {
    "date": "2025-05-03",
    "build_duration": 138,
    "test_count": 158
  },
  {
    "date": "2025-05-04",
    "build_duration": 145,
    "test_count": 160
  }
]
EOF
  
  # Run the trend analyzer
  analyze_performance_trend "${TEST_TEMP_DIR}/historical_data.json" "${TEST_TEMP_DIR}/trend_analysis.json"
  
  # Check that trends were detected
  [ -f "${TEST_TEMP_DIR}/trend_analysis.json" ]
  grep -q '"trend": "increasing"' "${TEST_TEMP_DIR}/trend_analysis.json"
}

# Test recommendation generation
@test "analyzer generates optimization recommendations" {
  # Create mock analysis files
  cat > "${TEST_TEMP_DIR}/bottleneck_analysis.json" <<EOF
{
  "bottlenecks": ["cpu"]
}
EOF
  
  cat > "${TEST_TEMP_DIR}/slow_tests.json" <<EOF
{
  "slow_tests": ["com.example.SlowTest"]
}
EOF
  
  # Generate recommendations
  generate_recommendations "${TEST_TEMP_DIR}/bottleneck_analysis.json" "${TEST_TEMP_DIR}/slow_tests.json" "${TEST_TEMP_DIR}/recommendations.json"
  
  # Check that recommendations were generated
  [ -f "${TEST_TEMP_DIR}/recommendations.json" ]
  grep -q '"recommendations"' "${TEST_TEMP_DIR}/recommendations.json"
  grep -q '"priority"' "${TEST_TEMP_DIR}/recommendations.json"
}