# Toggle the blue-light filter (hyprsunset). The on/off state is kept in the
# runtime dir, so it resets at logout like the daemon does.

state="${XDG_RUNTIME_DIR:-/tmp}/nightlight-on"

if [ -e "$state" ]; then
  hyprctl hyprsunset identity >/dev/null
  rm -f "$state"
  notify-send -t 1500 -u low "Night light" "Off"
else
  hyprctl hyprsunset temperature 3800 >/dev/null
  touch "$state"
  notify-send -t 1500 -u low "Night light" "On"
fi
