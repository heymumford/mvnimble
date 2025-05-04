#!/usr/bin/env bash
# network_io_bottlenecks.bash
# Test doubles to simulate various network and I/O bottlenecks in test environments
#
# This file INTENTIONALLY creates problematic network behavior patterns to allow
# MVNimble to detect and diagnose networking issues in Maven test environments.
# Each simulation creates reproducible scenarios for common real-world networking
# problems that can affect build reliability and performance.
#
# ANTIPATTERNS IMPLEMENTED:
#
# 1. Network Latency and Packet Loss
#    - Adds artificial delay to network requests
#    - Simulates packet loss and connection interruptions
#    - Creates unstable network environments with jitter
#
# 2. DNS Resolution Problems
#    - Simulates slow, intermittent, or failing DNS resolution
#    - Creates time-dependent networking failures
#    - Tests application resilience to DNS infrastructure issues
#
# 3. Connection Issues
#    - Simulates timeouts, connection resets, and partial transfers
#    - Creates scenarios where connections fail at specific rates
#    - Tests application retry and failover mechanisms
#
# 4. Proxy Server Problems
#    - Simulates authentication issues, unavailable proxies, and misbehaving proxies
#    - Tests application behavior with enterprise proxy environments
#    - Demonstrates proper proxy configuration handling
#
# 5. Maven Repository Issues
#    - Simulates missing artifacts, corrupted downloads, and wrong versions
#    - Creates intermittent repository availability issues
#    - Tests build resilience to common repository problems
#
# 6. I/O Throttling
#    - Limits read/write speeds for file operations
#    - Simulates slow disk issues or network storage bottlenecks
#    - Tests application behavior under constrained I/O conditions
#
# 7. Temporary Directory Issues
#    - Simulates temp directory space constraints, permission issues, or missing directories
#    - Tests application handling of system temporary storage problems
#    - Creates scenarios where temp file creation fails
#
# EDUCATIONAL PURPOSE:
# These simulations are designed to help diagnose and reproduce common network-related
# failures in Maven builds. They provide a way to test how applications handle adverse
# network conditions and help build more resilient systems that can operate in
# real-world environments with network constraints.

# Load test helpers
source "${BATS_TEST_DIRNAME:-$(dirname "$0")/..}/test_helper.bash"

# ------------------------------------------------------------------------------
# NETWORK LATENCY SIMULATIONS
# ------------------------------------------------------------------------------

