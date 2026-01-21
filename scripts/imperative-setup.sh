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
source "${SCRIPT_DIR}/lib/status.sh"
source "${SCRIPT_DIR}/lib/menu.sh"

# Source step files
source "${SCRIPT_DIR}/steps/tailscale.sh"
source "${SCRIPT_DIR}/steps/sops-base.sh"
source "${SCRIPT_DIR}/steps/samba-password.sh"
source "${SCRIPT_DIR}/steps/playit.sh"
source "${SCRIPT_DIR}/steps/cloudflare.sh"
source "${SCRIPT_DIR}/steps/samba-credentials.sh"

# Main orchestration
main() {
  # Ensure whiptail is available
  if ! command_exists whiptail; then
    info "Installing whiptail for interactive menu..."
    nix-shell -p whiptail --run "true"
  fi
  
  info "==================================================================="
  info "NixOS Imperative Setup Script"
  info "==================================================================="
  info "Detected host: $HOSTNAME_SHORT"
  info "  Server: $IS_SERVER | Desktop: $IS_DESKTOP | Laptop: $IS_LAPTOP | WSL: $IS_WSL"
  info "  User: $SUDO_USER_REAL"
  info "==================================================================="
  
  # Initialize step status checks
  info "Checking step status..."
  init_steps
  
  # Show interactive menu
  local selected_steps
  selected_steps=$(nix-shell -p whiptail --run "$(declare -f show_step_menu format_step_for_menu); $(declare -p STEP_STATUS STEP_DESCRIPTION); show_step_menu")
  
  # Check if user cancelled
  if [[ -z "$selected_steps" ]]; then
    info "Setup cancelled by user"
    exit 0
  fi
  
  # Convert selected steps to array (whiptail returns quoted space-separated list)
  local -a steps_to_run
  eval "steps_to_run=($selected_steps)"
  
  if [[ ${#steps_to_run[@]} -eq 0 ]]; then
    info "No steps selected"
    exit 0
  fi
  
  # Run selected steps in order
  info "\n==================================================================="
  info "Running selected steps..."
  info "==================================================================="
  
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
  
  info "==================================================================="
  success "All selected steps completed successfully!"
  info "==================================================================="
  info "Next steps:"
  info "  1. Review and commit any changes to .sops.yaml and secrets/"
  info "  2. Run: sudo nixos-rebuild switch"
  info "  3. Verify services are working correctly"
  info "==================================================================="
}

main "$@"
