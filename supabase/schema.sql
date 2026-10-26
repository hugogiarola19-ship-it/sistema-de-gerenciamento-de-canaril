-- Canaril: tabela de dados por usuário, protegida por RLS.
-- Rode uma vez no Supabase: SQL Editor → New query → cole tudo → Run.
create table if not exists public.canaril_docs (
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  chave text not null,
  dados jsonb not null,
  atualizado_em timestamptz not null default now(),
  primary key (user_id, chave)
);

alter table public.canaril_docs enable row level security;

create policy "dono le"     on public.canaril_docs for select using (auth.uid() = user_id);
create policy "dono insere" on public.canaril_docs for insert with check (auth.uid() = user_id);
create policy "dono altera" on public.canaril_docs for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "dono apaga"  on public.canaril_docs for delete using (auth.uid() = user_id);
