#!/usr/bin/env bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
#
# Gold Standard Validation Suite for MVNimble
#
# This script implements a suite of gold standard test cases with expert-derived
# optimal configurations for various test scenarios. It validates MVNimble's
# recommendations against these known-good configurations and metrics.
#
# The gold standard tests serve as a benchmark to ensure that MVNimble's 
# recommendations meet or exceed the quality of configurations determined by
# testing experts.

# Source common libraries
source "$(dirname "$(dirname "$(dirname "$0")")")/test_helper.bash"
source "$(dirname "$(dirname "$(dirname "$0")")")/fixtures/problem_simulators/diagnostic_patterns.bash"
source "$(dirname "$(dirname "$(dirname "$0")")")/fixtures/problem_simulators/resource_constraints.bash"
source "$(dirname "$(dirname "$(dirname "$0")")")/fixtures/problem_simulators/thread_safety_issues.bash"
source "$(dirname "$(dirname "$(dirname "$0")")")/fixtures/problem_simulators/network_io_bottlenecks.bash"

# Constants
GOLD_STANDARD_DIR="${BATS_TEST_DIRNAME}/scenarios"
VALIDATION_THRESHOLD=0.85 # 85% match required to pass validation
VALIDATION_REPORT_DIR="${BATS_TEST_DIRNAME}/reports"

#######################################
# Creates the necessary directory structure for gold standard tests
# Arguments:
#   None
# Outputs:
#   None
#######################################
function setup_gold_standard_environment() {
  mkdir -p "${GOLD_STANDARD_DIR}"
  mkdir -p "${VALIDATION_REPORT_DIR}"
  
  # Create subdirectories for each gold standard category
  mkdir -p "${GOLD_STANDARD_DIR}/cpu_bound"
  mkdir -p "${GOLD_STANDARD_DIR}/memory_bound"
  mkdir -p "${GOLD_STANDARD_DIR}/io_bound"
  mkdir -p "${GOLD_STANDARD_DIR}/network_bound"
  mkdir -p "${GOLD_STANDARD_DIR}/thread_safety"
  mkdir -p "${GOLD_STANDARD_DIR}/multivariate"
}

#######################################
# Creates a gold standard scenario with expert-defined optimal configuration
# Arguments:
#   $1 - Scenario name
#   $2 - Category (cpu_bound, memory_bound, io_bound, network_bound, thread_safety, multivariate)
#   $3 - Constraint level (low, medium, high)
#   $4 - Expert recommendations in JSON format
# Outputs:
#   None
#######################################
function create_gold_standard_scenario() {
  local scenario_name="$1"
  local category="$2"
  local constraint_level="$3"
  local expert_recommendations="$4"
  
  local scenario_dir="${GOLD_STANDARD_DIR}/${category}/${scenario_name}"
  mkdir -p "${scenario_dir}"
  
  # Create Maven project template for this scenario
  create_test_project "${scenario_dir}/project"
  
  # Apply appropriate constraints based on category and level
  case "${category}" in
    cpu_bound)
      apply_cpu_constraints "${scenario_dir}/project" "${constraint_level}"
      ;;
    memory_bound)
      apply_memory_constraints "${scenario_dir}/project" "${constraint_level}"
      ;;
    io_bound)
      apply_io_constraints "${scenario_dir}/project" "${constraint_level}"
      ;;
    network_bound)
      apply_network_constraints "${scenario_dir}/project" "${constraint_level}"
      ;;
    thread_safety)
      apply_thread_safety_issues "${scenario_dir}/project" "${constraint_level}"
      ;;
    multivariate)
      # Apply multiple constraints for multivariate scenarios
      apply_multivariate_constraints "${scenario_dir}/project" "${constraint_level}"
      ;;
    *)
      echo "Unknown category: ${category}"
      return 1
      ;;
  esac
  
  # Store expert recommendations in a JSON file
  echo "${expert_recommendations}" > "${scenario_dir}/expert_recommendations.json"
  
  # Create a metadata file for the scenario
  cat > "${scenario_dir}/metadata.json" << EOF
{
  "name": "${scenario_name}",
  "category": "${category}",
  "constraint_level": "${constraint_level}",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "description": "Gold standard test case for ${category} constraints (${constraint_level} level)"
}
EOF
}

