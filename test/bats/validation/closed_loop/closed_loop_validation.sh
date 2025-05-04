#!/usr/bin/env bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# closed_loop_validation.sh
# MVNimble - Closed Loop Validation Module
#
# This module provides functions for validating MVNimble's recommendations
# by applying them and measuring actual performance improvements.
#
# Author: MVNimble Team
# Version: 1.0.0

# Load the necessary modules
if [[ -z "${SCRIPT_DIR}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Import problem simulators
source "${SCRIPT_DIR}/../../fixtures/problem_simulators/resource_constraints.bash" 2>/dev/null || \
  source "${SCRIPT_DIR}/../../../fixtures/problem_simulators/resource_constraints.bash"
source "${SCRIPT_DIR}/../../fixtures/problem_simulators/thread_safety_issues.bash" 2>/dev/null || \
  source "${SCRIPT_DIR}/../../../fixtures/problem_simulators/thread_safety_issues.bash"
source "${SCRIPT_DIR}/../../fixtures/problem_simulators/network_io_bottlenecks.bash" 2>/dev/null || \
  source "${SCRIPT_DIR}/../../../fixtures/problem_simulators/network_io_bottlenecks.bash"

# Constants
readonly DEFAULT_TIMEOUT=300  # Default timeout in seconds
readonly DEFAULT_ACCURACY_THRESHOLD=0.85  # Default accuracy threshold (85%)
readonly DEFAULT_MIN_IMPROVEMENT=0.15  # Default minimum improvement (15%)

# Temporary directories
TEMP_BASELINE_DIR=""
TEMP_OPTIMIZED_DIR=""

# ============================================================
# Test Scenario Setup Functions
# ============================================================

# Create a temporary Maven project for testing
create_test_project() {
  local scenario_type="$1"
  local output_dir="$2"
  
  echo "Creating test project for scenario: $scenario_type"
  
  mkdir -p "$output_dir/src/main/java/com/example"
  mkdir -p "$output_dir/src/test/java/com/example"
  
  # Create a simple Java class
  cat > "$output_dir/src/main/java/com/example/Calculator.java" << 'EOF'
package com.example;

/**
 * A simple calculator class with basic arithmetic operations.
 */
public class Calculator {
    
    /**
     * Adds two numbers.
     *
     * @param a first number
     * @param b second number
     * @return the sum of a and b
     */
    public double add(double a, double b) {
        return a + b;
    }
    
    /**
     * Subtracts the second number from the first.
     *
     * @param a first number
     * @param b second number
     * @return a minus b
     */
    public double subtract(double a, double b) {
        return a - b;
    }
    
    /**
     * Multiplies two numbers.
     *
     * @param a first number
     * @param b second number
     * @return the product of a and b
     */
    public double multiply(double a, double b) {
        return a * b;
    }
    
    /**
     * Divides the first number by the second.
     *
     * @param a first number (dividend)
     * @param b second number (divisor)
     * @return a divided by b
     * @throws IllegalArgumentException if b is zero
     */
    public double divide(double a, double b) {
        if (b == 0) {
            throw new IllegalArgumentException("Division by zero is not allowed");
        }
        return a / b;
    }
}
EOF
  
  # Create appropriate test class based on scenario
  case "$scenario_type" in
    cpu_bound)
      create_cpu_bound_test "$output_dir"
      ;;
    memory_bound)
      create_memory_bound_test "$output_dir"
      ;;
    io_bound)
      create_io_bound_test "$output_dir"
      ;;
    thread_safety)
      create_thread_safety_test "$output_dir"
      ;;
    *)
      create_default_test "$output_dir"
      ;;
  esac
  
  # Create pom.xml
  cat > "$output_dir/pom.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.example</groupId>
    <artifactId>mvnimble-test-project</artifactId>
    <version>1.0-SNAPSHOT</version>

    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <junit.version>5.8.2</junit.version>
        
        <!-- Default sub-optimal settings -->
        <jvm.fork.count>0.5C</jvm.fork.count>
        <maven.threads>1</maven.threads>
        <jvm.fork.memory>256M</jvm.fork.memory>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter-api</artifactId>
            <version>${junit.version}</version>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter-engine</artifactId>
            <version>${junit.version}</version>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <version>3.0.0</version>
                <configuration>
                    <forkCount>${jvm.fork.count}</forkCount>
                    <threadCount>${maven.threads}</threadCount>
                    <reuseForks>true</reuseForks>
                    <argLine>-Xms${jvm.fork.memory} -Xmx${jvm.fork.memory}</argLine>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
EOF
  
  echo "Test project created at: $output_dir"
}

