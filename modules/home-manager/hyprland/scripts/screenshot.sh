# Screenshots via hyprshot. region/window/output save to ~/Pictures/Screenshots
# AND copy to the clipboard (with a notification). `region` and `window` ask you
# to select; `output` grabs the active monitor straight away. `edit` drops the
# selected region into satty for annotation instead.

dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$dir"

case "${1:-region}" in
  region) hyprshot -m region --freeze -o "$dir" ;;
  window) hyprshot -m window --freeze -o "$dir" ;;
  # hyprshot exits 1 after a *successful* capture of the active output: its
  # trailing `pkill hyprpicker` finds nothing (hyprpicker is only used by the
  # interactive modes). The screenshot is saved and copied either way.
  output) hyprshot -m output -m active -o "$dir" || true ;;
  edit)
    hyprshot -m region --freeze --raw -s | satty --filename - \
      --output-filename "$dir/$(date +%Y-%m-%d_%H-%M-%S)-edit.png" \
      --early-exit --copy-command wl-copy --actions-on-enter save-to-clipboard
    ;;
  *) echo "usage: screenshot region|window|output|edit" >&2; exit 2 ;;
esac
