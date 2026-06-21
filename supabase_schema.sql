-- DapurList v1.1 Supabase schema
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
  claim_status text default 'unpaid',
  claim_paid_at timestamptz,
  created_at timestamptz default now()
);
-- For production, enable RLS and create policies based on family_members.
