#!/usr/bin/env bash
set -euo pipefail

# NixOS Configuration - Imperative Setup Script
#
# Purpose: Handle one-time imperative setup steps that can't be managed 
#          declaratively in NixOS configuration. Each step includes:
#          - Idempotency checks (safe to re-run)
#          - User confirmation prompts
#          - Clear success/failure feedback
#
# Architecture:
#   1. Utility Functions - Logging, confirmations, host detection
#   2. sops-nix Base Functions - Shared secret management setup
#   3. Step Functions - Self-contained setup steps
#   4. Main Orchestration - Host-aware step execution
#
# Secrets Architecture:
#   - ALL hosts: Need sops-nix setup (age key + .sops.yaml)
#   - Server: Needs Cloudflare token (for Caddy DNS-01 ACME)
#   - Clients: Need Samba credentials (to mount server shares)

# Configuration constants

readonly SERVER_HOST="nixos-server"
readonly HOSTNAME_SHORT="$(hostname -s)"
readonly CONFIG_DIR="/home/${SUDO_USER:-${LOGNAME:-$(whoami)}}/nixos-config"
readonly SECRETS_FILE="${CONFIG_DIR}/secrets/secrets.yaml"
readonly SOPS_CONFIG="${CONFIG_DIR}/.sops.yaml"
readonly AGE_KEY_FILE="/var/lib/sops-nix/key.txt"

# Host detection - determines which steps to run
IS_SERVER=0
IS_DESKTOP=0
IS_LAPTOP=0
IS_WSL=0

case "$HOSTNAME_SHORT" in
  "nixos-server")
    IS_SERVER=1
    ;;
  "nixos-desktop")
    IS_DESKTOP=1
    ;;
  "nixos-laptop")
    IS_LAPTOP=1
    ;;
  "nixos-wsl")
    IS_WSL=1
    ;;
esac

# Privilege escalation - re-exec with sudo so the remainder runs as root
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  exec sudo -E "$0" "$@"
fi

# Preserve the real user who invoked sudo
SUDO_USER_REAL=${SUDO_USER:-${LOGNAME:-$(whoami)}}

# Utility functions

# Logging functions with consistent formatting
info()  { printf "\n[INFO] %s\n" "$*"; }
warn()  { printf "[WARN] %s\n" "$*"; }
error() { printf "[ERROR] %s\n" "$*"; exit 1; }
success() { printf "[SUCCESS] %s\n\n" "$*"; }

# Check if a command exists
# Args: $1 = command name
# Returns: 0 if exists, 1 otherwise
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Step status tracking
declare -A STEP_STATUS
declare -A STEP_DESCRIPTION
declare -A STEP_APPLICABLE

# Check step completion status
# Returns: "done", "needed", or "not-applicable"
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

# Initialize step metadata
init_steps() {
  # Step IDs, descriptions, and checks
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

# Format step for display in menu
# Args: $1 = step_id
format_step_for_menu() {
  local step_id="$1"
  local status="${STEP_STATUS[$step_id]}"
  local desc="${STEP_DESCRIPTION[$step_id]}"
  local marker
  local default_state="OFF"
  
  case "$status" in
    "done")
      marker="✓"
      ;;
    "needed")
      marker="○"
      default_state="ON"
      ;;
    "not-applicable")
      marker="—"
      ;;
  esac
  
  echo "$step_id" "$marker $desc" "$default_state"
}

# Show interactive menu and get selected steps
show_step_menu() {
  local menu_items=()
  
  # Build menu items
  for step_id in tailscale sops_base samba_password playit cloudflare samba_creds; do
    if [[ "${STEP_STATUS[$step_id]}" != "not-applicable" ]]; then
      read -r id desc state < <(format_step_for_menu "$step_id")
      menu_items+=("$id" "$desc" "$state")
    fi
  done
  
  # Show menu
  local selected
  selected=$(whiptail --title "NixOS Imperative Setup" \
    --checklist "\nSelect steps to run:\n\n✓ = Already done (safe to re-run)\n○ = Needs setup\n\nUse SPACE to select/deselect, ENTER to confirm:" \
    20 78 10 \
    "${menu_items[@]}" \
    3>&1 1>&2 2>&3)
  
  echo "$selected"
}

