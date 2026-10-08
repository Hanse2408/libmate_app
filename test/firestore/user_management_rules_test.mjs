import assert from 'node:assert/strict';

// Run with:
// firebase emulators:exec --config firebase.user-management-tests.json --project demo-libmate --only firestore "node test/firestore/user_management_rules_test.mjs"
const project = 'demo-libmate';
const host = process.env.FIRESTORE_EMULATOR_HOST;
assert.ok(host, 'Run this test inside firebase emulators:exec.');
const base = `http://${host}/v1/projects/${project}/databases/(default)/documents`;
function token(uid) {
  const now = Math.floor(Date.now() / 1000);
  const enc = (value) => Buffer.from(JSON.stringify(value)).toString('base64url');
  return `${enc({ alg: 'none', typ: 'JWT' })}.${enc({
    sub: uid, user_id: uid, aud: project, iss: `https://securetoken.google.com/${project}`,
    iat: now, exp: now + 3600, auth_time: now,
    firebase: { sign_in_provider: 'password', identities: {} },
  })}.`;
}
function fields(data) {
  return Object.fromEntries(Object.entries(data).map(([key, value]) =>
    [key, value === null ? { nullValue: null } : { stringValue: value }]));
}
async function write(uid, data, actor = 'owner', keys = null) {
  const query = keys ? '?' + keys.map(k => `updateMask.fieldPaths=${k}`).join('&') : '';
  return fetch(`${base}/users/${uid}${query}`, {
    method: 'PATCH', headers: { Authorization: `Bearer ${actor === 'owner' ? 'owner' : token(actor)}`,
      'Content-Type': 'application/json' }, body: JSON.stringify({ fields: fields(data) }),
  });
}
async function allowed(response, description) {
  assert.equal(response.status, 200, `${description}: ${await response.text()}`);
}
async function denied(response, description) {
  assert.equal(response.status, 403, `${description}: ${await response.text()}`);
}
const profile = (uid, role = 'student', status = 'active') => ({
  uid, name: 'Test User', email: `${uid}@test.com`, role, accountStatus: status, studentId: 'ID123',
});
await fetch(`http://${host}/emulator/v1/projects/${project}/databases/(default)/documents`, { method: 'DELETE' });
for (const [uid, role] of [['manager', 'manager'], ['librarian', 'librarian'], ['student', 'student']]) {
  await allowed(await write(uid, profile(uid, role)), `seed ${uid}`);
}
for (const role of ['student', 'librarian', 'manager']) {
  await allowed(await write(`new-${role}`, profile(`new-${role}`, role), 'manager'), `Manager creates ${role}`);
  await denied(await write(`bad-${role}`, profile(`bad-${role}`, role), 'librarian'), `Librarian cannot create ${role}`);
}
await allowed(await write('signup', profile('signup'), 'signup'), 'self signup creates active student');
await denied(await write('promote', profile('promote', 'manager'), 'promote'), 'self signup cannot be manager');
await denied(await write('staff-signup', profile('staff-signup', 'librarian'), 'staff-signup'), 'self signup cannot be librarian');
await denied(await write('disabled-signup', profile('disabled-signup', 'student', 'inactive'), 'disabled-signup'), 'signup cannot create inactive profile');
await denied(await write('mismatch', profile('wrong-uid'), 'manager'), 'UID must match document ID');
await denied(await write('bad-role', profile('bad-role', 'admin'), 'manager'), 'invalid roles denied');

await allowed(await write('student', { accountStatus: 'inactive' }, 'manager', ['accountStatus']), 'Manager deactivates other');
await allowed(await write('student', { accountStatus: 'active' }, 'manager', ['accountStatus']), 'Manager activates other');
await denied(await write('student', { accountStatus: 'suspended' }, 'manager', ['accountStatus']), 'Manager cannot write legacy suspended');
await denied(await write('manager', { accountStatus: 'inactive' }, 'manager', ['accountStatus']), 'Manager cannot deactivate self');
await denied(await write('manager', { role: 'student' }, 'manager', ['role']), 'Manager cannot change own role');
await denied(await write('student', { role: 'manager' }, 'student', ['role']), 'Student cannot change own role');
await denied(await write('student', { accountStatus: 'inactive' }, 'student', ['accountStatus']), 'Student cannot change own status');
await denied(await write('student', { uid: 'changed' }, 'student', ['uid']), 'Student cannot change UID');
await denied(await write('student', { role: 'manager' }, 'librarian', ['role']), 'Librarian cannot change role');
await denied(await write('student', { accountStatus: 'inactive' }, 'librarian', ['accountStatus']), 'Librarian cannot deactivate');
await write('student', { accountStatus: 'inactive' }, 'owner', ['accountStatus']);
await denied(await write('student', { accountStatus: 'active' }, 'librarian', ['accountStatus']), 'Librarian cannot activate');
await allowed(await write('student', { name: 'Edited', role: 'librarian', studentId: 'STAFF123' }, 'manager', ['name', 'role', 'studentId']), 'Manager edits name role ID');
await denied(await write('student', { email: 'changed@test.com' }, 'manager', ['email']), 'Manager cannot change Firestore-only email');
await allowed(await write('manager', { name: 'Renamed' }, 'manager', ['name']), 'Manager may edit own name');
await write('student', profile('student'), 'owner');
await allowed(await write('student', { name: 'Self edit' }, 'student', ['name']), 'Normal profile editing preserved');
await write('legacy', profile('legacy', 'student', 'suspended'), 'owner');
await allowed(await write('legacy', { name: 'Legacy edit' }, 'manager', ['name']), 'Edit legacy profile without writing status');
await allowed(await write('legacy', { accountStatus: 'active' }, 'manager', ['accountStatus']), 'Activate legacy suspended account');
const deletion = await fetch(`${base}/users/student`, {
  method: 'DELETE', headers: { Authorization: `Bearer ${token('manager')}` },
});
await denied(deletion, 'No Manager Delete User');
await fetch(`${base}/seats/test-seat`, {
  method: 'PATCH', headers: { Authorization: 'Bearer owner', 'Content-Type': 'application/json' },
  body: JSON.stringify({ fields: fields({ seatNumber: 'A01' }) }),
});
for (const [uid, status] of [['active-student', 'active'], ['inactive-student', 'inactive'], ['legacy-student', 'suspended']]) {
  await write(uid, profile(uid, 'student', status));
  const response = await fetch(`${base}/reservations/${uid}`, {
    method: 'PATCH', headers: { Authorization: `Bearer ${token(uid)}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields: fields({ studentUid: uid, type: 'seat', status: 'approved', itemId: 'test-seat' }) }),
  });
  if (status === 'active') await allowed(response, 'active student eligibility');
  else await denied(response, `${status} student must not qualify as active`);
}
console.log('User management Firestore rules: all checks passed.');
