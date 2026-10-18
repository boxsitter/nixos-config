# modules/home-manager/hyprland/binds.nix
# Keybinds. Super is the modifier. Every bind carries a description, and
# Super+/ shows them all (generated from `hyprctl binds`, so it cannot go
# stale). The helper commands (power-menu, wallpaper, screenshot, ...) are
# small scripts defined in the module that owns the feature.
#
# Layout of the scheme:
#   Super + key           act            Super + Shift + key   move / alternate
#   Super + Ctrl + key    resize         Super + Alt + key     (unused, free)

{ ... }:

{
  wayland.windowManager.hyprland.extraLuaFiles."40-binds" = ''
    local mod = "SUPER"

    local function bind(keys, desc, action, opts)
      opts = opts or {}
      opts.description = desc
      return hl.bind(keys, action, opts)
    end
    local function run(cmd) return hl.dsp.exec_cmd(cmd) end

    -- Launch ----------------------------------------------------------------
    bind(mod .. " + Return",        "Terminal",            run("kitty"))
    bind(mod .. " + Space",         "Launcher",            run("rofi -show drun"))
    bind(mod .. " + E",             "Files",               run("nautilus"))
    bind(mod .. " + B",             "Browser",             run("firefox"))
    bind(mod .. " + SHIFT + Escape", "System monitor",      run("kitty --class tui-float --title btop -e btop"))
    bind(mod .. " + slash",         "Show keybinds",       run("keybinds"))

    -- Windows ---------------------------------------------------------------
    bind(mod .. " + Q",             "Close window",        hl.dsp.window.close())
    bind(mod .. " + F",             "Fullscreen",          hl.dsp.window.fullscreen({ mode = "fullscreen" }))
    bind(mod .. " + SHIFT + F",     "Maximize",            hl.dsp.window.fullscreen({ mode = "maximized" }))
    bind(mod .. " + V",             "Toggle floating",     hl.dsp.window.float({ action = "toggle" }))
    bind(mod .. " + backslash",     "Toggle split",        hl.dsp.layout("togglesplit"))

    local dirs = {
      { key = "left",  vim = "H", dir = "left" },
      { key = "down",  vim = "J", dir = "down" },
      { key = "up",    vim = "K", dir = "up" },
      { key = "right", vim = "L", dir = "right" },
    }
    local resize = {
      left  = { x = -40, y = 0 },
      right = { x = 40,  y = 0 },
      up    = { x = 0,   y = -40 },
      down  = { x = 0,   y = 40 },
    }
    for i, d in ipairs(dirs) do
      for j, k in ipairs({ d.key, d.vim }) do
        -- One described bind stands for the whole group in the cheat sheet.
        local doc = (i == 1 and j == 1)
          and { description = "Focus: arrows / H J K L  (+Shift move, +Ctrl resize)" }
          or nil
        hl.bind(mod .. " + " .. k, hl.dsp.focus({ direction = d.dir }), doc)
        hl.bind(mod .. " + SHIFT + " .. k, hl.dsp.window.move({ direction = d.dir }))
        hl.bind(mod .. " + CTRL + " .. k,
          hl.dsp.window.resize({ x = resize[d.dir].x, y = resize[d.dir].y, relative = true }),
          { repeating = true })
      end
    end

    -- Mouse: drag to move, right-drag to resize.
    hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),
      { mouse = true, description = "Drag to move window, right-drag to resize" })
    hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

    -- Workspaces ------------------------------------------------------------
    for i = 1, 10 do
      local key = i % 10 -- workspace 10 lives on 0
      local doc = (i == 1) and { description = "Workspace 1-10  (+Shift move window there)" } or nil
      hl.bind(mod .. " + " .. key,         hl.dsp.focus({ workspace = i }), doc)
      hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
    end
    bind(mod .. " + Tab",           "Previous workspace",  hl.dsp.focus({ workspace = "previous" }))
    bind(mod .. " + bracketleft",   "Workspace left",      hl.dsp.focus({ workspace = "e-1" }))
    bind(mod .. " + bracketright",  "Workspace right",     hl.dsp.focus({ workspace = "e+1" }))
    hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
    hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

    bind(mod .. " + grave",         "Scratchpad",          hl.dsp.workspace.toggle_special("scratch"))
    bind(mod .. " + SHIFT + grave", "Send to scratchpad",  hl.dsp.window.move({ workspace = "special:scratch" }))

    -- Monitors --------------------------------------------------------------
    bind(mod .. " + comma",         "Focus previous monitor", hl.dsp.focus({ monitor = "-1" }))
    bind(mod .. " + period",        "Focus next monitor",     hl.dsp.focus({ monitor = "+1" }))
    bind(mod .. " + SHIFT + comma", "Window to previous monitor", hl.dsp.window.move({ monitor = "-1" }))
    bind(mod .. " + SHIFT + period", "Window to next monitor",    hl.dsp.window.move({ monitor = "+1" }))

    -- Desktop shell ---------------------------------------------------------
    bind(mod .. " + C",             "Clipboard history",   run("clipboard-menu"))
    bind(mod .. " + N",             "Notification center", run("swaync-client -t -sw"))
    bind(mod .. " + SHIFT + N",     "Do not disturb",      run("swaync-client -d -sw"))
    bind(mod .. " + W",             "Wallpaper picker",    run("wallpaper pick"))
    bind(mod .. " + SHIFT + W",     "Random wallpaper",    run("wallpaper random"))
    bind(mod .. " + SHIFT + B",     "Night light",         run("nightlight"))
    bind(mod .. " + L",             "Lock",                run("loginctl lock-session"))
    bind(mod .. " + SHIFT + E",     "Power menu",          run("power-menu"))

    -- Screenshots -----------------------------------------------------------
    bind("Print",                   "Screenshot region",   run("screenshot region"))
    bind("SHIFT + Print",           "Screenshot window",   run("screenshot window"))
    bind("CTRL + Print",            "Screenshot screen",   run("screenshot output"))
    bind(mod .. " + SHIFT + S",     "Screenshot region and annotate", run("screenshot edit"))

    -- Hardware keys (work on the lock screen too) ---------------------------
    local locked_repeat = { locked = true, repeating = true }
    hl.bind("XF86AudioRaiseVolume",  run("swayosd-client --output-volume raise"),      locked_repeat)
    hl.bind("XF86AudioLowerVolume",  run("swayosd-client --output-volume lower"),      locked_repeat)
    hl.bind("XF86AudioMute",         run("swayosd-client --output-volume mute-toggle"), { locked = true })
    hl.bind("XF86AudioMicMute",      run("swayosd-client --input-volume mute-toggle"),  { locked = true })
    hl.bind("XF86MonBrightnessUp",   run("swayosd-client --brightness raise"),         locked_repeat)
    hl.bind("XF86MonBrightnessDown", run("swayosd-client --brightness lower"),         locked_repeat)
    hl.bind("XF86AudioPlay",         run("playerctl play-pause"), { locked = true })
    hl.bind("XF86AudioPause",        run("playerctl play-pause"), { locked = true })
    hl.bind("XF86AudioNext",         run("playerctl next"),       { locked = true })
    hl.bind("XF86AudioPrev",         run("playerctl previous"),   { locked = true })
  '';
}
