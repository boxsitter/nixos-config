# Power menu: rofi list; destructive actions ask first. Logout/reboot/shutdown
# go through hyprshutdown, which asks apps to quit cleanly before exiting.

menu() { rofi -dmenu -i -p "" -theme menu -theme-str "window { width: 300px; } listview { lines: $1; }"; }

confirm() {
  [ "$(printf 'No\nYes\n' | menu 2 | head -n1)" = "Yes" ]
}

lock=$(printf '\U000f033e')       # nf-md-lock
suspend=$(printf '\U000f04b2')    # nf-md-sleep
logout=$(printf '\U000f05fd')     # nf-md-logout
reboot=$(printf '\U000f0709')     # nf-md-restart
shutdown=$(printf '\U000f0425')   # nf-md-power

choice=$(printf '%s  Lock\n%s  Suspend\n%s  Log out\n%s  Reboot\n%s  Shut down\n' \
  "$lock" "$suspend" "$logout" "$reboot" "$shutdown" | menu 5) || exit 0

case "$choice" in
  *Lock)     loginctl lock-session ;;
  *Suspend)  systemctl suspend ;;
  *"Log out") confirm && hyprshutdown -t "Logging out..." ;;
  *Reboot)   confirm && hyprshutdown -t "Restarting..." --post-cmd "systemctl reboot" ;;
  *"Shut down") confirm && hyprshutdown -t "Shutting down..." --post-cmd "systemctl poweroff" ;;
esac
