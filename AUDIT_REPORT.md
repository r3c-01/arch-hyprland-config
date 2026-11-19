# Public release preparation audit

Updated: 2026-11-19 — final credits, source attribution and archive review.

## Readiness assessment

**Prepared as a reviewable public-source candidate; no publishing was performed.** The requested third-party provenance issues have been addressed by verified upstream licensing or exclusion. The unused UI library and uncertain inherited lock configuration are not part of the public source inventory/archive. Rofi themes and icons have verified source correspondence, retained attribution and complete upstream license texts. A replacement lock configuration is adapted from a pinned, verified GPL source. The verified Hyprland example portions now retain their BSD 3-Clause copyright and full notice. An unreferenced color palette and unused sampler with unresolved provenance are also excluded.

This resolves the earlier blanket hold for these specific third-party items. It is not a certification of ownership of every pre-existing file or of live desktop correctness. A project-wide license for unrelated original material remains an owner decision; absence of that license alone is not evidence that publication is prohibited. Hardware, service and visual acceptance remain documented limitations rather than established source-publication blockers.

There is still no valid Git metadata in this folder. Commit history, staged state, branches, tags and remote objects cannot be audited. If history is later attached, audit it separately. Nothing was initialized, committed, pushed, published or made public. No live dotfiles, installed configurations, private repositories or user services were changed or inspected to obtain missing components. All filesystem changes and downloaded verification snapshots are inside the requested working folder.

## Changes in this follow-up

| Affected files | Modification and evidence |
| --- | --- |
| `quickshell-control/ui/` | Confirmed no active QML/Lua/Python/shell/Rofi source imports this directory or references its component types. Moved all 13 QML files and `qmldir` to ignored `work/excluded/quickshell-control-ui/`, outside the intended public tree. No active behavior was removed. Unknown ownership is not treated as permission. |
| `quickshell/shell.qml` | Renamed outer window ID from `barWindow` to `barPanel`; updated the calendar binding to `barWindow: barPanel` and the width reference. The calendar retains its existing public property. The shadowing diagnostic is gone; live popup positioning is untested. |
| `hypr/hyprlock.conf` | Excluded the uncertain inherited variant as `work/excluded/hyprlock-unverified.conf`. Replaced it with a compact adaptation from the pinned JaKooLit/SherLock707 1080p configuration. Preserves password input, screenshot blur and date/time; removes wallust/helper-script dependencies and the former user label/custom styling. Added source, license and dated modification notices. |
| `rofi/squared-nord.rasi`, `rofi/themes/squared-nord.rasi` | Identified exact upstream Squared Nord source and GPL v3 license. The supplied alternate theme matched the pinned original byte for byte before notice additions. Retained both functional themes and author comments; added license pointers and a modification notice to the active local variant. |
| `quickshell/icons/*.svg` | All 14 match corresponding pinned Phosphor regular icons by viewBox/drawing geometry; local white styling and serialization differ. Retained the assets under verified MIT terms; recorded comparison method and both hash sets in `docs/ICON_PROVENANCE.md`. |
| `LICENSES/` | Four verbatim upstream license texts: Hyprland-Dots GPL v3, Rofi theme collection GPL v3, Phosphor Icons MIT and Hyprland BSD 3-Clause. No blanket license or original authorship grant was invented. |
| `.gitignore`, `scripts/validate` | Added an explicit ignore rule for the old UI path. The validator rejects a reintroduced UI directory or QML references to its component types/paths. Ignored `work/` remains outside the public inventory and archive. |
| `hypr/hyprland.lua` | Compared with the pinned Hyprland v0.57.2 example: 15 matching blocks of at least six stripped lines (226 lines before adding attribution), including substantial bindings and window rules. Added BSD source/copyright notice and full upstream license. Only comments changed; executable configuration behavior is unchanged. |
| `hypr/scheme/current.lua`, `quickshell-control/scripts/sysmon.sh` | Neither is referenced by active source. Preserved under ignored `work/excluded/` and excluded from release: palette generator is unknown; sampler header identifies another shell with no permission evidence. Active monitoring uses Python metrics.py. |
| Documentation and inventory | Added README Credits & Acknowledgments, explicit ownership/scope distinctions, a per-file source audit and a short isolated smoke-test checklist. Updated THIRD_PARTY and this report; regenerated file hashes and public archive from the explicit allowlist. |

