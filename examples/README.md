# MVNimble Examples

This directory contains examples and demo scripts to help you get started with MVNimble.

## Contents

- `simple-junit-project/` - A simple Maven project with JUnit tests
- `demo.sh` - A demonstration script showing basic MVNimble usage

## Running the Demo

To run the complete demonstration:

```bash
# Navigate to the examples directory
cd examples

# Run the demo script
./demo.sh
```

This demo script will:

1. Verify the MVNimble environment
2. Monitor a Maven build for the simple-junit-project
3. Analyze the build results
4. Generate an HTML report

## Manual Examples

### Basic Monitoring

```bash
cd simple-junit-project
mvnimble monitor -- mvn clean test
```

### Custom Monitoring

```bash
cd simple-junit-project
mvnimble monitor -o ./custom-results -i 2 -m 10 -- mvn clean test
```

### Analysis with Custom Output

```bash
mvnimble analyze -i ./results -o ./custom-analysis.md -f markdown
```

### Report Generation

```bash
mvnimble report -i ./results/data.json -o ./custom-report.html -f html
```

## Using Specialized Scripts

MVNimble also provides specialized scripts for specific functions:

```bash
# Monitoring only
mvnimble-monitor -o ./results -- mvn clean test

# Analysis only
mvnimble-analyze -i ./results -o ./analysis.html -f html
```

## Next Steps

After trying these examples, check the [Usage Guide](../doc/USAGE.md) for more advanced usage scenarios.