# Create CPU-bound test scenario
create_cpu_bound_test() {
  local output_dir="$1"
  
  cat > "$output_dir/src/test/java/com/example/CpuBoundTest.java" << 'EOF'
package com.example;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import java.util.concurrent.TimeUnit;

/**
 * CPU-bound test that performs intensive calculations
 */
public class CpuBoundTest {
    
    private Calculator calculator = new Calculator();
    
    @Test
    public void testComplexCalculation() {
        // Perform CPU-intensive calculations
        double result = 0;
        for (int i = 0; i < 10000; i++) {
            for (int j = 0; j < 1000; j++) {
                result += calculator.add(calculator.multiply(i, j), calculator.divide(i + 1, j + 1));
                // Ensure values are used to avoid optimization
                if (result == Double.NEGATIVE_INFINITY) {
                    fail("Unexpected result");
                }
            }
        }
        assertTrue(result > 0, "Result should be positive");
    }
    
    @Test
    public void testParallelCalculation() {
        // Another CPU-intensive test that benefits from parallelism
        double[] results = new double[20];
        
        for (int t = 0; t < 20; t++) {
            final int testIndex = t;
            // This would benefit from parallel execution
            double subResult = 0;
            for (int i = 0; i < 5000; i++) {
                for (int j = 0; j < 500; j++) {
                    subResult += calculator.add(calculator.multiply(i + testIndex, j), 
                                               calculator.divide(i + testIndex + 1, j + 1));
                }
            }
            results[testIndex] = subResult;
        }
        
        for (double result : results) {
            assertTrue(result > 0, "Each result should be positive");
        }
    }
    
    @Test
    public void testMathOperations() {
        // Test that performs various math operations
        double result = 0;
        for (int i = 0; i < 8000; i++) {
            result += Math.sin(i) * Math.cos(i) + Math.tan(i) + Math.sqrt(Math.abs(i));
        }
        assertTrue(result != Double.NaN, "Result should be a number");
    }
}
EOF
}

# Create memory-bound test scenario
create_memory_bound_test() {
  local output_dir="$1"
  
  cat > "$output_dir/src/test/java/com/example/MemoryBoundTest.java" << 'EOF'
package com.example;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import java.util.ArrayList;
import java.util.List;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;

/**
 * Memory-bound test that allocates large data structures
 */
public class MemoryBoundTest {
    
    private final Random random = new Random(42); // Fixed seed for reproducibility
    
    @Test
    public void testLargeArrayProcessing() {
        // Create and process a large array
        int size = 2000000;
        double[] largeArray = new double[size];
        
        // Fill array with random values
        for (int i = 0; i < size; i++) {
            largeArray[i] = random.nextDouble();
        }
        
        // Process array
        double sum = 0;
        for (int i = 0; i < size; i++) {
            sum += largeArray[i];
        }
        
        assertTrue(sum > 0, "Sum should be positive with our seed");
    }
    
    @Test
    public void testLargeCollectionOperations() {
        // Create and manipulate large collections
        int size = 500000;
        List<String> largeList = new ArrayList<>(size);
        Map<String, Double> largeMap = new HashMap<>(size);
        
        // Fill collections
        for (int i = 0; i < size; i++) {
            String key = "key" + i;
            largeList.add(key);
            largeMap.put(key, random.nextDouble());
        }
        
        // Process collections
        double sum = 0;
        for (String key : largeList) {
            Double value = largeMap.get(key);
            if (value != null) {
                sum += value;
            }
        }
        
        assertTrue(sum > 0, "Sum should be positive");
    }
    
    @Test
    public void testNestedDataStructures() {
        // Create nested data structures that consume memory
        int outerSize = 1000;
        int innerSize = 1000;
        
        List<List<Double>> nestedList = new ArrayList<>(outerSize);
        
        for (int i = 0; i < outerSize; i++) {
            List<Double> innerList = new ArrayList<>(innerSize);
            for (int j = 0; j < innerSize; j++) {
                innerList.add(random.nextDouble());
            }
            nestedList.add(innerList);
        }
        
        // Process nested structure
        double sum = 0;
        for (List<Double> innerList : nestedList) {
            for (Double value : innerList) {
                sum += value;
            }
        }
        
        assertTrue(sum > 0, "Sum should be positive");
    }
}
EOF
}

