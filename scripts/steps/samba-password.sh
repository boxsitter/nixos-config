#!/usr/bin/env bash
# Samba Password Setup Step (Server Only)

get_samba_password_help() {
  echo "Set your Samba password for file sharing access. Required for clients to mount shares."
}

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
