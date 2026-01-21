#!/usr/bin/env bash
# Cloudflare DNS Token Encryption Step (Server Only)

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
