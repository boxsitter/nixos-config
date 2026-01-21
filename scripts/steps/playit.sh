#!/usr/bin/env bash
# Playit Agent Claim Step (Server Only)

step_playit_claim() {
  local playit_config="/var/lib/playit/playit.toml"
  local user_config="/home/${SUDO_USER_REAL}/.config/playit_gg/playit.toml"
  
  info "Starting playit agent claim process..."
  
  if [[ "${STEP_STATUS[playit]}" == "done" ]]; then
    warn "$playit_config exists; re-claiming anyway"
  fi
  
  info "Follow the prompts to authenticate and configure your tunnel"
  
  # Run as the invoking user so config lands in their home directory
  sudo -u "$SUDO_USER_REAL" nix run github:pedorich-n/playit-nixos-module#playit-cli -- start
  
  # Copy claimed config to system location
  if [[ -f "$user_config" ]]; then
    info "Copying claimed playit.toml to $playit_config..."
    install -d -m755 /var/lib/playit
    install -m600 "$user_config" "$playit_config"
    chown playit:playit "$playit_config"
    success "Playit agent claimed and configured successfully"
  else
    warn "Could not find $user_config after claim"
    warn "If the claim was successful, copy it manually to $playit_config"
  fi
}
