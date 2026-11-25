-- 18: ایندکس‌های کارایی (امن: if not exists). Postgres برای ستون‌های user_id/habit_id خودکار ایندکس نمی‌سازد.
-- روی Supabase SQL Editor اجرا کنید. اگر ایندکسی با اسم دیگر وجود داشته باشد، فقط یکی اضافه می‌شود (بی‌ضرر).

-- عادت‌ها و تکمیل‌ها (صفحهٔ امروز، آنالیتیکس، استریک)
create index if not exists habits_user_idx                 on public.habits (user_id);
create index if not exists habit_completions_user_date_idx on public.habit_completions (user_id, date);
create index if not exists habit_completions_habit_date_idx on public.habit_completions (habit_id, date);
create index if not exists habit_daily_status_user_date_idx on public.habit_daily_status (user_id, date);
create index if not exists habit_daily_status_habit_date_idx on public.habit_daily_status (habit_id, date);
create index if not exists tasks_user_due_idx              on public.tasks (user_id, due_date);
create index if not exists user_daily_activity_user_date_idx on public.user_daily_activity (user_id, activity_date);

-- چالش‌ها و ماموریت‌ها
create index if not exists user_challenges_user_active_idx on public.user_challenges (user_id, is_active);
create index if not exists user_quests_user_idx            on public.user_quests (user_id);
create index if not exists challenge_completions_user_date_idx on public.challenge_completions (user_id, date);
create index if not exists user_badges_user_idx            on public.user_badges (user_id);

-- چت و درخواست‌ها
create index if not exists conversation_members_conv_idx   on public.conversation_members (conversation_id);
create index if not exists buddy_requests_to_status_idx    on public.buddy_requests (to_user_id, status);
create index if not exists buddy_requests_from_status_idx  on public.buddy_requests (from_user_id, status);

-- تالار افتخارات: order by total_xp desc limit 100
create index if not exists user_progress_total_xp_idx      on public.user_progress (total_xp desc);

-- جستجوی کاربر با ilike روی username (btree معمولی برای ilike کمکی نمی‌کند؛ trigram می‌کند)
create extension if not exists pg_trgm with schema extensions;
create index if not exists profiles_username_trgm_idx
  on public.profiles using gin (username extensions.gin_trgm_ops);

analyze;
