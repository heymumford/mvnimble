#!/usr/bin/env bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
#
# Thread Safety Validation Suite for MVNimble
#
# This script implements advanced tests to validate MVNimble's ability to detect,
# diagnose, and provide recommendations for various thread safety issues in Maven tests.
#
# The test suite simulates different types of concurrency problems and verifies that
# MVNimble correctly identifies the issues and provides appropriate recommendations.

# Source common libraries
source "$(dirname "$(dirname "$(dirname "$0")")")/test_helper.bash"
source "$(dirname "$(dirname "$(dirname "$0")")")/fixtures/problem_simulators/thread_safety_issues.bash"
source "$(dirname "$(dirname "$(dirname "$0")")")/fixtures/problem_simulators/diagnostic_patterns.bash"

# Constants
THREAD_SAFETY_DIR="${BATS_TEST_DIRNAME}/scenarios"
REPORT_DIR="${BATS_TEST_DIRNAME}/reports"
THREADS_MIN=2
THREADS_MAX=16

#######################################
# Creates the necessary directory structure for thread safety validation
# Arguments:
#   None
# Outputs:
#   None
#######################################
function setup_thread_safety_environment() {
  mkdir -p "${THREAD_SAFETY_DIR}"
  mkdir -p "${REPORT_DIR}"
  
  # Create subdirectories for each thread safety issue category
  mkdir -p "${THREAD_SAFETY_DIR}/race_conditions"
  mkdir -p "${THREAD_SAFETY_DIR}/deadlocks"
  mkdir -p "${THREAD_SAFETY_DIR}/thread_ordering"
  mkdir -p "${THREAD_SAFETY_DIR}/memory_visibility"
  mkdir -p "${THREAD_SAFETY_DIR}/resource_contention"
  mkdir -p "${THREAD_SAFETY_DIR}/thread_leaks"
}

#######################################
# Creates a base Maven test project structure
# Arguments:
#   $1 - Directory path for the project
# Outputs:
#   None
#######################################
function create_base_project() {
  local project_dir="$1"
  mkdir -p "${project_dir}"
  
  # Create a minimal Maven project structure
  mkdir -p "${project_dir}/src/main/java/com/example/threadsafety"
  mkdir -p "${project_dir}/src/test/java/com/example/threadsafety"
  mkdir -p "${project_dir}/src/test/resources"
  
  # Create a basic pom.xml file
  cat > "${project_dir}/pom.xml" << EOF
<project xmlns="http://maven.apache.org/POM/4.0.0" 
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  
  <groupId>com.example</groupId>
  <artifactId>thread-safety-test</artifactId>
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
}

