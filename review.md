# NixOS Config Review
_Reviewed: April 22, 2026_

---

## Overall Impression

The architecture is fundamentally sound and above average for a vibe-coded config. The directory split (`modules/nixos/` vs `modules/home-manager/`), the host-as-wiring pattern, and the use of sops-nix are all correct community practices. The `goals.md` suggests you already understand where technical debt has accumulated. But there are real issues across several categories, documented below.

---

## Table of Contents

1. [Architecture & Organization](#architecture--organization)
2. [Security Issues](#security-issues)
3. [Duplication & Minor Issues](#duplication--minor-issues)
4. [Summary Table](#summary-table)
5. [Closing Assessment](#closing-assessment)

---

## Architecture & Organization

### ✅ What's Working Well

- **Host files are thin "wiring" files.** Hosts list imports and set host-specific overrides (hostname, kernel params, DPI). They don't repeat logic. This is the right pattern.
- **Module placement is logical.** `modules/nixos/` for system config, `modules/home-manager/` for user config, `pkgs/` for custom derivations. No major boundary violations.
- **sops-nix** is correctly wired with age keys, the secrets file is encrypted, and secrets are injected via `EnvironmentFile` in service configs.
- **Hardware in dedicated modules.** `nvidia-desktop.nix`, `nvidia-laptop.nix`, etc. are cleanly isolated. The PRIME offload setup on the laptop is correctly configured.
- **Media group permissions model** (shared `media` group, `UMask = "0002"`, `systemd.tmpfiles` for `/var/lib/media`) is a solid pattern for a media server.

---

### ❌ Architecture Issues

#### Two conflicting module patterns are mixed throughout

The service modules use two different patterns with no consistency:

- **Pattern A – Simple** (just enables the service): `radarr.nix`, `sonarr.nix`, `jellyfin.nix`, `navidrome.nix`, `immich.nix`, etc.
- **Pattern B – Custom `mkOption` wrapper**: defines a `services.xxx-custom` namespace with `enable`, `port`, etc. — used in `cockpit.nix`, `mealie.nix`, `netdata.nix`, `uptime-kuma.nix`, `qbittorrent.nix`, `homepage.nix`

The custom wrapper pattern delivers zero value here. Every single wrapper sets `default = true; # enable on import` on its `enable` option. If it's always `true` when imported, the option is pointless — you're carrying extra boilerplate (`options`, `config = mkIf cfg.enable { ... }`) for no benefit. This is a pattern AI generates when asked to "make it configurable." It is only warranted if you import the module in a host that should sometimes have the service disabled — which you never do.

**Fix:** Collapse all Pattern B modules into the simple Pattern A.

---

#### `modules/nixos/core.nix` contains server-specific logic

The sudo `NOPASSWD` rules in `core.nix` include:

```nix
command = "...journalctl -u minecraft-server-main -f --no-hostname -o cat";
```

This Minecraft-specific sudo rule is applied to the desktop, laptop, and WSL — machines with no Minecraft server. Sudo rules for a specific service should live next to that service in `minecraft.nix`, not in the shared base.

Similarly, `max-jobs = 12; cores = 4;` are clearly lifted from the desktop build machine and applied to every host, including WSL and the server which may have a very different core count.

---

#### WSL imports Immich

`hosts/wsl/configuration.nix` imports `../../modules/nixos/services/immich.nix`. Immich is a photo server. WSL is described as "no GUI, minimal config." This is an accidental leftover from copy-paste.

---

#### Tailscale routing config lives in `ssh.nix`

In `modules/nixos/services/ssh.nix`:

```nix
services.tailscale.useRoutingFeatures = "both";
```

Tailscale configuration belongs in `tailscale.nix`. Having a Tailscale router setting hidden inside the SSH module is unexpected and will confuse anyone reading the code later.

---

#### The fish `mc` Minecraft function is global

`modules/home-manager/programs/fish.nix` defines an `mc` function (Minecraft RCON/console helper) that is part of `core.nix`'s imports, meaning it lands on the desktop and laptop shells too. Server-specific shell helpers should be in the server's `hosts/server/leyton.nix` or included conditionally. Right now your desktop has Minecraft management commands.

---

#### `starship.nix` is an orphaned dead file

`modules/home-manager/programs/starship.nix` exists and references `../dotfiles/starship.toml` — **which does not exist** in the repository. Additionally, `starship.nix` is never imported by any module (`core.nix`, `desktop.nix`, or any host file). It is dead code pointing to a missing file.

Meanwhile, `fish.nix` manually calls `starship init fish | source` in `shellInit`. If `starship.nix` is ever imported with `enableFishIntegration = true`, the init will run twice.

**Fix:** Either delete `starship.nix` and keep the manual init in `fish.nix`, or create `starship.toml`, import `starship.nix` into `core.nix`, and remove the manual `shellInit` line.

---

## Security Issues

### 🔴 High: `sandbox = "relaxed"` in flake `nixConfig`

```nix
nixConfig = {
  sandbox = "relaxed";
};
```

This globally relaxes the Nix sandbox for every build on every machine that evaluates this flake. It was presumably added to support `pkgs/hydra-server/default.nix` which uses `__noChroot = true` to fetch npm packages at build time. But `__noChroot = true` on the derivation already handles that specific package — the global `sandbox = "relaxed"` is redundant for that purpose but weakens security for everything else. Any package built by any user of this flake now has the potential to make outbound network calls during builds.

**Fix:** Remove `sandbox = "relaxed"` from the flake-level `nixConfig`.

---

### 🔴 High: RCON password in plain text in the Nix store

In `modules/nixos/services/minecraft.nix`:

```nix
"rcon.password" = "minecraft";
```

Plain-text credentials written into a NixOS config land in the Nix store at a world-readable path (`/nix/store/...`). "minecraft" is also trivially guessable. Even though RCON is currently localhost-only, this is poor practice and will persist across generations.

**Fix:** Manage the RCON password via sops and inject it via a startup script or `EnvironmentFile`.

---

### 🔴 High: qBittorrent web UI has all authentication disabled

In `modules/nixos/services/qbittorrent.nix`, the generated config file contains:

```ini
WebUI\LocalHostAuth=false
WebUI\AuthSubnetWhitelistEnabled=true
WebUI\AuthSubnetWhitelist=0.0.0.0/0, ::/0
WebUI\CSRFProtection=false
WebUI\ClickjackingProtection=false
WebUI\HostHeaderValidation=false
```

This removes all web UI authentication entirely — any request from any IP is accepted with no credentials required. Combined with CSRF and host header validation being disabled, this would be trivially exploitable if Caddy ever misconfigures a route or a co-located service is compromised.

**Fix:** Enable authentication and let qBittorrent manage its own credentials. At minimum, restore CSRF protection and host header validation.

---

### 🟡 Medium: `LD_LIBRARY_PATH = lib.mkForce ""`

In `modules/nixos/services/gnome.nix`:

```nix
environment.sessionVariables = {
  LD_LIBRARY_PATH = lib.mkForce "";
};
```

Using `mkForce` to blank `LD_LIBRARY_PATH` will prevent any legitimate downstream overrides and can silently break third-party applications — AppImages, Steam runtime, some VS Code extensions, and proprietary apps that legitimately set this variable. NixOS packages have correct RPATHs, but forcing the variable empty with `mkForce` for all sessions is too aggressive.

**Fix:** Drop the `mkForce` or remove this line entirely.

---

## Duplication & Minor Issues

### `nixpkgs.config.allowUnfree` is set inconsistently

- Desktop: `hosts/desktop/configuration.nix`
- Laptop: `hosts/laptop/configuration.nix`
- Server: `hosts/server/configuration.nix`
- WSL: **not set at all**
- `nvidia.acceptLicense = true`: set in both the host config **and** the nvidia hardware module (defined twice on desktop and laptop)

**Fix:** Set `allowUnfree = true` once in `modules/nixos/core.nix`. Let each nvidia module own its own `nvidia.acceptLicense`.

---

### Duplicate `gnome-tweaks` package

`gnome-tweaks` appears in both:
- `modules/nixos/services/gnome.nix` → `environment.systemPackages`
- `modules/home-manager/theming.nix` → `home.packages`

It's installed twice. Remove it from one location (prefer the system package).

---

### Caddy TLS blocks are fully redundant

The `globalConfig` in `modules/nixos/services/caddy.nix` already sets:

```caddyfile
acme_dns cloudflare {env.CLOUDFLARE_API_TOKEN}
```

But then every single virtual host (15+) also repeats:

```caddyfile
tls {
  dns cloudflare {env.CLOUDFLARE_API_TOKEN}
}
```

The per-site TLS blocks are redundant with the global. This is ~60 lines of repetitive config that can be removed entirely.

---

### Trusted Tailscale interface makes the SSH port rule redundant

In `tailscale.nix`:

```nix
networking.firewall.trustedInterfaces = [ "tailscale0" ];
```

When an interface is trusted, **all** ports are already open through it. The rule in `ssh.nix`:

```nix
networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 22 ];
```

...is a no-op. Not harmful, just dead config.

---

### `catppuccin` flake input missing `inputs.nixpkgs.follows`

```nix
catppuccin = {
  url = "github:catppuccin/nix";
  # missing: inputs.nixpkgs.follows = "nixpkgs";
};
```

Every other input pins its nixpkgs version to follow the root. Catppuccin will download and use its own separate nixpkgs copy, increasing lock file complexity and potentially using a different nixpkgs version.

---

### `catppuccin.rofi.enable = true` but rofi is not installed

`theming.nix` enables Catppuccin's rofi theme but rofi is not in any package list. Dead config that generates a theme for software that isn't present.

---

### `consoleLogLevel` conflicts with `loglevel` kernel param on laptop

`modules/nixos/core.nix` sets:
```nix
boot.consoleLogLevel = 4;
```

`modules/nixos/hardware/nvidia-laptop.nix` sets (via kernelParams):
```
"loglevel=3"
```

Both control the kernel console log level through different mechanisms. On the laptop, both are active and the kernel param wins at boot time. The `consoleLogLevel` option is redundant/overridden on the laptop.

---

### `homepage.nix` uses `pkgs.writeText` as an `environmentFile`

```nix
environmentFile = "${pkgs.writeText "homepage-env" ''
  HOMEPAGE_ALLOWED_HOSTS=lhsv.net
''}";
```

Writing an environment file to the Nix store is unusual. For non-sensitive values like this it works, but the Nix store is world-readable, making this pattern dangerous if ever adapted for secrets. The conventional approach is `environment = { HOMEPAGE_ALLOWED_HOSTS = "lhsv.net"; }` directly in the service config.

---

## Summary Table

| Severity | Location | Issue |
|---|---|---|
| 🔴 High | `flake.nix` | `sandbox = "relaxed"` weakens builds globally |
| 🔴 High | `services/minecraft.nix` | RCON password in plain text in Nix store |
| 🔴 High | `services/qbittorrent.nix` | Web UI auth, CSRF, and host-header validation all disabled |
| 🟡 Medium | `services/gnome.nix` | `LD_LIBRARY_PATH = mkForce ""` can break third-party apps |
| 🟡 Medium | `nixos/core.nix` | Minecraft sudo rule applied to all hosts |
| 🟡 Medium | `hosts/wsl/configuration.nix` | Imports Immich (server service on a minimal WSL) |
| 🟡 Medium | `home-manager/programs/starship.nix` | Orphaned file, references missing `starship.toml` |
| 🟡 Medium | `services/ssh.nix` | Tailscale routing config lives in the wrong module |
| 🟡 Medium | `home-manager/programs/fish.nix` | Minecraft shell function is global (desktop/laptop get it) |
| 🟢 Low | `services/*.nix` (6 files) | `mkOption` wrappers always `default = true` — pointless boilerplate |
| 🟢 Low | host configs + nvidia modules | `nvidia.acceptLicense` duplicated |
| 🟢 Low | host configs | `allowUnfree` set inconsistently across hosts, missing on WSL |
| 🟢 Low | `services/caddy.nix` | TLS blocks repeated 15+ times; redundant with `globalConfig` |
| 🟢 Low | `services/ssh.nix` + `tailscale.nix` | SSH port rule on trusted interface is a no-op |
| 🟢 Low | `flake.nix` | `catppuccin` input missing `inputs.nixpkgs.follows` |
| 🟢 Low | `home-manager/theming.nix` | `catppuccin.rofi.enable = true` but rofi not installed |
| 🟢 Low | `services/gnome.nix` + `theming.nix` | Duplicate `gnome-tweaks` in system and home packages |
| 🟢 Low | `nixos/core.nix` + `nvidia-laptop.nix` | Conflicting `consoleLogLevel` / `loglevel` kernel param |
| 🟢 Low | `nixos/core.nix` | `max-jobs = 12; cores = 4` desktop values applied to all hosts |
| 🟢 Low | `services/homepage.nix` | `pkgs.writeText` env file pattern is unconventional |

---

## Closing Assessment

The foundation is real and usable as a daily driver. The biggest things to address before fully trusting it are the three **High** security items. After those, the main cleanup goal should be:

1. **Clean up `core.nix`** — it is absorbing things that belong in their respective modules (Minecraft sudo rule, desktop-tuned build settings).
2. **Remove the orphaned `starship.nix`** and decide on a single starship integration approach.
3. **Eliminate the `mkOption` wrappers** — the six Pattern B modules should be collapsed to simple Pattern A.
4. **Consolidate the Caddy config** — remove the repeated per-site TLS blocks.
5. **Move server-specific shell config** (the `mc` fish function) to the server's home-manager file.

Your `goals.md` item about removing AI artifacts is well-targeted. The custom wrapper modules, the Caddy TLS repetition, and the Minecraft sudo rule in `core.nix` are the clearest examples of vibe-coded patterns that got implemented despite being wrong.
