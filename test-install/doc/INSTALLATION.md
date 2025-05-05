# MVNimble Installation Guide

This guide provides instructions for installing MVNimble on various platforms and environments.

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Quick Installation](#quick-installation)
3. [Installation Without Symlinks](#installation-without-symlinks)
4. [Manual Installation](#manual-installation)
5. [Platform-Specific Notes](#platform-specific-notes)
6. [Docker Installation](#docker-installation)
7. [CI/CD Installation](#cicd-installation)
8. [Troubleshooting](#troubleshooting)

## System Requirements

MVNimble has the following prerequisites:

- **Bash** 3.2 or newer
- **Java** 8 or newer
- **Maven** 3.3 or newer
- **curl** or **wget** for the installation script

## Quick Installation

### From Github Repository

The easiest way to install MVNimble is directly from the GitHub repository:

```bash
# Clone the repository
git clone https://github.com/mvnimble/mvnimble.git

# Go to the cloned directory
cd mvnimble

# Run the installer (installs to ~/.mvnimble by default)
./install.sh
```

This will:
1. Install MVNimble to `~/.mvnimble` by default
2. Create symlinks in `~/.local/bin`
3. Offer to add MVNimble to your PATH by updating your shell profile

### Using Custom Installation Options

The MVNimble installer supports several options to customize the installation:

```bash
# Install to a custom location
./install.sh --prefix=/path/to/install/dir

# Perform system-wide installation (requires root)
sudo ./install.sh --system

# Skip running tests during installation
./install.sh --skip-tests

# Run only specific test categories
./install.sh --test-tags=functional,positive

# Generate test report during installation
./install.sh --test-report

# Run in non-interactive mode (for automated installations)
./install.sh --non-interactive
```

### Verifying Installation

After installation, verify that MVNimble is correctly installed:

```bash
mvnimble --version
```

You should see output like:
```
MVNimble v0.1.0
```

You can also verify the environment:

```bash
mvnimble verify
```

## Installation Without Symlinks

In some environments, symbolic links may not be supported or may cause issues. MVNimble provides an alternative installation method that doesn't use symbolic links:

```bash
# Install without using symbolic links
./install-simple.sh
```

This simplified installation:
1. Installs MVNimble to `~/.mvnimble` by default (or any specified location)
2. Creates direct wrapper scripts in `~/.local/bin` instead of symlinks
3. Uses a more direct approach to find library files

The simplified installation supports all the same options as the regular installer:

```bash
# Install to a custom location without symlinks
./install-simple.sh --prefix=/path/to/install/dir

# System-wide installation without symlinks
sudo ./install-simple.sh --system
```

For more details about the simplified installation, see [Simplified Installation](SIMPLIFIED-INSTALLATION.md).

## Manual Installation

If you prefer to install manually or the automatic installer doesn't work for your environment:

### Step 1: Download the Latest Release

```bash
# Create installation directory
mkdir -p ~/.mvnimble

# Download latest release
curl -L https://github.com/mvnimble/mvnimble/releases/latest/download/mvnimble.tar.gz -o /tmp/mvnimble.tar.gz

# Extract to installation directory
tar -xzf /tmp/mvnimble.tar.gz -C ~/.mvnimble
```

### Step 2: Add to PATH

Add the following to your shell profile (~/.bashrc, ~/.zshrc, etc.):

```bash
export PATH="$HOME/.mvnimble/bin:$PATH"
```

Then reload your shell configuration:

```bash
source ~/.bashrc  # or ~/.zshrc, etc.
```

## Platform-Specific Notes

### macOS

On macOS, you may need to install GNU utilities:

```bash
# Using Homebrew
brew install coreutils findutils gnu-sed

# Update your PATH to use GNU tools
echo 'export PATH="$(brew --prefix)/opt/coreutils/libexec/gnubin:$PATH"' >> ~/.zshrc
echo 'export PATH="$(brew --prefix)/opt/findutils/libexec/gnubin:$PATH"' >> ~/.zshrc
echo 'export PATH="$(brew --prefix)/opt/gnu-sed/libexec/gnubin:$PATH"' >> ~/.zshrc
```

### Linux

MVNimble works out of the box on most Linux distributions. For minimal environments, ensure the following packages are installed:

```bash
# Debian/Ubuntu
sudo apt-get install bash curl tar gzip coreutils

# CentOS/RHEL/Fedora
sudo yum install bash curl tar gzip coreutils
```

## Docker Installation

MVNimble can be run in a Docker container:

```bash
# Pull the MVNimble Docker image
docker pull mvnimble/mvnimble:latest

# Run MVNimble in a container
docker run -v $(pwd):/workspace -w /workspace mvnimble/mvnimble:latest mvnimble analyze
```

### Docker Compose Example

```yaml
version: '3'
services:
  mvnimble:
    image: mvnimble/mvnimble:latest
    volumes:
      - ./:/workspace
    working_dir: /workspace
    command: mvnimble analyze
```

## CI/CD Installation

### GitHub Actions

```yaml
steps:
  - name: Install MVNimble
    run: |
      git clone https://github.com/mvnimble/mvnimble.git
      cd mvnimble
      ./install.sh --non-interactive
  
  - name: Add to PATH
    run: echo "$HOME/.mvnimble/bin" >> $GITHUB_PATH
```

### Jenkins Pipeline

```groovy
pipeline {
  agent any
  stages {
    stage('Install MVNimble') {
      steps {
        sh '''
          git clone https://github.com/mvnimble/mvnimble.git
          cd mvnimble
          ./install.sh --non-interactive
          export PATH="$HOME/.mvnimble/bin:$PATH"
        '''
      }
    }
  }
}
```

### GitLab CI

```yaml
install_mvnimble:
  script:
    - git clone https://github.com/mvnimble/mvnimble.git
    - cd mvnimble
    - ./install.sh --non-interactive
    - export PATH="$HOME/.mvnimble/bin:$PATH"
```

## Troubleshooting

### Common Installation Issues

| Problem | Solution |
|---------|----------|
| Permission denied | Use `sudo bash` with the installer or manually adjust permissions |
| mvnimble command not found | Ensure ~/.mvnimble/bin is in your PATH |
| Incompatible Bash version | Update Bash to 3.2 or newer |
| Dependency missing | Install required dependencies (curl, tar, etc.) |

### Detailed Error Logs

For more detailed logs during installation:

```bash
bash -x install.sh
```

### Manual Uninstallation

To completely remove MVNimble:

```bash
rm -rf ~/.mvnimble
rm -f ~/.local/bin/mvnimble*
```

Then remove the PATH addition from your shell profile.

### Support

If you encounter issues not addressed here, please:

1. Check the [GitHub issues](https://github.com/mvnimble/mvnimble/issues)
2. Open a new issue if needed

---
Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license