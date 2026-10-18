# Show every described keybind from the running Hyprland, so the list can never
# drift from the config. Selecting an entry does nothing; it is a cheat sheet.
# Columns are aligned with a monospace font.

hyprctl binds -j | jq -r '
  def mods($m):
    [ (if ($m / 64 | floor) % 2 == 1 then "Super" else empty end),
      (if ($m / 4  | floor) % 2 == 1 then "Ctrl"  else empty end),
      (if ($m / 8  | floor) % 2 == 1 then "Alt"   else empty end),
      (if ($m      | floor) % 2 == 1 then "Shift" else empty end) ];
  def pretty($k):
    ({ "left": "←", "right": "→", "up": "↑", "down": "↓",
       "slash": "/", "backslash": "\\", "comma": ",", "period": ".",
       "grave": "`", "bracketleft": "[", "bracketright": "]",
       "Return": "Enter", "Escape": "Esc", "Print": "PrtSc", "Space": "Space",
       "mouse:272": "Mouse 1", "mouse:273": "Mouse 2",
       "mouse_down": "Scroll down", "mouse_up": "Scroll up" })[$k] // $k;
  .[] | select(.has_description)
      | ((mods(.modmask) + [pretty(.key)]) | join(" + ")) + "\t" + .description
' | column -t -s "$(printf '\t')" -o '   ' | rofi -dmenu -i -p "keybinds" -theme menu \
  -theme-str 'window { width: 820px; } listview { lines: 14; } element-text { font: "@mono@ 11"; }' >/dev/null || true
