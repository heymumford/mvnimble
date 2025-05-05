# MVNimble Installation Guide

This guide covers how to install MVNimble on your system.

## System Requirements

MVNimble works on:
- **macOS** (10.15 Catalina or newer)
- **Linux** (Ubuntu 18.04+, CentOS 7+, other modern distributions)

### Dependencies

MVNimble requires:
- Bash 3.2 or newer
- Maven 3.3 or newer
- Java 8 or newer

The following tools are recommended but will be installed automatically if missing:
- jq (for JSON processing)
- bc (for calculations)
- grep, sed, awk (standard Unix tools)

## Quick Installation

For standard installations:

```bash
# Download and run the simple installer
./bin/install/install-simple.sh
```

This will:
1. Install MVNimble to `~/mvnimble` (or the current directory if run from git)
2. Add MVNimble to your PATH in `.bashrc` or `.bash_profile`
3. Check for required dependencies

## Installation with Diagnostic Tools

For a more complete installation with additional diagnostic tools:

```bash
# Download and run the enhanced installer
./bin/install/install-with-fix.sh
```

This includes everything in the simple installation plus:
1. Additional diagnostic utilities
2. Thread dump analyzers
3. Advanced resource monitoring capabilities

## Manual Installation

If you prefer to install manually:

1. Clone the repository:
   ```bash
   git clone https://github.com/user/mvnimble.git
   cd mvnimble
   ```

2. Add to your PATH:
   ```bash
   echo 'export PATH="$PATH:$HOME/mvnimble/bin"' >> ~/.bashrc
   source ~/.bashrc
   ```

3. Check installation:
   ```bash
   mvnimble --version
   ```

## Verifying Your Installation

To verify that MVNimble installed correctly:

```bash
# Check if MVNimble is in your PATH
which mvnimble

# Check the version
mvnimble --version

# Test basic functionality
mvnimble --help
```

## Troubleshooting Installation

### Path Issues

If `mvnimble` command is not found:

1. Check if it's in your PATH:
   ```bash
   echo $PATH | grep mvnimble
   ```

2. If not found, add it manually:
   ```bash
   echo 'export PATH="$PATH:$HOME/mvnimble/bin"' >> ~/.bashrc
   source ~/.bashrc
   ```

### Missing Dependencies

If you see dependency errors:

```bash
# On macOS
brew install jq bc coreutils

# On Ubuntu/Debian
sudo apt-get install jq bc

# On CentOS/RHEL
sudo yum install jq bc
```

### Permission Issues

If you have permission errors:

```bash
# Make the scripts executable
chmod +x ~/mvnimble/bin/mvnimble
chmod +x ~/mvnimble/lib/*.sh
```

## Uninstalling MVNimble

To uninstall:

```bash
# Remove the directory
rm -rf ~/mvnimble

# Remove from PATH (edit your ~/.bashrc or ~/.bash_profile)
# Look for the line with 'export PATH=...$HOME/mvnimble/bin' and remove it
```

## Next Steps

After installation:

1. Read the [Usage Guide](./USAGE.md) to learn how to use MVNimble
2. Try running MVNimble on a test project:
   ```bash
   cd /path/to/maven/project
   mvnimble mvn test
   ```
3. Check out the generated reports in the `mvnimble-results` directory