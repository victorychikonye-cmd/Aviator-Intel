-- Aviator Intelligence Pro Max: run once in the Supabase SQL editor.
create table public.platforms (id smallint primary key, name text unique not null);
insert into public.platforms values (1,'Winnbucks'),(2,'Mwos'),(3,'PrideBet');

create table public.profiles (id uuid primary key references auth.users on delete cascade, display_name text, created_at timestamptz not null default now());
create table public.user_settings (user_id uuid primary key references auth.users on delete cascade, settings jsonb not null default '{}', updated_at timestamptz not null default now());

create table public.datasets (id bigint generated always as identity primary key, user_id uuid not null default auth.uid() references auth.users on delete cascade, name text not null, source text, created_at timestamptz not null default now());
create table public.imports (id bigint generated always as identity primary key, user_id uuid not null default auth.uid() references auth.users on delete cascade, dataset_id bigint references public.datasets on delete set null, source text, accepted int not null default 0, rejected int not null default 0, duplicates int not null default 0, created_at timestamptz not null default now());
create table public.historical_rounds (id bigint generated always as identity primary key, user_id uuid not null default auth.uid() references auth.users on delete cascade, platform_id smallint not null references public.platforms, multiplier numeric(12,2) not null check (multiplier >= 1), round_time timestamptz, source text, dataset_id bigint references public.datasets on delete set null, import_id bigint references public.imports on delete set null, verified boolean not null default false, created_at timestamptz not null default now());
create table public.statistical_reports (id bigint generated always as identity primary key, user_id uuid not null default auth.uid() references auth.users on delete cascade, scope text not null, date_from date, date_to date, summary text, content text, created_at timestamptz not null default now());
create table public.anomaly_records (id bigint generated always as identity primary key, user_id uuid not null default auth.uid() references auth.users on delete cascade, platform_id smallint references public.platforms, round_id bigint references public.historical_rounds on delete cascade, detected_at timestamptz not null default now(), reason text, sample_size int, severity text check (severity in ('Low','Medium','High')), explanation text);
create table public.analysis_sessions (id bigint generated always as identity primary key, user_id uuid not null default auth.uid() references auth.users on delete cascade, title text, messages jsonb not null default '[]', created_at timestamptz not null default now());
create table public.audit_log (id bigint generated always as identity primary key, user_id uuid not null default auth.uid() references auth.users on delete cascade, message text not null, created_at timestamptz not null default now());

create index on public.datasets (user_id);
create index on public.imports (user_id, created_at desc);
create index on public.imports (dataset_id);
create index on public.historical_rounds (user_id, platform_id, round_time);
create index on public.historical_rounds (dataset_id);
create index on public.historical_rounds (import_id);
create index on public.statistical_reports (user_id, created_at desc);
create index on public.anomaly_records (user_id);
create index on public.anomaly_records (round_id);
create index on public.anomaly_records (platform_id);
create index on public.analysis_sessions (user_id);
create index on public.audit_log (user_id, created_at desc);

alter table public.platforms enable row level security;
create policy "platforms readable" on public.platforms for select to authenticated using (true);
alter table public.profiles enable row level security;
create policy "own profile" on public.profiles for all to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));
alter table public.user_settings enable row level security;
create policy "own settings" on public.user_settings for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
do $$ declare t text; begin
  foreach t in array array['datasets','imports','historical_rounds','statistical_reports','anomaly_records','analysis_sessions','audit_log'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy "own rows" on public.%I for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()))', t);
  end loop;
end $$;

create function public.handle_new_user() returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, display_name) values (new.id, split_part(new.email, '@', 1));
  insert into public.user_settings (user_id) values (new.id);
  return new;
end $$;
revoke execute on function public.handle_new_user() from public, anon, authenticated;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();
