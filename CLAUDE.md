# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build/Test/Lint Commands

- Run all tests: `./test/run_bats_tests.sh`
- Run specific test: `./test/run_bats_tests.sh --test-dir ./test/bats/functional/adr001_shell_architecture.bats` 
- Run tests by tag: `./test/run_bats_tests.sh --tags functional,positive`
- Quick test summary: `./test/test_summary.sh`
- Generate test report: `./test/run_bats_tests.sh --report markdown|json|tap|html|junit`
- Run with verbose output: `./test/run_bats_tests.sh --verbose`
- Stop on first failure: `./test/run_bats_tests.sh --fail-fast`
- Lint shell scripts: Use shellcheck (referenced in src/lib/modules/shellcheck_wrapper.sh)

## Code Style Guidelines

- **File naming**: Scripts use snake_case with .sh extension
- **Directories**: Use kebab-case for directories
- **Documentation**: Use UPPERCASE for documentation files
- **Shell**: Use `#!/usr/bin/env bash`, with minimum Bash 3.2+ compatibility
- **Constants**: UPPERCASE with meaningful names
- **Functions**: snake_case with verb-noun structure
- **Variables**: snake_case, explicitly declare `local` for function variables
- **Error handling**: Use `set -e`, provide meaningful messages
- **Documentation**: Each function needs comment block with purpose, parameters, returns
- **Testing**: All changes should have BATS tests, preferably with @tags and positive/negative cases
- **Platform compatibility**: Use portable shell constructs, test on macOS and Ubuntu

---
Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