#######################################
# Creates a Maven test project for gold standard validation
# Arguments:
#   $1 - Project directory path
# Outputs:
#   None
#######################################
function create_test_project() {
  local project_dir="$1"
  mkdir -p "${project_dir}"
  
  # Create a minimal Maven project structure
  mkdir -p "${project_dir}/src/main/java/com/example"
  mkdir -p "${project_dir}/src/test/java/com/example"
  
  # Create a basic pom.xml file
  cat > "${project_dir}/pom.xml" << EOF
<project xmlns="http://maven.apache.org/POM/4.0.0" 
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  
  <groupId>com.example</groupId>
  <artifactId>gold-standard-test</artifactId>
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

  # Create Java source files
  cat > "${project_dir}/src/main/java/com/example/Calculator.java" << EOF
package com.example;

public class Calculator {
    public int add(int a, int b) {
        return a + b;
    }
    
    public int subtract(int a, int b) {
        return a - b;
    }
    
    public int multiply(int a, int b) {
        return a * b;
    }
    
    public int divide(int a, int b) {
        if (b == 0) {
            throw new ArithmeticException("Division by zero");
        }
        return a / b;
    }
}
EOF

  # Create Java test files with configurable characteristics
  cat > "${project_dir}/src/test/java/com/example/CalculatorTest.java" << EOF
package com.example;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

public class CalculatorTest {
    
    private final Calculator calculator = new Calculator();
    
    @Test
    public void testAdd() {
        assertEquals(2, calculator.add(1, 1));
    }
    
    @Test
    public void testSubtract() {
        assertEquals(0, calculator.subtract(1, 1));
    }
    
    @Test
    public void testMultiply() {
        assertEquals(1, calculator.multiply(1, 1));
    }
    
    @Test
    public void testDivide() {
        assertEquals(1, calculator.divide(1, 1));
    }
    
    @Test
    public void testDivideByZero() {
        assertThrows(ArithmeticException.class, () -> calculator.divide(1, 0));
    }
}
EOF
}

#######################################
# Apply CPU constraints to a test project
# Arguments:
#   $1 - Project directory path
#   $2 - Constraint level (low, medium, high)
# Outputs:
#   None
#######################################
function apply_cpu_constraints() {
  local project_dir="$1"
  local constraint_level="$2"
  
  # Create a CPU-intensive test
  cat > "${project_dir}/src/test/java/com/example/CpuIntensiveTest.java" << EOF
package com.example;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import java.util.concurrent.TimeUnit;

public class CpuIntensiveTest {
    
    @Test
    public void testCpuIntensiveOperation() {
        int complexity = 0;
        
        // Set complexity based on constraint level
        switch ("${constraint_level}") {
            case "low":
                complexity = 1000;
                break;
            case "medium":
                complexity = 10000;
                break;
            case "high":
                complexity = 30000;
                break;
            default:
                complexity = 5000;
        }
        
        // Perform CPU-intensive computation
        long result = 0;
        for (int i = 0; i < complexity; i++) {
            for (int j = 0; j < complexity; j++) {
                result += (i * j) % 17;
            }
        }
        
        assertTrue(result >= 0);
    }
    
    @Test
    public void testParallelComputation() {
        // Another CPU-intensive test with parallel execution
        int[] results = new int[10];
        
        // Parallel streams can consume multiple CPU cores
        java.util.Arrays.parallelSetAll(results, i -> {
            int sum = 0;
            for (int j = 0; j < 5000; j++) {
                sum += (i * j) % 11;
            }
            return sum;
        });
        
        for (int result : results) {
            assertTrue(result >= 0);
        }
    }
}
EOF

  # Modify pom.xml to add forkCount setting for Surefire based on expert recommendations
  case "${constraint_level}" in
    low)
      # For low CPU constraints, expert recommends forkCount=1
      sed -i.bak '/<artifactId>maven-surefire-plugin<\/artifactId>/,/<\/plugin>/ s|<version>.*</version>|<version>2.22.2</version>\n        <configuration>\n          <forkCount>1</forkCount>\n          <reuseForks>true</reuseForks>\n        </configuration>|' "${project_dir}/pom.xml"
      ;;
    medium)
      # For medium CPU constraints, expert recommends forkCount=0.5C
      sed -i.bak '/<artifactId>maven-surefire-plugin<\/artifactId>/,/<\/plugin>/ s|<version>.*</version>|<version>2.22.2</version>\n        <configuration>\n          <forkCount>0.5C</forkCount>\n          <reuseForks>true</reuseForks>\n        </configuration>|' "${project_dir}/pom.xml"
      ;;
    high)
      # For high CPU constraints, expert recommends forkCount=1C
      sed -i.bak '/<artifactId>maven-surefire-plugin<\/artifactId>/,/<\/plugin>/ s|<version>.*</version>|<version>2.22.2</version>\n        <configuration>\n          <forkCount>1C</forkCount>\n          <reuseForks>false</reuseForks>\n        </configuration>|' "${project_dir}/pom.xml"
      ;;
  esac
  
  # Remove backup file
  rm "${project_dir}/pom.xml.bak"
}

