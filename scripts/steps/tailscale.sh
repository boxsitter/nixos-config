#!/usr/bin/env bash
# Tailscale VPN Authentication Step

get_tailscale_help() {
  echo "Authenticate this machine to your Tailscale network for secure VPN access."
}

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

step_tailscale() {
  info "Configuring Tailscale VPN authentication..."
  
  if ! command_exists tailscale; then
    error "tailscale binary not found; ensure Tailscale is installed via NixOS config"
  fi
  
  if [[ "${STEP_STATUS[tailscale]}" == "done" ]]; then
    warn "Tailscale already authenticated; re-authenticating anyway"
  fi
  
  read -r -p "Enter Tailscale auth key (blank for interactive login): " AUTHKEY
  if [[ -n "$AUTHKEY" ]]; then
    tailscale up --ssh --authkey "$AUTHKEY"
  else
    tailscale up --ssh
  fi
  
  success "Tailscale configured successfully"
}
