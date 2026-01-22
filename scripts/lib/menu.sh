#!/usr/bin/env bash
# Interactive menu functions

# Format step for display in menu
# Args: $1 = step_id
format_step_for_menu() {
  local step_id="$1"
  local status="${STEP_STATUS[$step_id]:-needed}"
  local desc="${STEP_DESCRIPTION[$step_id]:-Unknown step}"
  local rerun_safe="${STEP_RERUN_SAFE[$step_id]:-true}"
  local status_marker
  local safety_marker
  
  # Status marker
  case "$status" in
    "done")
      status_marker="✓"
      ;;
    "needed")
      status_marker="○"
      ;;
    "not-applicable")
      status_marker="✗"
      ;;
  esac
  
  # Rerun safety marker
  if [[ "$rerun_safe" == "true" ]]; then
    safety_marker="[Safe]    "
  else
    safety_marker="[CAUTION] "
  fi
  
  echo "$status_marker $safety_marker $desc"
}

# Show interactive menu and get selected steps
show_step_menu() {
  local -a menu_items=()
  local -a step_ids=()
  local -a help_texts=()
  
  # Build menu items
  for step_id in tailscale sops_base samba_password playit cloudflare samba_creds; do
    local step_status="${STEP_STATUS[$step_id]:-}"
    if [[ -n "$step_status" ]]; then
      local display_text
      display_text=$(format_step_for_menu "$step_id")
      menu_items+=("$display_text")
      step_ids+=("$step_id")
      
      # Get help text for this step
      local help_func="get_${step_id}_help"
      if declare -f "$help_func" >/dev/null; then
        help_texts+=("$("$help_func")")
      else
        help_texts+=("")
      fi
    fi
  done
  
  # Display menu to stderr so it's visible (stdout is captured)
  echo "" >&2
  echo "Status: ✓ = Configured | ○ = Not configured | ✗ = Not applicable to this host" >&2
  echo "Safety: [Safe] = Can re-run anytime | [CAUTION] = May cause issues if re-run" >&2
  echo "" >&2
  
  # Display numbered menu with help text
  local i=1
  for item in "${menu_items[@]}"; do
    # Extract components
    local status_char="${item:0:1}"  # ✓, ○, or ✗
    local rest="${item:2}"  # Everything after status marker and space
    
    # Split safety marker and title
    local safety=""
    local title=""
    if [[ "$rest" =~ ^\[Safe\][[:space:]]+(.*) ]]; then
      safety="[Safe]    "
      title="${BASH_REMATCH[1]}"
    elif [[ "$rest" =~ ^\[CAUTION\][[:space:]]+(.*) ]]; then
      safety="[CAUTION] "
      title="${BASH_REMATCH[1]}"
    else
      title="$rest"
    fi
    
    # Print number and status marker
    printf "%2d) %s  " "$i" "$status_char" >&2
    # Print safety marker in dim/gray if terminal supports it
    printf "\033[2m%s\033[0m" "$safety" >&2
    # Print title in bold
    printf "\033[1m%s\033[0m\n" "$title" >&2
    
    # Print help text indented below if it exists
    if [[ -n "${help_texts[$((i-1))]}" ]]; then
      echo "${help_texts[$((i-1))]}" | sed 's/^/       /' >&2
    fi
    echo "" >&2
    ((i++))
  done
  
  echo "Enter numbers separated by spaces (e.g., '1 3 5'), 'all' for all steps, or 'q' to quit" >&2
  read -r -p "Selection: " selection >&2
  
  # Handle quit
  if [[ "$selection" == "q" || "$selection" == "Q" ]]; then
    echo "" >&2
    return
  fi
  
  # Handle 'all'
  if [[ "$selection" == "all" || "$selection" == "ALL" ]]; then
    echo "${step_ids[@]}"
    return
  fi
  
  # Parse number selections
  local -a selected_steps=()
  local -a invalid_steps=()
  for num in $selection; do
    if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#step_ids[@]}" ]; then
      local selected_id="${step_ids[$((num-1))]}"
      local selected_status="${STEP_STATUS[$selected_id]:-}"
      
      if [[ "$selected_status" == "not-applicable" ]]; then
        invalid_steps+=("$num")
      else
        selected_steps+=("$selected_id")
      fi
    fi
  done
  
  # Warn if any invalid steps were selected
  if [[ ${#invalid_steps[@]} -gt 0 ]]; then
    echo "" >&2
    echo "WARNING: The following steps are not applicable to this host and were skipped: ${invalid_steps[*]}" >&2
    echo "" >&2
  fi
  
  echo "${selected_steps[@]}"
}
