-- =====================================================================
-- Baby Care — Supabase Schema (Faz 1)
-- =====================================================================
-- Bu dosyayı Supabase Dashboard → SQL Editor üzerinde sırasıyla çalıştırın.
-- Tek parça olarak çalıştırılabilir.
--
-- Kapsam:
--   - profiles            : auth.users 1:1 eşleşmesi (display_name, foto)
--   - households          : aile/ev birimi
--   - household_members   : household ↔ user üyelik (rol)
--   - household_invites   : 6 haneli davet kodları
--   - babies              : bebek profili
--
-- Tüm tablolarda:
--   - id          : uuid (uygulamadan üretilir — offline yazım için)
--   - created_at  : timestamptz default now()
--   - updated_at  : timestamptz default now()  (trigger ile güncellenir)
--   - deleted_at  : timestamptz null            (soft delete)
-- =====================================================================

-- ---------- Ön Hazırlık ----------
create extension if not exists "uuid-ossp";
create extension if not exists pgcrypto;

-- updated_at otomatik güncelleme tetikleyicisi
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- =====================================================================
-- 1) PROFILES
-- =====================================================================
create table if not exists public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  photo_url    text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- Yeni auth.users satırı eklendiğinde profiles satırı otomatik açılsın
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data->>'full_name',
      new.raw_user_meta_data->>'name',
      split_part(new.email, '@', 1)
    )
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- =====================================================================
-- 2) HOUSEHOLDS
-- =====================================================================
create table if not exists public.households (
  id            uuid primary key,
  name          text not null check (length(name) between 1 and 80),
  owner_user_id uuid not null references public.profiles(id) on delete cascade,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  deleted_at    timestamptz
);

drop trigger if exists trg_households_updated_at on public.households;
create trigger trg_households_updated_at
  before update on public.households
  for each row execute function public.set_updated_at();

create index if not exists idx_households_owner on public.households(owner_user_id);

-- =====================================================================
-- 3) HOUSEHOLD_MEMBERS
-- =====================================================================
create table if not exists public.household_members (
  household_id uuid not null references public.households(id) on delete cascade,
  user_id      uuid not null references public.profiles(id) on delete cascade,
  role         text not null check (role in ('owner','parent','caregiver')),
  joined_at    timestamptz not null default now(),
  primary key (household_id, user_id)
);

create index if not exists idx_members_user on public.household_members(user_id);

-- Household oluşturulduğunda owner'ı otomatik üye yap
create or replace function public.add_owner_as_member()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.household_members (household_id, user_id, role)
  values (new.id, new.owner_user_id, 'owner')
  on conflict (household_id, user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_household_created on public.households;
create trigger on_household_created
  after insert on public.households
  for each row execute function public.add_owner_as_member();

-- =====================================================================
-- 4) HOUSEHOLD_INVITES
-- =====================================================================
create table if not exists public.household_invites (
  id              uuid primary key default uuid_generate_v4(),
  household_id    uuid not null references public.households(id) on delete cascade,
  invite_code     text not null unique check (length(invite_code) = 6),
  created_by      uuid not null references public.profiles(id) on delete cascade,
  expires_at      timestamptz not null,
  used_by_user_id uuid references public.profiles(id),
  used_at         timestamptz,
  created_at      timestamptz not null default now()
);

create index if not exists idx_invites_code on public.household_invites(invite_code);
create index if not exists idx_invites_household on public.household_invites(household_id);

-- Davet kodunu kullan: tek seferlik + süre kontrolü
create or replace function public.redeem_invite(p_code text)
returns table (household_id uuid, household_name text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invite public.household_invites%rowtype;
  v_household_name text;
begin
  if auth.uid() is null then
    raise exception 'unauthorized';
  end if;

  select * into v_invite
  from public.household_invites
  where invite_code = upper(p_code)
  for update;

  if not found then
    raise exception 'invite_not_found';
  end if;

  if v_invite.used_at is not null then
    raise exception 'invite_already_used';
  end if;

  if v_invite.expires_at < now() then
    raise exception 'invite_expired';
  end if;

  insert into public.household_members (household_id, user_id, role)
  values (v_invite.household_id, auth.uid(), 'parent')
  on conflict (household_id, user_id) do nothing;

  update public.household_invites
     set used_by_user_id = auth.uid(),
         used_at         = now()
   where id = v_invite.id;

  select name into v_household_name
  from public.households
  where id = v_invite.household_id;

  return query select v_invite.household_id, v_household_name;
end;
$$;

-- =====================================================================
-- 5) BABIES
-- =====================================================================
create table if not exists public.babies (
  id              uuid primary key,
  household_id    uuid not null references public.households(id) on delete cascade,
  name            text not null check (length(name) between 1 and 80),
  birth_date      date not null,
  birth_time      time,
  birth_weight_g  integer check (birth_weight_g between 300 and 8000),
  birth_length_cm numeric(5,2) check (birth_length_cm between 20 and 80),
  sex             text check (sex in ('female','male','unspecified')),
  photo_url       text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  deleted_at      timestamptz
);

drop trigger if exists trg_babies_updated_at on public.babies;
create trigger trg_babies_updated_at
  before update on public.babies
  for each row execute function public.set_updated_at();

create index if not exists idx_babies_household on public.babies(household_id);

-- =====================================================================
-- 6) ROW LEVEL SECURITY
-- =====================================================================
alter table public.profiles            enable row level security;
alter table public.households          enable row level security;
alter table public.household_members   enable row level security;
alter table public.household_invites   enable row level security;
alter table public.babies              enable row level security;

-- ---------- profiles ----------
drop policy if exists "profiles select own or co-member" on public.profiles;
create policy "profiles select own or co-member"
  on public.profiles for select
  using (
    id = auth.uid()
    or id in (
      select hm.user_id
      from public.household_members hm
      where hm.household_id in (
        select household_id from public.household_members where user_id = auth.uid()
      )
    )
  );

drop policy if exists "profiles update own" on public.profiles;
create policy "profiles update own"
  on public.profiles for update
  using (id = auth.uid()) with check (id = auth.uid());

-- ---------- households ----------
drop policy if exists "households select member" on public.households;
create policy "households select member"
  on public.households for select
  using (
    id in (select household_id from public.household_members where user_id = auth.uid())
    and deleted_at is null
  );

drop policy if exists "households insert by owner self" on public.households;
create policy "households insert by owner self"
  on public.households for insert
  with check (owner_user_id = auth.uid());

drop policy if exists "households update owner" on public.households;
create policy "households update owner"
  on public.households for update
  using (owner_user_id = auth.uid())
  with check (owner_user_id = auth.uid());

-- ---------- household_members ----------
drop policy if exists "members select co-member" on public.household_members;
create policy "members select co-member"
  on public.household_members for select
  using (
    household_id in (select household_id from public.household_members where user_id = auth.uid())
  );

drop policy if exists "members insert owner only" on public.household_members;
create policy "members insert owner only"
  on public.household_members for insert
  with check (
    household_id in (select id from public.households where owner_user_id = auth.uid())
  );

drop policy if exists "members delete owner or self" on public.household_members;
create policy "members delete owner or self"
  on public.household_members for delete
  using (
    user_id = auth.uid()
    or household_id in (select id from public.households where owner_user_id = auth.uid())
  );

-- ---------- household_invites ----------
drop policy if exists "invites select owner" on public.household_invites;
create policy "invites select owner"
  on public.household_invites for select
  using (
    household_id in (select id from public.households where owner_user_id = auth.uid())
  );

drop policy if exists "invites insert owner" on public.household_invites;
create policy "invites insert owner"
  on public.household_invites for insert
  with check (
    household_id in (select id from public.households where owner_user_id = auth.uid())
    and created_by = auth.uid()
  );

-- Davet kullanımı redeem_invite RPC üzerinden olur; doğrudan update kapalı.

-- ---------- babies ----------
drop policy if exists "babies select member" on public.babies;
create policy "babies select member"
  on public.babies for select
  using (
    household_id in (select household_id from public.household_members where user_id = auth.uid())
    and deleted_at is null
  );

drop policy if exists "babies insert member" on public.babies;
create policy "babies insert member"
  on public.babies for insert
  with check (
    household_id in (select household_id from public.household_members where user_id = auth.uid())
  );

drop policy if exists "babies update member" on public.babies;
create policy "babies update member"
  on public.babies for update
  using (
    household_id in (select household_id from public.household_members where user_id = auth.uid())
  )
  with check (
    household_id in (select household_id from public.household_members where user_id = auth.uid())
  );

-- =====================================================================
-- 7) REALTIME (Postgres changes)
-- =====================================================================
alter publication supabase_realtime add table public.households;
alter publication supabase_realtime add table public.household_members;
alter publication supabase_realtime add table public.babies;

-- =====================================================================
-- BİTTİ. Sıradaki faz tabloları (feedings, sleeps, diapers, vaccinations)
-- aynı kalıpla eklenecek.
-- =====================================================================
