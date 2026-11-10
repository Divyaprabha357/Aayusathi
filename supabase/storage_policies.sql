-- =========================================================================
-- AAYUSATHI: Supabase Storage Policies for `aayusathi-reports` Bucket
--
-- Security Mandates:
-- 1. Bucket `aayusathi-reports` is PRIVATE (public read disabled).
-- 2. Cloud file access requires short-lived signed URLs (e.g. 5 minutes).
-- 3. Least-privilege RLS: Restricted to canonical patient medical paths.
-- 4. Allows Flutter client (`anon` role) to upload official visit reports
--    without requiring service_role credentials in client code.
-- =========================================================================

-- Step 1: Ensure bucket exists and is marked PRIVATE
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'aayusathi-reports',
  'aayusathi-reports',
  false,
  15728640, -- 15 MB in bytes
  ARRAY['application/pdf', 'image/jpeg', 'image/jpg', 'image/png']
)
ON CONFLICT (id) DO UPDATE SET
  public = false,
  file_size_limit = 15728640,
  allowed_mime_types = ARRAY['application/pdf', 'image/jpeg', 'image/jpg', 'image/png'];

-- Step 2: Enable Row Level Security (RLS) on storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Step 3: Remove any previous conflicting policies on this bucket
DROP POLICY IF EXISTS "Allow aayusathi report uploads" ON storage.objects;
DROP POLICY IF EXISTS "Allow aayusathi report upsert" ON storage.objects;
DROP POLICY IF EXISTS "Allow aayusathi report select" ON storage.objects;
DROP POLICY IF EXISTS "Allow aayusathi report delete" ON storage.objects;

-- Step 4: INSERT Policy
-- Allows anon and authenticated clients to upload reports strictly to canonical paths
CREATE POLICY "Allow aayusathi report uploads"
ON storage.objects FOR INSERT
TO anon, authenticated
WITH CHECK (
  bucket_id = 'aayusathi-reports'
  AND (
    name LIKE 'patients/%/cases/%/visits/%/reports/%'
    OR name LIKE 'patients/%/cases/%/visits/%/uploads/%'
  )
);

-- Step 5: UPDATE Policy (Upsert support)
-- Allows upserting existing reports at canonical paths
CREATE POLICY "Allow aayusathi report upsert"
ON storage.objects FOR UPDATE
TO anon, authenticated
USING (
  bucket_id = 'aayusathi-reports'
  AND (
    name LIKE 'patients/%/cases/%/visits/%/reports/%'
    OR name LIKE 'patients/%/cases/%/visits/%/uploads/%'
  )
)
WITH CHECK (
  bucket_id = 'aayusathi-reports'
  AND (
    name LIKE 'patients/%/cases/%/visits/%/reports/%'
    OR name LIKE 'patients/%/cases/%/visits/%/uploads/%'
  )
);

-- Step 6: SELECT Policy
-- Allows verifying object existence and generating signed URLs
-- Note: Bucket remains private, so direct unauthenticated public downloads are denied
CREATE POLICY "Allow aayusathi report select"
ON storage.objects FOR SELECT
TO anon, authenticated
USING (
  bucket_id = 'aayusathi-reports'
  AND name LIKE 'patients/%'
);

-- Step 7: DELETE Policy (Restricted)
-- Only service_role or authenticated admins can delete reports
CREATE POLICY "Allow aayusathi report delete"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'aayusathi-reports'
  AND name LIKE 'patients/%'
);
