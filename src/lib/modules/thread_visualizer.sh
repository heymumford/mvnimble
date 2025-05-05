#!/usr/bin/env bash
# thread_visualizer.sh - Module for visualizing thread interactions
#
# This module provides functions to visualize thread interactions and
# diagnose concurrency issues from thread dumps.
#
# It generates mermaid diagrams that can be embedded in markdown documents
# and HTML reports to help diagnose flaky tests caused by thread safety issues.

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source required modules if not already loaded
if [[ -z "${CONSTANTS_LOADED+x}" ]]; then
  source "${SCRIPT_DIR}/constants.sh"
fi

# Use common functions if they exist
if [[ -f "${SCRIPT_DIR}/common.sh" ]]; then
  source "${SCRIPT_DIR}/common.sh"
else
  # Define minimal versions of common functions if not available
  function print_info() { echo -e "\033[0;34m$1\033[0m"; }
  function print_success() { echo -e "\033[0;32m$1\033[0m"; }
  function print_warning() { echo -e "\033[0;33m$1\033[0m"; }
  function print_error() { echo -e "\033[0;31m$1\033[0m" >&2; }
  function ensure_directory() { mkdir -p "$1"; }
fi

# Validates input parameters for visualization functions
# Parameters:
#   $1 - input thread dump file
#   $2 - output file path
# Returns:
#   0 if parameters are valid, 1 otherwise
validate_visualization_params() {
  local input_file="$1"
  local output_file="$2"
  
  if [[ -z "$input_file" ]]; then
    print_error "Input file is required"
    return 1
  fi
  
  if [[ ! -f "$input_file" ]]; then
    print_error "Input file doesn't exist: $input_file"
    return 1
  fi
  
  # Check if file is empty
  if [[ ! -s "$input_file" ]]; then
    print_error "Input file is empty: $input_file"
    return 1
  fi
  
  if [[ -z "$output_file" ]]; then
    print_error "Output file is required"
    return 1
  fi
  
  # Make sure parent directory exists for output file
  local output_dir="$(dirname "$output_file")"
  if ! ensure_directory "$output_dir" 2>/dev/null; then
    print_error "Cannot create directory: $output_dir"
    return 1
  fi
  
  # Check if directory is writable
  if [[ ! -w "$output_dir" ]]; then
    print_error "Permission denied: Cannot write to $output_dir"
    return 1
  fi
  
  # Check if input file is valid JSON if jq is available
  if command -v jq &> /dev/null; then
    if ! jq empty "$input_file" 2>/dev/null; then
      print_warning "Invalid JSON format in input file: $input_file"
      # We'll continue and try to handle errors gracefully rather than failing
    fi
    
    # Check if thread data exists
    if [[ "$(jq 'has("threads")' "$input_file" 2>/dev/null)" != "true" ]]; then
      print_warning "No thread data found in input file: $input_file"
      # We'll continue with empty thread set rather than failing
    fi
  fi
  
  return 0
}

