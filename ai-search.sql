-- MY STUDY OS — owner-scoped semantic retrieval (RAG) starter.
-- Embedding dimension is 1536; keep this consistent with the embedding model you choose.
-- If you select a model with another dimension, update the column, index and function together.

create index if not exists material_chunks_embedding_hnsw
on public.material_chunks using hnsw (embedding vector_cosine_ops);

create or replace function public.match_material_chunks(
  query_embedding vector(1536),
  match_count integer default 8,
  filter_subject uuid default null
)
returns table (
  chunk_id uuid,
  material_id uuid,
  page_number integer,
  chunk_text text,
  similarity double precision
)
language sql
stable
security invoker
set search_path = ''
as $$
  select
    c.id,
    c.material_id,
    c.page_number,
    c.chunk_text,
    1 - (c.embedding <=> query_embedding) as similarity
  from public.material_chunks c
  join public.materials m on m.id = c.material_id
  where c.owner_id = auth.uid()
    and m.owner_id = auth.uid()
    and (filter_subject is null or m.subject_id = filter_subject)
    and c.embedding is not null
  order by c.embedding <=> query_embedding
  limit greatest(1, least(match_count, 30));
$$;

grant execute on function public.match_material_chunks(vector, integer, uuid) to authenticated;
