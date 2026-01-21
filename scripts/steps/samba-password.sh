#!/usr/bin/env bash
# Samba Password Setup Step (Server Only)

step_samba_password() {
  local user="$SUDO_USER_REAL"
  info "Setting Samba password for user '$user'..."
  
  if ! command_exists pdbedit; then
    warn "pdbedit not found; Samba may not be installed"
    return 0
  fi
  
  if [[ "${STEP_STATUS[samba_password]}" == "done" ]]; then
    warn "Samba password already set; updating anyway"
  fi
  
  smbpasswd -a "$user"
  success "Samba password configured for $user"
}
