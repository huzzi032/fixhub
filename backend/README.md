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
2. URL-encode your password before placing it in `DATABASE_URL`.
3. Keep SSL enabled (`DATABASE_SSL=true`) for production.

Example with encoded password:

```bash
DATABASE_URL=postgresql://postgres:myPassword%21with%3Fchars@aws-0-your-region.pooler.supabase.com:6543/postgres
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
