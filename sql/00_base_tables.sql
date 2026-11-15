-- 00: ساختار پایه‌ی جدول‌ها (از دیتابیس واقعی استخراج شده؛ تاریخ: 2026-11-15)
-- فقط ستون‌ها، نوع‌ها، مقدار پیش‌فرض و NOT NULL. کلیدهای خارجی، ایندکس، RLS، تریگر و تابع در این فایل نیست.
-- روی دیتابیس موجود بی‌خطر است (IF NOT EXISTS) و فقط برای ساخت دوباره‌ی پروژه از صفر لازم است.

create table if not exists public.app_migrations (
  name text not null,
  applied_at timestamptz default now() not null,
  primary key (name)
);

create table if not exists public.blocked_users (
  id uuid default gen_random_uuid() not null,
  blocker_id uuid,
  blocked_id uuid,
  created_at timestamptz default now(),
  primary key (id)
);

create table if not exists public.buddy_requests (
  id uuid default gen_random_uuid() not null,
  from_user_id uuid,
  to_user_id uuid,
  status text default 'pending'::text,
  message text,
  created_at timestamptz default now(),
  match_score double precision,
  primary key (id)
);

create table if not exists public.challenge_completions (
  id uuid default gen_random_uuid() not null,
  user_id uuid not null,
  challenge_id uuid not null,
  date date not null,
  created_at timestamp default now(),
  primary key (id)
);

create table if not exists public.challenge_invites (
  id text not null,
  creator_id text not null,
  creator_name text not null,
  opponent_id text not null,
  opponent_name text not null,
  title text not null,
  description text,
  habits jsonb not null,
  duration integer not null,
  xp_reward integer not null,
  start_date timestamptz not null,
  end_date timestamptz,
  status text default 'pending'::text not null,
  progress jsonb,
  created_at timestamptz default now() not null,
  accepted_at timestamptz,
  completed_at timestamptz,
  primary key (id)
);

create table if not exists public.challenges (
  id uuid default gen_random_uuid() not null,
  title text not null,
  description text,
  icon text default 'emoji_events'::text,
  color text default '#4A90E2'::text,
  text_color text default '#FFFFFF'::text,
  badge text default '🔥'::text,
  xp_reward integer default 100,
  challenge_duration integer default 7,
  registration_start_date timestamptz default now(),
  registration_end_date timestamptz default (now() + '30 days'::interval),
  is_active boolean default true,
  is_boss boolean default false,
  community_xp integer,
  target_xp integer,
  tasks text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  full_description text default 'انجام کامل چالش'::text,
  half_description text default 'انجام نیمی از چالش'::text,
  basic_description text default 'انجام حداقل چالش'::text,
  target_value text,
  image_url text,
  primary key (id)
);

create table if not exists public.characters (
  id uuid default gen_random_uuid() not null,
  user_id uuid not null,
  name text default 'قهرمان'::text,
  hero_class text default 'warrior'::text,
  outfit text default 'default'::text,
  accessory text default 'none'::text,
  background text default 'default'::text,
  catchphrase text default 'من قهرمان درونم هستم!'::text,
  bg_music text default 'default'::text,
  current_animation text default 'idle'::text,
  level integer default 1,
  xp integer default 0,
  total_xp integer default 0,
  streak integer default 0,
  best_streak integer default 0,
  badges integer default 0,
  created_at timestamp default now(),
  last_active timestamp default now(),
  updated_at timestamp default now(),
  primary key (id)
);

create table if not exists public.comments (
  id uuid default gen_random_uuid() not null,
  post_id uuid,
  user_id uuid,
  content text not null,
  likes_count integer default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  primary key (id)
);

create table if not exists public.conversation_bans (
  conversation_id uuid not null,
  user_id uuid not null,
  banned_by uuid,
  created_at timestamptz default now() not null
);

create table if not exists public.conversation_members (
  id uuid default gen_random_uuid() not null,
  conversation_id uuid,
  user_id uuid,
  role text default 'member'::text,
  last_read_at timestamptz default now(),
  joined_at timestamptz default now(),
  muted boolean default false not null,
  primary key (id)
);

