-- 17: لاگ‌های برنامه (warn/error/fatal) از دستگاه کاربران
-- فقط درج برای کاربر واردشده؛ خواندن فقط از داشبورد Supabase / service_role.
create table if not exists public.app_logs (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  user_id     uuid default auth.uid(),
  session_id  text,
  level       text not null,
  tag         text,
  message     text,
  fields      jsonb,
  error       text,
  stack       text,
  screen      text,
  app_version text,
  platform    text,
  client_time timestamptz,
  seq         int
);

create index if not exists app_logs_created_idx on public.app_logs (created_at desc);
create index if not exists app_logs_level_idx   on public.app_logs (level, created_at desc);

alter table public.app_logs enable row level security;

drop policy if exists "app_logs_insert_own" on public.app_logs;
create policy "app_logs_insert_own" on public.app_logs
  for insert to authenticated
  with check (user_id = auth.uid());

-- پاک‌سازی لاگ‌های قدیمی‌تر از ۳۰ روز (دستی یا با pg_cron صدا بزنید)
create or replace function public.purge_app_logs() returns void
language sql security definer set search_path = public as $$
  delete from public.app_logs where created_at < now() - interval '30 days';
$$;
revoke all on function public.purge_app_logs() from public, anon, authenticated;

-- نمونه پرس‌وجو: خطاهای ۲۴ ساعت اخیر به تفکیک تگ
-- select tag, count(*) from app_logs where level in ('error','fatal') and created_at > now() - interval '1 day' group by 1 order by 2 desc;