# Create I/O-bound test scenario
create_io_bound_test() {
  local output_dir="$1"
  
  # Create data directory
  mkdir -p "$output_dir/src/test/resources/data"
  
  # Generate test data files
  for i in {1..10}; do
    # Create 1MB test file
    dd if=/dev/zero bs=1024 count=1024 2>/dev/null | tr '\0' "$(printf '%d' $i)" > "$output_dir/src/test/resources/data/test_file_$i.dat"
  done
  
  cat > "$output_dir/src/test/java/com/example/IoBoundTest.java" << 'EOF'
package com.example;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import java.io.*;
import java.nio.file.*;
import java.util.List;
import java.util.ArrayList;
import java.util.stream.Collectors;

/**
 * I/O-bound test that performs extensive file operations
 */
public class IoBoundTest {
    
    @Test
    public void testFileReading() throws IOException {
        // Read multiple files
        File dataDir = new File(getClass().getClassLoader().getResource("data").getFile());
        File[] files = dataDir.listFiles((dir, name) -> name.endsWith(".dat"));
        
        assertNotNull(files, "Data files should exist");
        assertTrue(files.length > 0, "Should find at least one data file");
        
        // Read each file and compute checksum
        for (File file : files) {
            long checksum = 0;
            try (FileInputStream fis = new FileInputStream(file);
                 BufferedInputStream bis = new BufferedInputStream(fis)) {
                
                byte[] buffer = new byte[8192];
                int bytesRead;
                while ((bytesRead = bis.read(buffer)) != -1) {
                    for (int i = 0; i < bytesRead; i++) {
                        checksum += buffer[i];
                    }
                }
            }
            
            assertTrue(checksum > 0, "Checksum should be positive");
        }
    }
    
    @Test
    public void testFileWriting() throws IOException {
        // Write to multiple files
        Path tempDir = Files.createTempDirectory("io-test");
        List<Path> tempFiles = new ArrayList<>();
        
        // Create and write to files
        for (int i = 0; i < 10; i++) {
            Path tempFile = tempDir.resolve("output_" + i + ".dat");
            tempFiles.add(tempFile);
            
            try (BufferedWriter writer = Files.newBufferedWriter(tempFile)) {
                // Write 1MB of data
                char[] buffer = new char[1024];
                for (int j = 0; j < 1024; j++) {
                    buffer[j] = (char)('A' + (i % 26));
                }
                
                for (int k = 0; k < 1024; k++) {
                    writer.write(buffer);
                }
            }
        }
        
        // Verify files were created
        for (Path file : tempFiles) {
            assertTrue(Files.exists(file), "File should exist: " + file);
            assertTrue(Files.size(file) > 0, "File should not be empty: " + file);
        }
        
        // Clean up
        for (Path file : tempFiles) {
            Files.deleteIfExists(file);
        }
        Files.deleteIfExists(tempDir);
    }
    
    @Test
    public void testFileSearching() throws IOException {
        // Search through files for content
        File dataDir = new File(getClass().getClassLoader().getResource("data").getFile());
        
        // Find all .dat files recursively
        List<Path> datFiles = Files.walk(dataDir.toPath())
            .filter(path -> path.toString().endsWith(".dat"))
            .collect(Collectors.toList());
        
        assertFalse(datFiles.isEmpty(), "Should find at least one .dat file");
        
        // Search each file for specific byte patterns
        for (Path file : datFiles) {
            byte targetByte = (byte)'1';
            long occurrences = 0;
            
            try (InputStream is = Files.newInputStream(file);
                 BufferedInputStream bis = new BufferedInputStream(is)) {
                
                byte[] buffer = new byte[8192];
                int bytesRead;
                while ((bytesRead = bis.read(buffer)) != -1) {
                    for (int i = 0; i < bytesRead; i++) {
                        if (buffer[i] == targetByte) {
                            occurrences++;
                        }
                    }
                }
            }
            
            // Not asserting specific count, just tracking occurrences
        }
    }
}
EOF
}

# Create thread safety test scenario
create_thread_safety_test() {
  local output_dir="$1"
  
  cat > "$output_dir/src/test/java/com/example/ThreadSafetyTest.java" << 'EOF'
package com.example;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

import java.util.Map;
import java.util.HashMap;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Thread safety tests with various concurrency issues
 */
public class ThreadSafetyTest {
    
    // Thread-unsafe counter
    private int unsafeCounter = 0;
    
    // Thread-safe counter
    private AtomicInteger safeCounter = new AtomicInteger(0);
    
    // Unsafe map for concurrent access
    private Map<String, Integer> unsafeMap = new HashMap<>();
    
    // Safe map for concurrent access
    private Map<String, Integer> safeMap = new ConcurrentHashMap<>();
    
    @Test
    public void testUnsafeCounter() throws InterruptedException {
        int numThreads = 10;
        int incrementsPerThread = 1000;
        ExecutorService executor = Executors.newFixedThreadPool(numThreads);
        CountDownLatch latch = new CountDownLatch(numThreads);
        
        unsafeCounter = 0;
        
        // Spawn threads to increment the counter
        for (int i = 0; i < numThreads; i++) {
            executor.submit(() -> {
                try {
                    for (int j = 0; j < incrementsPerThread; j++) {
                        // This operation is not atomic
                        unsafeCounter++;
                    }
                } finally {
                    latch.countDown();
                }
            });
        }
        
        // Wait for all threads to complete
        latch.await(10, TimeUnit.SECONDS);
        executor.shutdown();
        
        // This assertion will likely fail due to race condition
        assertEquals(numThreads * incrementsPerThread, unsafeCounter, 
                "Unsafe counter should equal the expected total");
    }
    
    @Test
    public void testSafeCounter() throws InterruptedException {
        int numThreads = 10;
        int incrementsPerThread = 1000;
        ExecutorService executor = Executors.newFixedThreadPool(numThreads);
        CountDownLatch latch = new CountDownLatch(numThreads);
        
        safeCounter.set(0);
        
        // Spawn threads to increment the counter
        for (int i = 0; i < numThreads; i++) {
            executor.submit(() -> {
                try {
                    for (int j = 0; j < incrementsPerThread; j++) {
                        // This operation is atomic
                        safeCounter.incrementAndGet();
                    }
                } finally {
                    latch.countDown();
                }
            });
        }
        
        // Wait for all threads to complete
        latch.await(10, TimeUnit.SECONDS);
        executor.shutdown();
        
        // This assertion should pass
        assertEquals(numThreads * incrementsPerThread, safeCounter.get(), 
                "Safe counter should equal the expected total");
    }
    
    @Test
    public void testUnsafeMap() throws InterruptedException {
        int numThreads = 10;
        int operationsPerThread = 1000;
        ExecutorService executor = Executors.newFixedThreadPool(numThreads);
        CountDownLatch latch = new CountDownLatch(numThreads);
        
        unsafeMap.clear();
        
        // Spawn threads to modify the map
        for (int i = 0; i < numThreads; i++) {
            final int threadId = i;
            executor.submit(() -> {
                try {
                    for (int j = 0; j < operationsPerThread; j++) {
                        String key = "key-" + threadId + "-" + j;
                        unsafeMap.put(key, j);
                        
                        // Some threads will read while others write
                        if (j % 2 == 0) {
                            for (String existingKey : unsafeMap.keySet()) {
                                // This might throw ConcurrentModificationException
                                Integer value = unsafeMap.get(existingKey);
                                // Just accessing the value
                                if (value != null && value < 0) {
                                    fail("Value should be non-negative");
                                }
                            }
                        }
                    }
                } catch (Exception e) {
                    // Catching exceptions to let the test complete
                    System.err.println("Exception in thread " + threadId + ": " + e.getMessage());
                } finally {
                    latch.countDown();
                }
            });
        }
        
        // Wait for all threads to complete
        latch.await(10, TimeUnit.SECONDS);
        executor.shutdown();
        
        // The map size may not equal the expected total due to race conditions
        assertTrue(unsafeMap.size() <= numThreads * operationsPerThread, 
                "Unsafe map size should not exceed the expected total");
    }
}
EOF
}

