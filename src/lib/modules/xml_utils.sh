#!/usr/bin/env bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
#==============================================================================
# xml_utils.sh
#
# MVNimble - XML Utilities Module
#
# Description:
#   This module provides functions for XML manipulation using XMLStarlet.
#   It centralizes XML operations for generating, querying, and modifying
#   XML files, particularly Maven POM files.
#
# Usage:
#   source "path/to/xml_utils.sh"
#   xml_generate_fragment "plugin" "<groupId>org.apache.maven.plugins</groupId>..."
#   xml_query_pom "pom.xml" "//project/dependencies/dependency/artifactId"
#   xml_modify_pom "pom.xml" "//project/properties/jvm.fork.count" "4"
#
# Dependencies:
#   - XMLStarlet command-line utility
#   - constants.sh for exit codes and other constants
#
# Author: MVNimble Team
# Version: 1.0.0
#==============================================================================

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source required modules
if [[ -z "${CONSTANTS_LOADED+x}" ]]; then
  source "${SCRIPT_DIR}/constants.sh"
fi

# Verify XMLStarlet is installed
verify_xmlstarlet() {
  if ! command -v xmlstarlet >/dev/null 2>&1; then
    # Try the 'xml' command which is an alias on some systems
    if ! command -v xml >/dev/null 2>&1; then
      echo "ERROR: XMLStarlet not found. Please install XMLStarlet." >&2
      return ${EXIT_DEPENDENCY_ERROR}
    fi
  fi
  return ${EXIT_SUCCESS}
}

# Helper function to get the correct XMLStarlet command name
# Some systems use 'xmlstarlet', others use 'xml'
get_xmlstarlet_command() {
  if command -v xmlstarlet >/dev/null 2>&1; then
    echo "xmlstarlet"
  else
    echo "xml"
  fi
}

# Generate an XML fragment
# This function creates a valid XML fragment from a list of elements
#
# Usage:
#   xml_generate_fragment "root_element" "child1" "child2" ...
#
# Example:
#   xml_generate_fragment "plugin" "groupId>org.apache.maven.plugins</groupId" "artifactId>maven-surefire-plugin</artifactId"
xml_generate_fragment() {
  local root_element="$1"
  shift
  
  # Verify XMLStarlet is installed
  verify_xmlstarlet || return ${EXIT_DEPENDENCY_ERROR}
  
  # Get the correct XMLStarlet command
  local xml_cmd=$(get_xmlstarlet_command)
  
  # Create XML content
  local xml_content="<${root_element}>"
  for element in "$@"; do
    # Check if element has full tags, if not add them
    if [[ "$element" == *">"* ]]; then
      # Element already has tags, just add it
      xml_content+="<${element}"
    else
      # Element doesn't have tags, assume it's text content
      xml_content+="${element}"
    fi
  done
  xml_content+="</${root_element}>"
  
  # Format the XML
  echo "$xml_content" | $xml_cmd fo -o
}

# Generate a Maven Surefire plugin configuration fragment
#
# Usage:
#   xml_generate_surefire_config "forkCount" "reuseForks" "argLine" "parallel" "threadCount"
#
# Example:
#   xml_generate_surefire_config "1C" "true" "-Xmx1024m" "classes" "2"
xml_generate_surefire_config() {
  local fork_count="$1"
  local reuse_forks="$2"
  local arg_line="$3"
  local parallel="$4"
  local thread_count="$5"
  
  xml_generate_fragment "plugin" \
    "groupId>org.apache.maven.plugins</groupId" \
    "artifactId>maven-surefire-plugin</artifactId" \
    "configuration>
      <forkCount>${fork_count}</forkCount>
      <reuseForks>${reuse_forks}</reuseForks>
      <argLine>${arg_line}</argLine>
      <parallel>${parallel}</parallel>
      <threadCount>${thread_count}</threadCount>
    </configuration"
}

# Query a Maven POM file using XPath
#
# Usage:
#   xml_query_pom "pom_file" "xpath_expression" ["format"]
#
# Examples:
#   xml_query_pom "pom.xml" "//project/dependencies/dependency/artifactId"
#   xml_query_pom "pom.xml" "//project/properties/jvm.fork.count" "text"
xml_query_pom() {
  local pom_file="$1"
  local xpath="$2"
  local format="${3:-text}"  # Default format is text
  
  # Verify XMLStarlet is installed
  verify_xmlstarlet || return ${EXIT_DEPENDENCY_ERROR}
  
  # Verify POM file exists
  if [[ ! -f "$pom_file" ]]; then
    echo "ERROR: POM file not found: $pom_file" >&2
    return ${EXIT_FILE_ERROR}
  fi
  
  # Get the correct XMLStarlet command
  local xml_cmd=$(get_xmlstarlet_command)
  
  # Query the XML using XMLStarlet
  case "$format" in
    text)
      $xml_cmd sel -t -v "$xpath" "$pom_file" 2>/dev/null || echo ""
      ;;
    xml)
      $xml_cmd sel -t -c "$xpath" "$pom_file" 2>/dev/null || echo ""
      ;;
    count)
      $xml_cmd sel -t -v "count($xpath)" "$pom_file" 2>/dev/null || echo "0"
      ;;
    *)
      echo "ERROR: Unknown format: $format" >&2
      return ${EXIT_INVALID_ARGS}
      ;;
  esac
}

