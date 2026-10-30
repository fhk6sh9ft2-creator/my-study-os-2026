import { createClient } from "@/lib/supabase/client";

const MAX_FILE_BYTES = 50 * 1024 * 1024;
const ALLOWED_EXTENSIONS = new Set(["pdf", "doc", "docx", "ppt", "pptx", "txt", "md", "png", "jpg", "jpeg", "webp"]);

export type UploadResult = {
  materialId: string;
  storagePath: string;
  originalFilename: string;
};

/**
 * Upload one private learning material.
 * Requires the private `study-materials` bucket, schema.sql and storage-policies.sql.
 * Files are stored under the authenticated user's UUID folder.
 */
export async function uploadLearningMaterial(file: File, subjectId?: string): Promise<UploadResult> {
  const extension = file.name.split(".").pop()?.toLowerCase() ?? "";
  if (!ALLOWED_EXTENSIONS.has(extension)) {
    throw new Error("Unsupported file type. Choose PDF, Office documents, text, Markdown or an image.");
  }
  if (file.size <= 0 || file.size > MAX_FILE_BYTES) {
    throw new Error("File must be smaller than 50 MB.");
  }

  const supabase = createClient();
  const { data: authData, error: authError } = await supabase.auth.getUser();
  if (authError || !authData.user) throw new Error("Please sign in before uploading materials.");

  const ownerId = authData.user.id;
  const safeName = file.name.replace(/[^a-zA-Z0-9._-]/g, "_").slice(-120);
  const storagePath = `${ownerId}/${crypto.randomUUID()}/${safeName}`;

  const { error: uploadError } = await supabase.storage
    .from("study-materials")
    .upload(storagePath, file, { contentType: file.type || "application/octet-stream", upsert: false });

  if (uploadError) throw uploadError;

  const { data: row, error: insertError } = await supabase
    .from("materials")
    .insert({
      owner_id: ownerId,
      subject_id: subjectId || null,
      title: file.name,
      original_filename: file.name,
      storage_path: storagePath,
      mime_type: file.type || "application/octet-stream",
      file_size_bytes: file.size,
      processing_status: "queued",
    })
    .select("id")
    .single();

  if (insertError) {
    // Avoid leaving an orphaned object if metadata insertion fails.
    await supabase.storage.from("study-materials").remove([storagePath]);
    throw insertError;
  }

  return { materialId: row.id, storagePath, originalFilename: file.name };
}
