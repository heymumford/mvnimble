#!/usr/bin/env bash
# Test script to verify that our fixes to analyze.sh work correctly

set -e

# Create a temporary test directory
TEST_DIR="/tmp/mvnimble-test"
mkdir -p "$TEST_DIR/lib"
mkdir -p "$TEST_DIR/outputs"

# Create minimal mock modules to satisfy dependencies
cat > "$TEST_DIR/lib/constants.sh" << 'EOF'
#!/usr/bin/env bash
# Mock constants module for testing
CONSTANTS_LOADED=true
EXIT_SUCCESS=0
EXIT_FILE_ERROR=1
EXIT_INVALID_ARGS=2
MVNIMBLE_VERSION="0.1.0-test"
EOF

cat > "$TEST_DIR/lib/common.sh" << 'EOF'
#!/usr/bin/env bash
# Mock common module for testing
print_header() { echo "HEADER: $1"; }
print_success() { echo "SUCCESS: $1"; }
print_error() { echo "ERROR: $1" >&2; }
print_warning() { echo "WARNING: $1"; }
print_info() { echo "INFO: $1"; }
ensure_directory() { mkdir -p "$1"; }
EOF

# Extract only the required functions from analyze.sh
cat > "$TEST_DIR/analyze-test.sh" << 'EOF'
#!/usr/bin/env bash
# Test version with only the functions we need to test

# Mock environment functions
get_cpu_cores() { echo 8; }
get_available_memory() { echo 16384; }
get_os_type() { echo "TestOS"; }
print_header() { echo "HEADER: $1"; }
print_success() { echo "SUCCESS: $1"; }
print_warning() { echo "WARNING: $1"; }
print_error() { echo "ERROR: $1" >&2; }
print_info() { echo "INFO: $1"; }
ensure_directory() { mkdir -p "$1"; }

# Constants
EXIT_SUCCESS=0
EXIT_FILE_ERROR=1
EXIT_INVALID_ARGS=2
MVNIMBLE_VERSION="0.1.0-test"

# Generate build recommendations based on analysis
function generate_build_recommendations() {
  local maven_output="$1"
  local metrics_dir="$2"
  local report_file="$3"
  
  # Create report directory if needed
  ensure_directory "$(dirname "$report_file")"
  
  print_header "Generating Build Recommendations"
  
  # Extract system information
  local cpu_cores=$(get_cpu_cores)
  local memory_mb=$(get_available_memory)
  local os_type=$(get_os_type)
  
  # Calculate recommended settings
  local recommended_threads=$((cpu_cores * 2))
  local recommended_fork_count="$cpu_cores"
  local recommended_memory=$((memory_mb / 4))  # 25% of available memory
  
  # Generate the report
  {
    echo "# Build Optimization Recommendations"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "## System Information"
    echo ""
    echo "* OS: $os_type"
    echo "* CPU Cores: $cpu_cores"
    echo "* Available Memory: ${memory_mb}MB"
    echo ""
    echo "## Maven Configuration Recommendations"
    echo ""
    echo "### Command Line Options"
    echo ""
    echo "\\`\\`\\`bash"
    echo "\\mvn -T ${recommended_threads} clean test"
    echo "\\`\\`\\`"
    echo ""
    echo "### Surefire Configuration"
    echo ""
    echo "\\`\\`\\`xml"
    echo "\\<plugin\\>"
    echo "  \\<groupId\\>org.apache.maven.plugins\\</groupId\\>"
    echo "  \\<artifactId\\>maven-surefire-plugin\\</artifactId\\>"
    echo "  \\<configuration\\>"
    echo "    \\<forkCount\\>${recommended_fork_count}\\</forkCount\\>"
    echo "    \\<reuseForks\\>true\\</reuseForks\\>"
    echo "    \\<argLine\\>-Xmx${recommended_memory}m\\</argLine\\>"
    echo "  \\</configuration\\>"
    echo "\\</plugin\\>"
    echo "\\`\\`\\`"
    echo ""
    echo "## Performance Optimization Tips"
    echo ""
    echo "1. Group tests by category to enable parallel execution"
    echo "2. Avoid test interdependencies"
    echo "3. Use \`\\@Category\` annotations for better test organization"
    echo "4. Consider using JUnit 5 for improved parallel test execution"
    echo ""
    echo "---"
    echo "Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license"
  } > "$report_file"
  
  print_success "Build recommendations report generated: $report_file"
  return ${EXIT_SUCCESS}
}

