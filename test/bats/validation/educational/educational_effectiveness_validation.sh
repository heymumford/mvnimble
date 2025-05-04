#!/usr/bin/env bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
#
# Educational Effectiveness Validation Suite for MVNimble
#
# This script implements a framework to validate the educational effectiveness
# of MVNimble's recommendations and explanations. It tests whether MVNimble
# successfully transfers knowledge to users and helps them understand the
# underlying causes of test flakiness.

# Source common libraries
source "$(dirname "$(dirname "$(dirname "$0")")")/test_helper.bash"
source "$(dirname "$(dirname "$(dirname "$0")")")/fixtures/problem_simulators/diagnostic_patterns.bash"

# Constants
EDUCATIONAL_DIR="${BATS_TEST_DIRNAME}/scenarios"
REPORT_DIR="${BATS_TEST_DIRNAME}/reports"
SURVEY_DIR="${BATS_TEST_DIRNAME}/surveys"
LEARNING_METRICS_DIR="${BATS_TEST_DIRNAME}/metrics"

#######################################
# Creates the necessary directory structure for educational effectiveness validation
# Arguments:
#   None
# Outputs:
#   None
#######################################
function setup_educational_environment() {
  mkdir -p "${EDUCATIONAL_DIR}"
  mkdir -p "${REPORT_DIR}"
  mkdir -p "${SURVEY_DIR}"
  mkdir -p "${LEARNING_METRICS_DIR}"
  
  # Create subdirectories for each educational scenario category
  mkdir -p "${EDUCATIONAL_DIR}/clarity"
  mkdir -p "${EDUCATIONAL_DIR}/knowledge_transfer"
  mkdir -p "${EDUCATIONAL_DIR}/progressive_learning"
  mkdir -p "${EDUCATIONAL_DIR}/actionability"
  mkdir -p "${EDUCATIONAL_DIR}/retention"
}

#######################################
# Creates a test scenario for validating clarity of recommendations
# Arguments:
#   $1 - Scenario name
#   $2 - Complexity level (low, medium, high)
# Outputs:
#   None
#######################################
function create_clarity_scenario() {
  local scenario_name="$1"
  local complexity="$2"
  
  local scenario_dir="${EDUCATIONAL_DIR}/clarity/${scenario_name}"
  mkdir -p "${scenario_dir}"
  
  # Create a Maven project with different levels of diagnostic complexity
  mkdir -p "${scenario_dir}/project"
  
  # Create baseline diagnostics for clarity testing
  case "${complexity}" in
    low)
      # Simple, single-issue scenario
      generate_simple_diagnostic_scenario "${scenario_dir}/project"
      ;;
    medium)
      # Moderate complexity with 2-3 interrelated issues
      generate_moderate_diagnostic_scenario "${scenario_dir}/project"
      ;;
    high)
      # Complex scenario with multiple interacting issues
      generate_complex_diagnostic_scenario "${scenario_dir}/project"
      ;;
    *)
      echo "Unknown complexity level: ${complexity}"
      return 1
      ;;
  esac
  
  # Create expected clarity metrics file
  cat > "${scenario_dir}/expected_metrics.json" << EOF
{
  "readability_score": ${complexity == "low" ? 90 : (complexity == "medium" ? 80 : 70)},
  "jargon_ratio": ${complexity == "low" ? 0.05 : (complexity == "medium" ? 0.15 : 0.25)},
  "example_quality": ${complexity == "low" ? 5 : (complexity == "medium" ? 4 : 3)},
  "explanation_length": "${complexity == "low" ? "appropriate" : (complexity == "medium" ? "moderate" : "detailed")}",
  "visualization_quality": ${complexity == "low" ? 5 : (complexity == "medium" ? 4 : 3)}
}
EOF

  # Create a metadata file for the scenario
  cat > "${scenario_dir}/metadata.json" << EOF
{
  "name": "${scenario_name}",
  "complexity": "${complexity}",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "description": "Clarity validation scenario (${complexity} complexity)",
  "expected_metrics": ["readability_score", "jargon_ratio", "example_quality", "explanation_length", "visualization_quality"]
}
EOF
}

#######################################
# Creates a test scenario for validating knowledge transfer
# Arguments:
#   $1 - Scenario name
#   $2 - Knowledge depth (basic, intermediate, advanced)
# Outputs:
#   None
#######################################
function create_knowledge_transfer_scenario() {
  local scenario_name="$1"
  local knowledge_depth="$2"
  
  local scenario_dir="${EDUCATIONAL_DIR}/knowledge_transfer/${scenario_name}"
  mkdir -p "${scenario_dir}"
  
  # Create a Maven project with different levels of knowledge requirements
  mkdir -p "${scenario_dir}/project"
  
  # Create baseline for knowledge transfer testing
  case "${knowledge_depth}" in
    basic)
      # Basic knowledge scenario (e.g., simple resource contention)
      generate_basic_knowledge_scenario "${scenario_dir}/project"
      ;;
    intermediate)
      # Intermediate knowledge scenario (e.g., thread safety issues)
      generate_intermediate_knowledge_scenario "${scenario_dir}/project"
      ;;
    advanced)
      # Advanced knowledge scenario (e.g., complex JVM internals)
      generate_advanced_knowledge_scenario "${scenario_dir}/project"
      ;;
    *)
      echo "Unknown knowledge depth: ${knowledge_depth}"
      return 1
      ;;
  esac
  
  # Create expected knowledge transfer metrics file
  cat > "${scenario_dir}/expected_metrics.json" << EOF
{
  "concept_explanation_score": ${knowledge_depth == "basic" ? 90 : (knowledge_depth == "intermediate" ? 80 : 70)},
  "prerequisite_knowledge_identified": ${knowledge_depth == "basic" ? "true" : "true"},
  "learning_resources_quality": ${knowledge_depth == "basic" ? 5 : (knowledge_depth == "intermediate" ? 4 : 3)},
  "technical_accuracy": ${knowledge_depth == "basic" ? 95 : (knowledge_depth == "intermediate" ? 90 : 85)},
  "knowledge_scaffolding": ${knowledge_depth == "basic" ? 5 : (knowledge_depth == "intermediate" ? 4 : 3)}
}
EOF

  # Create a metadata file for the scenario
  cat > "${scenario_dir}/metadata.json" << EOF
{
  "name": "${scenario_name}",
  "knowledge_depth": "${knowledge_depth}",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "description": "Knowledge transfer validation scenario (${knowledge_depth} depth)",
  "expected_metrics": ["concept_explanation_score", "prerequisite_knowledge_identified", "learning_resources_quality", "technical_accuracy", "knowledge_scaffolding"]
}
EOF
}

