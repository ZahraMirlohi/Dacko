-- فقط خواندنی: کلید اصلی/خارجی، RLS، ایندکس، تریگر و تابع‌ها. خروجی هر بخش را جدا بفرستید.
-- 1) قیدها
select conrelid::regclass as tbl, conname, pg_get_constraintdef(oid) as def
from pg_constraint where connamespace = 'public'::regnamespace order by 1, 2;
-- 2) سیاست‌های RLS
select tablename, policyname, cmd, roles, qual, with_check from pg_policies where schemaname = 'public' order by 1, 2;
-- 3) ایندکس‌ها
select tablename, indexname, indexdef from pg_indexes where schemaname = 'public' order by 1, 2;
-- 4) تریگرها و تابع‌ها
select event_object_table as tbl, trigger_name, action_timing, event_manipulation, action_statement
from information_schema.triggers where trigger_schema = 'public' order by 1, 2;
select p.proname, pg_get_functiondef(p.oid) as def from pg_proc p where p.pronamespace = 'public'::regnamespace;
-- 5) جدول‌های Realtime
select tablename from pg_publication_tables where pubname = 'supabase_realtime' order by 1;
