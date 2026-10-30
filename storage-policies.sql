-- Run after creating a PRIVATE bucket named `study-materials`.
-- Object path convention: <auth.uid()>/<uuid>/<filename>
-- Never make this bucket public for private student documents.

create policy "Users can read their own study materials"
on storage.objects for select
to authenticated
using (
  bucket_id = 'study-materials'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users can upload their own study materials"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'study-materials'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users can update their own study materials"
on storage.objects for update
to authenticated
using (
  bucket_id = 'study-materials'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'study-materials'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users can delete their own study materials"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'study-materials'
  and (storage.foldername(name))[1] = auth.uid()::text
);
