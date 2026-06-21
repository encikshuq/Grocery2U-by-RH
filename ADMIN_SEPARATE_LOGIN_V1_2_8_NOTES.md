# Grocery2U v1.2.8 - Separate Staff Admin Login

Update dibuat:

- Admin dibuang daripada user app utama.
- Admin hanya di `/admin/index.html`.
- Admin login guna username + password staf.
- Demo local admin: `admin` / `grocery2u`.
- Supabase schema ditambah:
  - `admin_users`
  - `admin_sessions`
  - `app_limits`
  - trigger maksimum 3,000 total family
  - trigger maksimum 5 family per user
  - view `admin_family_limit_monitor`

Nota production:

Admin password tidak boleh disahkan terus di frontend. Untuk production sebenar, gunakan Supabase Edge Function / backend trusted untuk verify `password_hash` dan keluarkan session token.