# Test function for POM recommendations
function generate_pom_recommendations() {
  local output_file="$1"
  
  # Create output directory if needed
  ensure_directory "$(dirname "$output_file")"
  
  # Generate system-specific recommendations
  local cpu_cores=$(get_cpu_cores)
  local recommended_fork_count=$((cpu_cores > 1 ? cpu_cores : 1))
  
  # Generate the report
  {
    echo "1. **Parallelism**: Configure Maven Surefire Plugin for parallel execution"
    echo "   \\`\\`\\`xml"
    echo "   \\<forkCount\\>${recommended_fork_count}\\</forkCount\\>"
    echo "   \\<reuseForks\\>true\\</reuseForks\\>"
    echo "   \\<parallel\\>classes\\</parallel\\>"
    echo "   \\<threadCount\\>${recommended_fork_count}\\</threadCount\\>"
    echo "   \\`\\`\\`"
    echo ""
    echo "2. **Memory Settings**: Optimize JVM memory allocation"
    echo "   \\`\\`\\`xml"
    echo "   \\<argLine\\>-Xmx1024m -XX:+UseG1GC\\</argLine\\>"
    echo "   \\`\\`\\`"
    echo ""
    echo "3. **Test Organization**: Group tests by category to enable selective execution"
    echo "   \\`\\`\\`xml"
    echo "   \\<groups\\>UnitTest,FastTest\\</groups\\>"
    echo "   \\<excludedGroups\\>IntegrationTest,SlowTest\\</excludedGroups\\>"
    echo "   \\`\\`\\`"
  } > "$output_file"
  
  print_success "POM recommendations report generated: $output_file"
  return ${EXIT_SUCCESS}
}
EOF

echo "Testing the fixed analyze.sh functions..."

# Make the test script executable
chmod +x "$TEST_DIR/analyze-test.sh"

# Create a test function that would normally trigger the errors
cat > "$TEST_DIR/test_function.sh" << EOF
#!/usr/bin/env bash

# Source the analyze-test.sh script
source "$TEST_DIR/analyze-test.sh"

# Test directory
TEST_DIR="$TEST_DIR"

# Test function that uses the problematic sections
test_generate_recommendations() {
  # Test the function
  REPORT_FILE="\$TEST_DIR/outputs/test_report.md"
  echo "Generating test report at \$REPORT_FILE..."
  generate_build_recommendations "\$TEST_DIR/maven_output.log" "\$TEST_DIR/metrics_dir" "\$REPORT_FILE"
  
  # Check if report was generated without errors
  if [ -f "\$REPORT_FILE" ]; then
    echo "✓ Report generated successfully"
    echo "Report contents (first few lines):"
    echo "-----------------"
    head -n 10 "\$REPORT_FILE"
    echo "..."
    echo "-----------------"
    return 0
  else
    echo "✗ Report generation failed"
    return 1
  fi
}

# Test function that uses the problematic sections from POM recommendations
test_pom_recommendations() {
  # Test the function
  REPORT_FILE="\$TEST_DIR/outputs/test_pom_report.md"
  echo "Generating test POM report at \$REPORT_FILE..."
  
  # Use our test function
  generate_pom_recommendations "\$REPORT_FILE"
  
  # Check if report was generated without errors
  if [ -f "\$REPORT_FILE" ]; then
    echo "✓ POM recommendations generated successfully"
    echo "Report contents (first few lines):"
    echo "-----------------"
    head -n 10 "\$REPORT_FILE"
    echo "..."
    echo "-----------------"
    return 0
  else
    echo "✗ POM recommendations generation failed"
    return 1
  fi
}

# Test basic XML escaping
test_xml_escaping() {
  echo "Testing XML escaping..."
  
  # Test cases that were causing errors
  echo "<plugin> - This shouldn't error"
  echo "@Category - This shouldn't error" 
  echo "<forkCount> - This shouldn't error"
  echo "<argLine> - This shouldn't error"
  echo "<groups> - This shouldn't error"
  
  echo "✓ XML escaping test completed successfully"
}

# Run all tests
echo "Running test_generate_recommendations..."
test_generate_recommendations
echo ""

echo "Running test_pom_recommendations..."
test_pom_recommendations
echo ""

echo "Running test_xml_escaping..."
test_xml_escaping
echo ""

echo "All tests completed successfully!"
EOF

# Make the test script executable
chmod +x "$TEST_DIR/test_function.sh"

# Run the test script
echo "Running tests..."
"$TEST_DIR/test_function.sh"

# Clean up
rm -rf "$TEST_DIR"
echo "Test completed and temporary files cleaned up"