create table if not exists public.conversations (
  id uuid default gen_random_uuid() not null,
  type text not null,
  name text,
  created_by uuid,
  squad_id uuid,
  challenge_id uuid,
  is_active boolean default true,
  last_message_at timestamptz default now(),
  created_at timestamptz default now(),
  description text,
  avatar_url text,
  is_public boolean default false not null,
  invite_code text,
  reactions_enabled boolean default true not null,
  posting_mode text default 'all'::text not null,
  primary key (id)
);

create table if not exists public.cosmetics (
  id text not null,
  name text not null,
  description text,
  category text not null,
  icon text not null,
  price integer not null,
  color text not null,
  preview_image text,
  is_active boolean default true,
  created_at timestamptz default now(),
  primary key (id)
);

create table if not exists public.daily_spark (
  id text not null,
  text text not null,
  author text,
  type text not null,
  date text not null,
  is_active boolean default true,
  created_at timestamptz default now(),
  primary key (id)
);

create table if not exists public.feed_posts (
  id uuid default gen_random_uuid() not null,
  challenge_id uuid,
  user_id uuid,
  type text,
  content text not null,
  metadata jsonb default '{}'::jsonb,
  likes_count integer default 0,
  comments_count integer default 0,
  is_pinned boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  primary key (id)
);

create table if not exists public.habit_completions (
  id uuid default gen_random_uuid() not null,
  user_id uuid not null,
  date text not null,
  completed_at timestamp default now(),
  created_at timestamp default now(),
  completion_level varchar default 'full'::character varying,
  habit_id uuid not null,
  primary key (id)
);

create table if not exists public.habit_daily_status (
  id uuid default gen_random_uuid() not null,
  habit_id uuid not null,
  user_id uuid not null,
  date date not null,
  status text,
  created_at timestamp default now(),
  primary key (id)
);

create table if not exists public.habit_level_settings (
  id uuid default gen_random_uuid() not null,
  full_description text default 'انجام کامل عادت'::text,
  half_description text default 'انجام نیمی از عادت'::text,
  basic_description text default 'انجام حداقل عادت'::text,
  full_value text,
  half_value text,
  basic_value text,
  created_at timestamp default now(),
  updated_at timestamp default now(),
  user_id uuid not null,
  habit_id uuid not null,
  primary key (id)
);

create table if not exists public.habit_time_tracking (
  id uuid default gen_random_uuid() not null,
  date date not null,
  total_seconds integer default 0 not null,
  last_updated timestamptz default now(),
  created_at timestamptz default now(),
  user_id uuid not null,
  habit_id uuid not null,
  primary key (id)
);

create table if not exists public.habits (
  title text not null,
  description text,
  sub_habits text[] default '{}'::text[],
  completed_sub_habits text[] default '{}'::text[],
  icon_name text default 'fitness_center'::text,
  icon_color bigint default '4280394978'::bigint,
  background_color bigint default '4294967285'::bigint,
  frequency_type text default 'daily'::text,
  daily_interval_days integer,
  weekly_days integer[],
  weekly_interval_weeks integer default 1,
  monthly_days integer[],
  monthly_interval_months integer default 1,
  time_of_day text default 'morning'::text,
  reminders jsonb default '[]'::jsonb,
  xp_reward integer default 10,
  current_streak integer default 0,
  best_streak integer default 0,
  is_active boolean default true,
  group_id text,
  start_date date,
  end_date date,
  challenge_id text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  quest_id text,
  timer_setting jsonb default '{}'::jsonb,
  target_value varchar,
  full_description text default 'انجام کامل عادت'::text,
  half_description text default 'انجام نیمی از عادت'::text,
  basic_description text default 'انجام حداقل عادت'::text,
  user_id uuid not null,
  id uuid default gen_random_uuid() not null,
  package_id text,
  primary key (id)
);

create table if not exists public.likes (
  id uuid default gen_random_uuid() not null,
  user_id uuid,
  target_type text,
  target_id uuid not null,
  created_at timestamptz default now(),
  primary key (id)
);

create table if not exists public.member_reports (
  id uuid default gen_random_uuid() not null,
  conversation_id uuid not null,
  reporter_id uuid not null,
  reported_user_id uuid not null,
  reason text not null,
  details text,
  status text default 'open'::text not null,
  created_at timestamptz default now() not null,
  primary key (id)
);

