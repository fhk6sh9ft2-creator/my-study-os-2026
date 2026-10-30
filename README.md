# MY STUDY OS

A clean Next.js 15 starter for a personal study workspace.

## Requirements
- Node.js 20+
- Supabase project
- Private Storage bucket named `study-materials` (Public bucket OFF)
- Storage policies restricting each signed-in user to their own folder

## Netlify environment variables
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` (Supabase Publishable key)

Never put a `service_role` or `sb_secret_` key in a `NEXT_PUBLIC_` variable.

## Netlify build settings
- Base directory: repository root (leave blank)
- Build command: `npm run build`
- Publish directory: leave blank / use Netlify's Next.js runtime integration
- Install command: `npm install`

## Current scope
Includes six subject landing cards, email sign-in/sign-up, and a private-bucket upload flow. OCR, PDF text extraction, AI search/embeddings, study planner persistence, and production security review are not yet implemented. Configure and test Supabase Auth redirect URLs and Storage RLS policies before public launch.
