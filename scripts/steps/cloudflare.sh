#!/usr/bin/env bash
# Cloudflare DNS Token Encryption Step (Server Only)

get_cloudflare_help() {
  echo "Encrypt your Cloudflare API token for Caddy's DNS-01 ACME challenges."
}

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
    if nix-shell -p sops --run "sops -d $SECRETS_FILE 2>/dev/null" 2>/dev/null | grep -q "cloudflare-dns-token"; then
      echo "done"
      return
    fi
  fi
  
  echo "needed"
}

step_sops_cloudflare_token() {
  info "Encrypting Cloudflare API token..."
  
  if [[ ! -f "$AGE_KEY_FILE" ]]; then
    warn "Age key not found; run sops base setup first"
    return 0
  fi
  
  if [[ "${STEP_STATUS[cloudflare]}" == "done" ]]; then
    warn "Cloudflare token already encrypted; updating anyway"
  fi
  
  read -r -p "Enter Cloudflare API token (DNS edit for lhsv.net): " CF_TOKEN
  
  if [[ -z "$CF_TOKEN" ]]; then
    warn "No token provided; skipping"
    return 0
  fi
  
  # Format: CLOUDFLARE_API_TOKEN=value (as expected by Caddy systemd service)
  sops_encrypt_secret "cloudflare-dns-token" "CLOUDFLARE_API_TOKEN=$CF_TOKEN"
  
  success "Cloudflare token encrypted successfully"
  info "Don't forget to commit: cd ~/nixos-config && git add secrets/secrets.yaml && git commit"
}
