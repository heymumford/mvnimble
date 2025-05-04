#!/bin/bash
# Copyright (C) 2025 Eric C. Mumford (@heymumford) Code covered by MIT license
# generate_report.sh
# Utility to generate HTML report from MVNimble results

if [ $# -lt 1 ]; then
  echo "Usage: $0 <result_directory>"
  echo "Example: $0 results/mvnimble-optimization-20250502184656"
  exit 1
fi

RESULT_DIR=$1
OUTPUT_FILE="${RESULT_DIR}/report.html"

if [ ! -d "$RESULT_DIR" ]; then
  echo "Error: Result directory '$RESULT_DIR' not found"
  exit 1
fi

# Check for required result files
if [ ! -f "${RESULT_DIR}/results.csv" ] || [ ! -f "${RESULT_DIR}/environment.txt" ]; then
  echo "Error: Required files not found in '$RESULT_DIR'"
  exit 1
fi

echo "Generating HTML report from results in ${RESULT_DIR}..."

# Function to extract basic stats from results.csv
extract_stats() {
  local total_tests=$(grep -v FORK_COUNT "${RESULT_DIR}/results.csv" | awk -F',' '{sum+=$5} END {print sum}')
  local fastest_config=$(grep -v FORK_COUNT "${RESULT_DIR}/results.csv" | sort -t',' -k4,4n | head -1)
  local fastest_time=$(echo "$fastest_config" | cut -d',' -f4)
  local fork_count=$(echo "$fastest_config" | cut -d',' -f1)
  local thread_count=$(echo "$fastest_config" | cut -d',' -f2)
  local memory=$(echo "$fastest_config" | cut -d',' -f3)
  
  echo "total_tests=$total_tests"
  echo "fastest_time=$fastest_time"
  echo "fork_count=$fork_count"
  echo "thread_count=$thread_count"
  echo "memory=$memory"
}

# Extract environment type from environment.txt
extract_env_type() {
  grep "Environment Type:" "${RESULT_DIR}/environment.txt" | cut -d' ' -f3
}

# Generate chart data
generate_chart_data() {
  # Skip header line and extract fork count, threads, memory, and time
  grep -v FORK_COUNT "${RESULT_DIR}/results.csv" | awk -F',' '{print "{forks: \""$1"\", threads: "$2", memory: "$3", time: "$4", peak_cpu: "$7", peak_mem: "$8"},"}' 
}

# Create HTML report
cat > "$OUTPUT_FILE" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>MVNimble Performance Analysis Report</title>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <style>
    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      line-height: 1.6;
      color: #333;
      max-width: 1200px;
      margin: 0 auto;
      padding: 20px;
    }
    h1, h2, h3 {
      color: #2c3e50;
    }
    .header {
      text-align: center;
      margin-bottom: 30px;
      border-bottom: 1px solid #eee;
      padding-bottom: 20px;
    }
    .logo {
      font-family: monospace;
      white-space: pre;
      line-height: 1.2;
      color: #3498db;
      margin-bottom: 20px;
    }
    .summary {
      background-color: #f9f9f9;
      border-radius: 5px;
      padding: 20px;
      margin-bottom: 30px;
    }
    .chart-container {
      position: relative;
      height: 400px;
      margin-bottom: 30px;
    }
    .recommendations {
      background-color: #e8f4f8;
      border-left: 5px solid #3498db;
      padding: 15px;
      margin-bottom: 30px;
    }
    .environment {
      display: flex;
      flex-wrap: wrap;
      gap: 20px;
      margin-bottom: 30px;
    }
    .env-card {
      flex: 1;
      min-width: 250px;
      border: 1px solid #ddd;
      border-radius: 5px;
      padding: 15px;
    }
    .footer {
      text-align: center;
      margin-top: 50px;
      font-size: 0.9em;
      color: #7f8c8d;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 30px;
    }
    th, td {
      padding: 12px;
      text-align: left;
      border-bottom: 1px solid #ddd;
    }
    th {
      background-color: #f2f2f2;
    }
    tr:hover {
      background-color: #f5f5f5;
    }
    .optimal {
      font-weight: bold;
      color: #27ae60;
    }
  </style>
