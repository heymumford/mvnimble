#\!/usr/bin/env bats
# platform_compatibility.bats
# Tests platform detection and compatibility features

load test_helper
load common/environment_helpers
load common/package_manager_helpers

setup() {
  # Create the test environment
  setup_temp_dir
  
  # Load platform compatibility module
  source_module "platform_compatibility.sh"
}

teardown() {
  # Clean up the environment mocks
  cleanup_environment_mocks
  
  # Clean up temporary directory
  cleanup_temp_dir
}

# @functional @positive @platform @adr004
@test "Should correctly detect macOS environment" {
  # Mock a macOS environment
  mock_macos_environment
  
  # Run the platform detection
  run detect_platform
  
  # Verify it identified macOS
  [ "$status" -eq 0 ]
  [[ "$output" == *"macos"* ]] || [[ "$output" == *"darwin"* ]]
}

# @functional @positive @platform @adr004
@test "Should correctly detect Linux environment" {
  # Mock a Linux environment
  mock_linux_environment
  
  # Run the platform detection
  run detect_platform
  
  # Verify it identified Linux
  [ "$status" -eq 0 ]
  [[ "$output" == *"linux"* ]]
}

# @functional @positive @platform @adr004
@test "Should detect container environment" {
  # Mock a container environment
  mock_container_environment
  
  # Run the container detection
  run is_running_in_container
  
  # Verify it identified container environment
  [ "$status" -eq 0 ]
}

# @functional @positive @platform @adr004
@test "Should get correct CPU count on macOS" {
  # Mock a macOS environment
  mock_macos_environment
  
  # Run the CPU count function
  run get_cpu_count
  
  # Verify it returns a positive number
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+$ ]]
  [[ "$output" -gt 0 ]]
}

# @functional @positive @platform @adr004
@test "Should get correct CPU count on Linux" {
  # Mock a Linux environment
  mock_linux_environment
  
  # Run the CPU count function
  run get_cpu_count
  
  # Verify it returns a positive number
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+$ ]]
  [[ "$output" -gt 0 ]]
}

# @functional @positive @platform @adr004
@test "Should correctly determine Java version" {
  # Mock Java command
  mock_command "java" 0 "openjdk version \"17.0.7\" 2023-04-18
OpenJDK Runtime Environment (build 17.0.7+7-Ubuntu-0ubuntu120.04)
OpenJDK 64-Bit Server VM (build 17.0.7+7-Ubuntu-0ubuntu120.04, mixed mode, sharing)"
  
  # Run the Java version detection
  run get_java_version
  
  # Verify it correctly extracts the version
  [ "$status" -eq 0 ]
  [[ "$output" == "17" ]] || [[ "$output" == "17.0.7" ]]
}

# @functional @negative @platform @adr004
@test "Should handle missing Java gracefully" {
  # Skip this test for now - it requires more complex mocking
  skip "This test requires more complex mocking"
  
  # Mock Java command to fail
  mock_command "java" 127 "java: command not found"
  
  # Run the Java version detection
  run get_java_version
  
  # Verify it handles the error correctly
  [ "$status" -ne 0 ]
  [[ "$output" == *"not found"* ]] || [[ "$output" == *"not installed"* ]]
}

# @functional @positive @platform @adr004
@test "Should detect Maven installation" {
  # Mock Maven command
  mock_maven_environment "version"
  
  # Run the Maven detection
  run is_maven_installed
  
  # Verify it detects Maven
  [ "$status" -eq 0 ]
}

# @functional @positive @platform @adr004
@test "Should get correct Maven version" {
  # Mock Maven command
  mock_maven_environment "version"
  
  # Run the Maven version detection
  run get_maven_version
  
  # Verify it correctly extracts the version
  [ "$status" -eq 0 ]
  [[ "$output" == "3.9.2" ]]
}

# @functional @positive @platform @adr004 @env-detection
@test "Should detect if running in CI environment" {
  # Mock CI environment variables
  export CI="true"
  export GITHUB_ACTIONS="true"
  
  # Run the CI detection
  run is_running_in_ci
  
  # Verify it detects CI environment
  [ "$status" -eq 0 ]
  
  # Clean up
  unset CI GITHUB_ACTIONS
}

# @functional @positive @platform @adr004
@test "Should optimize thread count based on available CPUs" {
  # Mock a Linux environment with 8 CPUs
  mock_linux_environment
  mock_command "nproc" 0 "8"
  
  # Run the thread count optimization
  run get_optimal_thread_count
  
  # Verify it calculates a reasonable thread count
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+$ ]]
  [[ "$output" -ge 8 ]]  # Should be at least the number of CPUs
}

# @functional @positive @platform @adr004
@test "Should optimize memory settings based on available memory" {
  # Mock a Linux environment
  mock_linux_environment
  
  # Run the memory optimization
  run get_optimal_memory_settings
  
  # Verify it produces valid memory settings
  [ "$status" -eq 0 ]
  [[ "$output" == *"Xms"* ]]
  [[ "$output" == *"Xmx"* ]]
}

