# ساختار دیتابیس (Supabase / public)

42 جدول. استخراج‌شده از دیتابیس واقعی در 2026-11-15. کلید اصلی‌ها حدس‌اند (id یا user_id).

## app_migrations
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| name | text |  | بله |
| applied_at | timestamptz | now() | بله |

## blocked_users
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | uuid | gen_random_uuid() | بله |
| blocker_id | uuid |  |  |
| blocked_id | uuid |  |  |
| created_at | timestamptz | now() |  |

## buddy_requests
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | uuid | gen_random_uuid() | بله |
| from_user_id | uuid |  |  |
| to_user_id | uuid |  |  |
| status | text | 'pending'::text |  |
| message | text |  |  |
| created_at | timestamptz | now() |  |
| match_score | double precision |  |  |

## challenge_completions
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | uuid | gen_random_uuid() | بله |
| user_id | uuid |  | بله |
| challenge_id | uuid |  | بله |
| date | date |  | بله |
| created_at | timestamp | now() |  |

## challenge_invites
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | text |  | بله |
| creator_id | text |  | بله |
| creator_name | text |  | بله |
| opponent_id | text |  | بله |
| opponent_name | text |  | بله |
| title | text |  | بله |
| description | text |  |  |
| habits | jsonb |  | بله |
| duration | integer |  | بله |
| xp_reward | integer |  | بله |
| start_date | timestamptz |  | بله |
| end_date | timestamptz |  |  |
| status | text | 'pending'::text | بله |
| progress | jsonb |  |  |
| created_at | timestamptz | now() | بله |
| accepted_at | timestamptz |  |  |
| completed_at | timestamptz |  |  |

## challenges
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | uuid | gen_random_uuid() | بله |
| title | text |  | بله |
| description | text |  |  |
| icon | text | 'emoji_events'::text |  |
| color | text | '#4A90E2'::text |  |
| text_color | text | '#FFFFFF'::text |  |
| badge | text | '🔥'::text |  |
| xp_reward | integer | 100 |  |
| challenge_duration | integer | 7 |  |
| registration_start_date | timestamptz | now() |  |
| registration_end_date | timestamptz | (now() + '30 days'::interval) |  |
| is_active | boolean | true |  |
| is_boss | boolean | false |  |
| community_xp | integer |  |  |
| target_xp | integer |  |  |
| tasks | text |  |  |
| created_at | timestamptz | now() |  |
| updated_at | timestamptz | now() |  |
| full_description | text | 'انجام کامل چالش'::text |  |
| half_description | text | 'انجام نیمی از چالش'::text |  |
| basic_description | text | 'انجام حداقل چالش'::text |  |
| target_value | text |  |  |
| image_url | text |  |  |

## characters
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | uuid | gen_random_uuid() | بله |
| user_id | uuid |  | بله |
| name | text | 'قهرمان'::text |  |
| hero_class | text | 'warrior'::text |  |
| outfit | text | 'default'::text |  |
| accessory | text | 'none'::text |  |
| background | text | 'default'::text |  |
| catchphrase | text | 'من قهرمان درونم هستم!'::text |  |
| bg_music | text | 'default'::text |  |
| current_animation | text | 'idle'::text |  |
| level | integer | 1 |  |
| xp | integer | 0 |  |
| total_xp | integer | 0 |  |
| streak | integer | 0 |  |
| best_streak | integer | 0 |  |
| badges | integer | 0 |  |
| created_at | timestamp | now() |  |
| last_active | timestamp | now() |  |
| updated_at | timestamp | now() |  |

## comments
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | uuid | gen_random_uuid() | بله |
| post_id | uuid |  |  |
| user_id | uuid |  |  |
| content | text |  | بله |
| likes_count | integer | 0 |  |
| created_at | timestamptz | now() |  |
| updated_at | timestamptz | now() |  |

## conversation_bans
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| conversation_id | uuid |  | بله |
| user_id | uuid |  | بله |
| banned_by | uuid |  |  |
| created_at | timestamptz | now() | بله |