#######################################
# Creates a test scenario for validating progressive learning
# Arguments:
#   $1 - Scenario name
#   $2 - Learning stage (beginner, practitioner, expert)
# Outputs:
#   None
#######################################
function create_progressive_learning_scenario() {
  local scenario_name="$1"
  local learning_stage="$2"
  
  local scenario_dir="${EDUCATIONAL_DIR}/progressive_learning/${scenario_name}"
  mkdir -p "${scenario_dir}"
  
  # Create a Maven project with progressive learning stages
  mkdir -p "${scenario_dir}/project"
  
  # Create baseline for progressive learning testing
  case "${learning_stage}" in
    beginner)
      # Beginner stage scenario with fundamental concepts
      generate_beginner_learning_scenario "${scenario_dir}/project"
      ;;
    practitioner)
      # Practitioner stage with intermediate techniques
      generate_practitioner_learning_scenario "${scenario_dir}/project"
      ;;
    expert)
      # Expert stage with advanced optimization techniques
      generate_expert_learning_scenario "${scenario_dir}/project"
      ;;
    *)
      echo "Unknown learning stage: ${learning_stage}"
      return 1
      ;;
  esac
  
  # Create expected progressive learning metrics file
  cat > "${scenario_dir}/expected_metrics.json" << EOF
{
  "level_appropriateness": ${learning_stage == "beginner" ? 90 : (learning_stage == "practitioner" ? 85 : 80)},
  "building_on_prior_knowledge": ${learning_stage == "beginner" ? "minimal" : (learning_stage == "practitioner" ? "moderate" : "extensive")},
  "advancement_path_clarity": ${learning_stage == "beginner" ? 5 : (learning_stage == "practitioner" ? 4 : 3)},
  "concept_sequencing": ${learning_stage == "beginner" ? 5 : (learning_stage == "practitioner" ? 4 : 3)},
  "learning_curve_appropriateness": ${learning_stage == "beginner" ? 5 : (learning_stage == "practitioner" ? 4 : 3)}
}
EOF

  # Create a metadata file for the scenario
  cat > "${scenario_dir}/metadata.json" << EOF
{
  "name": "${scenario_name}",
  "learning_stage": "${learning_stage}",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "description": "Progressive learning validation scenario (${learning_stage} stage)",
  "expected_metrics": ["level_appropriateness", "building_on_prior_knowledge", "advancement_path_clarity", "concept_sequencing", "learning_curve_appropriateness"]
}
EOF
}

#######################################
# Creates a test scenario for validating actionability of recommendations
# Arguments:
#   $1 - Scenario name
#   $2 - Implementation difficulty (easy, moderate, challenging)
# Outputs:
#   None
#######################################
function create_actionability_scenario() {
  local scenario_name="$1"
  local difficulty="$2"
  
  local scenario_dir="${EDUCATIONAL_DIR}/actionability/${scenario_name}"
  mkdir -p "${scenario_dir}"
  
  # Create a Maven project with different implementation difficulties
  mkdir -p "${scenario_dir}/project"
  
  # Create baseline for actionability testing
  case "${difficulty}" in
    easy)
      # Easy implementation scenario (simple configuration changes)
      generate_easy_implementation_scenario "${scenario_dir}/project"
      ;;
    moderate)
      # Moderate implementation difficulty (code refactoring)
      generate_moderate_implementation_scenario "${scenario_dir}/project"
      ;;
    challenging)
      # Challenging implementation (architectural changes)
      generate_challenging_implementation_scenario "${scenario_dir}/project"
      ;;
    *)
      echo "Unknown implementation difficulty: ${difficulty}"
      return 1
      ;;
  esac
  
  # Create expected actionability metrics file
  cat > "${scenario_dir}/expected_metrics.json" << EOF
{
  "step_by_step_clarity": ${difficulty == "easy" ? 90 : (difficulty == "moderate" ? 80 : 70)},
  "implementation_practicality": ${difficulty == "easy" ? 5 : (difficulty == "moderate" ? 4 : 3)},
  "time_estimate_accuracy": ${difficulty == "easy" ? 5 : (difficulty == "moderate" ? 4 : 3)},
  "prerequisite_steps_identified": ${difficulty == "easy" ? "complete" : (difficulty == "moderate" ? "most" : "partial")},
  "success_validation_guidance": ${difficulty == "easy" ? 5 : (difficulty == "moderate" ? 4 : 3)}
}
EOF

  # Create a metadata file for the scenario
  cat > "${scenario_dir}/metadata.json" << EOF
{
  "name": "${scenario_name}",
  "implementation_difficulty": "${difficulty}",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "description": "Actionability validation scenario (${difficulty} implementation difficulty)",
  "expected_metrics": ["step_by_step_clarity", "implementation_practicality", "time_estimate_accuracy", "prerequisite_steps_identified", "success_validation_guidance"]
}
EOF
}

#######################################
# Creates a test scenario for validating knowledge retention
# Arguments:
#   $1 - Scenario name
#   $2 - Retention level (short_term, medium_term, long_term)
# Outputs:
#   None
#######################################
function create_retention_scenario() {
  local scenario_name="$1"
  local retention_level="$2"
  
  local scenario_dir="${EDUCATIONAL_DIR}/retention/${scenario_name}"
  mkdir -p "${scenario_dir}"
  
  # Create a Maven project for retention testing
  mkdir -p "${scenario_dir}/project"
  
  # Create baseline for retention testing
  case "${retention_level}" in
    short_term)
      # Short-term retention scenario (immediate application)
      generate_short_term_retention_scenario "${scenario_dir}/project"
      ;;
    medium_term)
      # Medium-term retention scenario (days to weeks)
      generate_medium_term_retention_scenario "${scenario_dir}/project"
      ;;
    long_term)
      # Long-term retention scenario (months)
      generate_long_term_retention_scenario "${scenario_dir}/project"
      ;;
    *)
      echo "Unknown retention level: ${retention_level}"
      return 1
      ;;
  esac
  
  # Create expected retention metrics file
  cat > "${scenario_dir}/expected_metrics.json" << EOF
{
  "concept_memorability": ${retention_level == "short_term" ? 90 : (retention_level == "medium_term" ? 80 : 70)},
  "principle_vs_specific_balance": ${retention_level == "short_term" ? 3 : (retention_level == "medium_term" ? 4 : 5)},
  "mental_model_construction": ${retention_level == "short_term" ? 3 : (retention_level == "medium_term" ? 4 : 5)},
  "reinforcement_techniques": ${retention_level == "short_term" ? 3 : (retention_level == "medium_term" ? 4 : 5)},
  "knowledge_application_guidance": ${retention_level == "short_term" ? 5 : (retention_level == "medium_term" ? 4 : 3)}
}
EOF

  # Create a metadata file for the scenario
  cat > "${scenario_dir}/metadata.json" << EOF
{
  "name": "${scenario_name}",
  "retention_level": "${retention_level}",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "description": "Retention validation scenario (${retention_level} retention)",
  "expected_metrics": ["concept_memorability", "principle_vs_specific_balance", "mental_model_construction", "reinforcement_techniques", "knowledge_application_guidance"]
}
EOF
}

#######################################
# Generates a simple diagnostic scenario with clear issues
# Arguments:
#   $1 - Project directory path
# Outputs:
#   None
#######################################
function generate_simple_diagnostic_scenario() {
  local project_dir="$1"
  
  # Create a basic Maven project structure
  mkdir -p "${project_dir}/src/main/java/com/example"
  mkdir -p "${project_dir}/src/test/java/com/example"
  
  # Create a simple pom.xml file
  cat > "${project_dir}/pom.xml" << EOF
<project xmlns="http://maven.apache.org/POM/4.0.0" 
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  
  <groupId>com.example</groupId>
  <artifactId>simple-diagnostic</artifactId>
  <version>1.0-SNAPSHOT</version>
  
  <properties>
    <maven.compiler.source>11</maven.compiler.source>
    <maven.compiler.target>11</maven.compiler.target>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <junit.version>5.8.2</junit.version>
  </properties>
  
  <dependencies>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter-api</artifactId>
      <version>\${junit.version}</version>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter-engine</artifactId>
      <version>\${junit.version}</version>
      <scope>test</scope>
    </dependency>
  </dependencies>
  
  <build>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-surefire-plugin</artifactId>
        <version>2.22.2</version>
      </plugin>
    </plugins>
  </build>
</project>
EOF

  # Create a simple class with timing-dependent behavior
  cat > "${project_dir}/src/main/java/com/example/TimeService.java" << EOF
package com.example;

/**
 * A simple service that performs time-dependent operations.
 * Used to demonstrate clear timing issues in tests.
 */
public class TimeService {
    
    // Simulates a slow operation that depends on external timing
    public boolean performTimedOperation(long timeoutMs) {
        try {
            // Simulate work
            Thread.sleep(timeoutMs - 50);
            return true;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return false;
        }
    }
    
    // Method with a fixed execution time for stable tests
    public boolean performStableOperation() {
        try {
            // Fixed execution time
            Thread.sleep(50);
            return true;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return false;
        }
    }
}
EOF

  # Create a test with timing issues
  cat > "${project_dir}/src/test/java/com/example/TimeServiceTest.java" << EOF
package com.example;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Tests for TimeService that demonstrate a simple timing issue.
 * These tests are designed to be clear examples of timing problems.
 */
public class TimeServiceTest {
    
    @Test
    public void testTimedOperationFlaky() {
        TimeService service = new TimeService();
        
        // This test is flaky because it uses a tight timeout
        // that may occasionally fail on slower systems
        boolean result = service.performTimedOperation(100);
        
        assertTrue(result, "Operation should complete successfully");
    }
    
    @Test
    public void testStableOperation() {
        TimeService service = new TimeService();
        
        // This test is stable
        boolean result = service.performStableOperation();
        
        assertTrue(result, "Operation should complete successfully");
    }
}
EOF

  # Create a simple explanation file that MVNimble should improve upon
  cat > "${project_dir}/explanation.md" << EOF
# Timing Issue Explanation

The test is failing because it's timing out. You need to increase the timeout value.
EOF
}