#######################################
# Apply memory constraints to a test project
# Arguments:
#   $1 - Project directory path
#   $2 - Constraint level (low, medium, high)
# Outputs:
#   None
#######################################
function apply_memory_constraints() {
  local project_dir="$1"
  local constraint_level="$2"
  
  # Create a memory-intensive test
  cat > "${project_dir}/src/test/java/com/example/MemoryIntensiveTest.java" << EOF
package com.example;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import java.util.ArrayList;
import java.util.List;

public class MemoryIntensiveTest {
    
    @Test
    public void testMemoryIntensiveOperation() {
        int size = 0;
        
        // Set size based on constraint level
        switch ("${constraint_level}") {
            case "low":
                size = 100_000;
                break;
            case "medium":
                size = 1_000_000;
                break;
            case "high":
                size = 5_000_000;
                break;
            default:
                size = 500_000;
        }
        
        // Allocate memory
        List<byte[]> memoryConsumers = new ArrayList<>();
        for (int i = 0; i < 10; i++) {
            memoryConsumers.add(new byte[size]);
        }
        
        assertEquals(10, memoryConsumers.size());
    }
}
EOF

  # Modify pom.xml to add memory settings for Surefire based on expert recommendations
  case "${constraint_level}" in
    low)
      # For low memory constraints, expert recommends minimal JVM args
      sed -i.bak '/<artifactId>maven-surefire-plugin<\/artifactId>/,/<\/plugin>/ s|<version>.*</version>|<version>2.22.2</version>\n        <configuration>\n          <argLine>-Xmx512m</argLine>\n        </configuration>|' "${project_dir}/pom.xml"
      ;;
    medium)
      # For medium memory constraints, expert recommends moderate JVM args
      sed -i.bak '/<artifactId>maven-surefire-plugin<\/artifactId>/,/<\/plugin>/ s|<version>.*</version>|<version>2.22.2</version>\n        <configuration>\n          <argLine>-Xmx1024m -XX:+UseG1GC</argLine>\n        </configuration>|' "${project_dir}/pom.xml"
      ;;
    high)
      # For high memory constraints, expert recommends aggressive JVM args
      sed -i.bak '/<artifactId>maven-surefire-plugin<\/artifactId>/,/<\/plugin>/ s|<version>.*</version>|<version>2.22.2</version>\n        <configuration>\n          <argLine>-Xmx2048m -XX:+UseG1GC -XX:MaxGCPauseMillis=100</argLine>\n          <forkCount>1</forkCount>\n          <reuseForks>false</reuseForks>\n        </configuration>|' "${project_dir}/pom.xml"
      ;;
  esac
  
  # Remove backup file
  rm "${project_dir}/pom.xml.bak"
}

#######################################
# Apply IO constraints to a test project
# Arguments:
#   $1 - Project directory path
#   $2 - Constraint level (low, medium, high)
# Outputs:
#   None
#######################################
function apply_io_constraints() {
  local project_dir="$1"
  local constraint_level="$2"
  
  # Create an IO-intensive test
  cat > "${project_dir}/src/test/java/com/example/IoIntensiveTest.java" << EOF
package com.example;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import static org.junit.jupiter.api.Assertions.*;
import java.io.*;
import java.nio.file.Path;
import java.util.Random;

public class IoIntensiveTest {
    
    @Test
    public void testFileOperations(@TempDir Path tempDir) throws IOException {
        int fileCount = 0;
        int fileSize = 0;
        
        // Set parameters based on constraint level
        switch ("${constraint_level}") {
            case "low":
                fileCount = 5;
                fileSize = 10_000;
                break;
            case "medium":
                fileCount = 20;
                fileSize = 100_000;
                break;
            case "high":
                fileCount = 50;
                fileSize = 500_000;
                break;
            default:
                fileCount = 10;
                fileSize = 50_000;
        }
        
        // Create and write to multiple files
        Random random = new Random();
        for (int i = 0; i < fileCount; i++) {
            File file = tempDir.resolve("test-file-" + i + ".dat").toFile();
            try (BufferedOutputStream out = new BufferedOutputStream(new FileOutputStream(file))) {
                byte[] data = new byte[fileSize];
                random.nextBytes(data);
                out.write(data);
            }
            
            // Read the file back
            try (BufferedInputStream in = new BufferedInputStream(new FileInputStream(file))) {
                byte[] data = new byte[fileSize];
                int bytesRead = in.read(data);
                assertEquals(fileSize, bytesRead);
            }
        }
    }
}
EOF

  # Modify pom.xml to add IO-friendly settings based on expert recommendations
  case "${constraint_level}" in
    low)
      # For low IO constraints, basic settings
      ;;
    medium)
      # For medium IO constraints, set parallel=classes
      sed -i.bak '/<artifactId>maven-surefire-plugin<\/artifactId>/,/<\/plugin>/ s|<version>.*</version>|<version>2.22.2</version>\n        <configuration>\n          <parallel>classes</parallel>\n          <threadCount>2</threadCount>\n        </configuration>|' "${project_dir}/pom.xml"
      ;;
    high)
      # For high IO constraints, more sophisticated approach
      sed -i.bak '/<artifactId>maven-surefire-plugin<\/artifactId>/,/<\/plugin>/ s|<version>.*</version>|<version>2.22.2</version>\n        <configuration>\n          <parallel>classes</parallel>\n          <threadCount>3</threadCount>\n          <forkCount>1</forkCount>\n          <reuseForks>false</reuseForks>\n        </configuration>|' "${project_dir}/pom.xml"
      ;;
  esac
  
  # Remove backup file if it exists
  if [ -f "${project_dir}/pom.xml.bak" ]; then
    rm "${project_dir}/pom.xml.bak"
  fi
}

