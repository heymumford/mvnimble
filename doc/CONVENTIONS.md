# MVNimble Coding Conventions

This document outlines the coding conventions and standards used in the MVNimble project to ensure consistency, readability, and maintainability.

## File and Directory Naming

### Directories

- Use lowercase names with hyphens as separators (`kebab-case`)
- Example: `src/`, `lib/`, `test-fixtures/`
- Directories should have descriptive names indicating their purpose

### Script Files

- Use lowercase names with underscores as separators (`snake_case`)
- All executable shell scripts should end with `.sh` extension
- Modules should be named according to their functionality
- Example: `environment_detection.sh`, `test_analysis.sh`

### Documentation Files

- Use UPPERCASE for documentation files
- Example: `README.md`, `CONVENTIONS.md`, `LICENSE`

### Configuration Files

- Use lowercase names with hyphens as separators (`kebab-case`)
- Example: `config-defaults.yml`

## Code Conventions

### Shell Selection

- All scripts should start with `#!/usr/bin/env zsh` to ensure portability
- Include compatibility check for non-zsh environments
- Fall back to bash when zsh is not available

### Constants

- Use UPPERCASE for constants with underscores as separators
- Example: `MAX_WAIT_TIME`, `DEFAULT_MEMORY_SIZE`
- Declare all constants at the top of the file or in a dedicated constants module
- Use meaningful names that describe the purpose, not the value

### Functions

- Use lowercase with underscores as separators (`snake_case`)
- Name functions according to what they do, not how they do it
- Use verb-noun naming structure for clarity
- Example: `detect_container_environment()`, `analyze_test_results()`
- Functions should be self-documenting through their names
- Include parameter validation at the beginning of each function

### Variables

- Use lowercase with underscores as separators (`snake_case`)
- Use meaningful, descriptive names
- Local variables should be explicitly declared with `local`
- Example: `local memory_usage`, `local thread_count`

## Defensive Coding Practices

### Dependency Checks

- Check for required dependencies at the beginning of scripts
- Verify availability of external commands (`java`, `mvn`, etc.)
- Exit gracefully with informative error messages when dependencies are missing

### Parameter Validation

- Validate all function parameters before use
- Check for required parameters and provide defaults for optional ones
- Validate parameter types and ranges when applicable

### Error Handling

- Use `set -e` to exit on errors (with appropriate error handling)
- Consider using `trap` for cleanup operations
- Provide meaningful error messages with potential solutions
- Return appropriate exit codes

### Environment Validation

- Check for required environment variables
- Validate platform compatibility (macOS, Ubuntu)
- Ensure required directories and files exist

## Documentation Standards

### Function Documentation

- Each function should have a comment block describing:
  - Purpose of the function
  - Parameters and their expected types/formats
  - Return values or side effects
  - Example usage (for complex functions)

### Script Documentation

- Each script file should have a header comment including:
  - Brief description of purpose
  - Author information
  - Version information
  - Dependencies
  - Usage examples

### Implementation Notes

- Explain complex algorithms or unusual implementations
- Document known limitations or edge cases
- Provide context for workarounds or non-obvious solutions

## Example

```bash
#!/usr/bin/env zsh
# file_system_utils.sh - File system utility functions for MVNimble
# 
# This module provides file system operations specific to MVNimble requirements
# with proper error handling and cross-platform compatibility.

# Exit on error, but allow for proper error messages
set -e

# Constants
readonly MAX_FILE_SIZE_MB=100
readonly DEFAULT_PERMISSIONS=0755
readonly TEMP_DIRECTORY="/tmp/mvnimble"

# Check if directory exists and is writable
function validate_writable_directory() {
  local directory_path="$1"
  
  # Validate input
  if [[ -z "$directory_path" ]]; then
    echo "ERROR: Directory path not provided to validate_writable_directory" >&2
    return 1
  fi
  
  # Check if directory exists
  if [[ ! -d "$directory_path" ]]; then
    echo "ERROR: Directory does not exist: $directory_path" >&2
    return 1
  fi
  
  # Check if directory is writable
  if [[ ! -w "$directory_path" ]]; then
    echo "ERROR: Directory is not writable: $directory_path" >&2
    return 1
  }
  
  return 0
}
```

## Platform Compatibility

- Use portable shell constructs where possible
- When platform-specific code is required, use clear conditionals:

```bash
if [[ "$(uname)" == "Darwin" ]]; then
  # macOS-specific code
elif [[ "$(uname)" == "Linux" ]]; then
  # Linux-specific code
else
  echo "Unsupported platform: $(uname)" >&2
  exit 1
fi
```

- Test on both macOS and Ubuntu before committing changes
- Document any platform-specific limitations or differences

---
Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