# Create default test scenario
create_default_test() {
  local output_dir="$1"
  
  cat > "$output_dir/src/test/java/com/example/DefaultTest.java" << 'EOF'
package com.example;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Basic test class for the Calculator
 */
public class DefaultTest {
    
    private Calculator calculator = new Calculator();
    
    @Test
    public void testAdd() {
        assertEquals(5, calculator.add(2, 3), "2 + 3 should equal 5");
        assertEquals(0, calculator.add(-2, 2), "-2 + 2 should equal 0");
        assertEquals(-5, calculator.add(-2, -3), "-2 + -3 should equal -5");
    }
    
    @Test
    public void testSubtract() {
        assertEquals(2, calculator.subtract(5, 3), "5 - 3 should equal 2");
        assertEquals(-2, calculator.subtract(3, 5), "3 - 5 should equal -2");
        assertEquals(0, calculator.subtract(3, 3), "3 - 3 should equal 0");
    }
    
    @Test
    public void testMultiply() {
        assertEquals(6, calculator.multiply(2, 3), "2 * 3 should equal 6");
        assertEquals(0, calculator.multiply(5, 0), "5 * 0 should equal 0");
        assertEquals(-6, calculator.multiply(2, -3), "2 * -3 should equal -6");
    }
    
    @Test
    public void testDivide() {
        assertEquals(2, calculator.divide(6, 3), "6 / 3 should equal 2");
        assertEquals(0.5, calculator.divide(1, 2), "1 / 2 should equal 0.5");
        assertEquals(-2, calculator.divide(-6, 3), "-6 / 3 should equal -2");
    }
    
    @Test
    public void testDivideByZero() {
        Exception exception = assertThrows(IllegalArgumentException.class, () -> {
            calculator.divide(1, 0);
        });
        
        String expectedMessage = "Division by zero is not allowed";
        String actualMessage = exception.getMessage();
        
        assertTrue(actualMessage.contains(expectedMessage));
    }
}
EOF
}

# Setup a test scenario with constraints
setup_baseline_scenario() {
  local scenario_type="$1"
  local constraint_level="${2:-medium}"
  
  echo "Setting up baseline scenario: $scenario_type (constraint level: $constraint_level)"
  
  # Create temporary directory for the project
  TEMP_BASELINE_DIR=$(mktemp -d)
  TEMP_OPTIMIZED_DIR=$(mktemp -d)
  
  # Create test project
  create_test_project "$scenario_type" "$TEMP_BASELINE_DIR"
  
  # Copy project to optimized directory
  cp -r "$TEMP_BASELINE_DIR/"* "$TEMP_OPTIMIZED_DIR/"
  
  # Apply constraints based on scenario type
  case "$scenario_type" in
    cpu_bound)
      apply_cpu_constraints "$TEMP_BASELINE_DIR" "$constraint_level"
      ;;
    memory_bound)
      apply_memory_constraints "$TEMP_BASELINE_DIR" "$constraint_level"
      ;;
    io_bound)
      apply_io_constraints "$TEMP_BASELINE_DIR" "$constraint_level"
      ;;
    thread_safety)
      apply_thread_safety_constraints "$TEMP_BASELINE_DIR" "$constraint_level"
      ;;
    *)
      echo "Unknown scenario type: $scenario_type, no constraints applied"
      ;;
  esac
  
  echo "Baseline scenario set up in: $TEMP_BASELINE_DIR"
  echo "Optimized directory prepared: $TEMP_OPTIMIZED_DIR"
}

# Apply CPU constraints to the test
apply_cpu_constraints() {
  local test_dir="$1"
  local level="$2"
  
  case "$level" in
    low)
      simulate_high_cpu_load 30 9999 &
      ;;
    medium)
      simulate_high_cpu_load 60 9999 &
      ;;
    high)
      simulate_high_cpu_load 90 9999 &
      ;;
  esac
  
  # Store constraint PID for cleanup
  echo $! > "$test_dir/.constraint_pid"
}

