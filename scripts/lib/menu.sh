#!/usr/bin/env bash
# Interactive menu functions

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
