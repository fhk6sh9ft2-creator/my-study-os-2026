-- MY STUDY OS V1.0 — starter schema for Supabase/PostgreSQL
-- Apply only after creating a Supabase project and reviewing this schema.
create extension if not exists pgcrypto;
create extension if not exists vector;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  preferred_language text not null default 'zh' check (preferred_language in ('zh','en','ms')),
  created_at timestamptz not null default now()
);

create table if not exists public.subjects (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references auth.users(id) on delete cascade,
  slug text not null,
  name text not null,
  created_at timestamptz not null default now(),
  unique(owner_id, slug)
);

create table if not exists public.materials (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  subject_id uuid references public.subjects(id) on delete set null,
  title text not null,
  original_filename text not null,
  storage_path text not null,
  mime_type text,
  file_size_bytes bigint,
  processing_status text not null default 'queued'
    check (processing_status in ('queued','processing','ready','failed')),
  created_at timestamptz not null default now()
);

create table if not exists public.material_chunks (
  id uuid primary key default gen_random_uuid(),
  material_id uuid not null references public.materials(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  page_number integer,
  chunk_text text not null,
  embedding vector(1536),
  created_at timestamptz not null default now()
);

create table if not exists public.study_tasks (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  subject_id uuid references public.subjects(id) on delete set null,
  title text not null,
  planned_minutes integer not null default 25,
  due_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.study_sessions (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  subject_id uuid references public.subjects(id) on delete set null,
  started_at timestamptz not null,
  ended_at timestamptz,
  duration_seconds integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.notes (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  subject_id uuid references public.subjects(id) on delete set null,
  material_id uuid references public.materials(id) on delete set null,
  title text not null,
  body text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.subjects enable row level security;
alter table public.materials enable row level security;
alter table public.material_chunks enable row level security;
alter table public.study_tasks enable row level security;
alter table public.study_sessions enable row level security;
alter table public.notes enable row level security;

create policy "profile owner access" on public.profiles for all using (auth.uid() = id) with check (auth.uid() = id);
create policy "subject owner access" on public.subjects for all using (auth.uid() = owner_id) with check (auth.uid() = owner_id);
create policy "material owner access" on public.materials for all using (auth.uid() = owner_id) with check (auth.uid() = owner_id);
create policy "chunk owner access" on public.material_chunks for all using (auth.uid() = owner_id) with check (auth.uid() = owner_id);
create policy "task owner access" on public.study_tasks for all using (auth.uid() = owner_id) with check (auth.uid() = owner_id);
create policy "session owner access" on public.study_sessions for all using (auth.uid() = owner_id) with check (auth.uid() = owner_id);
create policy "note owner access" on public.notes for all using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

-- Seed subjects per user after sign-up from application code:
-- sejarah, english, bahasa-melayu, science, mathematics, moral
-- Public registration does NOT mean public access to private learning files.


-- Automatically create a private profile and six default subjects for every new account.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1)))
  on conflict (id) do nothing;

  insert into public.subjects (owner_id, slug, name)
  values
    (new.id, 'sejarah', 'Sejarah'),
    (new.id, 'english', 'English'),
    (new.id, 'bahasa-melayu', 'Bahasa Melayu'),
    (new.id, 'science', 'Science'),
    (new.id, 'mathematics', 'Mathematics'),
    (new.id, 'moral', 'Moral')
  on conflict (owner_id, slug) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();