#######################################
# Apply network constraints to a test project
# Arguments:
#   $1 - Project directory path
#   $2 - Constraint level (low, medium, high)
# Outputs:
#   None
#######################################
function apply_network_constraints() {
  local project_dir="$1"
  local constraint_level="$2"
  
  # Create a network-intensive test (simulated)
  cat > "${project_dir}/src/test/java/com/example/NetworkTest.java" << EOF
package com.example;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import java.net.HttpURLConnection;
import java.net.URL;
import java.io.IOException;

public class NetworkTest {
    
    // This test simulates network operations without actually making external calls
    @Test
    public void testNetworkOperations() throws Exception {
        int operations = 0;
        int delay = 0;
        
        // Set parameters based on constraint level
        switch ("${constraint_level}") {
            case "low":
                operations = 5;
                delay = 100;
                break;
            case "medium":
                operations = 20;
                delay = 250;
                break;
            case "high":
                operations = 50;
                delay = 500;
                break;
            default:
                operations = 10;
                delay = 200;
        }
        
        // Simulate network operations with delays
        for (int i = 0; i < operations; i++) {
            simulateNetworkCall(delay);
        }
        
        assertTrue(true); // Always succeeds if we reach here
    }
    
    private void simulateNetworkCall(int delayMs) throws InterruptedException {
        // Simulate network latency
        Thread.sleep(delayMs);
    }
}
EOF

  # Modify pom.xml to add recommended settings
  case "${constraint_level}" in
    low)
      # For low network constraints, no specific optimization needed
      ;;
    medium)
      # For medium network constraints, improve parallelism
      sed -i.bak '/<artifactId>maven-surefire-plugin<\/artifactId>/,/<\/plugin>/ s|<version>.*</version>|<version>2.22.2</version>\n        <configuration>\n          <parallel>methods</parallel>\n          <threadCount>4</threadCount>\n        </configuration>|' "${project_dir}/pom.xml"
      ;;
    high)
      # For high network constraints, advanced settings
      sed -i.bak '/<artifactId>maven-surefire-plugin<\/artifactId>/,/<\/plugin>/ s|<version>.*</version>|<version>2.22.2</version>\n        <configuration>\n          <parallel>all</parallel>\n          <threadCount>8</threadCount>\n          <perCoreThreadCount>true</perCoreThreadCount>\n        </configuration>|' "${project_dir}/pom.xml"
      ;;
  esac
  
  # Remove backup file if it exists
  if [ -f "${project_dir}/pom.xml.bak" ]; then
    rm "${project_dir}/pom.xml.bak"
  fi
}

#######################################
# Apply thread safety issues to a test project
# Arguments:
#   $1 - Project directory path
#   $2 - Constraint level (low, medium, high)
# Outputs:
#   None
#######################################
function apply_thread_safety_issues() {
  local project_dir="$1"
  local constraint_level="$2"
  
  # Create a class with thread safety issues
  cat > "${project_dir}/src/main/java/com/example/Counter.java" << EOF
package com.example;

public class Counter {
    private int count = 0;
    
    // Non-thread-safe increment
    public void increment() {
        count++;
    }
    
    // Thread-safe increment
    public synchronized void incrementSafe() {
        count++;
    }
    
    public int getCount() {
        return count;
    }
}
EOF

  # Create tests demonstrating thread safety issues
  cat > "${project_dir}/src/test/java/com/example/ThreadSafetyTest.java" << EOF
package com.example;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

public class ThreadSafetyTest {
    
    @Test
    public void testThreadSafety() throws Exception {
        int threadCount = 0;
        int incrementsPerThread = 0;
        
        // Set parameters based on constraint level
        switch ("${constraint_level}") {
            case "low":
                threadCount = 5;
                incrementsPerThread = 1000;
                break;
            case "medium":
                threadCount = 10;
                incrementsPerThread = 10000;
                break;
            case "high":
                threadCount = 20;
                incrementsPerThread = 50000;
                break;
            default:
                threadCount = 8;
                incrementsPerThread = 5000;
        }
        
        Counter counter = new Counter();
        CountDownLatch latch = new CountDownLatch(1);
        ExecutorService executor = Executors.newFixedThreadPool(threadCount);
        
        // Launch multiple threads to increment the counter
        for (int i = 0; i < threadCount; i++) {
            executor.submit(() -> {
                try {
                    latch.await(); // Wait for all threads to be ready
                    for (int j = 0; j < incrementsPerThread; j++) {
                        counter.increment(); // Non-thread-safe increment
                    }
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            });
        }
        
        latch.countDown(); // Start all threads
        executor.shutdown();
        executor.awaitTermination(30, TimeUnit.SECONDS);
        
        // Due to race conditions, the actual count will likely be less than expected
        int expectedCount = threadCount * incrementsPerThread;
        // For test purposes, we're asserting the race condition will occur
        // This test is "successful" when it fails due to thread safety issues
        assertTrue(counter.getCount() <= expectedCount);
    }
    
    @Test
    public void testThreadSafeSolution() throws Exception {
        int threadCount = 10;
        int incrementsPerThread = 1000;
        
        Counter counter = new Counter();
        CountDownLatch latch = new CountDownLatch(1);
        ExecutorService executor = Executors.newFixedThreadPool(threadCount);
        
        // Launch multiple threads to increment the counter
        for (int i = 0; i < threadCount; i++) {
            executor.submit(() -> {
                try {
                    latch.await(); // Wait for all threads to be ready
                    for (int j = 0; j < incrementsPerThread; j++) {
                        counter.incrementSafe(); // Thread-safe increment
                    }
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            });
        }
        
        latch.countDown(); // Start all threads
        executor.shutdown();
        executor.awaitTermination(30, TimeUnit.SECONDS);
        
        // With thread-safe increment, the count should be exactly as expected
        int expectedCount = threadCount * incrementsPerThread;
        assertEquals(expectedCount, counter.getCount());
    }
}
EOF

  # Modify pom.xml to add thread-safety settings based on expert recommendations
  case "${constraint_level}" in
    low)
      # For low thread safety issues, basic tests are enough
      ;;
    medium)
      # For medium thread safety issues, use moderate parallelism
      sed -i.bak '/<artifactId>maven-surefire-plugin<\/artifactId>/,/<\/plugin>/ s|<version>.*</version>|<version>2.22.2</version>\n        <configuration>\n          <parallel>classes</parallel>\n          <threadCount>2</threadCount>\n        </configuration>|' "${project_dir}/pom.xml"
      ;;
    high)
      # For high thread safety issues, use extensive parallelism
      sed -i.bak '/<artifactId>maven-surefire-plugin<\/artifactId>/,/<\/plugin>/ s|<version>.*</version>|<version>2.22.2</version>\n        <configuration>\n          <parallel>classesAndMethods</parallel>\n          <threadCount>8</threadCount>\n          <useUnlimitedThreads>true</useUnlimitedThreads>\n        </configuration>|' "${project_dir}/pom.xml"
      ;;
  esac
  
  # Remove backup file if it exists
  if [ -f "${project_dir}/pom.xml.bak" ]; then
    rm "${project_dir}/pom.xml.bak"
  fi
}

