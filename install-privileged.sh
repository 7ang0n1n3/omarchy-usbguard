#!/usr/bin/env bash
set -euo pipefail
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
if [[ $EUID != 0 ]]; then
    exec sudo /usr/bin/bash "$source_dir/install-privileged.sh"
fi
/usr/bin/install -d -o root -g root -m 0755 /usr/local/libexec
/usr/bin/install -o root -g root -m 0755 "$source_dir/privileged/omarchy-usbguard-action" /usr/local/libexec/omarchy-usbguard-action
/usr/bin/install -o root -g root -m 0644 "$source_dir/privileged/org.omarchy.usbguard.policy" /usr/share/polkit-1/actions/org.omarchy.usbguard.policy
echo "Installed scoped USBGuard helper and per-operation administrator authentication policy."
