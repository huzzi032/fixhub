# FixHub Backend (Vercel + Supabase Postgres)

This backend is designed for free deployment on Vercel using Supabase Postgres.

## Endpoints

- `GET /api/health`
- `POST /api/auth/email-signup`
- `POST /api/auth/email-signin`
- `POST /api/auth/request-otp`
- `POST /api/auth/verify-otp`
- `POST /api/users/create-profile`
- `GET /api/users/me`
- `GET /api/users/provider-status`
- `GET /api/users/saved-addresses`
- `POST /api/users/add-saved-address`
- `POST /api/users/remove-saved-address`
- `GET /api/bookings?action=...`
- `POST /api/bookings` with `action`
- `GET /api/marketplace?action=...`
- `POST /api/marketplace` with `action`

### Booking Actions

- `getById`
- `getCustomerBookings`
- `getProviderActiveBookings`
- `getProviderJobs`
- `getIncomingLeads`
- `getProviderWalletBalance`
- `getProviderEarnings`
- `getMessages`
- `createBooking`
- `acceptLead`
- `updateBookingStatus`
- `markPaymentCollected`
- `topUpWallet`
- `submitReview`
- `sendMessage`
- `markMessagesRead`

### Marketplace Actions

- `searchServices`
- `getServicesByCategory`
- `getProviderServices`
- `getServiceById`
- `getDeals`
- `getFeaturedDeals`
- `saveProviderService`
- `setServiceActive`
- `deleteService`
- `createDeal`
- `joinDeal`
- `leaveDeal`

## Environment Variables

Copy `.env.example` to `.env.local` for local development.

Required for production:
- `DATABASE_URL`
- `JWT_SECRET`

Optional:
- `DATABASE_SSL` (defaults to `true`)

Optional:
- `FIXHUB_DEV_OTP` (defaults to `123456`)

## Supabase Connection Setup

1. Open Supabase project settings and copy the Session Pooler connection string.
2. Keep the copied username and host exactly as shown in Supabase.
3. URL-encode your password before placing it in `DATABASE_URL`.
4. Keep SSL enabled (`DATABASE_SSL=true`) for production.
5. Run [backend/supabase/setup.sql](supabase/setup.sql) in Supabase SQL Editor.

Do not manually guess the host/user format. Supabase pooler formats vary by project and pooler mode, so always use the exact values copied from your dashboard.

Example template:

```bash
DATABASE_URL=postgresql://[USERNAME_FROM_DASHBOARD]:myPassword%21with%3Fchars@[POOLER_HOST_FROM_DASHBOARD]:6543/postgres
```

## Local Run

```bash
cd backend
npm install
npx vercel dev
```

## Deploy on Vercel

1. Create a new Vercel project from the `backend` folder.
2. Set environment variables from `.env.example`.
3. Deploy.

## Notes

- In development mode, `request-otp` returns `devOtp` in the response.
- In production mode, `devOtp` is not returned.
