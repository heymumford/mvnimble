#\!/usr/bin/env bash
# adr_helpers.bash
# Helper functions for testing ADRs

# Extract ADR section content
# Arguments:
#   $1 - ADR file path
#   $2 - Section name (e.g. "Status", "Context")
extract_adr_section() {
  local adr_file="$1"
  local section="$2"
  
  # Get content from the section to the next section
  sed -n "/^## ${section}/,/^## /p" "$adr_file" | 
    grep -v "^## ${section}" | 
    grep -v "^## " | 
    grep -v "^$"
}

# Check if an ADR follows the standard format
# Arguments:
#   $1 - ADR file path
check_adr_format() {
  local adr_file="$1"
  local missing_sections=0
  
  # Check the title format
  if \! grep -q "^# ADR [0-9]\{3\}:" "$adr_file"; then
    echo "Missing or invalid title"
    ((missing_sections++))
  fi
  
  # Check required sections
  local required_sections=("Status" "Context" "Decision" "Consequences")
  
  for section in "${required_sections[@]}"; do
    if \! grep -q "^## ${section}" "$adr_file"; then
      echo "Missing section: ${section}"
      ((missing_sections++))
    fi
  done
  
  # Check status content
  local status_content
  status_content=$(extract_adr_section "$adr_file" "Status")
  if [ -z "$status_content" ]; then
    echo "Empty Status section"
    ((missing_sections++))
  fi
  
  # Check consequences subsections
  if \! grep -q "### Positive" "$adr_file"; then
    echo "Missing subsection: Positive consequences"
    ((missing_sections++))
  fi
  
  if \! grep -q "### Negative" "$adr_file"; then
    echo "Missing subsection: Negative consequences"
    ((missing_sections++))
  fi
  
  return $missing_sections
}

# Validate ADR filename format
# Arguments:
#   $1 - ADR filename
validate_adr_filename() {
  local filename="$1"
  
  # Check format: NNN-kebab-case.md
  [[ "$filename" =~ ^[0-9]{3}-[a-z0-9-]+\.md$ ]]
  return $?
}

# Extract ADR number from filename
# Arguments:
#   $1 - ADR filename
extract_adr_number() {
  local filename="$1"
  echo "${filename:0:3}"
}

# Extract ADR title from file
# Arguments:
#   $1 - ADR file path
extract_adr_title() {
  local adr_file="$1"
  
  # Extract title from the first line
  head -1 "$adr_file" | sed 's/^# ADR [0-9]*: //'
}

# Check if an ADR has references to other ADRs
# Arguments:
#   $1 - ADR file path
# Returns:
#   Space-separated list of referenced ADR numbers
find_adr_references() {
  local adr_file="$1"
  
  # Find references in format "ADR NNN"
  grep -o "ADR [0-9]\{3\}" "$adr_file" | 
    grep -v "$(basename "$adr_file" | cut -c1-3)" | # Exclude self-references
    sed 's/ADR //' | 
    sort -u | 
    tr '\n' ' ' | 
    xargs
}

# Check readability metrics
# Arguments:
#   $1 - ADR file path
# Returns:
#   0 if readability metrics are good, 1 otherwise
check_readability() {
  local adr_file="$1"
  
  # Count sentences (roughly)
  local sentences
  sentences=$(grep -o '\. [A-Z]' "$adr_file" | wc -l)
  sentences=$((sentences + 1)) # Add one for the last sentence
  
  # Count words
  local words
  words=$(wc -w < "$adr_file")
  
  # Count bullet points
  local bullet_points
  bullet_points=$(grep -c "^ *[-*]" "$adr_file")
  
  # Skip files with too few sentences
  if [ "$sentences" -lt 5 ]; then
    return 0
  fi
  
  # Calculate average sentence length
  local avg_sentence_length=$((words / sentences))
  
  # Average sentence length should be reasonable (< 25 words)
  if [ "$avg_sentence_length" -ge 25 ]; then
    return 1
  fi
  
  # For longer ADRs, expect bullet points for clarity
  local file_length
  file_length=$(wc -l < "$adr_file")
  
  if [ "$file_length" -gt 50 ] && [ "$bullet_points" -lt 3 ]; then
    return 1
  fi
  
  return 0
}