#######################################
# Apply multiple constraints for multivariate scenarios
# Arguments:
#   $1 - Project directory path
#   $2 - Constraint level (low, medium, high)
# Outputs:
#   None
#######################################
function apply_multivariate_constraints() {
  local project_dir="$1"
  local constraint_level="$2"
  
  # Apply multiple constraints based on level
  case "${constraint_level}" in
    low)
      # For low level, apply minimal constraints
      apply_cpu_constraints "${project_dir}" "low"
      apply_memory_constraints "${project_dir}" "low"
      ;;
    medium)
      # For medium level, apply moderate constraints
      apply_cpu_constraints "${project_dir}" "medium"
      apply_memory_constraints "${project_dir}" "medium"
      apply_io_constraints "${project_dir}" "low"
      ;;
    high)
      # For high level, apply significant constraints
      apply_cpu_constraints "${project_dir}" "high"
      apply_memory_constraints "${project_dir}" "high"
      apply_io_constraints "${project_dir}" "medium"
      apply_thread_safety_issues "${project_dir}" "medium"
      ;;
  esac
}

#######################################
# Run MVNimble against a gold standard scenario and compare recommendations
# Arguments:
#   $1 - Scenario directory path
# Outputs:
#   Comparison score (0.0-1.0) indicating match between MVNimble and expert recommendations
#######################################
function validate_recommendations() {
  local scenario_dir="$1"
  local project_dir="${scenario_dir}/project"
  local results_dir="${scenario_dir}/results"
  
  mkdir -p "${results_dir}"
  
  # Run MVNimble against the test project
  (cd "${project_dir}" && mvnimble analyze > "${results_dir}/mvnimble_output.log")
  
  # Extract MVNimble recommendations
  local mvnimble_recommendations=$(grep -A 50 "RECOMMENDATIONS:" "${results_dir}/mvnimble_output.log" | grep -v "RECOMMENDATIONS:")
  echo "${mvnimble_recommendations}" > "${results_dir}/mvnimble_recommendations.txt"
  
  # Compare with expert recommendations
  local expert_recommendations=$(cat "${scenario_dir}/expert_recommendations.json")
  local comparison_score=$(compare_recommendations "${expert_recommendations}" "${mvnimble_recommendations}")
  
  echo "${comparison_score}" > "${results_dir}/comparison_score.txt"
  
  # Generate validation report
  generate_validation_report "${scenario_dir}" "${comparison_score}"
  
  echo "${comparison_score}"
}

