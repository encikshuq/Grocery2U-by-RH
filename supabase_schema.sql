-- Grocery2U by RH v1.2.6 Supabase schema
create extension if not exists pgcrypto;
create table if not exists app_users (
  id uuid primary key default gen_random_uuid(),
  username text unique not null,
  pin_hash text not null,
  full_name text,
  created_at timestamptz default now()
);
create table if not exists families (
  id uuid primary key default gen_random_uuid(),
  family_name text not null,
  created_by uuid references app_users(id),
  invite_code text unique,
  created_at timestamptz default now()
);
create table if not exists family_members (
  id uuid primary key default gen_random_uuid(),
  family_id uuid references families(id) on delete cascade,
  user_id uuid references app_users(id) on delete cascade,
  role text default 'member',
  nickname text,
  status text default 'active',
  created_at timestamptz default now(),
  unique(family_id,user_id)
);
create table if not exists master_categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references app_users(id) on delete cascade,
  name text not null,
  sort_order int default 0,
  is_active boolean default true
);
create table if not exists master_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references app_users(id) on delete cascade,
  category_id uuid references master_categories(id),
  item_name text not null,
  default_unit text,
  is_active boolean default true,
  created_at timestamptz default now()
);
create table if not exists shopping_lists (
  id uuid primary key default gen_random_uuid(),
  family_id uuid references families(id) on delete cascade,
  title text not null,
  created_by_user_id uuid references app_users(id),
  assigned_to_user_id uuid references app_users(id),
  status text default 'draft',
  created_at timestamptz default now(),
  completed_at timestamptz
);
create table if not exists shopping_list_items (
  id uuid primary key default gen_random_uuid(),
  list_id uuid references shopping_lists(id) on delete cascade,
  master_item_id uuid references master_items(id),
  item_name text not null,
  category_name text,
  quantity text,
  note text,
  status text default 'requested',
  replacement_name text,
  updated_at timestamptz default now()
);
create table if not exists receipts (
  id uuid primary key default gen_random_uuid(),
  family_id uuid references families(id) on delete cascade,
  list_id uuid references shopping_lists(id),
  paid_by_user_id uuid references app_users(id),
  store_name text,
  receipt_date date default current_date,
  total_amount numeric(10,2) default 0,
  receipt_file_url text,
  original_file_path text,
  preview_file_path text,
  file_name text,
  mime_type text,
  file_size_bytes bigint default 0,
  claim_status text default 'unpaid',
  claim_paid_at timestamptz,
  created_at timestamptz default now()
);
-- For production, enable RLS and create policies based on family_members.


-- Receipt storage bucket
insert into storage.buckets (id, name, public)
values ('receipts', 'receipts', false)
on conflict (id) do nothing;

-- Suggested path format:
-- receipts/{family_id}/{yyyy}/{mm}/receipt_{receipt_id}.webp
-- Store the file path in receipts.original_file_path / preview_file_path.


-- Admin monitor view for registration dashboard
create or replace view admin_register_monitor as
select
  u.id as user_id,
  u.username,
  u.full_name,
  u.created_at as registered_at,
  count(distinct f.id) as family_created_count,
  count(distinct fm.family_id) as family_joined_count
from app_users u
left join families f on f.created_by = u.id
left join family_members fm on fm.user_id = u.id
group by u.id, u.username, u.full_name, u.created_at;

-- Production note: restrict this view to admin users only with RLS/policies.

-- Grocery2U by RH v1.2.8 Admin staff + production limits
-- Run this section after the base schema. Review policies before public launch.

create table if not exists admin_users (
  id uuid primary key default gen_random_uuid(),
  username text unique not null,
  password_hash text not null,
  full_name text,
  role text not null default 'staff' check (role in ('super_admin','staff','support')),
  is_active boolean not null default true,
  created_at timestamptz default now(),
  last_login_at timestamptz
);

create table if not exists admin_sessions (
  id uuid primary key default gen_random_uuid(),
  admin_user_id uuid references admin_users(id) on delete cascade,
  session_token_hash text not null,
  ip_address text,
  user_agent text,
  created_at timestamptz default now(),
  expires_at timestamptz not null,
  revoked_at timestamptz
);

create table if not exists app_limits (
  key text primary key,
  value_int int not null,
  description text,
  updated_at timestamptz default now()
);

insert into app_limits (key, value_int, description)
values
  ('max_total_families', 3000, 'Initial production cap for Grocery2U families'),
  ('max_families_per_user', 5, 'Maximum family created/joined by one user')
on conflict (key) do update set value_int = excluded.value_int, updated_at = now();

create or replace function grocery2u_check_family_create_limit()
returns trigger as $$
declare
  total_limit int;
  per_user_limit int;
  total_count int;
  user_created_count int;
begin
  select value_int into total_limit from app_limits where key = 'max_total_families';
  select value_int into per_user_limit from app_limits where key = 'max_families_per_user';

  select count(*) into total_count from families;
  if total_count >= coalesce(total_limit, 3000) then
    raise exception 'Grocery2U family registration limit reached: % families', coalesce(total_limit, 3000);
  end if;

  select count(*) into user_created_count from families where created_by = new.created_by;
  if user_created_count >= coalesce(per_user_limit, 5) then
    raise exception 'User family creation limit reached: % families', coalesce(per_user_limit, 5);
  end if;

  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_grocery2u_check_family_create_limit on families;
create trigger trg_grocery2u_check_family_create_limit
before insert on families
for each row execute function grocery2u_check_family_create_limit();

create or replace function grocery2u_check_family_membership_limit()
returns trigger as $$
declare
  per_user_limit int;
  joined_count int;
begin
  select value_int into per_user_limit from app_limits where key = 'max_families_per_user';
  select count(*) into joined_count from family_members where user_id = new.user_id and status = 'active';
  if joined_count >= coalesce(per_user_limit, 5) then
    raise exception 'User family membership limit reached: % active families', coalesce(per_user_limit, 5);
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_grocery2u_check_family_membership_limit on family_members;
create trigger trg_grocery2u_check_family_membership_limit
before insert on family_members
for each row execute function grocery2u_check_family_membership_limit();

create or replace view admin_family_limit_monitor as
select
  (select count(*) from families) as total_families,
  (select value_int from app_limits where key = 'max_total_families') as max_total_families,
  round(((select count(*) from families)::numeric / nullif((select value_int from app_limits where key = 'max_total_families'),0)) * 100, 2) as used_percent,
  (select count(*) from app_users) as total_users,
  (select count(*) from receipts) as total_receipts;

-- Recommended production security:
-- 1. Enable RLS on admin_users/admin_sessions.
-- 2. Never expose password_hash to browser clients.
-- 3. Use Supabase Edge Function or trusted backend to verify admin password.
-- 4. Only staff admin dashboard should read admin_* views.
