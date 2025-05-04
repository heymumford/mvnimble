#!/bin/bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# simple_test.sh
# Simplified test script for verification

set -e

echo "MVNimble Test Verification"
echo "=========================="
echo

# Check system requirements
echo "Checking system requirements..."
if ! command -v bash >/dev/null 2>&1; then
  echo "Error: Bash is required but not installed."
  exit 1
fi

echo "✓ Bash is available: $(bash --version | head -n 1)"

if ! command -v grep >/dev/null 2>&1; then
  echo "Error: Grep is required but not installed."
  exit 1
fi

echo "✓ Grep is available"

# Verify directory structure
echo
echo "Verifying directory structure..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

required_dirs=(
  "src/lib"
  "src/lib/modules"
  "src/completion"
  "doc"
  "test"
  "examples"
)

for dir in "${required_dirs[@]}"; do
  if [ ! -d "${PROJECT_ROOT}/${dir}" ]; then
    echo "Error: Required directory ${dir} not found."
    exit 1
  fi
  echo "✓ Directory ${dir} exists"
done

# Verify key files
echo
echo "Verifying key files..."
required_files=(
  "bin/mvnimble"
  "src/lib/mvnimble.sh"
  "src/lib/modules/common.sh"
  "src/lib/modules/constants.sh"
  "install.sh"
  "README.md"
)

for file in "${required_files[@]}"; do
  if [ ! -f "${PROJECT_ROOT}/${file}" ]; then
    echo "Error: Required file ${file} not found."
    exit 1
  fi
  echo "✓ File ${file} exists"
done

# Run simple functionality tests
echo
echo "Running simple functionality tests..."

# Test 1: Ensure the installer has correct permissions
if [ ! -x "${PROJECT_ROOT}/install.sh" ]; then
  echo "Error: install.sh is not executable."
  exit 1
fi
echo "✓ install.sh is executable"

# Test 2: Verify constants file has expected variables
if ! grep -q "COLOR_" "${PROJECT_ROOT}/src/lib/modules/constants.sh"; then
  echo "Error: constants.sh does not contain color definitions."
  exit 1
fi
echo "✓ constants.sh contains color definitions"

# Test 3: Verify documentation exists for ADRs
adr_count=$(find "${PROJECT_ROOT}/doc/adr" -name "*.md" | wc -l)
if [ "$adr_count" -lt 1 ]; then
  echo "Error: No ADR documentation files found."
  exit 1
fi
echo "✓ Found ${adr_count} ADR documentation files"

# All tests passed
echo
echo "All tests passed successfully!"
echo "MVNimble installation verified"
echo

exit 0