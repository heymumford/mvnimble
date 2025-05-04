#!/usr/bin/env bash
# test_tags.bash
# Support for test tags in BATS tests

# Global variables for tag filtering
TAGS_INCLUDE=""
TAGS_EXCLUDE=""

# Parse a test's tags from its definition
parse_test_tags() {
  local test_name="$1"
  local test_file="$2"
  
  # Attempt to find the line with the test definition
  local test_line
  test_line=$(grep -n "@test \"$test_name\"" "$test_file" | cut -d':' -f1)
  
  if [ -z "$test_line" ]; then
    # Test not found, return empty tags
    echo ""
    return 0
  fi
  
  # Look for tag annotations in the line before the test
  local tag_line=$((test_line - 1))
  local tags=$(sed -n "${tag_line}p" "$test_file" | grep -o '@[a-zA-Z0-9_-]*' || echo "")
  
  echo "$tags"
}

# Check if a test should be run based on its tags
should_run_test() {
  local test_name="$1"
  local test_file="$2"
  
  # If no tag filters are set, run all tests
  if [ -z "$TAGS_INCLUDE" ] && [ -z "$TAGS_EXCLUDE" ]; then
    return 0
  fi
  
  # Get test tags
  local test_tags
  test_tags=$(parse_test_tags "$test_name" "$test_file")
  
  # If test has no tags, check if untagged tests should run
  if [ -z "$test_tags" ]; then
    # If including specific tags, skip untagged tests
    if [ -n "$TAGS_INCLUDE" ]; then
      return 1
    else
      # If only excluding tags, run untagged tests
      return 0
    fi
  fi
  
  # Check if any include tag matches
  if [ -n "$TAGS_INCLUDE" ]; then
    local found=1
    for tag in $TAGS_INCLUDE; do
      if [[ "$test_tags" == *"$tag"* ]]; then
        found=0
        break
      fi
    done
    
    # If no include tag matches, skip the test
    if [ $found -eq 1 ]; then
      return 1
    fi
  fi
  
  # Check if any exclude tag matches
  if [ -n "$TAGS_EXCLUDE" ]; then
    for tag in $TAGS_EXCLUDE; do
      if [[ "$test_tags" == *"$tag"* ]]; then
        # If an exclude tag matches, skip the test
        return 1
      fi
    done
  fi
  
  # If we get here, the test should run
  return 0
}

# Set tag filters for including tests
set_tag_include() {
  TAGS_INCLUDE="$1"
}

# Set tag filters for excluding tests
set_tag_exclude() {
  TAGS_EXCLUDE="$1"
}

# Skip test if it doesn't match tag filters
skip_if_tag_mismatch() {
  # Get the test name from BATS_TEST_NAME
  local test_name="${BATS_TEST_NAME#* }"
  test_name="${test_name%\"*}"
  
  # Get the test file from BATS_TEST_FILENAME
  local test_file="$BATS_TEST_FILENAME"
  
  # Check if the test should run
  if ! should_run_test "$test_name" "$test_file"; then
    skip "Test skipped due to tag filtering"
  fi
}

# Add test setup function that checks tags
bats_test_setup() {
  # Call the original setup function if it exists
  if declare -F setup > /dev/null; then
    setup
  fi
  
  # Check tag filtering
  skip_if_tag_mismatch
}

# Override BATS test setup to include tag filtering
setup() {
  # This can be overridden by test files
  :
}

# Extract statistics about test tags
get_tag_statistics() {
  local test_dir="$1"
  local stats=()
  
  # Find all test files
  local test_files
  test_files=$(find "$test_dir" -name "*.bats")
  
  # Loop through files
  for file in $test_files; do
    # Get all tag lines (comments starting with #)
    local tag_lines
    tag_lines=$(grep -n "^# @" "$file" | cut -d':' -f1)
    
    # Get test definition lines (lines with @test)
    local test_lines
    test_lines=$(grep -n "@test" "$file" | cut -d':' -f1)
    
    # Pair each test with its tags
    for test_line in $test_lines; do
      local test_name
      test_name=$(sed -n "${test_line}p" "$file" | grep -o '"[^"]*"' | sed 's/"//g')
      
      # Find closest tag line before this test
      local closest_tag_line=0
      for tag_line in $tag_lines; do
        if [ "$tag_line" -lt "$test_line" ] && [ "$tag_line" -gt "$closest_tag_line" ]; then
          closest_tag_line=$tag_line
        fi
      done
      
      # Get the tags if a tag line was found
      if [ "$closest_tag_line" -gt 0 ]; then
        local tags
        tags=$(sed -n "${closest_tag_line}p" "$file" | grep -o '@[a-zA-Z0-9_-]*')
        
        # Add to statistics
        for tag in $tags; do
          stats+=("$tag")
        done
      fi
    done
  done
  
  # Return the stats array
  echo "${stats[@]}"
}