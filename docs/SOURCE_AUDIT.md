# Source, ownership and redistribution audit

Reviewed on 2026-11-19. This inventory distinguishes what the available evidence establishes. It does not assign ownership, infer copying permission from public availability, or certify all pre-existing code as original.

## Review scope and method

All public regular files were inventoried. Source headers/comments, imported modules, file/image/script references, local paths, attributed names and license indicators were inspected. Known upstream material was checked against pinned public source; four full license texts are included. All image payloads in the public source are the 14 verified Phosphor SVGs. No fonts, binary dependencies, wallpapers, screenshots, recordings, album artwork or executable binaries are bundled. Runtime icon/artwork providers are external.

The supplied folder has no valid Git history. No private source trees, live configuration or user services were accessed to fill authorship gaps. There is no exhaustive internet similarity search for every unattributed line. Therefore a finding of “no additional upstream attribution identified” is not proof of original authorship or permission. Owners/contributors should disclose any further borrowed source before the first release.

## Categories

- **Preparation addition:** documentation, Cava text configurations, validator and offline tests written in this preparation session. No named author or ownership allocation is asserted.
- **Supplied project implementation:** the pre-existing QML interfaces, Python workers, helpers and small settings. They form the project integration layer; their complete original/adapted history is not established by the export.
- **Adapted or redistributed upstream:** the Hyprland example portions, replacement Hyprlock configuration, Squared Nord themes and Phosphor assets, with verified scope and notices in THIRD_PARTY.md.
- **External dependency:** imported frameworks, services, utilities, fonts/cursors and runtime artwork, installed/provided separately. Their presence in a dependency list is not a source-authorship claim.
- **Excluded:** unused UI library, inherited lock variant, unknown generated palette and unused sampler identifying another shell. Originals remain only under ignored `work/excluded/`; no active component depends on the excluded library, palette or sampler.

## Public-file classification

