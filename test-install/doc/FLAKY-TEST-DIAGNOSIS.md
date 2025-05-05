# MVNimble Flaky Test Diagnostic Reference

This document provides a comprehensive framework for diagnosing flaky tests, organized by the seven fundamental layers of test flakiness. Each layer includes specific diagnostic steps, skills required, and investigation techniques to help QA engineers efficiently identify root causes.

Use this reference in conjunction with the diagnostic tools in MVNimble to systematically investigate test flakiness and develop targeted solutions.

## Diagnostic Steps for Each Layer of Test Flakiness

## 1. Timing Layer

### Type A: Hard-coded Wait Patterns

1. **Log Execution Times**
   - Run tests with enhanced logging to capture the actual time each operation takes
   - Compare these times against the hard-coded waits to identify mismatches
   - Skills: Log analysis, instrumentation, performance profiling

2. **Vary System Load Conditions**
   - Execute tests under different system load patterns (idle, moderate, heavy)
   - Record pass/fail rates correlated with system resource utilization
   - Skills: Performance testing, system monitoring, load generation

3. **Trace Wait Dependencies**
   - Identify exact wait conditions in the code using call stack analysis
   - Document the system dependencies each wait is guarding against
   - Skills: Code tracing, dependency analysis, asynchronous programming patterns

### Type B: Race Conditions

1. **Thread Dump Analysis**
   - Capture thread dumps at the moment of failure
   - Analyze execution states to identify competing threads and resources
   - Skills: Multi-threading concepts, deadlock analysis, thread state interpretation

2. **Increase Execution Interleaving**
   - Deliberately introduce random delays at critical sections
   - Use stress testing to maximize the probability of race condition manifestation
   - Skills: Chaos engineering, concurrency testing, thread timing manipulation

3. **Event Sequence Visualization**
   - Record the exact sequence of events during test execution
   - Create timing diagrams to visualize thread interactions
   - Skills: Distributed tracing, sequence diagramming, event correlation

## 2. Resource Contention Layer

### Type A: Exclusive Resource Locks

1. **Resource Acquisition Mapping**
   - Instrument code to log all resource acquisition attempts with timestamps
   - Identify patterns of conflicting resource usage across test cases
   - Skills: Resource utilization monitoring, lock analysis, instrumentation

2. **Contention Heat Map Creation**
   - Chart resources by contention frequency in parallel test runs
   - Correlate test failures with specific resource contention patterns
   - Skills: Data visualization, statistical analysis, resource monitoring

3. **Lock Duration Profiling**
   - Measure how long each resource is locked by different tests
   - Identify opportunities to minimize lock duration or scope
   - Skills: Performance profiling, lock optimization, deadlock analysis

### Type B: Resource Exhaustion

1. **Resource Consumption Tracking**
   - Monitor memory, connections, file handles throughout test execution
   - Establish resource usage patterns for each test
   - Skills: System resource monitoring, memory profiling, connection pooling

2. **Threshold Testing**
   - Incrementally lower resource limits until failures occur
   - Determine the minimum viable resources for reliable test execution
   - Skills: Configuration management, threshold analysis, stress testing

3. **Leak Detection**
   - Run extended test cycles to identify resource leaks
   - Use memory/resource profilers to pinpoint leaked resources
   - Skills: Memory leak analysis, resource tracking, garbage collection optimization

## 3. Environmental Dependency Layer

### Type A: Configuration Dependencies

1. **Environment Variable Diffing**
   - Compare environment variables between passing and failing environments
   - Create a matrix of environment differences correlated with test outcomes
   - Skills: Environment configuration analysis, system administration, variable tracing

2. **Configuration Isolation Testing**
   - Systematically neutralize each configuration variable
   - Create minimal configuration profiles needed for test success
   - Skills: Configuration management, dependency isolation, test environment setup

3. **Dynamic Configuration Tracing**
   - Instrument code to log all configuration value accesses
   - Identify which specific configurations impact test outcomes
   - Skills: Code instrumentation, configuration tracking, dependency analysis

### Type B: System Clock Dependencies

1. **Time Manipulation Testing**
   - Run tests with artificially altered system clocks
   - Test around time boundaries (midnight, DST changes, year end)
   - Skills: Time manipulation, date/time library expertise, temporal logic

2. **Time Sensitivity Mapping**
   - Log all time-dependent operations and compare with failure patterns
   - Identify code that makes assumptions about time progression
   - Skills: Timing analysis, log correlation, temporal dependency mapping

3. **Time Zone Variation Testing**
   - Execute tests across different time zones
   - Identify assumptions about local time vs. UTC
   - Skills: Time zone handling, international date line awareness, date/time formatting

## 4. External Integration Layer

### Type A: Third-Party API Instability

1. **Service Reliability Tracking**
   - Create dashboards monitoring external service availability
   - Correlate test failures with service degradation periods
   - Skills: Service monitoring, uptime tracking, status page integration

