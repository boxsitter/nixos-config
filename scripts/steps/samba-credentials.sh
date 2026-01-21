#!/usr/bin/env bash
# Samba Mount Credentials Encryption Step (Client Hosts Only)

step_sops_samba_credentials() {
  info "Encrypting Samba mount credentials..."
  
  if [[ ! -f "$AGE_KEY_FILE" ]]; then
    warn "Age key not found; run sops base setup first"
    return 0
  fi
  
  if [[ "${STEP_STATUS[samba_creds]}" == "done" ]]; then
    warn "Samba credentials already encrypted; updating anyway"
  fi
  
  read -r -p "Enter Samba username (usually 'leyton'): " SAMBA_USER
  read -r -s -p "Enter Samba password: " SAMBA_PASSWORD
  echo ""
  read -r -p "Enter Samba domain (usually 'WORKGROUP'): " SAMBA_DOMAIN
  
  if [[ -z "$SAMBA_USER" ]] || [[ -z "$SAMBA_PASSWORD" ]]; then
    warn "Username or password empty; skipping"
    return 0
  fi
  
  SAMBA_DOMAIN="${SAMBA_DOMAIN:-WORKGROUP}"
  
  # Format as multi-line credentials file (as expected by mount.cifs)
  local credentials
  credentials=$(cat <<EOF
username=${SAMBA_USER}
password=${SAMBA_PASSWORD}
domain=${SAMBA_DOMAIN}
EOF
)
  
  # For multi-line secrets, we need to handle this specially
  # Create temp file with proper formatting
  local temp_file=$(mktemp)
  
  if [[ -f "$SECRETS_FILE" ]]; then
    export SOPS_AGE_KEY_FILE="$AGE_KEY_FILE"
    nix-shell -p sops --run "sops -d $SECRETS_FILE" > "$temp_file" 2>/dev/null || {
      # File doesn't exist yet or can't decrypt, create new
      cat > "$temp_file" <<EOF
# Encrypted secrets managed by sops-nix
EOF
    }
  else
    cat > "$temp_file" <<EOF
# Encrypted secrets managed by sops-nix
EOF
  fi
  
  # Remove existing samba-credentials if present
  sed -i '/^samba-credentials:/,/^[a-z-]*:/{ /^samba-credentials:/d; /^  /d; /^[a-z-]*:/!d; }' "$temp_file"
  
  # Add new samba-credentials
  cat >> "$temp_file" <<EOF
samba-credentials: |
  username=${SAMBA_USER}
  password=${SAMBA_PASSWORD}
  domain=${SAMBA_DOMAIN}
EOF
  
  # Encrypt the file
  cp "$temp_file" "$SECRETS_FILE"
  rm -f "$temp_file"
  chown "$SUDO_USER_REAL:users" "$SECRETS_FILE"
  
  export SOPS_AGE_KEY_FILE="$AGE_KEY_FILE"
  nix-shell -p sops --run "sops -e -i $SECRETS_FILE"
  
  success "Samba credentials encrypted successfully"
  info "Don't forget to commit: cd ~/nixos-config && git add secrets/secrets.yaml && git commit"
}
