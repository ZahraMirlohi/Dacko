-- 14: ساعت پیام‌ها از سرور + واکنش زنده
-- 1) created_at پیام همیشه ساعت سرور باشد (ترتیب پیام‌ها دیگر به ساعت گوشی‌ها وابسته نیست)
create or replace function public.set_message_created_at()
returns trigger language plpgsql as $$
begin
  new.created_at := now();
  return new;
end $$;

drop trigger if exists trg_messages_created_at on public.messages;
create trigger trg_messages_created_at
before insert on public.messages
for each row execute function public.set_message_created_at();

-- 2) واکنش‌ها به‌صورت زنده برای طرف مقابل برسد
do $$
begin
  alter publication supabase_realtime add table public.message_reactions;
exception when duplicate_object then null;
end $$;
