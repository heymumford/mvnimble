#!/bin/bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# bats_helper.sh
# MVNimble - BATS installation and integration helper
#
# This module provides functions to check for and install BATS,
# and to integrate it with the MVNimble testing framework.

# Source constants and package manager module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=constants.sh
source "${SCRIPT_DIR}/constants.sh"
# shellcheck source=package_manager.sh
source "${SCRIPT_DIR}/package_manager.sh"

# Check if BATS is installed
function check_bats_installed() {
  if command -v bats >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

# Install BATS from GitHub
function install_bats_from_github() {
  local install_dir="${1:-/usr/local}"
  local temp_dir
  
  echo "Installing BATS from GitHub..."
  
  # Create a temporary directory
  temp_dir=$(mktemp -d)
  cd "$temp_dir" || return 1
  
  # Clone and install BATS
  if ! git clone https://github.com/bats-core/bats-core.git; then
    echo "Failed to clone BATS repository" >&2
    rm -rf "$temp_dir"
    return 1
  fi
  
  cd bats-core || return 1
  
  # Check if we need sudo
  if [[ ! -w "$install_dir" ]]; then
    echo "Installation directory $install_dir requires root privileges"
    if sudo -n true 2>/dev/null; then
      sudo ./install.sh "$install_dir"
    else
      echo "Please enter your password to install BATS:"
      sudo ./install.sh "$install_dir"
    fi
  else
    ./install.sh "$install_dir"
  fi
  
  local result=$?
  
  # Clean up
  cd "$OLDPWD" || return 1
  rm -rf "$temp_dir"
  
  return $result
}

# Try to install BATS using the package manager
function install_bats_via_package_manager() {
  local pkg_manager
  pkg_manager=$(detect_package_manager)
  
  case "$pkg_manager" in
    apt)
      if check_and_offer_install "bats" true false; then
        return 0
      fi
      ;;
    brew)
      if check_and_offer_install "bats-core" true false; then
        return 0
      fi
      ;;
    yum|dnf)
      # BATS might not be in standard repos
      echo "BATS may not be available via package manager on this system"
      return 1
      ;;
    *)
      echo "Package manager installation not supported for $pkg_manager"
      return 1
      ;;
  esac
  
  return 1
}

# Install BATS with user confirmation
function install_bats_with_confirmation() {
  local response
  local home_response
  local install_dir
  
  echo "BATS is required for running tests but is not installed."
  read -r -p "Would you like to install BATS now? [y/N] " response
  
  if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    # First try package manager
    if install_bats_via_package_manager; then
      echo "BATS installed successfully via package manager"
      return 0
    fi
    
    # If package manager fails, try GitHub
    echo "Installing from package manager failed, trying GitHub..."
    
    # Determine install location
    install_dir="/usr/local"
    if [[ ! -w "$install_dir" && ! -w "/usr/local/bin" ]]; then
      read -r -p "You don't have write permissions to $install_dir. Install to ~/.local instead? [Y/n] " home_response
      if [[ ! "$home_response" =~ ^([nN][oO]|[nN])$ ]]; then
        install_dir="$HOME/.local"
        mkdir -p "$install_dir"
      fi
    fi
    
    if install_bats_from_github "$install_dir"; then
      echo "BATS installed successfully from GitHub"
      
      # Add to PATH if installed to home directory
      if [[ "$install_dir" == "$HOME/.local" ]]; then
        echo "Please add this line to your shell profile:"
        echo "export PATH=\"$HOME/.local/bin:\$PATH\""
        
        # Add to current PATH for this session
        export PATH="$HOME/.local/bin:$PATH"
      fi
      
      return 0
    else
      echo "Failed to install BATS" >&2
      return 1
    fi
  fi
  
  echo "BATS installation skipped" >&2
  return 1
}

# Run BATS tests in a directory
function run_bats_tests() {
  local test_dir="${1:-$(pwd)/test/bats}"
  local test_count
  
  if ! check_bats_installed; then
    if ! install_bats_with_confirmation; then
      echo "BATS is required to run tests" >&2
      return 1
    fi
  fi
  
  if [ ! -d "$test_dir" ]; then
    echo "Test directory $test_dir does not exist" >&2
    return 1
  fi
  
  test_count=$(find "$test_dir" -name "*.bats" | wc -l)
  
  if [ "$test_count" -eq 0 ]; then
    echo "No BATS test files found in $test_dir" >&2
    return 1
  fi
  
  echo "Running $test_count BATS test files from $test_dir"
  
  # Run the tests
  bats --tap "$test_dir"
  return $?
}