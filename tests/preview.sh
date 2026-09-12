#!/usr/bin/env bash
set -euo pipefail
test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export USBGUARD_TEST_DIR
USBGUARD_TEST_DIR=$(mktemp -d /tmp/usbguard-preview.XXXXXX)
mkdir -p "$USBGUARD_TEST_DIR/bin" "$USBGUARD_TEST_DIR/app" "$USBGUARD_TEST_DIR/home/.local/state/omarchy/current" "$USBGUARD_TEST_DIR/home/.config/omarchy"
cp -r "$test_dir/../components" "$test_dir/../services" "$test_dir/../Panel.qml" "$USBGUARD_TEST_DIR/app/"
sed -i "s|/usr/bin/pkexec|$USBGUARD_TEST_DIR/bin/pkexec|g" "$USBGUARD_TEST_DIR/app/services/UsbGuardService.qml"
cp "$test_dir/VisualTest.qml" "$USBGUARD_TEST_DIR/app/shell.qml"
ln -s /usr/share/omarchy/shell/Commons "$USBGUARD_TEST_DIR/app/Commons"
ln -s /usr/share/omarchy/shell/Ui "$USBGUARD_TEST_DIR/app/Ui"
sed -i 's/title: "USBGuard"/title: "USBGuard · Preview"/' "$USBGUARD_TEST_DIR/app/Panel.qml"
ln -s "$test_dir/fake-cli.cjs" "$USBGUARD_TEST_DIR/bin/usbguard"
ln -s "$test_dir/fake-cli.cjs" "$USBGUARD_TEST_DIR/bin/systemctl"
ln -s "$test_dir/fake-cli.cjs" "$USBGUARD_TEST_DIR/bin/pkexec"
ln -s "$HOME/.local/state/omarchy/current/theme" "$USBGUARD_TEST_DIR/home/.local/state/omarchy/current/theme"
cp "$HOME/.config/omarchy/shell.toml" "$USBGUARD_TEST_DIR/home/.config/omarchy/"
printf '%s' '{"mode":"normal","connected":true,"target":"block","rules":[{"id":4,"target":"allow"}]}' > "$USBGUARD_TEST_DIR/state.json"
echo "Preview directory: $USBGUARD_TEST_DIR"
env HOME="$USBGUARD_TEST_DIR/home" PATH="$USBGUARD_TEST_DIR/bin:$PATH" quickshell -p "$USBGUARD_TEST_DIR/app"
