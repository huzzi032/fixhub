# FixHub - On-Demand Services Marketplace

FixHub is a Flutter marketplace app for Pakistan with three roles: Customer, Provider, and Admin.

This project is now Firebase-free.

## What Changed

- Firebase dependency removed from the app.
- App authentication and user profile storage moved to local SQLite (`sqflite`) for zero-cost offline usage.
- Added an optional deployable backend in [backend/](backend/) for Vercel using SQLite-compatible libSQL (Turso free tier).

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
- Local database: SQLite (`sqflite`)
- Optional cloud backend: Vercel Serverless + libSQL/Turso

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

## Run App (Free, No Cloud Needed)

1. Install dependencies:

```bash
flutter pub get
```

2. Run app:

```bash
flutter run
```

3. Phone OTP in local mode:

- Use `123456` (development OTP).

## Optional Backend (Vercel)

The app can run fully local, but if you want deployable backend APIs:

1. Go to [backend/](backend/)
2. Install dependencies:

```bash
cd backend
npm install
```

3. Local backend dev:

```bash
npx vercel dev
```

4. Deploy backend on Vercel with env vars:

- `DATABASE_URL`
- `DATABASE_AUTH_TOKEN`
- `JWT_SECRET`

Recommended free DB: Turso (SQLite-compatible libSQL).

## Backend API Endpoints

- `GET /api/health`
- `POST /api/auth/email-signup`
- `POST /api/auth/email-signin`
- `POST /api/auth/request-otp`
- `POST /api/auth/verify-otp`
- `POST /api/users/create-profile`
- `GET /api/users/me`

## Notes

- `firestore.rules` and `firestore.indexes.json` are now legacy artifacts and not used by runtime.
- If you want real SMS OTP provider, push notifications, or LLM integrations, provide API credentials and it can be wired in next.

## Build

```bash
flutter build apk --release
flutter build appbundle --release
flutter build ios --release
```
