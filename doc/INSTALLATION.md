# MVNimble Installation Guide

This guide provides instructions for installing MVNimble on various platforms and environments.

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Quick Installation](#quick-installation)
3. [Manual Installation](#manual-installation)
4. [Platform-Specific Notes](#platform-specific-notes)
5. [Docker Installation](#docker-installation)
6. [CI/CD Installation](#cicd-installation)
7. [Troubleshooting](#troubleshooting)

## System Requirements

MVNimble has the following prerequisites:

- **Bash** 3.2 or newer
- **Java** 8 or newer
- **Maven** 3.3 or newer
- **curl** or **wget** for the installation script

## Quick Installation

### One-Line Installer

For most users, the quickest way to install MVNimble is using our one-line installer:

```bash
curl -sSL https://get.mvnimble.io | bash
```

or with wget:

```bash
wget -qO- https://get.mvnimble.io | bash
```

This will:
1. Download the latest stable release
2. Install it to ~/.mvnimble
3. Add mvnimble to your PATH (requires shell restart)

### Verifying Installation

After installation, verify that MVNimble is correctly installed:

```bash
mvnimble --version
```

You should see output like:
```
MVNimble v1.2.3
```

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
    run: curl -sSL https://get.mvnimble.io | bash
  
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
        sh 'curl -sSL https://get.mvnimble.io | bash'
        sh 'export PATH="$HOME/.mvnimble/bin:$PATH"'
      }
    }
  }
}
```

### GitLab CI

```yaml
install_mvnimble:
  script:
    - curl -sSL https://get.mvnimble.io | bash
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
curl -sSL https://get.mvnimble.io | bash -x
```

### Manual Uninstallation

To completely remove MVNimble:

```bash
rm -rf ~/.mvnimble
```

Then remove the PATH addition from your shell profile.

### Support

If you encounter issues not addressed here, please:

1. Check the [GitHub issues](https://github.com/mvnimble/mvnimble/issues)
2. Open a new issue if needed
3. Contact support at support@mvnimble.io

---
Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license