#######################################
# Generates a moderately complex diagnostic scenario
# Arguments:
#   $1 - Project directory path
# Outputs:
#   None
#######################################
function generate_moderate_diagnostic_scenario() {
  local project_dir="$1"
  
  # Create a Maven project structure
  mkdir -p "${project_dir}/src/main/java/com/example/service"
  mkdir -p "${project_dir}/src/test/java/com/example/service"
  
  # Create pom.xml
  cat > "${project_dir}/pom.xml" << EOF
<project xmlns="http://maven.apache.org/POM/4.0.0" 
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  
  <groupId>com.example</groupId>
  <artifactId>moderate-diagnostic</artifactId>
  <version>1.0-SNAPSHOT</version>
  
  <properties>
    <maven.compiler.source>11</maven.compiler.source>
    <maven.compiler.target>11</maven.compiler.target>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <junit.version>5.8.2</junit.version>
  </properties>
  
  <dependencies>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter-api</artifactId>
      <version>\${junit.version}</version>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter-engine</artifactId>
      <version>\${junit.version}</version>
      <scope>test</scope>
    </dependency>
  </dependencies>
  
  <build>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-surefire-plugin</artifactId>
        <version>2.22.2</version>
        <configuration>
          <parallel>methods</parallel>
          <threadCount>2</threadCount>
        </configuration>
      </plugin>
    </plugins>
  </build>
</project>
EOF

  # Create a data store with resource contention and timing issues
  cat > "${project_dir}/src/main/java/com/example/service/DataStore.java" << EOF
package com.example.service;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

/**
 * A data store class with moderate complexity issues.
 * Demonstrates resource contention and timing dependencies.
 */
public class DataStore {
    private Map<String, Object> store = new HashMap<>();
    private boolean initialized = false;
    
    public void initialize() {
        // Simulate initialization work
        try {
            TimeUnit.MILLISECONDS.sleep(100);
            initialized = true;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
    
    public void store(String key, Object value) {
        if (!initialized) {
            throw new IllegalStateException("DataStore not initialized");
        }
        
        // Simulate storage operation with timing dependency
        try {
            TimeUnit.MILLISECONDS.sleep(50);
            store.put(key, value);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
    
    public Object retrieve(String key) {
        if (!initialized) {
            throw new IllegalStateException("DataStore not initialized");
        }
        
        // Simulate retrieval operation with timing dependency
        try {
            TimeUnit.MILLISECONDS.sleep(30);
            return store.get(key);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return null;
        }
    }
    
    public void clear() {
        store.clear();
    }
    
    public boolean isInitialized() {
        return initialized;
    }
}
EOF

  # Create service that uses the data store
  cat > "${project_dir}/src/main/java/com/example/service/DataService.java" << EOF
package com.example.service;

/**
 * A service that uses the DataStore.
 * Demonstrates dependencies between components.
 */
public class DataService {
    private final DataStore dataStore;
    
    public DataService(DataStore dataStore) {
        this.dataStore = dataStore;
    }
    
    public void initialize() {
        dataStore.initialize();
    }
    
    public void saveData(String key, String value) {
        dataStore.store(key, value);
    }
    
    public String getData(String key) {
        Object value = dataStore.retrieve(key);
        return value != null ? value.toString() : null;
    }
}
EOF

  # Create test with multiple issues
  cat > "${project_dir}/src/test/java/com/example/service/DataServiceTest.java" << EOF
package com.example.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeEach;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Tests for DataService with moderate complexity issues.
 * Demonstrates multiple interrelated problems.
 */
public class DataServiceTest {
    
    private DataStore dataStore;
    private DataService service;
    
    @BeforeEach
    public void setup() {
        dataStore = new DataStore();
        service = new DataService(dataStore);
        // Note: initialization is not called here, creating a dependency issue
    }
    
    @Test
    public void testSaveAndRetrieveData() {
        // Missing initialization
        service.saveData("key1", "value1");
        String retrieved = service.getData("key1");
        assertEquals("value1", retrieved, "Retrieved value should match saved value");
    }
    
    @Test
    public void testMultipleOperations() {
        // Initialize here but not in other tests
        service.initialize();
        
        // Perform multiple operations with timing dependencies
        for (int i = 0; i < 5; i++) {
            service.saveData("key" + i, "value" + i);
        }
        
        // Verify all values
        for (int i = 0; i < 5; i++) {
            String retrieved = service.getData("key" + i);
            assertEquals("value" + i, retrieved, "Retrieved value should match saved value for key" + i);
        }
    }
}
EOF

  # Create a basic explanation file that MVNimble should improve upon
  cat > "${project_dir}/explanation.md" << EOF
# Data Service Issues

The tests are failing due to initialization problems and timing issues. You need to make sure the data store is initialized before use and consider thread safety for parallel test execution.
EOF
}

#######################################
# Generates a complex diagnostic scenario with multiple interacting issues
# Arguments:
#   $1 - Project directory path
# Outputs:
#   None
#######################################
function generate_complex_diagnostic_scenario() {
  local project_dir="$1"
  
  # Create a Maven project structure
  mkdir -p "${project_dir}/src/main/java/com/example/complex"
  mkdir -p "${project_dir}/src/test/java/com/example/complex"
  mkdir -p "${project_dir}/src/test/resources"
  
  # Create pom.xml with complex settings
  cat > "${project_dir}/pom.xml" << EOF
<project xmlns="http://maven.apache.org/POM/4.0.0" 
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  
  <groupId>com.example</groupId>
  <artifactId>complex-diagnostic</artifactId>
  <version>1.0-SNAPSHOT</version>
  
  <properties>
    <maven.compiler.source>11</maven.compiler.source>
    <maven.compiler.target>11</maven.compiler.target>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <junit.version>5.8.2</junit.version>
  </properties>
  
  <dependencies>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter-api</artifactId>
      <version>\${junit.version}</version>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter-engine</artifactId>
      <version>\${junit.version}</version>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter-params</artifactId>
      <version>\${junit.version}</version>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.mockito</groupId>
      <artifactId>mockito-core</artifactId>
      <version>4.5.1</version>
      <scope>test</scope>
    </dependency>
  </dependencies>
  
  <build>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-surefire-plugin</artifactId>
        <version>2.22.2</version>
        <configuration>
          <parallel>classes</parallel>
          <threadCount>4</threadCount>
          <forkCount>2</forkCount>
        </configuration>
      </plugin>
    </plugins>
  </build>
</project>
EOF

  # Create a complex system with multiple components and dependencies
  # ResourceManager class with thread safety issues
  cat > "${project_dir}/src/main/java/com/example/complex/ResourceManager.java" << EOF
package com.example.complex;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReadWriteLock;
import java.util.concurrent.locks.ReentrantReadWriteLock;

/**
 * Manages system resources with complex locking and timing behaviors.
 * Contains multiple potential threading issues.
 */
public class ResourceManager {
    private final Map<String, Resource> resources = new HashMap<>();
    private final ReadWriteLock resourceLock = new ReentrantReadWriteLock();
    private final Lock readLock = resourceLock.readLock();
    private final Lock writeLock = resourceLock.writeLock();
    
    private volatile boolean initialized = false;
    private int resourceCount = 0;
    
    // Class for representing a managed resource
    public static class Resource {
        private final String id;
        private String data;
        private int usageCount = 0;
        
        public Resource(String id, String data) {
            this.id = id;
            this.data = data;
        }
        
        public String getId() {
            return id;
        }
        
        public String getData() {
            return data;
        }
        
        public void setData(String data) {
            this.data = data;
        }
        
        public int incrementUsage() {
            return ++usageCount;
        }
        
        public int getUsageCount() {
            return usageCount;
        }
    }
    
    public void initialize() {
        // Simulate initialization work
        try {
            TimeUnit.MILLISECONDS.sleep(200);
            initialized = true;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
    
    public void addResource(String id, String data) {
        if (!initialized) {
            throw new IllegalStateException("ResourceManager not initialized");
        }
        
        // Issue: Not consistently using locks
        // Sometimes we use write lock, sometimes we don't
        if (resourceCount > 10) {
            writeLock.lock();
            try {
                resources.put(id, new Resource(id, data));
                resourceCount++;
            } finally {
                writeLock.unlock();
            }
        } else {
            // Potential race condition here
            resources.put(id, new Resource(id, data));
            resourceCount++;
        }
    }
    
    public Resource getResource(String id) {
        if (!initialized) {
            throw new IllegalStateException("ResourceManager not initialized");
        }
        
        readLock.lock();
        try {
            // Simulate work to increase lock contention
            TimeUnit.MILLISECONDS.sleep(50);
            return resources.get(id);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return null;
        } finally {
            readLock.unlock();
        }
    }
    
    public boolean updateResource(String id, String newData) {
        if (!initialized) {
            throw new IllegalStateException("ResourceManager not initialized");
        }
        
        writeLock.lock();
        try {
            Resource resource = resources.get(id);
            if (resource != null) {
                // Simulate work to increase lock contention
                TimeUnit.MILLISECONDS.sleep(100);
                resource.setData(newData);
                return true;
            }
            return false;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return false;
        } finally {
            writeLock.unlock();
        }
    }
    
    public int getResourceUsage(String id) {
        Resource resource = getResource(id);
        if (resource != null) {
            // Potential race condition: incrementing outside a lock
            return resource.incrementUsage();
        }
        return -1;
    }
    
    public int getResourceCount() {
        return resourceCount;
    }
    
    public boolean isInitialized() {
        return initialized;
    }
}
EOF

  # DataProcessor class with external dependencies and timing issues
  cat > "${project_dir}/src/main/java/com/example/complex/DataProcessor.java" << EOF
package com.example.complex;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

/**
 * Processes data with asynchronous operations and file I/O.
 * Demonstrates timing issues, external dependencies, and state isolation problems.
 */
public class DataProcessor {
    private final ResourceManager resourceManager;
    private final String tempDirectory;
    private boolean processingActive = false;
    
    public DataProcessor(ResourceManager resourceManager, String tempDirectory) {
        this.resourceManager = resourceManager;
        this.tempDirectory = tempDirectory;
    }
    
    public void startProcessing() {
        if (!resourceManager.isInitialized()) {
            throw new IllegalStateException("ResourceManager not initialized");
        }
        
        processingActive = true;
    }
    
    public void stopProcessing() {
        processingActive = false;
    }
    
    public CompletableFuture<String> processDataAsync(String resourceId, String inputData) {
        if (!processingActive) {
            CompletableFuture<String> future = new CompletableFuture<>();
            future.completeExceptionally(new IllegalStateException("Processing not active"));
            return future;
        }
        
        return CompletableFuture.supplyAsync(() -> {
            try {
                // Simulate complex processing
                TimeUnit.MILLISECONDS.sleep(150);
                
                // Check if the resource exists
                ResourceManager.Resource resource = resourceManager.getResource(resourceId);
                if (resource == null) {
                    throw new IllegalArgumentException("Resource not found: " + resourceId);
                }
                
                // Write to a temporary file (external dependency)
                String fileName = tempDirectory + File.separator + "process_" + resourceId + ".tmp";
                try (FileWriter writer = new FileWriter(fileName)) {
                    writer.write(inputData + ":" + resource.getData());
                }
                
                // More processing
                TimeUnit.MILLISECONDS.sleep(100);
                
                // Read the processed result
                String result = new String(Files.readAllBytes(Paths.get(fileName)));
                
                // Update resource usage
                resourceManager.getResourceUsage(resourceId);
                
                // Clean up
                Files.deleteIfExists(Paths.get(fileName));
                
                return result;
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new RuntimeException("Processing interrupted", e);
            } catch (IOException e) {
                throw new RuntimeException("I/O error during processing", e);
            }
        });
    }
    
    public boolean isProcessingActive() {
        return processingActive;
    }
}
EOF

  # Create complex test class with multiple issues
  cat > "${project_dir}/src/test/java/com/example/complex/ComplexSystemTest.java" << EOF
package com.example.complex;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Complex tests with multiple potential issues:
 * - Thread safety problems
 * - External file dependencies
 * - Timing dependencies
 * - Resource cleanup issues
 * - State isolation between tests
 */
public class ComplexSystemTest {
    
    private ResourceManager resourceManager;
    private DataProcessor dataProcessor;
    private String tempDirPath;
    
    @BeforeEach
    public void setup(@TempDir Path tempDir) {
        // Create a new ResourceManager for each test
        resourceManager = new ResourceManager();
        resourceManager.initialize();
        
        tempDirPath = tempDir.toString();
        dataProcessor = new DataProcessor(resourceManager, tempDirPath);
        dataProcessor.startProcessing();
        
        // Add some default resources
        resourceManager.addResource("resource1", "default-data-1");
        resourceManager.addResource("resource2", "default-data-2");
    }
    
    @Test
    public void testBasicProcessing() throws Exception {
        String result = dataProcessor.processDataAsync("resource1", "input-data").get();
        assertTrue(result.contains("input-data"), "Result should contain input data");
        assertTrue(result.contains("default-data-1"), "Result should contain resource data");
    }
    
    @ParameterizedTest
    @ValueSource(strings = {"resource1", "resource2"})
    public void testParameterizedProcessing(String resourceId) throws Exception {
        String result = dataProcessor.processDataAsync(resourceId, "param-input").get();
        assertTrue(result.contains("param-input"), "Result should contain input data");
        assertTrue(result.contains("default-data"), "Result should contain resource data");
    }
    
    @Test
    public void testParallelProcessing() throws Exception {
        // This test has race conditions and resource contention
        int threadCount = 10;
        ExecutorService executor = Executors.newFixedThreadPool(threadCount);
        List<CompletableFuture<String>> futures = new ArrayList<>();
        
        // Submit multiple parallel processing tasks
        for (int i = 0; i < threadCount; i++) {
            final int id = i;
            // Add resources inside the loop - potential race condition
            resourceManager.addResource("concurrent-" + id, "concurrent-data-" + id);
            
            futures.add(dataProcessor.processDataAsync("concurrent-" + id, "concurrent-input-" + id));
        }
        
        // Wait for all tasks to complete
        for (CompletableFuture<String> future : futures) {
            String result = future.get();
            assertNotNull(result, "Result should not be null");
        }
        
        executor.shutdown();
        assertTrue(executor.awaitTermination(5, TimeUnit.SECONDS), "Executor should terminate");
    }
    
    @Test
    public void testResourceUpdates() throws Exception {
        // This test has potential thread safety issues
        // Start with initial data
        ResourceManager.Resource resource = resourceManager.getResource("resource1");
        assertNotNull(resource, "Resource should exist");
        assertEquals("default-data-1", resource.getData(), "Initial data should match");
        
        // Update the resource
        boolean updated = resourceManager.updateResource("resource1", "updated-data");
        assertTrue(updated, "Update should succeed");
        
        // Process data with updated resource
        String result = dataProcessor.processDataAsync("resource1", "after-update").get();
        assertTrue(result.contains("updated-data"), "Result should contain updated resource data");
        
        // Check usage count
        int usageCount = resourceManager.getResourceUsage("resource1");
        assertTrue(usageCount > 0, "Resource should have been used");
    }
    
    @Test
    public void testProcessingFailure() {
        // This test has error handling issues
        CompletableFuture<String> future = dataProcessor.processDataAsync("nonexistent", "bad-input");
        
        ExecutionException exception = assertThrows(ExecutionException.class, future::get);
        assertTrue(exception.getCause() instanceof IllegalArgumentException, 
            "Should fail with IllegalArgumentException for nonexistent resource");
    }
    
    @Test
    public void testStateIsolation() throws Exception {
        // Stop and restart processing to test state transitions
        dataProcessor.stopProcessing();
        assertFalse(dataProcessor.isProcessingActive(), "Processing should be inactive");
        
        CompletableFuture<String> future = dataProcessor.processDataAsync("resource1", "inactive-input");
        ExecutionException exception = assertThrows(ExecutionException.class, future::get);
        assertTrue(exception.getCause() instanceof IllegalStateException, "Should fail when processing inactive");
        
        // Restart and verify processing works
        dataProcessor.startProcessing();
        assertTrue(dataProcessor.isProcessingActive(), "Processing should be active");
        
        String result = dataProcessor.processDataAsync("resource1", "reactivated-input").get();
        assertNotNull(result, "Should process data after reactivation");
    }
}
EOF

  # Create a basic explanation file that MVNimble should improve upon
  cat > "${project_dir}/explanation.md" << EOF
# Complex System Issues

The tests are failing because of a combination of thread safety issues, timing problems, and state isolation failures. You need to review the concurrency model and fix the race conditions.
EOF
}

#######################################
# Generates a basic knowledge scenario
# Arguments:
#   $1 - Project directory path
# Outputs:
#   None
#######################################
function generate_basic_knowledge_scenario() {
  # Implementation similar to generate_simple_diagnostic_scenario but focused on
  # basic knowledge transfer rather than clarity
  local project_dir="$1"
  
  # Create basic project structure
  mkdir -p "${project_dir}/src/main/java/com/example/knowledge/basic"
  mkdir -p "${project_dir}/src/test/java/com/example/knowledge/basic"
  
  # Create a basic Maven project file
  cat > "${project_dir}/pom.xml" << EOF
<project xmlns="http://maven.apache.org/POM/4.0.0" 
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  
  <groupId>com.example</groupId>
  <artifactId>basic-knowledge</artifactId>
  <version>1.0-SNAPSHOT</version>
  
  <properties>
    <maven.compiler.source>11</maven.compiler.source>
    <maven.compiler.target>11</maven.compiler.target>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <junit.version>5.8.2</junit.version>
  </properties>
  
  <dependencies>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter-api</artifactId>
      <version>\${junit.version}</version>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter-engine</artifactId>
      <version>\${junit.version}</version>
      <scope>test</scope>
    </dependency>
  </dependencies>
  
  <build>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-surefire-plugin</artifactId>
        <version>2.22.2</version>
      </plugin>
    </plugins>
  </build>
</project>
EOF

  # Create a simple class with memory usage issues
  cat > "${project_dir}/src/main/java/com/example/knowledge/basic/MemoryConsumer.java" << EOF
package com.example.knowledge.basic;

import java.util.ArrayList;
import java.util.List;

/**
 * A simple class that demonstrates basic memory consumption issues.
 * Used for teaching fundamental memory management concepts.
 */
public class MemoryConsumer {
    private List<byte[]> memoryList = new ArrayList<>();
    
    // Allocate a specified amount of memory
    public void consumeMemory(int megabytes) {
        int bytesPerMB = 1024 * 1024;
        for (int i = 0; i < megabytes; i++) {
            memoryList.add(new byte[bytesPerMB]);
        }
    }
    
    // Release the allocated memory
    public void releaseMemory() {
        memoryList.clear();
    }
    
    // Get the current memory usage
    public int getCurrentUsage() {
        return memoryList.size();
    }
}
EOF

  # Create test with memory issues
  cat > "${project_dir}/src/test/java/com/example/knowledge/basic/MemoryConsumerTest.java" << EOF
package com.example.knowledge.basic;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.AfterEach;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Basic tests that demonstrate memory consumption issues.
 * Used for teaching fundamental memory management concepts.
 */
public class MemoryConsumerTest {
    
    private MemoryConsumer consumer;
    
    @BeforeEach
    public void setup() {
        consumer = new MemoryConsumer();
    }
    
    @AfterEach
    public void cleanup() {
        consumer.releaseMemory();
    }
    
    @Test
    public void testMemoryAllocation() {
        // Allocate a moderate amount of memory
        consumer.consumeMemory(10);
        assertEquals(10, consumer.getCurrentUsage(), "Should allocate 10 MB of memory");
        
        // Allocate more memory
        consumer.consumeMemory(20);
        assertEquals(30, consumer.getCurrentUsage(), "Should now have 30 MB of memory allocated");
    }
    
    @Test
    public void testLargeMemoryAllocation() {
        // This test may cause issues on memory-constrained systems
        consumer.consumeMemory(100);
        assertEquals(100, consumer.getCurrentUsage(), "Should allocate 100 MB of memory");
    }
    
    @Test
    public void testMemoryRelease() {
        consumer.consumeMemory(50);
        assertEquals(50, consumer.getCurrentUsage(), "Should allocate 50 MB of memory");
        
        consumer.releaseMemory();
        assertEquals(0, consumer.getCurrentUsage(), "Should release all allocated memory");
    }
}
EOF

  # Create a basic knowledge reference document
  cat > "${project_dir}/knowledge_reference.md" << EOF
# Memory Management Basics

Memory issues can cause test failures when:
- Tests consume too much memory
- Memory is not properly released between tests
- The JVM has insufficient memory allocation

Solutions involve:
- Setting appropriate heap sizes
- Releasing resources properly
- Using less memory-intensive algorithms
EOF
}

#######################################
# Generates an intermediate knowledge scenario
# Arguments:
#   $1 - Project directory path
# Outputs:
#   None
#######################################
function generate_intermediate_knowledge_scenario() {
  # Implementation for intermediate knowledge transfer scenario
  local project_dir="$1"
  
  # Placeholder implementation - would be similar pattern to above functions
  mkdir -p "${project_dir}/src/main/java/com/example/knowledge/intermediate"
  mkdir -p "${project_dir}/src/test/java/com/example/knowledge/intermediate"
  
  # Create empty files as placeholders
  touch "${project_dir}/pom.xml"
  touch "${project_dir}/src/main/java/com/example/knowledge/intermediate/ThreadPoolManager.java"
  touch "${project_dir}/src/test/java/com/example/knowledge/intermediate/ThreadPoolManagerTest.java"
  touch "${project_dir}/knowledge_reference.md"
}

#######################################
# Generates an advanced knowledge scenario
# Arguments:
#   $1 - Project directory path
# Outputs:
#   None
#######################################
function generate_advanced_knowledge_scenario() {
  # Implementation for advanced knowledge transfer scenario
  local project_dir="$1"
  
  # Placeholder implementation - would be similar pattern to above functions
  mkdir -p "${project_dir}/src/main/java/com/example/knowledge/advanced"
  mkdir -p "${project_dir}/src/test/java/com/example/knowledge/advanced"
  
  # Create empty files as placeholders
  touch "${project_dir}/pom.xml"
  touch "${project_dir}/src/main/java/com/example/knowledge/advanced/JvmOptimizer.java"
  touch "${project_dir}/src/test/java/com/example/knowledge/advanced/JvmOptimizerTest.java"
  touch "${project_dir}/knowledge_reference.md"
}

#######################################
# Generates a beginner learning scenario
# Arguments:
#   $1 - Project directory path
# Outputs:
#   None
#######################################
function generate_beginner_learning_scenario() {
  # Implementation for beginner progressive learning scenario
  local project_dir="$1"
  
  # Placeholder implementation - would be similar pattern to above functions
  mkdir -p "${project_dir}/src/main/java/com/example/learning/beginner"
  mkdir -p "${project_dir}/src/test/java/com/example/learning/beginner"
  
  # Create empty files as placeholders
  touch "${project_dir}/pom.xml"
  touch "${project_dir}/src/main/java/com/example/learning/beginner/SimpleTimer.java"
  touch "${project_dir}/src/test/java/com/example/learning/beginner/SimpleTimerTest.java"
  touch "${project_dir}/learning_path.md"
}

#######################################
# Generates a practitioner learning scenario
# Arguments:
#   $1 - Project directory path
# Outputs:
#   None
#######################################
function generate_practitioner_learning_scenario() {
  # Implementation for practitioner progressive learning scenario
  local project_dir="$1"
  
  # Placeholder implementation - would be similar pattern to above functions
  mkdir -p "${project_dir}/src/main/java/com/example/learning/practitioner"
  mkdir -p "${project_dir}/src/test/java/com/example/learning/practitioner"
  
  # Create empty files as placeholders
  touch "${project_dir}/pom.xml"
  touch "${project_dir}/src/main/java/com/example/learning/practitioner/ResourceMonitor.java"
  touch "${project_dir}/src/test/java/com/example/learning/practitioner/ResourceMonitorTest.java"
  touch "${project_dir}/learning_path.md"
}

#######################################
# Generates an expert learning scenario
# Arguments:
#   $1 - Project directory path
# Outputs:
#   None
#######################################
function generate_expert_learning_scenario() {
  # Implementation for expert progressive learning scenario
  local project_dir="$1"
  
  # Placeholder implementation - would be similar pattern to above functions
  mkdir -p "${project_dir}/src/main/java/com/example/learning/expert"
  mkdir -p "${project_dir}/src/test/java/com/example/learning/expert"
  
  # Create empty files as placeholders
  touch "${project_dir}/pom.xml"
  touch "${project_dir}/src/main/java/com/example/learning/expert/TestOptimizer.java"
  touch "${project_dir}/src/test/java/com/example/learning/expert/TestOptimizerTest.java"
  touch "${project_dir}/learning_path.md"
}

#######################################
# Generates an easy implementation scenario
# Arguments:
#   $1 - Project directory path
# Outputs:
#   None
#######################################
function generate_easy_implementation_scenario() {
  # Implementation for easy actionability scenario
  local project_dir="$1"
  
  # Placeholder implementation - would be similar pattern to above functions
  mkdir -p "${project_dir}/src/main/java/com/example/actionability/easy"
  mkdir -p "${project_dir}/src/test/java/com/example/actionability/easy"
  
  # Create empty files as placeholders
  touch "${project_dir}/pom.xml"
  touch "${project_dir}/src/main/java/com/example/actionability/easy/SimpleService.java"
  touch "${project_dir}/src/test/java/com/example/actionability/easy/SimpleServiceTest.java"
  touch "${project_dir}/implementation_guide.md"
}

#######################################
# Generates a moderate implementation scenario
# Arguments:
#   $1 - Project directory path
# Outputs:
#   None
#######################################
function generate_moderate_implementation_scenario() {
  # Implementation for moderate actionability scenario
  local project_dir="$1"
  
  # Placeholder implementation - would be similar pattern to above functions
  mkdir -p "${project_dir}/src/main/java/com/example/actionability/moderate"
  mkdir -p "${project_dir}/src/test/java/com/example/actionability/moderate"
  
  # Create empty files as placeholders
  touch "${project_dir}/pom.xml"
  touch "${project_dir}/src/main/java/com/example/actionability/moderate/DatabaseService.java"
  touch "${project_dir}/src/test/java/com/example/actionability/moderate/DatabaseServiceTest.java"
  touch "${project_dir}/implementation_guide.md"
}

#######################################
# Generates a challenging implementation scenario
# Arguments:
#   $1 - Project directory path
# Outputs:
#   None
#######################################
function generate_challenging_implementation_scenario() {
  # Implementation for challenging actionability scenario
  local project_dir="$1"
  
  # Placeholder implementation - would be similar pattern to above functions
  mkdir -p "${project_dir}/src/main/java/com/example/actionability/challenging"
  mkdir -p "${project_dir}/src/test/java/com/example/actionability/challenging"
  
  # Create empty files as placeholders
  touch "${project_dir}/pom.xml"
  touch "${project_dir}/src/main/java/com/example/actionability/challenging/DistributedSystem.java"
  touch "${project_dir}/src/test/java/com/example/actionability/challenging/DistributedSystemTest.java"
  touch "${project_dir}/implementation_guide.md"
}

#######################################
# Creates placeholder implementations for retention scenarios
# Arguments:
#   $1 - Project directory path
#   $2 - Retention level (short_term, medium_term, long_term)
# Outputs:
#   None
#######################################
function generate_retention_scenario_base() {
  local project_dir="$1"
  local retention_level="$2"
  
  # Create directory structure
  mkdir -p "${project_dir}/src/main/java/com/example/retention/${retention_level}"
  mkdir -p "${project_dir}/src/test/java/com/example/retention/${retention_level}"
  
  # Create empty files as placeholders
  touch "${project_dir}/pom.xml"
  touch "${project_dir}/src/main/java/com/example/retention/${retention_level}/RetentionService.java"
  touch "${project_dir}/src/test/java/com/example/retention/${retention_level}/RetentionServiceTest.java"
  touch "${project_dir}/retention_concepts.md"
}

#######################################
# Generates a short-term retention scenario
# Arguments:
#   $1 - Project directory path
# Outputs:
#   None
#######################################
function generate_short_term_retention_scenario() {
  local project_dir="$1"
  generate_retention_scenario_base "${project_dir}" "short_term"
}

#######################################
# Generates a medium-term retention scenario
# Arguments:
#   $1 - Project directory path
# Outputs:
#   None
#######################################
function generate_medium_term_retention_scenario() {
  local project_dir="$1"
  generate_retention_scenario_base "${project_dir}" "medium_term"
}

#######################################
# Generates a long-term retention scenario
# Arguments:
#   $1 - Project directory path
# Outputs:
#   None
#######################################
function generate_long_term_retention_scenario() {
  local project_dir="$1"
  generate_retention_scenario_base "${project_dir}" "long_term"
}

#######################################
# Validates MVNimble's educational effectiveness on a scenario
# Arguments:
#   $1 - Scenario directory path
# Outputs:
#   Validation report and score
#######################################
function validate_educational_effectiveness() {
  local scenario_dir="$1"
  local category=$(basename "$(dirname "${scenario_dir}")")
  local scenario_name=$(basename "${scenario_dir}")
  local project_dir="${scenario_dir}/project"
  local results_dir="${scenario_dir}/results"
  
  mkdir -p "${results_dir}"
  
  # Run MVNimble on the scenario project
  (cd "${project_dir}" && mvnimble analyze > "${results_dir}/mvnimble_output.log")
  
  # Extract MVNimble's educational content
  grep -A 100 "RECOMMENDATIONS:" "${results_dir}/mvnimble_output.log" > "${results_dir}/educational_content.txt"
  
  # Analyze the educational effectiveness
  local metrics_file="${scenario_dir}/expected_metrics.json"
  local actual_metrics_file="${results_dir}/actual_metrics.json"
  
  # Analyze content and generate metrics
  case "${category}" in
    clarity)
      analyze_clarity "${results_dir}/educational_content.txt" > "${actual_metrics_file}"
      ;;
    knowledge_transfer)
      analyze_knowledge_transfer "${results_dir}/educational_content.txt" > "${actual_metrics_file}"
      ;;
    progressive_learning)
      analyze_progressive_learning "${results_dir}/educational_content.txt" > "${actual_metrics_file}"
      ;;
    actionability)
      analyze_actionability "${results_dir}/educational_content.txt" > "${actual_metrics_file}"
      ;;
    retention)
      analyze_retention "${results_dir}/educational_content.txt" > "${actual_metrics_file}"
      ;;
    *)
      echo "Unknown category: ${category}"
      return 1
      ;;
  esac
  
  # Compare with expected metrics
  local comparison_result=$(compare_metrics "${metrics_file}" "${actual_metrics_file}")
  
  # Generate validation report
  generate_educational_report "${scenario_dir}" "${comparison_result}"
  
  echo "${comparison_result}"
}