# Apply memory constraints to the test
apply_memory_constraints() {
  local test_dir="$1"
  local level="$2"
  
  case "$level" in
    low)
      simulate_memory_pressure 50 9999 &
      ;;
    medium)
      simulate_memory_pressure 75 9999 &
      ;;
    high)
      simulate_memory_pressure 85 9999 &
      ;;
  esac
  
  # Store constraint PID for cleanup
  echo $! > "$test_dir/.constraint_pid"
}

# Apply I/O constraints to the test
apply_io_constraints() {
  local test_dir="$1"
  local level="$2"
  
  case "$level" in
    low)
      simulate_io_throttling 4096 4096
      ;;
    medium)
      simulate_io_throttling 1024 1024
      ;;
    high)
      simulate_io_throttling 512 512
      ;;
  esac
  
  # Store "io" for cleanup
  echo "io" > "$test_dir/.constraint_type"
}

# Apply thread safety constraints to the test
apply_thread_safety_constraints() {
  local test_dir="$1"
  local level="$2"
  
  case "$level" in
    low)
      simulate_race_condition
      ;;
    medium)
      simulate_thread_ordering_dependency
      ;;
    high)
      simulate_deadlock
      ;;
  esac
  
  # Store "thread" for cleanup
  echo "thread" > "$test_dir/.constraint_type"
}

# ============================================================
# Test Execution and Metric Collection Functions
# ============================================================

# Run test and collect metrics
run_test_and_collect_metrics() {
  local test_dir="$1"
  local timeout="${2:-$DEFAULT_TIMEOUT}"
  
  echo "Running test in directory: $test_dir"
  
  # Prepare output files
  local log_file="$test_dir/mvn_test.log"
  local metrics_file="$test_dir/metrics.txt"
  
  # Record start time
  local start_time=$(date +%s.%N)
  
  # Run Maven test with timeout
  timeout "$timeout" bash -c "cd \"$test_dir\" && mvn clean test" > "$log_file" 2>&1
  local status=$?
  
  # Record end time
  local end_time=$(date +%s.%N)
  
  # Calculate runtime
  if [[ "$(uname)" == "Darwin" ]]; then
    # macOS doesn't support the same date arithmetic
    local runtime=$(perl -e "printf \"%.2f\", $end_time - $start_time")
  else
    local runtime=$(echo "$end_time - $start_time" | bc)
  fi
  
  # Extract test counts
  local tests_run=$(grep -E "Tests run:" "$log_file" | awk '{sum+=$3} END {print sum}')
  local tests_failed=$(grep -E "Tests run:" "$log_file" | awk '{sum+=$5} END {print sum}')
  local tests_errors=$(grep -E "Tests run:" "$log_file" | awk '{sum+=$7} END {print sum}')
  
  # Extract resource usage if available
  local peak_cpu="N/A"
  local peak_mem="N/A"
  if grep -q "CPU:" "$log_file"; then
    peak_cpu=$(grep "CPU:" "$log_file" | cut -d' ' -f2 | sort -nr | head -1)
  fi
  if grep -q "MEM:" "$log_file"; then
    peak_mem=$(grep "MEM:" "$log_file" | cut -d' ' -f2 | sort -nr | head -1)
  fi
  
  # Write metrics to file
  cat > "$metrics_file" << EOF
runtime=$runtime
status=$status
tests_run=${tests_run:-0}
tests_failed=${tests_failed:-0}
tests_errors=${tests_errors:-0}
peak_cpu=$peak_cpu
peak_mem=$peak_mem
EOF
  
  echo "Test completed in $runtime seconds with status $status"
  echo "Metrics saved to: $metrics_file"
  
  # Return metrics file path
  echo "$metrics_file"
}

# Generate MVNimble recommendations
generate_mvnimble_recommendations() {
  local test_dir="$1"
  local log_file="$test_dir/mvn_test.log"
  local output_dir="$test_dir/mvnimble_output"
  
  echo "Generating MVNimble recommendations based on test log"
  
  # Create output directory
  mkdir -p "$output_dir"
  
  # Run MVNimble on the test log
  if [[ -f "/Users/vorthruna/Code/mvnimble/test/bats/fixtures/problem_simulators/optimization_config_generator.bash" ]]; then
    echo "Using fixtures directory path"
    "/Users/vorthruna/Code/mvnimble/test/bats/fixtures/problem_simulators/optimization_config_generator.bash" "$log_file" "$output_dir"
  elif [[ -f "/Users/vorthruna/Code/mvnimble/test/fixtures/problem_simulators/optimization_config_generator.bash" ]]; then
    echo "Using test fixtures directory path"
    "/Users/vorthruna/Code/mvnimble/test/fixtures/problem_simulators/optimization_config_generator.bash" "$log_file" "$output_dir"
  else
    echo "Warning: optimization_config_generator.bash not found, using mock generator"
    # Mock generator for testing
    create_mock_recommendations "$log_file" "$output_dir"
  fi
  
  echo "Recommendations generated at: $output_dir"
  
  # Return the output directory
  echo "$output_dir"
}

