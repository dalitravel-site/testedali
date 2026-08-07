/**
 * Seed único: baixa as imagens exportadas do Figma (válidas por ~7 dias)
 * e sobe para o bucket "pagina-inicial-imagens" no Supabase, depois
 * grava as URLs públicas na tabela pagina_inicial.
 *
 * Rode isso UMA VEZ, o quanto antes (as URLs do Figma expiram).
 * Como rodar:
 *  1) node seed-imagens-pagina-inicial.js   (com Node 18+, que já tem fetch)
 *  2) ou cole o conteúdo no console do navegador, numa aba logada como admin
 *
 * Preencha SUPABASE_URL e SUPABASE_SERVICE_KEY (ou anon key + login admin)
 * antes de rodar.
 */

import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://SEU-PROJETO.supabase.co';
const SUPABASE_KEY = 'SUA_SERVICE_ROLE_OU_ANON_KEY';

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);
const BUCKET = 'pagina-inicial-imagens';

// URLs geradas pelo Figma MCP para o node 2:3 (expiram em ~7 dias)
const assets = {
  hero_bg_url: {
    src: 'https://www.figma.com/api/mcp/asset/a79d758c-258f-43b1-8795-3a5b98b8a416.png',
    filename: 'hero-bg.png',
  },
  logo_url: {
    src: 'https://www.figma.com/api/mcp/asset/f546dfde-cdef-4cf3-b593-2cd0a38bbc05.png',
    filename: 'logo.png',
  },
  hero_card_imagem_url: {
    src: 'https://www.figma.com/api/mcp/asset/a110df4e-c2e7-4ad8-8fb1-4c68d212e82e.png',
    filename: 'hero-card.png',
  },
  banner_imagem_url: {
    src: 'https://www.figma.com/api/mcp/asset/95ba4f38-ac11-46fb-9f19-1b51936d9cca.png',
    filename: 'banner-icone.png',
  },
};

async function subirImagem(campo, { src, filename }) {
  const resp = await fetch(src);
  if (!resp.ok) throw new Error(`Falha ao baixar ${filename}: ${resp.status}`);
  const blob = await resp.blob();

  const path = `inicial/${filename}`;
  const { error: uploadError } = await supabase.storage
    .from(BUCKET)
    .upload(path, blob, { upsert: true, contentType: blob.type });

  if (uploadError) throw uploadError;

  const { data } = supabase.storage.from(BUCKET).getPublicUrl(path);
  return { campo, url: data.publicUrl };
}

async function main() {
  const resultados = await Promise.all(
    Object.entries(assets).map(([campo, info]) => subirImagem(campo, info))
  );

  const update = {};
  for (const { campo, url } of resultados) update[campo] = url;

  const { error } = await supabase
    .from('pagina_inicial')
    .update(update)
    .eq('id', 1);

  if (error) throw error;

  console.log('Imagens migradas para o Supabase Storage e tabela atualizada:', update);
}

main().catch((err) => {
  console.error('Erro no seed de imagens:', err);
  process.exit(1);
});
