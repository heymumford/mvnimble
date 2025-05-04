#!/usr/bin/env bats
#
# Educational Effectiveness Validation Tests for MVNimble
#
# These tests verify MVNimble's ability to effectively educate users
# about test flakiness and provide clear, actionable recommendations.

load "../../test_helper"
load "../../../bats/fixtures/problem_simulators/diagnostic_patterns.bash"

# Source the educational effectiveness validation script
source "${BATS_TEST_DIRNAME}/educational_effectiveness_validation.sh"

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

@test "Educational: Setup validation environment" {
  # Test the setup function
  setup_educational_environment
  
  # Verify directories were created
  [ -d "${EDUCATIONAL_DIR}" ]
  [ -d "${REPORT_DIR}" ]
  [ -d "${SURVEY_DIR}" ]
  [ -d "${LEARNING_METRICS_DIR}" ]
  [ -d "${EDUCATIONAL_DIR}/clarity" ]
  [ -d "${EDUCATIONAL_DIR}/knowledge_transfer" ]
  [ -d "${EDUCATIONAL_DIR}/progressive_learning" ]
  [ -d "${EDUCATIONAL_DIR}/actionability" ]
  [ -d "${EDUCATIONAL_DIR}/retention" ]
}

@test "Educational: Create clarity scenario (low complexity)" {
  # Set up environment
  setup_educational_environment
  
  # Create a low-complexity clarity scenario
  local scenario_name="test_clarity_low"
  create_clarity_scenario "${scenario_name}" "low"
  
  # Verify scenario structure
  [ -d "${EDUCATIONAL_DIR}/clarity/${scenario_name}" ]
  [ -d "${EDUCATIONAL_DIR}/clarity/${scenario_name}/project" ]
  [ -f "${EDUCATIONAL_DIR}/clarity/${scenario_name}/expected_metrics.json" ]
  [ -f "${EDUCATIONAL_DIR}/clarity/${scenario_name}/metadata.json" ]
  
  # Verify the project structure
  [ -f "${EDUCATIONAL_DIR}/clarity/${scenario_name}/project/pom.xml" ]
  [ -d "${EDUCATIONAL_DIR}/clarity/${scenario_name}/project/src/main/java/com/example" ]
  [ -d "${EDUCATIONAL_DIR}/clarity/${scenario_name}/project/src/test/java/com/example" ]
  
  # Verify Java files were created
  [ -f "${EDUCATIONAL_DIR}/clarity/${scenario_name}/project/src/main/java/com/example/TimeService.java" ]
  [ -f "${EDUCATIONAL_DIR}/clarity/${scenario_name}/project/src/test/java/com/example/TimeServiceTest.java" ]
  
  # Verify content
  grep -q "performTimedOperation" "${EDUCATIONAL_DIR}/clarity/${scenario_name}/project/src/main/java/com/example/TimeService.java"
  grep -q "testTimedOperationFlaky" "${EDUCATIONAL_DIR}/clarity/${scenario_name}/project/src/test/java/com/example/TimeServiceTest.java"
  
  # Verify expected metrics
  grep -q "readability_score" "${EDUCATIONAL_DIR}/clarity/${scenario_name}/expected_metrics.json"
  grep -q "jargon_ratio" "${EDUCATIONAL_DIR}/clarity/${scenario_name}/expected_metrics.json"
}

