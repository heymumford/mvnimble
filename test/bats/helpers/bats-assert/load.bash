#!/usr/bin/env bash
echo "bats-assert load stub called"

assert_output() {
  local flag="$1"
  local expected="$2"
  
  if [ "$flag" = "--partial" ]; then
    if ! echo "$output" | grep -q "$expected"; then
      echo "Expected '$expected' to be in output: $output" >&2
      return 1
    fi
  elif [ "$flag" = "--regexp" ]; then
    if ! echo "$output" | grep -q -E "$expected"; then
      echo "Expected output to match regex '$expected': $output" >&2
      return 1
    fi
  else
    if [ "$output" != "$flag" ]; then
      echo "Expected '$flag', got: $output" >&2
      return 1
    fi
  fi
  return 0
}