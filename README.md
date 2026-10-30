# MY STUDY OS — V1.1 Development Build

A multilingual, open-source learning workspace for six subjects, study planning, focus timing, and learning materials.

## Current features

- Dashboard with study-time timer and task completion progress
- Six subject spaces: Sejarah, English, Bahasa Melayu, Science, Mathematics, Moral
- Interface language switcher: 简体中文 / English / Bahasa Melayu
- Materials library with multi-file selection and subject filter
- Supabase account-aware private material listing, upload, signed-link opening and deletion when configured
- Empty starter library (no retired sample PDFs are included)
- Tasks can be added and marked complete
- Demo state persists in the current browser via `localStorage`

## Important demo limitations

This build is still a **development prototype**, not yet a public production service. Cloud library features require the user to configure Supabase and apply the supplied SQL policies.

- Without Supabase credentials and a configured private bucket, uploads remain demo-only metadata in the browser; file bytes are not uploaded.
- With Supabase configured and a signed-in account, files are uploaded to the private `study-materials` bucket and listed through owner-scoped database policies.
- The included Sejarah trial PDF is represented as a sample library entry; it is not bundled into this repository.
- OCR, PDF text extraction, AI search, embeddings and cross-device task/session sync are not implemented yet.
- The sample study tasks and analytics are illustrative demo data.

## Run locally

Requirements: Node.js 20.9+ and npm.

```bash
npm install
npm run dev
```

Open http://localhost:3000.

## Next implementation milestones

1. Complete and test Supabase Auth, account recovery and session management.
2. Configure the private Supabase Storage bucket and apply per-user access policies.
3. Implement background processing, OCR and PDF text extraction.
4. Store extracted chunks and embeddings; implement owner-scoped semantic search with citations to file and page.
5. Add notes editor, PDF reader/annotations, planner calendar, durable study sessions and analytics.
6. Add AI provider abstraction with server-side keys, rate limits, quotas and source-grounded answers.
7. Add production monitoring, backups, privacy policy, terms, abuse controls and accessibility testing.

## Supabase setup

1. Create a Supabase project.
2. Review and run `supabase/schema.sql` in the SQL editor.
3. Create a **private** storage bucket named `study-materials`.
4. Add storage policies that restrict each user's objects to their own user ID folder.
5. Copy `.env.example` to `.env.local` and add project credentials.

Never expose `SUPABASE_SERVICE_ROLE_KEY` or an AI provider key to client-side code.

## Open source

The project is intended to use the MIT License. Review third-party dependency licenses before redistribution. See `LICENSE`.

## Privacy and public access

Public registration means people can create accounts; it must not mean their uploaded PDFs, notes, tasks or study sessions are public. User-owned records must remain private through authentication and Row Level Security.


## Private material upload helper

`lib/materials/upload.ts` provides a browser-side upload helper that:
- requires an authenticated Supabase user;
- checks file extension and a 50 MB per-file limit;
- stores each file under that user's UUID folder in a private bucket;
- creates a `materials` database row;
- attempts to remove the uploaded object if the database insert fails.

The current dashboard's demo upload control is intentionally still local-only. Wire this helper into the authenticated materials page after the sign-in/session experience is tested. The 50 MB limit is an initial application guardrail and should be aligned with the storage provider's configured limits.


## AI cross-material search foundation

`supabase/ai-search.sql` adds a pgvector HNSW index and an owner-scoped similarity-search function. It returns matching text chunks with source material IDs and page numbers, and can optionally restrict results to one subject. The function is `SECURITY INVOKER` and explicitly filters by `auth.uid()`; keep RLS enabled.

This is the database retrieval foundation only. A complete grounded AI answer still needs:
- a trusted server-side extraction/OCR worker;
- chunking that preserves source page numbers;
- an embedding provider adapter (API key stored server-side);
- rate limits and per-user quotas;
- a server endpoint that retrieves only the signed-in user's chunks and asks the model to cite file name and page;
- tests proving that one user cannot retrieve another user's chunks.

The SQL assumes 1536-dimensional embeddings. Confirm your chosen embedding provider's output dimension before production use.


## V1.1 progress

The materials library now detects a configured signed-in Supabase account, loads only that account's materials, uploads to its private storage path, opens files with short-lived signed URLs, and supports deletion. If Supabase is not configured, the interface clearly labels local demo metadata and does not claim the file was uploaded.
