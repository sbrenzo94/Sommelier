-- SOMMELIER — schema definitivo e migrazione compatibile
create extension if not exists pgcrypto;

create table if not exists public.wines (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 wine_name text not null, producer text, vintage integer, appellation text, region text, grapes text,
 quantity integer not null default 1 check(quantity between 1 and 150), purchase_price numeric(10,2) not null default 0 check(purchase_price>=0),
 purchase_date date, storage_location text, notes text, label_image_path text,
 market_value numeric(10,2), market_source text, market_date date, drink_from integer, drink_until integer,
 service_temp text, decanting text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
-- Aggiunge i campi mancanti anche a progetti creati con lo schema precedente.
alter table public.wines add column if not exists wine_name text;
alter table public.wines add column if not exists market_value numeric(10,2);
alter table public.wines add column if not exists market_source text;
alter table public.wines add column if not exists market_date date;
alter table public.wines add column if not exists drink_from integer;
alter table public.wines add column if not exists drink_until integer;
alter table public.wines add column if not exists service_temp text;
alter table public.wines add column if not exists decanting text;
alter table public.wines add column if not exists label_image_path text;
-- Migra il vecchio campo name se presente.
do $$ begin
 if exists(select 1 from information_schema.columns where table_schema='public' and table_name='wines' and column_name='name') then
  execute 'update public.wines set wine_name = name where wine_name is null';
  execute 'alter table public.wines alter column name set default ' || quote_literal('');
 end if;
end $$;

create table if not exists public.tastings (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 wine_id uuid not null references public.wines(id) on delete cascade, tasting_date date not null default current_date,
 score integer check(score between 0 and 100), appearance text, aromas text, palate text, evolution text, pairing text, notes text,
 created_at timestamptz not null default now()
);
alter table public.tastings add column if not exists tasting_date date;
alter table public.tastings add column if not exists appearance text;
alter table public.tastings add column if not exists aromas text;
alter table public.tastings add column if not exists palate text;
alter table public.tastings add column if not exists evolution text;
alter table public.tastings add column if not exists pairing text;
do $$ begin
 if exists(select 1 from information_schema.columns where table_schema='public' and table_name='tastings' and column_name='tasted_on') then
  execute 'update public.tastings set tasting_date = tasted_on where tasting_date is null';
 end if;
end $$;

create index if not exists wines_user_id_idx on public.wines(user_id);
create index if not exists tastings_user_id_idx on public.tastings(user_id);
create index if not exists tastings_wine_id_idx on public.tastings(wine_id);
alter table public.wines enable row level security;
alter table public.tastings enable row level security;
drop policy if exists "Users manage their own wines" on public.wines;
create policy "Users manage their own wines" on public.wines for all to authenticated using(auth.uid()=user_id) with check(auth.uid()=user_id);
drop policy if exists "Users manage their own tastings" on public.tastings;
create policy "Users manage their own tastings" on public.tastings for all to authenticated using(auth.uid()=user_id) with check(auth.uid()=user_id);

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('wine-labels','wine-labels',false,5242880,array['image/jpeg','image/png','image/webp','image/heic'])
on conflict(id) do update set public=false,file_size_limit=5242880;
drop policy if exists "Users read own label images" on storage.objects;
create policy "Users read own label images" on storage.objects for select to authenticated using(bucket_id='wine-labels' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists "Users upload own label images" on storage.objects;
create policy "Users upload own label images" on storage.objects for insert to authenticated with check(bucket_id='wine-labels' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists "Users update own label images" on storage.objects;
create policy "Users update own label images" on storage.objects for update to authenticated using(bucket_id='wine-labels' and (storage.foldername(name))[1]=auth.uid()::text) with check(bucket_id='wine-labels' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists "Users delete own label images" on storage.objects;
create policy "Users delete own label images" on storage.objects for delete to authenticated using(bucket_id='wine-labels' and (storage.foldername(name))[1]=auth.uid()::text);
