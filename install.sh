#!/bin/bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# MVNimble Installer
# Installs MVNimble to make it available system-wide

set -e

# Get current working directory
CWD=$(pwd)

# Determine installation location
DEFAULT_INSTALL_DIR="${CWD}/target/mvnimble"
BIN_LINK="${CWD}/target/bin/mvnimble"
ZSH_COMPLETION_DIR="${CWD}/target/zsh/completions"

echo "MVNimble Installer"
echo "================="
echo

# Check if target directory exists and clean it if it does
if [ -d "${CWD}/target" ]; then
    echo "Existing target directory found. Cleaning up..."
    rm -rf "${CWD}/target"
    echo "Target directory cleaned."
fi

# Default to target installation method for testing
INSTALL_METHOD="target"
# Ensure the target directories exist
mkdir -p "${CWD}/target/bin"
mkdir -p "${ZSH_COMPLETION_DIR}"

# Parse command line arguments for installation method
for arg in "$@"; do
  case $arg in
    --system)
      echo "Warning: System-wide installation is disabled."
      echo "All installations will go to the target directory."
      INSTALL_METHOD="target"
      shift
      ;;
  esac
done

echo "Installing MVNimble to target directory..."

# Parse command line arguments
INTERACTIVE=true

for arg in "$@"; do
  case $arg in
    --non-interactive)
      INTERACTIVE=false
      shift
      ;;
    --local)
      echo "All installations will go to the target directory."
      shift
      ;;
  esac
done

# Always use the default installation directory
echo "Using installation directory: ${DEFAULT_INSTALL_DIR}"
INSTALL_DIR=${DEFAULT_INSTALL_DIR}

echo "Installing MVNimble to ${INSTALL_DIR}..."

# Create installation directory structure
mkdir -p "${INSTALL_DIR}/bin"
mkdir -p "${INSTALL_DIR}/src/lib/modules"
mkdir -p "${INSTALL_DIR}/src/completion"
mkdir -p "${INSTALL_DIR}/doc"
mkdir -p "${INSTALL_DIR}/doc/adr"
mkdir -p "${INSTALL_DIR}/test"
mkdir -p "${INSTALL_DIR}/examples"
mkdir -p "${INSTALL_DIR}/results"

