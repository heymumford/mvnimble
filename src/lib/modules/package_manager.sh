#!/bin/bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# package_manager.sh
# MVNimble - Package manager detection and utilities
#
# This module provides functions for detecting and interacting with
# various package managers (apt, brew, yum, etc.) for dependency
# installation and management.

# Source constants if not already loaded
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=constants.sh
source "${SCRIPT_DIR}/constants.sh"

# Detect available package manager
detect_package_manager() {
  if command -v apt-get >/dev/null 2>&1; then
    echo "apt"
  elif command -v brew >/dev/null 2>&1; then
    echo "brew"
  elif command -v dnf >/dev/null 2>&1; then
    echo "dnf"
  elif command -v yum >/dev/null 2>&1; then
    echo "yum"
  elif command -v pacman >/dev/null 2>&1; then
    echo "pacman"
  elif command -v zypper >/dev/null 2>&1; then
    echo "zypper"
  else
    echo "unknown"
  fi
}

# Check if a package is installed via the detected package manager
is_package_installed() {
  local pkg="$1"
  local pkg_manager
  
  pkg_manager=$(detect_package_manager)
  
  case "$pkg_manager" in
    apt)
      dpkg -s "$pkg" >/dev/null 2>&1
      return $?
      ;;
    brew)
      brew list "$pkg" >/dev/null 2>&1
      return $?
      ;;
    dnf|yum)
      rpm -q "$pkg" >/dev/null 2>&1
      return $?
      ;;
    pacman)
      pacman -Qi "$pkg" >/dev/null 2>&1
      return $?
      ;;
    zypper)
      rpm -q "$pkg" >/dev/null 2>&1
      return $?
      ;;
    *)
      # If unknown package manager, assume not installed
      return 1
      ;;
  esac
}

# Get installation command for a package
get_install_command() {
  local pkg="$1"
  local pkg_manager
  
  pkg_manager=$(detect_package_manager)
  
  case "$pkg_manager" in
    apt)
      echo "sudo apt-get update && sudo apt-get install -y $pkg"
      ;;
    brew)
      echo "brew install $pkg"
      ;;
    dnf)
      echo "sudo dnf install -y $pkg"
      ;;
    yum)
      echo "sudo yum install -y $pkg"
      ;;
    pacman)
      echo "sudo pacman -S --noconfirm $pkg"
      ;;
    zypper)
      echo "sudo zypper install -y $pkg"
      ;;
    *)
      # If unknown package manager, provide general guidance
      echo "Please install $pkg using your system's package manager"
      ;;
  esac
}

# Attempt to install a package
install_package() {
  local pkg="$1"
  local auto_install="${2:-false}"
  local pkg_manager
  local install_cmd
  
  pkg_manager=$(detect_package_manager)
  
  if [ "$pkg_manager" = "unknown" ]; then
    echo "Unable to detect package manager." >&2
    echo "Please install $pkg manually." >&2
    return 1
  fi
  
  install_cmd=$(get_install_command "$pkg")
  
  if [ "$auto_install" = "true" ]; then
    echo "Installing $pkg using $pkg_manager..."
    eval "$install_cmd"
    if [ $? -ne 0 ]; then
      echo "Failed to install $pkg. Please install it manually." >&2
      return 1
    fi
    echo "$pkg installed successfully."
    return 0
  else
    echo "Package $pkg is not installed."
    echo "To install, run: $install_cmd"
    return 1
  fi
}

# Check for a package and offer to install it
check_and_offer_install() {
  local pkg="$1"
  local required="${2:-false}"
  local auto_install="${3:-false}"
  
  if is_package_installed "$pkg"; then
    return 0
  fi
  
  if [ "$auto_install" = "true" ]; then
    install_package "$pkg" true
    return $?
  fi
  
  echo "$pkg is not installed."
  
  # If non-interactive mode or not requiring confirmation
  if [ -n "${MVNIMBLE_NONINTERACTIVE:-}" ]; then
    install_package "$pkg" false
    if [ "$required" = "true" ]; then
      return 1
    else
      return 0
    fi
  fi
  
  # Interactive mode
  read -r -p "Would you like to install it now? [y/N] " response
  case "$response" in
    [yY][eE][sS]|[yY]) 
      install_package "$pkg" true
      return $?
      ;;
    *)
      if [ "$required" = "true" ]; then
        echo "Required package $pkg must be installed to continue." >&2
        return 1
      else
        echo "Optional package $pkg will not be installed."
        return 0
      fi
      ;;
  esac
}

# Get the system update command
get_update_command() {
  local pkg_manager
  
  pkg_manager=$(detect_package_manager)
  
  case "$pkg_manager" in
    apt)
      echo "sudo apt-get update"
      ;;
    brew)
      echo "brew update"
      ;;
    dnf)
      echo "sudo dnf check-update"
      ;;
    yum)
      echo "sudo yum check-update"
      ;;
    pacman)
      echo "sudo pacman -Sy"
      ;;
    zypper)
      echo "sudo zypper refresh"
      ;;
    *)
      # If unknown package manager, provide empty command
      echo ""
      ;;
  esac
}

# Install shellcheck if not already installed
install_shellcheck() {
  check_and_offer_install "shellcheck" true "$1"
}

# Install bashate if not already installed
install_bashate() {
  local pkg_manager
  pkg_manager=$(detect_package_manager)
  
  if command -v bashate >/dev/null 2>&1; then
    return 0
  fi
  
  # Check if pip/pip3 is available
  if command -v pip3 >/dev/null 2>&1; then
    pip_cmd="pip3"
  elif command -v pip >/dev/null 2>&1; then
    pip_cmd="pip"
  else
    echo "Neither pip nor pip3 is available. Cannot install bashate." >&2
    echo "Please install Python and pip first, then run: pip install bashate" >&2
    return 1
  fi
  
  # Ask for confirmation
  if [ -n "${MVNIMBLE_NONINTERACTIVE:-}" ]; then
    echo "Bashate is not installed. Install with: $pip_cmd install bashate" >&2
    return 1
  fi
  
  read -r -p "Bashate is not installed. Would you like to install it with $pip_cmd? [y/N] " response
  case "$response" in
    [yY][eE][sS]|[yY]) 
      echo "Installing bashate..."
      if [ "$pkg_manager" = "apt" ] || [ "$pkg_manager" = "dnf" ] || [ "$pkg_manager" = "yum" ]; then
        $pip_cmd install --user bashate
      else
        $pip_cmd install bashate
      fi
      
      if [ $? -ne 0 ]; then
        echo "Failed to install bashate. Please install it manually." >&2
        return 1
      fi
      echo "Bashate installed successfully."
      return 0
      ;;
    *)
      echo "Bashate will not be installed."
      return 1
      ;;
  esac
}