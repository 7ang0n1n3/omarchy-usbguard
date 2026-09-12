const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const p = vm.createContext({});
vm.runInContext(fs.readFileSync(__dirname + '/../services/UsbGuardParser.js', 'utf8'), p);
let count = 0;
function test(name, fn) { fn(); count++; console.log('PASS ' + name); }
const record = '23: block id 0b38:0010 serial "a b" name "Keyboard \\"quoted\\"" hash "abc=" with-interface { 03:01:01 03:01:02 03:00:00 }';
test('quoted names, serials, composite HID and status', () => {
  const d = p.parse(record, 'device')[0];
  assert.equal(d.name, 'Keyboard "quoted"'); assert.equal(d.serial, 'a b');
  assert.equal(d.status, 'Blocked'); assert.ok(d.keyboard && d.mouse && d.composite);
  assert.match(p.warning(d), /prevent you from controlling/);
});
test('hash cannot be confused with parent-hash', () => {
  assert.equal(p.parse('1: allow parent-hash "parent" hash "child"', 'rule')[0].hash, 'child');
});
test('set operators and wildcard rules remain policy records', () => {
  const d = p.parse('2: reject id *:* with-interface all-of { 03:*:* 08:*:* }', 'rule')[0];
  assert.equal(d.usbId, '*:*'); assert.equal(d.connected, false); assert.ok(d.hid);
});
test('unknown targets and empty output', () => { assert.equal(p.parse('9: match id 1234:5678', 'rule')[0].status, 'Unknown'); assert.equal(p.parse('', 'device').length, 0); });
test('malformed output is rejected instead of showing an empty success', () => assert.throws(() => p.parse('bad record', 'device')));
test('search spans IDs, serial, manufacturer and name', () => {
  const d = p.parse(record, 'device')[0]; d.manufacturer = 'Example';
  for (const q of ['0010', '0b38', '23', 'a b', 'EXAMPLE', 'keyboard']) assert.ok(p.search(d, q));
});
test('temporary and persistent argv are separate', () => {
  const d = p.parse(record, 'device')[0];
  assert.equal(JSON.stringify(p.command('allow', d)), '["usbguard","allow-device","23"]');
  assert.equal(JSON.stringify(p.command('alwaysBlock', d)), '["usbguard","block-device","--permanent","23"]');
  assert.equal(JSON.stringify(p.command('reject', d)), '["usbguard","reject-device","23"]');
});
test('rule IDs cannot accidentally become device actions', () => {
  const r = p.parse('4: allow id *:*', 'rule')[0];
  assert.throws(() => p.command('block', r));
  assert.equal(JSON.stringify(p.command('remove', r)), '["usbguard","remove-rule","4"]');
});
test('shell metacharacters in IDs are rejected', () => assert.throws(() => p.command('allow', {id:'1; touch /tmp/no',kind:'device'})));
test('hubs and generic HID require lockout warnings', () => {
  assert.match(p.warning(p.parse('1: allow with-interface 09:00:00', 'device')[0]), /all devices/);
  assert.match(p.warning(p.parse('2: allow with-interface 03:00:00', 'device')[0]), /security key/);
});
test('permission and disconnect errors are readable', () => {
  assert.match(p.humanError('IPC connect: Operation not permitted'), /Permission denied/);
  assert.match(p.humanError('No such device'), /no longer available/);
});
console.log(`${count} parser and safety tests passed`);
