#!/usr/bin/env bash
# MVNimble Test Helpers
# Common helper functions for BATS tests

# Set strict mode
set -eo pipefail

# Get project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"

# Path to the lib directory containing the modules
LIB_DIR="${PROJECT_ROOT}/lib"

# Path to fixtures
FIXTURES_DIR="${PROJECT_ROOT}/test/simplified/common/fixtures"

# Load bats-support and bats-assert if available
load_libs() {
  if [ -d "${PROJECT_ROOT}/test/bats/helpers/bats-support" ]; then
    load "${PROJECT_ROOT}/test/bats/helpers/bats-support/load"
    load "${PROJECT_ROOT}/test/bats/helpers/bats-assert/load"
  fi
}

# Setup for each test
setup() {
  # Load libraries
  load_libs
  
  # Create a temporary directory for test artifacts
  TEST_TEMP_DIR="$(mktemp -d)"
  export TEST_TEMP_DIR
}

# Teardown after each test
teardown() {
  # Clean up temporary directory
  if [ -n "$TEST_TEMP_DIR" ] && [ -d "$TEST_TEMP_DIR" ]; then
    rm -rf "$TEST_TEMP_DIR"
  fi
}

# Load a library module for testing
load_module() {
  local module_name="$1"
  local module_path="${LIB_DIR}/${module_name}.sh"
  
  # Source the module if it exists
  if [ -f "$module_path" ]; then
    source "$module_path"
  else
    echo "Module not found: $module_path" >&2
    return 1
  fi
}

# Create a test fixture file
create_test_fixture() {
  local filename="$1"
  local content="$2"
  local filepath="${TEST_TEMP_DIR}/${filename}"
  
  echo "$content" > "$filepath"
  echo "$filepath"
}

# Verify that a command is available
assert_command_exists() {
  local command_name="$1"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Command not available: $command_name" >&2
    return 1
  fi
  return 0
}

# Run a command with a timeout
run_with_timeout() {
  local timeout="$1"
  shift
  
  # Timeout function is not available on all platforms
  if command -v timeout >/dev/null 2>&1; then
    timeout "$timeout" "$@"
    return $?
  else
    # Fallback for macOS and other systems without timeout command
    local pid
    "$@" &
    pid=$!
    
    # Wait for the command to complete or timeout
    local start_time=$(date +%s)
    local timeout_seconds=${timeout%s}
    
    while kill -0 $pid 2>/dev/null; do
      if [ $(($(date +%s) - start_time)) -ge "$timeout_seconds" ]; then
        kill -9 $pid 2>/dev/null || true
        wait $pid 2>/dev/null || true
        return 124  # Same as GNU timeout exit code
      fi
      sleep 0.1
    done
    
    wait $pid
    return $?
  fi
}

# Create a mock Maven output file
create_mock_maven_output() {
  local output_type="$1"  # success, failure, or warning
  local output_file="${TEST_TEMP_DIR}/maven_${output_type}.log"
  
  case "$output_type" in
    success)
      cat > "$output_file" <<EOF
[INFO] Scanning for projects...
[INFO] 
[INFO] -----------------------< com.example:sample-app >-----------------------
[INFO] Building sample-app 1.0-SNAPSHOT
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-clean-plugin:3.1.0:clean (default-clean) @ sample-app ---
[INFO] Deleting /tmp/sample-app/target
[INFO] 
[INFO] --- maven-resources-plugin:3.0.2:resources (default-resources) @ sample-app ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] Copying 1 resource
[INFO] 
[INFO] --- maven-compiler-plugin:3.8.0:compile (default-compile) @ sample-app ---
[INFO] Changes detected - recompiling the module!
[INFO] Compiling 2 source files to /tmp/sample-app/target/classes
[INFO] 
[INFO] --- maven-surefire-plugin:2.22.1:test (default-test) @ sample-app ---
[INFO] 
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running com.example.AppTest
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.035 s - in com.example.AppTest
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  1.985 s
[INFO] Finished at: 2025-05-04T14:32:45-07:00
[INFO] ------------------------------------------------------------------------
EOF
      ;;
    failure)
      cat > "$output_file" <<EOF