## conversation_members
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | uuid | gen_random_uuid() | بله |
| conversation_id | uuid |  |  |
| user_id | uuid |  |  |
| role | text | 'member'::text |  |
| last_read_at | timestamptz | now() |  |
| joined_at | timestamptz | now() |  |
| muted | boolean | false | بله |

## conversations
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | uuid | gen_random_uuid() | بله |
| type | text |  | بله |
| name | text |  |  |
| created_by | uuid |  |  |
| squad_id | uuid |  |  |
| challenge_id | uuid |  |  |
| is_active | boolean | true |  |
| last_message_at | timestamptz | now() |  |
| created_at | timestamptz | now() |  |
| description | text |  |  |
| avatar_url | text |  |  |
| is_public | boolean | false | بله |
| invite_code | text |  |  |
| reactions_enabled | boolean | true | بله |
| posting_mode | text | 'all'::text | بله |

## cosmetics
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | text |  | بله |
| name | text |  | بله |
| description | text |  |  |
| category | text |  | بله |
| icon | text |  | بله |
| price | integer |  | بله |
| color | text |  | بله |
| preview_image | text |  |  |
| is_active | boolean | true |  |
| created_at | timestamptz | now() |  |

## daily_spark
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | text |  | بله |
| text | text |  | بله |
| author | text |  |  |
| type | text |  | بله |
| date | text |  | بله |
| is_active | boolean | true |  |
| created_at | timestamptz | now() |  |

## feed_posts
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | uuid | gen_random_uuid() | بله |
| challenge_id | uuid |  |  |
| user_id | uuid |  |  |
| type | text |  |  |
| content | text |  | بله |
| metadata | jsonb | '{}'::jsonb |  |
| likes_count | integer | 0 |  |
| comments_count | integer | 0 |  |
| is_pinned | boolean | false |  |
| created_at | timestamptz | now() |  |
| updated_at | timestamptz | now() |  |

## habit_completions
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | uuid | gen_random_uuid() | بله |
| user_id | uuid |  | بله |
| date | text |  | بله |
| completed_at | timestamp | now() |  |
| created_at | timestamp | now() |  |
| completion_level | varchar | 'full'::character varying |  |
| habit_id | uuid |  | بله |

## habit_daily_status
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | uuid | gen_random_uuid() | بله |
| habit_id | uuid |  | بله |
| user_id | uuid |  | بله |
| date | date |  | بله |
| status | text |  |  |
| created_at | timestamp | now() |  |

## habit_level_settings
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | uuid | gen_random_uuid() | بله |
| full_description | text | 'انجام کامل عادت'::text |  |
| half_description | text | 'انجام نیمی از عادت'::text |  |
| basic_description | text | 'انجام حداقل عادت'::text |  |
| full_value | text |  |  |
| half_value | text |  |  |
| basic_value | text |  |  |
| created_at | timestamp | now() |  |
| updated_at | timestamp | now() |  |
| user_id | uuid |  | بله |
| habit_id | uuid |  | بله |

## habit_time_tracking
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | uuid | gen_random_uuid() | بله |
| date | date |  | بله |
| total_seconds | integer | 0 | بله |
| last_updated | timestamptz | now() |  |
| created_at | timestamptz | now() |  |
| user_id | uuid |  | بله |
| habit_id | uuid |  | بله |

