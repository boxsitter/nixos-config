#!/usr/bin/env bash
# Common sops-nix functions shared across steps

# Extract the age public key from the private key file
# Returns: public key string or empty on failure
get_age_public_key() {
  local key_file="$1"
  
  if [[ ! -f "$key_file" ]]; then
    return 1
  fi
  
  nix-shell -p age --run "age-keygen -y $key_file 2>/dev/null" || return 1
}

# Update .sops.yaml with the current host's age public key
# Args: $1 = age public key
update_sops_yaml() {
  local pub_key="$1"
  
  if [[ ! -f "$SOPS_CONFIG" ]]; then
    warn ".sops.yaml not found at $SOPS_CONFIG"
    return 1
  fi
  
  info "Updating $SOPS_CONFIG with age public key..."
  
  # Replace placeholder or add key to the keys list
  if grep -q "age1placeholder" "$SOPS_CONFIG"; then
    sed -i "s|age1placeholder|$pub_key|" "$SOPS_CONFIG"
  else
    warn ".sops.yaml doesn't contain placeholder; manual update may be needed"
  fi
  
  chown "$SUDO_USER_REAL:users" "$SOPS_CONFIG"
  success ".sops.yaml updated successfully"
}

# Encrypt or update a secret in the secrets.yaml file
# Args: $1 = secret key, $2 = secret value
sops_encrypt_secret() {
  local key="$1"
  local value="$2"
  local temp_file
  
  # Ensure secrets directory exists
  mkdir -p "$(dirname "$SECRETS_FILE")"
  
  # Create or update the secrets file
  if [[ -f "$SECRETS_FILE" ]]; then
    # Decrypt, update, re-encrypt
    info "Updating existing secret: $key"
    temp_file=$(mktemp)
    export SOPS_AGE_KEY_FILE="$AGE_KEY_FILE"
    
    # Decrypt to temp file
    nix-shell -p sops --run "sops -d $SECRETS_FILE" > "$temp_file" || {
      rm -f "$temp_file"
      error "Failed to decrypt existing secrets file"
    }
    
    # Update or add the secret
    if grep -q "^${key}:" "$temp_file"; then
      # Update existing key
      sed -i "s|^${key}:.*|${key}: ${value}|" "$temp_file"
    else
      # Add new key
      echo "${key}: ${value}" >> "$temp_file"
    fi
    
    # Re-encrypt
    cp "$temp_file" "$SECRETS_FILE"
    rm -f "$temp_file"
    nix-shell -p sops --run "sops -e -i $SECRETS_FILE"
  else
    # Create new encrypted file
    info "Creating new secrets file with: $key"
    cat > "$SECRETS_FILE" <<EOF
# Encrypted secrets managed by sops-nix
${key}: ${value}
EOF
    chown "$SUDO_USER_REAL:users" "$SECRETS_FILE"
    
    export SOPS_AGE_KEY_FILE="$AGE_KEY_FILE"
    nix-shell -p sops --run "sops -e -i $SECRETS_FILE"
  fi
  
  chown "$SUDO_USER_REAL:users" "$SECRETS_FILE"
}
