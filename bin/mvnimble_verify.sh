#!/bin/bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# MVNimble verification script
# This script checks the MVNimble installation and prints basic information

set -e

echo "MVNimble Installation Verification"
echo "================================="
echo

# Check PATH setup
echo "1. Checking PATH setup..."
if command -v mvnimble >/dev/null 2>&1; then
  echo "✓ MVNimble command found in PATH"
  echo "  Location: $(which mvnimble)"
else
  echo "✗ MVNimble command not found in PATH"
  
  # Check local installation
  if [[ -f "${HOME}/.local/bin/mvnimble" ]]; then
    echo "  Found in local installation at: ${HOME}/.local/bin/mvnimble"
    echo "  To use, run: export PATH=\"\$HOME/.local/bin:\$PATH\""
  fi
fi
echo

# Check user installation
echo "2. Checking user installation..."
if [[ -d "${HOME}/.local/share/mvnimble" ]]; then
  echo "✓ Installation directory exists: ${HOME}/.local/share/mvnimble"
  
  # Check key files
  for file in "bin/mvnimble" "src/lib/mvnimble.sh" "src/lib/modules/constants.sh"; do
    if [[ -f "${HOME}/.local/share/mvnimble/${file}" ]]; then
      echo "  ✓ Found component: $file"
    else
      echo "  ✗ Missing component: $file"
    fi
  done
else
  echo "✗ Installation directory not found: ${HOME}/.local/share/mvnimble"
fi
echo

# Check BATS installation
echo "3. Checking BATS installation..."
if command -v bats >/dev/null 2>&1; then
  echo "✓ BATS is installed: $(bats --version)"
else
  echo "✗ BATS is not installed or not in PATH"
  
  # Check local installation
  if [[ -f "${HOME}/.local/bin/bats" ]]; then
    echo "  Found in local installation at: ${HOME}/.local/bin/bats"
    echo "  To use, run: export PATH=\"\$HOME/.local/bin:\$PATH\""
  fi
fi
echo

# Check test directory
echo "4. Checking test files..."
if [[ -d "${HOME}/.local/share/mvnimble/test" ]]; then
  echo "✓ Test directory exists: ${HOME}/.local/share/mvnimble/test"
  local_test_count=$(find "${HOME}/.local/share/mvnimble/test" -name "*.bats" 2>/dev/null | wc -l)
  echo "  Found ${local_test_count} BATS test files in local installation"
  
  orig_test_count=$(find "./test" -name "*.bats" 2>/dev/null | wc -l)
  echo "  Found ${orig_test_count} BATS test files in original source"
else
  echo "✗ Test directory not found in local installation"
fi
echo

# Check documentation
echo "5. Checking documentation..."
if [[ -d "${HOME}/.local/share/mvnimble/doc" ]]; then
  echo "✓ Documentation directory exists: ${HOME}/.local/share/mvnimble/doc"
  
  # Check ADR directory
  if [[ -d "${HOME}/.local/share/mvnimble/doc/adr" ]]; then
    adr_count=$(find "${HOME}/.local/share/mvnimble/doc/adr" -name "*.md" 2>/dev/null | wc -l)
    echo "  Found ${adr_count} ADR documentation files"
  else
    echo "  ✗ ADR documentation directory not found"
  fi
else
  echo "✗ Documentation directory not found"
fi
echo

echo "Installation verification complete!"
echo
echo "To use MVNimble, add the following to your ~/.bashrc or ~/.zshrc:"
echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
echo
echo "Then run: mvnimble --help"