#######################################
# Compare MVNimble recommendations against expert recommendations
# Arguments:
#   $1 - Expert recommendations (JSON)
#   $2 - MVNimble recommendations (text)
# Outputs:
#   Similarity score (0.0-1.0)
#######################################
function compare_recommendations() {
  local expert_json="$1"
  local mvnimble_text="$2"
  local score=0.0
  
  # Extract key recommendations from expert JSON
  # This is a simplified comparison for demonstration purposes
  # In a real implementation, this would use proper JSON parsing and semantic comparison
  
  # Check for presence of key recommendations in MVNimble output
  # For each key recommendation found, increase the score
  
  # Example scoring algorithm:
  # 1. Parse JSON to get key recommendations
  # 2. For each recommendation, check if it appears in MVNimble text
  # 3. Calculate percentage of matches
  
  # Simplified scoring for demonstration:
  # CPU recommendations
  if echo "${expert_json}" | grep -q "forkCount" && echo "${mvnimble_text}" | grep -q "forkCount"; then
    score=$(echo "${score} + 0.2" | bc)
  fi
  
  # Memory recommendations
  if echo "${expert_json}" | grep -q "Xmx" && echo "${mvnimble_text}" | grep -q "Xmx"; then
    score=$(echo "${score} + 0.2" | bc)
  fi
  
  # Thread recommendations
  if echo "${expert_json}" | grep -q "threadCount" && echo "${mvnimble_text}" | grep -q "threadCount"; then
    score=$(echo "${score} + 0.2" | bc)
  fi
  
  # Parallelism recommendations
  if echo "${expert_json}" | grep -q "parallel" && echo "${mvnimble_text}" | grep -q "parallel"; then
    score=$(echo "${score} + 0.2" | bc)
  fi
  
  # General quality of recommendations
  if echo "${mvnimble_text}" | grep -q "recommend"; then
    score=$(echo "${score} + 0.2" | bc)
  fi
  
  # Ensure score doesn't exceed 1.0
  if (( $(echo "${score} > 1.0" | bc -l) )); then
    score=1.0
  fi
  
  echo "${score}"
}

#######################################
# Generate a validation report for a gold standard scenario
# Arguments:
#   $1 - Scenario directory path
#   $2 - Comparison score
# Outputs:
#   None
#######################################
function generate_validation_report() {
  local scenario_dir="$1"
  local score="$2"
  local metadata=$(cat "${scenario_dir}/metadata.json")
  local name=$(echo "${metadata}" | grep -o '"name": "[^"]*"' | cut -d'"' -f4)
  local category=$(echo "${metadata}" | grep -o '"category": "[^"]*"' | cut -d'"' -f4)
  local constraint_level=$(echo "${metadata}" | grep -o '"constraint_level": "[^"]*"' | cut -d'"' -f4)
  
  # Determine pass/fail status
  local status="FAIL"
  if (( $(echo "${score} >= ${VALIDATION_THRESHOLD}" | bc -l) )); then
    status="PASS"
  fi
  
  # Generate report
  local report_file="${VALIDATION_REPORT_DIR}/${name}_${category}_${constraint_level}.md"
  
  cat > "${report_file}" << EOF
# Gold Standard Validation Report

## Scenario Information
- **Name**: ${name}
- **Category**: ${category}
- **Constraint Level**: ${constraint_level}
- **Validation Date**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

## Validation Results
- **Comparison Score**: ${score}
- **Validation Threshold**: ${VALIDATION_THRESHOLD}
- **Status**: ${status}

## Analysis
The MVNimble recommendations for this scenario were compared against expert-derived optimal configurations.
${status} - MVNimble's recommendations $(if [ "${status}" = "PASS" ]; then echo "match"; else echo "do not match"; fi) the expert recommendations with sufficient accuracy.

## Recommendations
$(if [ "${status}" = "PASS" ]; then
  echo "MVNimble's recommendations are validated for this scenario."
else
  echo "MVNimble's recommendations need improvement for this scenario. Areas to focus on:"
  echo "- Review ${category} diagnostic patterns"
  echo "- Enhance recommendation generation for ${constraint_level} ${category} constraints"
  echo "- Consider adding more specific guidance for this type of scenario"
fi)

EOF
}

