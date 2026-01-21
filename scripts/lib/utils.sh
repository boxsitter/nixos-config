#!/usr/bin/env bash
# Shared utility functions

# Logging functions with consistent formatting
info()  { printf "\n[INFO] %s\n" "$*"; }
warn()  { printf "[WARN] %s\n" "$*"; }
error() { printf "[ERROR] %s\n" "$*"; exit 1; }
success() { printf "[SUCCESS] %s\n\n" "$*"; }

# Check if a command exists
# Args: $1 = command name
# Returns: 0 if exists, 1 otherwise
command_exists() {
  command -v "$1" >/dev/null 2>&1
}
