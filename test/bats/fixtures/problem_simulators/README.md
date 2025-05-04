# MVNimble: Test Environment Diagnostic Toolkit

MVNimble provides QA engineers with diagnostic tools that follow the QA Empowerment mission of ADR-000. These tools enable systematic investigation of test execution patterns without requiring code expertise, allowing engineers to make data-driven decisions about test environments.

## How MVNimble Empowers QA Engineers

MVNimble takes a unique **pattern recognition approach** to test diagnostics:

1. **Identify distinctive test execution patterns** in logs and performance data
2. **Apply the 1-2-3 framework** to investigate methodically:
   - **ONE signature** that identifies the issue type
   - **TWO options** to explore in parallel
   - **THREE steps** to validate your hypothesis
3. **Build your diagnostic toolkit** through systematic experimentation

This approach helps QA engineers develop valuable skills in diagnostics, controlled experimentation, and solution validation - making you more effective regardless of test suite size or complexity.

## Core Diagnostic Components

MVNimble organizes diagnostics around four key domains:

| Domain | Tools | Purpose |
|--------|-------|---------|
| **Resource Patterns** | `resource_constraints.bash` | Simulate and diagnose CPU, memory, and disk constraints |
| **Concurrency Patterns** | `thread_safety_issues.bash` | Identify race conditions, deadlocks, and isolation problems |
| **Network Patterns** | `network_io_bottlenecks.bash` | Diagnose latency, connectivity, and dependency issues |
| **Pattern Combinations** | `pairwise_test_matrix.bash`<br>`diagnostic_patterns.bash` | Systematically test factor interactions and generate targeted diagnosis |

## Quick Start Guide

### 1. Diagnose Test Execution Patterns

```bash
# Generate diagnostic questions from test logs
./optimization_config_generator.bash maven-test.log ./mvnimble-diagnostics

# Identify specific diagnostic patterns
./diagnostic_patterns.bash identify maven-test.log
```

### 2. Investigate with Controlled Experiments

```bash
# Explore a specific diagnostic pattern with the 1-2-3 framework
./diagnostic_patterns.bash show cpu_bound

# Run experiments with controlled constraints
source ./resource_constraints.bash
simulate_high_cpu_load 50
mvn test -Dtest=SlowTests
```

### 3. Validate Multiple Hypotheses

```bash
# Generate and run a pairwise test matrix
./pairwise_test_matrix.bash generate-matrix matrix.csv
./pairwise_test_matrix.bash run-all-cases matrix.csv 'mvn test' results.csv

# Generate diagnostic guidance with the 1-2-3 framework
./pairwise_test_matrix.bash generate-guidance results.csv guidance.md
```

## MVNimble Tools and Usage

### Core Diagnostic Tools

| Tool | Purpose | Key Commands |
|------|---------|-------------|
| **Diagnostic Pattern Analyzer**<br>`diagnostic_patterns.bash` | Apply the 1-2-3 framework to identified patterns | `./diagnostic_patterns.bash identify log-file.log`<br>`./diagnostic_patterns.bash show cpu_bound` |
| **Question Generator**<br>`optimization_config_generator.bash` | Generate targeted investigative questions | `./optimization_config_generator.bash maven-test.log ./diagnostics` |
| **Pairwise Test Matrix**<br>`pairwise_test_matrix.bash` | Test combinations of factors systematically | `./pairwise_test_matrix.bash generate-matrix matrix.csv`<br>`./pairwise_test_matrix.bash generate-guidance results.csv` |

### Constraint Simulators

| Simulator | Constraints | Example |
|-----------|-------------|---------|
| **Resource Constraints**<br>`resource_constraints.bash` | CPU, memory, disk | `simulate_high_cpu_load 80 30 2`<br>`simulate_memory_pressure 70`<br>`mock_disk_space_issues 100` |
| **Thread Safety Issues**<br>`thread_safety_issues.bash` | Race conditions, deadlocks, isolation | `simulate_race_condition`<br>`simulate_deadlock`<br>`simulate_test_isolation_issue` |
| **Network Bottlenecks**<br>`network_io_bottlenecks.bash` | Latency, connectivity, DNS | `simulate_network_latency "repo1.maven.org" 200`<br>`simulate_dns_issues "maven.apache.org" "slow"`<br>`simulate_connection_issues "repo1.maven.org" "timeout" 50` |

### Pre-configured Common Scenarios

For quick diagnostics with realistic constraints:

```bash
# Simulate typical CI environment constraints
./pairwise_test_matrix.bash ci-environment 'mvn test'

# Simulate unreliable network conditions
./pairwise_test_matrix.bash flaky-network 'mvn test'

# Simulate heavily loaded developer workstation
./pairwise_test_matrix.bash overloaded-workstation 'mvn test'

# Simulate environment with thread safety issues
./pairwise_test_matrix.bash thread-unsafe 'mvn test'
```