#######################################
# Create a set of standard gold standard scenarios
# Arguments:
#   None
# Outputs:
#   None
#######################################
function create_standard_gold_scenarios() {
  # Set up environment
  setup_gold_standard_environment
  
  # CPU-bound scenarios
  create_gold_standard_scenario "cpu_light" "cpu_bound" "low" '{
    "recommendations": {
      "forkCount": "1",
      "reuseForks": "true",
      "threadCount": "1"
    },
    "reasoning": "Low CPU constraint requires minimal forking to avoid overhead"
  }'
  
  create_gold_standard_scenario "cpu_moderate" "cpu_bound" "medium" '{
    "recommendations": {
      "forkCount": "0.5C",
      "reuseForks": "true",
      "threadCount": "2"
    },
    "reasoning": "Medium CPU constraint benefits from moderate parallelism with fork reuse"
  }'
  
  create_gold_standard_scenario "cpu_heavy" "cpu_bound" "high" '{
    "recommendations": {
      "forkCount": "1C",
      "reuseForks": "false",
      "threadCount": "1C"
    },
    "reasoning": "High CPU constraint requires maximizing available cores while minimizing overhead"
  }'
  
  # Memory-bound scenarios
  create_gold_standard_scenario "memory_light" "memory_bound" "low" '{
    "recommendations": {
      "argLine": "-Xmx512m",
      "forkCount": "1",
      "reuseForks": "true"
    },
    "reasoning": "Low memory constraints require minimal heap space allocation"
  }'
  
  create_gold_standard_scenario "memory_moderate" "memory_bound" "medium" '{
    "recommendations": {
      "argLine": "-Xmx1024m -XX:+UseG1GC",
      "forkCount": "2",
      "reuseForks": "true"
    },
    "reasoning": "Medium memory constraints benefit from G1GC and moderate heap space"
  }'
  
  create_gold_standard_scenario "memory_heavy" "memory_bound" "high" '{
    "recommendations": {
      "argLine": "-Xmx2048m -XX:+UseG1GC -XX:MaxGCPauseMillis=100",
      "forkCount": "1",
      "reuseForks": "false"
    },
    "reasoning": "High memory constraints require careful GC tuning and larger heap space"
  }'
  
  # I/O-bound scenarios
  create_gold_standard_scenario "io_light" "io_bound" "low" '{
    "recommendations": {
      "parallel": "none",
      "threadCount": "1"
    },
    "reasoning": "Low I/O constraints do not require specific I/O optimizations"
  }'
  
  create_gold_standard_scenario "io_moderate" "io_bound" "medium" '{
    "recommendations": {
      "parallel": "classes",
      "threadCount": "2",
      "forkCount": "1"
    },
    "reasoning": "Medium I/O constraints benefit from moderate parallelism at class level"
  }'
  
  create_gold_standard_scenario "io_heavy" "io_bound" "high" '{
    "recommendations": {
      "parallel": "classes",
      "threadCount": "3",
      "forkCount": "1",
      "reuseForks": "false"
    },
    "reasoning": "High I/O constraints require class-level parallelism with multiple threads"
  }'
  
  # Thread safety scenarios
  create_gold_standard_scenario "thread_safety_light" "thread_safety" "low" '{
    "recommendations": {
      "parallel": "none",
      "threadCount": "1"
    },
    "reasoning": "For code with minor thread safety concerns, sequential execution is safest"
  }'
  
  create_gold_standard_scenario "thread_safety_moderate" "thread_safety" "medium" '{
    "recommendations": {
      "parallel": "classes",
      "threadCount": "2"
    },
    "reasoning": "For code with moderate thread safety concerns, class-level parallelism is appropriate"
  }'
  
  create_gold_standard_scenario "thread_safety_severe" "thread_safety" "high" '{
    "recommendations": {
      "parallel": "classesAndMethods",
      "threadCount": "8",
      "useUnlimitedThreads": "true"
    },
    "reasoning": "For code with severe thread safety concerns, extensive parallelism helps expose issues"
  }'
  
  # Multivariate scenarios
  create_gold_standard_scenario "multivariate_light" "multivariate" "low" '{
    "recommendations": {
      "forkCount": "1",
      "reuseForks": "true",
      "argLine": "-Xmx512m"
    },
    "reasoning": "For simple multivariate constraints, minimal optimizations are sufficient"
  }'
  
  create_gold_standard_scenario "multivariate_moderate" "multivariate" "medium" '{
    "recommendations": {
      "forkCount": "0.5C",
      "reuseForks": "true",
      "argLine": "-Xmx1024m -XX:+UseG1GC",
      "parallel": "classes",
      "threadCount": "2"
    },
    "reasoning": "For moderate multivariate constraints, balanced optimizations across dimensions"
  }'
  
  create_gold_standard_scenario "multivariate_complex" "multivariate" "high" '{
    "recommendations": {
      "forkCount": "1C",
      "reuseForks": "false",
      "argLine": "-Xmx2048m -XX:+UseG1GC -XX:MaxGCPauseMillis=100",
      "parallel": "classesAndMethods",
      "threadCount": "4",
      "redirectTestOutputToFile": "true"
    },
    "reasoning": "For complex multivariate constraints, comprehensive optimizations required"
  }'
}

