import dotenv from 'dotenv';
import express from 'express';

dotenv.config({ path: '.env.local' });
dotenv.config();

const [
  { default: health },
  { default: emailSignup },
  { default: emailSignin },
  { default: requestOtp },
  { default: verifyOtp },
  { default: createProfile },
  { default: me },
  { default: providerStatus },
  { default: savedAddresses },
  { default: addSavedAddress },
  { default: removeSavedAddress },
  { default: bookings },
  { default: marketplace },
] = await Promise.all([
  import('./api/health.js'),
  import('./api/auth/email-signup.js'),
  import('./api/auth/email-signin.js'),
  import('./api/auth/request-otp.js'),
  import('./api/auth/verify-otp.js'),
  import('./api/users/create-profile.js'),
  import('./api/users/me.js'),
  import('./api/users/provider-status.js'),
  import('./api/users/saved-addresses.js'),
  import('./api/users/add-saved-address.js'),
  import('./api/users/remove-saved-address.js'),
  import('./api/bookings.js'),
  import('./api/marketplace.js'),
]);

const app = express();
app.use(express.json({ limit: '1mb' }));

// Keep CORS open for mobile/web clients during self-hosting.
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'Content-Type, Authorization, Accept',
  );
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');

  if (req.method === 'OPTIONS') {
    return res.status(204).end();
  }

  return next();
});

function wrap(handler) {
  return async (req, res) => {
    try {
      await handler(req, res);
    } catch (error) {
      console.error(error);
      return res.status(500).json({
        error: 'Internal server error.',
      });
    }
  };
}

app.get('/api/health', wrap(health));

app.post('/api/auth/email-signup', wrap(emailSignup));
app.post('/api/auth/email-signin', wrap(emailSignin));
app.post('/api/auth/request-otp', wrap(requestOtp));
app.post('/api/auth/verify-otp', wrap(verifyOtp));

app.post('/api/users/create-profile', wrap(createProfile));
app.get('/api/users/me', wrap(me));
app.get('/api/users/provider-status', wrap(providerStatus));
app.get('/api/users/saved-addresses', wrap(savedAddresses));
app.post('/api/users/add-saved-address', wrap(addSavedAddress));
app.post('/api/users/remove-saved-address', wrap(removeSavedAddress));

app.get('/api/bookings', wrap(bookings));
app.post('/api/bookings', wrap(bookings));

app.get('/api/marketplace', wrap(marketplace));
app.post('/api/marketplace', wrap(marketplace));

app.use((req, res) => {
  return res.status(404).json({ error: `Route not found: ${req.method} ${req.path}` });
});

const port = Number(process.env.PORT || 8080);
app.listen(port, '0.0.0.0', () => {
  console.log(`FixHub API running on http://0.0.0.0:${port}`);
});
