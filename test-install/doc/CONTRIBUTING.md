# Contributing to MVNimble

Thank you for your interest in contributing to MVNimble! This document provides guidelines for contributing to the project, including coding standards and development processes.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Environment](#development-environment)
4. [Coding Conventions](#coding-conventions)
5. [Testing Guidelines](#testing-guidelines)
6. [Pull Request Process](#pull-request-process)
7. [Architectural Decision Records](#architectural-decision-records)

## Code of Conduct

We expect all contributors to be respectful and considerate of others. Please be constructive in code reviews and discussions.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR-USERNAME/mvnimble.git`
3. Create a branch for your changes: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Run tests to ensure everything works
6. Submit a pull request

## Development Environment

MVNimble requires:
- Bash 3.2 or newer
- Maven 3.x
- Java 8 or newer
- BATS testing framework

### Setup

1. Install dependencies:
   ```bash
   # Install BATS
   git clone https://github.com/bats-core/bats-core.git
   cd bats-core
   ./install.sh /usr/local
   ```

2. Verify installation:
   ```bash
   bats --version
   ```

3. Run MVNimble tests:
   ```bash
   ./test/run_bats_tests.sh
   ```

## Coding Conventions

### File and Directory Naming

- **Directories**: Use lowercase with hyphens (`kebab-case`)
  - Example: `test-fixtures/`, `functional-tests/`

- **Scripts**: Use lowercase with underscores (`snake_case`) and `.sh` extension
  - Example: `environment_detection.sh`, `test_analysis.sh`

- **Documentation**: Use UPPERCASE with hyphens
  - Example: `CONTRIBUTING.md`, `CODE-OF-CONDUCT.md`

### Bash Coding Standards

- Always use `#!/usr/bin/env bash` shebang
- Use 2-space indentation
- Maximum line length of 80 characters
- Always quote variable references: `"$variable"` not `$variable`
- Use `function` keyword for function declarations
- Add descriptive comments for complex logic

### Function Naming and Style

- Use `snake_case` for function names
- Follow verb-noun naming pattern: `get_cpu_info()`, `analyze_environment()`
- Functions should do one thing well
- Include function documentation comments:

```bash
## Brief description of what the function does
#
# Detailed explanation of the function's purpose and behavior
#
# Parameters:
#   $1 - description of first parameter
#   $2 - description of second parameter
#
# Returns:
#   Description of what the function returns
#
# Example:
#   result=$(function_name "param1" "param2")
function function_name() {
  # Implementation
}
```

### Variable Conventions

- Use `snake_case` for variable names
- Always use `local` for function-scoped variables
- Use UPPERCASE for constants
- Use descriptive variable names

```bash
# Constants
readonly MAX_RETRY_COUNT=5

function process_data() {
  local input_file="$1"
  local output_format="$2"
  local temp_directory
  
  temp_directory=$(mktemp -d)
  # Implementation
}
```

### Error Handling

- Use `set -e` at the beginning of scripts
- Handle errors explicitly when needed
- Provide meaningful error messages
- Use cleanup traps for proper resource management

```bash
set -e

function cleanup() {
  # Cleanup resources
  rm -rf "$temp_dir"
}

trap cleanup EXIT

function handle_error() {
  echo "Error: $1" >&2
  exit 1
}

# Example usage
if ! command -v java &>/dev/null; then
  handle_error "Java is not installed"
fi
```

## Testing Guidelines

- Every feature should have corresponding tests
- All tests must pass before pull requests are merged
- Use the established test taxonomy (see [TESTING.md](./TESTING.md))
- Write both positive and negative tests

## Pull Request Process

1. Update documentation for any changed functionality
2. Update the CHANGELOG.md file with details of changes
3. Run all tests and ensure they pass
4. Submit the pull request with a clear description of the changes
5. Address any feedback from code reviews

## Architectural Decision Records

When making significant architectural changes, create or update an Architectural Decision Record (ADR) in the `doc/adr/` directory.

### ADR Format

```markdown
# N. Title of ADR

## Status
[Proposed, Accepted, Deprecated, Superseded]

## Context
[Description of the problem and context]

## Decision
[Description of the decision made]

## Consequences
[Description of the consequences of this decision]
```

### ADR Process

1. Create a new file in `doc/adr/` with the next available number
2. Fill in the ADR template
3. Submit the ADR as part of your pull request
4. Update the ADR status after review

---
Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license