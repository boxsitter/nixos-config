# Pick an entry from clipboard history (cliphist) and put it back on the clipboard.

selection=$(cliphist list | rofi -dmenu -i -p "" -theme menu \
  -theme-str 'window { width: 640px; } listview { lines: 10; }') || exit 0

printf '%s' "$selection" | cliphist decode | wl-copy
