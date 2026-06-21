# Grocery2U by RH v1.2.7 Admin Dashboard

Update:
- Added Admin tab for register monitoring.
- Shows total registered users, registrations today, total family, members, shopping lists, receipts.
- Shows family limit usage: max 5 family per user.
- Added recent registrations and latest families list.
- Added Supabase admin_register_monitor view in supabase_schema.sql.

Production note:
The Admin page is a UI foundation. For live Supabase production, restrict access to admin users only and enable RLS policies.
