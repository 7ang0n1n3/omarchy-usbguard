#!/usr/bin/env bash
set -euo pipefail
test_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export USBGUARD_TEST_DIR
USBGUARD_TEST_DIR=$(mktemp -d /tmp/usbguard-test.XXXXXX)
mkdir "$USBGUARD_TEST_DIR/bin"
mkdir -p "$USBGUARD_TEST_DIR/app/services"
cp "$test_dir/../services/UsbGuardService.qml" "$test_dir/../services/Command.qml" "$test_dir/../services/UsbGuardParser.js" "$test_dir/../services/usb-metadata.sh" "$USBGUARD_TEST_DIR/app/services/"
sed -i "s|/usr/bin/pkexec|$USBGUARD_TEST_DIR/bin/pkexec|g" "$USBGUARD_TEST_DIR/app/services/UsbGuardService.qml"
sed 's|"../services"|"services"|' "$test_dir/ServiceTest.qml" > "$USBGUARD_TEST_DIR/app/shell.qml"
ln -s "$test_dir/fake-cli.cjs" "$USBGUARD_TEST_DIR/bin/usbguard"
ln -s "$test_dir/fake-cli.cjs" "$USBGUARD_TEST_DIR/bin/systemctl"
ln -s "$test_dir/fake-cli.cjs" "$USBGUARD_TEST_DIR/bin/pkexec"
printf '%s' '{"mode":"normal","connected":true,"target":"block","rules":[{"id":4,"target":"allow"}]}' > "$USBGUARD_TEST_DIR/state.json"
export PATH="$USBGUARD_TEST_DIR/bin:$PATH"
QT_QPA_PLATFORM=offscreen timeout 55s quickshell -p "$USBGUARD_TEST_DIR/app" --no-color 2>&1 | tee "$USBGUARD_TEST_DIR/test.log"
grep -q 'SERVICE TESTS PASSED' "$USBGUARD_TEST_DIR/test.log"
node -e 'const fs=require("fs"),assert=require("assert");const lines=fs.readFileSync(process.env.USBGUARD_TEST_DIR+"/commands.jsonl","utf8").trim().split("\n").map(JSON.parse);const mutations=lines.filter(a=>/^(allow-device|block-device|reject-device|remove-rule)$/.test(a[1]));assert.equal(mutations.length,6,"stale request must not reach CLI");console.log("PASS exactly six expected mutations; stale ID never dispatched");'
echo "Fixtures and command trace: $USBGUARD_TEST_DIR"
