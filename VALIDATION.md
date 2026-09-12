# Validation — 2026-09-12

## Environment inspected

- Quickshell 0.3.1, QtQuick, installed Omarchy `Commons`, `Ui`, plugin manifests and sample panels.
- Omarchy user configuration, current theme files, font override (14px base), Hyprland Lua helpers.
- USBGuard 1.1.4; help for listing, allow/block/reject, permanent decisions, append/remove rule, watch and add-user.
- `usbguard.service` active, service unit inspected. Daemon configuration and rules read with administrator authentication; no policy changes made.
- Ordinary-user IPC: device and policy listing both work. Initially seven devices and eight policy rules. Later a YubiKey appeared and was shown as blocked without manual refresh. No real device action was issued by this implementation session.

## Automated checks

- All production QML files parse with the installed `qmlformat`.
- `qmllint` resolves the installed modules using a temporary `qs` import root. Remaining static warnings concern dynamically typed Omarchy `QtObject` style tokens and unqualified QML delegate access. They are not runtime load failures. Quickshell is the final runtime validator.
- Eleven Node parser/safety tests pass: quoted attributes, parent/device hashes, interface sets, wildcard rules, unknown state, malformed records, search fields, temporary/permanent argv, rule/device ID separation, invalid IDs, input/controller warnings and friendly errors.
- Quickshell service tests pass with an isolated fake CLI: list devices/rules, temporary allow, permanent block, permanent allow, temporary block without policy modification, delete rule, reject/disconnect, reconnect/refresh, denied permissions, stopped daemon, recovery, stale identity rejection, missing executable.
- Command trace confirms exactly six intended mutations and no dispatch for the stale identity. Latest successful trace: `/tmp/usbguard-test.gtpF4k/commands.jsonl` (temporary artifact).
- Shell scripts pass Bash syntax validation.

## GUI checks

- Installed plugin passes `omarchy plugin validate`; enabled and opened inside the running Omarchy shell. Only its plugin enabled state was added to shell configuration.
- Launched standalone on the live Wayland desktop and inspected Quickshell logs.
- Verified real device/rule counts, product/manufacturer enrichment and an actual device arrival.
- Inspected tiled (941×1146), compact (770×680), and minimum (540×440) layouts.
- Verified safety-dialog fit at minimum size, readable warning text and visible Cancel/Confirm buttons.
- Verified real Wayland keyboard input: J/Enter opens details; Escape dismisses sheets; slash focuses search; entering `5678` populates the search; Escape clears it.
- QtTest mouse injection verified clicking a row opens details and clicking the ellipsis opens the contextual menu. Snapshot confirmed the corresponding popup state.
- Inspected details, device menu, rules and safety confirmation screenshots. Details scroll when their content exceeds the window; long attribute text wraps.
- Changed only an isolated preview's theme symlink to stock Catppuccin Latte. The running app updated its palette within 2.5 seconds; inspected light and dark rendering. User's actual theme was untouched.
- Fixed a delegate signal/menu-ID collision and a focus-restoration issue discovered during these checks. No production QML runtime errors remained after the fixes. Qt emits an existing host-portal application-ID registration warning for standalone Quickshell; listing and UI operation are unaffected.

## Limits

- Allow/block/reject, persistent writes and rule deletion were tested against the fake CLI, not real peripherals. Real destructive tests could interrupt input, storage or security keys; write ACL access remains unproven until the user performs an intended action.
- A real arrival was observed; physical unplug/reconnect was tested through the fixture rather than deliberately disconnecting hardware.
- Daemon shutdown, missing package and permission-denied paths were simulated, without stopping the real security service or altering ACLs.
- Rejected devices can disappear from USBGuard's live list; policy rules are not a historical inventory. Complex rule matching is left to USBGuard.
- The preflight identity check and subsequent CLI action are not an atomic daemon transaction.
- Omarchy's internal shared UI modules are an explicit runtime dependency. Future incompatible API changes may require adaptation.
- Theme colors/fonts/radii derive from Omarchy; compositor opacity/shadows remain under Hyprland. No persistent floating-window rule was installed automatically.

Reproduce with `node tests/parser.test.cjs`, `bash tests/run-service.sh`, and `bash tests/preview.sh` from the project directory. The preview's QtTest helpers are test-only and never installed as an application entry point.

## Authenticated writes update

- All mutations now use the absolute `/usr/bin/pkexec` path and a root-owned, non-setuid helper; read/refresh remains unprivileged. No USBGuard group membership or write ACL was added.
- Seven privilege-boundary tests pass: fixed supported actions, malicious/invalid arguments, stale targets after authentication, root requirement, timeouts/failures, clean environment/absolute executable, and scoped non-cached polkit policy.
- Service regressions additionally cover authentication cancellation, denial and missing-helper errors, with exactly six intended fake mutations and no retries. Fixture copies redirect pkexec to a mock; production uses the absolute system binary.
- Confirmed installed ownership root:root, helper mode 0755, policy mode 0644; pkaction reports auth_admin for active sessions and no access for inactive/remote sessions.
- Real pkexec health check authenticated successfully and returned uid=0, without changing a USB device or rule. Real YubiKey authorization remains a user-initiated action in the app.

## Block/remove authentication regression

- Daemon logs showed denied applyDevicePolicy/removeRule requests without corresponding pkexec calls, while the user's successful permanent allow had a pkexec record. Ordinary device/rule listing still worked. Retained QML components in the long-running shell were suspected.
- Installation now publishes complete content-addressed QML/JS releases and atomically changes the plugin entry path. A packaging regression verifies nested service changes produce new URLs and preserve prior releases.
- The command runner refuses direct USBGuard mutation commands. Diagnostics identify the loaded backend and distinguish listing/preflight/authenticated failures.
- Parser tests (11), helper tests (7), packaging test and Quickshell service regressions pass. The service test refuses five direct mutation commands and routes all six supported actions through mock pkexec, including block and remove. It also covers cancellation, denial, stale targets and daemon failures. Trace: /tmp/usbguard-test.CZQLjE/commands.jsonl.
- No real USB device was blocked or rejected and no saved rule was removed during this regression test.
