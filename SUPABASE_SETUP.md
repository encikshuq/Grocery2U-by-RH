# Grocery2U by RH - Supabase Setup

## 1. Run database schema
Open Supabase Dashboard > SQL Editor > New Query.
Copy everything from `supabase_schema.sql`, paste, then Run.

This creates the main tables:
- app_users
- families
- family_members
- master_categories
- master_items
- shopping_lists
- shopping_list_items
- receipts

## 2. Create Storage buckets
Open Supabase Dashboard > Storage > New bucket.
Create these buckets:
- receipts
- app-assets

Recommended:
- `receipts` should be private for production.
- `app-assets` can be public for logos/icons if needed.

## 3. Supabase URL and anon key
The project URL and anon key have been inserted into `supabase-config.js`.
Do not put the Supabase `service_role` key in frontend files.

## 4. Current app mode
This v1.1 UI currently runs using browser localStorage demo data.
The Supabase schema/config is ready for the next step: connecting login, family, shopping list, receipts and claim to live Supabase data.
