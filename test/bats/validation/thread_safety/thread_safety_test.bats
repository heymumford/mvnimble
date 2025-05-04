#!/usr/bin/env bats
#
# Thread Safety Validation Tests for MVNimble
#
# These tests verify MVNimble's ability to detect, diagnose, and provide
# recommendations for thread safety issues in Maven tests.

load "../../test_helper"
load "../../../bats/fixtures/problem_simulators/thread_safety_issues.bash"

# Source the thread safety validation script
source "${BATS_TEST_DIRNAME}/thread_safety_validation.sh"

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

@test "Thread Safety: Setup validation environment" {
  # Test the setup function
  setup_thread_safety_environment
  
  # Verify directories were created
  [ -d "${THREAD_SAFETY_DIR}" ]
  [ -d "${REPORT_DIR}" ]
  [ -d "${THREAD_SAFETY_DIR}/race_conditions" ]
  [ -d "${THREAD_SAFETY_DIR}/deadlocks" ]
  [ -d "${THREAD_SAFETY_DIR}/thread_ordering" ]
  [ -d "${THREAD_SAFETY_DIR}/memory_visibility" ]
  [ -d "${THREAD_SAFETY_DIR}/resource_contention" ]
  [ -d "${THREAD_SAFETY_DIR}/thread_leaks" ]
}

@test "Thread Safety: Create base project" {
  # Create a base project
  local project_dir="${TEST_TEMP_DIR}/base_project"
  create_base_project "${project_dir}"
  
  # Verify project structure
  [ -d "${project_dir}" ]
  [ -f "${project_dir}/pom.xml" ]
  [ -d "${project_dir}/src/main/java/com/example/threadsafety" ]
  [ -d "${project_dir}/src/test/java/com/example/threadsafety" ]
  
  # Verify pom.xml contains expected content
  grep -q "thread-safety-test" "${project_dir}/pom.xml"
  grep -q "junit.jupiter" "${project_dir}/pom.xml"
  grep -q "maven-surefire-plugin" "${project_dir}/pom.xml"
}

@test "Thread Safety: Create race condition scenario" {
  # Create a race condition scenario
  local scenario_name="test_race_condition"
  local severity="medium"
  
  # Set up environment
  setup_thread_safety_environment
  
  # Create the scenario
  create_race_condition_scenario "${scenario_name}" "${severity}"
  
  # Verify scenario structure
  [ -d "${THREAD_SAFETY_DIR}/race_conditions/${scenario_name}" ]
  [ -d "${THREAD_SAFETY_DIR}/race_conditions/${scenario_name}/project" ]
  
  # Verify Java files were created
  [ -f "${THREAD_SAFETY_DIR}/race_conditions/${scenario_name}/project/src/main/java/com/example/threadsafety/Counter.java" ]
  [ -f "${THREAD_SAFETY_DIR}/race_conditions/${scenario_name}/project/src/test/java/com/example/threadsafety/RaceConditionTest.java" ]
  
  # Verify content
  grep -q "Race conditions" "${THREAD_SAFETY_DIR}/race_conditions/${scenario_name}/project/src/test/java/com/example/threadsafety/RaceConditionTest.java"
  grep -q "void increment()" "${THREAD_SAFETY_DIR}/race_conditions/${scenario_name}/project/src/main/java/com/example/threadsafety/Counter.java"
  grep -q "void incrementSafe()" "${THREAD_SAFETY_DIR}/race_conditions/${scenario_name}/project/src/main/java/com/example/threadsafety/Counter.java"
}

@test "Thread Safety: Create deadlock scenario" {
  # Create a deadlock scenario
  local scenario_name="test_deadlock"
  local severity="medium"
  
  # Set up environment
  setup_thread_safety_environment
  
  # Create the scenario
  create_deadlock_scenario "${scenario_name}" "${severity}"
  
  # Verify scenario structure
  [ -d "${THREAD_SAFETY_DIR}/deadlocks/${scenario_name}" ]
  [ -d "${THREAD_SAFETY_DIR}/deadlocks/${scenario_name}/project" ]
  
  # Verify Java files were created
  [ -f "${THREAD_SAFETY_DIR}/deadlocks/${scenario_name}/project/src/main/java/com/example/threadsafety/ResourceManager.java" ]
  [ -f "${THREAD_SAFETY_DIR}/deadlocks/${scenario_name}/project/src/test/java/com/example/threadsafety/DeadlockTest.java" ]
  
  # Verify content
  grep -q "updateResourcesDeadlockProne" "${THREAD_SAFETY_DIR}/deadlocks/${scenario_name}/project/src/main/java/com/example/threadsafety/ResourceManager.java"
  grep -q "testBasicDeadlock" "${THREAD_SAFETY_DIR}/deadlocks/${scenario_name}/project/src/test/java/com/example/threadsafety/DeadlockTest.java"
  grep -q "testDeadlockFreeSolution" "${THREAD_SAFETY_DIR}/deadlocks/${scenario_name}/project/src/test/java/com/example/threadsafety/DeadlockTest.java"
  
  # Verify Surefire configuration
  grep -q "HeapDumpOnOutOfMemoryError" "${THREAD_SAFETY_DIR}/deadlocks/${scenario_name}/project/pom.xml"
}

