#!/usr/bin/env bash
#
# MVNimble Diagnostic Patterns Guide
#
# This file provides a structured approach to interpreting MVNimble diagnostics
# following the "1-2-3" framework:
#   1 identifying signature to recognize the issue
#   2 options to explore
#   3 steps to validate your hypothesis
#
# Usage: Source this file and then use the diagnostic_patterns function to get
# guidance for a specific test failure pattern.

# Load all problem simulators
source "${BATS_TEST_DIRNAME:-$(dirname "$0")/..}/test_helper.bash"
source "${BATS_TEST_DIRNAME:-$(dirname "$0")}/resource_constraints.bash"
source "${BATS_TEST_DIRNAME:-$(dirname "$0")}/thread_safety_issues.bash"
source "${BATS_TEST_DIRNAME:-$(dirname "$0")}/network_io_bottlenecks.bash"
source "${BATS_TEST_DIRNAME:-$(dirname "$0")}/pairwise_test_matrix.bash"

# ------------------------------------------------------------------------------
# DIAGNOSTIC PATTERN LIBRARY
# ------------------------------------------------------------------------------

# Define patterns and diagnostic approaches
declare -A DIAGNOSTIC_PATTERNS
DIAGNOSTIC_PATTERNS=(
  ["cpu_bound"]="# CPU-Bound Test Pattern
## 1️⃣ The ONE Signature
- **Test execution time increases linearly with CPU load**
- Log shows execution times varying by >40% between runs with same code
- Test failures occur predominantly during high system load periods

## 2️⃣ TWO Options to Explore
- **Thread Count Adjustments**: Test different thread count configurations to find optimal balance
  ```bash
  for threads in 1 2 4 8; do
    echo \"Testing with $threads threads\"
    time mvn test -DforkCount=$threads -Dtest=YourTest
  done
  ```
- **Algorithmic Complexity**: Examine computationally expensive operations that might be causing bottlenecks
  ```bash
  # Generate CPU profile during test execution
  java -XX:+UnlockDiagnosticVMOptions -XX:+DebugNonSafepoints \\
      -XX:+FlightRecorder -XX:StartFlightRecording=settings=profile,duration=60s,filename=cpu-profile.jfr \\
      -jar your-test-application.jar
  ```

## 3️⃣ THREE Steps to Validate
1. **Simulate varying CPU constraints** using MVNimble:
   ```bash
   # Run test with different CPU constraints
   source ./resource_constraints.bash
   for load in 0 30 60 90; do
     echo \"Testing with ${load}% CPU load\"
     simulate_high_cpu_load $load
     time mvn test -Dtest=YourTest
   done
   ```

2. **Plot execution time against CPU load** to confirm linear relationship:
   ```bash
   # Create simple visualization of the data 
   # (requires gnuplot)
   echo \"set terminal png; set output 'cpu-test.png'; \\
         set title 'Test Time vs CPU Load'; \\
         set xlabel 'CPU Load (%)'; \\
         set ylabel 'Execution Time (s)'; \\
         plot '-' with linespoints\" > plot.gnuplot
   # Add your data points here
   echo \"0 10.5\" >> plot.gnuplot  # Example: 0% load = 10.5s
   echo \"30 12.2\" >> plot.gnuplot  # Example: 30% load = 12.2s
   echo \"60 18.7\" >> plot.gnuplot  # Example: 60% load = 18.7s
   echo \"90 32.1\" >> plot.gnuplot  # Example: 90% load = 32.1s
   echo \"e\" >> plot.gnuplot
   gnuplot plot.gnuplot
   ```

3. **Validate thread count hypothesis** by iteratively testing different counts:
   ```bash
   # First, determine available CPU cores
   available_cores=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
   
   # Test with increasing thread counts until performance degrades
   optimal_threads=1
   best_time=999999
   
   for threads in $(seq 1 $((available_cores * 2))); do
     echo \"Testing with $threads threads\"
     time=$(mvn test -DforkCount=$threads -Dtest=YourTest | grep \"Time elapsed\" | cut -d\" \" -f6)
     echo \"Time: ${time}s\"
     
     if (( $(echo \"$time < $best_time\" | bc -l) )); then
       best_time=$time
       optimal_threads=$threads
     fi
   done
   
   echo \"Optimal thread count: $optimal_threads with time $best_time seconds\"
   ```"

  ["memory_constraint"]="# Memory-Constrained Test Pattern
## 1️⃣ The ONE Signature
- **OutOfMemoryError or GC overhead limit exceeded** errors in logs
- Test execution time increases dramatically as memory pressure increases
- Heap dump reveals large collections or caches being created during test

## 2️⃣ TWO Options to Explore
- **Memory Limit Adjustments**: Test with different heap size configurations
  ```bash
  # Test with different heap sizes
  for heap in 512m 1g 2g 4g; do
    echo \"Testing with heap size $heap\"
    time mvn test -DargLine=\"-Xmx$heap\" -Dtest=YourTest
  done
  ```
- **Memory Leak Investigation**: Check if resources aren't being released properly
  ```bash
  # Run tests with memory tracking enabled
  export MAVEN_OPTS=\"-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/tmp\"
  mvn test -Dtest=YourTest
  ```

## 3️⃣ THREE Steps to Validate
1. **Simulate varying memory constraints** using MVNimble:
   ```bash
   # Run test with different memory constraints
   source ./resource_constraints.bash
   for pressure in 0 40 70 90; do
     echo \"Testing with ${pressure}% memory pressure\"
     simulate_memory_pressure $pressure
     time mvn test -Dtest=YourTest
   done
   ```

2. **Profile memory usage patterns** throughout test execution:
   ```bash
   # Use Java Flight Recorder to track memory usage
   java -XX:+UnlockDiagnosticVMOptions -XX:+FlightRecorder \\
        -XX:StartFlightRecording=settings=profile,duration=120s,filename=memory-profile.jfr \\
        -jar your-test-application.jar
   
   # Analyze the JFR recording with JDK Mission Control
   jmc -open memory-profile.jfr
   ```

3. **Identify memory growth patterns** to distinguish leaks from legitimate usage:
   ```bash
   # Run test with GC logging enabled
   export MAVEN_OPTS=\"-verbose:gc -XX:+PrintGCDetails\"
   mvn test -Dtest=YourTest > gc-log.txt
   
   # Analyze GC log patterns for signs of memory leaks
   grep -A 10 \"Full GC\" gc-log.txt | grep -E \"(before|after)\"
   
   # Check if memory usage returns to baseline after test
   for i in {1..5}; do
     mvn test -Dtest=YourTest
     # If memory doesn't return to baseline, likely a leak
   done
   ```"

  ["network_latency"]="# Network Latency/Connectivity Pattern
## 1️⃣ The ONE Signature
- **Timeout exceptions and incomplete operations** in logs
- Inconsistent failures without code changes between runs
- Test success rate correlates with network quality metrics
- Error logs contain terms like 'timeout', 'connection reset', or 'host unreachable'

## 2️⃣ TWO Options to Explore
- **Timeout Configuration**: Adjust timeouts in test configuration
  ```bash
  # Test with different timeout values
  for timeout in 5 15 30 60; do
    echo \"Testing with ${timeout}s timeout\"
    mvn test -Dtest=YourTest -Dhttp.connection.timeout=$timeout
  done
  ```
- **Network Resilience Implementation**: Add retry logic and connection pooling
  ```bash
  # Check if connection pooling is configured
  grep -r \"ConnectionPooling\" --include=\"*.java\" .
  
  # Look for retry logic implementation
  grep -r \"retry\" --include=\"*.java\" .
  ```

## 3️⃣ THREE Steps to Validate
1. **Simulate varying network conditions** using MVNimble:
   ```bash
   # Run tests with different network latency values
   source ./network_io_bottlenecks.bash
   for latency in 0 50 200 500; do
     echo \"Testing with ${latency}ms network latency\"
     simulate_network_latency \"your-service-host.com\" $latency
     mvn test -Dtest=YourTest
   done
   ```

2. **Monitor network traffic** during test execution:
   ```bash
   # Capture network traffic during test
   sudo tcpdump -i any -w test-traffic.pcap host your-service-host.com &
   mvn test -Dtest=YourTest
   sudo kill $!
   
   # Analyze captured traffic
   wireshark test-traffic.pcap
   # Look for slow response times, retransmissions, or connection resets
   ```

3. **Test with connection mocking** to isolate network effects:
   ```bash
   # Run tests with mocked connections instead of real network
   # First, look for mocking configuration
   grep -r \"mock.*connection\" --include=\"*.java\" --include=\"*.xml\" .
   
   # Enable mocking in tests if available
   mvn test -Dtest=YourTest -Dmock.connections=true
   
   # Compare results with real network tests
   # If tests pass with mocks but fail with real network,
   # network conditions are likely the cause
   ```"

  ["thread_safety"]="# Thread Safety Issue Pattern
## 1️⃣ The ONE Signature
- **Test passes in isolation but fails in parallel runs**
- Observed exceptions include ConcurrentModificationException, NullPointerException in unexpected places
- Test success varies based on thread count even with same code
- Tests affecting each other when no direct relationship exists

## 2️⃣ TWO Options to Explore
- **Isolation Level**: Adjust test isolation configuration
  ```bash
  # Test with different isolation levels
  mvn test -Dtest=YourTest -DforkCount=1 -DreuseForks=false
  # vs.
  mvn test -Dtest=YourTest -DforkCount=0 -DreuseForks=true
  # vs.
  mvn test -Dtest=YourTest -DforkCount=1C -DreuseForks=true
  ```
- **Shared Resource Management**: Identify and fix shared state between tests
  ```bash
  # Look for static fields that might be shared
  grep -r \"static\" --include=\"*.java\" . | grep -v \"final\" | grep -E \"(List|Map|Set)\"
  
  # Check for thread-local usage
  grep -r \"ThreadLocal\" --include=\"*.java\" .
  ```

## 3️⃣ THREE Steps to Validate
1. **Run tests in different execution orders** to identify dependencies:
   ```bash
   # Run tests in reverse alphabetical order
   mvn test -Dtest=YourTest -Dsurefire.runOrder=reversealphabetical
   
   # Run tests in random order
   mvn test -Dtest=YourTest -Dsurefire.runOrder=random
   
   # Run tests with fixed random seed for reproducibility
   mvn test -Dtest=YourTest -Dsurefire.runOrder=random -Dsurefire.random.seed=1234
   ```

2. **Simulate thread safety issues** with MVNimble:
   ```bash
   # Introduce race conditions
   source ./thread_safety_issues.bash
   simulate_race_condition
   mvn test -Dtest=YourTest
   
   # Test with different thread interleaving patterns
   for i in {1..10}; do
     simulate_race_condition $i
     mvn test -Dtest=YourTest
   done
   ```

3. **Isolate problematic test combinations**:
   ```bash
   # Run tests individually and record results
   test_classes=$(find src/test -name \"*Test.java\" | xargs basename -s .java)
   for test in $test_classes; do
     echo \"Testing $test in isolation\"
     mvn test -Dtest=$test
   done
   
   # Then run tests in pairs to find conflicting combinations
   for test1 in $test_classes; do
     for test2 in $test_classes; do
       if [[ \"$test1\" != \"$test2\" ]]; then
         echo \"Testing $test1 with $test2\"
         mvn test -Dtest=$test1,$test2
       fi
     done
   done
   ```"

  ["resource_exhaustion"]="# Resource Exhaustion Pattern
## 1️⃣ The ONE Signature
- **Resource limit errors** like 'too many open files', 'connection limit exceeded'
- Test failure rate increases as test suite grows larger
- Resources not released properly between test runs
- System monitoring shows resource depletion during test execution

## 2️⃣ TWO Options to Explore
- **Resource Cleanup**: Ensure resources are properly closed after use
  ```bash
  # Look for resource cleanup patterns
  grep -r \"close()\" --include=\"*.java\" .
  grep -r \"try.*finally\" --include=\"*.java\" .
  grep -r \"try-with-resources\" --include=\"*.java\" .
  ```
- **Resource Limiting**: Set appropriate limits for resource consumption
  ```bash
  # Test with different connection pool sizes
  for poolSize in 10 20 50 100; do
    echo \"Testing with connection pool size $poolSize\"
    mvn test -Dtest=YourTest -Dconnection.pool.size=$poolSize
  done
  ```

## 3️⃣ THREE Steps to Validate
1. **Monitor system resources** during test execution:
   ```bash
   # Track file handles during test
   lsof -p $(pgrep -f \"yourtest\") > handles-before.txt
   mvn test -Dtest=YourTest
   lsof -p $(pgrep -f \"yourtest\") > handles-after.txt
   
   # Compare before and after
   diff handles-before.txt handles-after.txt
   ```

2. **Simulate resource constraints** with MVNimble:
   ```bash
   # Test with file descriptor limits
   source ./resource_constraints.bash
   mock_limited_file_descriptors 100
   mvn test -Dtest=YourTest
   
   # Test with connection limits
   mock_limited_network_connections 20
   mvn test -Dtest=YourTest
   ```

3. **Analyze resource usage patterns** over time:
   ```bash
   # Run extended test cycles to detect resource leaks
   for i in {1..20}; do
     echo \"Test iteration $i\"
     # Check resource count before test
     open_files_before=$(lsof -p $$ | wc -l)
     
     # Run test
     mvn test -Dtest=YourTest
     
     # Check resource count after test
     open_files_after=$(lsof -p $$ | wc -l)
     
     echo \"Open files delta: $((open_files_after - open_files_before))\"
     # If delta keeps growing, you have a resource leak
   done
   ```"

  ["flaky_assertion"]="# Flaky Assertion Pattern
## 1️⃣ The ONE Signature
- **Assertion failures with very small differences** from expected values
- Test results vary when run on different hardware or environments
- Floating-point comparisons failing inconsistently
- Tests that rely on precise formatting or string representation

## 2️⃣ TWO Options to Explore
- **Tolerance Adjustment**: Introduce appropriate tolerances in assertions
  ```bash
  # Look for exact equality assertions that could be replaced with delta assertions
  grep -r \"assertEquals\" --include=\"*.java\" . | grep -v \"delta\"
  
  # Check for strict time/date assertions
  grep -r \"assertEquals\" --include=\"*.java\" . | grep -E \"(Date|Time|timestamp)\"
  ```
- **Intent Refocusing**: Refocus assertions on business requirements rather than implementation details
  ```bash
  # Identify overly specific assertions
  grep -r \"assertArrayEquals\" --include=\"*.java\" .
  grep -r \"assertEquals.*toString\" --include=\"*.java\" .
  ```

## 3️⃣ THREE Steps to Validate
1. **Run tests across different environments** to identify variations:
   ```bash
   # Run tests on different JDK versions
   for jdk in 8 11 17; do
     echo \"Testing with JDK $jdk\"
     # Use appropriate JDK version
     export JAVA_HOME=/path/to/jdk$jdk
     mvn test -Dtest=YourTest
   done
   
   # Run tests with different locales
   for locale in en_US fr_FR ja_JP; do
     echo \"Testing with locale $locale\"
     mvn test -Dtest=YourTest -Duser.language=${locale%_*} -Duser.country=${locale#*_}
   done
   ```

2. **Test with progressively wider tolerance margins**:
   ```bash
   # Modify assertion delta values
   for delta in 0.0001 0.001 0.01 0.1; do
     echo \"Testing with delta $delta\"
     # You may need to modify the test code or use system properties
     mvn test -Dtest=YourTest -Dassertion.delta=$delta
   done
   ```

3. **Analyze assertion failure patterns** for clues:
   ```bash
   # Run the test multiple times and collect actual/expected values
   for i in {1..20}; do
     echo \"Test iteration $i\"
     mvn test -Dtest=YourTest > test-$i.log 2>&1
     # Extract assertion failures
     grep -A 3 \"AssertionError\" test-$i.log >> assertion-failures.txt
   done
   
   # Analyze the patterns in the failures
   # Look for trends in differences - are they all off by similar amounts?
   # Are failures more common on certain platforms?
   ```"

  ["timing_sensitivity"]="# Timing Sensitivity Pattern
## 1️⃣ The ONE Signature
- **Test failures that depend on execution speed**
- Contains explicit sleep() or wait() calls with fixed durations
- Failures increase under system load or on slower hardware
- Error messages contain terms like 'timeout', 'wait condition not satisfied'

## 2️⃣ TWO Options to Explore
- **Explicit Wait Conditions**: Replace sleep() with explicit wait for conditions
  ```bash
  # Look for sleep() calls in tests
  grep -r \"Thread.sleep\" --include=\"*.java\" src/test
  
  # Look for timing-based assertions
  grep -r \"assert.*After\" --include=\"*.java\" .
  ```
- **Asynchronous Test Patterns**: Use async testing frameworks or patterns
  ```bash
  # Check for async testing support
  grep -r \"CompletableFuture\" --include=\"*.java\" src/test
  grep -r \"CountDownLatch\" --include=\"*.java\" src/test
  ```

## 3️⃣ THREE Steps to Validate
1. **Vary system load during test execution**:
   ```bash
   # Run tests under different CPU loads
   source ./resource_constraints.bash
   for load in 0 30 60 90; do
     echo \"Testing with ${load}% CPU load\"
     simulate_high_cpu_load $load
     mvn test -Dtest=YourTest
   done
   ```

2. **Modify wait timeouts systematically**:
   ```bash
   # If the test allows configuration of timeouts via properties
   for timeout in 1 5 10 30 60; do
     echo \"Testing with ${timeout}s timeout\"
     mvn test -Dtest=YourTest -Dtest.timeout=$timeout
   done
   ```

3. **Instrument code to log actual operation times**:
   ```bash
   # Add timing instrumentation if possible
   # Or use Java Flight Recorder for timing analysis
   java -XX:+UnlockDiagnosticVMOptions -XX:+FlightRecorder \\
        -XX:StartFlightRecording=settings=profile,duration=60s,filename=timing-profile.jfr \\
        -jar your-test-application.jar
   
   # Analyze recorded timings to determine appropriate wait times
   # Look for operations that take longer than the configured timeouts
   # Identify the full range (min/max/avg) of timing for critical operations
   ```"

  ["external_dependency"]="# External Dependency Pattern
## 1️⃣ The ONE Signature
- **Test failures correlate with third-party service availability**
- Error logs reference external hosts, APIs, or services
- Test passes with mocks but fails with real dependencies
- Failures cluster around specific times of day or network conditions

## 2️⃣ TWO Options to Explore
- **Enhanced Mocking Strategy**: Improve test isolation from external dependencies
  ```bash
  # Check for mocking frameworks in use
  grep -r \"mock\" --include=\"pom.xml\" .
  grep -r \"@Mock\" --include=\"*.java\" .
  
  # Look for test configurations that might control mocking
  grep -r \"mock.*enabled\" --include=\"*.properties\" --include=\"*.xml\" .
  ```
- **Resilience Implementation**: Add retry logic and circuit breakers
  ```bash
  # Look for retry logic implementations
  grep -r \"retry\" --include=\"*.java\" .
  
  # Look for circuit breaker implementations
  grep -r \"circuit.*breaker\" --include=\"*.java\" .
  ```

## 3️⃣ THREE Steps to Validate
1. **Run tests with dependency proxying** to observe behavior:
   ```bash
   # Set up monitoring proxy for dependencies
   java -jar wiremock.jar --port 8080 --proxy-all=\"https://real-service.com\" --record-mappings
   
   # Run tests through the proxy
   mvn test -Dtest=YourTest -Dexternal.service.url=http://localhost:8080
   
   # Analyze recorded traffic
   # Look at timing, error patterns, request frequency
   ```

2. **Simulate various dependency behaviors** with MVNimble:
   ```bash
   # Simulate various network conditions to dependencies
   source ./network_io_bottlenecks.bash
   
   # Test with latency
   simulate_network_latency \"real-service.com\" 200
   mvn test -Dtest=YourTest
   
   # Test with connection failures
   simulate_connection_issues \"real-service.com\" \"timeout\" 50
   mvn test -Dtest=YourTest
   
   # Test with service unavailability
   simulate_dns_issues \"real-service.com\" \"failure\"
   mvn test -Dtest=YourTest
   ```

3. **Compare real vs. mocked dependency behavior**:
   ```bash
   # Run tests with mocked dependencies
   mvn test -Dtest=YourTest -Dmock.external.dependencies=true
   
   # Run tests with real dependencies
   mvn test -Dtest=YourTest -Dmock.external.dependencies=false
   
   # Compare results
   # If tests pass with mocks but fail with real dependencies,
   # the issue is likely in the integration with the external service
   ```"

  ["environment_dependency"]="# Environment Dependency Pattern
## 1️⃣ The ONE Signature
- **Tests pass locally but fail in CI or other environments**
- Failures related to file paths, environment variables, or configuration
- Tests sensitive to machine-specific settings
- Logs show different behaviors across environments with same code

## 2️⃣ TWO Options to Explore
- **Environment Isolation**: Containerize tests to ensure consistent environment
  ```bash
  # Look for Docker/container configuration
  find . -name \"Dockerfile\" -o -name \"docker-compose.yml\"
  
  # Check for environment initialization scripts
  find . -name \"setup*.sh\" -o -name \"init*.sh\"
  ```
- **Configuration Externalization**: Make environment dependencies explicit and configurable
  ```bash
  # Look for property loading patterns
  grep -r \"System.getProperty\" --include=\"*.java\" .
  grep -r \"getenv\" --include=\"*.java\" .
  ```

## 3️⃣ THREE Steps to Validate
1. **Run tests with environment variable diffing**:
   ```bash
   # On machine where tests pass, capture environment
   env > working-env.txt
   
   # On machine where tests fail, capture environment
   env > failing-env.txt
   
   # Compare environments
   diff working-env.txt failing-env.txt
   
   # Test with explicitly set environment variables
   # based on differences found
   ```

2. **Create a minimal reproducible environment**:
   ```bash
   # Create clean environment (e.g., Docker container)
   docker run -it --rm openjdk:11 bash
   
   # Clone repo and run tests
   git clone your-repo.git
   cd your-repo
   mvn test -Dtest=YourTest
   
   # Add environment variables one by one until test behavior changes
   # This identifies the critical environmental dependency
   ```

3. **Test with configuration parameter sweeping**:
   ```bash
   # Identify configuration parameters
   config_params=$(grep -r \"getProperty\" --include=\"*.java\" . | grep -o \"[\\\"'][^\\\"']*[\\\"']\" | sort | uniq)
   
   # For each parameter, test with different values
   for param in $config_params; do
     # Remove quotes
     param=$(echo $param | tr -d \"\\\"'\")
     
     echo \"Testing configuration parameter: $param\"
     # Try with explicit value
     mvn test -Dtest=YourTest -D$param=value1
     
     # Try with different value
     mvn test -Dtest=YourTest -D$param=value2
     
     # Try with parameter unset
     mvn test -Dtest=YourTest
   done
   ```"
)