@test "Educational: Create knowledge transfer scenario (basic)" {
  # Set up environment
  setup_educational_environment
  
  # Create a basic knowledge transfer scenario
  local scenario_name="test_knowledge_basic"
  create_knowledge_transfer_scenario "${scenario_name}" "basic"
  
  # Verify scenario structure
  [ -d "${EDUCATIONAL_DIR}/knowledge_transfer/${scenario_name}" ]
  [ -d "${EDUCATIONAL_DIR}/knowledge_transfer/${scenario_name}/project" ]
  [ -f "${EDUCATIONAL_DIR}/knowledge_transfer/${scenario_name}/expected_metrics.json" ]
  [ -f "${EDUCATIONAL_DIR}/knowledge_transfer/${scenario_name}/metadata.json" ]
  
  # Verify the project structure
  [ -f "${EDUCATIONAL_DIR}/knowledge_transfer/${scenario_name}/project/pom.xml" ]
  
  # Verify expected metrics
  grep -q "concept_explanation_score" "${EDUCATIONAL_DIR}/knowledge_transfer/${scenario_name}/expected_metrics.json"
  grep -q "learning_resources_quality" "${EDUCATIONAL_DIR}/knowledge_transfer/${scenario_name}/expected_metrics.json"
}

@test "Educational: Create progressive learning scenario (beginner)" {
  # Set up environment
  setup_educational_environment
  
  # Create a beginner progressive learning scenario
  local scenario_name="test_learning_beginner"
  create_progressive_learning_scenario "${scenario_name}" "beginner"
  
  # Verify scenario structure
  [ -d "${EDUCATIONAL_DIR}/progressive_learning/${scenario_name}" ]
  [ -d "${EDUCATIONAL_DIR}/progressive_learning/${scenario_name}/project" ]
  [ -f "${EDUCATIONAL_DIR}/progressive_learning/${scenario_name}/expected_metrics.json" ]
  [ -f "${EDUCATIONAL_DIR}/progressive_learning/${scenario_name}/metadata.json" ]
  
  # Verify expected metrics
  grep -q "level_appropriateness" "${EDUCATIONAL_DIR}/progressive_learning/${scenario_name}/expected_metrics.json"
  grep -q "advancement_path_clarity" "${EDUCATIONAL_DIR}/progressive_learning/${scenario_name}/expected_metrics.json"
}

@test "Educational: Create actionability scenario (easy)" {
  # Set up environment
  setup_educational_environment
  
  # Create an easy actionability scenario
  local scenario_name="test_action_easy"
  create_actionability_scenario "${scenario_name}" "easy"
  
  # Verify scenario structure
  [ -d "${EDUCATIONAL_DIR}/actionability/${scenario_name}" ]
  [ -d "${EDUCATIONAL_DIR}/actionability/${scenario_name}/project" ]
  [ -f "${EDUCATIONAL_DIR}/actionability/${scenario_name}/expected_metrics.json" ]
  [ -f "${EDUCATIONAL_DIR}/actionability/${scenario_name}/metadata.json" ]
  
  # Verify expected metrics
  grep -q "step_by_step_clarity" "${EDUCATIONAL_DIR}/actionability/${scenario_name}/expected_metrics.json"
  grep -q "implementation_practicality" "${EDUCATIONAL_DIR}/actionability/${scenario_name}/expected_metrics.json"
}

@test "Educational: Create retention scenario (short-term)" {
  # Set up environment
  setup_educational_environment
  
  # Create a short-term retention scenario
  local scenario_name="test_retention_short"
  create_retention_scenario "${scenario_name}" "short_term"
  
  # Verify scenario structure
  [ -d "${EDUCATIONAL_DIR}/retention/${scenario_name}" ]
  [ -d "${EDUCATIONAL_DIR}/retention/${scenario_name}/project" ]
  [ -f "${EDUCATIONAL_DIR}/retention/${scenario_name}/expected_metrics.json" ]
  [ -f "${EDUCATIONAL_DIR}/retention/${scenario_name}/metadata.json" ]
  
  # Verify expected metrics
  grep -q "concept_memorability" "${EDUCATIONAL_DIR}/retention/${scenario_name}/expected_metrics.json"
  grep -q "reinforcement_techniques" "${EDUCATIONAL_DIR}/retention/${scenario_name}/expected_metrics.json"
}

