-- Create study-materials bucket with Public bucket OFF.
create policy "Users can upload own study materials" on storage.objects for insert to authenticated with check (bucket_id='study-materials' and (storage.foldername(name))[1]=auth.uid()::text);
create policy "Users can read own study materials" on storage.objects for select to authenticated using (bucket_id='study-materials' and (storage.foldername(name))[1]=auth.uid()::text);
create policy "Users can delete own study materials" on storage.objects for delete to authenticated using (bucket_id='study-materials' and (storage.foldername(name))[1]=auth.uid()::text);