# Simulates high network latency for specific hosts or ports
simulate_network_latency() {
  local target="${1:-example.com}"
  local latency_ms="${2:-200}"  # Default to 200ms latency
  local jitter_ms="${3:-20}"    # Default to 20ms jitter
  local packet_loss="${4:-0}"   # Default to 0% packet loss
  
  # Check if we have sudo access for tc/netem (Linux only)
  local has_sudo=false
  local has_tc=false
  
  if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    has_sudo=true
  fi
  
  if command -v tc >/dev/null 2>&1; then
    has_tc=true
  fi
  
  if [[ "$has_sudo" = true && "$has_tc" = true && "$(uname)" = "Linux" ]]; then
    # We can use tc/netem for realistic network impairment
    echo "Using tc/netem for network latency simulation"
    
    # Setup network namespace for isolation (avoid affecting entire host)
    local ns="mvnimble_test_ns"
    sudo ip netns add "$ns" 2>/dev/null || true
    
    # Add latency with netem
    sudo ip netns exec "$ns" tc qdisc add dev lo root netem delay ${latency_ms}ms ${jitter_ms}ms loss ${packet_loss}%
    
    # Return the namespace name for cleanup
    echo "ns:$ns"
  elif command -v pfctl >/dev/null 2>&1 && [[ "$(uname)" = "Darwin" ]] && [[ "$has_sudo" = true ]]; then
    # macOS with pfctl
    echo "Using pfctl for network latency simulation"
    
    # Create temp files for pfctl rules
    local pf_rules_file=$(mktemp)
    
    # Create rules for specific target
    cat > "$pf_rules_file" << EOF
dummynet in proto tcp from any to $target pipe 1
dummynet out proto tcp from $target to any pipe 1
EOF
    
    # Apply the rules
    sudo pfctl -f "$pf_rules_file"
    
    # Configure the pipe for latency
    sudo dnctl pipe 1 config delay ${latency_ms}ms
    
    # Return the rules file for cleanup
    echo "pfctl:$pf_rules_file"
  else
    # Fallback to application-level delay simulation
    echo "Using application-level simulation for network latency"
    
    # Create wrapper functions for common network tools
    curl() {
      # Add delay before real curl
      sleep $(echo "scale=3; $latency_ms/1000" | bc)
      
      # Simulate packet loss
      if [[ "$packet_loss" -gt 0 ]]; then
        local random=$((RANDOM % 100))
        if [[ "$random" -lt "$packet_loss" ]]; then
          echo "curl: (7) Failed to connect: Connection refused" >&2
          return 7
        fi
      fi
      
      # Call real curl
      command curl "$@"
    }
    
    wget() {
      # Add delay before real wget
      sleep $(echo "scale=3; $latency_ms/1000" | bc)
      
      # Simulate packet loss
      if [[ "$packet_loss" -gt 0 ]]; then
        local random=$((RANDOM % 100))
        if [[ "$random" -lt "$packet_loss" ]]; then
          echo "wget: connection failed: Connection refused" >&2
          return 4
        fi
      fi
      
      # Call real wget
      command wget "$@"
    }
    
    # Export the functions
    export -f curl
    export -f wget
    
    # Return token for cleanup
    echo "function:curl,wget"
  fi
}

# Stop network latency simulation
stop_network_latency() {
  local token="$1"
  
  if [[ -z "$token" ]]; then
    echo "No token provided for cleanup" >&2
    return 1
  fi
  
  # Parse token
  local type=$(echo "$token" | cut -d: -f1)
  local value=$(echo "$token" | cut -d: -f2)
  
  case "$type" in
    ns)
      # Cleanup network namespace
      if [[ -n "$value" ]] && command -v sudo >/dev/null 2>&1; then
        sudo ip netns del "$value" 2>/dev/null || true
        echo "Removed network namespace: $value"
      fi
      ;;
    
    pfctl)
      # Cleanup pfctl rules
      if [[ -n "$value" ]] && command -v sudo >/dev/null 2>&1 && command -v pfctl >/dev/null 2>&1; then
        sudo pfctl -f /dev/null >/dev/null 2>&1
        sudo dnctl -q flush >/dev/null 2>&1
        rm -f "$value"
        echo "Cleared pfctl rules"
      fi
      ;;
    
    function)
      # Unset function overrides
      for func in ${value//,/ }; do
        unset -f "$func" 2>/dev/null || true
      done
      echo "Unset function overrides: $value"
      ;;
  esac
}

# ------------------------------------------------------------------------------
# DNS RESOLUTION ISSUES
# ------------------------------------------------------------------------------

