import health from './api/health.js';
import signup from './api/auth/email-signup.js';
import signin from './api/auth/email-signin.js';
import requestOtp from './api/auth/request-otp.js';
import verifyOtp from './api/auth/verify-otp.js';
import createProfile from './api/users/create-profile.js';
import me from './api/users/me.js';
import providerStatus from './api/users/provider-status.js';
import getSavedAddresses from './api/users/saved-addresses.js';
import addSavedAddress from './api/users/add-saved-address.js';
import removeSavedAddress from './api/users/remove-saved-address.js';
import bookings from './api/bookings.js';
import marketplace from './api/marketplace.js';

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

async function call(
  handler,
  { method, body = undefined, headers = {}, query = undefined, url = undefined },
) {
  const req = { method, body, headers, query, url };
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

const providerStatusResp = await call(providerStatus, {
  method: 'GET',
  headers: { authorization: `Bearer ${phoneToken}` },
});
assertStatus(providerStatusResp, 200, 'users/provider-status');

const addAddressResp = await call(addSavedAddress, {
  method: 'POST',
  headers: { authorization: `Bearer ${phoneToken}` },
  body: { label: 'Home', address: 'Street 1, Karachi' },
});
assertStatus(addAddressResp, 200, 'users/add-saved-address');

const listAddressesResp = await call(getSavedAddresses, {
  method: 'GET',
  headers: { authorization: `Bearer ${phoneToken}` },
});
assertStatus(listAddressesResp, 200, 'users/saved-addresses');

const createdAddressId = addAddressResp.body?.savedAddress?.id;
if (!createdAddressId) {
  throw new Error(
    `add-saved-address missing savedAddress.id: ${JSON.stringify(addAddressResp.body)}`,
  );
}

const removeAddressResp = await call(removeSavedAddress, {
  method: 'POST',
  headers: { authorization: `Bearer ${phoneToken}` },
  body: { addressId: createdAddressId },
});
assertStatus(removeAddressResp, 200, 'users/remove-saved-address');

const bookingCreateResp = await call(bookings, {
  method: 'POST',
  headers: { authorization: `Bearer ${phoneToken}` },
  body: {
    action: 'createBooking',
    customerId: otpVerifyResp.body.user.uid,
    serviceCategory: 'plumber',
    issueTitle: 'Leaking tap',
    issueDescription: 'Kitchen tap leaking continuously',
    address: 'Street 7, Lahore',
    scheduledAt: Date.now() + 2 * 60 * 60 * 1000,
    isSOS: false,
  },
});
assertStatus(bookingCreateResp, 200, 'bookings/createBooking');

const createdBookingId = bookingCreateResp.body?.bookingId;
if (!createdBookingId) {
  throw new Error(
    `createBooking missing bookingId: ${JSON.stringify(bookingCreateResp.body)}`,
  );
}

const bookingGetResp = await call(bookings, {
  method: 'GET',
  headers: { authorization: `Bearer ${phoneToken}` },
  query: { action: 'getById', bookingId: createdBookingId },
});
assertStatus(bookingGetResp, 200, 'bookings/getById');

const customerBookingsResp = await call(bookings, {
  method: 'GET',
  headers: { authorization: `Bearer ${phoneToken}` },
  query: {
    action: 'getCustomerBookings',
    customerId: otpVerifyResp.body.user.uid,
  },
});
assertStatus(customerBookingsResp, 200, 'bookings/getCustomerBookings');

const sendMessageResp = await call(bookings, {
  method: 'POST',
  headers: { authorization: `Bearer ${phoneToken}` },
  body: {
    action: 'sendMessage',
    bookingId: createdBookingId,
    senderId: otpVerifyResp.body.user.uid,
    message: 'Hello, need urgent help',
  },
});
assertStatus(sendMessageResp, 200, 'bookings/sendMessage');

const messagesResp = await call(bookings, {
  method: 'GET',
  headers: { authorization: `Bearer ${phoneToken}` },
  query: { action: 'getMessages', bookingId: createdBookingId },
});
assertStatus(messagesResp, 200, 'bookings/getMessages');

const markReadResp = await call(bookings, {
  method: 'POST',
  headers: { authorization: `Bearer ${phoneToken}` },
  body: {
    action: 'markMessagesRead',
    bookingId: createdBookingId,
    viewerId: otpVerifyResp.body.user.uid,
  },
});
assertStatus(markReadResp, 200, 'bookings/markMessagesRead');

const searchServicesResp = await call(marketplace, {
  method: 'GET',
  headers: { authorization: `Bearer ${phoneToken}` },
  query: { action: 'searchServices', query: '', minPrice: '0', maxPrice: '5000' },
});
assertStatus(searchServicesResp, 200, 'marketplace/searchServices');

const featuredDealsResp = await call(marketplace, {
  method: 'GET',
  headers: { authorization: `Bearer ${phoneToken}` },
  query: { action: 'getFeaturedDeals', userId: otpVerifyResp.body.user.uid, limit: '3' },
});
assertStatus(featuredDealsResp, 200, 'marketplace/getFeaturedDeals');

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
      providerStatus: providerStatusResp.status,
      addSavedAddress: addAddressResp.status,
      getSavedAddresses: listAddressesResp.status,
      removeSavedAddress: removeAddressResp.status,
      createBooking: bookingCreateResp.status,
      getBooking: bookingGetResp.status,
      getCustomerBookings: customerBookingsResp.status,
      sendMessage: sendMessageResp.status,
      getMessages: messagesResp.status,
      markMessagesRead: markReadResp.status,
      searchServices: searchServicesResp.status,
      getFeaturedDeals: featuredDealsResp.status,
    },
    null,
    2,
  ),
);