</head>
<body>
  <div class="header">
    <div class="logo">
  __  ____      ___  __ _           __    __     
 |  \\/  \\ \\    / / \\|_ |_ _ __ ___ | |__ | | ___ 
 | |\\/| |\\ \\/\\/ /|  _|| | '_ \` _ \\| '_ \\| |/ _ \\
 | |  | | \\_/\\_/ | | || | | | | | | |_) | |  __/
 |_|  |_|        |_| |_|_| |_| |_|_.__/|_|\\___|
    </div>
    <h1>Maven Test Cycle Optimization Report</h1>
    <p>Generated on $(date)</p>
  </div>

  <div class="summary">
    <h2>Executive Summary</h2>
EOF

# Add environment info
ENV_TYPE=$(extract_env_type)
STATS=$(extract_stats)
TOTAL_TESTS=$(echo "$STATS" | grep "total_tests" | cut -d= -f2)
FASTEST_TIME=$(echo "$STATS" | grep "fastest_time" | cut -d= -f2)
FORK_COUNT=$(echo "$STATS" | grep "fork_count" | cut -d= -f2)
THREAD_COUNT=$(echo "$STATS" | grep "thread_count" | cut -d= -f2)
MEMORY=$(echo "$STATS" | grep "memory" | cut -d= -f2)

cat >> "$OUTPUT_FILE" << EOF
    <p>This report provides analysis of Maven test cycle performance across various configurations.</p>
    <ul>
      <li><strong>Environment:</strong> ${ENV_TYPE}</li>
      <li><strong>Total Tests Executed:</strong> ${TOTAL_TESTS}</li>
      <li><strong>Fastest Execution Time:</strong> ${FASTEST_TIME} seconds</li>
      <li><strong>Optimal Configuration:</strong> Forks=${FORK_COUNT}, Threads=${THREAD_COUNT}, Memory=${MEMORY}MB</li>
    </ul>
  </div>

  <h2>Performance Comparison</h2>
  <div class="chart-container">
    <canvas id="performanceChart"></canvas>
  </div>

  <h2>Resource Utilization</h2>
  <div class="chart-container">
    <canvas id="resourceChart"></canvas>
  </div>

  <h2>Test Configurations</h2>
  <table>
    <thead>
      <tr>
        <th>Fork Count</th>
        <th>Threads</th>
        <th>Memory (MB)</th>
        <th>Execution Time (s)</th>
        <th>Peak CPU (%)</th>
        <th>Peak Memory (MB)</th>
      </tr>
    </thead>
    <tbody>
EOF

# Add table rows
grep -v FORK_COUNT "${RESULT_DIR}/results.csv" | sort -t',' -k4,4n | while IFS=, read -r fork threads memory time tests failed peak_cpu peak_mem status; do
  CSS_CLASS=""
  if (( $(echo "$time == $FASTEST_TIME" | bc -l) )); then
    CSS_CLASS="class=\"optimal\""
  fi
  
  echo "      <tr $CSS_CLASS>" >> "$OUTPUT_FILE"
  echo "        <td>$fork</td>" >> "$OUTPUT_FILE"
  echo "        <td>$threads</td>" >> "$OUTPUT_FILE"
  echo "        <td>$memory</td>" >> "$OUTPUT_FILE"
  echo "        <td>$time</td>" >> "$OUTPUT_FILE"
  echo "        <td>$peak_cpu</td>" >> "$OUTPUT_FILE"
  echo "        <td>$peak_mem</td>" >> "$OUTPUT_FILE"
  echo "      </tr>" >> "$OUTPUT_FILE"
done