# Simulates DNS resolution problems
simulate_dns_issues() {
  local target="${1:-maven.apache.org}"
  local issue_type="${2:-slow}"  # Options: slow, intermittent, failure
  
  echo "Simulating DNS $issue_type resolution for $target"
  
  # Override the host command
  host() {
    local host_arg="$1"
    
    # Only affect the target domain
    if [[ "$host_arg" == "$target" || "$host_arg" == *".$target" ]]; then
      case "$issue_type" in
        slow)
          # Simulate slow resolution
          sleep 2
          command host "$@"
          ;;
        
        intermittent)
          # Simulate intermittent resolution
          local random=$((RANDOM % 100))
          if [[ "$random" -lt 50 ]]; then
            sleep 1
            command host "$@"
          else
            echo "Host $host_arg not found: 3(NXDOMAIN)" >&2
            return 1
          fi
          ;;
        
        failure)
          # Simulate consistent failure
          echo "Host $host_arg not found: 3(NXDOMAIN)" >&2
          return 1
          ;;
      esac
    else
      # Pass through for non-target domains
      command host "$@"
    fi
  }
  
  # Override the dig command
  dig() {
    local dig_args="$*"
    
    # Only affect the target domain
    if [[ "$dig_args" == *"$target"* ]]; then
      case "$issue_type" in
        slow)
          # Simulate slow resolution
          sleep 2
          command dig "$@"
          ;;
        
        intermittent)
          # Simulate intermittent resolution
          local random=$((RANDOM % 100))
          if [[ "$random" -lt 50 ]]; then
            sleep 1
            command dig "$@"
          else
            command dig +noall +answer +nocmd
            return 1
          fi
          ;;
        
        failure)
          # Simulate consistent failure
          command dig +noall +answer +nocmd
          return 1
          ;;
      esac
    else
      # Pass through for non-target domains
      command dig "$@"
    fi
  }
  
  # Create DNS wrapper for Java
  # Mock common JVM system properties
  export MAVEN_OPTS="$MAVEN_OPTS -Dsun.net.spi.nameservice.provider.1=dns,sim"
  
  # Add hosts entry in /etc/hosts
  if [[ "$issue_type" == "failure" ]]; then
    # Create temp hosts file
    local hosts_file=$(mktemp)
    
    # Copy original
    if [[ -f /etc/hosts ]]; then
      cat /etc/hosts > "$hosts_file"
    fi
    
    # Block target in hosts file
    echo "127.0.0.1 $target" >> "$hosts_file"
    
    # Mock /etc/hosts
    mock_command "cat" 0 "$(cat "$hosts_file")" "/etc/hosts"
    
    # Clean up
    rm -f "$hosts_file"
  fi
  
  # Export the functions
  export -f host
  export -f dig
  
  # Return token for cleanup
  echo "function:host,dig MAVEN_OPTS"
}