2. **Response Pattern Analysis**
   - Log and categorize API responses from external services
   - Identify unusual response patterns that correlate with test failures
   - Skills: API response analysis, error pattern recognition, protocol debugging

3. **Mock Comparison Testing**
   - Run tests against both real services and mocked equivalents
   - Document discrepancies to identify misunderstandings about service behavior
   - Skills: Mocking, service virtualization, contract testing

### Type B: Network Variability

1. **Network Quality Monitoring**
   - Measure packet loss, latency, and jitter during test runs
   - Correlate network metrics with test outcomes
   - Skills: Network analysis, packet capture, latency measurement

2. **Network Condition Simulation**
   - Test under artificially degraded network conditions
   - Identify minimum viable network conditions for reliable tests
   - Skills: Network conditioning, traffic shaping, fault injection

3. **Connection Pattern Analysis**
   - Log TCP/IP connection establishment, duration, and termination
   - Identify abnormal connection behaviors during test failures
   - Skills: Socket debugging, network protocol analysis, connection pooling

## 5. State Isolation Layer

### Type A: Contaminated Test Context

1. **Global State Snapshot Diffing**
   - Capture snapshots of global state before and after each test
   - Compare state differences with expected cleanup behavior
   - Skills: Memory dumping, state comparison, object graph analysis

2. **Test Order Permutation**
   - Execute tests in different orders and track outcomes
   - Identify specific test sequences that trigger failures
   - Skills: Test orchestration, dependency mapping, execution order analysis

3. **Isolation Level Testing**
   - Run tests with progressively stricter isolation (process, classloader, VM)
   - Determine the isolation level required for consistent results
   - Skills: Test isolation techniques, runtime environment management, sandbox creation

### Type B: Hidden Dependencies

1. **Dependency Chain Analysis**
   - Trace data flow between test cases
   - Construct dependency graphs showing implicit test relationships
   - Skills: Data flow analysis, dependency graphing, implicit relation mapping

2. **Setup/Teardown Coverage Analysis**
   - Identify resources accessed in setup/teardown but not explicitly tracked
   - Verify coverage of cleanup routines against resource usage
   - Skills: Coverage analysis, resource tracking, cleanup verification

3. **Independent Verification Testing**
   - Execute test combinations on fresh environments
   - Identify tests that cannot pass in isolation
   - Skills: Clean environment management, dependency validation, test harness construction

## 6. Nondeterministic Logic Layer

### Type A: Unseeded Randomness

1. **Randomness Source Identification**
   - Instrument code to log all sources of randomness
   - Track random value generation across test runs
   - Skills: Random number generator detection, instrumentation, entropy source analysis

2. **Seed Manipulation Experiments**
   - Run tests with fixed seeds for all random generators
   - Verify reproducibility of results with identical seeds
   - Skills: Random seed management, reproducibility testing, deterministic programming

3. **Statistical Outcome Analysis**
   - Run tests hundreds of times to establish failure patterns
   - Apply statistical methods to identify random outcome clusters
   - Skills: Statistical analysis, pattern recognition, probability assessment

### Type B: Multi-threading Issues

1. **Thread Interaction Mapping**
   - Log all cross-thread data access and synchronization points
   - Construct thread interaction models showing potential race points
   - Skills: Thread analysis, concurrent programming, synchronization modeling

2. **Concurrency Hazard Detection**
   - Use static analysis tools to identify concurrent access patterns
   - Validate thread safety assumptions with formal verification
   - Skills: Static analysis, concurrency verification, thread safety patterns

3. **Atomicity Verification**
   - Instrument code to detect non-atomic operations on shared data
   - Test with different thread scheduling patterns
   - Skills: Atomicity analysis, thread scheduling, lock-free programming

## 7. Assertion Sensitivity Layer

### Type A: Overly Specific Assertions

1. **Assertion Fragility Analysis**
   - Count assertion failures during trivial code changes
   - Rank assertions by sensitivity to unrelated changes
   - Skills: Test impact analysis, change sensitivity measurement, assertion evaluation

2. **Assertion Abstraction Testing**
   - Create more generic versions of highly specific assertions
   - Compare stability of generic vs. specific assertions
   - Skills: Assertion design, abstraction techniques, equivalence testing

3. **Intent vs. Implementation Analysis**
   - Determine the business intent behind each assertion
   - Evaluate if assertions test implementation details rather than requirements
   - Skills: Requirements analysis, test purpose evaluation, intent extraction

### Type B: Numeric Precision Problems

1. **Precision Requirement Analysis**
   - Document the actual precision needed for business correctness
   - Compare with the precision enforced by assertions
   - Skills: Numeric analysis, business requirement analysis, precision evaluation

2. **Platform Variation Testing**
   - Run tests across different hardware/OS/compiler combinations
   - Identify floating-point behavior variations between platforms
   - Skills: Cross-platform testing, floating-point architecture, numeric stability

3. **Tolerance Boundary Exploration**
   - Test with progressively wider tolerance margins
   - Establish minimum viable precision for business correctness
   - Skills: Epsilon testing, numerical stability, tolerance determination

## Using MVNimble to Diagnose Flaky Tests

MVNimble provides several tools to help with flaky test diagnosis:

### 1. Generate Diagnostic Questions

```bash
# Analyze test execution logs for patterns
./optimization_config_generator.bash flaky-test.log ./flaky-diagnostics
```

This generates targeted questions about test execution patterns that might indicate flakiness.

### 2. Simulate Problematic Conditions

```bash
# For timing-related flakiness
source ./resource_constraints.bash
simulate_high_cpu_load 80

# For resource contention flakiness
simulate_memory_pressure 90

# For network-related flakiness
source ./network_io_bottlenecks.bash
simulate_network_latency "api.example.com" 150
```

These simulations can help reproduce flaky test conditions in a controlled manner.

### 3. Apply Pairwise Testing

```bash
# Generate combinations of problematic conditions
./pairwise_test_matrix.bash generate-matrix flaky-factors.csv

# Run tests with different combinations
./pairwise_test_matrix.bash run-all-cases flaky-factors.csv "mvn test -Dtest=FlakyTest" results.csv

# Analyze which factor combinations caused failures
./pairwise_test_matrix.bash analyze-results results.csv > flaky-analysis.md
```

Pairwise testing helps identify specific combinations of factors that trigger flaky test failures.

### 4. Document Findings

As you diagnose flaky tests, document your findings for future reference:

```
# Flaky Test: UserAuthenticationTest#testLoginTimeout
# Layer: Timing (Type A: Hard-coded Wait)
# Root Cause: Test uses Thread.sleep(2000) but login can take 2200ms under load
# Solution: Replaced with explicit wait for completion condition
```

By categorizing flaky tests according to this framework, you can build a knowledge base of common patterns in your codebase and develop systematic solutions.

## MVNimble Integration

MVNimble's diagnostic question generator can help identify which of these seven layers is most likely causing your flaky tests by analyzing test execution logs and resource usage patterns. By combining the structured diagnostic approach in this document with MVNimble's tools, QA engineers can more efficiently track down and resolve flaky tests.

## Common Shell Script Test Flakiness

Shell script tests can exhibit unique flakiness issues, especially related to:

### 1. Bash Version Incompatibilities

Flakiness symptom: Tests pass on newer systems but fail on older ones

- **Problem**: Features like associative arrays (`declare -A`) are only available in Bash 4.0+
- **Detection**: Run tests with `bash --version` set to different versions
- **Solution**: 
  - Replace associative arrays with simple string-based key-value stores
  - Use string manipulation for map-like access: `MYMAP="key1=val1 key2=val2"` and `echo "$MYMAP" | grep -o "key1=[^ ]*" | cut -d= -f2`

### 2. Environment Variable Leakage

Flakiness symptom: Tests pass in isolation but fail when run together

- **Problem**: Tests modify environment variables without restoring them
- **Detection**: Compare environment before and after each test
- **Solution**:
  - Save environment state at test start: `OLD_VAR="$VAR"`
  - Restore at test end: `VAR="$OLD_VAR"`
  - Use subshells to isolate environment changes: `(export VAR=value; run_test)`

### 3. Temporary File Collisions

Flakiness symptom: Tests fail inconsistently with file access errors

- **Problem**: Multiple tests use the same temporary file paths
- **Detection**: Add instrumentation to track file operations
- **Solution**:
  - Use `mktemp` to create unique temporary files
  - Create test-specific subdirectories
  - Clean up files in teardown, even after failures

### 4. Command Mocking Failures

Flakiness symptom: Tests pass locally but fail in CI

- **Problem**: Test mocks commands that exist in different paths across environments
- **Detection**: Compare `PATH` and command availability across environments
- **Solution**:
  - Use absolute paths when mocking commands
  - Create proper function-based mocks rather than PATH manipulation
  - Verify mock effectiveness before test execution

### 5. Performance Test Tool Availability

Flakiness symptom: Tests that use specific tools like `bc` work on some systems but fail on others

- **Problem**: Performance tests rely on tools that might not be installed or behave differently across systems
- **Detection**: Check if tools are available and compatible across environments
- **Solution**:
  - Use native Bash arithmetic (`$((expr))`) instead of external tools when possible
  - Mock timing functions to provide consistent results for testing
  - Focus tests on functionality rather than exact timing measurements
  - When testing performance, test for "less than X" rather than exact values

### 6. Path Resolution Differences

Flakiness symptom: Tests can't find modules/fixtures in CI but work locally

- **Problem**: Tests use relative paths that resolve differently based on working directory
- **Detection**: Print and compare absolute paths across environments
- **Solution**:
  - Use `${BATS_TEST_DIRNAME}` to locate fixtures relative to the test
  - Create local stubs in the test directory for helper modules
  - Avoid `cd` commands in tests or test setup/teardown

By addressing these shell-specific flakiness issues, you can significantly improve the reliability of your MVNimble test suite across different environments.

---
Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