# Add recommendations
cat >> "$OUTPUT_FILE" << EOF
    </tbody>
  </table>

  <div class="recommendations">
    <h2>Optimization Recommendations</h2>
EOF

if [ -f "${RESULT_DIR}/recommendations.txt" ]; then
  if grep -q "Memory binding: HIGH" "${RESULT_DIR}/optimal-settings.xml" 2>/dev/null; then
    echo "    <p><strong>Memory-Bound Workload:</strong> Your tests would benefit significantly from more memory allocation.</p>" >> "$OUTPUT_FILE"
  elif grep -q "CPU binding: HIGH" "${RESULT_DIR}/optimal-settings.xml" 2>/dev/null; then
    echo "    <p><strong>CPU-Bound Workload:</strong> Your tests would benefit significantly from more parallel execution threads.</p>" >> "$OUTPUT_FILE"
  elif grep -q "I/O binding: HIGH" "${RESULT_DIR}/optimal-settings.xml" 2>/dev/null; then
    echo "    <p><strong>I/O-Bound Workload:</strong> Your tests are limited by disk or network I/O speed. Consider reducing parallel execution and optimizing I/O operations.</p>" >> "$OUTPUT_FILE"
  fi
  
  echo "    <h3>Recommended Maven Configuration:</h3>" >> "$OUTPUT_FILE"
  echo "    <pre>" >> "$OUTPUT_FILE"
  cat "${RESULT_DIR}/optimal-settings.xml" >> "$OUTPUT_FILE"
  echo "    </pre>" >> "$OUTPUT_FILE"
fi

if [ -f "${RESULT_DIR}/thread_safety_report.txt" ]; then
  echo "    <h3>Thread Safety Issues:</h3>" >> "$OUTPUT_FILE"
  echo "    <p>Thread safety analysis detected potential issues. See the detailed report for specific tests that may have concurrency problems.</p>" >> "$OUTPUT_FILE"
fi

# Add environment details
cat >> "$OUTPUT_FILE" << EOF
  </div>

  <h2>Environment Details</h2>
  <div class="environment">
EOF

# Extract CPU info
CPU_MODEL=$(grep "cpu_model" "${RESULT_DIR}/environment.txt" | cut -d= -f2-)
CPU_COUNT=$(grep "cpu_count" "${RESULT_DIR}/environment.txt" | cut -d= -f2)

# Extract memory info
MEM_TOTAL=$(grep "memory_total_mb" "${RESULT_DIR}/environment.txt" | cut -d= -f2)
MEM_FREE=$(grep "memory_free_mb" "${RESULT_DIR}/environment.txt" | cut -d= -f2)

# Extract Java and Maven info
JAVA_VERSION=$(grep "java_version" "${RESULT_DIR}/environment.txt" | cut -d= -f2)
MAVEN_VERSION=$(grep "maven_version" "${RESULT_DIR}/environment.txt" | cut -d= -f2)

cat >> "$OUTPUT_FILE" << EOF
    <div class="env-card">
      <h3>System</h3>
      <p><strong>Environment Type:</strong> ${ENV_TYPE}</p>
      <p><strong>CPU:</strong> ${CPU_MODEL} (${CPU_COUNT} cores)</p>
      <p><strong>Memory:</strong> ${MEM_TOTAL}MB total, ${MEM_FREE}MB available</p>
    </div>
    
    <div class="env-card">
      <h3>Software</h3>
      <p><strong>Java Version:</strong> ${JAVA_VERSION}</p>
      <p><strong>Maven Version:</strong> ${MAVEN_VERSION}</p>
    </div>
EOF

