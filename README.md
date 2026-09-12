# USBGuard for Omarchy

Licensed under the [MIT License](LICENSE).

A Quickshell utility for inspecting USB devices and managing USBGuard policy. It uses the installed Omarchy shell's **actual** `qs.Commons` and `qs.Ui` modules: colors, font, spacing, control states, borders, corner radius and Nerd Font glyphs. Window shadows and compositor opacity remain under Hyprland's control.

## Requirements and installation

Developed against this machine's Quickshell **0.3.1**, USBGuard **1.1.4**, and Lua-based Omarchy shell at `/usr/share/omarchy/shell`. Requires Python 3 and pkexec for the privileged helper, plus Bash and coreutils (`timeout`, `stdbuf`), already present on Omarchy. Node.js is only needed for tests.

### Install the shell plugin from Git

```bash
omarchy plugin add https://github.com/7ang0n1n3/omarchy-usbguard.git
bash ~/.config/omarchy/plugins/tangonine.usbguard/install-privileged.sh
omarchy plugin enable tangonine.usbguard
omarchy restart shell
omarchy-shell shell toggle tangonine.usbguard
```

Adding the plugin clones its source; it does not execute the privileged installer.
Review the helper before installing it. Reads work without the helper when the
account has USBGuard read access. Enablement updates Omarchy shell configuration.
Restarting the shell ensures nested QML types load from the newly cloned source;
live testing found that hot reload can delay panel IPC registration.

Update and remove this Git installation with:

```bash
omarchy plugin update tangonine.usbguard
omarchy restart shell
# If the helper changed, review and reinstall it:
bash ~/.config/omarchy/plugins/tangonine.usbguard/install-privileged.sh
# Removal:
omarchy plugin remove tangonine.usbguard
```

The root-owned helper and polkit policy remain until separately removed using
the command below. USBGuard rules, package and existing IPC ACLs are retained.

### Optional standalone installation

Use a separate source checkout for the standalone launcher and versioned plugin
installer. Do not install this over a Git-managed plugin with the same ID; the
installer refuses destinations it does not own.

From a local source checkout whose exact commit you have reviewed:

```bash
bash install-privileged.sh
bash install.sh
quickshell -c usbguard --no-duplicate
```

This creates a standalone copy in `~/.config/quickshell/usbguard`, a versioned
plugin copy in `~/.config/omarchy/plugins/tangonine.usbguard`, and the launcher
`~/.local/share/applications/omarchy-usbguard.desktop`. Standalone module links
are created in its installed directory; the Git source and installed plugin
contain no symlinks. Old content-addressed generations remain until uninstall.

```bash
# After reviewing an updated exact source commit:
bash install.sh
# Close standalone mode before updating or removing it.
bash uninstall.sh
```

Use either plugin or standalone mode for normal operation. Standalone reads
installed Omarchy theme modules and reloads active theme files every 2.5 seconds.
No daemon configuration, USB rules, permissions or Hyprland config is edited by
the user installer. Git installs restart the shell after add/update because the
host can retain imported QML types; the custom installer uses fresh content URLs.

## Permissions and policy

Every device/rule change now invokes `pkexec --disable-internal-agent /usr/local/libexec/omarchy-usbguard-action`. Omarchy’s polkit agent asks for administrator authentication after any app safety confirmation. The UI never runs as root and never handles passwords. Opening, searching and refreshing do not trigger authentication.

Install the privileged support files once (this requires administrator authentication):

```bash
bash install-privileged.sh
```

The installer creates a root-owned, non-setuid helper (0755) and `/usr/share/polkit-1/actions/org.omarchy.usbguard.policy` (0644). The policy is restricted to that helper path and uses `auth_admin`, not `auth_admin_keep`; inactive and remote sessions are denied. Existing administrator-defined polkit rules remain authoritative. No USBGuard group, write ACL, sudo rule or daemon restart is added.

The helper uses Python 3 in isolated mode (`-I`) only for its small privilege boundary; the application remains QML/Quickshell. It accepts six fixed actions, a numeric ID, and the selected record. After authentication it independently re-reads the record, rejects changed/disconnected targets, and invokes only `/usr/bin/usbguard` with fixed argument arrays and a clean environment. It cannot execute arbitrary commands or accept policy/configuration paths. CLI calls are limited to ten seconds; the UI allows three minutes for authentication. Cancellation/denial does not retry or perform a change.

Existing ordinary-user **read access** on this account is sufficient. If setting up a different account, an administrator can grant only the optional browsing privileges below after reviewing existing ACLs:

```bash
sudo usbguard add-user "$USER" --devices=list,listen --policy=list --parameters=list
```

Do not replace an existing ACL blindly. These are read/event privileges, not device or policy modification. The configured `IPCAccessControlFiles` directory must be active. The app does not alter it. This setup does not require adding the user to a USBGuard group.

To test the installed authentication path without changing any device:

```bash
pkexec --disable-internal-agent /usr/local/libexec/omarchy-usbguard-action check
```

Removing the app’s user files intentionally retains this root-owned support. To remove it too, after uninstalling the app:

```bash
sudo rm /usr/local/libexec/omarchy-usbguard-action /usr/share/polkit-1/actions/org.omarchy.usbguard.policy
```

On Arch, the package was verified in the `extra` repository:

```bash
sudo pacman -S usbguard
```

Before first starting the service, review/configure a policy with particular care for keyboards, mice and hubs. This installer deliberately does not generate or replace one. Check `systemctl status usbguard.service` when the app reports an inactive daemon.

### Inspected machine configuration

Both `/etc/usbguard/usbguard-daemon.conf` and `/etc/usbguard/rules.conf` were inspected read-only. The daemon uses:

```ini
RuleFile=/etc/usbguard/rules.conf
RuleFolder=/etc/usbguard/rules.d/
ImplicitPolicyTarget=block
InsertedDevicePolicy=block
PresentDevicePolicy=apply-policy
DeviceRulesWithPort=false
IPCAccessControlFiles=/etc/usbguard/IPCAccessControl.d/
```

**New connections start blocked on this machine.** “Always allow” saves a rule and allows the current connection, but does not override `InsertedDevicePolicy=block`. Changing the daemon's insertion policy is a separate administrator decision; the app does not change it. When `get-parameter InsertedDevicePolicy` is permitted, the app displays this condition in its footer.

## Using the app

- **Devices**: live devices recognized by USBGuard. Manufacturer/product metadata is enriched from sysfs when available; status always comes from USBGuard.
- **Rules**: the daemon's policy, including rules for currently disconnected devices. Broad/wildcard rules are retained and clearly identified by their rule ID. This is not a historical inventory of every device ever seen.
- **Activity**: successful actions and errors from this app session. It is not the daemon's audit log.
- Click a device for details; the ellipsis opens contextual actions. Search covers product, manufacturer, vendor/product ID, serial, USBGuard ID and hash. Status badges always include text.
- Device details list rules with an identical hash. This is explicitly an association, not proof that a complex rule matches; inspect the expandable full record for all conditions.

| Action | CLI used |
| --- | --- |
| Allow temporarily | `usbguard allow-device ID` |
| Block temporarily | `usbguard block-device ID` |
| Reject | `usbguard reject-device ID` |
| Always allow | `usbguard allow-device --permanent ID` |
| Always block | `usbguard block-device --permanent ID` |
| Delete saved rule | `usbguard remove-rule RULE_ID` |

These options were checked against the installed CLI help. Permanent changes are made through the daemon's supported mechanisms, which can append or update a device-specific rule. The app never writes the policy file itself. Rule removal does not immediately change an already-connected device's authorization. Reject removes the device from the system; it may vanish from the live list until physically reconnected.

All block/reject operations and all permanent changes require confirmation. HID keyboard, mouse, composite HID, generic HID/security-key and hub/controller functions receive an additional lockout warning. Cancel receives initial focus. USB interfaces are device-supplied metadata, so detection is necessarily heuristic. Before mutation, both the app and the authenticated helper re-read the relevant list and compare the entire selected record to protect against changed/recycled IDs. The CLI cannot make this check and mutation atomic; a very small race remains.

Refresh happens on opening, after actions, manually, and after debounced `usbguard watch` events. A 30-second refresh recovers from daemon restarts, missing event permissions, or another client's policy edits. Commands have a 10-second timeout; a timed-out mutation may already have reached the daemon, so review refreshed state before retrying. No operation is automatically retried.

### Keys

`R` refreshes; `/` focuses search; `J/K` or arrows move the selection; `Enter` opens details after list navigation; `Menu` opens actions. `Tab` moves between controls, and `Enter`/`Space` activates the focused control. `Esc` dismisses a sheet, clears/leaves search, or closes the window. Shortcuts are local to this window and do not consume search typing.

### Optional Hyprland integration

This installation uses Lua. Add these yourself only if desired; check for an existing binding before assigning Super+U:

```lua
o.bind("SUPER + U", "USBGuard", "omarchy-shell shell toggle tangonine.usbguard")

-- Optional compact floating utility window (otherwise Hyprland may tile it):
o.window({ class = "^org[.]quickshell$", title = "^USBGuard$" }, {
  float = true,
  center = true,
  size = { 770, 680 },
})
```

