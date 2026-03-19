# Admin CRM & S3 uploads

## Database: create an admin user

After migrations run, insert at least one admin phone (E.164 style, matching app input normalization):

```sql
INSERT INTO admins (id, phone, name, status)
VALUES (
  gen_random_uuid(),
  '+919876543210',
  'Temple Admin',
  'active'
);
```

Use your real admin number. OTP login only works for rows in `admins` with `status = 'active'`.

## Environment variables

| Variable | Purpose |
|----------|---------|
| `DATABASE_URL` | Postgres connection (required) |
| `ADMIN_OTP_PEPPER` | Secret pepper for admin OTP hashing (prod required) |
| `S3_BUCKET` | Bucket name for presigned uploads |
| `AWS_REGION` | e.g. `ap-south-1` |
| `AWS_ACCESS_KEY_ID` | IAM key allowed to `s3:PutObject` on the prefix |
| `AWS_SECRET_ACCESS_KEY` | IAM secret |
| `S3_ENDPOINT` | Optional; for MinIO / path-style (e.g. `http://127.0.0.1:9000`) |
| `MEDIA_PUBLIC_BASE_URL` | Optional; if set, presign response `public_url` is `{base}/{key}` (CDN). Else default AWS virtual-hosted URL. |

## Security notes

- All `/api/admin/*` routes except `request-otp`, `verify-otp` require `Authorization: Bearer <token>`.
- Dev OTP is returned in JSON from `POST /api/admin/request-otp` (same pattern as membership).
- **User prasad edits:** `PATCH /api/prasad/order/{reference_id}` requires a `phone` field matching the order’s phone (prevents blind updates by reference id only).
- **Order status** changes for fulfillment use `PATCH /api/admin/prasad/order/{reference_id}` with admin session.

## Manual QA checklist

1. Insert admin row → request OTP → verify → `GET /api/admin/me` with token.
2. Presign → PUT file to `upload_url` with same `Content-Type` → object appears in bucket → save `public_url` via admin gallery create.
3. Public app: gallery lists new item; video items open external player.
4. Admin: patch live darshan → public Live Darshan screen shows live badge when `is_live` + `stream_url` set.
5. Admin: change prasad order status → list reflects after refresh.