# Check if a specific element exists in a POM file
#
# Usage:
#   xml_element_exists "pom_file" "xpath_expression"
#
# Example:
#   if xml_element_exists "pom.xml" "//project/properties/jvm.fork.count"; then
#     echo "Fork count is defined"
#   fi
xml_element_exists() {
  local pom_file="$1"
  local xpath="$2"
  
  # Count occurrences
  local count=$(xml_query_pom "$pom_file" "$xpath" "count")
  
  # Return true if count > 0
  [[ "$count" -gt 0 ]]
}

# Get Maven settings from POM file
#
# Usage:
#   xml_get_maven_settings "pom_file"
#
# Example:
#   settings=$(xml_get_maven_settings "pom.xml")
#   echo "$settings"  # Output: fork_count=1C,threads=2,memory=1024M
xml_get_maven_settings() {
  local pom_file="$1"
  
  # Initialize default values
  local fork_count="1.0C"
  local maven_threads="1"
  local fork_memory="256M"
  
  # Get fork count from POM
  if xml_element_exists "$pom_file" "//project/properties/jvm.fork.count"; then
    local fc=$(xml_query_pom "$pom_file" "//project/properties/jvm.fork.count")
    [[ -n "$fc" ]] && fork_count="$fc"
  fi
  
  # Get thread count from POM
  if xml_element_exists "$pom_file" "//project/properties/maven.threads"; then
    local mt=$(xml_query_pom "$pom_file" "//project/properties/maven.threads")
    [[ -n "$mt" ]] && maven_threads="$mt"
  fi
  
  # Get memory settings from POM
  if xml_element_exists "$pom_file" "//project/properties/jvm.fork.memory"; then
    local fm=$(xml_query_pom "$pom_file" "//project/properties/jvm.fork.memory")
    [[ -n "$fm" ]] && fork_memory="$fm"
  fi
  
  # Return the settings string
  echo "fork_count=${fork_count},threads=${maven_threads},memory=${fork_memory}"
}

# Detect test frameworks used in the project
#
# Usage:
#   xml_detect_test_frameworks "pom_file"
#
# Example:
#   frameworks=$(xml_detect_test_frameworks "pom.xml")
#   echo "$frameworks"  # Output: junit5=true,testng=false,custom_dimensions=false
xml_detect_test_frameworks() {
  local pom_file="$1"
  
  # Initialize values
  local junit5="false"
  local testng="false"
  local custom_dimensions="false"
  local dimension_patterns=""
  
  # Check for JUnit 5
  if xml_element_exists "$pom_file" "//project/dependencies/dependency/artifactId[text()='junit-jupiter']" ||
     xml_element_exists "$pom_file" "//project/dependencies/dependency/artifactId[text()='junit-jupiter-api']"; then
    junit5="true"
  fi
  
  # Check for TestNG
  if xml_element_exists "$pom_file" "//project/dependencies/dependency/artifactId[text()='testng']"; then
    testng="true"
  fi
  
  # Check for custom dimensions
  if grep -q "test.dimension" "$pom_file"; then
    custom_dimensions="true"
    
    # Extract dimension patterns
    # We still use grep here as XPath can't easily extract these from property values
    dimension_patterns=$(grep -A 30 "<profile>" "$pom_file" | grep "test.dimension=" | sort | uniq | cut -d= -f2 | cut -d'<' -f1 | tr -d ' ')
  fi
  
  # Return the frameworks string
  echo "junit5=${junit5},testng=${testng},custom_dimensions=${custom_dimensions},dimension_patterns=${dimension_patterns}"
}

# Modify a Maven POM file
#
# Usage:
#   xml_modify_pom "pom_file" "xpath_expression" "new_value" ["create"]
#
# Examples:
#   xml_modify_pom "pom.xml" "//project/properties/jvm.fork.count" "4"
#   xml_modify_pom "pom.xml" "//project/properties/jvm.fork.memory" "1024M" "true"
xml_modify_pom() {
  local pom_file="$1"
  local xpath="$2"
  local new_value="$3"
  local create="${4:-false}"  # Whether to create the element if it doesn't exist
  
  # Verify XMLStarlet is installed
  verify_xmlstarlet || return ${EXIT_DEPENDENCY_ERROR}
  
  # Verify POM file exists
  if [[ ! -f "$pom_file" ]]; then
    echo "ERROR: POM file not found: $pom_file" >&2
    return ${EXIT_FILE_ERROR}
  fi
  
  # Create a backup if it doesn't exist
  if [[ ! -f "${pom_file}${POM_BACKUP_SUFFIX}" ]]; then
    cp "$pom_file" "${pom_file}${POM_BACKUP_SUFFIX}"
  fi
  
  # Get the correct XMLStarlet command
  local xml_cmd=$(get_xmlstarlet_command)
  
  # Check if the element exists
  if xml_element_exists "$pom_file" "$xpath"; then
    # Element exists, update it
    $xml_cmd ed --inplace -u "$xpath" -v "$new_value" "$pom_file"
  elif [[ "$create" == "true" ]]; then
    # Element doesn't exist but we want to create it
    # This is complex and depends on the xpath structure
    # For simplicity, we'll handle a few common cases
    
    # Extract parent path and element name
    local parent_path=$(dirname "$xpath")
    local element_name=$(basename "$xpath")
    
    # Check if the parent exists
    if xml_element_exists "$pom_file" "$parent_path"; then
      # Add the element to the parent
      $xml_cmd ed --inplace -s "$parent_path" -t elem -n "$element_name" -v "$new_value" "$pom_file"
    else
      echo "ERROR: Cannot create element: parent path does not exist: $parent_path" >&2
      return ${EXIT_INVALID_ARGS}
    fi
  else
    echo "ERROR: Element does not exist: $xpath" >&2
    return ${EXIT_INVALID_ARGS}
  fi
  
  return ${EXIT_SUCCESS}
}