## habits
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| title | text |  | بله |
| description | text |  |  |
| sub_habits | text[] | '{}'::text[] |  |
| completed_sub_habits | text[] | '{}'::text[] |  |
| icon_name | text | 'fitness_center'::text |  |
| icon_color | bigint | '4280394978'::bigint |  |
| background_color | bigint | '4294967285'::bigint |  |
| frequency_type | text | 'daily'::text |  |
| daily_interval_days | integer |  |  |
| weekly_days | integer[] |  |  |
| weekly_interval_weeks | integer | 1 |  |
| monthly_days | integer[] |  |  |
| monthly_interval_months | integer | 1 |  |
| time_of_day | text | 'morning'::text |  |
| reminders | jsonb | '[]'::jsonb |  |
| xp_reward | integer | 10 |  |
| current_streak | integer | 0 |  |
| best_streak | integer | 0 |  |
| is_active | boolean | true |  |
| group_id | text |  |  |
| start_date | date |  |  |
| end_date | date |  |  |
| challenge_id | text |  |  |
| created_at | timestamptz | now() |  |
| updated_at | timestamptz | now() |  |
| quest_id | text |  |  |
| timer_setting | jsonb | '{}'::jsonb |  |
| target_value | varchar | NULL::character varying |  |
| full_description | text | 'انجام کامل عادت'::text |  |
| half_description | text | 'انجام نیمی از عادت'::text |  |
| basic_description | text | 'انجام حداقل عادت'::text |  |
| user_id | uuid |  | بله |
| id | uuid | gen_random_uuid() | بله |
| package_id | text |  |  |

## likes
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | uuid | gen_random_uuid() | بله |
| user_id | uuid |  |  |
| target_type | text |  |  |
| target_id | uuid |  | بله |
| created_at | timestamptz | now() |  |

## member_reports
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | uuid | gen_random_uuid() | بله |
| conversation_id | uuid |  | بله |
| reporter_id | uuid |  | بله |
| reported_user_id | uuid |  | بله |
| reason | text |  | بله |
| details | text |  |  |
| status | text | 'open'::text | بله |
| created_at | timestamptz | now() | بله |

## message_reactions
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | uuid | gen_random_uuid() | بله |
| message_id | uuid |  | بله |
| user_id | uuid |  | بله |
| emoji | text |  | بله |
| created_at | timestamptz | now() |  |

## messages
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | uuid | gen_random_uuid() | بله |
| conversation_id | uuid |  |  |
| sender_id | uuid |  |  |
| content | text |  | بله |
| type | text | 'text'::text |  |
| metadata | jsonb | '{}'::jsonb |  |
| is_read | boolean | false |  |
| created_at | timestamptz | now() |  |
| reply_to_id | uuid |  |  |
| is_deleted | boolean | false |  |
| is_edited | boolean | false |  |
| reactions | text[] | '{}'::text[] |  |
| reactions_by_user | jsonb | '{}'::jsonb |  |
| edited_at | timestamptz |  |  |
| deleted_at | timestamptz |  |  |
| hidden_for | text[] | '{}'::text[] |  |
| status | text | 'sent'::text |  |
| read_at | timestamptz |  |  |
| sender_name | text |  |  |
| is_pinned | boolean | false |  |
| pinned_at | timestamptz |  |  |
| pinned_by | text |  |  |

## packages
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | uuid | gen_random_uuid() | بله |
| title | text |  | بله |
| description | text |  |  |
| icon | text | 'fitness_center'::text |  |
| color | text | '#4A90E2'::text |  |
| background_color | text | '#F5F5F5'::text |  |
| category | text | 'other'::text |  |
| habits | jsonb | '[]'::jsonb |  |
| is_active | boolean | true |  |
| xp_reward | integer | 50 |  |
| badge | text | '📦'::text |  |
| created_at | timestamp | now() |  |
| full_description | text | 'انجام کامل عادت'::text |  |
| half_description | text | 'انجام نیمی از عادت'::text |  |
| basic_description | text | 'انجام حداقل عادت'::text |  |
| target_value | text |  |  |
| image_url | text |  |  |

## photo_likes
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | uuid | gen_random_uuid() | بله |
| photo_id | uuid |  | بله |
| user_id | uuid |  | بله |
| created_at | timestamptz | now() |  |

## profiles
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| email | text |  | بله |
| name | text |  | بله |
| total_xp | integer | 0 |  |
| created_at | timestamptz | now() |  |
| updated_at | timestamptz | now() |  |
| avatar_url | text |  |  |
| phone | text |  |  |
| birth_date | date |  |  |
| real_age | integer |  |  |
| gender | text |  |  |
| avatar_style | text | 'default'::text |  |
| skin_color | text | '#F5D0B8'::text |  |
| hair_style | text | 'default'::text |  |
| hair_color | text | '#4A3728'::text |  |
| eye_style | text | 'default'::text |  |
| eye_color | text | '#4A90E2'::text |  |
| mouth_style | text | 'default'::text |  |
| accessory_type | text | 'none'::text |  |
| outfit_style | text | 'default'::text |  |
| background_style | text | 'default'::text |  |
| weekly_streak | integer | 0 |  |
| last_streak_update | date |  |  |
| level | integer | 1 |  |
| xp_to_next_level | integer | 100 |  |
| current_streak | integer | 0 |  |
| best_streak | integer | 0 |  |
| last_streak_date | date |  |  |
| unique_id | text |  |  |
| last_seen_at | timestamptz | now() |  |
| bio | text |  |  |
| username | text |  |  |
| username_updated_at | timestamptz |  |  |
| user_id | uuid |  | بله |
| allow_buddy_requests | boolean | true | بله |

## quests
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | uuid | gen_random_uuid() | بله |
| title | text |  | بله |
| description | text |  |  |
| icon | text | 'flag'::text |  |
| color | text | '#FF9F43'::text |  |
| xp_reward | integer | 100 |  |
| badge | text | '🎯'::text |  |
| target_count | integer |  | بله |
| is_active | boolean | true |  |
| created_at | timestamp | now() |  |
| full_description | text | 'انجام کامل ماموریت'::text |  |
| half_description | text | 'انجام نیمی از ماموریت'::text |  |
| basic_description | text | 'انجام حداقل ماموریت'::text |  |
| target_value | text |  |  |
| image_url | text |  |  |

## quotes
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | text |  | بله |
| text | text |  | بله |
| author | text |  | بله |
| category | text |  |  |
| is_active | boolean | true |  |
| created_at | timestamptz | now() |  |

## tasks
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| title | text |  | بله |
| description | text |  |  |
| sub_tasks | text[] | '{}'::text[] |  |
| completed_sub_tasks | text[] | '{}'::text[] |  |
| due_date | date |  |  |
| is_completed | boolean | false |  |
| xp_reward | integer | 10 |  |
| created_at | timestamptz | now() |  |
| updated_at | timestamptz | now() |  |
| user_id | uuid |  | بله |
| id | uuid | gen_random_uuid() | بله |

## template_packages
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | text |  | بله |
| title | text |  | بله |
| description | text |  | بله |
| xp_reward | integer | 0 |  |
| color | text |  | بله |
| background_color | text |  | بله |
| icon | text |  | بله |
| habits | text |  |  |
| is_active | boolean | true |  |
| order | integer | 0 |  |
| created_at | timestamptz | now() |  |

## typing_status
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | uuid | gen_random_uuid() | بله |
| conversation_id | uuid |  | بله |
| user_id | uuid |  | بله |
| is_typing | boolean | false |  |
| updated_at | timestamptz | now() |  |

## user_badges
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | uuid | gen_random_uuid() | بله |
| user_id | uuid |  | بله |
| badge_name | text |  | بله |
| badge_icon | text |  | بله |
| is_active | boolean | true |  |
| earned_at | timestamp | now() |  |

## user_challenges
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | uuid | gen_random_uuid() | بله |
| challenge_id | text |  | بله |
| joined_at | timestamptz | now() |  |
| challenge_start_date | timestamptz |  |  |
| challenge_end_date | timestamptz |  |  |
| progress | integer | 0 |  |
| is_completed | boolean | false |  |
| is_active | boolean | true |  |
| status | text | 'active'::text |  |
| completed_at | timestamptz |  |  |
| created_at | timestamptz | now() |  |
| updated_at | timestamptz | now() |  |
| user_id | uuid |  | بله |

