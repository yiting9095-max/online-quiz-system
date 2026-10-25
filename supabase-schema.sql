-- 室內配線丙級線上測驗系統
-- 在 Supabase Dashboard > SQL Editor 執行整份 SQL。
-- 題目選項存成 JSON 陣列，例如 ["選項一","選項二","選項三","選項四"]。
-- correct_index 使用 0 起算：0=A、1=B、2=C、3=D。

create extension if not exists pgcrypto;

create table if not exists public.questions (
  id uuid primary key default gen_random_uuid(),
  category text not null check (category in ('common','professional')),
  category_label text not null,
  chapter text not null default '未分類',
  question_text text not null,
  options jsonb not null check (jsonb_typeof(options) = 'array'),
  correct_index integer not null check (correct_index >= 0),
  explanation text not null default '',
  source_name text not null default '',
  source_page integer,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  check (correct_index < jsonb_array_length(options))
);

create table if not exists public.user_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  question_id uuid not null references public.questions(id) on delete cascade,
  attempts integer not null default 0 check (attempts >= 0),
  correct_count integer not null default 0 check (correct_count >= 0),
  wrong_count integer not null default 0 check (wrong_count >= 0),
  recent_results jsonb not null default '[]'::jsonb,
  last_answer_index integer,
  last_answer_correct boolean,
  last_answered_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key (user_id, question_id),
  check (correct_count + wrong_count = attempts)
);

alter table public.questions enable row level security;
alter table public.user_progress enable row level security;

-- 登入使用者可以讀取已啟用題目；題目新增/修改由管理者在 Dashboard 執行。
drop policy if exists "Signed-in users can read active questions" on public.questions;
create policy "Signed-in users can read active questions"
  on public.questions for select to authenticated
  using (is_active = true);

drop policy if exists "Users can read their own progress" on public.user_progress;
create policy "Users can read their own progress"
  on public.user_progress for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can insert their own progress" on public.user_progress;
create policy "Users can insert their own progress"
  on public.user_progress for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can update their own progress" on public.user_progress;
create policy "Users can update their own progress"
  on public.user_progress for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

grant select on public.questions to authenticated;
grant select, insert, update on public.user_progress to authenticated;

create index if not exists questions_category_chapter_idx
  on public.questions(category, chapter);
create index if not exists user_progress_user_idx
  on public.user_progress(user_id);