# Create mock recommendations for testing
create_mock_recommendations() {
  local log_file="$1"
  local output_dir="$2"
  
  echo "Creating mock recommendations for testing"
  
  # Determine bottlenecks from log
  local cpu_bottleneck="false"
  local memory_bottleneck="false"
  local io_bottleneck="false"
  local thread_bottleneck="false"
  
  if grep -q "CPU: [89][0-9]%" "$log_file" || grep -q "CPU: 100%" "$log_file"; then
    cpu_bottleneck="true"
  fi
  
  if grep -q "OutOfMemoryError" "$log_file" || grep -q "heap space" "$log_file"; then
    memory_bottleneck="true"
  fi
  
  if grep -q "Slow I/O" "$log_file"; then
    io_bottleneck="true"
  fi
  
  if grep -q "ConcurrentModificationException" "$log_file"; then
    thread_bottleneck="true"
  fi
  
  # Generate mock POM snippet
  cat > "$output_dir/pom-snippet.xml" << EOF
<!-- MVNimble generated optimization snippet for pom.xml -->
<build>
  <plugins>
    <!-- Memory optimization -->
    <plugin>
      <groupId>org.apache.maven.plugins</groupId>
      <artifactId>maven-surefire-plugin</artifactId>
      <version>3.0.0</version>
      <configuration>
        <argLine>-Xms1024m -Xmx4096m -XX:+UseG1GC</argLine>
        
        <!-- CPU and parallel execution optimization -->
        <parallel>classes</parallel>
        <threadCount>4</threadCount>
        <perCoreThreadCount>true</perCoreThreadCount>
        <forkCount>1C</forkCount>
        <reuseForks>true</reuseForks>
        
        <!-- Thread safety optimization -->
        <rerunFailingTestsCount>2</rerunFailingTestsCount>
        
        <!-- Test result optimization -->
        <trimStackTrace>false</trimStackTrace>
        <useFile>false</useFile>
        <disableXmlReport>false</disableXmlReport>
      </configuration>
    </plugin>
  </plugins>
</build>
EOF
  
  # Generate mock optimization summary
  cat > "$output_dir/optimization-summary.md" << EOF
# MVNimble Test Optimization Summary

## Detected Bottlenecks

1. **CPU Utilization**: $cpu_bottleneck
   - Utilization appears to be high
   - Recommendation: Optimize thread count and reduce CPU-intensive operations

2. **Memory Constraints**: $memory_bottleneck
   - Memory issues detected
   - Recommendation: Increase heap size and optimize object creation

3. **Disk I/O**: $io_bottleneck
   - I/O bottlenecks detected
   - Recommendation: Optimize file operations and consider using RAM disk

4. **Thread Safety**: $thread_bottleneck
   - Thread safety issues detected
   - Recommendation: Identify and fix thread safety issues in tests

## Predicted Improvements

- Execution Time: -35%
- Memory Usage: -20%
- CPU Utilization: -15%
- Thread Efficiency: +40%

## Implementation Plan

1. Apply the generated Maven settings by copying settings.xml to ~/.m2/settings.xml or merge with existing settings
2. Add the POM snippet to your project's pom.xml
3. Use the maven-opts.sh script to set environment variables before running Maven
4. Follow the multimodule strategy document for optimizing build organization
5. Monitor test execution with these changes and adjust as needed
EOF
  
  # Create recommended settings
  cat > "$output_dir/recommendations.txt" << EOF
fastest_forks=1.0C
fastest_threads=4
fastest_memory=1024M
EOF
}

# Extract predicted improvement percentage
extract_predicted_improvement() {
  local recommendations_dir="$1"
  local summary_file="$recommendations_dir/optimization-summary.md"
  
  echo "Extracting predicted improvement from recommendations"
  
  # Extract improvement percentage from summary
  if [[ -f "$summary_file" ]]; then
    local improvement=$(grep "Execution Time:" "$summary_file" | grep -o -E "\-[0-9]+%" | tr -d '%' | tr -d '-')
    echo "$improvement"
  else
    echo "Error: Summary file not found at $summary_file" >&2
    echo "0"
  fi
}

# Apply recommendations to test project
apply_recommendations() {
  local recommendations_dir="$1"
  local target_dir="$2"
  
  echo "Applying recommendations to target directory: $target_dir"
  
  # Check if recommendations exist
  if [[ ! -d "$recommendations_dir" ]]; then
    echo "Error: Recommendations directory not found: $recommendations_dir" >&2
    return 1
  fi
  
  # Read optimal settings
  local recommendations_file="$recommendations_dir/recommendations.txt"
  if [[ -f "$recommendations_file" ]]; then
    local fork_count=$(grep "fastest_forks" "$recommendations_file" | cut -d= -f2)
    local thread_count=$(grep "fastest_threads" "$recommendations_file" | cut -d= -f2)
    local memory=$(grep "fastest_memory" "$recommendations_file" | cut -d= -f2)
    
    # Update pom.xml with recommended settings
    echo "Updating pom.xml with: Forks=$fork_count, Threads=$thread_count, Memory=$memory"
    
    # Check if pom.xml exists
    if [[ -f "$target_dir/pom.xml" ]]; then
      # Update settings in pom.xml
      sed -i.bak "s/<jvm.fork.count>.*<\/jvm.fork.count>/<jvm.fork.count>${fork_count}<\/jvm.fork.count>/" "$target_dir/pom.xml"
      sed -i.bak "s/<maven.threads>.*<\/maven.threads>/<maven.threads>${thread_count}<\/maven.threads>/" "$target_dir/pom.xml"
      sed -i.bak "s/<jvm.fork.memory>.*<\/jvm.fork.memory>/<jvm.fork.memory>${memory}<\/jvm.fork.memory>/" "$target_dir/pom.xml"
      
      # Remove backup file
      rm -f "$target_dir/pom.xml.bak"
      
      echo "Successfully updated pom.xml with recommended settings"
      return 0
    else
      echo "Error: pom.xml not found in target directory: $target_dir" >&2
      return 1
    fi
  else
    echo "Error: Recommendations file not found: $recommendations_file" >&2
    return 1
  fi
}

