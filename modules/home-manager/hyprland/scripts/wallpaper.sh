# Wallpaper control on top of awww (animated transitions).
#
#   wallpaper pick      grid picker with thumbnails (rofi)
#   wallpaper random    a different random one
#   wallpaper next      cycle forward
#   wallpaper set NAME  set by file name (with or without extension)
#   wallpaper restore   re-apply the saved choice (login, monitor hotplug)
#
# The wallpapers themselves are in the Nix store (committed under
# resources/wallpapers/<theme>); only the chosen name is state, kept in
# $XDG_STATE_HOME. `current` is a symlink hyprlock reads for its background.

wallpapers="@wallpapers@"
thumbs="@thumbs@"
state="${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper"
mkdir -p "$state"

mapfile -t names < <(find -L "$wallpapers" -maxdepth 1 -type f \
  \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
  -printf '%f\n' | sort)

if [ "${#names[@]}" -eq 0 ]; then
  echo "wallpaper: no images in $wallpapers" >&2
  exit 1
fi

saved() { cat "$state/name" 2>/dev/null || true; }

index_of() {
  local want="$1" i
  for i in "${!names[@]}"; do
    [ "${names[$i]}" = "$want" ] || [ "${names[$i]%.*}" = "$want" ] && { echo "$i"; return 0; }
  done
  return 1
}

apply() { # apply NAME [TRANSITION]
  local name="$1" transition="${2:-grow}" file
  file="$wallpapers/$name"
  [ -f "$file" ] || { echo "wallpaper: not found: $name" >&2; return 1; }

  # The daemon is a user service that starts with the session; wait for it.
  local tries=0
  until awww query >/dev/null 2>&1; do
    tries=$((tries + 1))
    [ "$tries" -lt 100 ] || { echo "wallpaper: awww-daemon is not running" >&2; return 1; }
    sleep 0.1
  done

  awww img "$file" --transition-type "$transition" --transition-duration 0.9 --transition-fps 60
  ln -sfn "$file" "$state/current"
  printf '%s\n' "$name" > "$state/name"
}

case "${1:-pick}" in
  restore)
    cur=$(saved)
    if [ -n "$cur" ] && index_of "$cur" >/dev/null; then
      apply "${names[$(index_of "$cur")]}" none
    else
      apply "${names[0]}" none
    fi
    ;;
  set)
    i=$(index_of "${2:?usage: wallpaper set NAME}") || { echo "wallpaper: unknown wallpaper: $2" >&2; exit 1; }
    apply "${names[$i]}"
    ;;
  next)
    i=$(index_of "$(saved)" || echo -1)
    apply "${names[$(( (i + 1) % ${#names[@]} ))]}"
    ;;
  random)
    cur=$(saved)
    if [ "${#names[@]}" -gt 1 ]; then
      while :; do
        pick=${names[RANDOM % ${#names[@]}]}
        [ "$pick" != "$cur" ] && break
      done
    else
      pick=${names[0]}
    fi
    apply "$pick"
    ;;
  pick)
    start=$(index_of "$(saved)" || echo 0)
    idx=$(
      for n in "${names[@]}"; do
        printf '%s\0icon\x1f%s\n' "${n%.*}" "$thumbs/${n%.*}.jpg"
      done | rofi -dmenu -i -show-icons -format i -selected-row "$start" -p "" -theme grid
    ) || exit 0
    apply "${names[$idx]}"
    ;;
  *)
    echo "usage: wallpaper pick|random|next|set NAME|restore" >&2
    exit 2
    ;;
esac