# Stop DNS issue simulation
stop_dns_issues() {
  local token="$1"
  
  if [[ -z "$token" ]]; then
    echo "No token provided for cleanup" >&2
    return 1
  fi
  
  # Parse token
  local parts=(${token//:/ })
  
  if [[ "${parts[0]}" == "function" ]]; then
    # Unset function overrides
    for func in ${parts[1]//,/ }; do
      if [[ "$func" == "MAVEN_OPTS" ]]; then
        # Reset MAVEN_OPTS
        export MAVEN_OPTS=$(echo "$MAVEN_OPTS" | sed 's/-Dsun.net.spi.nameservice.provider.1=dns,sim//')
      else
        unset -f "$func" 2>/dev/null || true
      fi
    done
    echo "Unset DNS overrides"
  fi
  
  # Restore /etc/hosts mock if applicable
  if type -t mock_command >/dev/null; then
    mock_command "cat" 0 "$(cat /etc/hosts 2>/dev/null || echo '127.0.0.1 localhost')" "/etc/hosts"
  fi
}

# ------------------------------------------------------------------------------
# CONNECTION ISSUES
# ------------------------------------------------------------------------------

# Simulates connection issues like timeouts, resets, and partial failures
simulate_connection_issues() {
  local target="${1:-repo1.maven.org}"
  local issue_type="${2:-timeout}"  # Options: timeout, reset, partial
  local frequency="${3:-50}"        # Percentage of requests affected (0-100)
  
  echo "Simulating connection $issue_type for $target (${frequency}% of requests)"
  
  # Override curl command
  curl() {
    local curl_args="$*"
    
    # Only affect the target domain
    if [[ "$curl_args" == *"$target"* ]]; then
      # Determine if this request should be affected
      local random=$((RANDOM % 100))
      if [[ "$random" -lt "$frequency" ]]; then
        case "$issue_type" in
          timeout)
            # Simulate connection timeout
            sleep 10
            echo "curl: (28) Connection timed out after 10000 milliseconds" >&2
            return 28
            ;;
          
          reset)
            # Simulate connection reset
            sleep 0.5
            echo "curl: (56) Connection reset by peer" >&2
            return 56
            ;;
          
          partial)
            # Simulate partial transfer
            sleep 0.5
            # Return partial data
            echo "{\"partial\": true, \"data\": \"incomplete"
            echo "curl: (18) Transfer closed with outstanding read data remaining" >&2
            return 18
            ;;
        esac
      else
        # This request succeeds
        command curl "$@"
      fi
    else
      # Pass through for non-target domains
      command curl "$@"
    fi
  }
  
  # Override wget command
  wget() {
    local wget_args="$*"
    
    # Only affect the target domain
    if [[ "$wget_args" == *"$target"* ]]; then
      # Determine if this request should be affected
      local random=$((RANDOM % 100))
      if [[ "$random" -lt "$frequency" ]]; then
        case "$issue_type" in
          timeout)
            # Simulate connection timeout
            sleep 10
            echo "wget: connection timed out" >&2
            return 4
            ;;
          
          reset)
            # Simulate connection reset
            sleep 0.5
            echo "wget: connection reset by peer" >&2
            return 4
            ;;
          
          partial)
            # Simulate partial transfer
            sleep 0.5
            # Create a partial file
            local output_file=$(echo "$wget_args" | grep -o -- "-O [^ ]*" | cut -d' ' -f2)
            if [[ -n "$output_file" ]]; then
              echo "{\"partial\": true, \"data\": \"incomplete" > "$output_file"
            fi
            echo "wget: transfer interrupted" >&2
            return 4
            ;;
        esac
      else
        # This request succeeds
        command wget "$@"
      fi
    else
      # Pass through for non-target domains
      command wget "$@"
    fi
  }
  
  # Export the functions
  export -f curl
  export -f wget
  
  # Return token for cleanup
  echo "function:curl,wget"
}

# ------------------------------------------------------------------------------
# PROXY ISSUES
# ------------------------------------------------------------------------------

# Simulates proxy server issues
simulate_proxy_issues() {
  local issue_type="${1:-auth}"  # Options: auth, unavailable, misbehaving
  
  echo "Simulating proxy server $issue_type issues"
  
  # Set proxy environment variables
  case "$issue_type" in
    auth)
      # Authentication required but not provided
      export http_proxy="http://proxy.example.com:8080"
      export https_proxy="http://proxy.example.com:8080"
      export no_proxy="localhost,127.0.0.1"
      ;;
    
    unavailable)
      # Proxy server that doesn't exist
      export http_proxy="http://non.existent.proxy:9999"
      export https_proxy="http://non.existent.proxy:9999"
      export no_proxy="localhost,127.0.0.1"
      ;;
    
    misbehaving)
      # Proxy that modifies content
      export http_proxy="http://localhost:4"  # Invalid port, will cause issues
      export https_proxy="http://localhost:4"
      export no_proxy="localhost,127.0.0.1"
      ;;
  esac
  
  # Also set for Maven
  export MAVEN_OPTS="$MAVEN_OPTS -Dhttp.proxyHost=proxy.example.com -Dhttp.proxyPort=8080 -Dhttps.proxyHost=proxy.example.com -Dhttps.proxyPort=8080"
  
  # Override curl command for more realistic proxy behavior
  curl() {
    if [[ -n "$http_proxy" || -n "$https_proxy" ]]; then
      case "$issue_type" in
        auth)
          echo "curl: (407) Proxy Authentication Required" >&2
          return 407
          ;;
        
        unavailable)
          echo "curl: (5) Could not resolve proxy: non.existent.proxy" >&2
          return 5
          ;;
        
        misbehaving)
          echo "curl: (56) Connection to proxy reset" >&2
          return 56
          ;;
      esac
    else
      # No proxy set or exempt
      command curl "$@"
    fi
  }
  
  # Export the functions
  export -f curl
  
  # Return token for cleanup
  echo "env:http_proxy,https_proxy,no_proxy,MAVEN_OPTS function:curl"
}

