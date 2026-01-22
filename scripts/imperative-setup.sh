#!/usr/bin/env bash
set -euo pipefail

# NixOS Configuration - Imperative Setup Script
#
# Purpose: Handle one-time imperative setup steps that can't be managed 
#          declaratively in NixOS configuration. Each step includes:
#          - Idempotency checks (safe to re-run)
#          - User confirmation via interactive menu
#          - Clear success/failure feedback
#
# Architecture:
#   This script orchestrates modular step files located in scripts/steps/
#   Each step is self-contained and can be easily maintained independently.
#
# Secrets Architecture:
#   - ALL hosts: Need sops-nix setup (age key + .sops.yaml)
#   - Server: Needs Cloudflare token (for Caddy DNS-01 ACME)
#   - Clients: Need Samba credentials (to mount server shares)

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration constants
readonly SERVER_HOST="nixos-server"
readonly HOSTNAME_SHORT="$(hostname -s)"
readonly CONFIG_DIR="/home/${SUDO_USER:-${LOGNAME:-$(whoami)}}/nixos-config"
readonly SECRETS_FILE="${CONFIG_DIR}/secrets/secrets.yaml"
readonly SOPS_CONFIG="${CONFIG_DIR}/.sops.yaml"
readonly AGE_KEY_FILE="/var/lib/sops-nix/key.txt"

# Host detection - determines which steps to run
IS_SERVER=0
IS_DESKTOP=0
IS_LAPTOP=0
IS_WSL=0

case "$HOSTNAME_SHORT" in
  "nixos-server")
    IS_SERVER=1
    ;;
  "nixos-desktop")
    IS_DESKTOP=1
    ;;
  "nixos-laptop")
    IS_LAPTOP=1
    ;;
  "nixos-wsl")
    IS_WSL=1
    ;;
esac

# Privilege escalation - re-exec with sudo so the remainder runs as root
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  exec sudo -E "$0" "$@"
fi

# Preserve the real user who invoked sudo
SUDO_USER_REAL=${SUDO_USER:-${LOGNAME:-$(whoami)}}

# Source library files
source "${SCRIPT_DIR}/lib/utils.sh"
source "${SCRIPT_DIR}/lib/sops-common.sh"
source "${SCRIPT_DIR}/lib/menu.sh"

# Source step files
source "${SCRIPT_DIR}/steps/tailscale.sh"
source "${SCRIPT_DIR}/steps/sops-base.sh"
source "${SCRIPT_DIR}/steps/samba-password.sh"
source "${SCRIPT_DIR}/steps/playit.sh"
source "${SCRIPT_DIR}/steps/cloudflare.sh"
source "${SCRIPT_DIR}/steps/samba-credentials.sh"

# Step status tracking
declare -A STEP_STATUS
declare -A STEP_DESCRIPTION
declare -A STEP_RERUN_SAFE

# Initialize step metadata and check all statuses
init_steps() {
  # Step IDs and descriptions
  STEP_DESCRIPTION["tailscale"]="Tailscale VPN authentication"
  STEP_DESCRIPTION["sops_base"]="sops-nix base setup (age key + .sops.yaml)"
  STEP_DESCRIPTION["samba_password"]="Samba password for file sharing"
  STEP_DESCRIPTION["playit"]="Playit tunnel agent claim"
  STEP_DESCRIPTION["cloudflare"]="Cloudflare DNS token for Caddy ACME"
  STEP_DESCRIPTION["samba_creds"]="Samba mount credentials"
  
  # Mark which steps are safe to re-run (true=safe, false=caution needed)
  STEP_RERUN_SAFE["tailscale"]="true"
  STEP_RERUN_SAFE["sops_base"]="true"
  STEP_RERUN_SAFE["samba_password"]="true"
  STEP_RERUN_SAFE["playit"]="false"  # Creates duplicate agents if re-run
  STEP_RERUN_SAFE["cloudflare"]="true"
  STEP_RERUN_SAFE["samba_creds"]="true"
  
  # Check status for each step (functions defined in step files)
  STEP_STATUS["tailscale"]=$(check_tailscale_status)
  STEP_STATUS["sops_base"]=$(check_sops_base_status)
  STEP_STATUS["samba_password"]=$(check_samba_password_status)
  STEP_STATUS["playit"]=$(check_playit_status)
  STEP_STATUS["cloudflare"]=$(check_cloudflare_token_status)
  STEP_STATUS["samba_creds"]=$(check_samba_credentials_status)
}

# Main orchestration
main() {
  info "NixOS Imperative Setup Script"
  info "Detected host: $HOSTNAME_SHORT"
  
  # Initialize step status checks
  info "Checking step status..."
  init_steps
  
  # Show interactive menu
  local selected_steps
  selected_steps=$(show_step_menu)
  
  # Check if user cancelled
  if [[ -z "$selected_steps" ]]; then
    info "Setup cancelled by user"
    exit 0
  fi
  
  # Convert selected steps to array
  local -a steps_to_run
  read -r -a steps_to_run <<< "$selected_steps"
  
  if [[ ${#steps_to_run[@]} -eq 0 ]]; then
    info "No steps selected"
    exit 0
  fi
  
  # Run selected steps in order
  info "\nRunning selected steps..."
  
  for step_id in "${steps_to_run[@]}"; do
    case "$step_id" in
      tailscale)
        step_tailscale
        ;;
      sops_base)
        step_sops_base_setup
        ;;
      samba_password)
        step_samba_password
        ;;
      playit)
        step_playit_claim
        ;;
      cloudflare)
        step_sops_cloudflare_token
        ;;
      samba_creds)
        step_sops_samba_credentials
        ;;
    esac
  done
  
  success "All selected steps completed successfully!"
  info "Next steps:"
  info "  1. Review and commit any changes to .sops.yaml and secrets/"
  info "  2. Run: sudo nixos-rebuild switch"
  info "  3. Verify services are working correctly"
}

main "$@"
