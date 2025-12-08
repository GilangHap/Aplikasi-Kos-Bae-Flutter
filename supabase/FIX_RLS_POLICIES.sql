-- ================================================================
-- FIX RLS POLICIES - Run this in Supabase SQL Editor
-- ================================================================
-- Problem: Table profiles is empty, so RLS policies that check 
-- for admin role fail. This prevents data from being read.
-- ================================================================

-- OPTION 1: Temporarily disable RLS for development (QUICK FIX)
-- Uncomment these lines if you want to disable RLS temporarily:
-- ALTER TABLE public.tenants DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.rooms DISABLE ROW LEVEL SECURITY;

-- OPTION 2: Create profile for current logged-in user as admin
-- First, check your auth.users to get your user ID:
-- SELECT id, email FROM auth.users;

-- Then insert your profile (replace YOUR_USER_ID with actual UUID):
-- INSERT INTO public.profiles (id, full_name, phone, role)
-- VALUES ('YOUR_USER_ID', 'Admin Kos Bae', '081234567890', 'admin')
-- ON CONFLICT (id) DO UPDATE SET role = 'admin';

-- OPTION 3: Fix RLS policies to allow all authenticated users (Recommended for development)
-- This allows any authenticated user to perform all operations

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Authenticated users can view tenants" ON public.tenants;
DROP POLICY IF EXISTS "Admins can insert tenants" ON public.tenants;
DROP POLICY IF EXISTS "Admins can update tenants" ON public.tenants;
DROP POLICY IF EXISTS "Admins can delete tenants" ON public.tenants;
DROP POLICY IF EXISTS "Allow all for authenticated" ON public.tenants;

-- Create permissive policy for all authenticated users
CREATE POLICY "Allow all for authenticated"
  ON public.tenants
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Same for rooms table if needed
DROP POLICY IF EXISTS "Authenticated users can view rooms" ON public.rooms;
DROP POLICY IF EXISTS "Admins can insert rooms" ON public.rooms;
DROP POLICY IF EXISTS "Admins can update rooms" ON public.rooms;
DROP POLICY IF EXISTS "Admins can delete rooms" ON public.rooms;
DROP POLICY IF EXISTS "Allow all for authenticated rooms" ON public.rooms;

CREATE POLICY "Allow all for authenticated rooms"
  ON public.rooms
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- ================================================================
-- VERIFY DATA IS NOW ACCESSIBLE
-- ================================================================
SELECT 'Tenants count:' as info, COUNT(*) as count FROM public.tenants
UNION ALL
SELECT 'Rooms count:' as info, COUNT(*) as count FROM public.rooms;

-- ================================================================
-- OPTIONAL: Create admin profile from existing auth user
-- ================================================================
-- This will create a profile for the first user in auth.users as admin
-- Uncomment and run if needed:

/*
INSERT INTO public.profiles (id, full_name, phone, role)
SELECT 
  id,
  COALESCE(raw_user_meta_data->>'full_name', email) as full_name,
  raw_user_meta_data->>'phone' as phone,
  'admin' as role
FROM auth.users
LIMIT 1
ON CONFLICT (id) DO UPDATE SET role = 'admin';
*/

-- Check profiles table
SELECT * FROM public.profiles;

-- Check tenants table
SELECT * FROM public.tenants;