[INFO] Scanning for projects...
[INFO] 
[INFO] -----------------------< com.example:sample-app >-----------------------
[INFO] Building sample-app 1.0-SNAPSHOT
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-clean-plugin:3.1.0:clean (default-clean) @ sample-app ---
[INFO] Deleting /tmp/sample-app/target
[INFO] 
[INFO] --- maven-resources-plugin:3.0.2:resources (default-resources) @ sample-app ---
[INFO] Using 'UTF-8' encoding to copy filtered resources.
[INFO] Copying 1 resource
[INFO] 
[INFO] --- maven-compiler-plugin:3.8.0:compile (default-compile) @ sample-app ---
[INFO] Changes detected - recompiling the module!
[INFO] Compiling 2 source files to /tmp/sample-app/target/classes
[INFO] 
[INFO] --- maven-surefire-plugin:2.22.1:test (default-test) @ sample-app ---
[INFO] 
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running com.example.AppTest
[ERROR] Tests run: 3, Failures: 1, Errors: 0, Skipped: 0, Time elapsed: 0.045 s <<< FAILURE! - in com.example.AppTest
[ERROR] testCalculator(com.example.AppTest)  Time elapsed: 0.012 s  <<< FAILURE!
java.lang.AssertionError: expected:<42> but was:<41>
        at org.junit.Assert.fail(Assert.java:89)
        at org.junit.Assert.failNotEquals(Assert.java:835)
        at org.junit.Assert.assertEquals(Assert.java:647)
        at org.junit.Assert.assertEquals(Assert.java:633)
        at com.example.AppTest.testCalculator(AppTest.java:22)

[INFO] 
[INFO] Results:
[INFO] 
[ERROR] Failures: 
[ERROR]   AppTest.testCalculator:22 expected:<42> but was:<41>
[INFO] 
[ERROR] Tests run: 3, Failures: 1, Errors: 0, Skipped: 0
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  2.312 s
[INFO] Finished at: 2025-05-04T14:33:15-07:00
[INFO] ------------------------------------------------------------------------
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-surefire-plugin:2.22.1:test (default-test) on project sample-app: There are test failures.
[ERROR] 
[ERROR] Please refer to /tmp/sample-app/target/surefire-reports for the individual test results.
[ERROR] -> [Help 1]
EOF
      ;;
    warning)
      cat > "$output_file" <<EOF
[INFO] Scanning for projects...
[INFO] 
[INFO] -----------------------< com.example:sample-app >-----------------------
[INFO] Building sample-app 1.0-SNAPSHOT
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-clean-plugin:3.1.0:clean (default-clean) @ sample-app ---
[INFO] Deleting /tmp/sample-app/target
[INFO] 
[INFO] --- maven-resources-plugin:3.0.2:resources (default-resources) @ sample-app ---
[WARNING] Using platform encoding (UTF-8 actually) to copy filtered resources, i.e. build is platform dependent!
[INFO] Copying 1 resource
[INFO] 
[INFO] --- maven-compiler-plugin:3.8.0:compile (default-compile) @ sample-app ---
[INFO] Changes detected - recompiling the module!
[WARNING] File encoding has not been set, using platform encoding UTF-8, i.e. build is platform dependent!
[INFO] Compiling 2 source files to /tmp/sample-app/target/classes
[WARNING] bootstrap class path not set in conjunction with -source 8
[INFO] 
[INFO] --- maven-surefire-plugin:2.22.1:test (default-test) @ sample-app ---
[INFO] 
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running com.example.AppTest
[WARNING] Tests run: 3, Failures: 0, Errors: 0, Skipped: 1, Time elapsed: 0.034 s - in com.example.AppTest
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 1
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  2.034 s
[INFO] Finished at: 2025-05-04T14:34:05-07:00
[INFO] ------------------------------------------------------------------------
EOF
      ;;
  esac
  
  echo "$output_file"
}

# Create a mock environment configuration
create_mock_environment() {
  local env_type="$1"  # macos, linux, ci, or container
  local output_dir="${TEST_TEMP_DIR}/mock_env_${env_type}"
  
  mkdir -p "$output_dir"
  
  case "$env_type" in
    macos)
      # Mock macOS environment files
      cat > "${output_dir}/uname.out" <<EOF
Darwin MacBook-Pro.local 20.6.0 Darwin Kernel Version 20.6.0: Wed Jan 12 22:22:42 PST 2022; root:xnu-7195.141.19~2/RELEASE_X86_64 x86_64
EOF
      cat > "${output_dir}/system_profile.out" <<EOF
Hardware:

    Hardware Overview:

      Model Name: MacBook Pro
      Model Identifier: MacBookPro16,1
      Processor Name: 6-Core Intel Core i7
      Processor Speed: 2.6 GHz
      Number of Processors: 1
      Total Number of Cores: 6
      L2 Cache (per Core): 256 KB
      L3 Cache: 12 MB
      Hyper-Threading Technology: Enabled
      Memory: 32 GB
      