# ============================================================
# Result Analysis Functions
# ============================================================

# Calculate actual improvement percentage
calculate_improvement() {
  local baseline_metrics="$1"
  local improved_metrics="$2"
  
  echo "Calculating improvement between baseline and optimized metrics"
  
  # Extract runtime from metrics files
  local baseline_runtime=$(grep "runtime=" "$baseline_metrics" | cut -d= -f2)
  local improved_runtime=$(grep "runtime=" "$improved_metrics" | cut -d= -f2)
  
  # Calculate improvement percentage
  local improvement=0
  if [[ -n "$baseline_runtime" && -n "$improved_runtime" && "$baseline_runtime" != "0" ]]; then
    improvement=$(echo "scale=2; 100 * ($baseline_runtime - $improved_runtime) / $baseline_runtime" | bc)
  fi
  
  echo "Baseline runtime: $baseline_runtime seconds"
  echo "Improved runtime: $improved_runtime seconds"
  echo "Improvement: $improvement%"
  
  # Return the improvement percentage
  echo "$improvement"
}

# Calculate prediction accuracy
calculate_prediction_accuracy() {
  local predicted_improvement="$1"
  local actual_improvement="$2"
  
  echo "Calculating prediction accuracy"
  echo "Predicted improvement: $predicted_improvement%"
  echo "Actual improvement: $actual_improvement%"
  
  # Calculate accuracy
  local accuracy=0
  if [[ "$predicted_improvement" != "0" ]]; then
    accuracy=$(echo "scale=2; 100 * (1 - (($predicted_improvement - $actual_improvement) / $predicted_improvement))" | bc)
    
    # Ensure accuracy is between 0 and 100
    if (( $(echo "$accuracy < 0" | bc -l) )); then
      accuracy=0
    elif (( $(echo "$accuracy > 100" | bc -l) )); then
      accuracy=100
    fi
  elif [[ "$actual_improvement" == "0" ]]; then
    # If both predicted and actual are 0, that's 100% accurate
    accuracy=100
  fi
  
  echo "Prediction accuracy: $accuracy%"
  
  # Return the accuracy percentage
  echo "$accuracy"
}

# Assert minimum accuracy
assert_minimum_accuracy() {
  local actual_accuracy="$1"
  local minimum_accuracy="${2:-$DEFAULT_ACCURACY_THRESHOLD}"
  
  echo "Asserting minimum accuracy: $minimum_accuracy%"
  
  # Convert to integers for comparison (removing decimal part)
  local actual_int=$(echo "$actual_accuracy" | cut -d. -f1)
  local minimum_int=$(echo "$minimum_accuracy" | cut -d. -f1)
  
  # Assert minimum accuracy
  if (( actual_int >= minimum_int )); then
    echo "✅ Accuracy assertion passed: $actual_accuracy% >= $minimum_accuracy%"
    return 0
  else
    echo "❌ Accuracy assertion failed: $actual_accuracy% < $minimum_accuracy%"
    return 1
  fi
}

# Assert minimum improvement
assert_minimum_improvement() {
  local actual_improvement="$1"
  local minimum_improvement="${2:-$DEFAULT_MIN_IMPROVEMENT}"
  
  echo "Asserting minimum improvement: $minimum_improvement%"
  
  # Convert to integers for comparison (removing decimal part)
  local actual_int=$(echo "$actual_improvement" | cut -d. -f1)
  local minimum_int=$(echo "$minimum_improvement" | cut -d. -f1)
  
  # Assert minimum improvement
  if (( actual_int >= minimum_int )); then
    echo "✅ Improvement assertion passed: $actual_improvement% >= $minimum_improvement%"
    return 0
  else
    echo "❌ Improvement assertion failed: $actual_improvement% < $minimum_improvement%"
    return 1
  fi
}

# ============================================================
# Clean Up Functions
# ============================================================

