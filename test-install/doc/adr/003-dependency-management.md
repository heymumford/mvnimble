# ADR 003: Dependency Management

## Status

Accepted

## Context

MVNimble depends on several external tools and environment conditions to function correctly. Without proper dependency management, users may encounter cryptic errors or unexpected behavior when running the tool in environments that lack necessary dependencies.

Key dependency challenges include:

1. **External Command Dependencies**: MVNimble relies on several external commands (Java, Maven, etc.)
2. **Version Requirements**: Some dependencies have minimum version requirements
3. **Platform-Specific Tools**: Different platforms may have different tools available
4. **Optional vs. Required Dependencies**: Some dependencies are essential, while others enable optional features
5. **Environment Requirements**: MVNimble has certain requirements for the execution environment (memory, disk space, etc.)
6. **Missing Error Messages**: Without proper checks, missing dependencies lead to confusing errors deep in execution

We need a comprehensive approach to manage these dependencies, ensure they're available, and provide clear guidance when they're not.

## Decision

We will implement a robust dependency management system with the following components:

1. **Centralized Dependency Checking**: Create a dedicated module (`dependency_check.sh`) that handles all dependency validation.

2. **Fail-Fast Approach**: Check all critical dependencies at the start of execution and exit with clear error messages if requirements aren't met.

3. **Dependency Categories**:
   - **Essential Commands**: External commands required for core functionality
   - **Runtime Environment**: Shell, CPU, memory, and disk requirements
   - **Maven Project**: Validation of Maven project structure
   - **Optional Tools**: Tools that enhance functionality but aren't required

4. **Version Validation**: Check minimum versions for critical tools like Java and Maven.

5. **Package Manager Detection**: Detect available package managers (apt, brew) to provide installation instructions.

6. **Self-Healing Capabilities**: For certain dependencies (like ShellCheck), offer to install them automatically if the appropriate package manager is available.

7. **Deferred Validation**: For dependencies only needed by specific features, validate them just before use.

## Consequences

### Positive

- **Improved User Experience**: Clear error messages with actionable guidance
- **Reduced Support Burden**: Fewer issues from missing dependencies
- **Better First-Run Experience**: Users know immediately what they need to install
- **Self-Documentation**: Dependency checks document the tool's requirements
- **Graceful Degradation**: Optional features can be disabled when dependencies aren't available

### Negative

- **Startup Overhead**: Additional checks add time to startup
- **Maintenance Burden**: Need to keep dependency checks updated as requirements change
- **False Positives**: Might reject configurations that would actually work

### Neutral

- **User Control**: Limits how users can run the tool but improves reliability
- **Strict Requirements**: May frustrate users who want to run in unsupported environments

## Implementation Notes

1. **Core Dependency Check Function**:
```bash
function verify_essential_commands() {
  local missing_commands=()
  local essential_commands=("grep" "awk" "sed" "bc" "date" "mkdir" "chmod" "cp")
  
  for cmd in "${essential_commands[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing_commands+=("$cmd")
    fi
  done
  
  if [[ ${#missing_commands[@]} -gt 0 ]]; then
    echo "ERROR: Missing essential commands: ${missing_commands[*]}" >&2
    echo "Please install these utilities before running MVNimble." >&2
    return 1
  fi
  
  return 0
}
```

2. **Version Check Function**:
```bash
function verify_java_installation() {
  if ! command -v java >/dev/null 2>&1; then
    echo "ERROR: Java is not installed or not in PATH" >&2
    echo "MVNimble requires Java $MINIMUM_JAVA_VERSION or higher" >&2
    echo "Please install Java and ensure it's available in your PATH" >&2
    return 1
  fi
  
  # Get Java version
  local java_version
  java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
  
  # For Java 1.8, convert to 8
  if [[ "$java_version" == "1."* ]]; then
    java_version=$(echo "$java_version" | cut -d'.' -f2)
  fi
  
  # Check version against minimum
  if [[ -z "$java_version" || "$java_version" -lt "$MINIMUM_JAVA_VERSION" ]]; then
    echo "ERROR: Java version $java_version is below minimum required version $MINIMUM_JAVA_VERSION" >&2
    echo "Please upgrade Java to version $MINIMUM_JAVA_VERSION or higher" >&2
    return 1
  fi
  
  return 0
}
```

3. **Package Manager Detection**:
```bash
function detect_package_manager() {
  if command -v apt-get >/dev/null 2>&1; then
    echo "apt"
  elif command -v brew >/dev/null 2>&1; then
    echo "brew"
  elif command -v yum >/dev/null 2>&1; then
    echo "yum"
  else
    echo "unknown"
  fi
}
```

4. **Installation Instructions**:
```bash
function provide_installation_instructions() {
  local package="$1"
  local pkg_manager=$(detect_package_manager)
  
  echo "Please install $package using one of the following methods:"
  
  case "$pkg_manager" in
    apt)
      echo "  sudo apt-get update && sudo apt-get install -y $package"
      ;;
    brew)
      echo "  brew install $package"
      ;;
    yum)
      echo "  sudo yum install -y $package"
      ;;
    *)
      echo "  Please install $package using your system's package manager"
      ;;
  esac
}
```

5. **Main Verification Function**:
```bash
function verify_all_dependencies() {
  local results_dir="$1"
  local errors=0
  
  # Run all verification checks
  verify_shell_environment || ((errors++))
  verify_essential_commands || ((errors++))
  verify_java_installation || ((errors++))
  verify_maven_installation || ((errors++))
  verify_system_resources || ((errors++))
  verify_maven_project || ((errors++))
  verify_write_permissions "$results_dir" || ((errors++))
  verify_platform_compatibility || true # Just a warning
  
  # Return results
  if [[ "$errors" -gt 0 ]]; then
    echo "ERROR: Found $errors dependency or environment issues that must be fixed" >&2
    return 1
  fi
  
  return 0
}
```

---
Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
