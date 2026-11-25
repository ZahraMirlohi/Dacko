-- 15: حذف گفتگو/پیام برای طرف مقابل لحظه‌ای دیده شود (Realtime)
do $$
declare t text;
begin
  foreach t in array array['conversations','conversation_members','messages','message_reactions'] loop
    begin
      execute format('alter publication supabase_realtime add table public.%I', t);
    exception when duplicate_object then null;
    end;
  end loop;
end $$;

-- فرستنده باید بتواند پیام خودش را (برای همه) حذف نرم کند؛ اگر قبلاً policy آپدیت دارید لازم نیست.
-- (حذف برای همه حالا is_deleted=true می‌شود، نه حذف ردیف)
