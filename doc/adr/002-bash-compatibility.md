# ADR 002: Bash Compatibility

## Status

Accepted

## Context

Shell scripting environments vary widely across different operating systems and user configurations. To ensure maximum compatibility, we need to decide on a specific shell and version target for MVNimble.

Key considerations include:

1. **Shell Diversity**: Different systems may have different shells installed (bash, zsh, dash, etc.)
2. **Version Differences**: Different bash versions have different features (bash 3.2 vs bash 4+ vs bash 5+)
3. **Default Shell Variations**: macOS ships with bash 3.2 by default (due to licensing), while most Linux distributions use bash 4 or 5
4. **Feature Availability**: Newer bash versions offer helpful features like associative arrays that are not available in bash 3.2
5. **Cross-Platform Requirements**: MVNimble needs to run on macOS and various Linux distributions

We initially considered using zsh due to its feature set, but this introduces compatibility issues for systems without zsh installed, potentially limiting MVNimble's reach.

## Decision

We will use bash as the primary shell for MVNimble with the following approach:

1. **Target bash 3.2 compatible syntax** for all core functionality to provide broad compatibility.

2. **Warn but not halt** when running on older bash versions or non-bash shells, allowing users with non-standard configurations to still attempt to use the tool.

3. **Avoid bash 4+ features** such as:
   - Associative arrays (`declare -A`)
   - Case modification parameter expansion (`${var^}`, `${var,}`, etc.)
   - Negative array indices
   - The `mapfile` and `readarray` builtins
   - The `&>>` redirection operator

4. **Use POSIX-compatible syntax** where possible, favoring:
   - `[` over `[[` for basic conditionals when the additional features aren't needed
   - Standard command substitution with `$(command)` instead of backticks
   - Avoid bash-specific string operations when POSIX alternatives exist

5. **Provide fallback mechanism** for essential functionality that might be implemented differently across platforms.

## Consequences

### Positive

- **Maximum Compatibility**: Works on most Unix-like systems without requiring shell upgrades
- **No Hard Dependencies**: Users with older bash versions or alternative shells can still attempt to use the tool
- **Stable Foundation**: Bash 3.2 is a mature and stable platform
- **Cross-Platform**: Will work consistently across macOS and Linux environments

### Negative

- **Feature Limitations**: Can't use newer bash features that might simplify implementation
- **Additional Complexity**: Need to write more verbose code for some operations
- **Performance Impact**: Some operations may be less efficient without newer shell features
- **Testing Burden**: Must test across multiple bash versions

### Neutral

- **Learning Curve**: Developers may need to learn bash 3.2 constraints
- **Alternative Implementations**: May need multiple implementations for some features

## Implementation Notes

1. **Shebang Line**:
```bash
#!/usr/bin/env bash
```

2. **Version Detection with Warning**:
```bash
# Check bash version
if [[ -z "$BASH_VERSION" ]]; then
  echo "WARNING: MVNimble is designed for bash shell." >&2
  echo "Current shell doesn't appear to be bash. You may encounter issues." >&2
else
  bash_major_version="${BASH_VERSINFO[0]}"
  bash_minor_version="${BASH_VERSINFO[1]}"

  if [ "$bash_major_version" -lt 3 ] || { [ "$bash_major_version" -eq 3 ] && [ "$bash_minor_version" -lt 2 ]; }; then
    echo "WARNING: MVNimble works best with bash 3.2 or higher." >&2
    echo "Current version: $BASH_VERSION" >&2
    echo "You may encounter issues with some features." >&2
  fi
fi
```

3. **Array Handling (3.2 compatible)**:
```bash
# Instead of associative arrays
config_keys=("memory" "threads" "forks")
config_values=("256" "4" "2")

# To access by key, use a function:
function get_config_value() {
    local key="$1"
    local i
    for i in "${!config_keys[@]}"; do
        if [[ "${config_keys[$i]}" == "$key" ]]; then
            echo "${config_values[$i]}"
            return 0
        fi
    done
    return 1
}
```

4. **String Operations**:
```bash
# Instead of ${var^^} for uppercase
function to_upper() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

# Instead of ${var,,} for lowercase
function to_lower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}
```

5. **Fallback Script Path Detection**:
```bash
# Determine the installation directory in a way that works in both bash and zsh
SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"

# Resolve symlinks to find the real script location
if command -v readlink >/dev/null 2>&1; then
  SCRIPT_PATH="$(readlink -f "$SCRIPT_PATH" 2>/dev/null || echo "$SCRIPT_PATH")"
elif command -v greadlink >/dev/null 2>&1; then
  SCRIPT_PATH="$(greadlink -f "$SCRIPT_PATH" 2>/dev/null || echo "$SCRIPT_PATH")"
fi
```

---
Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