create table if not exists public.message_reactions (
  id uuid default gen_random_uuid() not null,
  message_id uuid not null,
  user_id uuid not null,
  emoji text not null,
  created_at timestamptz default now(),
  primary key (id)
);

create table if not exists public.messages (
  id uuid default gen_random_uuid() not null,
  conversation_id uuid,
  sender_id uuid,
  content text not null,
  type text default 'text'::text,
  metadata jsonb default '{}'::jsonb,
  is_read boolean default false,
  created_at timestamptz default now(),
  reply_to_id uuid,
  is_deleted boolean default false,
  is_edited boolean default false,
  reactions text[] default '{}'::text[],
  reactions_by_user jsonb default '{}'::jsonb,
  edited_at timestamptz,
  deleted_at timestamptz,
  hidden_for text[] default '{}'::text[],
  status text default 'sent'::text,
  read_at timestamptz,
  sender_name text,
  is_pinned boolean default false,
  pinned_at timestamptz,
  pinned_by text,
  primary key (id)
);

create table if not exists public.packages (
  id uuid default gen_random_uuid() not null,
  title text not null,
  description text,
  icon text default 'fitness_center'::text,
  color text default '#4A90E2'::text,
  background_color text default '#F5F5F5'::text,
  category text default 'other'::text,
  habits jsonb default '[]'::jsonb,
  is_active boolean default true,
  xp_reward integer default 50,
  badge text default '📦'::text,
  created_at timestamp default now(),
  full_description text default 'انجام کامل عادت'::text,
  half_description text default 'انجام نیمی از عادت'::text,
  basic_description text default 'انجام حداقل عادت'::text,
  target_value text,
  image_url text,
  primary key (id)
);

create table if not exists public.photo_likes (
  id uuid default gen_random_uuid() not null,
  photo_id uuid not null,
  user_id uuid not null,
  created_at timestamptz default now(),
  primary key (id)
);

create table if not exists public.profiles (
  email text not null,
  name text not null,
  total_xp integer default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  avatar_url text,
  phone text,
  birth_date date,
  real_age integer,
  gender text,
  avatar_style text default 'default'::text,
  skin_color text default '#F5D0B8'::text,
  hair_style text default 'default'::text,
  hair_color text default '#4A3728'::text,
  eye_style text default 'default'::text,
  eye_color text default '#4A90E2'::text,
  mouth_style text default 'default'::text,
  accessory_type text default 'none'::text,
  outfit_style text default 'default'::text,
  background_style text default 'default'::text,
  weekly_streak integer default 0,
  last_streak_update date,
  level integer default 1,
  xp_to_next_level integer default 100,
  current_streak integer default 0,
  best_streak integer default 0,
  last_streak_date date,
  unique_id text,
  last_seen_at timestamptz default now(),
  bio text,
  username text,
  username_updated_at timestamptz,
  user_id uuid not null,
  allow_buddy_requests boolean default true not null,
  primary key (user_id)
);

create table if not exists public.quests (
  id uuid default gen_random_uuid() not null,
  title text not null,
  description text,
  icon text default 'flag'::text,
  color text default '#FF9F43'::text,
  xp_reward integer default 100,
  badge text default '🎯'::text,
  target_count integer not null,
  is_active boolean default true,
  created_at timestamp default now(),
  full_description text default 'انجام کامل ماموریت'::text,
  half_description text default 'انجام نیمی از ماموریت'::text,
  basic_description text default 'انجام حداقل ماموریت'::text,
  target_value text,
  image_url text,
  primary key (id)
);

create table if not exists public.quotes (
  id text not null,
  text text not null,
  author text not null,
  category text,
  is_active boolean default true,
  created_at timestamptz default now(),
  primary key (id)
);

create table if not exists public.tasks (
  title text not null,
  description text,
  sub_tasks text[] default '{}'::text[],
  completed_sub_tasks text[] default '{}'::text[],
  due_date date,
  is_completed boolean default false,
  xp_reward integer default 10,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  user_id uuid not null,
  id uuid default gen_random_uuid() not null,
  primary key (id)
);

