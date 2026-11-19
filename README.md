# Arch Linux · Hyprland Desktop Engineering

A modular Wayland desktop configuration combining a Quickshell interface with Linux automation, process monitoring, network diagnostics, and a reversible desktop Game Mode. The project demonstrates QML interface design, Python systems tooling, Bash automation, and integration with Hyprland, PipeWire, systemd, and Linux process APIs.

This is a configurable desktop project, not a distribution or an unattended installer. Review the monitor layout and optional applications before using it. See [the release audit](AUDIT_REPORT.md) for verified checks and known limitations, and [third-party notices](THIRD_PARTY.md) for verified sources, license terms and exclusions. Bundled themes/lock configuration use their upstream GPL v3 terms; Hyprland example portions use BSD 3-Clause; icons use MIT. Complete upstream notices are in `LICENSES/`. No project-wide license has been selected for unrelated material.

## Credits & Acknowledgments

This desktop combines project-specific integration with established Linux desktop tools. Upstream work is credited separately from local adaptations and preparation additions; no claim of sole authorship is made for the complete repository.

| Included upstream material | Credit and local use |
| --- | --- |
| [Hyprland example configuration](https://github.com/hyprwm/Hyprland/blob/11cbc6c577b84ffb1edf4df3fc5b6128c3ae6947/example/hyprland.lua) | vaxerski and the Hyprland project: BSD 3-Clause configuration portions adapted for this desktop's monitor layout, startup, rules and bindings. |
| [JaKooLit / Hyprland-Dots](https://github.com/JaKooLit/Hyprland-Dots/blob/c093e836764d62346390ba307c9163ca11d0229b/config/hypr/hyprlock-1080p.conf) | Credits SherLock707 for the original lock configuration. The included GPL v3 adaptation uses standalone colors, screenshot blur and compact date/time fields. |
| [Squared Nord by Newman Sanchez / newmanls](https://github.com/newmanls/rofi-themes-collection/blob/911cc27afe9c66d7e2cb06a47c905d046ea3dfd2/themes/squared-nord.rasi) | GPL v3 Rofi theme, included as an alternate and adapted into the active monochrome/translucent variant. |
| [Phosphor Icons](https://github.com/phosphor-icons/core/tree/2b75f3ad12b420c9504ef05df8d2564a28f8500e/assets/regular) | Fourteen MIT-licensed regular SVG icons, with local white styling. Full copyright and permission notice is retained. |

The runtime builds on [Quickshell](https://quickshell.org/), [Qt](https://www.qt.io/), [Hyprland](https://hypr.land/), [PipeWire](https://pipewire.org/) and [Cava](https://github.com/karlstav/cava), alongside the Linux utilities listed below. These are external dependencies; their binaries, libraries and fonts are not bundled, and acknowledgment implies no endorsement.

**Preparation additions written for this release** include the Cava configuration text, offline source validator, safety-test fixtures, documentation and release inventory. **Pre-existing project implementation** includes the QML interfaces, Python workers and desktop helpers; the supplied export does not establish their complete authorship history. They are not represented as verified original work merely because no attribution header was found. **Adapted and redistributed upstream material** is listed in the table above, with complete notices under `LICENSES/`. See [THIRD_PARTY.md](THIRD_PARTY.md) and the [per-file source audit](docs/SOURCE_AUDIT.md) for license scope, source verification and exclusions.

## Architecture

| Directory | Responsibility |
| --- | --- |
| `hypr/` | Lua compositor configuration, window rules, bindings, idle and lock settings, static wallpaper configuration |
| `quickshell/` | Per-output bar, dock, notifications, MPRIS media controls, PipeWire audio, tray, calendar, desktop spectrum |
| `quickshell-control/` | Control center, system/network/process pages, tasks, activity summaries, power and Game Mode controls |
| `quickshell-control/scripts/` | Python telemetry, bounded network diagnostics, process actions and shared worker lifecycle |
| `quickshell-caffeine/` | Independent Wayland idle-inhibition service with an IPC interface |
| `quickshell-activity/` | Independent active-application usage tracker with local daily totals |
| `scripts/` | Launch/toggle helpers, screenshots, recorder IPC, Game Mode, offline source validator |
| `cava/`, `rofi/`, `kitty/` | Spectrum producer settings, launcher/power menu, terminal appearance |
| `tests/` | Offline safety and rollback checks using fixtures and simulated desktop operations |

The bar and control center are separate Quickshell processes. Dedicated background processes keep caffeine and activity state independent of the control center window. The top-bar pulse opens the monitor page through IPC; the clock opens the calendar. Python workers emit structured JSON consumed by QML. Workers bound subprocess timeouts, avoid shell interpolation for network targets, and arrange termination when their parent exits.

## Features

- Multi-output bar with workspaces, system tray, notification history and do-not-disturb state, media transport, volume and calendar.
- Control center with audio device selection, volume/mute, Wi-Fi and Bluetooth radio controls, task management, activity summaries and session actions.
- System monitoring with CPU/memory/disk metrics, CPU temperature and optional NVIDIA telemetry, history charts and sortable process rows.
- Network interface throughput, socket/listener inspection, DNS lookup, bounded route tracing, optional health probes and an explicit public-IP request.
- Process termination requests use SIGTERM and check the displayed process start identity using Linux pidfds.
- Caffeine uses native Wayland idle inhibition. It does not stop or rewrite the idle daemon.
- Screenshot-to-file and clipboard automation, recorder IPC helpers, and a 96-band Cava spectrum.
- Game Mode captures current effects settings and visualizer state, pauses recognized animated wallpaper processes, and journals changes for restoration. It verifies an existing 180-second replay recorder before changing the desktop. It does not start, stop, or reconfigure the recorder.

## Requirements

The compositor configuration uses the **Lua `hl` API**, not legacy Hyprlang. The source was checked with Hyprland 0.57.2 and Qt tooling 6.12.0 and Quickshell 0.3.2 on the audit host. These are validation-host versions, not an established minimum-version compatibility matrix. Quickshell must provide the imported Hyprland, Wayland, PipeWire, MPRIS, notifications, tray, networking and Bluetooth modules. Older builds may lack the networking APIs. Python workers use the standard library; Python 3.9 or newer is required by source features, with Linux pidfd support needed for process actions and Game Mode.

| Feature | Required programs/services |
| --- | --- |
| Desktop and interface | Hyprland/`hyprctl`, Quickshell/`qs`, Qt 6 Quick/Controls/Layouts, a session D-Bus, systemd user services |
| Audio and spectrum | PipeWire, WirePlumber/`wpctl`, PulseAudio compatibility (`pipewire-pulse`), Cava |
| Idle/lock/wallpaper | `hypridle`, `hyprlock`, `hyprpaper`; a user-supplied wallpaper |
| Network controls | A supported Quickshell network backend (e.g. NetworkManager), BlueZ for Bluetooth, applicable session authorization |
| Diagnostics | `ip`, `ss` (iproute2), `dig` (Arch `bind`), `ping`/`tracepath` (iputils), optional `traceroute` |
| Process/system workers | Python 3, `ps`, `uptime` (procps-ng), standard coreutils, Linux `/proc` and `/sys`; optional `nvidia-smi` |
| Screenshot | `grim`, `wl-copy` (wl-clipboard), `notify-send` (libnotify) |
| Terminal spectrum toggle | `kitty`, `cava`, `jq`, `hyprctl` |
| Recording and Game Mode | GPU Screen Recorder, `gsr-cli`, a separately configured `gpu-screen-recorder.service`, `flock` (util-linux), `notify-send`; optional `mpvpaper` |
| Optional application bindings/dock | Kitty, Thunar, Firefox, VS Code (`code`), Spotify, Obsidian, Flameshot, Vesktop, `rofimoji`, `playerctl`, `hyprshutdown` |
| Offline validation | Python 3, Bash, `luac`, Qt 6 `qmlformat`; `qmllint` for additional semantic analysis |

Fonts are not bundled. Active configurations reference Inter, JetBrains Mono Nerd Font, and Tintoretto; change these to installed alternatives as needed. The alternate Rofi theme uses FiraCode Nerd Font. The unused file-preview/UI library is excluded, so its QtMultimedia module and widget-specific fonts are not requirements. Cursor configuration requests `phinger-cursors-dark`.

## Setup

No installation or live-dotfile changes were performed during preparation. Back up existing configurations independently before copying anything. Start with a separate user or disposable session for visual testing.

1. Review `hypr/hyprland.lua`. Its example layout is DP-1 at 2560×1440/144 Hz and HDMI-A-1 at 1920×1080/60 Hz. Replace output names, positions, refresh rates, workspace placement, keyboard and cursor settings for your hardware.
2. Install the requirements for the features you intend to use. Verify `qs --version` and the available modules; no lockfile or fully tested package-version matrix is supplied.
3. Manually copy each configuration directory to its matching default location: `hypr`, `quickshell`, `quickshell-control`, `quickshell-caffeine`, `quickshell-activity`, `rofi`, `kitty`, and `cava` under `~/.config/`. Copy the executable desktop helpers from `scripts/` to `~/.local/bin/` and ensure that directory is on PATH. `scripts/validate` is a repository tool and should stay here.
4. Supply your own image at `~/.config/hypr/wallpaper.png`, or edit `hyprpaper.conf` to point to your chosen file. Hyprpaper uses a home-relative path; the Rofi theme uses a config-relative path. Hyprlock uses the current screen as its blurred background.
5. Initialize the local state directory with mode 700 and new state files with mode 600: `~/.local/state/quickshell-control/activity.json` containing `{"days":{}}`, and `tasks.json` containing `{"tasks":[]}`. **Create only if absent; never replace existing task or activity data.** The current UI reports a load error for missing or malformed state rather than automatically replacing it.
6. Start with the optional control center via `qs -p ~/.config/quickshell-control`. Test the bar in a disposable desktop session; it provides a notification server and can conflict with another notification daemon. The compositor startup hook launches the bar, idle daemon, wallpaper daemon and dedicated background helpers at next login.
7. Configure the recorder service separately before trying Game Mode or recording shortcuts. No recorder service file, capture target, media or private systemd configuration is bundled.

Most components intentionally use default `~/.config`, `~/.local/bin` and `~/.local/state` locations. Custom XDG locations are not comprehensively supported. `VISUALIZER_OUTPUT` selects a spectrum output (otherwise the first output); `SCREENSHOT_OUTPUT` selects a screenshot output (otherwise all outputs). Set those variables in your session before launching their consumers.

## Main controls

| Control | Action |
| --- | --- |
| Super+Shift+D | Toggle control center |
| Super+K / bar pulse | Open system monitor |
| Super+D | Toggle bundled dock |
| Super+Alt+V | Toggle desktop visualizer |
| Super+Home | Screenshot and clipboard |
| Super+Alt+C | Toggle Kitty terminal spectrum |
| Super+R / Super+P | Rofi launcher / power menu |
| Super+Alt+G | Ask the external recorder service to save replay (SIGUSR1) |
| Super+Shift+G | Toggle external recorder replay recording through its IPC socket |

Run `game-mode status`, `game-mode doctor`, `game-mode enable`, or `game-mode disable` from a Hyprland terminal after installation. `enable` requires exactly one recognized main bar process, the live Lua configuration API and a verified recorder. `disable` restores captured state; preserve its runtime journal if restoration fails. Status/doctor output can contain usernames, executable paths, process arguments and service logs; do not publish it without review. Game Mode changes session effects; it is not Feral GameMode and makes no benchmark or FPS claim.

## Data and network behavior

Activity tracking records application classes and time totals locally, excluding idle periods; it retains today and the previous 29 calendar days. Tasks contain user-entered text and scheduling data. Neither dataset belongs in this repository. Create state before starting the tracker and stop its dedicated process if you do not want collection.

Socket inspection displays process/network information. While the socket diagnostics worker runs, it may issue bounded reverse DNS lookups for globally routable peers. Health probes are off by default; enabling them pings the gateway and `1.1.1.1` and resolves `example.com`. The public-IP button contacts `https://api.ipify.org`; DNS/trace tools send traffic to the selected destination. These features are not all offline, and displayed results can reveal hostnames, addresses and application names. Review any future screenshots before committing them.

## Validation and limitations

From this folder, run:

```sh
python3 -B scripts/validate
python3 -B tests/test_safety.py
```

The validator parses source without launching the desktop. Tests use temporary fixtures inside `work/` and simulate desktop changes. They do not establish hardware or live-session correctness. Additional local checks completed for Hyprland config parsing and Rofi theme loading; see [AUDIT_REPORT.md](AUDIT_REPORT.md).

Known limits include hardware-specific monitor rules, incomplete custom-XDG support, unverified visual layout and live IPC, optional NVIDIA-only GPU metrics, system authorization differences, and remaining QML semantic warnings. The calendar now receives its anchor window through an unambiguous `barPanel` ID; its live positioning still requires visual verification. The workspace overview and wallpaper picker are optional external components and their missing launch commands are disabled. The animated-wallpaper launcher is not bundled; static Hyprpaper is the default. Game Mode can pause existing compatible `mpvpaper` processes described by runtime PID files, but none are started here.

The alternate GPL-covered Rofi theme is retained. The unused Bash sampler and generated color palette are excluded because their provenance is unresolved; the active Python metrics worker remains included. The unused `quickshell-control/ui/` library is excluded after confirming no active component imports it. The uncertain inherited Hyprlock variant is also excluded; a smaller configuration adapted from a pinned, verified GPL upstream source preserves password locking, screenshot blur and date/time display. No screenshots or media have been invented.

## Public source boundary

The intended public files are listed in `docs/FILE_INVENTORY.sha256` (plus that manifest itself). A local, unpublished source archive is prepared at `work/releases/arch-hyprland-config-public-source.tar.gz` using exactly that allowlist, with ownership metadata removed. This archive includes license texts and attribution, and excludes all of `work/`, the unused UI library, the inherited lock variant, unverified unused sampler/palette, tool/account metadata, runtime state and Git metadata. A checksum is beside the archive. Rebuild the inventory/archive after any further source changes; the archive is a snapshot, not a publishing action.

The ignored `work/excluded/` directory preserves excluded material for reversibility, and `work/provenance/` holds downloaded public verification snapshots. **Do not upload the entire working folder or force-add these directories.** The validator rejects a reintroduced UI directory or QML references to its types/paths. Exclusion does not establish permission to redistribute those original copies.

The verified Rofi and replacement Hyprlock configuration sources are GPL v3; the 14 icons are MIT with their full upstream notice retained. See [THIRD_PARTY.md](THIRD_PARTY.md) and [icon verification](docs/ICON_PROVENANCE.md). No blanket license or ownership claim was invented. Live desktop acceptance and the owner's decision about licensing unrelated original material remain outstanding.


## Isolated Quickshell smoke test

Use the [short smoke-test checklist](docs/QUICKSHELL_SMOKE_TEST.md) in a disposable VM or separate desktop account/session. Changing HOME alone does not isolate the compositor, audio, system services or session D-Bus. This checklist is provided for acceptance testing; it has not been executed as part of preparation.