# Copy files
cp bin/mvnimble "${INSTALL_DIR}/bin/"
cp src/lib/mvnimble.sh "${INSTALL_DIR}/src/lib/"
cp src/lib/modules/*.sh "${INSTALL_DIR}/src/lib/modules/"
cp src/lib/generate_report.sh "${INSTALL_DIR}/src/lib/"
cp src/completion/_mvnimble "${INSTALL_DIR}/src/completion/"
cp -r doc/* "${INSTALL_DIR}/doc/"
cp -r examples/* "${INSTALL_DIR}/examples/" 2>/dev/null || true
cp -r test/* "${INSTALL_DIR}/test/" 2>/dev/null || true
cp README.md "${INSTALL_DIR}/"

# Make scripts executable
chmod +x "${INSTALL_DIR}/bin/mvnimble"
chmod +x "${INSTALL_DIR}/src/lib/mvnimble.sh"
chmod +x "${INSTALL_DIR}/src/lib/modules/"*.sh
chmod +x "${INSTALL_DIR}/src/lib/generate_report.sh"
chmod +x "${INSTALL_DIR}/test/run_bats_tests.sh" 2>/dev/null || true

# Copy binary script directly instead of symlink to avoid path issues
mkdir -p "$(dirname "${BIN_LINK}")"
cp "${INSTALL_DIR}/bin/mvnimble" "${BIN_LINK}"

# Fix up the bin script to use absolute paths
sed -i.bak "s|INSTALL_DIR=\"\${SCRIPT_DIR}/\.\.\"|INSTALL_DIR=\"${INSTALL_DIR}\"|g" "${BIN_LINK}"
rm "${BIN_LINK}.bak" 2>/dev/null || true

# Install ZSH completion if possible
if [[ -d "${ZSH_COMPLETION_DIR}" && -w "${ZSH_COMPLETION_DIR}" ]]; then
    echo "Installing ZSH completion..."
    ln -sf "${INSTALL_DIR}/src/completion/_mvnimble" "${ZSH_COMPLETION_DIR}/_mvnimble"
    echo "ZSH completion installed. You may need to run 'compinit' to enable it."
elif [[ "${INSTALL_METHOD}" == "user" ]]; then
    echo "To enable ZSH completion, add this to your .zshrc:"
    echo "    fpath=(${ZSH_COMPLETION_DIR} \$fpath)"
    echo "    autoload -Uz compinit"
    echo "    compinit"
fi

# Create a standalone BATS installation for the target directory
echo
echo "Setting up BATS (Bash Automated Testing System) for this installation..."
echo "Installing BATS to target directory..."

# Create a temporary directory for installation
TEMP_DIR=$(mktemp -d)
CURRENT_DIR=$(pwd)
cd "$TEMP_DIR" || { echo "Failed to cd to temp directory"; exit 1; }

# Clone and install BATS
git clone https://github.com/bats-core/bats-core.git
cd bats-core || { echo "Failed to cd to bats-core directory"; exit 1; }

# Install BATS to the target directory
BATS_INSTALL_DIR="${CWD}/target/bats"
mkdir -p "$BATS_INSTALL_DIR"
./install.sh "$BATS_INSTALL_DIR"

# Add to PATH for this script
export PATH="$BATS_INSTALL_DIR/bin:$PATH"

# Clean up
cd "$CURRENT_DIR" || { echo "Failed to return to original directory"; exit 1; }
rm -rf "$TEMP_DIR"

echo "BATS installed successfully to ${BATS_INSTALL_DIR}!"

# Parse additional arguments for testing
SKIP_TESTS=false
TEST_TAGS=""
TEST_REPORT=false

for arg in "$@"; do
  case $arg in
    --skip-tests)
      SKIP_TESTS=true
      shift
      ;;
    --test-tags=*)
      TEST_TAGS="${arg#*=}"
      shift
      ;;
    --test-report)
      TEST_REPORT=true
      shift
      ;;
  esac
done

echo
echo "Installation complete!"

echo "To use mvnimble from this installation, run:"
echo "    export PATH=\"${CWD}/target/bin:\$PATH\""
echo "    export BATS_PATH=\"${CWD}/target/bats/bin:\$PATH\""

# Run tests if not skipped
if [[ "$SKIP_TESTS" == "false" ]]; then
    echo
    echo "Running MVNimble tests with local BATS installation..."
    
    # Export the path to the local BATS installation
    export PATH="${BATS_INSTALL_DIR}/bin:$PATH"
    
    # Run test summary script for a cleaner output
    if [[ -f "${INSTALL_DIR}/test/test_summary.sh" ]]; then
        chmod +x "${INSTALL_DIR}/test/test_summary.sh"
        
        # Pass --with-report option if test report is requested
        if [[ "$TEST_REPORT" == "true" ]]; then
            "${INSTALL_DIR}/test/test_summary.sh" --with-report
        else
            "${INSTALL_DIR}/test/test_summary.sh"
        fi
    else
        # Fall back to direct test execution if summary script isn't available
        TEST_CMD="${INSTALL_DIR}/test/run_bats_tests.sh --non-interactive"
        
        if [[ -n "$TEST_TAGS" ]]; then
          TEST_CMD="${TEST_CMD} --tags ${TEST_TAGS}"
        fi
        
        if [[ "$TEST_REPORT" == "true" ]]; then
          TEST_CMD="${TEST_CMD} --report markdown"
        fi
        
        chmod +x "${INSTALL_DIR}/test/run_bats_tests.sh"
        eval "$TEST_CMD"
    fi
    
    echo
    echo "Tests completed!"
else
    echo
    echo "To use MVNimble, run: ${CWD}/target/bin/mvnimble --help"
    echo "To run tests, use: ${INSTALL_DIR}/test/run_bats_tests.sh"
fi

echo