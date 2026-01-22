#!/usr/bin/env bash
# Status checking coordination

# Step status tracking
declare -A STEP_STATUS
declare -A STEP_DESCRIPTION
declare -A STEP_RERUN_SAFE

# Initialize step metadata and check all statuses
# Note: check_*_status functions are defined in their respective step files
init_steps() {
  # Step IDs and descriptions
  STEP_DESCRIPTION["tailscale"]="Tailscale VPN authentication"
  STEP_DESCRIPTION["sops_base"]="sops-nix base setup (age key + .sops.yaml)"
  STEP_DESCRIPTION["samba_password"]="Samba password (server only)"
  STEP_DESCRIPTION["playit"]="Playit tunnel agent claim (server only)"
  STEP_DESCRIPTION["cloudflare"]="Cloudflare DNS token (server only)"
  STEP_DESCRIPTION["samba_creds"]="Samba mount credentials (clients only)"
  
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
