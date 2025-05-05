# Running MVNimble on the Checkvox Project

This guide explains how to run MVNimble on the Checkvox project using our simplified installation that doesn't rely on symbolic links.

## Prerequisites

- The Checkvox project must be installed at `/Users/vorthruna/Code/checkvox`
- MVNimble must be installed at `/Users/vorthruna/Code/mvnimble/test-install`

## Running the Analysis

We've created two scripts to help you run MVNimble on the Checkvox project:

### Option 1: Using the monitor-checkvox.sh script (Recommended)

This script is already configured to run MVNimble on the Checkvox project with optimized settings.

```bash
./run-mvnimble-on-checkvox.sh
```

This will:
1. Run the monitor-checkvox.sh script from the MVNimble installation directory
2. Monitor the Maven build for the Checkvox project with unit tests
3. Analyze the build results and identify optimization opportunities
4. Generate a report in HTML and Markdown format

### Option 2: Using the custom run script

If you need more control over the analysis parameters, you can use the custom run script:

```bash
./run-checkvox-analysis.sh
```

This script:
1. Monitors the Maven build for the Checkvox project with all tests
2. Analyzes the build results and identifies optimization opportunities
3. Generates reports in HTML and Markdown format

## Viewing Results

After running either script, you can find the results in:

- HTML Report: `/Users/vorthruna/Code/mvnimble/test-install/results/checkvox/report.html`
- Analysis Markdown: `/Users/vorthruna/Code/mvnimble/test-install/results/checkvox/analysis.md`
- Raw Data: `/Users/vorthruna/Code/mvnimble/test-install/results/checkvox/data.json`

## Troubleshooting

If you encounter issues:

1. Ensure both the Checkvox project and MVNimble installation exist at the expected paths
2. Verify that Maven is properly installed and in your PATH
3. Make sure the monitoring scripts have execute permissions
4. Check for any error messages during execution

## Next Steps

After reviewing the analysis and reports, you might want to:

1. Implement the suggested optimizations in the Checkvox project
2. Run MVNimble again to verify improvements
3. Integrate MVNimble with your CI/CD pipeline for ongoing monitoring