#######################################
# Run validation on all gold standard scenarios
# Arguments:
#   None
# Outputs:
#   Summary of validation results
#######################################
function run_validation() {
  local total_scenarios=0
  local passed_scenarios=0
  
  echo "Running Gold Standard Validation..."
  
  # Track start time
  local start_time=$(date +%s)
  
  # Process each category of scenarios
  for category in cpu_bound memory_bound io_bound network_bound thread_safety multivariate; do
    echo "Processing ${category} scenarios..."
    
    if [ -d "${GOLD_STANDARD_DIR}/${category}" ]; then
      for scenario in "${GOLD_STANDARD_DIR}/${category}"/*; do
        if [ -d "${scenario}" ]; then
          echo "  Validating scenario: $(basename "${scenario}")..."
          local score=$(validate_recommendations "${scenario}")
          total_scenarios=$((total_scenarios + 1))
          
          if (( $(echo "${score} >= ${VALIDATION_THRESHOLD}" | bc -l) )); then
            passed_scenarios=$((passed_scenarios + 1))
            echo "    PASS - Score: ${score}"
          else
            echo "    FAIL - Score: ${score}"
          fi
        fi
      done
    else
      echo "  No scenarios found for ${category}"
    fi
  done
  
  # Track end time and calculate duration
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))
  
  # Generate summary report
  local passing_percentage=$(echo "scale=2; (${passed_scenarios} / ${total_scenarios}) * 100" | bc)
  
  echo "Gold Standard Validation Summary"
  echo "================================"
  echo "Total Scenarios: ${total_scenarios}"
  echo "Passing Scenarios: ${passed_scenarios}"
  echo "Passing Percentage: ${passing_percentage}%"
  echo "Validation Duration: ${duration} seconds"
  
  # Generate detailed summary report file
  cat > "${VALIDATION_REPORT_DIR}/summary_report.md" << EOF
# Gold Standard Validation Summary Report

## Overview
- **Date**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
- **Total Scenarios**: ${total_scenarios}
- **Passing Scenarios**: ${passed_scenarios}
- **Passing Percentage**: ${passing_percentage}%
- **Validation Duration**: ${duration} seconds
- **Validation Threshold**: ${VALIDATION_THRESHOLD}

## Results by Category
$(for category in cpu_bound memory_bound io_bound network_bound thread_safety multivariate; do
  if [ -d "${GOLD_STANDARD_DIR}/${category}" ]; then
    local cat_total=0
    local cat_passed=0
    for scenario in "${GOLD_STANDARD_DIR}/${category}"/*; do
      if [ -d "${scenario}" ] && [ -f "${scenario}/results/comparison_score.txt" ]; then
        cat_total=$((cat_total + 1))
        local scenario_score=$(cat "${scenario}/results/comparison_score.txt")
        if (( $(echo "${scenario_score} >= ${VALIDATION_THRESHOLD}" | bc -l) )); then
          cat_passed=$((cat_passed + 1))
        fi
      fi
    done
    
    if [ ${cat_total} -gt 0 ]; then
      local cat_percentage=$(echo "scale=2; (${cat_passed} / ${cat_total}) * 100" | bc)
      echo "### ${category}"
      echo "- Total: ${cat_total}"
      echo "- Passing: ${cat_passed}"
      echo "- Percentage: ${cat_percentage}%"
      echo ""
    fi
  fi
done)

## Recommendations
$(if (( $(echo "${passing_percentage} >= 90" | bc -l) )); then
  echo "MVNimble's recommendations are generally excellent, with over 90% matching expert recommendations."
elif (( $(echo "${passing_percentage} >= 75" | bc -l) )); then
  echo "MVNimble's recommendations are good but could use improvement in some areas."
else
  echo "MVNimble's recommendations need significant improvement to match expert recommendations."
  echo ""
  echo "Areas for improvement:"
  # List categories with below-average performance
  for category in cpu_bound memory_bound io_bound network_bound thread_safety multivariate; do
    if [ -d "${GOLD_STANDARD_DIR}/${category}" ]; then
      local cat_total=0
      local cat_passed=0
      for scenario in "${GOLD_STANDARD_DIR}/${category}"/*; do
        if [ -d "${scenario}" ] && [ -f "${scenario}/results/comparison_score.txt" ]; then
          cat_total=$((cat_total + 1))
          local scenario_score=$(cat "${scenario}/results/comparison_score.txt")
          if (( $(echo "${scenario_score} >= ${VALIDATION_THRESHOLD}" | bc -l) )); then
            cat_passed=$((cat_passed + 1))
          fi
        fi
      done
      
      if [ ${cat_total} -gt 0 ]; then
        local cat_percentage=$(echo "scale=2; (${cat_passed} / ${cat_total}) * 100" | bc)
        if (( $(echo "${cat_percentage} < ${passing_percentage}" | bc -l) )); then
          echo "- ${category}: ${cat_percentage}% (below average)"
        fi
      fi
    fi
  done
fi)

## Detailed Results
$(for category in cpu_bound memory_bound io_bound network_bound thread_safety multivariate; do
  echo "### ${category}"
  echo ""
  echo "| Scenario | Constraint Level | Score | Status |"
  echo "|----------|------------------|-------|--------|"
  
  if [ -d "${GOLD_STANDARD_DIR}/${category}" ]; then
    for scenario in "${GOLD_STANDARD_DIR}/${category}"/*; do
      if [ -d "${scenario}" ] && [ -f "${scenario}/results/comparison_score.txt" ]; then
        local name=$(basename "${scenario}")
        local metadata_file="${scenario}/metadata.json"
        local level="unknown"
        if [ -f "${metadata_file}" ]; then
          level=$(grep -o '"constraint_level": "[^"]*"' "${metadata_file}" | cut -d'"' -f4)
        fi
        
        local score=$(cat "${scenario}/results/comparison_score.txt")
        local status="FAIL"
        if (( $(echo "${score} >= ${VALIDATION_THRESHOLD}" | bc -l) )); then
          status="PASS"
        fi
        
        echo "| ${name} | ${level} | ${score} | ${status} |"
      fi
    done
  else
    echo "No scenarios found for this category."
  fi
  echo ""
done)
EOF

  echo "Summary report generated: ${VALIDATION_REPORT_DIR}/summary_report.md"
  
  # Return the passing percentage as an indicator of overall success
  echo "${passing_percentage}"
}

# Main function
function main() {
  # Create gold standard scenarios
  create_standard_gold_scenarios
  
  # Run validation
  run_validation
}

# Allow sourcing without executing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi