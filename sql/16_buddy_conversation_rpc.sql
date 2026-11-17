-- 16: ساخت/پیدا کردن گفتگوی هم‌مسیر در سرور (بدون وابستگی به RLS و بدون گفتگوی تکراری)
-- با دکمه‌ی هر هم‌مسیر در تب هم‌مسیرها، گفتگو اگر نبود ساخته می‌شود.
create or replace function public.get_or_create_buddy_conversation(other uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  me  uuid := auth.uid();
  cid uuid;
begin
  if me is null then raise exception 'not authenticated'; end if;
  if other is null or other = me then raise exception 'invalid user'; end if;

  if not exists (
    select 1 from buddy_requests
    where status = 'accepted'
      and ((from_user_id = me and to_user_id = other)
        or (from_user_id = other and to_user_id = me))
  ) then
    raise exception 'not buddies';
  end if;

  -- لمس‌های پشت‌سرهم/هم‌زمان فقط یک گفتگو بسازند
  perform pg_advisory_xact_lock(hashtext(least(me::text, other::text) || greatest(me::text, other::text)));

  select c.id into cid
  from conversations c
  where c.type = 'buddy'
    and c.is_active is not false
    and exists (select 1 from conversation_members m where m.conversation_id = c.id and m.user_id = me)
    and exists (select 1 from conversation_members m where m.conversation_id = c.id and m.user_id = other)
  order by c.created_at
  limit 1;

  if cid is null then
    insert into conversations (type, created_by, is_active, last_message_at)
    values ('buddy', me, true, now())
    returning id into cid;
  end if;

  -- عضویت هر دو نفر (اگر یکی‌شان قبلاً حذف شده بود، برمی‌گردد)
  insert into conversation_members (conversation_id, user_id, role)
  select cid, u, case when u = me then 'admin' else 'member' end
  from unnest(array[me, other]) as u
  where not exists (
    select 1 from conversation_members m where m.conversation_id = cid and m.user_id = u
  );

  return cid;
end;
$$;

grant execute on function public.get_or_create_buddy_conversation(uuid) to authenticated;