@test "Thread Safety: Create thread ordering scenario" {
  # Create a thread ordering scenario
  local scenario_name="test_ordering"
  local severity="high"
  
  # Set up environment
  setup_thread_safety_environment
  
  # Create the scenario
  create_thread_ordering_scenario "${scenario_name}" "${severity}"
  
  # Verify scenario structure
  [ -d "${THREAD_SAFETY_DIR}/thread_ordering/${scenario_name}" ]
  [ -d "${THREAD_SAFETY_DIR}/thread_ordering/${scenario_name}/project" ]
  
  # Verify Java files were created
  [ -f "${THREAD_SAFETY_DIR}/thread_ordering/${scenario_name}/project/src/main/java/com/example/threadsafety/ConcurrentProcessor.java" ]
  [ -f "${THREAD_SAFETY_DIR}/thread_ordering/${scenario_name}/project/src/test/java/com/example/threadsafety/ThreadOrderingTest.java" ]
  
  # Verify content
  grep -q "processMessagesUnsafe" "${THREAD_SAFETY_DIR}/thread_ordering/${scenario_name}/project/src/main/java/com/example/threadsafety/ConcurrentProcessor.java"
  grep -q "processMessagesSafe" "${THREAD_SAFETY_DIR}/thread_ordering/${scenario_name}/project/src/main/java/com/example/threadsafety/ConcurrentProcessor.java"
  grep -q "testThreadOrderingSafeSolution" "${THREAD_SAFETY_DIR}/thread_ordering/${scenario_name}/project/src/test/java/com/example/threadsafety/ThreadOrderingTest.java"
}

@test "Thread Safety: Generate validation report" {
  # Set up environment
  setup_thread_safety_environment
  
  # Create directories for test
  local scenario_dir="${THREAD_SAFETY_DIR}/race_conditions/test_scenario"
  mkdir -p "${scenario_dir}/results"
  
  # Create a sample thread safety analysis file
  mkdir -p "${scenario_dir}/results"
  cat > "${scenario_dir}/results/thread_safety_analysis.txt" << EOF
Thread Safety Analysis
---------------------
Thread safety issues detected: Found potential race conditions in Counter.increment()
Recommendation: Consider using synchronized methods or atomic variables
EOF
  
  # Generate a validation report
  generate_validation_report "${scenario_dir}" "true" "true" "PASS"
  
  # Verify report was created
  [ -f "${REPORT_DIR}/race_conditions_test_scenario_report.md" ]
  
  # Check report content
  grep -q "Issues Detected: true" "${REPORT_DIR}/race_conditions_test_scenario_report.md"
  grep -q "Recommendations Provided: true" "${REPORT_DIR}/race_conditions_test_scenario_report.md"
  grep -q "Overall Result: PASS" "${REPORT_DIR}/race_conditions_test_scenario_report.md"
}

@test "Thread Safety: Create all scenarios" {
  # Create all thread safety scenarios
  create_all_scenarios
  
  # Verify scenarios were created for each category
  [ -d "${THREAD_SAFETY_DIR}/race_conditions/simple_counter" ]
  [ -d "${THREAD_SAFETY_DIR}/race_conditions/array_updates" ]
  [ -d "${THREAD_SAFETY_DIR}/race_conditions/complex_race" ]
  
  [ -d "${THREAD_SAFETY_DIR}/deadlocks/basic_deadlock" ]
  [ -d "${THREAD_SAFETY_DIR}/deadlocks/trylock_deadlock" ]
  [ -d "${THREAD_SAFETY_DIR}/deadlocks/complex_deadlock" ]
  
  [ -d "${THREAD_SAFETY_DIR}/thread_ordering/initialization_race" ]
  [ -d "${THREAD_SAFETY_DIR}/thread_ordering/message_processing" ]
  [ -d "${THREAD_SAFETY_DIR}/thread_ordering/random_ordering" ]
  
  # Check for Java files in each scenario
  [ -f "${THREAD_SAFETY_DIR}/race_conditions/simple_counter/project/src/main/java/com/example/threadsafety/Counter.java" ]
  [ -f "${THREAD_SAFETY_DIR}/deadlocks/basic_deadlock/project/src/main/java/com/example/threadsafety/ResourceManager.java" ]
  [ -f "${THREAD_SAFETY_DIR}/thread_ordering/initialization_race/project/src/main/java/com/example/threadsafety/ConcurrentProcessor.java" ]
}

# Note: We skip actual validation tests since they would require
# MVNimble to be fully functional in the test environment
# These would be integration tests run in a full environment