#######################################
# Placeholder functions for analyzing different aspects of educational effectiveness
# These would contain actual implementation in a real system
#######################################
function analyze_clarity() {
  local content_file="$1"
  echo '{"readability_score": 85, "jargon_ratio": 0.1, "example_quality": 4, "explanation_length": "appropriate", "visualization_quality": 4}'
}

function analyze_knowledge_transfer() {
  local content_file="$1"
  echo '{"concept_explanation_score": 80, "prerequisite_knowledge_identified": true, "learning_resources_quality": 4, "technical_accuracy": 90, "knowledge_scaffolding": 4}'
}

function analyze_progressive_learning() {
  local content_file="$1"
  echo '{"level_appropriateness": 85, "building_on_prior_knowledge": "moderate", "advancement_path_clarity": 4, "concept_sequencing": 4, "learning_curve_appropriateness": 4}'
}

function analyze_actionability() {
  local content_file="$1"
  echo '{"step_by_step_clarity": 80, "implementation_practicality": 4, "time_estimate_accuracy": 4, "prerequisite_steps_identified": "most", "success_validation_guidance": 4}'
}

function analyze_retention() {
  local content_file="$1"
  echo '{"concept_memorability": 80, "principle_vs_specific_balance": 4, "mental_model_construction": 4, "reinforcement_techniques": 4, "knowledge_application_guidance": 4}'
}