# Stop proxy issue simulation
stop_proxy_issues() {
  local token="$1"
  
  if [[ -z "$token" ]]; then
    echo "No token provided for cleanup" >&2
    return 1
  fi
  
  # Parse token
  local parts=(${token//:/ })
  
  if [[ "${parts[0]}" == "env" ]]; then
    # Unset environment variables
    for var in ${parts[1]//,/ }; do
      if [[ "$var" == "MAVEN_OPTS" ]]; then
        # Reset MAVEN_OPTS
        export MAVEN_OPTS=$(echo "$MAVEN_OPTS" | sed 's/-Dhttp.proxyHost=proxy.example.com -Dhttp.proxyPort=8080 -Dhttps.proxyHost=proxy.example.com -Dhttps.proxyPort=8080//')
      else
        unset "$var"
      fi
    done
    echo "Unset proxy environment variables"
  fi
  
  if [[ "${parts[2]}" == "function" ]]; then
    # Unset function overrides
    for func in ${parts[3]//,/ }; do
      unset -f "$func" 2>/dev/null || true
    done
    echo "Unset function overrides: ${parts[3]}"
  fi
}

# ------------------------------------------------------------------------------
# REPOSITORY ISSUES
# ------------------------------------------------------------------------------

# Simulates Maven repository issues
simulate_repository_issues() {
  local issue_type="${1:-missing}"  # Options: missing, corrupted, wrong-version, intermittent
  
  echo "Simulating Maven repository $issue_type issues"
  
  # Create a fake Maven local repository to simulate issues
  local repo_dir=$(mktemp -d)
  mkdir -p "$repo_dir/repository"
  
  # Override Maven local repository location
  export MAVEN_OPTS="$MAVEN_OPTS -Dmaven.repo.local=$repo_dir/repository"
  
  # Also create a maven settings file
  local settings_file="$repo_dir/settings.xml"
  
  cat > "$settings_file" << EOF
<settings>
  <localRepository>$repo_dir/repository</localRepository>
  <mirrors>
    <!-- Mirror that will simulate issues -->
    <mirror>
      <id>problem-mirror</id>
      <name>Problem Maven Mirror</name>
      <url>http://localhost:8081/maven</url>
      <mirrorOf>central</mirrorOf>
    </mirror>
  </mirrors>
  <proxies>
    <proxy>
      <id>optional</id>
      <active>false</active>
      <protocol>http</protocol>
      <host>proxy.example.com</host>
      <port>8080</port>
      <nonProxyHosts>localhost|127.0.0.1</nonProxyHosts>
    </proxy>
  </proxies>
</settings>
EOF
  
  # Create a wrapper script for mvn command
  local mvn_wrapper="$repo_dir/mvn"
  
  cat > "$mvn_wrapper" << 'EOF'
#!/bin/bash
# Wrapper script to simulate repository issues

ISSUE_TYPE="$REPO_ISSUE_TYPE"
REAL_MVN=$(which mvn)

simulate_issue() {
  case "$ISSUE_TYPE" in
    missing)
      echo "[ERROR] Missing artifact: Could not find artifact com.example:missing:jar:1.0 in central"
      return 1
      ;;
    
    corrupted)
      echo "[ERROR] Invalid checksum: Checksum validation failed for com.example:corrupted:jar:1.0"
      return 1
      ;;
    
    wrong-version)
      echo "[WARNING] Using wrong version: Using 1.1 of com.example:wrong-version instead of requested 1.2"
      # Continue with success status
      return 0
      ;;
    
    intermittent)
      # 50% chance of success
      if [[ $((RANDOM % 2)) -eq 0 ]]; then
        echo "[ERROR] Repository temporarily unavailable: Connection refused"
        return 1
      else
        # Pass through to real mvn
        return 0
      fi
      ;;
  esac
}

# Check if this is a dependency-related command
if [[ "$*" == *"dependency"* || "$*" == *"test"* || "$*" == *"package"* ]]; then
  # Simulate the issue
  simulate_issue
  if [[ $? -ne 0 ]]; then
    exit 1
  fi
fi

# Run the real mvn command with custom settings
"$REAL_MVN" --settings "$MVN_SETTINGS" "$@"
EOF
  
  chmod +x "$mvn_wrapper"
  
  # Set environment variables
  export PATH="$repo_dir:$PATH"
  export REPO_ISSUE_TYPE="$issue_type"
  export MVN_SETTINGS="$settings_file"
  
  # Return the temp directory for cleanup
  echo "dir:$repo_dir env:PATH,REPO_ISSUE_TYPE,MVN_SETTINGS,MAVEN_OPTS"
}