### The MVNimble Diagnostic Workflow

1. **Identify patterns** in test behavior using MVNimble's diagnostic tools
2. **Generate specific questions** to investigate each pattern
3. **Design controlled experiments** to test your hypotheses
4. **Apply the 1-2-3 framework** to validate your findings
5. **Document your discoveries** to build your diagnostic toolkit

**Real-world example:** A QA team applied MVNimble's pattern analysis to inconsistent test failures and identified a previously hidden interaction between thread count and container CPU limit. By changing a single parameter (`-T 4` instead of `-T 16`), they achieved 3x faster and more reliable test execution without any code changes.

## Key Diagnostic Strategies

### The 80/20 Principle of Test Optimization

MVNimble consistently demonstrates that in most test suites:
- **80% of execution time** is consumed by 20% of tests
- **50%+ performance gains** are achievable with configuration changes alone
- **Thread count optimization** alone can yield 20-40% improvements

This insight allows QA engineers to make targeted, high-impact improvements without code changes.

### Effective Investigation Techniques

| Strategy | Description | Approach |
|----------|-------------|----------|
| **Isolate Then Combine** | Identify individual factors before exploring interactions | 1. Test one constraint at a time<br>2. Use pairwise matrix for interactions<br>3. Document each finding separately |
| **Apply 80/20 Principle** | Focus on the most impactful tests first | 1. Identify your slowest tests<br>2. Apply pattern analysis to those tests<br>3. Target optimizations for maximum impact |
| **Build Shareable Insights** | Create a diagnostic knowledge base | 1. Document patterns with 1-2-3 framework<br>2. Share findings as runnable experiments<br>3. Maintain a team diagnostic playbook |

### The Five Core Skills MVNimble Helps Develop

1. **Pattern Recognition** - Transform "Tests are slow" into "What specific patterns do we observe?"
   ```bash
   # Identify patterns in test logs
   ./diagnostic_patterns.bash identify maven-test.log
   ```

2. **Controlled Experimentation** - Test specific hypotheses systematically
   ```bash
   # Test a specific hypothesis about thread count
   for threads in 1 2 4 8; do
     time mvn test -DforkCount=$threads
   done
   ```

3. **Factor Interaction Analysis** - Understand how multiple factors combine
   ```bash
   # Generate and run pairwise test matrix
   ./pairwise_test_matrix.bash generate-matrix matrix.csv
   ./pairwise_test_matrix.bash run-all-cases matrix.csv 'mvn test'
   ```

4. **Data-Driven Decision Making** - Base recommendations on measurements
   ```bash
   # Apply the 1-2-3 framework to test results
   ./pairwise_test_matrix.bash generate-guidance results.csv
   ```

5. **Systematic Problem Solving** - Follow the 1-2-3 framework methodically
   ```bash
   # For identified test patterns
   ./diagnostic_patterns.bash show thread_safety
   # Then follow the ONE signature, TWO options, THREE steps
   ```

### Empowerment Through Investigation

MVNimble transforms QA engineering by shifting from random troubleshooting to methodical diagnostics. This empowerment comes from building your diagnostic toolkit and skills.

Remember: **"Better questions lead to better answers."**

This approach enables you to:
1. **Frame precise questions** about test execution patterns
2. **Design controlled experiments** to validate hypotheses
3. **Build shared knowledge** that persists beyond individual troubleshooting sessions
4. **Make data-driven recommendations** without requiring code expertise

## Further Reading

For detailed explanations and practical guidance, see:
- [QA-ENGINEERS-GUIDE.md](../../../doc/QA-ENGINEERS-GUIDE.md) - Comprehensive practitioner's guide with flaky test diagnostics
- [DIAGNOSTIC-APPROACHES.md](../../../doc/DIAGNOSTIC-APPROACHES.md) - The 1-2-3 framework for systematic test investigation
- [FLAKY-TEST-DIAGNOSIS.md](../../../doc/FLAKY-TEST-DIAGNOSIS.md) - Detailed reference for diagnosing flaky tests by layer
- [FLAKY-TEST-HUMOR.md](../../../doc/FLAKY-TEST-HUMOR.md) - A lighthearted take on the frustrations of flaky tests
- [REAL-WORLD-SCENARIOS.md](../../../doc/REAL-WORLD-SCENARIOS.md) - Real-world investigation examples
- [OPTIMIZATION-INSIGHTS.md](../../../doc/OPTIMIZATION-INSIGHTS.md) - Data-driven insights for investigation
- [ADR-000-QA-EMPOWERMENT.md](../../../doc/adr/000-adr-process-qa-empowerment.md) - Architectural decision record on QA empowerment

---
Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