# Update Maven configuration in POM file
#
# Usage:
#   xml_update_maven_config "pom_file" "fork_count" "threads" "heap_size"
#
# Example:
#   xml_update_maven_config "pom.xml" "4" "8" "2048"
xml_update_maven_config() {
  local pom_file="$1"
  local fork_count="$2"
  local threads="$3"
  local heap_size="$4"
  
  # Create a backup if it doesn't exist
  if [[ ! -f "${pom_file}${POM_BACKUP_SUFFIX}" ]]; then
    cp "$pom_file" "${pom_file}${POM_BACKUP_SUFFIX}"
  fi
  
  # Verify XMLStarlet is installed
  verify_xmlstarlet || return ${EXIT_DEPENDENCY_ERROR}
  
  # Make sure properties section exists
  if ! xml_element_exists "$pom_file" "//project/properties"; then
    # Get the correct XMLStarlet command
    local xml_cmd=$(get_xmlstarlet_command)
    
    # Create properties section
    $xml_cmd ed --inplace -s "//project" -t elem -n "properties" "$pom_file"
  fi
  
  # Update fork count
  xml_modify_pom "$pom_file" "//project/properties/jvm.fork.count" "$fork_count" "true"
  
  # Update thread count
  xml_modify_pom "$pom_file" "//project/properties/maven.threads" "$threads" "true"
  
  # Update heap size
  xml_modify_pom "$pom_file" "//project/properties/jvm.fork.memory" "${heap_size}M" "true"
  
  return ${EXIT_SUCCESS}
}

# Restore original POM file from backup
#
# Usage:
#   xml_restore_pom "pom_file"
#
# Example:
#   xml_restore_pom "pom.xml"
xml_restore_pom() {
  local pom_file="$1"
  
  if [[ -f "${pom_file}${POM_BACKUP_SUFFIX}" ]]; then
    cp "${pom_file}${POM_BACKUP_SUFFIX}" "$pom_file"
    echo "Restored original POM file: $pom_file"
    return ${EXIT_SUCCESS}
  else
    echo "ERROR: No backup file found for $pom_file" >&2
    return ${EXIT_FILE_ERROR}
  fi
}

# Extract Maven Surefire configuration for reporting
#
# Usage:
#   xml_extract_surefire_config "pom_file"
#
# Example:
#   config=$(xml_extract_surefire_config "pom.xml")
#   echo "$config"
xml_extract_surefire_config() {
  local pom_file="$1"
  
  # Find Surefire plugin configuration
  local surefire_config=""
  
  if xml_element_exists "$pom_file" "//project/build/plugins/plugin[artifactId='maven-surefire-plugin']/configuration"; then
    surefire_config=$(xml_query_pom "$pom_file" \
      "//project/build/plugins/plugin[artifactId='maven-surefire-plugin']/configuration" "xml")
  fi
  
  # Extract key settings
  local fork_count="Not specified (defaults to 1)"
  local reuse_forks="Not specified (defaults to true)"
  local arg_line="Not specified"
  
  if [[ -n "$surefire_config" ]]; then
    if xml_element_exists "$pom_file" \
      "//project/build/plugins/plugin[artifactId='maven-surefire-plugin']/configuration/forkCount"; then
      fork_count=$(xml_query_pom "$pom_file" \
        "//project/build/plugins/plugin[artifactId='maven-surefire-plugin']/configuration/forkCount")
    fi
    
    if xml_element_exists "$pom_file" \
      "//project/build/plugins/plugin[artifactId='maven-surefire-plugin']/configuration/reuseForks"; then
      reuse_forks=$(xml_query_pom "$pom_file" \
        "//project/build/plugins/plugin[artifactId='maven-surefire-plugin']/configuration/reuseForks")
    fi
    
    if xml_element_exists "$pom_file" \
      "//project/build/plugins/plugin[artifactId='maven-surefire-plugin']/configuration/argLine"; then
      arg_line=$(xml_query_pom "$pom_file" \
        "//project/build/plugins/plugin[artifactId='maven-surefire-plugin']/configuration/argLine")
    fi
  fi
  
  echo "fork_count=${fork_count},reuse_forks=${reuse_forks},arg_line=${arg_line}"
}