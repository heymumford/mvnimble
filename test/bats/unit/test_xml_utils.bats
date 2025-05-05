#!/usr/bin/env bats
# Test the xml_utils.sh module

load ../test_helper
load ../helpers/bats-support/load
load ../helpers/bats-assert/load

# Setup - runs before each test
setup() {
  # Source the module being tested
  source "${BATS_TEST_DIRNAME}/../../../src/lib/modules/xml_utils.sh"
  
  # Create test directory if it doesn't exist
  TEST_DIR="${BATS_TEST_DIRNAME}/../../fixtures/xml_test"
  mkdir -p "${TEST_DIR}"
  
  # Create a sample POM file for testing
  cat > "${TEST_DIR}/test_pom.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" 
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <groupId>com.example</groupId>
    <artifactId>test-project</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    
    <properties>
        <maven.compiler.source>1.8</maven.compiler.source>
        <maven.compiler.target>1.8</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <jvm.fork.count>1.0C</jvm.fork.count>
        <maven.threads>2</maven.threads>
        <jvm.fork.memory>512M</jvm.fork.memory>
    </properties>
    
    <dependencies>
        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <version>4.12</version>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.mockito</groupId>
            <artifactId>mockito-core</artifactId>
            <version>3.3.3</version>
            <scope>test</scope>
        </dependency>
    </dependencies>
    
    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <version>2.22.2</version>
                <configuration>
                    <forkCount>1</forkCount>
                    <reuseForks>true</reuseForks>
                    <argLine>-Xmx512m</argLine>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
EOF
}

# Teardown - runs after each test
teardown() {
  # Clean up test files
  rm -rf "${TEST_DIR}"
}

# Test whether XMLStarlet is available
@test "XMLStarlet availability check" {
  if ! verify_xmlstarlet; then
    skip "XMLStarlet not available, skipping tests"
  fi
  
  # If we get here, XMLStarlet is available
  run verify_xmlstarlet
  assert_success
}

# Test getting the XMLStarlet command name
@test "Get XMLStarlet command name" {
  if ! verify_xmlstarlet; then
    skip "XMLStarlet not available, skipping tests"
  fi
  
  run get_xmlstarlet_command
  assert_success
  assert [ -n "$output" ]
  
  # The output should be either "xmlstarlet" or "xml"
  assert [ "$output" = "xmlstarlet" -o "$output" = "xml" ]
}

# Test XML fragment generation
@test "Generate XML fragment" {
  if ! verify_xmlstarlet; then
    skip "XMLStarlet not available, skipping tests"
  fi
  
  run xml_generate_fragment "plugin" "groupId>org.apache.maven.plugins</groupId" "artifactId>maven-surefire-plugin</artifactId"
  assert_success
  assert_output --partial "<plugin>"
  assert_output --partial "<groupId>org.apache.maven.plugins</groupId>"
  assert_output --partial "<artifactId>maven-surefire-plugin</artifactId>"
  assert_output --partial "</plugin>"
}

# Test Surefire configuration generation
@test "Generate Surefire configuration" {
  if ! verify_xmlstarlet; then
    skip "XMLStarlet not available, skipping tests"
  fi
  
  run xml_generate_surefire_config "2" "true" "-Xmx1024m" "classes" "4"
  assert_success
  assert_output --partial "<plugin>"
  assert_output --partial "<groupId>org.apache.maven.plugins</groupId>"
  assert_output --partial "<artifactId>maven-surefire-plugin</artifactId>"
  assert_output --partial "<configuration>"
  assert_output --partial "<forkCount>2</forkCount>"
  assert_output --partial "<reuseForks>true</reuseForks>"
  assert_output --partial "<argLine>-Xmx1024m</argLine>"
  assert_output --partial "<parallel>classes</parallel>"
  assert_output --partial "<threadCount>4</threadCount>"
  assert_output --partial "</configuration>"
  assert_output --partial "</plugin>"
}

# Test POM querying
@test "Query POM file" {
  if ! verify_xmlstarlet; then
    skip "XMLStarlet not available, skipping tests"
  fi
  
  # Test querying a single element
  run xml_query_pom "${TEST_DIR}/test_pom.xml" "//project/properties/jvm.fork.count"
  assert_success
  assert_output "1.0C"
  
  # Test querying multiple elements
  run xml_query_pom "${TEST_DIR}/test_pom.xml" "//project/dependencies/dependency/artifactId"
  assert_success
  assert_output --partial "junit"
  assert_output --partial "mockito-core"
  
  # Test counting elements
  run xml_query_pom "${TEST_DIR}/test_pom.xml" "//project/dependencies/dependency" "count"
  assert_success
  assert_output "2"
}

