-- ===================================================================
-- PÁGINA INICIAL — tabela de conteúdo + bucket de imagens (Supabase)
-- Rode este script inteiro no SQL Editor do seu projeto Supabase.
-- ===================================================================

-- 1) Tabela de conteúdo (linha única, id fixo = 1)
create table if not exists public.pagina_inicial (
  id smallint primary key default 1,
  constraint pagina_inicial_singleton check (id = 1),

  -- Menu
  logo_url text,
  menu_sobre_nos_label text default 'Sobre Nós',
  menu_sobre_nos_link text default '#sobre-nos',
  menu_viagens_label text default 'Viagens',
  menu_viagens_link text default '#viagens',
  menu_negocios_label text default 'Negócios',
  menu_negocios_link text default '#negocios',
  menu_contato_label text default 'Contato',
  menu_contato_link text default '#contato',

  -- Hero
  hero_bg_url text,
  hero_titulo_linha1 text default 'Pácoa na',
  hero_titulo_linha2 text default 'Finlândia',
  hero_local text default 'Finlândia',
  hero_tipo text default 'Turismo',
  hero_data text default '22 a 31 de Março',
  hero_botao_texto text default 'Conheça',
  hero_botao_link text default '#',

  -- Card "próxima experiência"
  hero_card_imagem_url text,
  hero_card_label text default 'Próxima',
  hero_card_titulo text default 'Navegar é preciso',
  hero_card_tag1 text default 'Amazonia',
  hero_card_tag2 text default 'Cultural',
  hero_card_link text default '#',

  -- Banner
  banner_titulo_linha1 text default 'Experimente',
  banner_titulo_linha2 text default 'um novo olhar',
  banner_texto text default 'Fugimos do óbvio para conectar você à alma de cada destino. Combinamos parceiros de excelência e olhar apurado para entregar experiências verdadeiramente autênticas e memoráveis.',
  banner_imagem_url text,

  updated_at timestamptz not null default now()
);

-- garante que sempre existe a linha única
insert into public.pagina_inicial (id)
values (1)
on conflict (id) do nothing;

-- atualiza updated_at automaticamente
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_pagina_inicial_updated_at on public.pagina_inicial;
create trigger trg_pagina_inicial_updated_at
before update on public.pagina_inicial
for each row execute function public.set_updated_at();

-- 2) RLS: leitura pública, escrita só para autenticados (admins convidados)
alter table public.pagina_inicial enable row level security;

drop policy if exists "pagina_inicial_select_publica" on public.pagina_inicial;
create policy "pagina_inicial_select_publica"
on public.pagina_inicial for select
to anon, authenticated
using (true);

drop policy if exists "pagina_inicial_update_autenticados" on public.pagina_inicial;
create policy "pagina_inicial_update_autenticados"
on public.pagina_inicial for update
to authenticated
using (true)
with check (true);

-- 3) Bucket de imagens (público para leitura, upload só autenticado)
insert into storage.buckets (id, name, public)
values ('pagina-inicial-imagens', 'pagina-inicial-imagens', true)
on conflict (id) do nothing;

drop policy if exists "pagina_inicial_imagens_leitura_publica" on storage.objects;
create policy "pagina_inicial_imagens_leitura_publica"
on storage.objects for select
to anon, authenticated
using (bucket_id = 'pagina-inicial-imagens');

drop policy if exists "pagina_inicial_imagens_upload_autenticado" on storage.objects;
create policy "pagina_inicial_imagens_upload_autenticado"
on storage.objects for insert
to authenticated
with check (bucket_id = 'pagina-inicial-imagens');

drop policy if exists "pagina_inicial_imagens_update_autenticado" on storage.objects;
create policy "pagina_inicial_imagens_update_autenticado"
on storage.objects for update
to authenticated
using (bucket_id = 'pagina-inicial-imagens');
