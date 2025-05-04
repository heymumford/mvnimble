#!/usr/bin/env bats
#
# Gold Standard Validation Tests for MVNimble
#
# These tests verify that MVNimble's recommendations match expert-derived optimal 
# configurations for various test scenarios.

load "../../test_helper"
load "../../../bats/fixtures/problem_simulators/diagnostic_patterns.bash"

# Source the gold standard validation script
source "${BATS_TEST_DIRNAME}/gold_standard_validation.sh"

setup() {
  # Create a temporary directory for test artifacts
  export TEST_TEMP_DIR="$(mktemp -d)"
}

teardown() {
  # Clean up temporary directory
  if [ -d "${TEST_TEMP_DIR}" ]; then
    rm -rf "${TEST_TEMP_DIR}"
  fi
}

@test "Gold Standard: Setup validation environment" {
  # Test the setup function
  setup_gold_standard_environment
  
  # Verify directories were created
  [ -d "${GOLD_STANDARD_DIR}" ]
  [ -d "${VALIDATION_REPORT_DIR}" ]
  [ -d "${GOLD_STANDARD_DIR}/cpu_bound" ]
  [ -d "${GOLD_STANDARD_DIR}/memory_bound" ]
  [ -d "${GOLD_STANDARD_DIR}/io_bound" ]
  [ -d "${GOLD_STANDARD_DIR}/network_bound" ]
  [ -d "${GOLD_STANDARD_DIR}/thread_safety" ]
  [ -d "${GOLD_STANDARD_DIR}/multivariate" ]
}

@test "Gold Standard: Create test project" {
  # Create a test project
  local project_dir="${TEST_TEMP_DIR}/test_project"
  create_test_project "${project_dir}"
  
  # Verify project structure
  [ -d "${project_dir}" ]
  [ -f "${project_dir}/pom.xml" ]
  [ -d "${project_dir}/src/main/java/com/example" ]
  [ -d "${project_dir}/src/test/java/com/example" ]
  [ -f "${project_dir}/src/main/java/com/example/Calculator.java" ]
  [ -f "${project_dir}/src/test/java/com/example/CalculatorTest.java" ]
}

@test "Gold Standard: Create CPU-bound scenario" {
  # Create a CPU-bound scenario
  local scenario_name="test_cpu_scenario"
  local category="cpu_bound"
  local constraint_level="medium"
  local expert_recommendations='{
    "recommendations": {
      "forkCount": "0.5C",
      "reuseForks": "true",
      "threadCount": "2"
    }
  }'
  
  # Set up environment
  setup_gold_standard_environment
  
  # Create the scenario
  create_gold_standard_scenario "${scenario_name}" "${category}" "${constraint_level}" "${expert_recommendations}"
  
  # Verify scenario structure
  [ -d "${GOLD_STANDARD_DIR}/${category}/${scenario_name}" ]
  [ -d "${GOLD_STANDARD_DIR}/${category}/${scenario_name}/project" ]
  [ -f "${GOLD_STANDARD_DIR}/${category}/${scenario_name}/expert_recommendations.json" ]
  [ -f "${GOLD_STANDARD_DIR}/${category}/${scenario_name}/metadata.json" ]
  
  # Verify the content of files
  grep -q "forkCount" "${GOLD_STANDARD_DIR}/${category}/${scenario_name}/expert_recommendations.json"
  grep -q "constraint_level.*${constraint_level}" "${GOLD_STANDARD_DIR}/${category}/${scenario_name}/metadata.json"
  
  # Verify that the CPU constraints were applied
  [ -f "${GOLD_STANDARD_DIR}/${category}/${scenario_name}/project/src/test/java/com/example/CpuIntensiveTest.java" ]
}

