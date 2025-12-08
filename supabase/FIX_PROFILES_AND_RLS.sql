-- ================================================================
-- FIX ALL RLS - Tables AND Storage
-- Run this in Supabase SQL Editor
-- ================================================================

-- ==================== PART 1: FIX TABLE RLS ====================

-- Disable RLS for all tables (simple fix for development)
ALTER TABLE public.tenants DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.rooms DISABLE ROW LEVEL SECURITY;

-- Profiles table (create if not exists)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  phone TEXT,
  role TEXT DEFAULT 'admin',
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- ==================== PART 2: FIX STORAGE RLS ====================

-- Create storage bucket if not exists (run in Dashboard > Storage instead if this fails)
-- INSERT INTO storage.buckets (id, name, public) 
-- VALUES ('kos-bae-storage', 'kos-bae-storage', true)
-- ON CONFLICT (id) DO UPDATE SET public = true;

-- Drop existing storage policies
DROP POLICY IF EXISTS "Allow public read" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated upload" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated update" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated delete" ON storage.objects;
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete" ON storage.objects;
DROP POLICY IF EXISTS "Give users access to own folder" ON storage.objects;
DROP POLICY IF EXISTS "Allow all operations for authenticated" ON storage.objects;

-- Create permissive storage policies for kos-bae-storage bucket

-- 1. Anyone can READ/VIEW files (public bucket)
CREATE POLICY "Public read access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'kos-bae-storage');

-- 2. Authenticated users can UPLOAD files
CREATE POLICY "Authenticated users can upload"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'kos-bae-storage');

-- 3. Authenticated users can UPDATE files
CREATE POLICY "Authenticated users can update"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'kos-bae-storage');

-- 4. Authenticated users can DELETE files
CREATE POLICY "Authenticated users can delete"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'kos-bae-storage');

-- ==================== PART 3: VERIFY ====================

-- Check table RLS status
SELECT 
  schemaname, 
  tablename, 
  rowsecurity 
FROM pg_tables 
WHERE tablename IN ('tenants', 'rooms', 'profiles');

-- Check storage policies
SELECT policyname, tablename, cmd 
FROM pg_policies 
WHERE tablename = 'objects' AND schemaname = 'storage';

-- Count data
SELECT 'Tenants' as tbl, COUNT(*) as cnt FROM public.tenants
UNION ALL
SELECT 'Rooms' as tbl, COUNT(*) as cnt FROM public.rooms;
