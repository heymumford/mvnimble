#!/usr/bin/env bash
# MVNimble Installer
# Installs MVNimble to make it available system-wide
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license

set -e

# Get current working directory
CWD="$(pwd)"

# Define color output
COLOR_RED="\033[0;31m"
COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_BLUE="\033[0;34m"
COLOR_BOLD="\033[1m"
COLOR_RESET="\033[0m"

# Print styled message
function print_header() {
  echo -e "${COLOR_BOLD}${COLOR_BLUE}=== $1 ===${COLOR_RESET}"
}

function print_success() {
  echo -e "${COLOR_GREEN}✓ $1${COLOR_RESET}"
}

function print_error() {
  echo -e "${COLOR_RED}✗ $1${COLOR_RESET}"
}

function print_warning() {
  echo -e "${COLOR_YELLOW}! $1${COLOR_RESET}"
}

# Installation options
DEFAULT_INSTALL_DIR="${CWD}/target/mvnimble"
LOCAL_BIN_DIR="${CWD}/target/bin"
SYSTEM_BIN_DIR="/usr/local/bin"
ZSH_COMPLETION_DIR="${CWD}/target/zsh/completions"

# Parse command line arguments
INSTALL_METHOD="target"  # default to target installation
INTERACTIVE=true
SKIP_TESTS=false
TEST_TAGS=""
TEST_REPORT=false

# Print welcome message
print_header "MVNimble Installer"
echo

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --system)
      print_warning "System-wide installation requested"
      if [[ "$EUID" -ne 0 ]]; then
        print_error "System-wide installation requires root privileges"
        print_warning "Falling back to target installation method"
      else
        INSTALL_METHOD="system"
      fi
      shift
      ;;
    --local)
      INSTALL_METHOD="target"
      print_success "Using target installation method"
      shift
      ;;
    --non-interactive)
      INTERACTIVE=false
      shift
      ;;
    --skip-tests)
      SKIP_TESTS=true
      shift
      ;;
    --test-tags=*)
      TEST_TAGS="${1#*=}"
      shift
      ;;
    --test-report)
      TEST_REPORT=true
      shift
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo
      echo "Options:"
      echo "  --system         Install MVNimble system-wide (requires root)"
      echo "  --local          Install MVNimble to local target directory (default)"
      echo "  --non-interactive Skip interactive prompts"
      echo "  --skip-tests     Skip running tests after installation"
      echo "  --test-tags=TAGS Run only tests with specific tags"
      echo "  --test-report    Generate test report"
      echo "  --help           Show this help message"
      exit 0
      ;;
    *)
      print_error "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Select appropriate installation directory
if [[ "$INSTALL_METHOD" == "system" ]]; then
  INSTALL_DIR="/usr/local/opt/mvnimble"
  BIN_DIR="$SYSTEM_BIN_DIR"
  print_warning "Installing MVNimble system-wide to $INSTALL_DIR"
else
  INSTALL_DIR="$DEFAULT_INSTALL_DIR"
  BIN_DIR="$LOCAL_BIN_DIR"
  print_success "Installing MVNimble to $INSTALL_DIR"
fi

# Clean up existing target directory if using target installation
if [[ "$INSTALL_METHOD" == "target" && -d "${CWD}/target" ]]; then
  print_header "Cleaning Existing Installation"
  rm -rf "${CWD}/target"
  print_success "Target directory cleaned"
fi

# Create necessary directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/bin"
mkdir -p "$INSTALL_DIR/lib"
mkdir -p "$INSTALL_DIR/doc"
mkdir -p "$INSTALL_DIR/examples"
mkdir -p "$BIN_DIR"
mkdir -p "$ZSH_COMPLETION_DIR"

# Install files
print_header "Installing Files"

# Copy core files
echo "Copying library files..."
cp -r "${CWD}/lib/"* "$INSTALL_DIR/lib/" 2>/dev/null || true

# Copy bin scripts
echo "Copying executable scripts..."
cp -r "${CWD}/bin/"* "$INSTALL_DIR/bin/" 2>/dev/null || true

# Copy documentation
echo "Copying documentation..."
cp -r "${CWD}/doc/"* "$INSTALL_DIR/doc/" 2>/dev/null || true

# Copy examples
echo "Copying examples..."
cp -r "${CWD}/examples/"* "$INSTALL_DIR/examples/" 2>/dev/null || true

# Copy readme files
cp "${CWD}/README.md" "$INSTALL_DIR/" 2>/dev/null || true
cp "${CWD}/STRUCTURE.md" "$INSTALL_DIR/" 2>/dev/null || true
cp "${CWD}/CLAUDE.md" "$INSTALL_DIR/" 2>/dev/null || true

# Make scripts executable
print_header "Setting Permissions"
chmod +x "$INSTALL_DIR/bin/"*.sh 2>/dev/null || true
chmod +x "$INSTALL_DIR/bin/mvnimble"* 2>/dev/null || true
chmod +x "$INSTALL_DIR/lib/"*.sh 2>/dev/null || true

