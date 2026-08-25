# Laptop display-blank troubleshooting log

**Host:** `nixos-laptop` — Dell XPS 15 9530, Intel Raptor Lake-H iGPU + NVIDIA RTX 3050
Mobile (PRIME offload, RTD3). GNOME on Wayland via GDM. Suspend = `s2idle`.

This file exists so this problem stops getting re-diagnosed from scratch. **If you are an
agent or a future me: read this whole file before changing any display/suspend/power
config, and do not "declare a definitive fix" — this bug has survived many of those.**
Change ONE variable at a time and confirm against the recorders (see Instrumentation).

---

## Symptom (refined)

On the **unlocked, actively-used desktop**, a few (~20–30) seconds after resuming from a
lid-close, the **screen backlight and the keyboard backlight turn off together**, abruptly,
for ~1–2 seconds. **Any keypress recovers it.** Originally thought to need a *prolonged*
close, but it has reproduced after a **15-second** close too.

Key user observations that constrain the cause:
- Screen + **keyboard** backlight die **simultaneously**.
- It is a full **blank**, not the gentle partial **dim** that normal GNOME idle-dim does
  (that still works normally and is different).
- **No actual inactivity** — the user is present/active when it happens.
- **Does not happen on Windows** (same machine, dual-boot) → not a raw hardware failure.

---

## CURRENT STATUS (2026-08-24): confirmed software-triggered, narrowed to 2 actors

Diagnosis is **evidence-based now**, from two custom recorders (below), not theory.

### Definitively RULED OUT (with evidence)

- **Intel PSR** — disabled via `i915.enable_psr=0`, rebooted, **blank still happened**.
  (Boot cmdline confirmed `i915.enable_psr=0`, kernel no longer tainted.) PSR was a wrong
  lead; see history.
- **Idle screen-blank timeout** — `org.gnome.desktop.session idle-delay = 0` (blank
  disabled). Not the path.
- **Lock screen / screensaver** — recorder shows `ss=false` at the blank (unlocked).
- **Phantom ACPI/HID/lid key event** — the input recorder captured **nothing** at the
  blank instant: no `SW_LID`, no Video Bus, no Dell WMI, no Intel HID, no key. The only
  input events all session were *real* lid open/close + wake.
- **Hardware sensor fault (e.g. flaky lid Hall sensor)** — would also break under Windows;
  it doesn't. And no `SW_LID` fires at the blank.
- **NVIDIA GPU / RTD3** — display is driven by Intel i915; all activity is on the Intel
  pipe. NVIDIA is offload-only and asleep.
- **DRM/KMS hardware fault** — the blank leaves **zero** journal entries (no DRM error, no
  atomic-commit failure). It is a clean, deliberate power-off, not a crash.

### The one hard fact that drives everything

The **screen backlight AND keyboard backlight turn off in the same instant.** On this
laptop only **two** things gang those two backlights together:

1. **GNOME `gsd-power`** (software, GNOME's power daemon), or
2. **The embedded controller / firmware** (EC natively cuts both backlights on a lid
   signal, and can do so **without** emitting any OS event — which matches the total log
   silence, and could differ from Windows if Linux programs the EC / lid-detect
   differently).

Splitting these two is the current open question.

### Captured evidence (blank at 2026-08-24 14:23:27, from the recorder)

```
14:23:26  bl_power=0  screen_bright=29472  kbd=1   ← everything on
14:23:27  bl_power=4  screen_bright=0      kbd=0   ← BLANK: screen + keyboard off together
14:23:28  bl_power=4  screen_bright=0      kbd=0
14:23:29  bl_power=0  screen_bright=29472  kbd=1   ← recovered (keypress)
```
Input recorder at 14:23:27: **no events.** `ss=false` throughout (unlocked).
NOTE: the `idle_ms` column in the recorder is **unreliable** on this box — it jumps between
0.6s and 640s between one-second samples (physically impossible), so do NOT rest any
argument on "was idle / wasn't idle."

---

## Instrumentation (the recorders — reuse these)

Two dependency-free recorders run as **user systemd services** (survive suspend, not
reboot). Scripts live in the repo root:

- `scratchpad-blank-capture.sh` → logs `bl_power`, screen brightness, **kbd backlight**,
  idle_ms, screensaver-active, AC — once/sec to `~/display-blank-capture.log`.
- `scratchpad-input-capture.pl` → decodes `/dev/input/event{1..9}` (Lid, Power, Intel HID,
  Dell WMI, Video Bus — **not** the keyboard, so no keystrokes) to `~/input-capture.log`.

```fish
# start (note: systemd --user has a minimal PATH, pass absolute interpreter paths)
systemd-run --user --unit=blank-capture bash /home/leyton/nixos-config/scratchpad-blank-capture.sh
systemd-run --user --unit=input-capture (command -v perl) /home/leyton/nixos-config/scratchpad-input-capture.pl
# status / stop
systemctl --user is-active blank-capture input-capture
systemctl --user stop blank-capture input-capture
```

To analyze a blank: find `bl_power=4` in `~/display-blank-capture.log`, note the timestamp,
then check `~/input-capture.log` for any event at that same second.

---

## OPEN EXPERIMENT (in progress as of 2026-08-24)

To split "gsd-power vs EC/firmware," `idle-dim` was turned **off live** (session only, NOT
written to any config file):

```fish
gsettings set org.gnome.settings-daemon.plugins.power idle-dim false   # revert: ... true
```

This is a **discriminator, not a claimed fix** (normal idle-dim only dims and works fine;
unlikely to be the direct culprit). Waiting for the next reproduction:

- **Still blanks with idle-dim off** → gsd-power idle path exonerated → cause is the
  **EC/firmware** (or a non-idle gsd-power trigger). Investigate at the firmware/kernel
  layer: BIOS revision on the 9530, `dell_laptop`/`dell-wmi` handling, lid-detect / GPIO,
  `acpi_osi`, EC quirks.
- **Stops blanking** → a gsd-power idle path *was* involved after all → pursue the GNOME
  side (which gsd-power idle mode, why it triggers with no real inactivity).

Restore normal dimming (`idle-dim true`) once the question is answered, then apply the
*real* fix based on the result. If a fix is confirmed, make it declarative in
`modules/home-manager/gnome.nix` (dconf) or the appropriate NixOS layer — the current
change is live-only and will not survive a dconf reset.

Live power settings snapshot (2026-08-24): `idle-delay=0`, `idle-dim` now false,
`ambient-enabled=true`, `sleep-inactive-ac-type=nothing`,
`sleep-inactive-battery-type=suspend`/`timeout=900`. If the EC path is ruled out and it's
gsd-power, `ambient-enabled=true` (auto-brightness from light sensor) is the next single
lever to test.

---

## Full history of attempts (so nobody repeats them)

| Date | Where | Attempt | Verdict |
|------|-------|---------|---------|
| 2026-02-17 | b761ff2 | Xorg DPMS/BlankTime off, gdm autoSuspend off | Inert — session is Wayland, not Xorg |
| 2026-03-11 | 2ac1c7a | nvme APST off, nvidia early module load | Unrelated to the blank |
| 2026-04-27 | ae83744 | `i915.enable_psr=1` (forced on) | Wrong direction |
| 2026-04-29 | 5d7c710 | Removed param → PSR at kernel default | Default ≠ off; not a real test |
| 2026-05-04 | 721c9a0 | NVIDIA RTD3 60s autosuspend delay | Wrong GPU — Intel drives the display |
| 2026-05-13 | cfb6420 | `enable_psr=1 + psr_safest_params=1` | Keeps PSR on — did not help |
| 2026-08-20 | (this repo) | `i915.enable_psr=0` (fully off) | **RULED OUT** — rebooted, blank still happens |
| 2026-08-24 | live gsettings | `idle-dim=false` (discriminator) | **In progress** — awaiting reproduction |

The NVIDIA RTD3 udev rule (`autosuspend_delay_ms=60000`, from 721c9a0) is still in
`nvidia-laptop.nix`. Harmless; left in place to change one variable at a time. The
`i915.enable_psr=0` line is currently applied — decide whether to keep (battery vs the
earlier PSR atomic-commit glitches) once the real cause is fixed.

---

## Quick-start for the next session

1. Read this file.
2. Check the recorders are running (`systemctl --user is-active blank-capture input-capture`);
   restart if a reboot happened (see Instrumentation).
3. When the user reports a blank, pull both logs and line them up by timestamp.
4. Resolve the OPEN EXPERIMENT above (gsd-power vs EC/firmware), then fix at that layer.