# Clean up resources used by the test
cleanup_resources() {
  echo "Cleaning up resources"
  
  # Clean up constraint processes
  if [[ -n "$TEMP_BASELINE_DIR" && -f "$TEMP_BASELINE_DIR/.constraint_pid" ]]; then
    local pid=$(cat "$TEMP_BASELINE_DIR/.constraint_pid")
    if [[ -n "$pid" ]]; then
      echo "Stopping constraint process: $pid"
      kill -9 "$pid" 2>/dev/null || true
    fi
  fi
  
  # Clean up I/O constraints
  if [[ -n "$TEMP_BASELINE_DIR" && -f "$TEMP_BASELINE_DIR/.constraint_type" ]]; then
    local type=$(cat "$TEMP_BASELINE_DIR/.constraint_type")
    if [[ "$type" == "io" ]]; then
      echo "Stopping I/O constraints"
      stop_io_throttling
    elif [[ "$type" == "thread" ]]; then
      echo "Stopping thread constraints"
      # Thread constraints typically clean up automatically
    fi
  fi
  
  # Remove temporary directories
  if [[ -n "$TEMP_BASELINE_DIR" && -d "$TEMP_BASELINE_DIR" ]]; then
    echo "Removing baseline directory: $TEMP_BASELINE_DIR"
    rm -rf "$TEMP_BASELINE_DIR"
  fi
  
  if [[ -n "$TEMP_OPTIMIZED_DIR" && -d "$TEMP_OPTIMIZED_DIR" ]]; then
    echo "Removing optimized directory: $TEMP_OPTIMIZED_DIR"
    rm -rf "$TEMP_OPTIMIZED_DIR"
  fi
}

# ============================================================
# Main Validation Function
# ============================================================

# Main closed-loop validation function
closed_loop_validate() {
  local scenario="$1"
  local constraint_level="${2:-medium}"
  local min_accuracy="${3:-85}"
  local min_improvement="${4:-15}"
  
  echo "=== Starting Closed-Loop Validation for $scenario scenario ==="
  echo "Constraint level: $constraint_level"
  echo "Minimum accuracy threshold: $min_accuracy%"
  echo "Minimum improvement threshold: $min_improvement%"
  
  # Set up trap to clean up on exit
  trap cleanup_resources EXIT
  
  # Create baseline test environment
  setup_baseline_scenario "$scenario" "$constraint_level"
  
  # Run initial test and collect metrics
  local baseline_metrics=$(run_test_and_collect_metrics "$TEMP_BASELINE_DIR")
  
  # Generate MVNimble recommendations
  local recommendations_dir=$(generate_mvnimble_recommendations "$TEMP_BASELINE_DIR")
  local predicted_improvement=$(extract_predicted_improvement "$recommendations_dir")
  
  # Apply recommendations to optimized directory
  apply_recommendations "$recommendations_dir" "$TEMP_OPTIMIZED_DIR"
  
  # Run test again with recommendations applied
  local improved_metrics=$(run_test_and_collect_metrics "$TEMP_OPTIMIZED_DIR")
  
  # Calculate actual improvement
  local actual_improvement=$(calculate_improvement "$baseline_metrics" "$improved_metrics")
  
  # Calculate prediction accuracy
  local accuracy=$(calculate_prediction_accuracy "$predicted_improvement" "$actual_improvement")
  
  # Assert minimum accuracy
  assert_minimum_accuracy "$accuracy" "$min_accuracy"
  local accuracy_status=$?
  
  # Assert minimum improvement
  assert_minimum_improvement "$actual_improvement" "$min_improvement"
  local improvement_status=$?
  
  echo "=== Closed-Loop Validation Results ==="
  echo "Predicted improvement: $predicted_improvement%"
  echo "Actual improvement: $actual_improvement%"
  echo "Prediction accuracy: $accuracy%"
  
  if [[ "$accuracy_status" -eq 0 && "$improvement_status" -eq 0 ]]; then
    echo "✅ Validation PASSED"
    return 0
  else
    echo "❌ Validation FAILED"
    return 1
  fi
}

# Run a full suite of closed-loop validation tests
run_closed_loop_test_suite() {
  local result_dir="${1:-./validation_results}"
  mkdir -p "$result_dir"
  
  echo "=== Running Closed-Loop Validation Test Suite ==="
  echo "Results will be saved to: $result_dir"
  
  local scenarios=("cpu_bound" "memory_bound" "io_bound" "thread_safety")
  local constraint_levels=("low" "medium" "high")
  local success_count=0
  local total_count=0
  
  for scenario in "${scenarios[@]}"; do
    for level in "${constraint_levels[@]}"; do
      total_count=$((total_count + 1))
      
      echo ""
      echo "=================================================================="
      echo "Testing scenario: $scenario, constraint level: $level"
      echo "=================================================================="
      
      local log_file="$result_dir/${scenario}_${level}.log"
      closed_loop_validate "$scenario" "$level" > "$log_file" 2>&1
      local status=$?
      
      if [[ "$status" -eq 0 ]]; then
        success_count=$((success_count + 1))
        echo "✅ Test passed: $scenario ($level)"
      else
        echo "❌ Test failed: $scenario ($level) - See $log_file for details"
      fi
    done
  done
  
  echo ""
  echo "=== Closed-Loop Test Suite Results ==="
  echo "Tests passed: $success_count/$total_count ($(echo "scale=2; 100 * $success_count / $total_count" | bc)%)"
  
  # Return success if all tests passed
  if [[ "$success_count" -eq "$total_count" ]]; then
    return 0
  else
    return 1
  fi
}

# If executed directly, display usage information
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "MVNimble Closed-Loop Validation Module"
  echo "Usage:"
  echo "  source $(basename "$0") # To load the functions for testing"
  echo ""
  echo "  # Or run a full test suite directly:"
  echo "  $(basename "$0") run_suite [result_directory]"
  
  # If run with "run_suite" argument, execute the test suite
  if [[ "$1" == "run_suite" ]]; then
    run_closed_loop_test_suite "${2:-./validation_results}"
  fi
fi