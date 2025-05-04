# CI Integration for MVNimble

This document outlines how to use the MVNimble test framework in CI environments.

## GitHub Actions Integration

We've set up a comprehensive GitHub Actions workflow that automatically runs the MVNimble tests on both Linux and macOS. The workflow is defined in `.github/workflows/ci-tests.yml`.

### Key Features

1. **Platform Coverage**: Tests run on both Ubuntu (Linux) and macOS environments
2. **ShellCheck Static Analysis**: All shell scripts are analyzed for potential issues
3. **Multiple Report Formats**: Generates reports in HTML, JSON, Markdown, TAP, and JUnit formats
4. **Artifact Publishing**: Test results are uploaded as workflow artifacts
5. **GitHub Pages Integration**: Consolidated test reports can be published to GitHub Pages
6. **Custom Testing Parameters**: Supports customizing test execution through workflow dispatch

### Running the Workflow Manually

You can manually trigger the workflow with custom parameters:

1. Go to the "Actions" tab in your GitHub repository
2. Select the "MVNimble CI Tests" workflow
3. Click "Run workflow"
4. You can specify:
   - Test tags to include (e.g., `functional,positive`)
   - Test tags to exclude (e.g., `nonfunctional`)
   - Report format (html, json, markdown, tap)

### GitHub Pages Reports

When tests run on the `main` branch, a consolidated report is automatically published to GitHub Pages in the `test-reports` directory. You can access these reports at:

```
https://<your-username>.github.io/<repo-name>/test-reports/
```

## Jenkins Integration

The MVNimble test framework generates JUnit XML reports which are compatible with Jenkins' test reporting system.

### Setup in Jenkins

1. Add a build step that runs the MVNimble tests with JUnit output:
   ```bash
   ./test/run_bats_tests.sh --ci --non-interactive --report junit
   ```

2. Add a post-build action to publish JUnit test results:
   - Select "Publish JUnit test result report"
   - Set "Test report XMLs" to `test/test_results/*.xml`

### Test Trend Visualization

Jenkins will automatically collect test results and can display test trends over time, showing:
- Total tests over time
- Failed/Passed/Skipped test metrics
- Test stability

## Travis CI Integration

For Travis CI environments, add the following to your `.travis.yml` file:

```yaml
script:
  - ./test/run_bats_tests.sh --ci --non-interactive --report tap

after_script:
  - cat test/test_results/*.tap
```

## Custom CI Integration

For other CI systems, the test framework provides several interfaces:

1. **CI Detection**: The test runner automatically detects common CI environments
2. **JUnit XML Export**: Compatible with most CI test reporting systems
3. **TAP Output**: Standard format supported by many testing frameworks
4. **JSON Data**: Machine-readable format for custom integrations
5. **HTML Reports**: Human-readable reports for publishing

## Command Line Options

The following command line options are particularly useful in CI environments:

```
--ci                   CI mode (machine-readable output, no colors)
--non-interactive      Run in non-interactive mode (auto-install BATS if needed)
--report FORMAT        Generate a report in the specified format (markdown, json, tap, html, junit)
--tags TAGS            Only run tests with the specified tags (comma-separated)
--exclude-tags TAGS    Skip tests with the specified tags (comma-separated)
--fail-fast            Stop on first test failure
```

## Example Usage

Minimal CI command:
```bash
./test/run_bats_tests.sh --ci --non-interactive
```

Comprehensive CI command:
```bash
./test/run_bats_tests.sh --ci --non-interactive --report junit --tags functional,positive --exclude-tags slow
```

## Troubleshooting

If tests fail in CI environments but pass locally:

1. Check OS-specific issues (path separators, command availability)
2. Verify BATS installation in the CI environment
3. Check for timing-sensitive tests that may behave differently in CI
4. Review the full test logs - CI environments may have different output formatting

---
Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