# Generate mermaid diagram from thread dump
# Parameters:
#   $1 - input thread dump file
#   $2 - output diagram file
generate_thread_diagram() {
  local input_file="$1"
  local output_file="$2"
  
  # Validate parameters
  if ! validate_visualization_params "$input_file" "$output_file"; then
    return 1
  fi
  
  # Check if jq is available
  if ! command -v jq &> /dev/null; then
    print_warning "jq not found, using simple thread diagram generation"
    # Create a simple diagram without parsing JSON
    {
      echo '```mermaid'
      echo 'graph TD'
      echo '  subgraph "Thread Interaction (Simple View - jq not available)"'
      echo '    Main["Main Thread"] --> Code["Application Code"]'
      echo '    Worker1["Worker Thread 1"] --> SharedResource["Shared Resource"]'
      echo '    Worker2["Worker Thread 2"] --> SharedResource'
      echo '    SharedResource --> Contention["Potential Contention Point"]'
      echo '  end'
      echo '```'
    } > "$output_file"
    return 0
  fi
  
  # Parse thread dump using jq, with fallback for missing timestamp
  local timestamp
  timestamp=$(jq -r '.timestamp // "Unknown"' "$input_file")
  
  # Check if there are any threads
  local thread_count
  thread_count=$(jq '.threads | length // 0' "$input_file")
  
  # Start building the mermaid diagram
  {
    echo '```mermaid'
    echo 'graph TD'
    echo "  %% Thread Interaction Diagram generated from thread dump at $timestamp"
    
    if [[ "$thread_count" -eq 0 ]]; then
      # No threads found, create empty diagram with note
      echo '  No_Threads["No threads found in thread dump"]'
      echo '  style No_Threads fill:#f96,stroke:#333,stroke-width:1px'
    else
      # Add thread states subgraph
      echo '  subgraph "Thread States"'
      
      # Add each thread to the diagram with error handling
      jq -r '.threads[] | 
        "    Thread\(.id // "unknown")[\"Thread \(.id // "?"): \(.name // "unnamed") (\(.state // "UNKNOWN"))\"]:::\((.state | ascii_downcase) // "unknown")"' "$input_file" 2>/dev/null || echo '    UnknownThread["Error parsing thread data"]'
      
      echo '  end'
    fi
  } > "$output_file"
  
  # Add lock information if any exists
  local lock_count
  lock_count=$(jq '.locks | length // 0' "$input_file")
  
  if [[ "$lock_count" -gt 0 ]]; then
    echo '  subgraph "Locks"' >> "$output_file"
    
    # Add each lock with error handling
    jq -r '.locks[] | 
      "    Lock\((.identity | gsub("[^a-zA-Z0-9]"; "")) // "unknown")[\"Lock: \(.identity // "unknown")\"]"' "$input_file" 2>/dev/null || echo '    UnknownLock["Error parsing lock data"]' >> "$output_file"
    
    echo '  end' >> "$output_file"
    
    # Add lock relationships with error handling
    jq -r '.locks[] | 
      "  Lock\((.identity | gsub("[^a-zA-Z0-9]"; "")) // "unknown") --> Thread\(.owner_thread // "unknown") %% Owner"' "$input_file" 2>/dev/null || true >> "$output_file"
    
    jq -r '.locks[] | 
      select(.waiting_threads | length > 0) |
      .waiting_threads[] | 
      "  Thread\(.) -.-> Lock\((.parent.identity | gsub("[^a-zA-Z0-9]"; "")) // "unknown") %% Waiting"' "$input_file" 2>/dev/null || true >> "$output_file"
  elif [[ "$thread_count" -gt 0 ]]; then
    # If we have threads but no locks, add a note
    echo '  No_Locks["No locks found in thread dump"]' >> "$output_file"
    echo '  style No_Locks fill:#f96,stroke:#333,stroke-width:1px' >> "$output_file"
  fi
  
  # Add CSS classes for thread states
  echo '' >> "$output_file"
  echo '  %% Thread state styling' >> "$output_file"
  echo '  classDef runnable fill:green,stroke:#333,stroke-width:1px,color:white' >> "$output_file"
  echo '  classDef blocked fill:red,stroke:#333,stroke-width:1px,color:white' >> "$output_file"
  echo '  classDef waiting fill:orange,stroke:#333,stroke-width:1px,color:white' >> "$output_file"
  echo '  classDef timed_waiting fill:yellow,stroke:#333,stroke-width:1px,color:black' >> "$output_file"
  echo '  classDef terminated fill:gray,stroke:#333,stroke-width:1px,color:white' >> "$output_file"
  echo '  classDef new fill:blue,stroke:#333,stroke-width:1px,color:white' >> "$output_file"
  echo '```' >> "$output_file"
  
  print_success "Generated thread diagram: $output_file"
  return 0
}

# Generate a thread interaction timeline
# Parameters:
#   $1 - input thread dump file
#   $2 - output timeline file
generate_thread_timeline() {
  local input_file="$1"
  local output_file="$2"
  
  # Validate parameters
  if ! validate_visualization_params "$input_file" "$output_file"; then
    return 1
  fi
  
  # Check if jq is available
  if ! command -v jq &> /dev/null; then
    print_warning "jq not found, using simple timeline generation"
    # Create a simple timeline without parsing JSON
    {
      echo '```mermaid'
      echo 'gantt'
      echo '  title Thread Execution Timeline (Simple View - jq not available)'
      echo '  dateFormat X'
      echo '  axisFormat %s'
      echo '  section Main Thread'
      echo '  Execution: 0, 100'
      echo '  section Worker Thread 1'
      echo '  Execution: 0, 50'
      echo '  Lock Acquisition: 50, 80'
      echo '  section Worker Thread 2'
      echo '  Execution: 0, 60'
      echo '  Waiting for Lock: 60, 80'
      echo '```'
    } > "$output_file"
    return 0
  fi
  
  # Parse thread dump using jq
  local timestamp
  timestamp=$(jq -r '.timestamp' "$input_file")
  
  # Start building the mermaid Gantt chart
  {
    echo '```mermaid'
    echo 'gantt'
    echo "  title Thread Execution Timeline for dump at $timestamp"
    echo '  dateFormat X'
    echo '  axisFormat %s'
  } > "$output_file"
  
  # Add each thread to the timeline
  # Using "ascii_downcase" instead of "tolower" for compatibility with older jq versions
  jq -r '.threads[] | "  section Thread \(.id): \(.name)\n  \(.state | ascii_downcase): 0, 100"' "$input_file" >> "$output_file"
  
  # Add lock information if available
  jq -r '.locks[] | 
    "  Lock \(.identity) held by Thread \(.owner_thread): 50, 100"' "$input_file" 2>/dev/null >> "$output_file" || true
  
  # Add waiting threads
  jq -r '.locks[] | .waiting_threads[] | 
    "  Thread \(.) waiting for \(.parent.identity): 60, 100"' "$input_file" 2>/dev/null >> "$output_file" || true
  
  echo '```' >> "$output_file"
  
  print_success "Generated thread timeline: $output_file"
  return 0
}

# Generate a lock contention graph
# Parameters:
#   $1 - input thread dump file
#   $2 - output graph file
generate_lock_contention_graph() {
  local input_file="$1"
  local output_file="$2"
  
  # Validate parameters
  if ! validate_visualization_params "$input_file" "$output_file"; then
    return 1
  fi
  
  # Check if jq is available
  if ! command -v jq &> /dev/null; then
    print_warning "jq not found, using simple lock contention graph generation"
    # Create a simple graph without parsing JSON
    {
      echo '```mermaid'
      echo 'flowchart TD'
      echo '  Lock1["Lock 1"] --> Thread1["Thread 1 (owner)"]'
      echo '  Lock1 -.-> Thread2["Thread 2 (waiting)"]'
      echo '  subgraph Locks'
      echo '    Lock1'
      echo '  end'
      echo '  subgraph Threads'
      echo '    Thread1'
      echo '    Thread2'
      echo '  end'
      echo '```'
    } > "$output_file"
    return 0
  fi
  
  # Check for deadlocks
  local deadlock_detected=false
  local deadlock_threads=()
  local deadlock_locks=()
  
  # Algorithm to detect deadlocks:
  # For each thread T1 that is waiting for a lock L1:
  #   Find the owner thread T2 of L1
  #   If T2 is waiting for a lock L2 owned by T1, we have a deadlock
  
  if [[ -n "$(jq '.locks' "$input_file")" && "$(jq '.locks | length' "$input_file")" -gt 0 ]]; then
    # Create a temporary file for deadlock detection
    local tmp_file
    tmp_file=$(mktemp)
    
    # For each thread that is waiting for a lock, find what locks it holds
    jq -r '.locks[] | 
      select(.waiting_threads | length > 0) | 
      .waiting_threads[] as $wt | 
      $wt as $waiting_thread | 
      .identity as $lock_identity | 
      .owner_thread as $owner | 
      { 
        "waiting_thread": $waiting_thread, 
        "waiting_for": $lock_identity, 
        "owner": $owner 
      }' "$input_file" > "$tmp_file"
    
    # If the waiting thread holds locks that the owner thread is waiting for, it's a deadlock
    while IFS= read -r waiting_thread_info; do
      local waiting_thread owner_thread lock_identity
      waiting_thread=$(echo "$waiting_thread_info" | jq -r '.waiting_thread')
      owner_thread=$(echo "$waiting_thread_info" | jq -r '.owner')
      lock_identity=$(echo "$waiting_thread_info" | jq -r '.waiting_for')
      
      # Check if the owner thread is waiting for a lock held by the waiting thread
      local owner_waiting_for
      # This is a simplification - in a real implementation you'd need a more robust algorithm
      owner_waiting_for=$(jq -r --arg owner "$owner_thread" --arg waiting "$waiting_thread" '
        .locks[] | 
        select(.owner_thread == ($waiting | tonumber)) |
        select(.waiting_threads | map(. == ($owner | tonumber)) | any) |
        .identity' "$input_file")
      
      if [[ -n "$owner_waiting_for" && "$owner_waiting_for" != "null" ]]; then
        deadlock_detected=true
        deadlock_threads+=("$waiting_thread" "$owner_thread")
        deadlock_locks+=("$lock_identity" "$owner_waiting_for")
      fi
    done < <(jq -c '.' "$tmp_file")
    
    rm "$tmp_file"
  fi
  
  # Start building the mermaid flowchart
  {
    echo '```mermaid'
    echo 'flowchart TD'
  } > "$output_file"
  
  # If deadlock detected, highlight it
  if [[ "$deadlock_detected" == "true" ]]; then
    local unique_deadlock_threads
    unique_deadlock_threads=($(printf "%s\n" "${deadlock_threads[@]}" | sort -u))
    local unique_deadlock_locks
    unique_deadlock_locks=($(printf "%s\n" "${deadlock_locks[@]}" | sort -u))
    
    echo '  subgraph "⚠️ DEADLOCK DETECTED ⚠️"' >> "$output_file"
    echo '    direction LR' >> "$output_file"
    
    # Create node for each thread in deadlock
    for thread in "${unique_deadlock_threads[@]}"; do
      local thread_name
      thread_name=$(jq -r --arg tid "$thread" '.threads[] | select(.id == ($tid | tonumber)) | .name' "$input_file")
      echo "    Thread${thread}[\"Thread ${thread}: ${thread_name}\"]:::deadlock" >> "$output_file"
    done
    
    # Create node for each lock in deadlock
    for lock in "${unique_deadlock_locks[@]}"; do
      local lock_id
      lock_id=$(echo "$lock" | sed 's/[^a-zA-Z0-9]//g')
      echo "    Lock${lock_id}[\"${lock}\"]:::deadlock_lock" >> "$output_file"
    done
    
    # Create edges for ownership and waiting
    for ((i=0; i<${#deadlock_threads[@]}; i+=2)); do
      local t1=${deadlock_threads[$i]}
      local t2=${deadlock_threads[$i+1]}
      local l1=${deadlock_locks[$i]}
      local l2=${deadlock_locks[$i+1]}
      local l1_id=${l1//[^a-zA-Z0-9]/}
      local l2_id=${l2//[^a-zA-Z0-9]/}
      
      echo "    Thread${t2} -->|holds| Lock${l1_id}" >> "$output_file"
      echo "    Thread${t1} -.->|waiting for| Lock${l1_id}" >> "$output_file"
      echo "    Thread${t1} -->|holds| Lock${l2_id}" >> "$output_file"
      echo "    Thread${t2} -.->|waiting for| Lock${l2_id}" >> "$output_file"
    done
    
    echo '  end' >> "$output_file"
    
    # Add warning node
    echo '  DeadlockWarning["⚠️ DEADLOCK DETECTED: Circular wait between threads!"]' >> "$output_file"
    echo '  style DeadlockWarning fill:#ff0000,stroke:#333,stroke-width:2px,color:#fff,font-weight:bold' >> "$output_file"
  else
    # No deadlock, just show regular lock contention
    echo '  subgraph "Lock Ownership"' >> "$output_file"
    
    # Add locks and their relationships
    jq -r '.locks[] | 
      "    Lock\(.identity | gsub("[^a-zA-Z0-9]"; ""))[\"Lock: \(.identity)\"]"' "$input_file" >> "$output_file" || true
    
    echo '  end' >> "$output_file"
    
    echo '  subgraph "Threads"' >> "$output_file"
    # Add each thread
    jq -r '.threads[] | 
      "    Thread\(.id)[\"Thread \(.id): \(.name) (\(.state))\"]:::\(.state | ascii_downcase)"' "$input_file" >> "$output_file"
    echo '  end' >> "$output_file"
    
    # Add lock relationships
    jq -r '.locks[] | "  Lock\(.identity | gsub("[^a-zA-Z0-9]"; "")) --> Thread\(.owner_thread)[\"Thread \(.owner_thread) (owner)\"]"' "$input_file" >> "$output_file" || true
    
    # Add waiting relationships
    jq -r '.locks[] | 
      .waiting_threads[] as $wt | 
      "  Thread\($wt)[\"Thread \($wt) (waiting)\"] -.-> Lock\(.identity | gsub("[^a-zA-Z0-9]"; ""))"' "$input_file" 2>/dev/null >> "$output_file" || true
  fi
  
  # Add CSS classes
  echo '' >> "$output_file"
  echo '  %% Thread state styling' >> "$output_file"
  echo '  classDef runnable fill:green,stroke:#333,stroke-width:1px,color:white' >> "$output_file"
  echo '  classDef blocked fill:red,stroke:#333,stroke-width:1px,color:white' >> "$output_file"
  echo '  classDef waiting fill:orange,stroke:#333,stroke-width:1px,color:white' >> "$output_file"
  echo '  classDef timed_waiting fill:yellow,stroke:#333,stroke-width:1px,color:black' >> "$output_file"
  echo '  classDef deadlock fill:#ff6666,stroke:#990000,stroke-width:2px,color:white,font-weight:bold' >> "$output_file"
  echo '  classDef deadlock_lock fill:#990000,stroke:#ff0000,stroke-width:2px,color:white,font-weight:bold' >> "$output_file"
  echo '```' >> "$output_file"
  
  if [[ "$deadlock_detected" == "true" ]]; then
    print_warning "Deadlock detected! Visualization saved to: $output_file"
  else
    print_success "Generated lock contention graph: $output_file"
  fi
  
  return 0
}

# Generate HTML visualization of thread interactions
# Parameters:
#   $1 - input thread dump file
#   $2 - output HTML file
generate_thread_visualization() {
  local input_file="$1"
  local output_file="$2"
  
  # Validate parameters
  if ! validate_visualization_params "$input_file" "$output_file"; then
    return 1
  fi
  
  # Create temporary files for each visualization
  local tmp_dir
  tmp_dir=$(mktemp -d)
  local thread_diagram="${tmp_dir}/thread_diagram.md"
  local thread_timeline="${tmp_dir}/thread_timeline.md"
  local lock_contention="${tmp_dir}/lock_contention.md"
  
  # Generate each visualization
  generate_thread_diagram "$input_file" "$thread_diagram"
  generate_thread_timeline "$input_file" "$thread_timeline"
  generate_lock_contention_graph "$input_file" "$lock_contention"
  
  # Extract timestamp from thread dump
  local timestamp="Unknown"
  if command -v jq &> /dev/null; then
    timestamp=$(jq -r '.timestamp // "Unknown"' "$input_file")
  fi
  
  # Create the HTML file
  {
    echo '<!DOCTYPE html>'
    echo '<html lang="en">'
    echo '<head>'
    echo '  <meta charset="UTF-8">'
    echo '  <meta name="viewport" content="width=device-width, initial-scale=1.0">'
    echo '  <title>Thread Interaction Visualization</title>'
    echo '  <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>'
    echo '  <script>mermaid.initialize({startOnLoad:true});</script>'
    echo '  <style>'
    echo '    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; padding: 20px; max-width: 1200px; margin: 0 auto; color: #333; }'
    echo '    h1, h2, h3 { margin-top: 30px; color: #0366d6; }'
    echo '    h1 { border-bottom: 1px solid #eaecef; padding-bottom: 10px; }'
    echo '    .visualization-container { margin: 20px 0; padding: 20px; border: 1px solid #e1e4e8; border-radius: 6px; background-color: #f6f8fa; }'
    echo '    .timestamp { color: #666; font-style: italic; }'
    echo '    .legend { display: flex; flex-wrap: wrap; margin: 20px 0; }'
    echo '    .legend-item { display: flex; align-items: center; margin-right: 15px; margin-bottom: 5px; }'
    echo '    .legend-color { width: 20px; height: 20px; margin-right: 5px; border: 1px solid #333; }'
    echo '    .runnable { background-color: green; }'
    echo '    .blocked { background-color: red; }'
    echo '    .waiting { background-color: orange; }'
    echo '    .timed_waiting { background-color: yellow; }'
    echo '    .deadlock { background-color: #ff6666; }'
    echo '    .deadlock-warning { background-color: #ff0000; color: white; padding: 10px; border-radius: 5px; margin: 20px 0; font-weight: bold; }'
    echo '    pre { white-space: pre-wrap; }'
    echo '    .tab-container { margin-top: 20px; }'
    echo '    .tab-buttons { display: flex; margin-bottom: -1px; }'
    echo '    .tab-button { padding: 10px 20px; border: 1px solid #e1e4e8; background-color: #f6f8fa; cursor: pointer; border-bottom: none; border-radius: 6px 6px 0 0; }'
    echo '    .tab-button.active { background-color: white; border-bottom: 1px solid white; }'
    echo '    .tab-content { border: 1px solid #e1e4e8; padding: 20px; border-radius: 0 6px 6px 6px; display: none; background-color: white; }'
    echo '    .tab-content.active { display: block; }'
    echo '  </style>'
    echo '</head>'
    echo '<body>'
    echo '  <h1>Thread Interaction Visualization</h1>'
    echo "  <p class=\"timestamp\">Thread dump from: $timestamp</p>"
    
    # Add thread state legend
    echo '  <h2>Thread State Legend</h2>'
    echo '  <div class="legend">'
    echo '    <div class="legend-item"><div class="legend-color runnable"></div>RUNNABLE</div>'
    echo '    <div class="legend-item"><div class="legend-color blocked"></div>BLOCKED</div>'
    echo '    <div class="legend-item"><div class="legend-color waiting"></div>WAITING</div>'
    echo '    <div class="legend-item"><div class="legend-color timed_waiting"></div>TIMED_WAITING</div>'
    echo '    <div class="legend-item"><div class="legend-color deadlock"></div>DEADLOCK</div>'
    echo '  </div>'
    
    # Check if there's a deadlock
    if grep -q "DEADLOCK DETECTED" "$lock_contention"; then
      echo '  <div class="deadlock-warning">⚠️ DEADLOCK DETECTED: This thread dump contains a deadlock condition that may cause the application to hang!</div>'
    fi
    
    # Create tab container
    echo '  <div class="tab-container">'
    echo '    <div class="tab-buttons">'
    echo '      <div class="tab-button active" onclick="changeTab(0)">Thread Diagram</div>'
    echo '      <div class="tab-button" onclick="changeTab(1)">Thread Timeline</div>'
    echo '      <div class="tab-button" onclick="changeTab(2)">Lock Contention</div>'
    echo '      <div class="tab-button" onclick="changeTab(3)">Raw Thread Dump</div>'
    echo '    </div>'
    
    # Thread diagram tab
    echo '    <div class="tab-content active">'
    echo '      <h2>Thread Interaction Diagram</h2>'
    echo '      <div class="visualization-container">'
    sed -n '/```mermaid/,/```/p' "$thread_diagram" | sed 's/```mermaid/<div class="mermaid">/; s/```/<\/div>/' >> "$output_file"
    echo '      </div>'
    echo '      <p>This diagram shows the relationships between threads and their states. Colored nodes indicate the thread state.</p>'
    echo '    </div>'
    
    # Thread timeline tab
    echo '    <div class="tab-content">'
    echo '      <h2>Thread Timeline</h2>'
    echo '      <div class="visualization-container">'
    sed -n '/```mermaid/,/```/p' "$thread_timeline" | sed 's/```mermaid/<div class="mermaid">/; s/```/<\/div>/' >> "$output_file"
    echo '      </div>'
    echo '      <p>This timeline shows the execution of threads over time, including periods of waiting and lock acquisitions.</p>'
    echo '    </div>'
    
    # Lock contention tab
    echo '    <div class="tab-content">'
    echo '      <h2>Lock Contention Graph</h2>'
    echo '      <div class="visualization-container">'
    sed -n '/```mermaid/,/```/p' "$lock_contention" | sed 's/```mermaid/<div class="mermaid">/; s/```/<\/div>/' >> "$output_file"
    echo '      </div>'
    echo '      <p>This graph shows lock ownership and waiting relationships between threads. Solid lines indicate a thread holds a lock, dotted lines indicate a thread is waiting for a lock.</p>'
    echo '    </div>'
    
    # Raw thread dump tab
    echo '    <div class="tab-content">'
    echo '      <h2>Raw Thread Dump</h2>'
    echo '      <div class="visualization-container">'
    echo '        <pre>'
    cat "$input_file" >> "$output_file"
    echo '        </pre>'
    echo '      </div>'
    echo '    </div>'
    
    echo '  </div>'
    
    # Add JavaScript
    echo '  <script>'
    echo '    function changeTab(tabIndex) {'
    echo '      const buttons = document.querySelectorAll(".tab-button");'
    echo '      const contents = document.querySelectorAll(".tab-content");'
    echo '      '
    echo '      buttons.forEach((btn, idx) => {'
    echo '        if (idx === tabIndex) {'
    echo '          btn.classList.add("active");'
    echo '        } else {'
    echo '          btn.classList.remove("active");'
    echo '        }'
    echo '      });'
    echo '      '
    echo '      contents.forEach((content, idx) => {'
    echo '        if (idx === tabIndex) {'
    echo '          content.classList.add("active");'
    echo '        } else {'
    echo '          content.classList.remove("active");'
    echo '        }'
    echo '      });'
    echo '    }'
    echo '  </script>'
    
    echo '</body>'
    echo '</html>'
  } > "$output_file"
  
  # Clean up temporary files
  rm -rf "$tmp_dir"
  
  print_success "Generated HTML thread visualization: $output_file"
  return 0
}

# Detect deadlocks in thread dump
# Parameters:
#   $1 - input thread dump file
# Returns:
#   0 if deadlock is detected, 1 otherwise
# Outputs:
#   Prints deadlock information if detected
detect_deadlocks() {
  local input_file="$1"
  
  if [[ -z "$input_file" || ! -f "$input_file" ]]; then
    print_error "Valid input file is required for deadlock detection"
    return 1
  fi
  
  # Check if file is empty
  if [[ ! -s "$input_file" ]]; then
    print_error "Input file is empty: $input_file"
    return 1
  fi
  
  # Check if jq is available
  if ! command -v jq &> /dev/null; then
    print_warning "jq not found, cannot perform detailed deadlock detection"
    return 1
  fi
  
  # Check if input is valid JSON
  if ! jq empty "$input_file" 2>/dev/null; then
    print_error "Invalid JSON format in input file: $input_file"
    return 1
  fi
  
  # Check if thread data exists
  if [[ "$(jq 'has("threads")' "$input_file" 2>/dev/null)" != "true" ]]; then
    print_warning "No thread data found in input file: $input_file"
    return 1
  fi
  
  # Create a temporary file for deadlock detection
  local tmp_file
  tmp_file=$(mktemp)
  
  # Ensure temp file is removed on exit or error
  trap 'rm -f "$tmp_file"' EXIT
  
  # First, extract the basic information we need
  jq -r '[
    .threads[] | 
    { 
      "id": .id, 
      "name": .name, 
      "locks_held": .locks_held, 
      "locks_waiting": .locks_waiting 
    }
  ]' "$input_file" > "$tmp_file"
  
  # Create a simplified list of waiting relationships
  jq -r '[
    .locks[] | 
    {
      "lock": .identity,
      "owner": .owner_thread,
      "waiters": .waiting_threads
    }
  ]' "$input_file" > "${tmp_file}.locks"
  
  local deadlock_detected=false
  local deadlock_info=""
  
  # Create a directed graph of thread dependencies and look for cycles
  # This approach can detect complex deadlocks involving more than two threads
  
  # First, build the graph as an adjacency list
  local graph=()
  local thread_names=()
  local locks_held=()
  
  # Read thread names for better reporting
  while read -r name_info; do
    local thread_id name
    thread_id=$(echo "$name_info" | cut -d':' -f1)
    name=$(echo "$name_info" | cut -d':' -f2-)
    thread_names["$thread_id"]="$name"
  done < <(jq -r '.threads[] | "\(.id):\(.name)"' "$input_file")
  
  # Read locks held by each thread
  while read -r locks_info; do
    local thread_id held_locks
    thread_id=$(echo "$locks_info" | cut -d':' -f1)
    held_locks=$(echo "$locks_info" | cut -d':' -f2-)
    locks_held["$thread_id"]="$held_locks"
  done < <(jq -r '.threads[] | "\(.id):\(.locks_held | join(","))"' "$input_file")
  
  # First, extract basic thread info
  while read -r thread_info; do
    local thread_id=$(echo "$thread_info" | jq -r '.id')
    local thread_name=$(echo "$thread_info" | jq -r '.name')
    
    # Store thread name
    thread_names["$thread_id"]="$thread_name"
    
    # Store locks held
    locks_held["$thread_id"]=$(echo "$thread_info" | jq -r '.locks_held | join(", ")')
  done < <(jq -c '.[]' "$tmp_file")
  
  # Now build the graph by processing lock information
  while read -r lock_info; do
    local lock=$(echo "$lock_info" | jq -r '.lock')
    local owner=$(echo "$lock_info" | jq -r '.owner')
    
    # Process each waiting thread
    echo "$lock_info" | jq -r '.waiters[]?' | while read -r waiter; do
      if [[ -n "$waiter" && "$waiter" != "null" && -n "$owner" && "$owner" != "null" ]]; then
        # Add edge: waiter -> owner (waiter is waiting for a lock owned by owner)
        graph["$waiter"]+=" $owner"
      fi
    done
  done < <(jq -c '.[]' "${tmp_file}.locks")
  
  # Function to detect cycles in the graph using DFS
  detect_cycles() {
    local node="$1"
    local visited=("${@:2}")
    local path=("${@:2}")
    
    # Check if node is already in the current path (cycle detected)
    for p in "${path[@]}"; do
      if [[ "$p" == "$node" ]]; then
        # Found a cycle, extract it
        local cycle=("$node")
        local i=$((${#path[@]} - 1))
        while [[ $i -ge 0 && "${path[$i]}" != "$node" ]]; do
          cycle+=("${path[$i]}")
          i=$((i - 1))
        done
        cycle+=("$node") # Complete the cycle
        
        # Report the cycle
        deadlock_detected=true
        
        deadlock_info+="DEADLOCK DETECTED - Circular Wait:\n"
        
        # Generate the deadlock description
        local prev_node=""
        for c in "${cycle[@]}"; do
          if [[ -n "$prev_node" ]]; then
            local thread_name="${thread_names[$c]:-Thread $c}"
            local prev_thread_name="${thread_names[$prev_node]:-Thread $prev_node}"
            local lock_held="${locks_held[$prev_node]}"
            deadlock_info+="Thread $prev_node ($prev_thread_name) holds lock(s) [$lock_held]\n"
            deadlock_info+="  which is needed by Thread $c ($thread_name)\n"
          fi
          prev_node="$c"
        done
        deadlock_info+="\n"
        
        return 0
      fi
    done
    
    # Mark as visited
    visited+=("$node")
    path+=("$node")
    
    # Visit all neighbors
    for neighbor in ${graph[$node]}; do
      if [[ " ${visited[*]} " != *" $neighbor "* ]]; then
        detect_cycles "$neighbor" "${visited[@]}" "${path[@]}"
      fi
    done
    
    return 0
  }
  
  # Start DFS from each node
  for node in "${!graph[@]}"; do
    detect_cycles "$node"
  done
  
  # Cleanup
  rm -f "$tmp_file" "${tmp_file}.locks"
  trap - EXIT
  
  # Output results
  if [[ "$deadlock_detected" == "true" ]]; then
    print_warning "Deadlock detected in thread dump:"
    echo -e "$deadlock_info"
    return 0
  else
    print_info "No deadlocks detected in thread dump"
    return 1
  fi
}

# Analyze thread dump for potential issues
# Parameters:
#   $1 - input thread dump file
# Returns:
#   0 if analysis was successful, 1 otherwise
# Outputs:
#   Prints analysis information
analyze_thread_dump() {
  local input_file="$1"
  
  if [[ -z "$input_file" || ! -f "$input_file" ]]; then
    print_error "Valid input file is required for thread analysis"
    return 1
  fi
  
  # Check if jq is available
  if ! command -v jq &> /dev/null; then
    print_warning "jq not found, cannot perform detailed thread analysis"
    return 1
  fi
  
  # Check for deadlocks
  detect_deadlocks "$input_file"
  
  # Count threads by state
  local thread_state_counts
  thread_state_counts=$(jq -r '.threads[] | .state' "$input_file" | sort | uniq -c | sort -nr)
  
  print_info "Thread state summary:"
  echo "$thread_state_counts" | while read -r count state; do
    echo "  $state: $count"
  done
  
  # Check for blocked threads
  local blocked_count
  blocked_count=$(echo "$thread_state_counts" | grep -w "BLOCKED" | awk '{print $1}' || echo 0)
  
  if [[ "$blocked_count" -gt 0 ]]; then
    print_warning "Found $blocked_count BLOCKED threads. This may indicate contention issues."
    jq -r '.threads[] | select(.state == "BLOCKED") | "  Thread \(.id): \(.name)"' "$input_file"
  fi
  
  # Check for lock contention
  local contention_count
  contention_count=$(jq '.locks | map(.waiting_threads | length) | add // 0' "$input_file")
  
  if [[ "$contention_count" -gt 0 ]]; then
    print_warning "Found $contention_count threads waiting for locks. Locks with contention:"
    jq -r '.locks[] | select(.waiting_threads | length > 0) | "  Lock \(.identity): held by Thread \(.owner_thread), \(.waiting_threads | length) threads waiting"' "$input_file"
  fi
  
  return 0
}

# Main function for CLI usage
thread_visualizer_main() {
  local command="$1"
  shift
  
  case "$command" in
    diagram)
      if [[ $# -lt 2 ]]; then
        print_error "Usage: thread_visualizer diagram <input_file> <output_file>"
        return 1
      fi
      generate_thread_diagram "$1" "$2"
      ;;
    timeline)
      if [[ $# -lt 2 ]]; then
        print_error "Usage: thread_visualizer timeline <input_file> <output_file>"
        return 1
      fi
      generate_thread_timeline "$1" "$2"
      ;;
    contention)
      if [[ $# -lt 2 ]]; then
        print_error "Usage: thread_visualizer contention <input_file> <output_file>"
        return 1
      fi
      generate_lock_contention_graph "$1" "$2"
      ;;
    visualize)
      if [[ $# -lt 2 ]]; then
        print_error "Usage: thread_visualizer visualize <input_file> <output_file>"
        return 1
      fi
      generate_thread_visualization "$1" "$2"
      ;;
    analyze)
      if [[ $# -lt 1 ]]; then
        print_error "Usage: thread_visualizer analyze <input_file>"
        return 1
      fi
      analyze_thread_dump "$1"
      ;;
    detect-deadlocks)
      if [[ $# -lt 1 ]]; then
        print_error "Usage: thread_visualizer detect-deadlocks <input_file>"
        return 1
      fi
      detect_deadlocks "$1"
      ;;
    help|--help|-h)
      echo "Thread Visualizer - Visualize and analyze thread interactions"
      echo ""
      echo "Usage:"
      echo "  thread_visualizer <command> [options]"
      echo ""
      echo "Commands:"
      echo "  diagram <input_file> <output_file>     Generate a thread interaction diagram"
      echo "  timeline <input_file> <output_file>    Generate a thread timeline visualization"
      echo "  contention <input_file> <output_file>  Generate a lock contention graph"
      echo "  visualize <input_file> <output_file>   Generate a complete HTML visualization"
      echo "  analyze <input_file>                   Analyze a thread dump for issues"
      echo "  detect-deadlocks <input_file>          Check for deadlocks in a thread dump"
      echo "  help                                   Show this help message"
      echo ""
      echo "Examples:"
      echo "  thread_visualizer diagram thread_dump.json diagram.md"
      echo "  thread_visualizer visualize thread_dump.json visualization.html"
      ;;
    *)
      print_error "Unknown command: $command"
      print_info "Try 'thread_visualizer help' for usage information"
      return 1
      ;;
  esac
}

# Execute main function if the script is being run directly
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  thread_visualizer_main "$@"
fi