create table if not exists public.template_packages (
  id text not null,
  title text not null,
  description text not null,
  xp_reward integer default 0,
  color text not null,
  background_color text not null,
  icon text not null,
  habits text,
  is_active boolean default true,
  "order" integer default 0,
  created_at timestamptz default now(),
  primary key (id)
);

create table if not exists public.typing_status (
  id uuid default gen_random_uuid() not null,
  conversation_id uuid not null,
  user_id uuid not null,
  is_typing boolean default false,
  updated_at timestamptz default now(),
  primary key (id)
);

create table if not exists public.user_badges (
  id uuid default gen_random_uuid() not null,
  user_id uuid not null,
  badge_name text not null,
  badge_icon text not null,
  is_active boolean default true,
  earned_at timestamp default now(),
  primary key (id)
);

create table if not exists public.user_challenges (
  id uuid default gen_random_uuid() not null,
  challenge_id text not null,
  joined_at timestamptz default now(),
  challenge_start_date timestamptz,
  challenge_end_date timestamptz,
  progress integer default 0,
  is_completed boolean default false,
  is_active boolean default true,
  status text default 'active'::text,
  completed_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  user_id uuid not null,
  primary key (id)
);

create table if not exists public.user_cosmetics (
  id text not null,
  cosmetic_id text not null,
  is_active boolean default false,
  purchased_at text not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  user_id uuid not null,
  primary key (id)
);

create table if not exists public.user_daily_activity (
  id uuid default gen_random_uuid() not null,
  activity_date date not null,
  habits_completed integer default 0,
  tasks_completed integer default 0,
  xp_earned integer default 0,
  is_active boolean default false,
  created_at timestamp default now(),
  updated_at timestamp default now(),
  user_id uuid not null,
  primary key (id)
);

create table if not exists public.user_onboarding (
  user_id uuid not null,
  goals text[] default '{}'::text[] not null,
  obstacle text,
  level text,
  wake_time text,
  remind_time text,
  language text,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null,
  goal text,
  first_task text,
  energy text,
  planning_style text,
  primary key (user_id)
);

create table if not exists public.user_packages (
  id uuid default gen_random_uuid() not null,
  user_id uuid not null,
  package_id uuid not null,
  is_active boolean default true,
  added_at timestamp default now(),
  removed_at timestamp,
  created_at timestamp default now(),
  primary key (id)
);

create table if not exists public.user_personalities (
  user_id uuid not null,
  gender text,
  personality_types text[] default '{}'::text[],
  mbti_type text,
  interests text[] default '{}'::text[],
  habits text[] default '{}'::text[],
  goals text[] default '{}'::text[],
  bio text,
  preferred_times text[] default '{}'::text[],
  experience_level integer default 1,
  updated_at timestamptz default now(),
  created_at timestamptz default now(),
  is_looking_for_buddy boolean default true,
  primary key (user_id)
);

create table if not exists public.user_photos (
  id uuid default gen_random_uuid() not null,
  photo_url text not null,
  caption text,
  storage_path text not null,
  file_size bigint,
  width integer,
  height integer,
  is_primary boolean default false,
  display_order integer default 0,
  likes_count integer default 0,
  is_visible boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  user_id uuid not null,
  primary key (id)
);

create table if not exists public.user_progress (
  id uuid default gen_random_uuid() not null,
  user_id uuid not null,
  total_xp integer default 0,
  weekly_xp integer default 0,
  monthly_xp integer default 0,
  created_at timestamp default now(),
  updated_at timestamp default now(),
  primary key (id)
);

create table if not exists public.user_quests (
  id uuid default gen_random_uuid() not null,
  user_id uuid not null,
  quest_id uuid not null,
  progress integer default 0,
  is_completed boolean default false,
  started_at timestamp default now(),
  completed_at timestamp,
  is_active boolean default true,
  created_at timestamp default now(),
  habit_id uuid,
  primary key (id)
);

create table if not exists public.xp_gifts (
  id text not null,
  sender_id text not null,
  sender_name text not null,
  receiver_id text not null,
  receiver_name text not null,
  amount integer not null,
  message text,
  sent_at timestamptz default now() not null,
  is_delivered boolean default false,
  delivered_at timestamptz,
  status text default 'pending'::text,
  primary key (id)
);