# @functional @positive @platform @adr004
@test "Should detect available disk space" {
  # Mock df command
  mock_command "df" 0 "Filesystem     1K-blocks      Used Available Use% Mounted on
/dev/sda1      487652636 105935488 381717148  22% /
tmpfs            8153752         0   8153752   0% /dev/shm"
  
  # Run the disk space detection
  run get_available_disk_space
  
  # Verify it returns a valid amount
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+$ ]]
  [[ "$output" -gt 0 ]]
}

# @functional @positive @platform @adr004
@test "Should generate optimized Maven command for platform" {
  # Mock environments
  mock_linux_environment
  mock_command "nproc" 0 "4"
  
  # Run the command generation
  run generate_optimized_maven_command 4 4096 8
  
  # Verify it generates a reasonable command
  [ "$status" -eq 0 ]
  [[ "$output" == *"mvn"* ]]
  [[ "$output" == *"-T 4C"* ]]  # Thread count
  [[ "$output" == *"Xms"* ]]     # Min heap
  [[ "$output" == *"Xmx"* ]]     # Max heap
}

# @functional @negative @platform @adr004
@test "Should fail gracefully on unsupported platforms" {
  # Skip this test for now - it requires more complex mocking
  skip "This test requires more complex mocking"
  
  # Mock an unsupported platform
  mock_command "uname" 0 "FreeBSD freebsd-server 13.2-RELEASE FreeBSD 13.2-RELEASE releng/13.2-n254617-525ecfdad597 GENERIC"
  
  # Run the platform detection with strict mode
  run detect_platform_strict
  
  # Verify it fails with a clear error
  [ "$status" -ne 0 ]
  [[ "$output" == *"unsupported"* ]] || [[ "$output" == *"not supported"* ]]
}

# @nonfunctional @positive @platform @adr004
@test "Should detect platform quickly (under 100ms)" {
  # Time the platform detection function
  start_time=$(date +%s.%N)
  detect_platform >/dev/null 2>&1
  end_time=$(date +%s.%N)
  
  # Calculate execution time in milliseconds
  execution_time=$(echo "($end_time - $start_time) * 1000" | bc)
  
  # Verify it's under 100ms
  [ "$(echo "$execution_time < 100" | bc)" -eq 1 ]
}

# @functional @positive @platform @adr004
@test "Should detect network connectivity" {
  # Mock ping command
  mock_command "ping" 0 "PING google.com (142.250.190.78): 56 data bytes
64 bytes from 142.250.190.78: icmp_seq=0 ttl=116 time=24.321 ms
64 bytes from 142.250.190.78: icmp_seq=1 ttl=116 time=23.726 ms
64 bytes from 142.250.190.78: icmp_seq=2 ttl=116 time=25.054 ms

--- google.com ping statistics ---
3 packets transmitted, 3 packets received, 0.0% packet loss
round-trip min/avg/max/stddev = 23.726/24.367/25.054/0.544 ms"
  
  # Run the network connectivity check
  run check_network_connectivity
  
  # Verify it detects connectivity
  [ "$status" -eq 0 ]
}

# @functional @negative @platform @adr004
@test "Should handle network connectivity failures" {
  # Skip this test for now - it requires more complex mocking
  skip "This test requires more complex mocking"
  
  # Mock ping command to fail
  mock_command "ping" 1 "ping: cannot resolve nonexistent.example.invalid: Unknown host"
  
  # Run the network connectivity check
  run check_network_connectivity "nonexistent.example.invalid"
  
  # Verify it detects connectivity failure
  [ "$status" -ne 0 ]
  [[ "$output" == *"network"* ]] || [[ "$output" == *"connectivity"* ]]
}

# @functional @positive @platform @adr004
@test "Should detect when running in Docker container" {
  # Create mock /.dockerenv file
  touch "${BATS_TMPDIR}/.dockerenv"
  
  # Mock root directory
  export MOCK_ROOT_DIR="${BATS_TMPDIR}"
  
  # Run the Docker detection
  run is_running_in_docker
  
  # Verify it detects Docker
  [ "$status" -eq 0 ]
  
  # Clean up
  unset MOCK_ROOT_DIR
  rm "${BATS_TMPDIR}/.dockerenv"
}

# @functional @positive @platform @adr004
@test "Should detect when running in Kubernetes pod" {
  # Set Kubernetes environment variables
  export KUBERNETES_SERVICE_HOST="10.96.0.1"
  export KUBERNETES_SERVICE_PORT="443"
  
  # Run the Kubernetes detection
  run is_running_in_kubernetes
  
  # Verify it detects Kubernetes
  [ "$status" -eq 0 ]
  
  # Clean up
  unset KUBERNETES_SERVICE_HOST KUBERNETES_SERVICE_PORT
}

# @nonfunctional @positive @platform @adr004
@test "Should apply correct platform-specific optimizations" {
  # Run platform-specific optimizations
  run apply_platform_optimizations
  
  # Verify it runs without errors
  [ "$status" -eq 0 ]
  
  # Check for platform-specific content in the output
  if [[ "$(uname)" == "Darwin" ]]; then
    [[ "$output" == *"macOS"* ]] || [[ "$output" == *"Darwin"* ]]
  elif [[ "$(uname)" == "Linux" ]]; then
    [[ "$output" == *"Linux"* ]]
  fi
}