#!/usr/bin/env bash
# Status checking functions for all steps

# Step status tracking
declare -A STEP_STATUS
declare -A STEP_DESCRIPTION

# Check if Tailscale is authenticated
check_tailscale_status() {
  if ! command_exists tailscale; then
    echo "not-applicable"
    return
  fi
  
  if tailscale status --peers=false >/dev/null 2>&1; then
    echo "done"
  else
    echo "needed"
  fi
}

# Check if sops base setup is complete
check_sops_base_status() {
  if [[ ! -f "$AGE_KEY_FILE" ]]; then
    echo "needed"
    return
  fi
  
  local pub_key
  pub_key=$(get_age_public_key "$AGE_KEY_FILE" 2>/dev/null)
  
  if [[ -n "$pub_key" ]] && grep -q "$pub_key" "$SOPS_CONFIG" 2>/dev/null; then
    echo "done"
  else
    echo "needed"
  fi
}

# Check if Samba password is set (server only)
check_samba_password_status() {
  if [[ $IS_SERVER -ne 1 ]]; then
    echo "not-applicable"
    return
  fi
  
  if ! command_exists pdbedit; then
    echo "not-applicable"
    return
  fi
  
  if pdbedit -L 2>/dev/null | grep -q "^${SUDO_USER_REAL}:"; then
    echo "done"
  else
    echo "needed"
  fi
}

# Check if Playit agent is claimed (server only)
check_playit_status() {
  if [[ $IS_SERVER -ne 1 ]]; then
    echo "not-applicable"
    return
  fi
  
  if [[ -f "/var/lib/playit/playit.toml" ]]; then
    echo "done"
  else
    echo "needed"
  fi
}

# Check if Cloudflare token is encrypted (server only)
check_cloudflare_token_status() {
  if [[ $IS_SERVER -ne 1 ]]; then
    echo "not-applicable"
    return
  fi
  
  if [[ ! -f "$AGE_KEY_FILE" ]]; then
    echo "needed"
    return
  fi
  
  if [[ -f "$SECRETS_FILE" ]]; then
    export SOPS_AGE_KEY_FILE="$AGE_KEY_FILE"
    if nix-shell -p sops --run "sops -d $SECRETS_FILE 2>/dev/null" | grep -q "cloudflare-dns-token"; then
      echo "done"
      return
    fi
  fi
  
  echo "needed"
}

# Check if Samba credentials are encrypted (client only)
check_samba_credentials_status() {
  if [[ $IS_SERVER -eq 1 ]]; then
    echo "not-applicable"
    return
  fi
  
  if [[ ! -f "$AGE_KEY_FILE" ]]; then
    echo "needed"
    return
  fi
  
  if [[ -f "$SECRETS_FILE" ]]; then
    export SOPS_AGE_KEY_FILE="$AGE_KEY_FILE"
    if nix-shell -p sops --run "sops -d $SECRETS_FILE 2>/dev/null" | grep -q "samba-credentials"; then
      echo "done"
      return
    fi
  fi
  
  echo "needed"
}

# Initialize step metadata and check all statuses
init_steps() {
  # Step IDs and descriptions
  STEP_DESCRIPTION["tailscale"]="Tailscale VPN authentication"
  STEP_DESCRIPTION["sops_base"]="sops-nix base setup (age key + .sops.yaml)"
  STEP_DESCRIPTION["samba_password"]="Samba password (server only)"
  STEP_DESCRIPTION["playit"]="Playit tunnel agent claim (server only)"
  STEP_DESCRIPTION["cloudflare"]="Cloudflare DNS token (server only)"
  STEP_DESCRIPTION["samba_creds"]="Samba mount credentials (clients only)"
  
  # Check status for each step
  STEP_STATUS["tailscale"]=$(check_tailscale_status)
  STEP_STATUS["sops_base"]=$(check_sops_base_status)
  STEP_STATUS["samba_password"]=$(check_samba_password_status)
  STEP_STATUS["playit"]=$(check_playit_status)
  STEP_STATUS["cloudflare"]=$(check_cloudflare_token_status)
  STEP_STATUS["samba_creds"]=$(check_samba_credentials_status)
}