# Add container-specific info if available
if grep -q "Container Limits:" "${RESULT_DIR}/environment.txt"; then
  CONTAINER_MEM=$(grep "container_memory_limit_mb" "${RESULT_DIR}/environment.txt" | cut -d= -f2)
  CONTAINER_CPU=$(grep "container_cpu_limit" "${RESULT_DIR}/environment.txt" | cut -d= -f2)
  
  cat >> "$OUTPUT_FILE" << EOF
    <div class="env-card">
      <h3>Container Limits</h3>
      <p><strong>Memory Limit:</strong> ${CONTAINER_MEM}MB</p>
      <p><strong>CPU Limit:</strong> ${CONTAINER_CPU} cores</p>
    </div>
EOF
fi

# Add network latency if available
if grep -q "Network Information:" "${RESULT_DIR}/environment.txt"; then
  HOST_LATENCY=$(grep "host_latency_ms" "${RESULT_DIR}/environment.txt" | cut -d= -f2)
  EXTERNAL_LATENCY=$(grep "external_latency_ms" "${RESULT_DIR}/environment.txt" | cut -d= -f2)
  
  cat >> "$OUTPUT_FILE" << EOF
    <div class="env-card">
      <h3>Network Latency</h3>
      <p><strong>Host Latency:</strong> ${HOST_LATENCY}ms</p>
      <p><strong>External Latency:</strong> ${EXTERNAL_LATENCY}ms</p>
    </div>
EOF
fi

# Add chart data and scripts
CHART_DATA=$(generate_chart_data)

cat >> "$OUTPUT_FILE" << EOF
  </div>

  <div class="footer">
    <p>Generated by MVNimble - Maven Test Cycle Optimization Analyzer</p>
    <p>For more information, visit: <a href="https://github.com/mvnimble/mvnimble">https://github.com/mvnimble/mvnimble</a></p>
  </div>

  <script>
    // Chart data
    const perfData = [
      ${CHART_DATA}
    ];
    
    // Format data for performance chart
    const labels = perfData.map(entry => \`\${entry.forks}/\${entry.threads}/\${entry.memory}MB\`);
    const executionTimes = perfData.map(entry => entry.time);
    
    // Create performance chart
    const perfCtx = document.getElementById('performanceChart').getContext('2d');
    const performanceChart = new Chart(perfCtx, {
      type: 'bar',
      data: {
        labels: labels,
        datasets: [{
          label: 'Execution Time (seconds)',
          data: executionTimes,
          backgroundColor: 'rgba(54, 162, 235, 0.5)',
          borderColor: 'rgb(54, 162, 235)',
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          title: {
            display: true,
            text: 'Execution Time by Configuration (Fork Count/Threads/Memory)'
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            title: {
              display: true,
              text: 'Time (seconds)'
            }
          }
        }
      }
    });
    
    // Create resource utilization chart
    const resCtx = document.getElementById('resourceChart').getContext('2d');
    const resourceChart = new Chart(resCtx, {
      type: 'scatter',
      data: {
        datasets: [{
          label: 'CPU vs Memory Usage',
          data: perfData.map(entry => ({
            x: entry.peak_cpu,
            y: entry.peak_mem,
            r: 10 + (100 / entry.time) // Size based on inverse of execution time
          })),
          backgroundColor: 'rgba(255, 99, 132, 0.5)',
          borderColor: 'rgb(255, 99, 132)',
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          tooltip: {
            callbacks: {
              label: function(context) {
                const index = context.dataIndex;
                const item = perfData[index];
                return [
                  \`Configuration: \${item.forks}/\${item.threads}/\${item.memory}MB\`,
                  \`CPU: \${item.peak_cpu}%\`,
                  \`Memory: \${item.peak_mem}MB\`,
                  \`Time: \${item.time}s\`
                ];
              }
            }
          },
          title: {
            display: true,
            text: 'Resource Utilization (CPU vs Memory)'
          }
        },
        scales: {
          x: {
            title: {
              display: true,
              text: 'CPU Usage (%)'
            }
          },
          y: {
            title: {
              display: true,
              text: 'Memory Usage (MB)'
            }
          }
        }
      }
    });
  </script>
</body>
</html>
EOF

echo "Report generated at: $OUTPUT_FILE"