# Stop repository issue simulation
stop_repository_issues() {
  local token="$1"
  
  if [[ -z "$token" ]]; then
    echo "No token provided for cleanup" >&2
    return 1
  fi
  
  # Parse token
  local parts=(${token//:/ })
  
  if [[ "${parts[0]}" == "dir" ]]; then
    # Remove directory
    rm -rf "${parts[1]}"
    echo "Removed temporary directory: ${parts[1]}"
  fi
  
  if [[ "${parts[2]}" == "env" ]]; then
    # Reset environment variables
    for var in ${parts[3]//,/ }; do
      if [[ "$var" == "PATH" ]]; then
        # Restore original PATH by removing the temp directory
        export PATH=$(echo "$PATH" | sed "s|${parts[1]}:||")
      elif [[ "$var" == "MAVEN_OPTS" ]]; then
        # Reset MAVEN_OPTS
        export MAVEN_OPTS=$(echo "$MAVEN_OPTS" | sed "s|-Dmaven.repo.local=${parts[1]}/repository||")
      else
        unset "$var"
      fi
    done
    echo "Reset environment variables"
  fi
}

# ------------------------------------------------------------------------------
# I/O THROTTLING
# ------------------------------------------------------------------------------

# Simulates I/O throttling for file operations
simulate_io_throttling() {
  local read_rate="${1:-1024}"   # KB/s
  local write_rate="${2:-1024}"  # KB/s
  
  echo "Simulating I/O throttling (read: ${read_rate}KB/s, write: ${write_rate}KB/s)"
  
  # Function to throttle reading
  cat() {
    if [[ "$1" == "/dev/null" ]]; then
      # Don't throttle /dev/null reads
      command cat "$@"
      return
    fi
    
    # Check if the file exists and get its size
    if [[ ! -f "$1" ]]; then
      command cat "$@"
      return
    fi
    
    local file_size=$(stat -c %s "$1" 2>/dev/null || stat -f %z "$1" 2>/dev/null)
    
    # Calculate delay based on file size and read rate
    local delay=$(echo "scale=3; $file_size / ($read_rate * 1024)" | bc)
    
    # Throttle by adding delay
    sleep "$delay"
    command cat "$@"
  }
  
  # Function to throttle writing
  cp() {
    local src="$1"
    local dst="$2"
    
    # Check if source exists and get its size
    if [[ ! -f "$src" ]]; then
      command cp "$@"
      return
    fi
    
    local file_size=$(stat -c %s "$src" 2>/dev/null || stat -f %z "$src" 2>/dev/null)
    
    # Calculate delay based on file size and write rate
    local delay=$(echo "scale=3; $file_size / ($write_rate * 1024)" | bc)
    
    # Throttle by adding delay before completion
    command cp "$@"
    sleep "$delay"
  }
  
  # Export the functions
  export -f cat
  export -f cp
  
  # Return token for cleanup
  echo "function:cat,cp"
}

# Stop I/O throttling simulation
stop_io_throttling() {
  local token="$1"
  
  if [[ -z "$token" ]]; then
    echo "No token provided for cleanup" >&2
    return 1
  fi
  
  # Parse token
  local parts=(${token//:/ })
  
  if [[ "${parts[0]}" == "function" ]]; then
    # Unset function overrides
    for func in ${parts[1]//,/ }; do
      unset -f "$func" 2>/dev/null || true
    done
    echo "Unset I/O throttling function overrides: ${parts[1]}"
  fi
}

# ------------------------------------------------------------------------------
# TEMPORARY FILE ISSUES
# ------------------------------------------------------------------------------

# Simulates issues with temporary directories
simulate_temp_dir_issues() {
  local issue_type="${1:-space}"  # Options: space, permissions, missing
  
  echo "Simulating temporary directory $issue_type issues"
  
  # Create a fake temporary directory
  local temp_dir=$(mktemp -d)
  
  # Configure the issue
  case "$issue_type" in
    space)
      # Create a disk space issue in temp dir
      if command -v fallocate >/dev/null 2>&1; then
        # Use fallocate to create a large file
        fallocate -l 10M "$temp_dir/big_file" 2>/dev/null || true
      else
        # Fallback to dd
        dd if=/dev/zero of="$temp_dir/big_file" bs=1M count=10 2>/dev/null || true
      fi
      
      # Mock df to show the dir as nearly full
      mock_df_output="Filesystem 1K-blocks Used Available Use% Mounted on"
      mock_df_output+=$'\n'"tmpfs 10240 10230 10 99% $temp_dir"
      
      mock_command "df" 0 "$mock_df_output" "$temp_dir"
      ;;
    
    permissions)
      # Create permission issue
      chmod 500 "$temp_dir"  # read and execute only, no write
      ;;
    
    missing)
      # Simulate missing temp directory
      rm -rf "$temp_dir"
      ;;
  esac
  
  # Override the TMPDIR environment variable
  export TMPDIR="$temp_dir"
  export TEMP="$temp_dir"
  export TMP="$temp_dir"
  
  # Override mktemp to use our directory
  mktemp() {
    case "$issue_type" in
      space)
        echo "mktemp: No space left on device" >&2
        return 1
        ;;
      
      permissions)
        echo "mktemp: Permission denied" >&2
        return 1
        ;;
      
      missing)
        echo "mktemp: failed to create directory via template: No such file or directory" >&2
        return 1
        ;;
    esac
  }
  
  # Export the function
  export -f mktemp
  
  # Return token for cleanup
  echo "dir:$temp_dir env:TMPDIR,TEMP,TMP function:mktemp"
}

# Stop temporary directory issue simulation
stop_temp_dir_issues() {
  local token="$1"
  
  if [[ -z "$token" ]]; then
    echo "No token provided for cleanup" >&2
    return 1
  fi
  
  # Parse token
  local parts=(${token//:/ })
  
  if [[ "${parts[0]}" == "dir" && -d "${parts[1]}" ]]; then
    # Restore permissions and remove directory
    chmod 755 "${parts[1]}" 2>/dev/null || true
    rm -rf "${parts[1]}"
    echo "Removed temporary directory: ${parts[1]}"
  fi
  
  if [[ "${parts[2]}" == "env" ]]; then
    # Reset environment variables
    for var in ${parts[3]//,/ }; do
      unset "$var"
    done
    echo "Unset temporary directory environment variables"
  fi
  
  if [[ "${parts[4]}" == "function" ]]; then
    # Unset function overrides
    for func in ${parts[5]//,/ }; do
      unset -f "$func" 2>/dev/null || true
    done
    echo "Unset function overrides: ${parts[5]}"
  fi
}