@test "Gold Standard: Create memory-bound scenario" {
  # Create a memory-bound scenario
  local scenario_name="test_memory_scenario"
  local category="memory_bound"
  local constraint_level="high"
  local expert_recommendations='{
    "recommendations": {
      "argLine": "-Xmx2048m -XX:+UseG1GC",
      "forkCount": "1",
      "reuseForks": "false"
    }
  }'
  
  # Set up environment
  setup_gold_standard_environment
  
  # Create the scenario
  create_gold_standard_scenario "${scenario_name}" "${category}" "${constraint_level}" "${expert_recommendations}"
  
  # Verify scenario structure
  [ -d "${GOLD_STANDARD_DIR}/${category}/${scenario_name}" ]
  [ -f "${GOLD_STANDARD_DIR}/${category}/${scenario_name}/expert_recommendations.json" ]
  
  # Verify that the memory constraints were applied
  [ -f "${GOLD_STANDARD_DIR}/${category}/${scenario_name}/project/src/test/java/com/example/MemoryIntensiveTest.java" ]
  grep -q "Xmx2048m" "${GOLD_STANDARD_DIR}/${category}/${scenario_name}/project/pom.xml"
}

@test "Gold Standard: Create IO-bound scenario" {
  # Create an IO-bound scenario
  local scenario_name="test_io_scenario"
  local category="io_bound"
  local constraint_level="medium"
  local expert_recommendations='{
    "recommendations": {
      "parallel": "classes",
      "threadCount": "2",
      "forkCount": "1"
    }
  }'
  
  # Set up environment
  setup_gold_standard_environment
  
  # Create the scenario
  create_gold_standard_scenario "${scenario_name}" "${category}" "${constraint_level}" "${expert_recommendations}"
  
  # Verify scenario structure
  [ -d "${GOLD_STANDARD_DIR}/${category}/${scenario_name}" ]
  [ -f "${GOLD_STANDARD_DIR}/${category}/${scenario_name}/expert_recommendations.json" ]
  
  # Verify that the IO constraints were applied
  [ -f "${GOLD_STANDARD_DIR}/${category}/${scenario_name}/project/src/test/java/com/example/IoIntensiveTest.java" ]
}

@test "Gold Standard: Create thread safety scenario" {
  # Create a thread safety scenario
  local scenario_name="test_thread_safety_scenario"
  local category="thread_safety"
  local constraint_level="high"
  local expert_recommendations='{
    "recommendations": {
      "parallel": "classesAndMethods",
      "threadCount": "8",
      "useUnlimitedThreads": "true"
    }
  }'
  
  # Set up environment
  setup_gold_standard_environment
  
  # Create the scenario
  create_gold_standard_scenario "${scenario_name}" "${category}" "${constraint_level}" "${expert_recommendations}"
  
  # Verify scenario structure
  [ -d "${GOLD_STANDARD_DIR}/${category}/${scenario_name}" ]
  [ -f "${GOLD_STANDARD_DIR}/${category}/${scenario_name}/expert_recommendations.json" ]
  
  # Verify that the thread safety constraints were applied
  [ -f "${GOLD_STANDARD_DIR}/${category}/${scenario_name}/project/src/main/java/com/example/Counter.java" ]
  [ -f "${GOLD_STANDARD_DIR}/${category}/${scenario_name}/project/src/test/java/com/example/ThreadSafetyTest.java" ]
}

@test "Gold Standard: Create multivariate scenario" {
  # Create a multivariate scenario
  local scenario_name="test_multivariate_scenario"
  local category="multivariate"
  local constraint_level="high"
  local expert_recommendations='{
    "recommendations": {
      "forkCount": "1C",
      "reuseForks": "false",
      "argLine": "-Xmx2048m -XX:+UseG1GC",
      "parallel": "classesAndMethods",
      "threadCount": "4"
    }
  }'
  
  # Set up environment
  setup_gold_standard_environment
  
  # Create the scenario
  create_gold_standard_scenario "${scenario_name}" "${category}" "${constraint_level}" "${expert_recommendations}"
  
  # Verify scenario structure
  [ -d "${GOLD_STANDARD_DIR}/${category}/${scenario_name}" ]
  [ -f "${GOLD_STANDARD_DIR}/${category}/${scenario_name}/expert_recommendations.json" ]
  
  # Verify that multiple constraints were applied
  [ -f "${GOLD_STANDARD_DIR}/${category}/${scenario_name}/project/src/test/java/com/example/CpuIntensiveTest.java" ]
  [ -f "${GOLD_STANDARD_DIR}/${category}/${scenario_name}/project/src/test/java/com/example/MemoryIntensiveTest.java" ]
}

