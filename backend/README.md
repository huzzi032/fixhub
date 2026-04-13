# FixHub Backend (Vercel + SQLite-Compatible)

This backend is designed for free deployment on Vercel using a SQLite-compatible database.

## Why libSQL/Turso

Vercel serverless functions do not provide persistent writable local disk, so plain local `sqlite3` files are not durable in production.

Turso provides a free SQLite-compatible hosted database (`libSQL`) and works well with Vercel.

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
- `DATABASE_AUTH_TOKEN`
- `JWT_SECRET`

Optional:
- `FIXHUB_DEV_OTP` (defaults to `123456`)

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
