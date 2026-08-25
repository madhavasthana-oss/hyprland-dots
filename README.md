# hyprland-dots

Minimal, utility-first Hyprland rice built around **astral-vagabond** (Quickshell) and the **Ash** monochrome palette.

Soft charcoal surfaces, silver accents, low-glare text. Functional over flashy.

---

## What’s in here

| Path | Role |
|------|------|
| [`.config/quickshell/astral-vagabond/`](./.config/quickshell/astral-vagabond/) | Bar, center console, system panels |
| [`.config/hypr/`](./.config/hypr/) | Hyprland (Lua), hyprlock, hypridle |
| [`.config/mako/`](./.config/mako/) | Legacy notification template (unused; toasts are Quickshell) |
| [`.config/fuzzel/`](./.config/fuzzel/) | Emoji / clipboard dmenu only |
| [`.config/kitty/`](./.config/kitty/) · [ghostty/](./.config/ghostty/) · [wezterm/](./.config/wezterm/) | Terminals (Ash) |
| [`.config/fish/`](./.config/fish/) · [nvim/](./.config/nvim/) · [oh-my-posh/](./.config/oh-my-posh/) | Shell + editor |
| [`install`](./install) | Package + config installer (Arch / CachyOS) |
| [`requirements.txt`](./requirements.txt) | pacman / AUR package list |
| [`CHANGELOG.md`](./CHANGELOG.md) | History of meaningful changes |

---

## Design

**Ash palette (shell chrome)**

| Role | Hex |
|------|-----|
| Background | `#121212` · `#1A1A1A` · `#242424` |
| Accent | `#C8C8C8` |
| Text | `#E5E5E5` · `#A3A3A3` · `#6B6B6B` |
| Border idle | `#333333` |

**Principles**

- No pure black / pure white (easier on the eyes)
- Hierarchy via luminance, not neon hues
- Utility labels over lore
- One palette across Hypr, astral-vagabond, terminals, nvim

**Wallust (optional)**  
Tints astral-vagabond **text + icon accents** and Hyprland **active window borders** from the wallpaper. Surfaces stay Ash. Activate from settings, `SUPER+W`, or:

```bash
~/.config/quickshell/astral-vagabond/utils/scripts/load-wallust-colors.sh --from-awww
# restore Ash (astral-vagabond + hypr): SUPER+SHIFT+W, or:
~/.config/quickshell/astral-vagabond/utils/scripts/load-legacy-colors.sh --activate
```

---

## Astral-Vagabond

Quickshell config name: `astral-vagabond` (`quickshell -c astral-vagabond`).

| Area | Contents |
|------|----------|
| Top bars | Workspaces · status / date · BAT · VOL · CPU · GPU · RAM |
| Center dropdown | **Dashboard** · **Console** · **Media** |
| Console | Left: app launcher · Right: Wi‑Fi, Bluetooth, settings, notifications (`widgets/…/console/`) |
| Settings tiles | Capture / record · **Caffeine** (`hyprcaffeine`) · **Autolock** (`hypridle` toggle) · wallust / Ash |
| Right bar click | CPU / GPU / RAM system panels |
| Bottom / power | Power actions strip |

---

## Install

**Target:** Arch Linux / CachyOS (`pacman`). Needs `rsync`; AUR helper (`paru` / `yay`) for AUR lines in `requirements.txt`.

```bash
git clone https://github.com/YOUR_USER/hyprland-dots.git
cd hyprland-dots
chmod +x install
./install              # packages + configs + SDDM
./install --core       # skip OPTIONAL packages
./install --configs    # configs only
./install --dry-run    # preview
```

Configs rsync into `~/.config` with `--delete` for listed trees — back up first if you care about live-only files.

Log out / reboot for SDDM and a clean Hypr session. Shell:

```bash
quickshell -c astral-vagabond
```

(Already started on login if hypr `execs.lua` is applied.)

---

## Useful paths

```text
.config/quickshell/astral-vagabond/Theme.qml          # color roles (live JSON overlay)
.config/quickshell/astral-vagabond/colors/            # active / legacy / wallust
.config/hypr/hyprland/colors.lua                # window borders
.config/kitty/theme.conf · ghostty/theme.conf   # terminals
.config/quickshell/astral-vagabond/NotifServer.qml  # notification daemon + toasts
scripts/bash/                                   # helpers (wallpaper, etc.)
```

---

## Notes

- Work only from this repo until you run `./install` or sync deliberately.
- Legacy script names under `scripts/bash/` may still mention older themes; the live stack is **astral-vagabond + Ash**.
- Changelog: [CHANGELOG.md](./CHANGELOG.md)

---

*Comforting dark. Useful by default.*