# Create symlinks in bin directory
print_header "Creating Executable Links"
ln -sf "$INSTALL_DIR/bin/mvnimble" "$BIN_DIR/mvnimble"
ln -sf "$INSTALL_DIR/bin/mvnimble-monitor" "$BIN_DIR/mvnimble-monitor"
ln -sf "$INSTALL_DIR/bin/mvnimble-analyze" "$BIN_DIR/mvnimble-analyze"

print_success "MVNimble executables installed to $BIN_DIR"

# Set up shell completion if available
if [[ -f "${CWD}/src/completion/_mvnimble" ]]; then
  print_header "Installing Shell Completion"
  mkdir -p "$INSTALL_DIR/completion"
  cp "${CWD}/src/completion/_mvnimble" "$INSTALL_DIR/completion/"
  
  if [[ -d "$ZSH_COMPLETION_DIR" && -w "$ZSH_COMPLETION_DIR" ]]; then
    ln -sf "$INSTALL_DIR/completion/_mvnimble" "$ZSH_COMPLETION_DIR/_mvnimble"
    print_success "ZSH completion installed"
  else
    print_warning "ZSH completion not installed automatically"
    echo "To enable ZSH completion, add this to your .zshrc:"
    echo "    fpath=($INSTALL_DIR/completion \$fpath)"
    echo "    autoload -Uz compinit"
    echo "    compinit"
  fi
fi

# Run tests if not skipped
if [[ "$SKIP_TESTS" == "false" ]]; then
  print_header "Running Tests"
  
  # Check if BATS is available
  if ! command -v bats >/dev/null 2>&1; then
    print_warning "BATS (Bash Automated Testing System) not found"
    
    if [[ "$INTERACTIVE" == "true" ]]; then
      read -p "Do you want to install BATS for testing? [y/N] " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Skipping tests as BATS is not available"
        SKIP_TESTS=true
      else
        print_header "Installing BATS"
        
        # Create a temporary directory for installation
        TEMP_DIR=$(mktemp -d)
        CURRENT_DIR=$(pwd)
        cd "$TEMP_DIR" || { print_error "Failed to cd to temp directory"; exit 1; }
        
        # Clone and install BATS
        git clone https://github.com/bats-core/bats-core.git
        cd bats-core || { print_error "Failed to cd to bats-core directory"; exit 1; }
        
        # Install BATS to the target directory
        BATS_INSTALL_DIR="${CWD}/target/bats"
        mkdir -p "$BATS_INSTALL_DIR"
        ./install.sh "$BATS_INSTALL_DIR"
        
        # Add to PATH for this script
        export PATH="$BATS_INSTALL_DIR/bin:$PATH"
        
        # Clean up
        cd "$CURRENT_DIR" || { print_error "Failed to return to original directory"; exit 1; }
        rm -rf "$TEMP_DIR"
        
        print_success "BATS installed successfully to ${BATS_INSTALL_DIR}"
      fi
    else
      print_warning "Skipping tests as BATS is not available and running in non-interactive mode"
      SKIP_TESTS=true
    fi
  fi
  
  if [[ "$SKIP_TESTS" == "false" ]]; then
    # Run tests
    if [[ -f "${CWD}/test/run_bats_tests.sh" ]]; then
      print_header "Running Tests"
      
      TEST_CMD="${CWD}/test/run_bats_tests.sh"
      
      if [[ "$INTERACTIVE" == "false" ]]; then
        TEST_CMD="${TEST_CMD} --non-interactive"
      fi
      
      if [[ -n "$TEST_TAGS" ]]; then
        TEST_CMD="${TEST_CMD} --tags ${TEST_TAGS}"
      fi
      
      if [[ "$TEST_REPORT" == "true" ]]; then
        TEST_CMD="${TEST_CMD} --report markdown"
      fi
      
      # Make sure test script is executable
      chmod +x "${CWD}/test/run_bats_tests.sh"
      
      # Run tests
      eval "$TEST_CMD"
      
      print_success "Tests completed successfully"
    else
      print_warning "Test script not found at ${CWD}/test/run_bats_tests.sh"
    fi
  fi
fi

# Print installation summary
print_header "Installation Complete"

if [[ "$INSTALL_METHOD" == "target" ]]; then
  echo "MVNimble installed to: $INSTALL_DIR"
  echo
  echo "To use MVNimble from this installation, run:"
  echo "    export PATH=\"$BIN_DIR:\$PATH\""
  
  if [[ -d "${CWD}/target/bats/bin" ]]; then
    echo "    export PATH=\"${CWD}/target/bats/bin:\$PATH\""
  fi
else
  echo "MVNimble installed system-wide to: $INSTALL_DIR"
  echo "Executable scripts installed to: $BIN_DIR"
fi

echo
echo "Try the following commands:"
echo "    mvnimble --help"
echo "    mvnimble verify"
echo "    mvnimble-monitor --help"
echo "    mvnimble-analyze --help"
echo
echo "For usage examples, see: $INSTALL_DIR/examples/README.md"