# MVNimble Command-Line Tools

This directory contains the main command-line tools for MVNimble, a Maven test optimization utility.

## Available Commands

### Main Command

- `mvnimble` - The main entry point with all functionality

### Specialized Commands

- `mvnimble-monitor` - Dedicated tool for monitoring Maven builds
- `mvnimble-analyze` - Dedicated tool for analyzing build data and suggesting optimizations

## Usage Examples

### Monitor a Maven Build

```bash
# Using the main command
mvnimble monitor -o ./results -- mvn clean test

# Using the specialized monitor command
mvnimble-monitor -o ./results -- mvn clean test
```

### Analyze Build Results

```bash
# Using the main command
mvnimble analyze -i ./results -o ./analysis.md

# Using the specialized analyze command
mvnimble-analyze -i ./results -o ./analysis.md -f html
```

### Generate Reports

```bash
mvnimble report -i ./results/data.json -o ./report.html -f html
```

### Verify Environment

```bash
mvnimble verify
```

## Common Options

- `-h, --help` - Show help message
- `-v, --version` - Show version information (main command only)

For more detailed usage information, run any command with the `--help` flag.