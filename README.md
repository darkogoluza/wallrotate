# wallrotate

A daily wallpaper rotator for Hyprland. Images and live (video) wallpapers, one per day,
every wallpaper getting an equal turn, with time-of-day groups like macOS dynamic wallpapers.

- **One wallpaper per day**, changing at midnight. Powered off for a few days? That counts as
  one change, not several.
- **Equal turns (shuffle bag):** every wallpaper is shown once, in random order, before any
  repeats. History survives reboots.
- **Groups:** a set of images (dawn, day, dusk, night) that switch at the times you choose.
  A group counts as one wallpaper.
- **Smooth fades:** image changes are pre-rendered as a short video mixed in linear light,
  so the middle of a fade looks like real light instead of a muddy grey mix.
- **Videos** play with `mpvpaper`, images show with `awww`.
- **DankMaterialShell:** if installed, its lock screen shows the current wallpaper too.

## Requirements

Hyprland (any wlroots compositor should work for the wallpaper part) and:

| Tool | For | Arch |
|---|---|---|
| python3 | the program | `python` |
| awww | images and transitions | `awww` |
| mpvpaper | video wallpapers and smooth fades | `mpvpaper` (AUR) |
| ffmpeg | rendering smooth fades | `ffmpeg` |

The installer installs missing ones for you. On Arch that's `pacman` for `awww`/`ffmpeg` and
`paru`/`yay` for `mpvpaper`. Elsewhere `awww` and `mpvpaper` are often not packaged: build them
from [awww](https://codeberg.org/LGFae/awww) and [mpvpaper](https://github.com/GhostNaN/mpvpaper).

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/darkogoluza/wallrotate/main/install.sh | bash
```

It detects your distro (Arch, Debian/Ubuntu, Fedora, openSUSE and their derivatives), asks
before installing missing dependencies with `sudo`, and puts `wallrotate` in `~/.local/bin`.
Nothing else is touched. To skip the question, add `-s -- --yes`:

```bash
curl -fsSL https://raw.githubusercontent.com/darkogoluza/wallrotate/main/install.sh | bash -s -- --yes
```

Run it again to update, then restart a running `wallrotate`.

To start it with Hyprland, add to `hyprland.conf`:

```
exec-once = ~/.local/bin/wallrotate
```

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/darkogoluza/wallrotate/main/uninstall.sh | bash
```

Stops it and removes the program, its rotation history and cache. Your config is kept.

Not removed automatically:

- **The current wallpaper stays on screen**, because `awww`/`mpvpaper` keep showing the last
  one. Clear it with `awww kill; pkill -x mpvpaper`, or let your next wallpaper tool replace it.
- **Dependencies** (`awww`, `mpvpaper`, `ffmpeg`), since other programs may use them. If
  unused, remove them with your package manager, e.g. `sudo pacman -Rns awww mpvpaper ffmpeg`.
- **Your autostart line** and `~/.config/wallrotate`, if you don't want them anymore.

## Configure

Create `~/.config/wallrotate/config.json`. Changes apply within a minute, no restart needed.

```json
{
  "dir": "~/Pictures/Wallpapers",
  "transition": "fade",
  "transition_duration": 1,
  "wallpapers": [
    { "name": "Mountain lake", "variants": [
        { "from": "06:00", "file": "lake-sunrise.jpg" },
        { "from": "10:00", "file": "lake-day.jpg" },
        { "from": "18:30", "file": "lake-sunset.jpg" },
        { "from": "21:00", "file": "lake-night.jpg" } ] },
    { "name": "City", "transition": "wipe", "variants": [
        { "from": "07:00", "file": "city-day.png" },
        { "from": "19:00", "file": "city-night.png" } ] },
    { "file": "forest.jpg" },
    { "file": "abstract-gradient.png", "transition": "grow" },
    { "file": "~/Videos/ocean-waves.mp4" },
    { "file": "~/Videos/rain-window.mp4" }
  ]
}
```

- `file` paths are relative to `dir`, or absolute (`~/...`).
- In a group, each variant shows from its `from` time until the next one. Before the first
  one (after midnight), the last variant stays on.
- Entries whose files are missing are skipped.

| Setting | Default | |
|---|---|---|
| `dir` | `~` | base folder for relative paths |
| `image_mode` | `fill` | `fill` (crop) or `fit` |
| `video_options` | `no-audio loop` | mpv options for video wallpapers |
| `transition` | `fade` | awww effect: `fade`, `wipe`, `grow`, `wave`, `outer`, `left`, ... |
| `transition_duration` | `1` | seconds |
| `transition_fps` | `60` | |
| `natural_blend` | `true` | smooth linear-light fades (needs ffmpeg + mpvpaper) |
| `sync_lock_screen` | `true` | DankMaterialShell lock screen follows the wallpaper |

`transition*` and `natural_blend` can also be set per wallpaper or per group variant.

## Commands

```bash
wallrotate status                    # today's wallpaper and round progress
wallrotate next                      # skip to another wallpaper for today
wallrotate preview "City" 3          # play a group's variants, 3 s each
wallrotate show forest.jpg 10        # try one wallpaper for 10 s
```

`preview` and `show` pause the background rotator and return to today's wallpaper afterwards.

## Files

| Path | |
|---|---|
| `~/.local/bin/wallrotate` | the program |
| `~/.config/wallrotate/config.json` | your config |
| `~/.local/state/wallrotate.json` | today's pick and the current round |
| `~/.cache/wallrotate/` | still frames of videos for the lock screen |

## License

MIT, see [LICENSE](LICENSE).
