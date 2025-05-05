#!/usr/bin/env bash
# MVNimble Installer
# Installs MVNimble to make it available locally or system-wide
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license

set -e

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

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Installation options - Use more flexible defaults
HOME_DIR="${HOME}"
DEFAULT_INSTALL_DIR="${HOME_DIR}/.mvnimble"
LOCAL_BIN_DIR="${HOME_DIR}/.local/bin"
SYSTEM_BIN_DIR="/usr/local/bin"

# Parse command line arguments
INSTALL_METHOD="local"  # default to local installation
INTERACTIVE=true
SKIP_TESTS=false
TEST_TAGS=""
TEST_REPORT=false
CUSTOM_INSTALL_DIR=""

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
        print_warning "Falling back to local installation method"
      else
        INSTALL_METHOD="system"
      fi
      shift
      ;;
    --local)
      INSTALL_METHOD="local"
      print_success "Using local installation method"
      shift
      ;;
    --prefix=*)
      CUSTOM_INSTALL_DIR="${1#*=}"
      print_success "Using custom installation directory: $CUSTOM_INSTALL_DIR"
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
      echo "  --local          Install MVNimble to user's home directory (default)"
      echo "  --prefix=DIR     Install MVNimble to a custom directory"
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
elif [[ -n "$CUSTOM_INSTALL_DIR" ]]; then
  INSTALL_DIR="$CUSTOM_INSTALL_DIR"
  BIN_DIR="${CUSTOM_INSTALL_DIR}/bin"
  print_success "Installing MVNimble to custom location: $INSTALL_DIR"
else
  INSTALL_DIR="$DEFAULT_INSTALL_DIR"
  BIN_DIR="$LOCAL_BIN_DIR"
  print_success "Installing MVNimble to $INSTALL_DIR"
fi

# Create necessary directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/bin"
mkdir -p "$INSTALL_DIR/lib"
mkdir -p "$INSTALL_DIR/doc"
mkdir -p "$INSTALL_DIR/examples"
mkdir -p "$BIN_DIR"

# Install files
print_header "Installing Files"

# Copy core files
echo "Copying library files..."
cp -r "${SCRIPT_DIR}/lib/"* "$INSTALL_DIR/lib/" 2>/dev/null || true

# Copy bin scripts
echo "Copying executable scripts..."
cp -r "${SCRIPT_DIR}/bin/"* "$INSTALL_DIR/bin/" 2>/dev/null || true

# Copy documentation
echo "Copying documentation..."
cp -r "${SCRIPT_DIR}/doc/"* "$INSTALL_DIR/doc/" 2>/dev/null || true

# Copy examples
echo "Copying examples..."
cp -r "${SCRIPT_DIR}/examples/"* "$INSTALL_DIR/examples/" 2>/dev/null || true

# Copy readme files
cp "${SCRIPT_DIR}/README.md" "$INSTALL_DIR/" 2>/dev/null || true
cp "${SCRIPT_DIR}/STRUCTURE.md" "$INSTALL_DIR/" 2>/dev/null || true
cp "${SCRIPT_DIR}/CLAUDE.md" "$INSTALL_DIR/" 2>/dev/null || true

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

# Check for XMLStarlet
print_header "Checking Dependencies"

# Check if XMLStarlet is available
if ! command -v xmlstarlet >/dev/null 2>&1 && ! command -v xml >/dev/null 2>&1; then
  print_warning "XMLStarlet is required for XML processing but is not installed"
  
  if [[ "$INTERACTIVE" == "true" ]]; then
    read -p "Do you want to install XMLStarlet? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      print_header "Installing XMLStarlet"
      
      # Detect OS and install XMLStarlet
      if [[ "$(uname)" == "Darwin" ]]; then
        # macOS - check if brew is available
        if command -v brew >/dev/null 2>&1; then
          brew install xmlstarlet
        else
          print_error "Homebrew not found. Please install Homebrew first:"
          print_error "/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
          print_error "Then install XMLStarlet manually: brew install xmlstarlet"
        fi
      elif [[ "$(uname)" == "Linux" ]]; then
        # Linux - try to detect package manager
        if command -v apt-get >/dev/null 2>&1; then
          sudo apt-get update && sudo apt-get install -y xmlstarlet
        elif command -v yum >/dev/null 2>&1; then
          sudo yum install -y xmlstarlet
        elif command -v dnf >/dev/null 2>&1; then
          sudo dnf install -y xmlstarlet
        elif command -v pacman >/dev/null 2>&1; then
          sudo pacman -S --noconfirm xmlstarlet
        elif command -v zypper >/dev/null 2>&1; then
          sudo zypper install -y xmlstarlet
        else
          print_error "Cannot determine package manager. Please install XMLStarlet manually."
        fi
      else
        print_error "Unsupported OS. Please install XMLStarlet manually."
      fi
      
      # Check if installation was successful
      if command -v xmlstarlet >/dev/null 2>&1 || command -v xml >/dev/null 2>&1; then
        print_success "XMLStarlet installed successfully"
      else
        print_warning "Failed to install XMLStarlet. Some features may not work correctly."
      fi
    else
      print_warning "XMLStarlet installation skipped. Some features may not work correctly."
    fi
  else
    print_warning "Running in non-interactive mode. Skipping XMLStarlet installation."
    print_warning "Some features may not work correctly without XMLStarlet."
  fi