## user_cosmetics
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | text |  | بله |
| cosmetic_id | text |  | بله |
| is_active | boolean | false |  |
| purchased_at | text |  | بله |
| created_at | timestamptz | now() |  |
| updated_at | timestamptz | now() |  |
| user_id | uuid |  | بله |

## user_daily_activity
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | uuid | gen_random_uuid() | بله |
| activity_date | date |  | بله |
| habits_completed | integer | 0 |  |
| tasks_completed | integer | 0 |  |
| xp_earned | integer | 0 |  |
| is_active | boolean | false |  |
| created_at | timestamp | now() |  |
| updated_at | timestamp | now() |  |
| user_id | uuid |  | بله |

## user_onboarding
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| user_id | uuid |  | بله |
| goals | text[] | '{}'::text[] | بله |
| obstacle | text |  |  |
| level | text |  |  |
| wake_time | text |  |  |
| remind_time | text |  |  |
| language | text |  |  |
| created_at | timestamptz | now() | بله |
| updated_at | timestamptz | now() | بله |
| goal | text |  |  |
| first_task | text |  |  |
| energy | text |  |  |
| planning_style | text |  |  |

## user_packages
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | uuid | gen_random_uuid() | بله |
| user_id | uuid |  | بله |
| package_id | uuid |  | بله |
| is_active | boolean | true |  |
| added_at | timestamp | now() |  |
| removed_at | timestamp |  |  |
| created_at | timestamp | now() |  |

## user_personalities
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| user_id | uuid |  | بله |
| gender | text |  |  |
| personality_types | text[] | '{}'::text[] |  |
| mbti_type | text |  |  |
| interests | text[] | '{}'::text[] |  |
| habits | text[] | '{}'::text[] |  |
| goals | text[] | '{}'::text[] |  |
| bio | text |  |  |
| preferred_times | text[] | '{}'::text[] |  |
| experience_level | integer | 1 |  |
| updated_at | timestamptz | now() |  |
| created_at | timestamptz | now() |  |
| is_looking_for_buddy | boolean | true |  |

## user_photos
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | uuid | gen_random_uuid() | بله |
| photo_url | text |  | بله |
| caption | text |  |  |
| storage_path | text |  | بله |
| file_size | bigint |  |  |
| width | integer |  |  |
| height | integer |  |  |
| is_primary | boolean | false |  |
| display_order | integer | 0 |  |
| likes_count | integer | 0 |  |
| is_visible | boolean | true |  |
| created_at | timestamptz | now() |  |
| updated_at | timestamptz | now() |  |
| user_id | uuid |  | بله |

## user_progress
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | uuid | gen_random_uuid() | بله |
| user_id | uuid |  | بله |
| total_xp | integer | 0 |  |
| weekly_xp | integer | 0 |  |
| monthly_xp | integer | 0 |  |
| created_at | timestamp | now() |  |
| updated_at | timestamp | now() |  |

## user_quests
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | uuid | gen_random_uuid() | بله |
| user_id | uuid |  | بله |
| quest_id | uuid |  | بله |
| progress | integer | 0 |  |
| is_completed | boolean | false |  |
| started_at | timestamp | now() |  |
| completed_at | timestamp |  |  |
| is_active | boolean | true |  |
| created_at | timestamp | now() |  |
| habit_id | uuid |  |  |

## xp_gifts
| ستون | نوع | پیش‌فرض | الزامی |
|---|---|---|---|
| id | text |  | بله |
| sender_id | text |  | بله |
| sender_name | text |  | بله |
| receiver_id | text |  | بله |
| receiver_name | text |  | بله |
| amount | integer |  | بله |
| message | text |  |  |
| sent_at | timestamptz | now() | بله |
| is_delivered | boolean | false |  |
| delivered_at | timestamptz |  |  |
| status | text | 'pending'::text |  |
