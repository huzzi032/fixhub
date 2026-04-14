# FixHub - On-Demand Services Marketplace

FixHub is a Flutter marketplace app for Pakistan with three roles: Customer, Provider, and Admin.

This project is now Firebase-free.

## What Changed

- Firebase dependency removed from the app.
- Core app data flows now use a deployable backend in [backend/](backend/) on Vercel with Supabase Postgres.
- Auth, user profiles, bookings, services, neighborhood deals, and chat are served through backend APIs.

## Features

### For Customers
- Browse services by category
- Search and filter services
- Book services with scheduling
- Track active jobs
- SOS emergency flow
- Neighborhood deals
- Cash on delivery flows
- Rate and review providers

### For Providers
- Online/offline toggle
- Job and lead flows
- Service management
- Wallet and earnings views

### For Admin
- Provider verification queue
- Dispute management
- Top-up approvals
- Platform overview dashboards

## Tech Stack

- Flutter 3.x
- Riverpod
- GoRouter
- Backend APIs: Vercel Serverless + Supabase Postgres
- Local device settings: SharedPreferences

## Project Structure

```
lib/
   core/
      auth/
      database/
      router/
      theme/
      constants/
      utils/
   features/
      auth/
      customer/
      provider/
      admin/
   shared/
      models/
      widgets/
backend/
   api/
   lib/
```

## Run App

1. Install dependencies:

```bash
flutter pub get
```

2. Run app with backend URL:

```bash
flutter run --dart-define=FIXHUB_API_BASE_URL=https://your-backend.vercel.app
```

3. Phone OTP in development mode:

- Use `123456` (development OTP).

## Backend (Vercel)

The app uses deployable backend APIs for multi-user shared data:

1. Go to [backend/](backend/)
2. Install dependencies:

```bash
cd backend
npm install
```

3. Local backend dev:

```bash
cd backend
npm run dev
```

No Vercel is required for local API runtime.

Temporary public URL for testing with another phone:

```bash
cd backend
npx localtunnel --port 8080
```

Build Flutter with the tunnel URL:

```bash
flutter run --dart-define=FIXHUB_API_BASE_URL=https://your-subdomain.loca.lt
```

4. Deploy backend on Vercel with env vars:

- `DATABASE_URL`
- `JWT_SECRET`

Use the exact Supabase Session Pooler URI for `DATABASE_URL` (copied from dashboard), not the direct DB host.

Recommended free DB: Supabase Postgres.

Run SQL setup once in Supabase:

- [backend/supabase/setup.sql](backend/supabase/setup.sql)

## Backend API Endpoints

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

## Notes

- `firestore.rules` and `firestore.indexes.json` are now legacy artifacts and not used by runtime.
- If you want real SMS OTP provider, push notifications, or LLM integrations, provide API credentials and it can be wired in next.

## Build

```bash
flutter build apk --release
flutter build appbundle --release
flutter build ios --release
```
