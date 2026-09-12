#!/usr/bin/env node
// Test-only CLI. Never calls real USBGuard or systemctl.
const fs = require('node:fs');
const path = require('node:path');
const dir = process.env.USBGUARD_TEST_DIR;
if (!dir || !dir.startsWith('/tmp/')) process.exit(99);
const statePath = path.join(dir, 'state.json');
let s = JSON.parse(fs.readFileSync(statePath));
let args = process.argv.slice(2);
fs.appendFileSync(path.join(dir, 'commands.jsonl'), JSON.stringify([path.basename(process.argv[1]), ...args]) + '\n');
const cmd = path.basename(process.argv[1]);
if (cmd === 'pkexec') {
  if (s.mode === 'auth_cancel') process.exit(126);
  if (s.mode === 'auth_denied') { console.error('Not authorized'); process.exit(127); }
  if (s.mode === 'missing_helper') { console.error('Error executing: No such file or directory'); process.exit(127); }
  if (args[0] !== '--disable-internal-agent' || args[1] !== '/usr/local/libexec/omarchy-usbguard-action') process.exit(99);
  const spec = {allow:['allow-device'],block:['block-device'],reject:['reject-device'],alwaysAllow:['allow-device','--permanent'],alwaysBlock:['block-device','--permanent'],remove:['remove-rule']}[args[2]];
  if (!spec || !/^\d+$/.test(args[3]) || !args[4].startsWith(args[3] + ': ')) process.exit(99);
  args = [...spec, args[3]];
  fs.appendFileSync(path.join(dir, 'commands.jsonl'), JSON.stringify(['usbguard', ...args]) + '\n');
}
if (cmd === 'systemctl') { console.log(s.mode === 'stopped' ? 'inactive' : 'active'); process.exit(s.mode === 'stopped' ? 3 : 0); }
if (s.mode === 'missing') { console.error('usbguard: No such file or directory'); process.exit(127); }
if (args[0] === '--version') { console.log('usbguard 1.1.4 (test fixture)'); process.exit(0); }
if (s.mode === 'denied') { console.error('IPC connect: Permission denied'); process.exit(1); }
if (s.mode === 'stopped') { console.error('IPC connect: Connection refused'); process.exit(1); }
const record = () => `17: ${s.target} id 1234:5678 serial "test" name "Test keyboard" hash "test-hash" with-interface { 03:01:01 03:01:02 }`;
if (args[0] === 'get-parameter') console.log('block');
else if (args[0] === 'list-devices') { if (s.connected) console.log(record()); }
else if (args[0] === 'list-rules') { for (const r of s.rules) console.log(`${r.id}: ${r.target} id 1234:5678 hash "test-hash"`); }
else if (args[0] === 'watch') { console.error('Fixture watch unavailable; use fallback'); process.exit(1); }
else if (args[0] === 'remove-rule') { s.rules = s.rules.filter(r => r.id !== Number(args[1])); }
else if (['allow-device','block-device','reject-device'].includes(args[0])) {
  if (!s.connected || args.at(-1) !== '17') { console.error('No such device'); process.exit(1); }
  s.target = args[0].split('-')[0];
  if (args.includes('--permanent')) s.rules = [{id:4,target:s.target}];
  if (s.target === 'reject') s.connected = false;
} else { console.error('Unexpected test command'); process.exit(2); }
if (args[0] === 'remove-rule' || args[0].endsWith('-device')) fs.writeFileSync(statePath, JSON.stringify(s));