#######################################
# Creates a test scenario for race conditions
# Arguments:
#   $1 - Scenario name
#   $2 - Severity level (low, medium, high)
# Outputs:
#   None
#######################################
function create_race_condition_scenario() {
  local scenario_name="$1"
  local severity="$2"
  
  local scenario_dir="${THREAD_SAFETY_DIR}/race_conditions/${scenario_name}"
  mkdir -p "${scenario_dir}"
  
  # Create base project
  create_base_project "${scenario_dir}/project"
  
  # Create a class with race conditions
  cat > "${scenario_dir}/project/src/main/java/com/example/threadsafety/Counter.java" << EOF
package com.example.threadsafety;

/**
 * A simple counter class with thread safety issues.
 * This class demonstrates race conditions at various severity levels.
 */
public class Counter {
    private int count = 0;
    private long totalOperations = 0;
    private int[] values;
    
    public Counter() {
        this.values = new int[100];
    }
    
    // Non-thread-safe increment (basic race condition)
    public void increment() {
        count++;
        totalOperations++;
    }
    
    // More complex race condition with multiple operations
    public void updateValues(int index, int value) {
        if (index >= 0 && index < values.length) {
            // Race condition: check-then-act pattern
            int oldValue = values[index];
            // Simulate some processing time to increase race window
            try {
                Thread.sleep(5);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
            values[index] = oldValue + value;
            totalOperations++;
        }
    }
    
    // Thread-safe increment
    public synchronized void incrementSafe() {
        count++;
        totalOperations++;
    }
    
    // Thread-safe update
    public synchronized void updateValuesSafe(int index, int value) {
        if (index >= 0 && index < values.length) {
            values[index] += value;
            totalOperations++;
        }
    }
    
    public int getCount() {
        return count;
    }
    
    public int getValue(int index) {
        if (index >= 0 && index < values.length) {
            return values[index];
        }
        return -1;
    }
    
    public long getTotalOperations() {
        return totalOperations;
    }
}
EOF

  # Create test class with race condition tests
  cat > "${scenario_dir}/project/src/test/java/com/example/threadsafety/RaceConditionTest.java" << EOF
package com.example.threadsafety;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.RepeatedTest;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import static org.junit.jupiter.api.Assertions.*;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Tests that demonstrate race conditions.
 * These tests are intentionally designed to fail intermittently due to thread safety issues.
 */
public class RaceConditionTest {
    
    @Test
    public void testBasicRaceCondition() throws Exception {
        Counter counter = new Counter();
        int threadCount = ${severity == "low" ? 5 : (severity == "medium" ? 10 : 20)};
        int incrementsPerThread = ${severity == "low" ? 1000 : (severity == "medium" ? 10000 : 50000)};
        
        CountDownLatch startLatch = new CountDownLatch(1);
        ExecutorService executor = Executors.newFixedThreadPool(threadCount);
        
        // Launch multiple threads to increment the counter
        for (int i = 0; i < threadCount; i++) {
            executor.submit(() -> {
                try {
                    startLatch.await(); // Wait for all threads to be ready
                    for (int j = 0; j < incrementsPerThread; j++) {
                        counter.increment(); // Non-thread-safe increment
                    }
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            });
        }
        
        startLatch.countDown(); // Start all threads
        executor.shutdown();
        boolean completed = executor.awaitTermination(30, TimeUnit.SECONDS);
        assertTrue(completed, "Execution timed out");
        
        // The actual count will likely be less than expected due to race conditions
        int expectedCount = threadCount * incrementsPerThread;
        assertEquals(expectedCount, counter.getCount(), 
            "Count should match expected (this test is designed to fail due to race conditions)");
    }
    
    @ParameterizedTest
    @ValueSource(ints = {0, 10, 20, 30, 40, 50, 60, 70, 80, 90})
    public void testArrayUpdateRaceCondition(int startIndex) throws Exception {
        Counter counter = new Counter();
        int threadCount = ${severity == "low" ? 3 : (severity == "medium" ? 6 : 10)};
        int updatesPerThread = ${severity == "low" ? 10 : (severity == "medium" ? 50 : 100)};
        
        ExecutorService executor = Executors.newFixedThreadPool(threadCount);
        CountDownLatch startLatch = new CountDownLatch(1);
        
        // Launch multiple threads to update the values array
        for (int i = 0; i < threadCount; i++) {
            final int threadNum = i;
            executor.submit(() -> {
                try {
                    startLatch.await(); // Wait for all threads to be ready
                    for (int j = 0; j < updatesPerThread; j++) {
                        int index = (startIndex + threadNum) % 100;
                        counter.updateValues(index, 1); // Non-thread-safe update
                    }
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            });
        }
        
        startLatch.countDown(); // Start all threads
        executor.shutdown();
        boolean completed = executor.awaitTermination(30, TimeUnit.SECONDS);
        assertTrue(completed, "Execution timed out");
        
        // Verify the total operations performed
        long expectedOps = threadCount * updatesPerThread;
        assertEquals(expectedOps, counter.getTotalOperations(), 
            "Total operations should match expected count");
        
        // The actual values will likely be incorrect due to race conditions
        // This assertion is designed to sometimes fail
        for (int i = 0; i < 10; i++) {
            int index = (startIndex + i) % 100;
            if (i < threadCount) {
                int expectedValue = updatesPerThread;
                assertEquals(expectedValue, counter.getValue(index), 
                    "Value at index " + index + " should match expected (this test is designed to fail due to race conditions)");
            }
        }
    }
    
    @RepeatedTest(10)
    public void testIntermittentRaceCondition() throws Exception {
        Counter counter = new Counter();
        AtomicBoolean stopFlag = new AtomicBoolean(false);
        int threadCount = ${severity == "low" ? 3 : (severity == "medium" ? 5 : 8)};
        
        ExecutorService executor = Executors.newFixedThreadPool(threadCount);
        CountDownLatch startLatch = new CountDownLatch(1);
        
        // Create threads that increment the counter at different rates
        for (int i = 0; i < threadCount; i++) {
            final int sleepTime = (i + 1) * 10; // Different sleep times to create unpredictable timing
            executor.submit(() -> {
                try {
                    startLatch.await(); // Wait for all threads to be ready
                    while (!stopFlag.get()) {
                        counter.increment();
                        Thread.sleep(sleepTime);
                    }
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            });
        }
        
        startLatch.countDown(); // Start all threads
        
        // Let the threads run for a while
        Thread.sleep(${severity == "low" ? 1000 : (severity == "medium" ? 2000 : 3000)});
        stopFlag.set(true);
        
        executor.shutdown();
        boolean completed = executor.awaitTermination(5, TimeUnit.SECONDS);
        assertTrue(completed, "Execution timed out");
        
        // We can't make exact assertions because the race conditions create unpredictable results
        // But we should have a count greater than zero
        assertTrue(counter.getCount() > 0, "Count should be greater than zero");
        assertEquals(counter.getCount(), counter.getTotalOperations(), 
            "Count should match total operations (this test is designed to fail due to race conditions)");
    }
    
    @Test
    public void testThreadSafeSolution() throws Exception {
        Counter counter = new Counter();
        int threadCount = 10;
        int incrementsPerThread = 1000;
        
        CountDownLatch startLatch = new CountDownLatch(1);
        ExecutorService executor = Executors.newFixedThreadPool(threadCount);
        
        // Launch multiple threads to increment the counter
        for (int i = 0; i < threadCount; i++) {
            executor.submit(() -> {
                try {
                    startLatch.await(); // Wait for all threads to be ready
                    for (int j = 0; j < incrementsPerThread; j++) {
                        counter.incrementSafe(); // Thread-safe increment
                    }
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            });
        }
        
        startLatch.countDown(); // Start all threads
        executor.shutdown();
        boolean completed = executor.awaitTermination(30, TimeUnit.SECONDS);
        assertTrue(completed, "Execution timed out");
        
        // With thread-safe increment, the count should be exactly as expected
        int expectedCount = threadCount * incrementsPerThread;
        assertEquals(expectedCount, counter.getCount(), "Thread-safe count should match expected");
    }
}
EOF

  # Modify pom.xml to include Surefire settings
  # For race conditions, we set high parallelism to increase the likelihood of failures
  if [[ "$severity" == "high" ]]; then
    sed -i.bak '/<artifactId>maven-surefire-plugin<\/artifactId>/,/<\/plugin>/ s|<version>.*</version>|<version>2.22.2</version>\n        <configuration>\n          <parallel>methods</parallel>\n          <threadCount>4</threadCount>\n          <reuseForks>false</reuseForks>\n        </configuration>|' "${scenario_dir}/project/pom.xml"
    rm "${scenario_dir}/project/pom.xml.bak"
  fi
}

#######################################
# Creates a test scenario for deadlocks
# Arguments:
#   $1 - Scenario name
#   $2 - Severity level (low, medium, high)
# Outputs:
#   None
#######################################
function create_deadlock_scenario() {
  local scenario_name="$1"
  local severity="$2"
  
  local scenario_dir="${THREAD_SAFETY_DIR}/deadlocks/${scenario_name}"
  mkdir -p "${scenario_dir}"
  
  # Create base project
  create_base_project "${scenario_dir}/project"
  
  # Create a class with potential deadlock issues
  cat > "${scenario_dir}/project/src/main/java/com/example/threadsafety/ResourceManager.java" << EOF
package com.example.threadsafety;

import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

/**
 * A resource manager class with potential deadlock issues.
 * This class demonstrates deadlocks at various severity levels.
 */
public class ResourceManager {
    private final Object resourceA = new Object();
    private final Object resourceB = new Object();
    private final Lock lockA = new ReentrantLock();
    private final Lock lockB = new ReentrantLock();
    
    private int valueA = 0;
    private int valueB = 0;
    
    // Method that acquires locks in an order that can cause deadlocks
    public void updateResourcesDeadlockProne(boolean startWithA) {
        if (startWithA) {
            synchronized (resourceA) {
                valueA++;
                // Sleep to increase the likelihood of deadlock
                try {
                    Thread.sleep(${severity == "low" ? 10 : (severity == "medium" ? 50 : 100)});
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
                synchronized (resourceB) {
                    valueB++;
                }
            }
        } else {
            synchronized (resourceB) {
                valueB++;
                // Sleep to increase the likelihood of deadlock
                try {
                    Thread.sleep(${severity == "low" ? 10 : (severity == "medium" ? 50 : 100)});
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
                synchronized (resourceA) {
                    valueA++;
                }
            }
        }
    }
    
    // Method using tryLock that can sometimes cause deadlocks
    public boolean updateResourcesWithTryLock(boolean startWithA) {
        Lock firstLock = startWithA ? lockA : lockB;
        Lock secondLock = startWithA ? lockB : lockA;
        
        try {
            if (firstLock.tryLock(100, TimeUnit.MILLISECONDS)) {
                try {
                    if (startWithA) valueA++; else valueB++;
                    
                    // Add delay to increase chance of contention
                    Thread.sleep(${severity == "low" ? 5 : (severity == "medium" ? 20 : 50)});
                    
                    if (secondLock.tryLock(100, TimeUnit.MILLISECONDS)) {
                        try {
                            if (startWithA) valueB++; else valueA++;
                            return true;
                        } finally {
                            secondLock.unlock();
                        }
                    }
                } finally {
                    firstLock.unlock();
                }
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        
        return false;
    }
    
    // Thread-safe method that acquires locks in a consistent order to prevent deadlocks
    public void updateResourcesSafe() {
        synchronized (resourceA) {
            valueA++;
            synchronized (resourceB) {
                valueB++;
            }
        }
    }
    
    public int getValueA() {
        return valueA;
    }
    
    public int getValueB() {
        return valueB;
    }
}
EOF

  # Create test class with deadlock tests
  cat > "${scenario_dir}/project/src/test/java/com/example/threadsafety/DeadlockTest.java" << EOF
package com.example.threadsafety;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.Timeout;
import static org.junit.jupiter.api.Assertions.*;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.ArrayList;
import java.util.List;

/**
 * Tests that demonstrate deadlock scenarios.
 * These tests are intentionally designed to deadlock under certain conditions.
 */
public class DeadlockTest {
    
    @Test
    @Timeout(value = ${severity == "low" ? 5 : (severity == "medium" ? 8 : 12)}, unit = TimeUnit.SECONDS)
    public void testBasicDeadlock() throws Exception {
        ResourceManager manager = new ResourceManager();
        int threadCount = ${severity == "low" ? 2 : (severity == "medium" ? 4 : 8)};
        int iterationsPerThread = ${severity == "low" ? 10 : (severity == "medium" ? 30 : 100)};
        
        CountDownLatch startLatch = new CountDownLatch(1);
        ExecutorService executor = Executors.newFixedThreadPool(threadCount);
        List<Future<?>> futures = new ArrayList<>();
        
        // Launch threads that acquire locks in opposite orders
        for (int i = 0; i < threadCount; i++) {
            final boolean startWithA = (i % 2 == 0);
            futures.add(executor.submit(() -> {
                try {
                    startLatch.await(); // Wait for all threads to be ready
                    for (int j = 0; j < iterationsPerThread; j++) {
                        manager.updateResourcesDeadlockProne(startWithA);
                    }
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }));
        }
        
        startLatch.countDown(); // Start all threads
        
        // Wait for all tasks to complete or timeout
        for (Future<?> future : futures) {
            try {
                future.get(${severity == "low" ? 3 : (severity == "medium" ? 5 : 10)}, TimeUnit.SECONDS);
            } catch (Exception e) {
                // Expected in high severity cases due to deadlock
                if ("${severity}" != "high") {
                    throw e;
                }
            }
        }
        
        executor.shutdownNow();
        boolean terminated = executor.awaitTermination(2, TimeUnit.SECONDS);
        
        // This assertion may never be reached in high severity cases due to deadlock
        assertTrue(terminated, "Executor should terminate");
        
        // Verify both values were updated
        assertTrue(manager.getValueA() > 0, "ValueA should be updated");
        assertTrue(manager.getValueB() > 0, "ValueB should be updated");
    }
    
    @Test
    @Timeout(value = ${severity == "low" ? 5 : (severity == "medium" ? 8 : 12)}, unit = TimeUnit.SECONDS)
    public void testTryLockDeadlock() throws Exception {
        ResourceManager manager = new ResourceManager();
        int threadCount = ${severity == "low" ? 2 : (severity == "medium" ? 4 : 8)};
        int iterationsPerThread = ${severity == "low" ? 20 : (severity == "medium" ? 50 : 200)};
        
        CountDownLatch startLatch = new CountDownLatch(1);
        ExecutorService executor = Executors.newFixedThreadPool(threadCount);
        
        // Launch threads that try to acquire locks in opposite orders
        for (int i = 0; i < threadCount; i++) {
            final boolean startWithA = (i % 2 == 0);
            executor.submit(() -> {
                try {
                    startLatch.await(); // Wait for all threads to be ready
                    int successes = 0;
                    for (int j = 0; j < iterationsPerThread; j++) {
                        if (manager.updateResourcesWithTryLock(startWithA)) {
                            successes++;
                        }
                    }
                    // We should have some successful updates
                    assertTrue(successes > 0, "Some updates should succeed");
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            });
        }
        
        startLatch.countDown(); // Start all threads
        
        boolean terminated = executor.awaitTermination(${severity == "low" ? 3 : (severity == "medium" ? 6 : 10)}, TimeUnit.SECONDS);
        if (!terminated) {
            executor.shutdownNow();
            terminated = executor.awaitTermination(2, TimeUnit.SECONDS);
        }
        
        // Verify both values were updated
        assertTrue(manager.getValueA() > 0, "ValueA should be updated");
        assertTrue(manager.getValueB() > 0, "ValueB should be updated");
    }
    
    @Test
    public void testDeadlockFreeSolution() throws Exception {
        ResourceManager manager = new ResourceManager();
        int threadCount = 10;
        int iterationsPerThread = 100;
        
        CountDownLatch startLatch = new CountDownLatch(1);
        ExecutorService executor = Executors.newFixedThreadPool(threadCount);
        
        // Launch multiple threads using the deadlock-free method
        for (int i = 0; i < threadCount; i++) {
            executor.submit(() -> {
                try {
                    startLatch.await(); // Wait for all threads to be ready
                    for (int j = 0; j < iterationsPerThread; j++) {
                        manager.updateResourcesSafe();
                    }
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            });
        }
        
        startLatch.countDown(); // Start all threads
        
        // This should always complete without deadlock
        boolean completed = executor.awaitTermination(5, TimeUnit.SECONDS);
        assertTrue(completed, "Should complete without deadlock");
        
        // Verify correct updates
        int expectedUpdates = threadCount * iterationsPerThread;
        assertEquals(expectedUpdates, manager.getValueA(), "ValueA should match expected");
        assertEquals(expectedUpdates, manager.getValueB(), "ValueB should match expected");
    }
}
EOF

  # Add deadlock detection VM arguments for Surefire
  # These help detect deadlocks during test execution
  sed -i.bak '/<artifactId>maven-surefire-plugin<\/artifactId>/,/<\/plugin>/ s|<version>.*</version>|<version>2.22.2</version>\n        <configuration>\n          <argLine>-XX:+HeapDumpOnOutOfMemoryError -Xmx512m</argLine>\n          <forkCount>1</forkCount>\n          <reuseForks>false</reuseForks>\n        </configuration>|' "${scenario_dir}/project/pom.xml"
  rm "${scenario_dir}/project/pom.xml.bak"
}

#######################################
# Creates a test scenario for thread ordering issues
# Arguments:
#   $1 - Scenario name
#   $2 - Severity level (low, medium, high)
# Outputs:
#   None
#######################################
function create_thread_ordering_scenario() {
  local scenario_name="$1"
  local severity="$2"
  
  local scenario_dir="${THREAD_SAFETY_DIR}/thread_ordering/${scenario_name}"
  mkdir -p "${scenario_dir}"
  
  # Create base project
  create_base_project "${scenario_dir}/project"
  
  # Create a class with thread ordering issues
  cat > "${scenario_dir}/project/src/main/java/com/example/threadsafety/ConcurrentProcessor.java" << EOF
package com.example.threadsafety;

import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * A processor class with thread ordering dependencies.
 * This class demonstrates issues that arise when thread execution order matters.
 */
public class ConcurrentProcessor {
    private ConcurrentLinkedQueue<String> messageQueue = new ConcurrentLinkedQueue<>();
    private ConcurrentLinkedQueue<Integer> resultQueue = new ConcurrentLinkedQueue<>();
    private AtomicBoolean initialized = new AtomicBoolean(false);
    private AtomicBoolean processingComplete = new AtomicBoolean(false);
    private AtomicInteger processedCount = new AtomicInteger(0);
    private CountDownLatch initLatch = new CountDownLatch(1);
    
    // Initialization method that must be called before processing
    public void initialize() {
        try {
            // Simulate initialization work
            Thread.sleep(${severity == "low" ? 50 : (severity == "medium" ? 150 : 300)});
            initialized.set(true);
            initLatch.countDown();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
    
    // Add messages to the queue for processing
    public void addMessage(String message) {
        if (processingComplete.get()) {
            throw new IllegalStateException("Cannot add messages after processing is complete");
        }
        messageQueue.add(message);
    }
    
    // Process messages without checking initialization
    public void processMessagesUnsafe() {
        if (messageQueue.isEmpty()) {
            return;
        }
        
        // Simulate processing
        try {
            Thread.sleep(${severity == "low" ? 10 : (severity == "medium" ? 30 : 60)});
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        
        // Process all messages
        String message;
        while ((message = messageQueue.poll()) != null) {
            resultQueue.add(message.length());
            processedCount.incrementAndGet();
        }
        
        processingComplete.set(true);
    }
    
    // Process messages with proper initialization checking
    public void processMessagesSafe() throws InterruptedException {
        // Wait for initialization
        initLatch.await();
        
        if (!initialized.get()) {
            throw new IllegalStateException("Processor not initialized");
        }
        
        if (messageQueue.isEmpty()) {
            return;
        }
        
        // Simulate processing
        try {
            Thread.sleep(${severity == "low" ? 10 : (severity == "medium" ? 30 : 60)});
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return;
        }
        
        // Process all messages
        String message;
        while ((message = messageQueue.poll()) != null) {
            resultQueue.add(message.length());
            processedCount.incrementAndGet();
        }
        
        processingComplete.set(true);
    }
    
    public boolean isInitialized() {
        return initialized.get();
    }
    
    public boolean isProcessingComplete() {
        return processingComplete.get();
    }
    
    public int getProcessedCount() {
        return processedCount.get();
    }
    
    public Integer[] getResults() {
        return resultQueue.toArray(new Integer[0]);
    }
    
    public void reset() {
        messageQueue.clear();
        resultQueue.clear();
        initialized.set(false);
        processingComplete.set(false);
        processedCount.set(0);
        initLatch = new CountDownLatch(1);
    }
}
EOF

  # Create test class with thread ordering tests
  cat > "${scenario_dir}/project/src/test/java/com/example/threadsafety/ThreadOrderingTest.java" << EOF
package com.example.threadsafety;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.RepeatedTest;
import static org.junit.jupiter.api.Assertions.*;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

/**
 * Tests that demonstrate thread ordering issues.
 * These tests are intentionally designed to fail intermittently due to thread ordering dependencies.
 */
public class ThreadOrderingTest {
    
    @RepeatedTest(${severity == "low" ? 3 : (severity == "medium" ? 5 : 10)})
    public void testProcessingWithoutInitialization() throws Exception {
        ConcurrentProcessor processor = new ConcurrentProcessor();
        
        // Add some messages
        for (int i = 0; i < 10; i++) {
            processor.addMessage("Message " + i);
        }
        
        // Process without initialization (should fail but sometimes "works" due to timing)
        processor.processMessagesUnsafe();
        
        // In a properly synchronized system, this would always fail
        // But due to timing issues, it might sometimes appear to work
        assertTrue(processor.getProcessedCount() > 0, 
            "Messages should be processed (this test demonstrates a thread ordering issue)");
        
        // Check if processing was marked as complete
        assertTrue(processor.isProcessingComplete(), 
            "Processing should be marked complete (this test demonstrates a thread ordering issue)");
    }
    
    @Test
    public void testConcurrentInitializationAndProcessing() throws Exception {
        ConcurrentProcessor processor = new ConcurrentProcessor();
        ExecutorService executor = Executors.newFixedThreadPool(2);
        
        // Add some messages
        for (int i = 0; i < 20; i++) {
            processor.addMessage("Message " + i);
        }
        
        // Start initialization and processing concurrently
        Future<?> initFuture = executor.submit(() -> processor.initialize());
        
        // Add a small delay to create a race condition
        Thread.sleep(${severity == "low" ? 10 : (severity == "medium" ? 30 : 0)});
        
        Future<?> processFuture = executor.submit(() -> processor.processMessagesUnsafe());
        
        // Wait for both tasks to complete
        initFuture.get(5, TimeUnit.SECONDS);
        processFuture.get(5, TimeUnit.SECONDS);
        
        executor.shutdown();
        executor.awaitTermination(5, TimeUnit.SECONDS);
        
        // Verify results - in a flaky test, these might sometimes pass and sometimes fail
        assertTrue(processor.isInitialized(), "Processor should be initialized");
        assertTrue(processor.isProcessingComplete(), "Processing should be complete");
        assertEquals(20, processor.getProcessedCount(), 
            "All messages should be processed (this test demonstrates a thread ordering issue)");
    }
    
    @Test
    public void testRandomOrderingOfOperations() throws Exception {
        ConcurrentProcessor processor = new ConcurrentProcessor();
        ExecutorService executor = Executors.newFixedThreadPool(${severity == "low" ? 3 : (severity == "medium" ? 5 : 10)});
        Random random = new Random();
        
        List<Future<?>> futures = new ArrayList<>();
        
        // Add a task to initialize the processor
        futures.add(executor.submit(() -> {
            try {
                Thread.sleep(random.nextInt(${severity == "low" ? 50 : (severity == "medium" ? 150 : 300)}));
                processor.initialize();
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }));
        
        // Add tasks to add messages
        for (int i = 0; i < 5; i++) {
            final int messageId = i;
            futures.add(executor.submit(() -> {
                try {
                    Thread.sleep(random.nextInt(${severity == "low" ? 30 : (severity == "medium" ? 80 : 200)}));
                    processor.addMessage("Message " + messageId);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }));
        }
        
        // Add tasks to process messages
        for (int i = 0; i < 3; i++) {
            futures.add(executor.submit(() -> {
                try {
                    Thread.sleep(random.nextInt(${severity == "low" ? 40 : (severity == "medium" ? 100 : 250)}));
                    processor.processMessagesUnsafe();
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }));
        }
        
        // Wait for all tasks to complete
        for (Future<?> future : futures) {
            future.get(5, TimeUnit.SECONDS);
        }
        
        executor.shutdown();
        executor.awaitTermination(5, TimeUnit.SECONDS);
        
        // These assertions demonstrate thread ordering issues
        // They may pass or fail depending on the actual execution order
        assertTrue(processor.isInitialized(), "Processor should be initialized");
        assertTrue(processor.isProcessingComplete(), "Processing should be complete");
        
        // Due to race conditions, we can't be sure how many messages were actually processed
        // This assertion may sometimes pass and sometimes fail
        assertEquals(5, processor.getProcessedCount(), 
            "All messages should be processed (this test demonstrates a thread ordering issue)");
    }
    
    @Test
    public void testThreadOrderingSafeSolution() throws Exception {
        ConcurrentProcessor processor = new ConcurrentProcessor();
        ExecutorService executor = Executors.newFixedThreadPool(5);
        List<Future<?>> futures = new ArrayList<>();
        
        // Add some messages
        for (int i = 0; i < 20; i++) {
            processor.addMessage("Message " + i);
        }
        
        // Start initialization
        futures.add(executor.submit(() -> processor.initialize()));
        
        // Start processing safely (will wait for initialization)
        futures.add(executor.submit(() -> {
            try {
                processor.processMessagesSafe();
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }));
        
        // Wait for all tasks to complete
        for (Future<?> future : futures) {
            future.get(5, TimeUnit.SECONDS);
        }
        
        executor.shutdown();
        executor.awaitTermination(5, TimeUnit.SECONDS);
        
        // These assertions should always pass with the safe implementation
        assertTrue(processor.isInitialized(), "Processor should be initialized");
        assertTrue(processor.isProcessingComplete(), "Processing should be complete");
        assertEquals(20, processor.getProcessedCount(), "All messages should be processed");
    }
}
EOF

  # Configure Surefire to make thread ordering issues more likely
  sed -i.bak '/<artifactId>maven-surefire-plugin<\/artifactId>/,/<\/plugin>/ s|<version>.*</version>|<version>2.22.2</version>\n        <configuration>\n          <parallel>methods</parallel>\n          <threadCount>2</threadCount>\n          <forkCount>1</forkCount>\n          <reuseForks>false</reuseForks>\n        </configuration>|' "${scenario_dir}/project/pom.xml"
  rm "${scenario_dir}/project/pom.xml.bak"
}

#######################################
# Validates MVNimble's thread safety analysis on a scenario
# Arguments:
#   $1 - Scenario directory path
# Outputs:
#   Validation result (PASS/FAIL)
#######################################
function validate_thread_safety_analysis() {
  local scenario_dir="$1"
  local project_dir="${scenario_dir}/project"
  local results_dir="${scenario_dir}/results"
  
  mkdir -p "${results_dir}"
  
  # Run MVNimble analysis on the project
  (cd "${project_dir}" && mvnimble analyze > "${results_dir}/mvnimble_output.log")
  
  # Extract thread safety diagnosis
  grep -A 20 "Thread Safety Analysis" "${results_dir}/mvnimble_output.log" > "${results_dir}/thread_safety_analysis.txt" || true
  
  # Check if thread safety issues were detected
  local detected=false
  if grep -q "Thread safety issues detected" "${results_dir}/thread_safety_analysis.txt"; then
    detected=true
  fi
  
  # Check if recommendations for thread safety were provided
  local recommendations=false
  if grep -q "recommend" "${results_dir}/thread_safety_analysis.txt" && 
     (grep -q "synchroniz" "${results_dir}/thread_safety_analysis.txt" || 
      grep -q "concurrent" "${results_dir}/thread_safety_analysis.txt" || 
      grep -q "atomic" "${results_dir}/thread_safety_analysis.txt" ||
      grep -q "lock" "${results_dir}/thread_safety_analysis.txt"); then
    recommendations=true
  fi
  
  # Determine validation result
  local result="FAIL"
  if $detected && $recommendations; then
    result="PASS"
  fi
  
  # Generate validation report
  generate_validation_report "${scenario_dir}" "${detected}" "${recommendations}" "${result}"
  
  echo "${result}"
}

#######################################
# Generates a validation report for thread safety analysis
# Arguments:
#   $1 - Scenario directory path
#   $2 - Whether issues were detected (true/false)
#   $3 - Whether recommendations were provided (true/false)
#   $4 - Overall result (PASS/FAIL)
# Outputs:
#   None
#######################################
function generate_validation_report() {
  local scenario_dir="$1"
  local detected="$2"
  local recommendations="$3"
  local result="$4"
  
  local category=$(basename "$(dirname "${scenario_dir}")")
  local scenario_name=$(basename "${scenario_dir}")
  
  # Generate report
  local report_file="${REPORT_DIR}/${category}_${scenario_name}_report.md"
  
  cat > "${report_file}" << EOF
# Thread Safety Validation Report

## Scenario Information
- **Category**: ${category}
- **Scenario**: ${scenario_name}
- **Validation Date**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

## Validation Results
- **Issues Detected**: ${detected}
- **Recommendations Provided**: ${recommendations}
- **Overall Result**: ${result}

## Analysis
$(if [ "${result}" = "PASS" ]; then
  echo "MVNimble successfully detected thread safety issues in this scenario and provided appropriate recommendations."
else
  if [ "${detected}" = "true" ]; then
    echo "MVNimble detected thread safety issues but did not provide sufficient recommendations."
  elif [ "${recommendations}" = "true" ]; then
    echo "MVNimble provided recommendations but failed to properly detect the thread safety issues."
  else
    echo "MVNimble failed to detect thread safety issues and did not provide appropriate recommendations."
  fi
fi)

## Recommendations for MVNimble Improvement
$(if [ "${result}" = "PASS" ]; then
  echo "No specific improvements needed for this scenario."
else
  if [ "${detected}" = "false" ]; then
    echo "- Enhance detection algorithms for ${category} issues"
    echo "- Improve log analysis for identifying concurrent execution patterns"
    echo "- Add specific pattern matching for thread-related exceptions"
  fi
  if [ "${recommendations}" = "false" ]; then
    echo "- Develop more specific recommendations for ${category} issues"
    echo "- Include code examples in recommendations"
    echo "- Provide links to best practices for thread safety"
  fi
fi)

## Raw Analysis Output
\`\`\`
$(cat "${scenario_dir}/results/thread_safety_analysis.txt")
\`\`\`
EOF
}

#######################################
# Creates all thread safety test scenarios
# Arguments:
#   None
# Outputs:
#   None
#######################################
function create_all_scenarios() {
  # Set up environment
  setup_thread_safety_environment
  
  # Create race condition scenarios
  create_race_condition_scenario "simple_counter" "low"
  create_race_condition_scenario "array_updates" "medium"
  create_race_condition_scenario "complex_race" "high"
  
  # Create deadlock scenarios
  create_deadlock_scenario "basic_deadlock" "low"
  create_deadlock_scenario "trylock_deadlock" "medium"
  create_deadlock_scenario "complex_deadlock" "high"
  
  # Create thread ordering scenarios
  create_thread_ordering_scenario "initialization_race" "low"
  create_thread_ordering_scenario "message_processing" "medium"
  create_thread_ordering_scenario "random_ordering" "high"
}

#######################################
# Runs validation on all thread safety scenarios
# Arguments:
#   None
# Outputs:
#   Summary of validation results
#######################################
function run_validation() {
  local total_scenarios=0
  local passed_scenarios=0
  
  echo "Running Thread Safety Analysis Validation..."
  
  # Track start time
  local start_time=$(date +%s)
  
  # Process each category of scenarios
  for category in race_conditions deadlocks thread_ordering; do
    echo "Processing ${category} scenarios..."
    
    if [ -d "${THREAD_SAFETY_DIR}/${category}" ]; then
      for scenario in "${THREAD_SAFETY_DIR}/${category}"/*; do
        if [ -d "${scenario}" ]; then
          echo "  Validating scenario: $(basename "${scenario}")..."
          local result=$(validate_thread_safety_analysis "${scenario}")
          total_scenarios=$((total_scenarios + 1))
          
          if [ "${result}" = "PASS" ]; then
            passed_scenarios=$((passed_scenarios + 1))
            echo "    PASS"
          else
            echo "    FAIL"
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
  local passing_percentage=0
  if [ ${total_scenarios} -gt 0 ]; then
    passing_percentage=$(echo "scale=2; (${passed_scenarios} / ${total_scenarios}) * 100" | bc)
  fi
  
  echo "Thread Safety Validation Summary"
  echo "================================"
  echo "Total Scenarios: ${total_scenarios}"
  echo "Passing Scenarios: ${passed_scenarios}"
  echo "Passing Percentage: ${passing_percentage}%"
  echo "Validation Duration: ${duration} seconds"
  
  # Generate detailed summary report file
  cat > "${REPORT_DIR}/summary_report.md" << EOF
# Thread Safety Validation Summary Report

## Overview
- **Date**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
- **Total Scenarios**: ${total_scenarios}
- **Passing Scenarios**: ${passed_scenarios}
- **Passing Percentage**: ${passing_percentage}%
- **Validation Duration**: ${duration} seconds

## Results by Category
$(for category in race_conditions deadlocks thread_ordering; do
  if [ -d "${THREAD_SAFETY_DIR}/${category}" ]; then
    local cat_total=0
    local cat_passed=0
    for scenario in "${THREAD_SAFETY_DIR}/${category}"/*; do
      if [ -d "${scenario}" ] && [ -f "${REPORT_DIR}/${category}_$(basename "${scenario}")_report.md" ]; then
        cat_total=$((cat_total + 1))
        if grep -q "Overall Result: PASS" "${REPORT_DIR}/${category}_$(basename "${scenario}")_report.md"; then
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

## Analysis and Recommendations
$(if (( $(echo "${passing_percentage} >= 80" | bc -l) )); then
  echo "MVNimble's thread safety analysis is performing well, correctly identifying and providing recommendations for most thread safety issues."
elif (( $(echo "${passing_percentage} >= 50" | bc -l) )); then
  echo "MVNimble's thread safety analysis is moderately effective but could be improved in several areas."
else
  echo "MVNimble's thread safety analysis needs significant improvement to effectively detect and provide recommendations for thread safety issues."
fi)

### Strengths and Weaknesses
$(for category in race_conditions deadlocks thread_ordering; do
  if [ -d "${THREAD_SAFETY_DIR}/${category}" ]; then
    local cat_total=0
    local cat_passed=0
    for scenario in "${THREAD_SAFETY_DIR}/${category}"/*; do
      if [ -d "${scenario}" ] && [ -f "${REPORT_DIR}/${category}_$(basename "${scenario}")_report.md" ]; then
        cat_total=$((cat_total + 1))
        if grep -q "Overall Result: PASS" "${REPORT_DIR}/${category}_$(basename "${scenario}")_report.md"; then
          cat_passed=$((cat_passed + 1))
        fi
      fi
    done
    
    if [ ${cat_total} -gt 0 ]; then
      local cat_percentage=$(echo "scale=2; (${cat_passed} / ${cat_total}) * 100" | bc)
      echo "#### ${category}"
      if (( $(echo "${cat_percentage} >= 80" | bc -l) )); then
        echo "**Strength**: MVNimble effectively handles ${category} with a ${cat_percentage}% success rate."
      elif (( $(echo "${cat_percentage} >= 50" | bc -l) )); then
        echo "**Moderate**: MVNimble has moderate effectiveness with ${category} (${cat_percentage}% success rate)."
      else
        echo "**Weakness**: MVNimble struggles with ${category}, achieving only a ${cat_percentage}% success rate."
      fi
      echo ""
    fi
  fi
done)

### Improvement Recommendations
$(
  low_category=""
  low_percentage=100
  
  for category in race_conditions deadlocks thread_ordering; do
    if [ -d "${THREAD_SAFETY_DIR}/${category}" ]; then
      local cat_total=0
      local cat_passed=0
      for scenario in "${THREAD_SAFETY_DIR}/${category}"/*; do
        if [ -d "${scenario}" ] && [ -f "${REPORT_DIR}/${category}_$(basename "${scenario}")_report.md" ]; then
          cat_total=$((cat_total + 1))
          if grep -q "Overall Result: PASS" "${REPORT_DIR}/${category}_$(basename "${scenario}")_report.md"; then
            cat_passed=$((cat_passed + 1))
          fi
        fi
      done
      
      if [ ${cat_total} -gt 0 ]; then
        local cat_percentage=$(echo "scale=2; (${cat_passed} / ${cat_total}) * 100" | bc)
        if (( $(echo "${cat_percentage} < ${low_percentage}" | bc -l) )); then
          low_category="${category}"
          low_percentage="${cat_percentage}"
        fi
      fi
    fi
  done
  
  if [ ! -z "${low_category}" ]; then
    echo "1. **Focus on ${low_category}**: With the lowest success rate (${low_percentage}%), this area needs the most attention."
    
    if [ "${low_category}" = "race_conditions" ]; then
      echo "   - Enhance detection of non-atomic operations on shared variables"
      echo "   - Improve analysis of test failures caused by data races"
      echo "   - Add pattern recognition for common race condition symptoms"
    elif [ "${low_category}" = "deadlocks" ]; then
      echo "   - Implement deadlock detection algorithms in the analysis phase"
      echo "   - Add timeout pattern recognition to identify potential deadlocks"
      echo "   - Enhance lock acquisition order analysis"
    elif [ "${low_category}" = "thread_ordering" ]; then
      echo "   - Improve detection of thread execution order dependencies"
      echo "   - Enhance recognition of initialization race patterns"
      echo "   - Add analysis for wait/notify usage patterns"
    fi
  fi
  
  echo ""
  echo "2. **General Thread Safety Improvements**:"
  echo "   - Enhance thread contention detection in resource monitoring"
  echo "   - Improve recommendations for using thread-safe collections"
  echo "   - Add detection of atomic variable usage patterns"
  echo "   - Enhance lock contention analysis"
  echo ""
  echo "3. **Documentation and Reporting**:"
  echo "   - Provide more specific recommendations with code examples"
  echo "   - Include links to thread safety best practices in reports"
  echo "   - Add visualization of thread interactions when issues are detected"
)

## Detailed Results
$(for category in race_conditions deadlocks thread_ordering; do
  echo "### ${category}"
  echo ""
  echo "| Scenario | Issues Detected | Recommendations | Result |"
  echo "|----------|----------------|-----------------|--------|"
  
  if [ -d "${THREAD_SAFETY_DIR}/${category}" ]; then
    for scenario in "${THREAD_SAFETY_DIR}/${category}"/*; do
      if [ -d "${scenario}" ] && [ -f "${REPORT_DIR}/${category}_$(basename "${scenario}")_report.md" ]; then
        local name=$(basename "${scenario}")
        local detected="No"
        local recommendations="No"
        local result="FAIL"
        
        if grep -q "Issues Detected: true" "${REPORT_DIR}/${category}_${name}_report.md"; then
          detected="Yes"
        fi
        
        if grep -q "Recommendations Provided: true" "${REPORT_DIR}/${category}_${name}_report.md"; then
          recommendations="Yes"
        fi
        
        if grep -q "Overall Result: PASS" "${REPORT_DIR}/${category}_${name}_report.md"; then
          result="PASS"
        fi
        
        echo "| ${name} | ${detected} | ${recommendations} | ${result} |"
      fi
    done
  else
    echo "No scenarios found for this category."
  fi
  echo ""
done)
EOF

  echo "Summary report generated: ${REPORT_DIR}/summary_report.md"
  
  # Return the passing percentage as an indicator of overall success
  echo "${passing_percentage}"
}

# Main function
function main() {
  # Create thread safety test scenarios
  create_all_scenarios
  
  # Run validation
  run_validation
}

# Allow sourcing without executing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi