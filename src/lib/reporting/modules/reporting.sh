#!/usr/bin/env bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# reporting.sh
# MVNimble - Reporting and recommendation module
#
# This module provides functions for analyzing test results,
# generating recommendations, and reporting optimization findings.
#
# Author: MVNimble Team
# Version: 1.0.0

# Define the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Import modules
if [[ -z "${CONSTANTS_LOADED+x}" ]]; then
  source "${SCRIPT_DIR}/constants.sh"
fi
source "${SCRIPT_DIR}/platform_compatibility.sh"

# ============================================================
# Resource Binding Analysis & Recommendation Functions
# ============================================================

# Analyze results to identify resource binding
analyze_resource_binding() {
  local result_dir=$1
  local env_type=$2
  
  echo -e "\n${COLOR_BOLD}${COLOR_BLUE}=== Resource Binding Analysis ===${COLOR_RESET}"
  
  local results_file="${result_dir}/results.csv"
  
  # Check if we have enough data
  local result_count=$(wc -l < "$results_file")
  if [ "$result_count" -lt 2 ]; then
    echo -e "${COLOR_RED}Not enough test data for analysis${COLOR_RESET}"
    return
  fi
  
  # Find fastest configuration
  local fastest_config=$(tail -n +2 "$results_file" | grep -v "FAILED" | sort -t',' -k4,4n | head -1)
  if [ -z "$fastest_config" ]; then
    echo -e "${COLOR_RED}No successful test runs found to analyze.${COLOR_RESET}"
    return
  fi
  
  local fastest_forks=$(echo "$fastest_config" | cut -d',' -f1)
  local fastest_threads=$(echo "$fastest_config" | cut -d',' -f2)
  local fastest_memory=$(echo "$fastest_config" | cut -d',' -f3)
  local fastest_time=$(echo "$fastest_config" | cut -d',' -f4)
  
  echo -e "Fastest test configuration: ${COLOR_GREEN}Forks=${fastest_forks}, Threads=${fastest_threads}, Memory=${fastest_memory}MB${COLOR_RESET}"
  echo -e "Execution time: ${COLOR_BOLD}${fastest_time}${COLOR_RESET} seconds"
  
  # Find most memory-efficient configuration that's within 10% of fastest time
  threshold=$(echo "$fastest_time * 1.1" | bc)
  local efficient_config=$(tail -n +2 "$results_file" | grep -v "FAILED" | awk -F',' -v threshold="$threshold" '$4 <= threshold {print $0}' | sort -t',' -k3,3n | head -1)
  
  if [ -n "$efficient_config" ]; then
    local efficient_forks=$(echo "$efficient_config" | cut -d',' -f1)
    local efficient_threads=$(echo "$efficient_config" | cut -d',' -f2)
    local efficient_memory=$(echo "$efficient_config" | cut -d',' -f3)
    local efficient_time=$(echo "$efficient_config" | cut -d',' -f4)
    
    echo -e "\nMost memory-efficient configuration within 10% of fastest time:"
    echo -e "${COLOR_CYAN}Forks=${efficient_forks}, Threads=${efficient_threads}, Memory=${efficient_memory}MB${COLOR_RESET}"
    echo -e "Execution time: ${COLOR_BOLD}${efficient_time}${COLOR_RESET} seconds"
    echo -e "Memory saving: ${COLOR_BOLD}$((fastest_memory - efficient_memory))MB${COLOR_RESET} per fork"
  fi
  
  # Analyze CPU vs Memory correlation
  echo -e "\n${COLOR_BOLD}Resource Binding Analysis:${COLOR_RESET}"
  
  # Test how performance changes with memory increases (keeping threads constant)
  local mem_correlation=$(tail -n +2 "$results_file" | grep -v "FAILED" | awk -F',' -v threads="$fastest_threads" '$2 == threads {print $3","$4}' | sort -t',' -k1,1n)
  
  if [ -n "$mem_correlation" ]; then
    local mem_sensitivity=$(echo "$mem_correlation" | awk -F',' 'NR>1 {print (prev_time-$2)/prev_time*100; prev_time=$2} {prev_time=$2}' | awk '{sum+=$1; count++} END {if(count>0) print sum/count; else print 0}')
    
    if (( $(echo "$mem_sensitivity > 15" | bc -l) )); then
      echo -e "Memory binding: ${COLOR_RED}HIGH${COLOR_RESET} - Performance improves significantly with more memory"
      echo -e "Average improvement: ${COLOR_BOLD}${mem_sensitivity}%${COLOR_RESET} per memory step"
    elif (( $(echo "$mem_sensitivity > 5" | bc -l) )); then
      echo -e "Memory binding: ${COLOR_YELLOW}MEDIUM${COLOR_RESET} - Performance moderately affected by memory"
      echo -e "Average improvement: ${COLOR_BOLD}${mem_sensitivity}%${COLOR_RESET} per memory step"
    else
      echo -e "Memory binding: ${COLOR_GREEN}LOW${COLOR_RESET} - Performance not significantly affected by memory"
    fi
  fi
  
  # Test how performance changes with thread increases (keeping memory constant)
  local thread_correlation=$(tail -n +2 "$results_file" | grep -v "FAILED" | awk -F',' -v memory="$fastest_memory" '$3 == memory {print $2","$4}' | sort -t',' -k1,1n)
  
  if [ -n "$thread_correlation" ]; then
    local thread_sensitivity=$(echo "$thread_correlation" | awk -F',' 'NR>1 {print (prev_time-$2)/prev_time*100; prev_time=$2} {prev_time=$2}' | awk '{sum+=$1; count++} END {if(count>0) print sum/count; else print 0}')
    
    if (( $(echo "$thread_sensitivity > 15" | bc -l) )); then
      echo -e "CPU binding: ${COLOR_RED}HIGH${COLOR_RESET} - Performance improves significantly with more threads"
      echo -e "Average improvement: ${COLOR_BOLD}${thread_sensitivity}%${COLOR_RESET} per thread step"
    elif (( $(echo "$thread_sensitivity > 5" | bc -l) )); then
      echo -e "CPU binding: ${COLOR_YELLOW}MEDIUM${COLOR_RESET} - Performance moderately affected by threads"
      echo -e "Average improvement: ${COLOR_BOLD}${thread_sensitivity}%${COLOR_RESET} per thread step"
    else
      echo -e "CPU binding: ${COLOR_GREEN}LOW${COLOR_RESET} - Performance not significantly affected by threads"
    fi
  fi
  
  # Check for I/O binding based on CPU utilization
  local peak_cpu=$(tail -n +2 "$results_file" | cut -d',' -f7 | grep -v "N/A" | sort -nr | head -1)
  
  if [ "$peak_cpu" != "N/A" ] && [ -n "$peak_cpu" ]; then
    if (( $(echo "$peak_cpu < 50" | bc -l) )); then
      echo -e "I/O binding: ${COLOR_RED}HIGH${COLOR_RESET} - Low CPU utilization suggests I/O bottleneck"
    elif (( $(echo "$peak_cpu < 80" | bc -l) )); then
      echo -e "I/O binding: ${COLOR_YELLOW}MEDIUM${COLOR_RESET} - Moderate CPU utilization may indicate partial I/O bottleneck"
    else
      echo -e "I/O binding: ${COLOR_GREEN}LOW${COLOR_RESET} - High CPU utilization suggests compute-bound workload"
    fi
  fi
  
  # Generate improvement recommendations based on binding analysis
  echo -e "\n${COLOR_BOLD}${COLOR_GREEN}Recommendations:${COLOR_RESET}"
  
  # Memory recommendations
  if (( $(echo "$mem_sensitivity > 15" | bc -l) )); then
    local recommended_memory=$((fastest_memory * 15 / 10))
    echo -e "- Increase memory allocation to ${COLOR_BOLD}${recommended_memory}MB${COLOR_RESET} per fork for potential improvements"
    
    if [[ "$env_type" == "container" ]]; then
      echo -e "- Container environment: Consider increasing container memory limit by at least ${COLOR_BOLD}$((recommended_memory - fastest_memory))MB${COLOR_RESET}"
    fi
  fi
  
  # Thread recommendations
  if (( $(echo "$thread_sensitivity > 15" | bc -l) )); then
    local recommended_threads=$((fastest_threads * 15 / 10))
    echo -e "- Increase parallel threads to ${COLOR_BOLD}${recommended_threads}${COLOR_RESET} for potential improvements"
    
    if [[ "$env_type" == "container" ]]; then
      echo -e "- Container environment: Consider increasing container CPU limit proportionally"
    fi
  fi
  
  # I/O recommendations
  if [ "$peak_cpu" != "N/A" ] && [ -n "$peak_cpu" ] && (( $(echo "$peak_cpu < 50" | bc -l) )); then
    echo -e "- I/O-bound tests detected: Consider reducing parallel execution to minimize I/O contention"
    echo -e "- Consider using an SSD if not already using one"
    echo -e "- Review test initialization to minimize file system operations"
  fi
  
  # Container-specific recommendations
  if [[ "$env_type" == "container" || "$env_type" == "kubernetes" ]]; then
    echo -e "\n${COLOR_BOLD}${COLOR_CYAN}Container-Specific Recommendations:${COLOR_RESET}"
    echo -e "- Use pre-warmed container images to minimize startup time"
    echo -e "- Set resource limits 20% higher than resource requests to allow for bursts"
    echo -e "- Consider increasing /dev/shm size for better performance of in-memory operations"
    
    # Add network recommendations if we have latency info
    if grep -q "network_latency" "${result_dir}/environment.txt" 2>/dev/null; then
      echo -e "- Consider using local caching for Maven dependencies to reduce network impact"
      echo -e "- If running in the cloud, ensure the container is in the same region as other services it communicates with"
    fi
  fi
  
  # Save recommended configuration
  echo "fastest_forks=$fastest_forks" > "${result_dir}/recommendations.txt"
  echo "fastest_threads=$fastest_threads" >> "${result_dir}/recommendations.txt"
  echo "fastest_memory=${fastest_memory}M" >> "${result_dir}/recommendations.txt"
  
  if [ -n "$efficient_config" ]; then
    echo "efficient_forks=$efficient_forks" >> "${result_dir}/recommendations.txt"
    echo "efficient_threads=$efficient_threads" >> "${result_dir}/recommendations.txt"
    echo "efficient_memory=${efficient_memory}M" >> "${result_dir}/recommendations.txt"
  fi
  
  # Create XML snippet for easy application to pom.xml
  cat > "${result_dir}/optimal-settings.xml" << EOF
<!-- Fastest execution configuration -->
<jvm.fork.count>${fastest_forks}</jvm.fork.count>
<maven.threads>${fastest_threads}</maven.threads>
<jvm.fork.memory>${fastest_memory}M</jvm.fork.memory>
EOF
  
  if [ -n "$efficient_config" ]; then
    cat > "${result_dir}/memory-efficient-settings.xml" << EOF
<!-- Memory efficient configuration -->
<jvm.fork.count>${efficient_forks}</jvm.fork.count>
<maven.threads>${efficient_threads}</maven.threads>
<jvm.fork.memory>${efficient_memory}M</jvm.fork.memory>
EOF
  fi
  
  echo -e "\nRecommended settings saved to: ${COLOR_BOLD}${result_dir}/optimal-settings.xml${COLOR_RESET}"
}

# Apply optimal settings to pom.xml if requested
apply_settings() {
  local result_dir=$1
  local apply_settings=$2
  
  if [[ "$apply_settings" != "true" ]]; then
    echo -e "\nTo apply these settings, run: mvnimble --apply"
    return
  fi
  
  echo -e "\n${COLOR_BOLD}${COLOR_BLUE}Applying optimal settings to pom.xml...${COLOR_RESET}"
  
  if [ -f "${result_dir}/recommendations.txt" ]; then
    local fastest_forks=$(grep "fastest_forks" "${result_dir}/recommendations.txt" | cut -d= -f2)
    local fastest_threads=$(grep "fastest_threads" "${result_dir}/recommendations.txt" | cut -d= -f2)
    local fastest_memory=$(grep "fastest_memory" "${result_dir}/recommendations.txt" | cut -d= -f2)
    
    # Backup pom.xml first
    cp pom.xml "${result_dir}/pom.xml.bak"
    
    # Update the pom.xml with optimal settings
    sed -i.tmp "s/<jvm.fork.count>[^<]*<\/jvm.fork.count>/<jvm.fork.count>${fastest_forks}<\/jvm.fork.count>/" pom.xml
    sed -i.tmp "s/<maven.threads>[^<]*<\/maven.threads>/<maven.threads>${fastest_threads}<\/maven.threads>/" pom.xml
    sed -i.tmp "s/<jvm.fork.memory>[^<]*<\/jvm.fork.memory>/<jvm.fork.memory>${fastest_memory}<\/jvm.fork.memory>/" pom.xml
    rm -f pom.xml.tmp
    
    echo -e "${COLOR_GREEN}Settings applied to pom.xml successfully\!${COLOR_RESET}"
    
    # Verify applied settings
    echo -e "\n${COLOR_BLUE}Verifying applied settings:${COLOR_RESET}"
    local applied_forks=$(grep -E "<jvm.fork.count>" pom.xml | grep -oE "[0-9.]+C")
    local applied_threads=$(grep -E "<maven.threads>" pom.xml | grep -oE "[0-9]+" | head -1)
    local applied_memory=$(grep -E "<jvm.fork.memory>" pom.xml | grep -oE "[0-9]+M")
    
    echo -e "JVM Fork Count: ${applied_forks}"
    echo -e "Maven Threads: ${applied_threads}"
    echo -e "JVM Fork Memory: ${applied_memory}"
  else
    echo -e "${COLOR_RED}No recommendations file found. Run analysis first.${COLOR_RESET}"
  fi
}

# Display a summary of the optimization results
display_summary() {
  local result_dir=$1
  
  if [ -f "${result_dir}/recommendations.txt" ]; then
    echo -e "\n${COLOR_BOLD}${COLOR_BLUE}=== Summary ===${COLOR_RESET}"
    echo -e "Based on the analysis, MVNimble recommends the following Maven/JVM configuration:"
    
    fastest_forks=$(grep "fastest_forks" "${result_dir}/recommendations.txt" | cut -d= -f2)
    fastest_threads=$(grep "fastest_threads" "${result_dir}/recommendations.txt" | cut -d= -f2)
    fastest_memory=$(grep "fastest_memory" "${result_dir}/recommendations.txt" | cut -d= -f2)
    
    echo -e "${COLOR_BOLD}Fastest Execution:${COLOR_RESET}"
    echo -e "JVM Fork Count: ${COLOR_BOLD}${fastest_forks}${COLOR_RESET}"
    echo -e "Maven Threads: ${COLOR_BOLD}${fastest_threads}${COLOR_RESET}"
    echo -e "JVM Heap Size: ${COLOR_BOLD}${fastest_memory}${COLOR_RESET}"
    
    if grep -q "efficient_memory" "${result_dir}/recommendations.txt"; then
      efficient_forks=$(grep "efficient_forks" "${result_dir}/recommendations.txt" | cut -d= -f2)
      efficient_threads=$(grep "efficient_threads" "${result_dir}/recommendations.txt" | cut -d= -f2)
      efficient_memory=$(grep "efficient_memory" "${result_dir}/recommendations.txt" | cut -d= -f2)
      
      echo -e "\n${COLOR_BOLD}Memory Efficient:${COLOR_RESET}"
      echo -e "JVM Fork Count: ${COLOR_BOLD}${efficient_forks}${COLOR_RESET}"
      echo -e "Maven Threads: ${COLOR_BOLD}${efficient_threads}${COLOR_RESET}"
      echo -e "JVM Heap Size: ${COLOR_BOLD}${efficient_memory}${COLOR_RESET}"
    fi
  fi
}

# Generate HTML report if requested
generate_html_report() {
  local result_dir=$1
  local export_report=$2
  local script_dir=$3
  
  if [[ "$export_report" != "true" ]]; then
    echo -e "\n${COLOR_YELLOW}Tip: Run with --export-report to generate a detailed HTML visualization${COLOR_RESET}"
    return
  fi
  
  echo -e "\n${COLOR_BOLD}${COLOR_BLUE}=== Generating HTML Report ===${COLOR_RESET}"
  
  if [ -f "${script_dir}/generate_report.sh" ]; then
    chmod +x "${script_dir}/generate_report.sh"
    "${script_dir}/generate_report.sh" "${result_dir}"
    
    if [ -f "${result_dir}/report.html" ]; then
      echo -e "${COLOR_GREEN}HTML report generated: ${COLOR_BOLD}${result_dir}/report.html${COLOR_RESET}"
    else
      echo -e "${COLOR_RED}Failed to generate HTML report.${COLOR_RESET}"
    fi
  else
    echo -e "${COLOR_RED}Report generator script not found at: ${script_dir}/generate_report.sh${COLOR_RESET}"
  fi
}