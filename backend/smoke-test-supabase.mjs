import health from './api/health.js';
import signup from './api/auth/email-signup.js';
import signin from './api/auth/email-signin.js';
import requestOtp from './api/auth/request-otp.js';
import verifyOtp from './api/auth/verify-otp.js';
import createProfile from './api/users/create-profile.js';
import me from './api/users/me.js';

function createRes() {
  return {
    _status: null,
    _json: null,
    status(code) {
      this._status = code;
      return this;
    },
    json(payload) {
      this._json = payload;
      return this;
    },
  };
}

async function call(handler, { method, body = undefined, headers = {} }) {
  const req = { method, body, headers };
  const res = createRes();
  await handler(req, res);
  return { status: res._status, body: res._json };
}

function assertStatus(resp, expected, label) {
  if (resp.status !== expected) {
    throw new Error(
      `${label} failed: expected ${expected}, got ${resp.status}, body=${JSON.stringify(resp.body)}`,
    );
  }
}

const uid = Date.now();
const email = `smoke${uid}@example.com`;
const password = 'secret123';
const phone = `+92300123${String(uid).slice(-4)}`;

const healthResp = await call(health, { method: 'GET' });
assertStatus(healthResp, 200, 'health');

const signupResp = await call(signup, {
  method: 'POST',
  body: { name: 'Smoke User', email, password },
});
assertStatus(signupResp, 201, 'email-signup');

const signinResp = await call(signin, {
  method: 'POST',
  body: { email, password },
});
assertStatus(signinResp, 200, 'email-signin');

const otpReqResp = await call(requestOtp, {
  method: 'POST',
  body: { phoneNumber: phone },
});
assertStatus(otpReqResp, 200, 'request-otp');

const verificationId = otpReqResp.body?.verificationId;
const otp = otpReqResp.body?.devOtp;
if (!verificationId || !otp) {
  throw new Error(
    `request-otp missing verificationId/devOtp: ${JSON.stringify(otpReqResp.body)}`,
  );
}

const otpVerifyResp = await call(verifyOtp, {
  method: 'POST',
  body: { verificationId, otp },
});
assertStatus(otpVerifyResp, 200, 'verify-otp');

const phoneToken = otpVerifyResp.body?.token;
if (!phoneToken) {
  throw new Error(`verify-otp missing token: ${JSON.stringify(otpVerifyResp.body)}`);
}

const profileResp = await call(createProfile, {
  method: 'POST',
  headers: { authorization: `Bearer ${phoneToken}` },
  body: { name: 'Phone User', phone, role: 'customer' },
});
assertStatus(profileResp, 200, 'create-profile');

const meResp = await call(me, {
  method: 'GET',
  headers: { authorization: `Bearer ${phoneToken}` },
});
assertStatus(meResp, 200, 'users/me');

console.log('SMOKE_OK');
console.log(
  JSON.stringify(
    {
      health: healthResp.status,
      signup: signupResp.status,
      signin: signinResp.status,
      requestOtp: otpReqResp.status,
      verifyOtp: otpVerifyResp.status,
      createProfile: profileResp.status,
      me: meResp.status,
    },
    null,
    2,
  ),
);
