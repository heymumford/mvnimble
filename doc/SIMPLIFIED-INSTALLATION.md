# Simplified MVNimble Installation (No Symlinks)

This document describes the simplified installation approach for MVNimble that avoids the use of symbolic links. This approach is useful in environments where symbolic links might cause problems or are not supported.

## Why a Simplified Installation?

The standard MVNimble installation uses symbolic links to make the command-line utilities available in your PATH. While this approach works well in most environments, it can lead to issues in some cases:

1. Some environments have security restrictions that prevent the use of symbolic links
2. Symbolic links can cause circular references if not handled correctly
3. Some file systems do not support symbolic links
4. Using symbolic links can make debugging more difficult as the actual code location may not be immediately obvious

The simplified installation addresses these issues by using direct file copies and simple wrapper scripts instead of symbolic links.

## How to Install MVNimble Without Symlinks

Use the `install-simple.sh` script instead of the regular `install.sh` script:

```bash
./install-simple.sh
```

This script supports the same options as the regular installer:

```bash
./install-simple.sh --prefix=/path/to/installation
```

### What's Different About the Simplified Installation?

1. No symbolic links are used in the installation
2. Command wrappers are created in the BIN_DIR that directly execute the main mvnimble script
3. The main script detects its own location to find the library files

### Directory Structure

The simplified installation creates the following directory structure:

```
$INSTALL_DIR/
├── bin/           # Executable scripts
├── lib/           # Library files
├── doc/           # Documentation
├── examples/      # Example projects
└── mvnimble.conf  # Configuration file
```

In `$BIN_DIR` (typically `~/.local/bin` or `/usr/local/bin`), it creates wrapper scripts that directly execute the scripts in `$INSTALL_DIR/bin/`.

## Checking Your Installation

After installation, you can verify that your installation is using the simplified approach:

```bash
mvnimble verify
```

If you see output indicating that no symbolic links are used, your installation is using the simplified approach.

## Troubleshooting

If you experience any issues with the simplified installation:

1. Check that the wrapper scripts in `$BIN_DIR` are executable
2. Verify that `$BIN_DIR` is in your PATH
3. Check the `mvnimble.conf` file in your installation directory to confirm that `MVNIMBLE_NO_SYMLINKS=true` is set

## Converting an Existing Installation

If you have an existing MVNimble installation that uses symbolic links, you can convert it to the simplified approach by running:

```bash
./install-simple.sh --prefix=your-existing-installation-directory
```

This will replace the symbolic links with direct copies and wrapper scripts.

---
Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license