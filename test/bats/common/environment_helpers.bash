#!/usr/bin/env bash
# environment_helpers.bash
# Helper functions for simulating different environments

# Comment this out for now as it's causing issues
# load ../test_helper

# Mock environment for macOS
mock_macos_environment() {
  mock_command "uname" 0 "$(cat "${FIXTURE_DIR}/platform/macos_uname.txt")"
  mock_command "system_profiler" 0 "$(cat "${FIXTURE_DIR}/platform/macos_system_profiler.txt")"
}

# Mock environment for Linux
mock_linux_environment() {
  mock_command "uname" 0 "$(cat "${FIXTURE_DIR}/platform/linux_uname.txt")"
  mock_command "lscpu" 0 "$(cat "${FIXTURE_DIR}/platform/linux_lscpu.txt")"
  
  # Create mock /proc/meminfo
  mkdir -p "${BATS_TMPDIR}/proc"
  cp "${FIXTURE_DIR}/platform/linux_proc_meminfo.txt" "${BATS_TMPDIR}/proc/meminfo"
  
  # Override environment to point to mock /proc
  export MOCK_PROC_DIR="${BATS_TMPDIR}/proc"
}

# Mock for container detection
mock_container_environment() {
  # Create mock /.dockerenv file
  touch "${BATS_TMPDIR}/.dockerenv"
  
  # Create mock cgroups file
  mkdir -p "${BATS_TMPDIR}/proc/self"
  echo "cgroup:/docker/7b3db0afad48c1fd8fb97579e9efc80d88c58d3844f0102c455a33778e32e042" > "${BATS_TMPDIR}/proc/self/cgroup"
  
  # Set kubernetes env variables
  export KUBERNETES_SERVICE_HOST="10.96.0.1"
  export KUBERNETES_SERVICE_PORT="443"
  
  # Override environment to point to mock /proc
  export MOCK_PROC_DIR="${BATS_TMPDIR}/proc"
  export MOCK_ROOT_DIR="${BATS_TMPDIR}"
}

# Mock for Maven execution
mock_maven_environment() {
  local scenario="$1"  # success, failure, parallel, etc.
  
  case "$scenario" in
    success)
      mock_command "mvn" 0 "$(cat "${FIXTURE_DIR}/maven/successful_build.log")"
      ;;
    failure)
      mock_command "mvn" 1 "$(cat "${FIXTURE_DIR}/maven/failed_build.log")"
      ;;
    parallel)
      mock_command "mvn" 0 "$(cat "${FIXTURE_DIR}/maven/parallel_test_output.log")"
      ;;
    thread_safe)
      mock_command "mvn" 0 "$(cat "${FIXTURE_DIR}/maven/thread_safe_test_output.log")"
      ;;
    thread_unsafe)
      mock_command "mvn" 1 "$(cat "${FIXTURE_DIR}/maven/thread_unsafe_test_output.log")"
      ;;
    version)
      mock_command "mvn" 0 "$(cat "${FIXTURE_DIR}/maven/mvn_version_output.log")"
      ;;
    dependency)
      mock_command "mvn" 0 "$(cat "${FIXTURE_DIR}/maven/dependency_tree.log")"
      ;;
    benchmark)
      mock_command "mvn" 0 "$(cat "${FIXTURE_DIR}/maven/memory_benchmark.log")"
      ;;
    *)
      echo "Unknown Maven scenario: $scenario" >&2
      return 1
      ;;
  esac
}

# Clean up environment mocks
cleanup_environment_mocks() {
  # Clean up mock commands
  unmock_command "uname"
  unmock_command "system_profiler"
  unmock_command "lscpu"
  unmock_command "mvn"
  
  # Clean up environment variables
  unset KUBERNETES_SERVICE_HOST
  unset KUBERNETES_SERVICE_PORT
  unset MOCK_PROC_DIR
  unset MOCK_ROOT_DIR
  
  # Clean up temporary files and directories
  rm -rf "${BATS_TMPDIR}/proc"
  rm -f "${BATS_TMPDIR}/.dockerenv"
}

# Create a mock file with given content
create_mock_file() {
  local path="$1"
  local content="$2"
  
  # Ensure the directory exists
  mkdir -p "$(dirname "${BATS_TMPDIR}${path}")"
  
  # Create the mock file
  echo "$content" > "${BATS_TMPDIR}${path}"
}

# Get CPU count for the current environment
get_cpu_count() {
  local cpu_count
  
  if [[ "$(uname)" == "Darwin" ]]; then
    cpu_count=$(sysctl -n hw.ncpu)
  else
    cpu_count=$(nproc)
  fi
  
  echo "$cpu_count"
}

# Get memory info in MB
get_memory_info() {
  local total_memory
  
  if [[ "$(uname)" == "Darwin" ]]; then
    # On macOS, return total physical memory in MB
    total_memory=$(($(sysctl -n hw.memsize) / 1024 / 1024))
  else
    # On Linux, return MemTotal from /proc/meminfo in MB
    total_memory=$(($(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024))
  fi
  
  echo "$total_memory"
}