@test "Gold Standard: Compare recommendations" {
  # Test recommendation comparison
  local expert_json='{
    "recommendations": {
      "forkCount": "0.5C",
      "reuseForks": "true",
      "threadCount": "2"
    }
  }'
  
  local mvnimble_text="RECOMMENDATIONS:
- Use forkCount=0.5C to better utilize CPU resources
- Set threadCount=2 for improved parallelism
- Enable reuseForks=true to reduce JVM startup overhead"
  
  # Compare recommendations
  local score=$(compare_recommendations "${expert_json}" "${mvnimble_text}")
  
  # Verify the score is between 0 and 1
  [ $(echo "${score} >= 0" | bc) -eq 1 ]
  [ $(echo "${score} <= 1" | bc) -eq 1 ]
  
  # For this particular example, we expect a good match
  [ $(echo "${score} >= 0.6" | bc) -eq 1 ]
}

@test "Gold Standard: Generate validation report" {
  # Set up environment
  setup_gold_standard_environment
  
  # Create a test scenario
  local scenario_name="test_scenario"
  local category="cpu_bound"
  local constraint_level="medium"
  local expert_recommendations='{
    "recommendations": {
      "forkCount": "0.5C",
      "reuseForks": "true"
    }
  }'
  
  create_gold_standard_scenario "${scenario_name}" "${category}" "${constraint_level}" "${expert_recommendations}"
  
  # Generate a validation report
  local scenario_dir="${GOLD_STANDARD_DIR}/${category}/${scenario_name}"
  generate_validation_report "${scenario_dir}" "0.8"
  
  # Verify the report was created
  [ -f "${VALIDATION_REPORT_DIR}/${scenario_name}_${category}_${constraint_level}.md" ]
  
  # Check report content
  grep -q "Comparison Score: 0.8" "${VALIDATION_REPORT_DIR}/${scenario_name}_${category}_${constraint_level}.md"
  
  # With score 0.8 and threshold 0.85, it should FAIL
  grep -q "Status: FAIL" "${VALIDATION_REPORT_DIR}/${scenario_name}_${category}_${constraint_level}.md"
}

@test "Gold Standard: Create standard scenarios" {
  # Create the standard set of gold standard scenarios
  create_standard_gold_scenarios
  
  # Verify scenarios were created for each category
  [ -d "${GOLD_STANDARD_DIR}/cpu_bound/cpu_light" ]
  [ -d "${GOLD_STANDARD_DIR}/cpu_bound/cpu_moderate" ]
  [ -d "${GOLD_STANDARD_DIR}/cpu_bound/cpu_heavy" ]
  
  [ -d "${GOLD_STANDARD_DIR}/memory_bound/memory_light" ]
  [ -d "${GOLD_STANDARD_DIR}/memory_bound/memory_moderate" ]
  [ -d "${GOLD_STANDARD_DIR}/memory_bound/memory_heavy" ]
  
  [ -d "${GOLD_STANDARD_DIR}/io_bound/io_light" ]
  [ -d "${GOLD_STANDARD_DIR}/io_bound/io_moderate" ]
  [ -d "${GOLD_STANDARD_DIR}/io_bound/io_heavy" ]
  
  [ -d "${GOLD_STANDARD_DIR}/thread_safety/thread_safety_light" ]
  [ -d "${GOLD_STANDARD_DIR}/thread_safety/thread_safety_moderate" ]
  [ -d "${GOLD_STANDARD_DIR}/thread_safety/thread_safety_severe" ]
  
  [ -d "${GOLD_STANDARD_DIR}/multivariate/multivariate_light" ]
  [ -d "${GOLD_STANDARD_DIR}/multivariate/multivariate_moderate" ]
  [ -d "${GOLD_STANDARD_DIR}/multivariate/multivariate_complex" ]
  
  # Check expert recommendations were created
  [ -f "${GOLD_STANDARD_DIR}/cpu_bound/cpu_moderate/expert_recommendations.json" ]
  [ -f "${GOLD_STANDARD_DIR}/memory_bound/memory_heavy/expert_recommendations.json" ]
  [ -f "${GOLD_STANDARD_DIR}/thread_safety/thread_safety_severe/expert_recommendations.json" ]
}

# Note: We skip actual validation tests since they would require
# MVNimble to be fully functional in the test environment
# These would be integration tests run in a full environment