For standalone mode, substitute `quickshell -c usbguard --no-duplicate` as the command. After editing Lua configuration, use `hyprctl reload` and `hyprctl configerrors`. The example follows the installed Omarchy helper and [current Hyprland window rules](https://wiki.hypr.land/Configuring/Basics/Window-Rules/).

## Architecture and files

```text
omarchy-usbguard/
├── shell.qml                 Standalone entry and IPC
├── Panel.qml                 Omarchy plugin entry, window and navigation
├── manifest.json             Omarchy panel plugin registration
├── components/
│   ├── Label.qml
│   ├── DeviceRow.qml
│   ├── StatusBadge.qml
│   ├── EmptyState.qml
│   ├── Sheet.qml
│   ├── ActionMenu.qml
│   ├── DeviceDetails.qml
│   └── ConfirmDialog.qml
├── services/
│   ├── UsbGuardService.qml    State, refresh, events and action preflight
│   ├── Command.qml            Bounded argv-based Process runner
│   ├── UsbGuardParser.js      Parsing, search, safety classification and argv
│   ├── usb-metadata.sh        Read-only sysfs metadata
│   └── Theme.qml              Standalone bridge to Omarchy theme loaders
├── tests/
│   ├── package_test.py
│   ├── helper_test.py
│   ├── parser.test.cjs
│   ├── fake-cli.cjs
│   ├── ServiceTest.qml
│   ├── run-service.sh
│   ├── VisualTest.qml
│   └── preview.sh
├── privileged/               Root-owned action helper and polkit policy
├── install-privileged.sh      One-time authenticated support installation
├── package-plugin.py          Atomic manifest switch to versioned QML releases
├── install.sh
├── uninstall.sh
├── VALIDATION.md
└── README.md
```

USBGuard commands are argument arrays, never shell strings built from device data. The unprivileged shell helper reads sysfs; the separately installed privilege helper validates and performs authenticated mutations. Device-controlled text is always rendered as plain text. No C++, Python GUI, Electron, GTK, web runtime, additional icon set, or separate theme is used.

## Validation and troubleshooting

Run the portable suite with `./tests/run` (Node.js, Python 3, and Bash).
Release readiness and outstanding prerequisites are recorded in
[RELEASE-PREFLIGHT.md](RELEASE-PREFLIGHT.md).

```bash
node tests/parser.test.cjs
python3 tests/helper_test.py
python3 tests/package_test.py
bash tests/run-service.sh
bash tests/preview.sh
```

The root marketplace preview uses only committed fictional USB records. On an
Omarchy Wayland session, reproduce it with `./demo/run`; the harness uses an
empty temporary workspace and restores the previous workspace on exit.

Service tests exercise real Quickshell Process integration against a fake CLI in a private `/tmp` directory. They do not touch the real daemon. Preview also uses fake devices and a private HOME for theme testing. Test logs and command traces are printed at completion. See [VALIDATION.md](VALIDATION.md) for performed checks and limits.

For runtime logs:

```bash
quickshell log -c usbguard -t 80
usbguard list-devices
usbguard list-rules
systemctl status usbguard.service
```

The app's information button contains setup instructions, version, service state, separate device/policy IPC status and expandable diagnostic output. Failed list calls clear stale data rather than presenting disconnected devices as current. Unknown or unsupported output is reported instead of silently appearing empty.

If `qs.Commons`/`qs.Ui` cannot load, verify the installed Omarchy shell path and rerun the standalone installer if needed. These shell APIs are an intentional dependency; changes to Omarchy's internal UI modules may require updating the app. A host-portal registration warning can occur because standalone Quickshell shares the `org.quickshell` application ID with the shell; it did not affect USBGuard operation in testing.

To uninstall, close the app then run `bash uninstall.sh`. It disables and removes its owned plugin copy, matching standalone link and desktop launcher. Source, USBGuard rules, package and IPC ACLs are retained. Any optional keybind/window rule you added must be removed separately.

References: installed USBGuard CLI/man pages and [upstream USBGuard documentation](https://github.com/USBGuard/usbguard).

For plugin action troubleshooting, inspect the loaded backend (expected `polkit-v3`) and release path:

```bash
omarchy-shell shell call tangonine.usbguard diagnosticsSnapshot ''
```

Diagnostics distinguish listing, preflight and authenticated-action failures. After reinstalling, run `omarchy-shell shell rescanPlugins` and reopen the panel.
