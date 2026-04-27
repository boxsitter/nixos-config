How to confirm which one it is
Run these immediately after reproducing the blank:

# Check for PSR events (i915)
sudo dmesg | grep -iE "psr|i915" | tail -30

# Check for NVIDIA runtime PM events
sudo dmesg | grep -iE "nvidia.*runtime|d3cold|rtd3" | tail -20

# Check if GNOME shell restarted (extension crash)
journalctl --user -b | grep -iE "gnome-shell|extension|killed|crash" | tail -20

If you see i915.*psr entries → Suspect A is confirmed
If you see nvidia.*D3 or d3cold entries → Suspect B is confirmed
If you see gnome-shell crash/restart entries → it's the gSnap extension (less likely since it's reproducible only on laptop, not desktop)