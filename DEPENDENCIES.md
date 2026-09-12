# Dependencies and system access

Runtime dependencies are supplied by the host: Omarchy Quattro Commons/Ui,
Quickshell, Qt 6 QML/Quick, USBGuard, Python 3, polkit/pkexec, Bash and coreutils.
The repository does not vendor their source or binaries. Their installed
licenses remain applicable; Omarchy UI modules are linked only in the optional
standalone installation. Node.js and QtTest are development dependencies.

The UI launches bounded USBGuard listing and event commands, `systemctl is-active`
for daemon status, and the repository's read-only sysfs metadata script. Writes
launch `/usr/bin/pkexec` and the separately installed root-owned helper, which
uses `/usr/bin/usbguard`. The UI never receives authentication secrets.

The application implements no network calls or telemetry. Git installation and
updates contact GitHub; package installation contacts configured package mirrors.
USBGuard communicates with the local daemon. The plugin reads device metadata
from sysfs, Omarchy theme files, and USBGuard output. Activity is held in memory.

The administrator installer writes `/usr/local/libexec/omarchy-usbguard-action`
and `/usr/share/polkit-1/actions/org.omarchy.usbguard.policy`. Explicit user
actions may cause the USBGuard daemon to update its configured policy storage.
The plugin itself does not edit daemon configuration or ACLs. The README lists
user installation paths, update/removal commands, and retained files.

No static scan constitutes a security audit. The identity check and subsequent
daemon mutation are separate operations and cannot eliminate every race.