# ------------------------------------------------------------------------------
# INTERACTIVE DIAGNOSTIC GUIDE
# ------------------------------------------------------------------------------

# Display the diagnostic guide for a specific pattern
show_diagnostic_guide() {
  local pattern="$1"
  
  if [[ -n "${DIAGNOSTIC_PATTERNS[$pattern]}" ]]; then
    echo "${DIAGNOSTIC_PATTERNS[$pattern]}"
  else
    echo "Unknown pattern: $pattern"
    echo "Available patterns:"
    for p in "${!DIAGNOSTIC_PATTERNS[@]}"; do
      echo "  $p"
    done
  fi
}

# List all available diagnostic patterns
list_diagnostic_patterns() {
  echo "Available MVNimble Diagnostic Patterns:"
  echo
  
  for pattern in "${!DIAGNOSTIC_PATTERNS[@]}"; do
    # Extract the first line (title) from the pattern
    local title=$(echo "${DIAGNOSTIC_PATTERNS[$pattern]}" | head -n 1)
    # Remove the leading "# " from the title
    title="${title:2}"
    echo "- $pattern: $title"
  done
}

# Try to identify most likely patterns based on log file
identify_patterns_from_log() {
  local log_file="$1"
  
  echo "Analyzing log file: $log_file"
  echo
  echo "Detected patterns (most likely first):"
  
  # Check for CPU-bound patterns
  if grep -q -E "(Time elapsed: [0-9]+\.[0-9]+ s|CPU: [89][0-9]%|Execution time exceeded)" "$log_file"; then
    echo "- cpu_bound: Test execution shows CPU sensitivity"
  fi
  
  # Check for memory constraint patterns
  if grep -q -E "(OutOfMemoryError|GC overhead limit exceeded|java.lang.OutOfMemoryError)" "$log_file"; then
    echo "- memory_constraint: Test shows memory pressure sensitivity"
  fi
  
  # Check for network latency patterns
  if grep -q -E "(ConnectException: Connection timed out|UnknownHostException|SocketTimeoutException)" "$log_file"; then
    echo "- network_latency: Test shows network connectivity sensitivity"
  fi
  
  # Check for thread safety patterns
  if grep -q -E "(ConcurrentModificationException|Deadlock found|race condition|thread|concurrent)" "$log_file"; then
    echo "- thread_safety: Test shows concurrency sensitivity"
  fi
  
  # Check for resource exhaustion patterns
  if grep -q -E "(Too many open files|Connection limit exceeded|Connection pool|Resource pool)" "$log_file"; then
    echo "- resource_exhaustion: Test shows resource limitation sensitivity"
  fi
  
  # Check for flaky assertion patterns
  if grep -q -E "(AssertionError|expected:.*but was:|junit.framework.Assert)" "$log_file"; then
    echo "- flaky_assertion: Test shows assertion sensitivity"
  fi
  
  # Check for timing sensitivity patterns
  if grep -q -E "(Thread.sleep|timeout|wait condition not satisfied|Timed out)" "$log_file"; then
    echo "- timing_sensitivity: Test shows timing sensitivity"
  fi
  
  # Check for external dependency patterns
  if grep -q -E "(http://|https://|service unavailable|API|endpoint)" "$log_file"; then
    echo "- external_dependency: Test shows external service dependency"
  fi
  
  # Check for environment dependency patterns
  if grep -q -E "(environment variable|configuration|property|System.getProperty|getenv)" "$log_file"; then
    echo "- environment_dependency: Test shows environment configuration sensitivity"
  fi
}