The original cleanup's changes remain: personal paths and private application rules removed; missing private-development startup paths replaced by bundled helpers or disabled optional integrations; Cava configurations added; visualizer delegate/output handling corrected; missing logo replaced with text; activity retention regex and alternate CPU guest accounting corrected; screenshot output generalized; recorder notifications no longer claim an unverified resolution. The earlier redundant Rofi backup and empty unreferenced launcher configuration remain removed.

## Verified upstream evidence

| Material | Verification and disposition |
| --- | --- |
| Squared Nord | `newmanls/rofi-themes-collection` at `911cc27afe9c66d7e2cb06a47c905d046ea3dfd2`, `themes/squared-nord.rasi` and root `LICENSE`. Supplied alternate theme matched exactly; active theme is an attributed adaptation. GPL version 3 as supplied upstream. |
| Icons | `phosphor-icons/core` at `2b75f3ad12b420c9504ef05df8d2564a28f8500e`, `assets/regular/<name>.svg` and root `LICENSE`. Fourteen verified geometry matches; MIT notice retained in full. Historical donor revision is unknown, but corresponding licensed artwork is verified. |
| Replacement Hyprlock | `JaKooLit/Hyprland-Dots` at `c093e836764d62346390ba307c9163ca11d0229b`, `config/hypr/hyprlock-1080p.conf` and root `LICENSE.md`. Newly adapted from this verified source under its GPL v3 terms. |
| Excluded inherited Hyprlock | Header credits align with the same source family, but the supplied variant differs from all three pinned current upstream lock configurations checked. Exact origin remains unresolved, so it was excluded rather than declaring it covered. |
| Hyprland example | `hyprwm/Hyprland` at `11cbc6c577b84ffb1edf4df3fc5b6128c3ae6947` (v0.57.2), `example/hyprland.lua` and root BSD 3-Clause `LICENSE`. Matching source blocks establish attribution of template-derived portions; unrelated additions are not blanket-relicensed. |
| Excluded UI library | Comments mention another shell/file-manager host without ownership/license evidence. No active import/reference was found. Excluded even though unused source could otherwise still be redistributed. |

Primary source links, scope, modifications and notices are in THIRD_PARTY.md. Direct source and license retrieval used public upstream URLs only. No private project source was accessed. Both GPL configuration sources are included in editable form, with the relevant licenses and change notices. Other project material has not been blanket-relicensed.

The template-derived Hyprland portions are now attributed to a verified BSD source, and the unexplained unused palette/sampler are excluded. The remaining pre-existing interfaces, workers and helpers have no independently reconstructed authorship history. They are classified as supplied project implementation, not claimed as verified original work. No further explicit third-party source/permission claim was identified in their headers/imports/references; absence of such a claim is not proof of ownership. See `docs/SOURCE_AUDIT.md` for the complete public-file classification and review limits.

## Public release boundary

The final source candidate contains 83 regular files (including its manifest). It consists of the files listed in `docs/FILE_INVENTORY.sha256`, plus the manifest itself. The local archive `work/releases/arch-hyprland-config-public-source.tar.gz` is assembled from exactly that allowlist and has a neighboring SHA-256 file. The archive contains no symlinks, absolute/traversal paths, special files, account metadata, private state, Git data, excluded originals, downloaded verification snapshots, logs/caches, recordings or `work/` contents. Repository-owned validation source/tests are intentionally included for reproducibility; generated development artifacts are excluded. Archive user/group names and IDs are normalized; no absolute host paths are used.

`work/excluded/` preserves the removed originals locally for reversibility. `work/provenance/` contains downloaded public evidence. **Neither directory is part of the release. Do not publish the entire working folder or force-add ignored files.** `.gitignore` is a safeguard for future staging, not a substitute for reviewing actual staged content or imported history. Any source changes require regenerating the manifest and archive.

## Validation evidence

Current final-review checks (rerun against the public source):

| Check | Observed result | Scope and limits |
| --- | --- | --- |
| Python source | 9 files parsed successfully | Includes helper entry points, validator and tests; Python 3.14.10 on audit host |
| Lua syntax | 1 public file passed `luac -p` | Lua 5.5.1; not live compositor API acceptance |
| Shell syntax | 7 public scripts passed `bash -n` | ShellCheck unavailable; desktop/power/recording helpers were not executed |
| QML source | 30 public QML files parsed with Qt 6 `qmlformat` 6.12.0 | Excluded 13-file UI library is intentionally not checked as public source |
| QML semantic lint | 0 error diagnostics; 155 warning diagnostics | 134 unqualified/grouped-scope, 15 missing-property, 3 uncreatable-type, 2 unresolved-type and 1 layout-positioning diagnostics; not a clean lint result |
| Calendar binding | No remaining ID-shadow diagnostic for `barWindow` | Source binding is unambiguous; no live popup test |
| DesktopVisualizer | No semantic lint diagnostics | Live Cava/audio/rendering untested |
| SVG XML | 14 files parsed successfully | Separate geometry/source and MIT verification completed |
| Rofi | Explicit current config/theme loaded with `-dump-theme`, exit 0 | No interactive menu or display test |
| Offline safety tests | All 6 passed | Invalid destinations, missing DNS tool, CPU guest accounting, worker timeout, simulated Game Mode restoration and partial-failure rollback; no live recorder/desktop mutation |
| Release integrity | Rebuilt archive, checked every member against the current allowlist, verified embedded manifest/content hashes and neighboring archive checksum | Explicit allowlist excludes local archives and scratch; no symlinks included |
| Privacy scan | No excluded-project references, personal home-path literals or recognizable credential formats found in the public-source candidate | Pattern-based, not a dedicated credential-scanner or history guarantee |

Reproduce syntax checks with `python3 -B scripts/validate` and tests with `python3 -B tests/test_safety.py`. The validator returns nonzero for syntax failures, unavailable required validators or excluded-library regressions. Tests use temporary fixtures inside ignored `work/` and simulated desktop effects.

Earlier baseline evidence is retained only as historical evidence: Hyprland 0.57.2 `--verify-config` returned `config ok`, exit 0, while reporting an IPC socket binding failure in its isolated environment. Only attribution comments changed in the Lua file in this final review; it was syntax-checked again. The compositor check was not repeated. Installed Quickshell previously reported 0.3.2. Hyprlock has no dry-run checker exposed by the inspected CLI; the replacement was not launched, and no parser/runtime success is claimed for it.

## Remaining issues and practical release decision

1. **Known QML compatibility limitations:** `PanelWindow`, popup anchors/margins and dynamic model `.values` warnings need review against the target Quickshell build. Static metadata warnings alone do not prove runtime failure. Test bar, tray, calendar, caffeine and audio in a disposable session before claiming full compatibility.
2. **Known layout issue:** `quickshell-control/PowerOverlay.qml:96` assigns direct height inside a layout. Replace it with `Layout.preferredHeight` or a suitable implicit height and visually verify when addressing UI polish. The unused preview library's 33 layout diagnostics are outside the release.
3. **Live acceptance pending:** replacement lock authentication/layout, Cava, notifications, tasks/activity initialization, Wi-Fi/Bluetooth, process actions, recording and Game Mode remain untested in a live session. Six simulated tests are not hardware, recovery or performance certification.
4. **Manual setup requirements:** monitor names/modes remain examples; supply a wallpaper, initialize state without overwriting user data and configure external services. Custom XDG support remains partial. Optional overview, wallpaper picker and animated-wallpaper launcher are not bundled; their absent launch paths stay disabled. Recorder service configuration is an external dependency.
5. **Ownership and licensing limits:** no blanket project license was selected, and this source export cannot establish authorship of every pre-existing integration file. README and THIRD_PARTY explicitly distinguish newly written preparation additions, attributed adaptations and external dependencies. Resolve any additional origins known to the owner/contributors before publishing; any newly identified unlicensed copied material would be a release blocker. No evidence of such an additional included copy was established in this review.
6. **Publication handling:** retain all bundled license notices/source credits and scope any future owner-selected license appropriately. Do not include excluded originals. Audit any later-added history and genuine screenshots/diagnostics before publication. No general right to reuse unrelated unlicensed project material should be implied.

No remaining unresolved permission issue was identified for the specifically investigated included Rofi themes, Phosphor assets, replacement Hyprlock source or BSD Hyprland example portions. The unknown UI and inherited lock material have been excluded. Source publication can be considered with these boundaries and limitations; a production-ready or fully tested desktop claim would be unsupported. This task stops before publishing.


## Isolated smoke-test handoff

`docs/QUICKSHELL_SMOKE_TEST.md` provides seven short checks covering isolation, clean state, foreground startup, rendering/IPC, task/activity persistence, reversible controls, explicit network/high-impact tests and worker cleanup. It was not executed. A VM with separate compositor, D-Bus and services is preferred; changing HOME alone does not isolate a live session. This final review launched no Quickshell instances, lock screen or desktop actions.