| File | Category | Evidence / license scope |
| --- | --- | --- |
| `.gitignore` | Preparation addition | Written during repository preparation; no named ownership or project-wide license assigned. |
| `AUDIT_REPORT.md` | Preparation addition | Written during repository preparation; no named ownership or project-wide license assigned. |
| `LICENSES/Hyprland-BSD-3-Clause.txt` | Verbatim upstream legal notice | Scope and source links in THIRD_PARTY.md; not a blanket project grant. |
| `LICENSES/Hyprland-Dots-GPL-3.0.txt` | Verbatim upstream legal notice | Scope and source links in THIRD_PARTY.md; not a blanket project grant. |
| `LICENSES/Phosphor-Icons-MIT.txt` | Verbatim upstream legal notice | Scope and source links in THIRD_PARTY.md; not a blanket project grant. |
| `LICENSES/rofi-themes-collection-GPL-3.0.txt` | Verbatim upstream legal notice | Scope and source links in THIRD_PARTY.md; not a blanket project grant. |
| `README.md` | Preparation addition | Written during repository preparation; no named ownership or project-wide license assigned. |
| `THIRD_PARTY.md` | Preparation addition | Written during repository preparation; no named ownership or project-wide license assigned. |
| `cava/cyberglass.conf` | Preparation addition | Written during repository preparation; no named ownership or project-wide license assigned. |
| `cava/wallpaper.conf` | Preparation addition | Written during repository preparation; no named ownership or project-wide license assigned. |
| `docs/ICON_PROVENANCE.md` | Preparation addition | Written during repository preparation; no named ownership or project-wide license assigned. |
| `docs/QUICKSHELL_SMOKE_TEST.md` | Preparation addition | Written during repository preparation; no named ownership or project-wide license assigned. |
| `hypr/hypridle.conf` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `hypr/hyprland.lua` | Adapted upstream + local integration | Hyprland BSD 3-Clause notice covers upstream-derived portions; local additions not blanket-licensed. |
| `hypr/hyprlock.conf` | Adapted upstream | Pinned JaKooLit/SherLock707 source; upstream GPL v3. |
| `hypr/hyprpaper.conf` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `kitty/kitty.conf` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell/AppDock.qml` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell/AudioPopup.qml` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell/CaffeineIndicator.qml` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell/CalendarPopup.qml` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell/DateTime.qml` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell/DesktopVisualizer.qml` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell/Notifications.qml` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell/NowPlaying.qml` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell/SystemMonitorButton.qml` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell/Tray.qml` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell/TrayMenu.qml` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell/TrayToggle.qml` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell/Volume.qml` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell/Workspaces.qml` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell/icons/bell-slash.svg` | Redistributed styled asset | Verified Phosphor regular geometry; MIT notice retained. |
| `quickshell/icons/bell.svg` | Redistributed styled asset | Verified Phosphor regular geometry; MIT notice retained. |
| `quickshell/icons/caret-up.svg` | Redistributed styled asset | Verified Phosphor regular geometry; MIT notice retained. |
| `quickshell/icons/coffee.svg` | Redistributed styled asset | Verified Phosphor regular geometry; MIT notice retained. |
| `quickshell/icons/music-notes.svg` | Redistributed styled asset | Verified Phosphor regular geometry; MIT notice retained. |
| `quickshell/icons/pause.svg` | Redistributed styled asset | Verified Phosphor regular geometry; MIT notice retained. |
| `quickshell/icons/play.svg` | Redistributed styled asset | Verified Phosphor regular geometry; MIT notice retained. |
| `quickshell/icons/pulse.svg` | Redistributed styled asset | Verified Phosphor regular geometry; MIT notice retained. |
| `quickshell/icons/skip-back.svg` | Redistributed styled asset | Verified Phosphor regular geometry; MIT notice retained. |
| `quickshell/icons/skip-forward.svg` | Redistributed styled asset | Verified Phosphor regular geometry; MIT notice retained. |
| `quickshell/icons/sliders-horizontal.svg` | Redistributed styled asset | Verified Phosphor regular geometry; MIT notice retained. |
| `quickshell/icons/speaker-high.svg` | Redistributed styled asset | Verified Phosphor regular geometry; MIT notice retained. |
| `quickshell/icons/speaker-low.svg` | Redistributed styled asset | Verified Phosphor regular geometry; MIT notice retained. |
| `quickshell/icons/speaker-x.svg` | Redistributed styled asset | Verified Phosphor regular geometry; MIT notice retained. |
| `quickshell/scripts/open_system_monitor.sh` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell/shell.qml` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell-activity/shell.qml` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell-caffeine/shell.qml` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell-control/ActivityOverlay.qml` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell-control/AudioControls.qml` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell-control/CaffeineControls.qml` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell-control/ControlButton.qml` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell-control/DeviceSelector.qml` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell-control/GameModeControls.qml` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell-control/NetworkControls.qml` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell-control/NetworkMonitorPage.qml` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell-control/PowerOverlay.qml` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell-control/ProcessManagerPage.qml` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell-control/SystemMonitorOverlay.qml` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell-control/TodoOverlay.qml` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell-control/scripts/metrics.py` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell-control/scripts/netdiag.py` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell-control/scripts/netproc.py` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell-control/scripts/nettool.py` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell-control/scripts/process_action.py` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell-control/scripts/worker_runtime.py` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `quickshell-control/shell.qml` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `rofi/config.rasi` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `rofi/scripts/powermenu.sh` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `rofi/squared-nord.rasi` | Redistributed/adapted upstream | Newman Sanchez / newmanls; upstream GPL v3. Active variant modified. |
| `rofi/themes/squared-nord.rasi` | Redistributed/adapted upstream | Newman Sanchez / newmanls; upstream GPL v3. Active variant modified. |
| `screenshots/README.md` | Preparation addition | Written during repository preparation; no named ownership or project-wide license assigned. |
| `scripts/cava-toggle` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `scripts/control-center-toggle` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `scripts/game-mode` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `scripts/gsr-toggle-recording` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `scripts/quickshell-background-start` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `scripts/screenshot-main` | Supplied project implementation | Pre-existing source/configuration; authorship not independently established; no additional upstream attribution identified. |
| `scripts/validate` | Preparation addition | Written during repository preparation; no named ownership or project-wide license assigned. |
| `tests/test_safety.py` | Preparation addition | Written during repository preparation; no named ownership or project-wide license assigned. |

This source audit and `docs/FILE_INVENTORY.sha256` are preparation records; the manifest hashes all public files except itself. The release archive contains only that manifest and its listed files. Development **outputs** and excluded sources are omitted; repository-owned validator/test **source** remains intentionally included for reproducibility. No all-rights-cleared or sole-authorship statement is made.
