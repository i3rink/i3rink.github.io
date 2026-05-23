-- ============================================================
-- Fairway — Supabase Schema
-- Run this in the Supabase SQL editor to initialise your database
-- ============================================================

-- Users
create table if not exists users (
  id uuid primary key default gen_random_uuid(),
  email text unique not null,
  full_name text,
  home_course text,
  handicap numeric(4,1),
  handicap_verified boolean default false,
  points_balance integer default 0,
  created_at timestamptz default now()
);

-- Courses
create table if not exists courses (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique not null,
  location text,
  lat numeric(9,6),
  lng numeric(9,6),
  holes integer default 18,
  par integer,
  tier text check (tier in ('basic','partner','premium')) default 'basic',
  active boolean default true,
  created_at timestamptz default now()
);

-- Seed Western Gailes
insert into courses (name, slug, location, lat, lng, holes, par, tier)
values ('Western Gailes Golf Club', 'western-gailes', 'Gailes, Irvine, KA11 5AE', 55.5847, -4.6823, 18, 71, 'partner')
on conflict (slug) do nothing;

-- Rounds logged (conditions submissions)
create table if not exists rounds_logged (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete set null,
  course_id uuid references courses(id) on delete cascade,
  -- Context
  tees_played text,
  time_of_day text check (time_of_day in ('morning','afternoon','evening')),
  weather text,
  pace_of_play text,
  -- Greens (1–5)
  greens_speed integer check (greens_speed between 1 and 5),
  greens_firmness integer check (greens_firmness between 1 and 5),
  greens_surface integer check (greens_surface between 1 and 5),
  -- Fairways (1–5)
  fairway_condition integer check (fairway_condition between 1 and 5),
  fairway_firmness integer check (fairway_firmness between 1 and 5),
  -- Other (1–5)
  rough integer check (rough between 1 and 5),
  bunkers integer check (bunkers between 1 and 5),
  overall integer check (overall between 1 and 5),
  -- Free text
  greenkeeper_note text,
  note_moderated boolean default false,
  note_published boolean default false,
  -- Metadata
  points_awarded integer default 0,
  submitted_at timestamptz default now(),
  -- Integrity flags
  anonymous boolean default false,
  device_fingerprint text,
  flagged boolean default false,
  flag_reason text
);

-- Points ledger
create table if not exists points_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  points integer not null,
  transaction_type text check (transaction_type in (
    'round_logged','first_course','monthly_bonus','referral',
    'handicap_multiplier','voucher_redeemed','expiry','adjustment'
  )),
  description text,
  round_id uuid references rounds_logged(id) on delete set null,
  created_at timestamptz default now(),
  expires_at timestamptz default (now() + interval '12 months')
);

-- Vouchers
create table if not exists vouchers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  course_id uuid references courses(id) on delete cascade,
  value_gbp numeric(6,2) not null,
  points_cost integer not null,
  code text unique not null default upper(substring(gen_random_uuid()::text, 1, 8)),
  status text check (status in ('active','redeemed','expired')) default 'active',
  issued_at timestamptz default now(),
  redeemed_at timestamptz,
  expires_at timestamptz default (now() + interval '12 months')
);

-- ============================================================
-- Useful views
-- ============================================================

-- Course conditions summary (last 30 days)
create or replace view course_conditions_summary as
select
  c.id as course_id,
  c.name as course_name,
  c.slug,
  count(r.id) as submission_count,
  round(avg(r.greens_speed)::numeric, 1) as avg_greens_speed,
  round(avg(r.greens_firmness)::numeric, 1) as avg_greens_firmness,
  round(avg(r.greens_surface)::numeric, 1) as avg_greens_surface,
  round(avg(r.fairway_condition)::numeric, 1) as avg_fairway_condition,
  round(avg(r.fairway_firmness)::numeric, 1) as avg_fairway_firmness,
  round(avg(r.rough)::numeric, 1) as avg_rough,
  round(avg(r.bunkers)::numeric, 1) as avg_bunkers,
  round(avg(r.overall)::numeric, 1) as avg_overall,
  max(r.submitted_at) as last_submission
from courses c
left join rounds_logged r
  on r.course_id = c.id
  and r.submitted_at > now() - interval '30 days'
  and r.flagged = false
group by c.id, c.name, c.slug;

-- Weekly trend (last 6 weeks) for a given course
create or replace view course_weekly_trend as
select
  c.slug as course_slug,
  date_trunc('week', r.submitted_at) as week_start,
  count(r.id) as submissions,
  round(avg(r.overall)::numeric, 2) as avg_overall,
  round(avg(r.greens_speed)::numeric, 2) as avg_greens,
  round(avg(r.fairway_condition)::numeric, 2) as avg_fairways
from rounds_logged r
join courses c on c.id = r.course_id
where r.submitted_at > now() - interval '6 weeks'
  and r.flagged = false
group by c.slug, date_trunc('week', r.submitted_at)
order by week_start;

-- ============================================================
-- Row Level Security
-- ============================================================

alter table users enable row level security;
alter table rounds_logged enable row level security;
alter table points_ledger enable row level security;
alter table vouchers enable row level security;

-- Users can read and update their own row
create policy "users_own" on users
  for all using (auth.uid() = id);

-- Anyone can read non-flagged rounds (for public conditions card)
create policy "rounds_public_read" on rounds_logged
  for select using (flagged = false);

-- Authenticated users can insert their own rounds
create policy "rounds_insert" on rounds_logged
  for insert with check (auth.uid() = user_id);

-- Users can read their own points
create policy "points_own_read" on points_ledger
  for select using (auth.uid() = user_id);

-- Users can read their own vouchers
create policy "vouchers_own_read" on vouchers
  for select using (auth.uid() = user_id);