# sops-nix base functions - shared secret management operations

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

# Step functions - each step is self-contained and idempotent

# ALL HOSTS: Tailscale Authentication
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

# ALL HOSTS: Base sops-nix Setup
# Sets up age key and updates .sops.yaml - required for any secret usage
step_sops_base_setup() {
  info "Configuring sops-nix base setup..."
  
  # Check if age key exists, if not inform user
  if [[ ! -f "$AGE_KEY_FILE" ]]; then
    warn "Age key not found at $AGE_KEY_FILE"
    info "The age key is auto-generated by sops-nix on first nixos-rebuild"
    info "Please run 'sudo nixos-rebuild switch' first, then re-run this script"
    return 0
  fi
  
  if [[ "${STEP_STATUS[sops_base]}" == "done" ]]; then
    warn "sops already configured; updating anyway"
  fi
  
  # Extract and display public key
  info "Extracting age public key from $AGE_KEY_FILE..."
  local pub_key
  pub_key=$(get_age_public_key "$AGE_KEY_FILE")
  
  if [[ -z "$pub_key" ]]; then
    error "Failed to extract age public key"
  fi
  
  info "Age public key: $pub_key"
  
  # Update .sops.yaml
  update_sops_yaml "$pub_key"
  
  success "sops-nix base setup complete"
  info "Don't forget to commit: cd ~/nixos-config && git add .sops.yaml && git commit"
}

# SERVER ONLY: Set Samba Password
# The server needs a Samba password for users who will access shared folders
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

# SERVER ONLY: Playit Agent Claim
# Playit provides tunneling for Minecraft server accessibility
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

# SERVER ONLY: Cloudflare DNS Token Secret
# Server needs Cloudflare token for Caddy's DNS-01 ACME challenges
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

# CLIENT HOSTS: Samba Mount Credentials Secret  
# Desktop, laptop, WSL need credentials to auto-mount server Samba shares
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

# Main orchestration - runs steps based on host type

main() {
  # Ensure whiptail is available
  if ! command_exists whiptail; then
    info "Installing whiptail for interactive menu..."
    nix-shell -p newt --run "true"
  fi
  
  info "==================================================================="
  info "NixOS Imperative Setup Script"
  info "==================================================================="
  info "Detected host: $HOSTNAME_SHORT"
  info "  Server: $IS_SERVER | Desktop: $IS_DESKTOP | Laptop: $IS_LAPTOP | WSL: $IS_WSL"
  info "  User: $SUDO_USER_REAL"
  info "==================================================================="
  
  # Initialize step status checks
  info "Checking step status..."
  init_steps
  
  # Show interactive menu
  local selected_steps
  selected_steps=$(nix-shell -p newt --run "$(declare -f show_step_menu format_step_for_menu); $(declare -p STEP_STATUS STEP_DESCRIPTION); show_step_menu")
  
  # Check if user cancelled
  if [[ -z "$selected_steps" ]]; then
    info "Setup cancelled by user"
    exit 0
  fi
  
  # Convert selected steps to array (whiptail returns quoted space-separated list)
  local -a steps_to_run
  eval "steps_to_run=($selected_steps)"
  
  if [[ ${#steps_to_run[@]} -eq 0 ]]; then
    info "No steps selected"
    exit 0
  fi
  
  # Run selected steps in order
  info "\n==================================================================="
  info "Running selected steps..."
  info "==================================================================="
  
  for step_id in "${steps_to_run[@]}"; do
    case "$step_id" in
      tailscale)
        step_tailscale
        ;;
      sops_base)
        step_sops_base_setup
        ;;
      samba_password)
        step_samba_password
        ;;
      playit)
        step_playit_claim
        ;;
      cloudflare)
        step_sops_cloudflare_token
        ;;
      samba_creds)
        step_sops_samba_credentials
        ;;
    esac
  done
  
  info "==================================================================="
  success "All selected steps completed successfully!"
  info "==================================================================="
  info "Next steps:"
  info "  1. Review and commit any changes to .sops.yaml and secrets/"
  info "  2. Run: sudo nixos-rebuild switch"
  info "  3. Verify services are working correctly"
  info "==================================================================="
}

main "$@"