Software:

    System Software Overview:

      System Version: macOS 11.6 (20G165)
      Kernel Version: Darwin 20.6.0
EOF
      ;;
    linux)
      # Mock Linux environment files
      cat > "${output_dir}/uname.out" <<EOF
Linux ubuntu-server 5.15.0-75-generic #82-Ubuntu SMP Tue May 7 14:38:40 UTC 2024 x86_64 x86_64 x86_64 GNU/Linux
EOF
      cat > "${output_dir}/lscpu.out" <<EOF
Architecture:            x86_64
  CPU op-mode(s):        32-bit, 64-bit
  Address sizes:         46 bits physical, 48 bits virtual
  Byte Order:            Little Endian
CPU(s):                  16
  On-line CPU(s) list:   0-15
Vendor ID:               GenuineIntel
  Model name:            Intel(R) Xeon(R) CPU E5-2680 v4 @ 2.40GHz
EOF
      cat > "${output_dir}/meminfo.out" <<EOF
MemTotal:       32675848 kB
MemFree:        26452812 kB
MemAvailable:   29575016 kB
Buffers:          545292 kB
Cached:          3742844 kB
SwapCached:            0 kB
Active:          3172240 kB
Inactive:        2418004 kB
EOF
      ;;
    container)
      # Mock container environment files
      cat > "${output_dir}/uname.out" <<EOF
Linux container-abc123 5.15.0-75-generic #82-Ubuntu SMP Tue May 7 14:38:40 UTC 2024 x86_64 x86_64 x86_64 GNU/Linux
EOF
      cat > "${output_dir}/container_detection.out" <<EOF
container
EOF
      cat > "${output_dir}/cgroup.out" <<EOF
0::/system.slice/docker-1a2b3c4d5e6f7g8h9i0j.scope
EOF
      ;;
    ci)
      # Mock CI environment files
      cat > "${output_dir}/uname.out" <<EOF
Linux github-runner-abc123 5.15.0-75-generic #82-Ubuntu SMP Tue May 7 14:38:40 UTC 2024 x86_64 x86_64 x86_64 GNU/Linux
EOF
      cat > "${output_dir}/env.out" <<EOF
CI=true
GITHUB_ACTIONS=true
GITHUB_WORKFLOW=MVNimble CI
GITHUB_REPOSITORY=owner/mvnimble
GITHUB_ACTOR=github-actions
EOF
      ;;
  esac
  
  echo "$output_dir"
}

# Create a mock Maven project for testing
create_mock_maven_project() {
  local project_dir="${TEST_TEMP_DIR}/mock_maven_project"
  
  mkdir -p "$project_dir/src/main/java/com/example"
  mkdir -p "$project_dir/src/test/java/com/example"
  
  # Create pom.xml
  cat > "${project_dir}/pom.xml" <<EOF
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.example</groupId>
  <artifactId>mock-project</artifactId>
  <packaging>jar</packaging>
  <version>1.0-SNAPSHOT</version>
  <name>mock-project</name>
  
  <properties>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <maven.compiler.source>1.8</maven.compiler.source>
    <maven.compiler.target>1.8</maven.compiler.target>
  </properties>
  
  <dependencies>
    <dependency>
      <groupId>junit</groupId>
      <artifactId>junit</artifactId>
      <version>4.13.2</version>
      <scope>test</scope>
    </dependency>
  </dependencies>
</project>
EOF
  
  # Create main class
  cat > "${project_dir}/src/main/java/com/example/Calculator.java" <<EOF
package com.example;

public class Calculator {
    public int add(int a, int b) {
        return a + b;
    }
    
    public int subtract(int a, int b) {
        return a - b;
    }
}
EOF
  
  # Create test class
  cat > "${project_dir}/src/test/java/com/example/CalculatorTest.java" <<EOF
package com.example;

import org.junit.Test;
import static org.junit.Assert.*;

public class CalculatorTest {
    private Calculator calculator = new Calculator();
    
    @Test
    public void testAdd() {
        assertEquals(5, calculator.add(2, 3));
    }
    
    @Test
    public void testSubtract() {
        assertEquals(1, calculator.subtract(3, 2));
    }
}
EOF
  
  echo "$project_dir"
}

# Export helper functions for use in tests
export -f load_module
export -f create_test_fixture
export -f assert_command_exists
export -f run_with_timeout
export -f create_mock_maven_output
export -f create_mock_environment
export -f create_mock_maven_project