# Test element existence check
@test "Check if element exists in POM" {
  if ! verify_xmlstarlet; then
    skip "XMLStarlet not available, skipping tests"
  fi
  
  # Element exists
  run xml_element_exists "${TEST_DIR}/test_pom.xml" "//project/properties/jvm.fork.count"
  assert_success
  
  # Element doesn't exist
  run xml_element_exists "${TEST_DIR}/test_pom.xml" "//project/properties/nonexistent"
  assert_failure
}

# Test getting Maven settings
@test "Get Maven settings from POM" {
  if ! verify_xmlstarlet; then
    skip "XMLStarlet not available, skipping tests"
  fi
  
  run xml_get_maven_settings "${TEST_DIR}/test_pom.xml"
  assert_success
  assert_output "fork_count=1.0C,threads=2,memory=512M"
}

# Test detecting test frameworks
@test "Detect test frameworks in POM" {
  if ! verify_xmlstarlet; then
    skip "XMLStarlet not available, skipping tests"
  fi
  
  run xml_detect_test_frameworks "${TEST_DIR}/test_pom.xml"
  assert_success
  assert_output --partial "junit5=false"
  assert_output --partial "testng=false"
  
  # Check for JUnit 4
  run xml_element_exists "${TEST_DIR}/test_pom.xml" "//project/dependencies/dependency/artifactId[text()='junit']"
  assert_success
}

# Test modifying a POM file
@test "Modify POM file" {
  if ! verify_xmlstarlet; then
    skip "XMLStarlet not available, skipping tests"
  fi
  
  # Modify an existing element
  run xml_modify_pom "${TEST_DIR}/test_pom.xml" "//project/properties/jvm.fork.count" "2.0C"
  assert_success
  
  # Verify the modification
  run xml_query_pom "${TEST_DIR}/test_pom.xml" "//project/properties/jvm.fork.count"
  assert_success
  assert_output "2.0C"
  
  # Create a new element
  run xml_modify_pom "${TEST_DIR}/test_pom.xml" "//project/properties/new.property" "new-value" "true"
  assert_success
  
  # Verify the new element
  run xml_query_pom "${TEST_DIR}/test_pom.xml" "//project/properties/new.property"
  assert_success
  assert_output "new-value"
}

# Test updating Maven configuration
@test "Update Maven configuration in POM" {
  if ! verify_xmlstarlet; then
    skip "XMLStarlet not available, skipping tests"
  fi
  
  # Update Maven configuration
  run xml_update_maven_config "${TEST_DIR}/test_pom.xml" "4" "8" "2048"
  assert_success
  
  # Verify the updates
  run xml_get_maven_settings "${TEST_DIR}/test_pom.xml"
  assert_success
  assert_output "fork_count=4,threads=8,memory=2048M"
}

# Test POM restoration
@test "Restore POM file from backup" {
  if ! verify_xmlstarlet; then
    skip "XMLStarlet not available, skipping tests"
  fi
  
  # Create a backup
  cp "${TEST_DIR}/test_pom.xml" "${TEST_DIR}/test_pom.xml${POM_BACKUP_SUFFIX}"
  
  # Modify the original
  xml_modify_pom "${TEST_DIR}/test_pom.xml" "//project/properties/jvm.fork.count" "3.0C"
  
  # Verify the modification was made
  run xml_query_pom "${TEST_DIR}/test_pom.xml" "//project/properties/jvm.fork.count"
  assert_output "3.0C"
  
  # Restore from backup
  run xml_restore_pom "${TEST_DIR}/test_pom.xml"
  assert_success
  
  # Verify restoration
  run xml_query_pom "${TEST_DIR}/test_pom.xml" "//project/properties/jvm.fork.count"
  assert_output "1.0C"
}

# Test extracting Surefire configuration
@test "Extract Surefire configuration from POM" {
  if ! verify_xmlstarlet; then
    skip "XMLStarlet not available, skipping tests"
  fi
  
  run xml_extract_surefire_config "${TEST_DIR}/test_pom.xml"
  assert_success
  assert_output --partial "fork_count=1"
  assert_output --partial "reuse_forks=true"
  assert_output --partial "arg_line=-Xmx512m"
}