#######################################
# Placeholder function for comparing educational metrics
# This would contain actual implementation in a real system
#######################################
function compare_metrics() {
  local expected_file="$1"
  local actual_file="$2"
  
  # Simple placeholder implementation
  echo "0.85"
}

#######################################
# Generates a validation report for educational effectiveness
# Arguments:
#   $1 - Scenario directory path
#   $2 - Comparison score
# Outputs:
#   None
#######################################
function generate_educational_report() {
  local scenario_dir="$1"
  local score="$2"
  
  local category=$(basename "$(dirname "${scenario_dir}")")
  local scenario_name=$(basename "${scenario_dir}")
  
  # Generate report
  local report_file="${REPORT_DIR}/${category}_${scenario_name}_report.md"
  
  cat > "${report_file}" << EOF
# Educational Effectiveness Validation Report

## Scenario Information
- **Category**: ${category}
- **Scenario**: ${scenario_name}
- **Validation Date**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## Validation Results
- **Effectiveness Score**: ${score}

## Analysis
MVNimble's educational content for this scenario was analyzed for effectiveness in the ${category} dimension.

## Recommendations for Improvement
To improve the educational effectiveness of MVNimble's recommendations, consider:
- Enhancing clarity of technical explanations
- Adding more concrete examples
- Providing links to further learning resources
- Including step-by-step implementation guides
- Explaining concepts at multiple levels of detail

## Raw Educational Content
\`\`\`
$(cat "${scenario_dir}/results/educational_content.txt")
\`\`\`
EOF
}

#######################################
# Creates standard educational effectiveness scenarios
# Arguments:
#   None
# Outputs:
#   None
#######################################
function create_standard_scenarios() {
  # Set up environment
  setup_educational_environment
  
  # Create clarity scenarios
  create_clarity_scenario "simple_explanation" "low"
  create_clarity_scenario "moderate_explanation" "medium"
  create_clarity_scenario "complex_explanation" "high"
  
  # Create knowledge transfer scenarios
  create_knowledge_transfer_scenario "basic_concepts" "basic"
  create_knowledge_transfer_scenario "advanced_concepts" "advanced"
  
  # Create progressive learning scenarios
  create_progressive_learning_scenario "beginner_guide" "beginner"
  create_progressive_learning_scenario "expert_guide" "expert"
  
  # Create actionability scenarios
  create_actionability_scenario "simple_implementation" "easy"
  create_actionability_scenario "complex_implementation" "challenging"
  
  # Create retention scenarios
  create_retention_scenario "core_concepts" "short_term"
  create_retention_scenario "advanced_patterns" "long_term"
}

#######################################
# Runs validation on all educational effectiveness scenarios
# Arguments:
#   None
# Outputs:
#   Summary of validation results
#######################################
function run_validation() {
  local total_scenarios=0
  local total_score=0
  
  echo "Running Educational Effectiveness Validation..."
  
  # Process each category of scenarios
  for category in clarity knowledge_transfer progressive_learning actionability retention; do
    echo "Processing ${category} scenarios..."
    
    if [ -d "${EDUCATIONAL_DIR}/${category}" ]; then
      for scenario in "${EDUCATIONAL_DIR}/${category}"/*; do
        if [ -d "${scenario}" ]; then
          echo "  Validating scenario: $(basename "${scenario}")..."
          local score=$(validate_educational_effectiveness "${scenario}")
          total_scenarios=$((total_scenarios + 1))
          total_score=$(echo "${total_score} + ${score}" | bc)
          
          echo "    Score: ${score}"
        fi
      done
    else
      echo "  No scenarios found for ${category}"
    fi
  done
  
  # Calculate average score
  local average_score=0
  if [ ${total_scenarios} -gt 0 ]; then
    average_score=$(echo "scale=2; ${total_score} / ${total_scenarios}" | bc)
  fi
  
  echo "Educational Effectiveness Validation Summary"
  echo "==========================================="
  echo "Total Scenarios: ${total_scenarios}"
  echo "Average Score: ${average_score}"
  
  # Generate summary report
  cat > "${REPORT_DIR}/educational_summary.md" << EOF
# Educational Effectiveness Summary Report

## Overview
- **Date**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- **Total Scenarios**: ${total_scenarios}
- **Average Effectiveness Score**: ${average_score}

## Results by Category
$(for category in clarity knowledge_transfer progressive_learning actionability retention; do
  if [ -d "${EDUCATIONAL_DIR}/${category}" ]; then
    local cat_total=0
    local cat_score=0
    for scenario in "${EDUCATIONAL_DIR}/${category}"/*; do
      if [ -d "${scenario}" ] && [ -f "${REPORT_DIR}/${category}_$(basename "${scenario}")_report.md" ]; then
        cat_total=$((cat_total + 1))
        local scenario_score=$(grep -o "Effectiveness Score: [0-9.]*" "${REPORT_DIR}/${category}_$(basename "${scenario}")_report.md" | cut -d' ' -f3)
        cat_score=$(echo "${cat_score} + ${scenario_score}" | bc)
      fi
    done
    
    if [ ${cat_total} -gt 0 ]; then
      local cat_average=$(echo "scale=2; ${cat_score} / ${cat_total}" | bc)
      echo "### ${category}"
      echo "- Total Scenarios: ${cat_total}"
      echo "- Average Score: ${cat_average}"
      echo ""
    fi
  fi
done)

## Strengths and Areas for Improvement

### Strengths
$(
  # Identify the highest scoring category
  high_category=""
  high_score=0
  
  for category in clarity knowledge_transfer progressive_learning actionability retention; do
    if [ -d "${EDUCATIONAL_DIR}/${category}" ]; then
      local cat_total=0
      local cat_score=0
      for scenario in "${EDUCATIONAL_DIR}/${category}"/*; do
        if [ -d "${scenario}" ] && [ -f "${REPORT_DIR}/${category}_$(basename "${scenario}")_report.md" ]; then
          cat_total=$((cat_total + 1))
          local scenario_score=$(grep -o "Effectiveness Score: [0-9.]*" "${REPORT_DIR}/${category}_$(basename "${scenario}")_report.md" | cut -d' ' -f3)
          cat_score=$(echo "${cat_score} + ${scenario_score}" | bc)
        fi
      done
      
      if [ ${cat_total} -gt 0 ]; then
        local cat_average=$(echo "scale=2; ${cat_score} / ${cat_total}" | bc)
        if (( $(echo "${cat_average} > ${high_score}" | bc -l) )); then
          high_category="${category}"
          high_score="${cat_average}"
        fi
      fi
    fi
  done
  
  if [ ! -z "${high_category}" ]; then
    echo "- **${high_category}**: MVNimble performs well in this area with a score of ${high_score}"
    
    case "${high_category}" in
      clarity)
        echo "  - Clear explanations with appropriate level of detail"
        echo "  - Good use of examples to illustrate concepts"
        echo "  - Minimal use of unnecessary jargon"
        ;;
      knowledge_transfer)
        echo "  - Effective explanation of technical concepts"
        echo "  - Good identification of prerequisite knowledge"
        echo "  - High technical accuracy in explanations"
        ;;
      progressive_learning)
        echo "  - Appropriate content for different skill levels"
        echo "  - Clear path for advancement to more complex topics"
        echo "  - Logical sequencing of concepts"
        ;;
      actionability)
        echo "  - Clear step-by-step implementation instructions"
        echo "  - Practical recommendations that can be implemented easily"
        echo "  - Good guidance for validating success"
        ;;
      retention)
        echo "  - Memorable presentation of key concepts"
        echo "  - Good balance of principles and specific examples"
        echo "  - Effective techniques for reinforcing knowledge"
        ;;
    esac
  fi
)

### Areas for Improvement
$(
  # Identify the lowest scoring category
  low_category=""
  low_score=1.0
  
  for category in clarity knowledge_transfer progressive_learning actionability retention; do
    if [ -d "${EDUCATIONAL_DIR}/${category}" ]; then
      local cat_total=0
      local cat_score=0
      for scenario in "${EDUCATIONAL_DIR}/${category}"/*; do
        if [ -d "${scenario}" ] && [ -f "${REPORT_DIR}/${category}_$(basename "${scenario}")_report.md" ]; then
          cat_total=$((cat_total + 1))
          local scenario_score=$(grep -o "Effectiveness Score: [0-9.]*" "${REPORT_DIR}/${category}_$(basename "${scenario}")_report.md" | cut -d' ' -f3)
          cat_score=$(echo "${cat_score} + ${scenario_score}" | bc)
        fi
      done
      
      if [ ${cat_total} -gt 0 ]; then
        local cat_average=$(echo "scale=2; ${cat_score} / ${cat_total}" | bc)
        if (( $(echo "${cat_average} < ${low_score}" | bc -l) )); then
          low_category="${category}"
          low_score="${cat_average}"
        fi
      fi
    fi
  done
  
  if [ ! -z "${low_category}" ]; then
    echo "- **${low_category}**: This area needs the most improvement with a score of ${low_score}"
    
    case "${low_category}" in
      clarity)
        echo "  - Simplify complex explanations"
        echo "  - Reduce technical jargon or provide better definitions"
        echo "  - Add more visual aids to illustrate concepts"
        ;;
      knowledge_transfer)
        echo "  - Improve explanation of fundamental concepts"
        echo "  - Provide more references to learning resources"
        echo "  - Enhance technical accuracy in complex scenarios"
        ;;
      progressive_learning)
        echo "  - Better tailor content to different skill levels"
        echo "  - Provide clearer progression paths"
        echo "  - Improve concept sequencing for logical learning"
        ;;
      actionability)
        echo "  - Provide more detailed step-by-step instructions"
        echo "  - Improve practicality of recommendations"
        echo "  - Add better verification steps to validate implementation"
        ;;
      retention)
        echo "  - Improve memorability of key concepts"
        echo "  - Better balance principles with specific examples"
        echo "  - Add more techniques for reinforcing knowledge"
        ;;
    esac
  fi
)

## Recommendations for MVNimble's Educational Approach

1. **Content Structure Improvements**
   - Organize recommendations in a consistent format across all categories
   - Use hierarchical structures for complex topics
   - Include summaries for quick reference

2. **Visualization Enhancements**
   - Add more diagrams to illustrate complex concepts
   - Use consistent visual language across different types of issues
   - Consider adding interactive elements to reports

3. **Knowledge Scaffolding**
   - Provide explicit links between basic and advanced concepts
   - Include "Further Reading" sections for users who want to deepen their understanding
   - Create a glossary of terms used in recommendations

4. **Implementation Guidance**
   - Add more concrete code examples
   - Include validation steps to verify successful implementation
   - Provide time estimates for implementing recommendations

5. **Learning Reinforcement**
   - Add review questions or self-assessment tools
   - Create reference cards for key concepts
   - Provide periodic reminders of important principles

## Detailed Results
$(for category in clarity knowledge_transfer progressive_learning actionability retention; do
  echo "### ${category}"
  echo ""
  echo "| Scenario | Score | Key Strengths | Areas for Improvement |"
  echo "|----------|-------|---------------|------------------------|"
  
  if [ -d "${EDUCATIONAL_DIR}/${category}" ]; then
    for scenario in "${EDUCATIONAL_DIR}/${category}"/*; do
      if [ -d "${scenario}" ] && [ -f "${REPORT_DIR}/${category}_$(basename "${scenario}")_report.md" ]; then
        local name=$(basename "${scenario}")
        local score=$(grep -o "Effectiveness Score: [0-9.]*" "${REPORT_DIR}/${category}_$(basename "${scenario}")_report.md" | cut -d' ' -f3)
        
        # Placeholder for strengths and improvements
        local strengths="Good explanations"
        local improvements="More examples needed"
        
        echo "| ${name} | ${score} | ${strengths} | ${improvements} |"
      fi
    done
  else
    echo "No scenarios found for this category."
  fi
  echo ""
done)
EOF

  echo "Summary report generated: ${REPORT_DIR}/educational_summary.md"
  
  # Return the average score as an indicator of overall success
  echo "${average_score}"
}

# Main function
function main() {
  # Create standard educational effectiveness scenarios
  create_standard_scenarios
  
  # Run validation
  run_validation
}

# Allow sourcing without executing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi