# The MVNimble 1-2-3 Diagnostic Framework

This document introduces MVNimble's structured approach to test diagnostics, designed to transform how QA engineers investigate test execution issues. The 1-2-3 framework helps you methodically diagnose problems without requiring deep code expertise.

## The Framework at a Glance

Every diagnostic pattern in MVNimble follows this consistent structure:

| Component | Purpose | Example |
|-----------|---------|---------|
| **1️⃣ ONE Signature** | The distinctive pattern that identifies the issue | Test execution time increases linearly with CPU load |
| **2️⃣ TWO Options** | Parallel investigation paths to explore | Thread count optimization + Algorithmic profiling |
| **3️⃣ THREE Steps** | Methodical validation process | 1. Simulate varying constraints<br>2. Measure & visualize impact<br>3. Validate optimal configuration |

## Why This Framework Works

The 1-2-3 approach addresses three common pitfalls in test diagnostics:

1. **Unclear Starting Point**: Identifying ONE signature helps you recognize issues quickly
2. **Single-Path Tunnel Vision**: Pursuing TWO options prevents getting stuck in one approach
3. **Incomplete Validation**: Following THREE steps ensures thorough hypothesis testing

## Diagnostic Pattern Library

MVNimble provides a comprehensive library of diagnostic patterns, each structured with the 1-2-3 framework. These patterns cover the most common test execution issues:

| Pattern | Signature | Common In | Access Command |
|---------|-----------|-----------|----------------|
| **CPU-Bound** | Execution time varies with CPU load | Compute-intensive tests | `./diagnostic_patterns.bash show cpu_bound` |
| **Memory-Constrained** | OutOfMemoryError or GC overhead errors | Data-processing tests | `./diagnostic_patterns.bash show memory_constraint` |
| **Network Latency** | Timeout exceptions, inconsistent failures | Integration tests | `./diagnostic_patterns.bash show network_latency` |
| **Thread Safety** | Passes in isolation, fails in parallel | Concurrent tests | `./diagnostic_patterns.bash show thread_safety` |
| **Resource Exhaustion** | Connection limits, file handle errors | I/O-heavy tests | `./diagnostic_patterns.bash show resource_exhaustion` |
| **Flaky Assertion** | Small differences in expected values | Floating-point comparisons | `./diagnostic_patterns.bash show flaky_assertion` |
| **Timing Sensitivity** | Failures depend on execution speed | Tests with explicit waits | `./diagnostic_patterns.bash show timing_sensitivity` |
| **External Dependency** | Correlates with third-party availability | API tests | `./diagnostic_patterns.bash show external_dependency` |

## Example: Applying the Framework to CPU-Bound Tests

### ONE Signature: Execution Time Correlates with CPU Load

```bash
# Running tests shows this pattern
Run 1 (low system load): 45 seconds
Run 2 (high system load): 74 seconds  # ~65% slower
Run 3 (low system load): 47 seconds
```

### TWO Options to Explore in Parallel

1. **Thread Count Optimization**
   ```bash
   # Test with different thread counts
   for threads in 1 2 4 8; do
     time mvn test -T $threads
   done
   ```

2. **CPU Usage Profiling**
   ```bash
   # Profile CPU hotspots during execution
   java -XX:+UnlockDiagnosticVMOptions -XX:+DebugNonSafepoints \
        -XX:+FlightRecorder -XX:StartFlightRecording=filename=profile.jfr \
        -jar your-application.jar
   ```

### THREE Steps to Validate

1. **Simulate varying CPU loads** to confirm the pattern
   ```bash
   source ./resource_constraints.bash
   for load in 0 30 60 90; do
     simulate_high_cpu_load $load
     time mvn test
   done
   ```

2. **Visualize the relationship** between CPU load and execution time
   ```bash
   # Plot shows linear relationship, confirming CPU bottleneck
   ```

3. **Determine optimal thread count** for your environment
   ```bash
   # Testing shows -T 4 is optimal for 8-core machine
   # Applying this change reduces execution time by 35%
   ```

## Using the Framework in Practice

### Automated Diagnostic Workflow

MVNimble automates much of the diagnostic process using the pairwise test matrix and diagnostic pattern analyzer:

```bash
# STEP 1: Generate a test matrix covering key factor combinations
./pairwise_test_matrix.bash generate-matrix matrix.csv

# STEP 2: Run tests with each combination of factors
./pairwise_test_matrix.bash run-all-cases matrix.csv 'mvn test' results.csv

# STEP 3: Generate diagnostic guidance with the 1-2-3 framework
./pairwise_test_matrix.bash generate-guidance results.csv guidance.md

# STEP 4: Identify specific patterns from test logs
./diagnostic_patterns.bash identify test.log
```

### From Diagnosis to Solution

The 1-2-3 framework creates a clear path from problem to solution:

1. **Pattern Identification**: The ONE signature points to specific diagnostic patterns
2. **Investigation**: The TWO options provide clear investigation paths
3. **Validation**: The THREE steps confirm the root cause
4. **Solution**: Apply targeted fixes based on validated findings
5. **Verification**: Run the same tests to confirm improvement

### Benefits for QA Engineers and Teams

The 1-2-3 framework develops five critical skills:

1. **Pattern Recognition**: Learn to quickly identify diagnostic signatures
2. **Controlled Experimentation**: Design tests that isolate specific factors
3. **Data-Driven Analysis**: Base conclusions on measured evidence
4. **Systematic Problem Solving**: Follow a methodical investigation process
5. **Knowledge Transfer**: Document findings in a consistent, reproducible format

This structured approach transforms test troubleshooting from an individual expertise-dependent activity into a systematic, team-enabled process that builds collective knowledge.

---
Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
