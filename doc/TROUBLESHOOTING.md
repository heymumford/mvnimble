# MVNimble Troubleshooting Guide

This guide helps you solve common problems with MVNimble.

## Installation Issues

### Command Not Found

```
-bash: mvnimble: command not found
```

**Solutions:**
1. Make sure installation completed successfully:
   ```bash
   ./install-simple.sh
   ```
2. Check if MVNimble is in your PATH:
   ```bash
   which mvnimble
   ```
3. Try using the full path:
   ```bash
   /path/to/mvnimble/bin/mvnimble mvn test
   ```

### Missing Dependencies

```
Error: Required dependency 'jq' not found
```

**Solutions:**
1. Install missing dependencies:
   ```bash
   # On macOS
   brew install jq
   
   # On Ubuntu/Debian
   sudo apt-get install jq
   ```
2. Run installation with dependency check:
   ```bash
   ./install-with-fix.sh
   ```

## Runtime Problems

### No Results Generated

**Problem:** Tests run but no report is generated

**Solutions:**
1. Check if MVNimble has write permissions:
   ```bash
   # Try creating output directory manually
   mkdir -p mvnimble-results
   chmod 755 mvnimble-results
   ```
2. Run with verbose output:
   ```bash
   mvnimble --verbose mvn test
   ```
3. Check for errors in the log:
   ```bash
   cat mvnimble-results/mvnimble.log
   ```

### Incomplete Reports

**Problem:** Reports are missing sections or data

**Solutions:**
1. Check if the test completed successfully:
   ```bash
   cat mvnimble-results/status.txt
   ```
2. Generate report manually:
   ```bash
   mvnimble report --format markdown
   ```
3. Look for error messages:
   ```bash
   grep ERROR mvnimble-results/mvnimble.log
   ```

### Performance Issues

**Problem:** MVNimble makes tests run much slower

**Solutions:**
1. Reduce monitoring frequency:
   ```bash
   mvnimble --sample-rate=5s mvn test
   ```
2. Disable thread monitoring:
   ```bash
   mvnimble --disable-thread-monitor mvn test
   ```
3. Run with minimal monitoring:
   ```bash
   mvnimble --monitor-only --minimal mvn test
   ```

## Flaky Test Detection Issues

### False Positives

**Problem:** Tests incorrectly marked as flaky

**Solutions:**
1. Increase detection runs:
   ```bash
   mvnimble --detect-flaky=10 mvn test
   ```
2. Adjust flakiness threshold:
   ```bash
   mvnimble --flaky-threshold=0.4 --detect-flaky=5 mvn test
   ```

### Deadlocks During Flaky Detection

**Problem:** Tests hang when running multiple times

**Solutions:**
1. Add timeout to prevent hanging:
   ```bash
   mvnimble --timeout=5m --detect-flaky=3 mvn test
   ```
2. Run tests in isolation:
   ```bash
   mvnimble --isolate-tests --detect-flaky=3 mvn test
   ```

## Report Interpretation Problems

### Resource Correlation Unclear

**Problem:** Can't understand resource correlation data

**Solutions:**
1. Generate a more detailed report:
   ```bash
   mvnimble report --format html --detailed-resources
   ```
2. View raw metrics data:
   ```bash
   cat mvnimble-results/metrics/system.csv
   cat mvnimble-results/metrics/jvm.csv
   ```
3. Generate a report focused on a specific test:
   ```bash
   mvnimble report --format markdown --focus-test=TestClassName
   ```

### Confusing Error Messages

**Problem:** Test failure reasons aren't clear

**Solutions:**
1. Enable enhanced error analysis:
   ```bash
   mvnimble --enhanced-errors mvn test
   ```
2. Check raw Maven output:
   ```bash
   cat mvnimble-results/maven_output.log
   ```
3. Run test directly for comparison:
   ```bash
   mvn -Dtest=SpecificTest test
   ```

## Platform-Specific Issues

### MacOS Issues

**Problem:** Resource monitoring incomplete on macOS

**Solutions:**
1. Install additional monitoring tools:
   ```bash
   brew install coreutils
   ```
2. Run with platform-specific options:
   ```bash
   mvnimble --macos-compatible mvn test
   ```

### Linux Issues

**Problem:** Permission issues with monitoring

**Solutions:**
1. Run with elevated permissions for monitoring:
   ```bash
   sudo mvnimble --monitor-system mvn test
   ```
2. Adjust system metrics collection:
   ```bash
   mvnimble --proc-metrics-only mvn test
   ```

## Getting Help

If you're still having problems:

1. Run MVNimble with diagnostics:
   ```bash
   mvnimble --diagnose-tool > mvnimble-diagnostic.log
   ```

2. Check for known issues in the documentation:
   ```bash
   grep -r "your issue" ./doc/
   ```

3. Submit a detailed issue with your diagnostic log and environment details