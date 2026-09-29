-- Glow Up backend for Supabase (Postgres + Auth + Storage). Run in the SQL editor.
create table profiles(id uuid primary key references auth.users on delete cascade,
 username text unique not null check(length(username) between 3 and 24),
 birth_date date not null, sex text, height_cm numeric, weight_kg numeric,
 skin_type text, skin_tone int, hair_type text, face_shape text, goal text,
 activity int, equipment text, premium boolean not null default false, created_at timestamptz default now());
create table logs(user_id uuid references profiles on delete cascade, day date, weight_kg numeric, waist_cm numeric, primary key(user_id,day));
create table checks(user_id uuid references profiles on delete cascade, day date, item text, primary key(user_id,day,item));
create table photos(id bigserial primary key, user_id uuid references profiles on delete cascade, kind text, path text, day date default current_date);
create table posts(id bigserial primary key, user_id uuid references profiles on delete cascade, title text not null, body text not null, hidden boolean default false, created_at timestamptz default now());
create table comments(id bigserial primary key, post_id bigint references posts on delete cascade, user_id uuid references profiles on delete cascade, body text not null, hidden boolean default false, created_at timestamptz default now());
create table reports(id bigserial primary key, reporter_id uuid, post_id bigint, comment_id bigint, reason text, created_at timestamptz default now());
create table blocks(blocker_id uuid, blocked_id uuid, primary key(blocker_id,blocked_id));
create table messages(id bigserial primary key, sender_id uuid references profiles, recipient_id uuid references profiles, body text not null check(length(body)<=1000), created_at timestamptz default now());

create function is_adult(u uuid) returns boolean language sql stable security definer as
 $$ select coalesce((select age(birth_date)>=interval '18 years' from profiles where id=u),false) $$;
create function is_premium(u uuid) returns boolean language sql stable security definer as
 $$ select coalesce((select premium from profiles where id=u),false) $$;

alter table profiles enable row level security; alter table logs enable row level security; alter table checks enable row level security;
alter table photos enable row level security; alter table posts enable row level security; alter table comments enable row level security;
alter table reports enable row level security; alter table blocks enable row level security; alter table messages enable row level security;

-- private data: owner only
create policy own_profile on profiles for all using(id=auth.uid()) with check(id=auth.uid() and premium=(select premium from profiles where id=auth.uid()));
create policy own_logs on logs for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy own_checks on checks for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy own_photos on photos for all using(user_id=auth.uid()) with check(user_id=auth.uid());
-- community: everyone signed in reads visible content, writes as self
create policy read_posts on posts for select using(auth.uid() is not null and not hidden);
create policy write_posts on posts for insert with check(user_id=auth.uid());
create policy read_comments on comments for select using(auth.uid() is not null and not hidden);
create policy write_comments on comments for insert with check(user_id=auth.uid());
create policy file_report on reports for insert with check(reporter_id=auth.uid());
create policy own_blocks on blocks for all using(blocker_id=auth.uid()) with check(blocker_id=auth.uid());
-- DMs: premium + 18+ on both sides, never to someone who blocked you
create policy read_dm on messages for select using(auth.uid() in(sender_id,recipient_id));
create policy send_dm on messages for insert with check(sender_id=auth.uid() and is_premium(auth.uid()) and is_adult(auth.uid()) and is_adult(recipient_id)
 and not exists(select 1 from blocks where blocker_id=recipient_id and blocked_id=auth.uid()));
-- Storage: create a PRIVATE bucket "progress-photos"; policy: path must start with auth.uid()::text || '/'.
-- Set profiles.premium only from a server webhook (Google Play / RevenueCat), never from the app.