else
  print_success "XMLStarlet is already installed"
fi

# Set up shell completion if available
if [[ -f "${SCRIPT_DIR}/src/completion/_mvnimble" ]]; then
  print_header "Installing Shell Completion"
  mkdir -p "$INSTALL_DIR/completion"
  cp "${SCRIPT_DIR}/src/completion/_mvnimble" "$INSTALL_DIR/completion/"
  
  if [[ -d "${HOME}/.zsh/completion" && -w "${HOME}/.zsh/completion" ]]; then
    mkdir -p "${HOME}/.zsh/completion"
    ln -sf "$INSTALL_DIR/completion/_mvnimble" "${HOME}/.zsh/completion/_mvnimble"
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
        
        # Install BATS to the MVNimble installation directory
        BATS_INSTALL_DIR="${INSTALL_DIR}/tools/bats"
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
    if [[ -f "${SCRIPT_DIR}/test/run_bats_tests.sh" ]]; then
      print_header "Running Tests"
      
      TEST_CMD="${SCRIPT_DIR}/test/run_bats_tests.sh"
      
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
      chmod +x "${SCRIPT_DIR}/test/run_bats_tests.sh"
      
      # Run tests
      eval "$TEST_CMD"
      
      print_success "Tests completed successfully"
    else
      print_warning "Test script not found at ${SCRIPT_DIR}/test/run_bats_tests.sh"
    fi
  fi
fi

# Create configuration file to save installation location
cat > "$INSTALL_DIR/mvnimble.conf" << EOF
# MVNimble configuration - DO NOT EDIT MANUALLY
MVNIMBLE_INSTALL_DIR="$INSTALL_DIR"
MVNIMBLE_BIN_DIR="$BIN_DIR"
MVNIMBLE_INSTALL_METHOD="$INSTALL_METHOD"
MVNIMBLE_INSTALL_DATE="$(date '+%Y-%m-%d %H:%M:%S')"
EOF

# Print installation summary
print_header "Installation Complete"

if [[ "$INSTALL_METHOD" == "local" ]]; then
  echo "MVNimble installed to: $INSTALL_DIR"
  echo
  echo "To use MVNimble from this installation, add to your PATH:"
  echo "    export PATH=\"$BIN_DIR:\$PATH\""
  
  if [[ -d "${INSTALL_DIR}/tools/bats/bin" ]]; then
    echo "    export PATH=\"${INSTALL_DIR}/tools/bats/bin:\$PATH\""
  fi

  # Try to add to PATH automatically in common shell profiles
  if [[ "$INTERACTIVE" == "true" ]]; then
    read -p "Would you like to add MVNimble to your PATH automatically? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      for shell_profile in "${HOME}/.bashrc" "${HOME}/.zshrc" "${HOME}/.bash_profile"; do
        if [[ -f "$shell_profile" ]]; then
          echo "" >> "$shell_profile"
          echo "# Added by MVNimble installer" >> "$shell_profile"
          echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$shell_profile"
          if [[ -d "${INSTALL_DIR}/tools/bats/bin" ]]; then
            echo "export PATH=\"${INSTALL_DIR}/tools/bats/bin:\$PATH\"" >> "$shell_profile"
          fi
          echo "# End of MVNimble installer additions" >> "$shell_profile"
          print_success "Updated $shell_profile"
        fi
      done
      print_info "Please restart your shell or run 'source ~/.bashrc' (or equivalent) to apply changes."
    fi
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