# Generate a diagnostic plan based on pairwise test results
generate_diagnostic_plan() {
  local results_file="$1"
  local output_file="${2:-diagnostic_plan.md}"
  
  echo "Generating diagnostic plan from pairwise test results: $results_file"
  
  # Extract failing test patterns
  echo "Extracting failure patterns..."
  
  # Create the diagnostic plan
  {
    echo "# MVNimble Diagnostic Plan"
    echo
    echo "Generated: $(date +'%Y-%m-%d %H:%M:%S')"
    echo
    echo "This diagnostic plan provides structured guidance for investigating test failures based on the patterns observed in pairwise testing."
    echo
    
    echo "## Observed Failure Patterns"
    echo
    
    # Find failed test configurations
    grep -v ",0," "$results_file" | while IFS=, read -r id cpu memory disk network thread io repo temp status duration notes; do
      # Skip header line
      if [[ "$id" == "TestID" ]]; then
        continue
      fi
      
      echo "### Test Case $id: Status $status (${duration}s)"
      echo
      echo "Configuration:"
      echo "- CPU: $cpu"
      echo "- Memory: $memory"
      echo "- Disk: $disk"
      echo "- Network: $network"
      echo "- Thread: $thread"
      echo "- I/O: $io"
      echo "- Repository: $repo"
      echo "- Temporary: $temp"
      echo
      
      # Determine most likely pattern based on configuration
      local likely_pattern=""
      
      if [[ "$cpu" != "none" ]]; then
        echo "#### CPU-Bound Pattern"
        echo
        echo "${DIAGNOSTIC_PATTERNS[cpu_bound]}"
        echo
      fi
      
      if [[ "$memory" != "none" ]]; then
        echo "#### Memory Constraint Pattern"
        echo
        echo "${DIAGNOSTIC_PATTERNS[memory_constraint]}"
        echo
      fi
      
      if [[ "$network" != "none" ]]; then
        echo "#### Network Latency/Connectivity Pattern"
        echo
        echo "${DIAGNOSTIC_PATTERNS[network_latency]}"
        echo
      fi
      
      if [[ "$thread" != "none" ]]; then
        echo "#### Thread Safety Issue Pattern"
        echo
        echo "${DIAGNOSTIC_PATTERNS[thread_safety]}"
        echo
      fi
      
      if [[ "$io" != "none" ]]; then
        echo "#### Resource Exhaustion Pattern"
        echo
        echo "${DIAGNOSTIC_PATTERNS[resource_exhaustion]}"
        echo
      fi
    done
    
    echo "## Next Steps"
    echo
    echo "1. For each observed pattern, follow the THREE-step validation approach"
    echo "2. Document your findings as you investigate each pattern"
    echo "3. Implement fixes based on the TWO options provided for each pattern"
    echo "4. Verify fixes by re-running the pairwise tests"
    echo
    echo "Remember that multiple patterns may interact. Start with the most dominant pattern, fix it, then re-evaluate."
    
  } > "$output_file"
  
  echo "Diagnostic plan generated: $output_file"
  echo "$output_file"
}

# Main function
main() {
  local action="$1"
  shift
  
  case "$action" in
    show)
      show_diagnostic_guide "$1"
      ;;
    
    list)
      list_diagnostic_patterns
      ;;
    
    identify)
      identify_patterns_from_log "$1"
      ;;
    
    plan)
      generate_diagnostic_plan "$@"
      ;;
    
    help|--help|-h)
      echo "Usage: $(basename "$0") <action> [options]"
      echo
      echo "Actions:"
      echo "  show <pattern>              Show guide for a specific diagnostic pattern"
      echo "  list                        List all available diagnostic patterns"
      echo "  identify <log_file>         Identify patterns from test log file"
      echo "  plan <results_file> [out]   Generate diagnostic plan from pairwise results"
      echo "  help                        Show this help message"
      echo
      echo "Examples:"
      echo "  $(basename "$0") show cpu_bound"
      echo "  $(basename "$0") list"
      echo "  $(basename "$0") identify test-output.log"
      echo "  $(basename "$0") plan pairwise_results.csv diagnostic_plan.md"
      ;;
    
    *)
      echo "Unknown action: $action" >&2
      echo "Run '$(basename "$0") help' for usage information" >&2
      return 1
      ;;
  esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi