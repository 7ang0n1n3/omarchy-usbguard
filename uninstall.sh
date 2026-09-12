#!/usr/bin/env bash
set -euo pipefail
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config_dir=${XDG_CONFIG_HOME:-$HOME/.config}
data_dir=${XDG_DATA_HOME:-$HOME/.local/share}
plugin_dir="$config_dir/omarchy/plugins/tangonine.usbguard"
if [[ -d "$plugin_dir" && ! -L "$plugin_dir" && -f "$plugin_dir/.usbguard-source" && $(<"$plugin_dir/.usbguard-source") == "$source_dir" ]]; then
    if command -v omarchy >/dev/null; then omarchy plugin disable tangonine.usbguard || true; fi
    rm -r -- "$plugin_dir"
fi
for path in "$plugin_dir" "$config_dir/quickshell/usbguard"; do
    if [[ -L "$path" && $(readlink -- "$path") == "$source_dir" ]]; then unlink "$path"; fi
done
app_dir="$config_dir/quickshell/usbguard"
if [[ -d "$app_dir" && ! -L "$app_dir" && -f "$app_dir/.usbguard-source" && $(<"$app_dir/.usbguard-source") == "$source_dir" ]]; then
    rm -r -- "$app_dir"
fi
desktop_file="$data_dir/applications/omarchy-usbguard.desktop"
if [[ -f "$desktop_file" ]] && grep -qx 'Exec=quickshell -c usbguard --no-duplicate' "$desktop_file"; then rm -- "$desktop_file"; fi
echo "Removed app links and launcher. USBGuard policy and permissions were not changed."
