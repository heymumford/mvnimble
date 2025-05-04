#!/usr/bin/env bash
echo "bats-support load stub called"

assert() {
  if ! "$@"; then
    echo "Assert failed: $*" >&2
    return 1
  fi
  return 0
}