@test "Educational: Generate educational report" {
  # Set up environment
  setup_educational_environment
  
  # Create directories for test
  local scenario_dir="${EDUCATIONAL_DIR}/clarity/test_report"
  mkdir -p "${scenario_dir}/results"
  
  # Create sample educational content
  echo "This is sample educational content for testing" > "${scenario_dir}/results/educational_content.txt"
  
  # Generate a validation report
  generate_educational_report "${scenario_dir}" "0.8"
  
  # Verify report was created
  [ -f "${REPORT_DIR}/clarity_test_report_report.md" ]
  
  # Check report content
  grep -q "Effectiveness Score: 0.8" "${REPORT_DIR}/clarity_test_report_report.md"
  grep -q "Educational Effectiveness Validation Report" "${REPORT_DIR}/clarity_test_report_report.md"
}

@test "Educational: Create standard scenarios" {
  # Create all standard educational scenarios
  create_standard_scenarios
  
  # Verify scenarios were created for each category
  [ -d "${EDUCATIONAL_DIR}/clarity/simple_explanation" ]
  [ -d "${EDUCATIONAL_DIR}/clarity/moderate_explanation" ]
  [ -d "${EDUCATIONAL_DIR}/clarity/complex_explanation" ]
  
  [ -d "${EDUCATIONAL_DIR}/knowledge_transfer/basic_concepts" ]
  [ -d "${EDUCATIONAL_DIR}/knowledge_transfer/advanced_concepts" ]
  
  [ -d "${EDUCATIONAL_DIR}/progressive_learning/beginner_guide" ]
  [ -d "${EDUCATIONAL_DIR}/progressive_learning/expert_guide" ]
  
  [ -d "${EDUCATIONAL_DIR}/actionability/simple_implementation" ]
  [ -d "${EDUCATIONAL_DIR}/actionability/complex_implementation" ]
  
  [ -d "${EDUCATIONAL_DIR}/retention/core_concepts" ]
  [ -d "${EDUCATIONAL_DIR}/retention/advanced_patterns" ]
  
  # Check for expected metrics files in each scenario
  [ -f "${EDUCATIONAL_DIR}/clarity/simple_explanation/expected_metrics.json" ]
  [ -f "${EDUCATIONAL_DIR}/knowledge_transfer/basic_concepts/expected_metrics.json" ]
  [ -f "${EDUCATIONAL_DIR}/progressive_learning/beginner_guide/expected_metrics.json" ]
  [ -f "${EDUCATIONAL_DIR}/actionability/simple_implementation/expected_metrics.json" ]
  [ -f "${EDUCATIONAL_DIR}/retention/core_concepts/expected_metrics.json" ]
}

@test "Educational: Analyze clarity content" {
  # Test the analyze_clarity function
  local temp_file="${TEST_TEMP_DIR}/clarity_content.txt"
  echo "This is a sample educational content for testing clarity analysis" > "${temp_file}"
  
  # Run the analysis
  local result=$(analyze_clarity "${temp_file}")
  
  # Verify the result is valid JSON
  echo "${result}" | grep -q "readability_score"
  echo "${result}" | grep -q "jargon_ratio"
  echo "${result}" | grep -q "example_quality"
}

@test "Educational: Compare metrics" {
  # Create test metrics files
  local expected_file="${TEST_TEMP_DIR}/expected_metrics.json"
  local actual_file="${TEST_TEMP_DIR}/actual_metrics.json"
  
  echo '{"readability_score": 90, "jargon_ratio": 0.05}' > "${expected_file}"
  echo '{"readability_score": 85, "jargon_ratio": 0.08}' > "${actual_file}"
  
  # Test the comparison function
  local score=$(compare_metrics "${expected_file}" "${actual_file}")
  
  # Verify the result is a number between 0 and 1
  [[ "${score}" =~ ^[0-9]+(\.[0-9]+)?$ ]]
  [ $(echo "${score} >= 0" | bc) -eq 1 ]
  [ $(echo "${score} <= 1" | bc) -eq 1 ]
}

# Note: We skip actual validation tests since they would require
# MVNimble to be fully functional in the test environment
# These would be integration tests run in a full environment