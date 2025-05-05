# ADR 004: Cross-Platform Compatibility

## Status

Accepted

## Context

MVNimble needs to run reliably across different operating systems, primarily macOS and various Linux distributions. These platforms have subtle differences in command availability, behavior, and system structure, which can lead to compatibility issues.

Key platform differences that affect MVNimble include:

1. **Command Availability**: Different platforms may have different commands available or different versions installed
2. **Command Behavior**: The same command might behave differently across platforms (e.g., differences in `sed`, `date`, etc.)
3. **Filesystem Structure**: Path conventions and filesystem hierarchies differ
4. **System Information Access**: Methods to access system information (CPU, memory, disk) vary
5. **Container Detection**: Container detection mechanisms differ
6. **Default Tools**: Different platforms ship with different default tools

Without addressing these differences, MVNimble would likely work on one platform but fail on others, or exhibit inconsistent behavior across platforms.

## Decision

We will implement a platform abstraction approach with the following key elements:

1. **Platform Detection**: Create a reliable mechanism to detect the underlying platform.

2. **Abstraction Layer**: Implement a dedicated module (`platform_compatibility.sh`) that provides platform-agnostic functions for common operations.

3. **Platform-Specific Implementations**: For each operation requiring platform-specific code, provide separate implementations based on the detected platform.

4. **Consistent Interfaces**: Ensure that all platform-specific implementations present the same interface, regardless of platform.

5. **Fallback Mechanisms**: Where possible, provide fallback implementations for platforms that lack specific features.

6. **Minimal Assumptions**: Make minimal assumptions about the environment, and validate those assumptions at runtime.

7. **Environment Variable Control**: Allow expert users to override automatic detection through environment variables when needed.

## Consequences

### Positive

- **Wider Compatibility**: MVNimble works consistently across different platforms
- **Improved Maintainability**: Platform-specific code is isolated and easier to maintain
- **Reduced Bugs**: Fewer platform-specific bugs since differences are explicitly handled
- **Better Testing**: Clearer testing requirements for each platform
- **User Flexibility**: Expert users can override detection when needed

### Negative

- **Increased Complexity**: More code to maintain with platform-specific branches
- **Performance Impact**: Abstraction layer adds slight performance overhead
- **Development Overhead**: Features must be implemented and tested across platforms
- **Testing Requirements**: Need access to multiple platforms for proper testing

### Neutral

- **Development Practices**: Requires discipline to maintain the abstraction layer
- **Documentation Needs**: Platform-specific behaviors need to be documented

## Implementation Notes

1. **Platform Detection**:
```bash
function detect_operating_system() {
  local os_name
  os_name="$(uname)"
  
  case "$os_name" in
    Darwin)
      echo "macos"
      ;;
    Linux)
      echo "linux"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}
```

2. **CPU Information Abstraction**:
```bash
function get_cpu_count() {
  local cpu_count
  
  if [[ "$(detect_operating_system)" == "macos" ]]; then
    cpu_count=$(sysctl -n hw.ncpu)
  else
    cpu_count=$(grep -c ^processor /proc/cpuinfo)
  fi
  
  echo "$cpu_count"
}

function get_cpu_model() {
  local cpu_model
  
  if [[ "$(detect_operating_system)" == "macos" ]]; then
    cpu_model=$(sysctl -n machdep.cpu.brand_string)
  else
    cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)
  fi
  
  echo "$cpu_model"
}
```

3. **Memory Information Abstraction**:
```bash
function get_total_memory_mb() {
  local mem_total_kb mem_total_mb
  
  if [[ "$(detect_operating_system)" == "macos" ]]; then
    mem_total_kb=$(($(sysctl -n hw.memsize) / 1024))
  else
    mem_total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  fi
  
  mem_total_mb=$((mem_total_kb / 1024))
  echo "$mem_total_mb"
}
```

4. **File Editing Abstraction**:
```bash
function modify_file_in_place() {
  local file="$1"
  local search_pattern="$2"
  local replace_pattern="$3"
  
  if [[ "$(detect_operating_system)" == "macos" ]]; then
    # macOS sed requires a backup extension for in-place edits
    sed -i.mvntemp "s|$search_pattern|$replace_pattern|g" "$file"
    rm -f "${file}.mvntemp"
  else
    # Linux sed doesn't require a backup extension
    sed -i "s|$search_pattern|$replace_pattern|g" "$file"
  fi
}
```

5. **Container Detection Abstraction**:
```bash
function detect_container_environment() {
  # Check for container indicators that work across platforms
  if [ -f "/.dockerenv" ] || grep -q "docker\|lxc" /proc/1/cgroup 2>/dev/null; then
    echo "container"
  elif [ -f /proc/self/cgroup ] && grep -q "kubepods" /proc/self/cgroup; then
    echo "kubernetes"
  elif [ -d /sys/fs/cgroup/memory/system.slice/containerd.service ] || 
       [ -d /sys/fs/cgroup/memory/system.slice/docker.service ]; then
    echo "container-host"
  else
    echo "bare-metal"
  fi
}
```

6. **Command Execution with Fallbacks**:
```bash
function calculate_elapsed_time() {
  local start_time="$1"
  local end_time="$2"
  local elapsed
  
  if [[ "$(detect_operating_system)" == "macos" ]]; then
    # macOS doesn't support the same date arithmetic
    if command -v perl >/dev/null 2>&1; then
      elapsed=$(perl -e "printf \"%.2f\", $end_time - $start_time")
    else
      elapsed=$((end_time - start_time))
    fi
  else
    if command -v bc >/dev/null 2>&1; then
      elapsed=$(echo "$end_time - $start_time" | bc)
    else
      elapsed=$((end_time - start_time))
    fi
  fi
  
  echo "$elapsed"
}
```

---
Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
