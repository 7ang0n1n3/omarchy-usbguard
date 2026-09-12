#!/usr/bin/env bash
set -euo pipefail
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config_dir=${XDG_CONFIG_HOME:-$HOME/.config}
data_dir=${XDG_DATA_HOME:-$HOME/.local/share}
plugin_dir="$config_dir/omarchy/plugins/tangonine.usbguard"
app_dir="$config_dir/quickshell/usbguard"
desktop_file="$data_dir/applications/omarchy-usbguard.desktop"
omarchy_dir=${OMARCHY_PATH:-/usr/share/omarchy}
[[ -f "$omarchy_dir/shell/Commons/Color.qml" ]] || { echo "Omarchy shell components not found at $omarchy_dir" >&2; exit 1; }
for path in "$app_dir" "$desktop_file"; do
    if [[ -e "$path" || -L "$path" ]]; then
        if [[ "$path" == "$app_dir" && -L "$path" && $(readlink -- "$path") == "$source_dir" ]]; then continue; fi
        if [[ "$path" == "$app_dir" && ! -L "$path" && -f "$path/.usbguard-source" && $(<"$path/.usbguard-source") == "$source_dir" ]]; then continue; fi
        if [[ "$path" == "$desktop_file" ]] && grep -qx 'Exec=quickshell -c usbguard --no-duplicate' "$path"; then continue; fi
        echo "Destination belongs to another installation: $path" >&2; exit 1
    fi
done
if [[ -L "$plugin_dir" && $(readlink -- "$plugin_dir") == "$source_dir" ]]; then
    unlink "$plugin_dir"
elif [[ -e "$plugin_dir" ]]; then
    [[ -f "$plugin_dir/.usbguard-source" && $(<"$plugin_dir/.usbguard-source") == "$source_dir" ]] || { echo "Existing plugin has no matching ownership marker: $plugin_dir" >&2; exit 1; }
fi
mkdir -p "$config_dir/omarchy/plugins" "$config_dir/quickshell" "$data_dir/applications"
mkdir -p "$plugin_dir"
# Every release has fresh URLs for ALL nested QML/JS types. A long-running
# Omarchy engine can otherwise retain an older imported service after reload.
python3 "$source_dir/package-plugin.py" "$source_dir" "$plugin_dir"
cp "$source_dir/README.md" "$source_dir/VALIDATION.md" "$plugin_dir/"
printf '%s\n' "$source_dir" > "$plugin_dir/.usbguard-source"
if [[ -L "$app_dir" ]]; then unlink "$app_dir"; fi
mkdir -p "$app_dir"
python3 "$source_dir/package-plugin.py" "$source_dir" "$app_dir"
revision=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["entryPoints"]["panel"].rsplit("/",1)[0])' "$app_dir/manifest.json")
{ printf 'import "%s"\n' "$revision"; cat "$source_dir/shell.qml"; } > "$app_dir/shell.qml"
ln -sfn "$omarchy_dir/shell/Commons" "$app_dir/Commons"
ln -sfn "$omarchy_dir/shell/Ui" "$app_dir/Ui"
printf '%s\n' "$source_dir" > "$app_dir/.usbguard-source"
cat > "$data_dir/applications/omarchy-usbguard.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=USBGuard
Comment=Control USB device access
Exec=quickshell -c usbguard --no-duplicate
Icon=drive-removable-media-usb
Categories=System;Security;
Terminal=false
EOF
echo "Installed USBGuard launcher, standalone copy, and Omarchy plugin."
echo "Launch: quickshell -c usbguard --no-duplicate"
echo "Enable plugin once: omarchy plugin enable tangonine.usbguard"
echo "Plugin: omarchy-shell shell toggle tangonine.usbguard"
[[ -x /usr/local/libexec/omarchy-usbguard-action ]] || echo "For authenticated changes, run once: bash $source_dir/install-privileged.sh"
