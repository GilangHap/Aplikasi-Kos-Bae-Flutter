-- =====================================================
-- FIX TENANT USER_ID LINKAGE
-- Run this in Supabase SQL Editor
-- =====================================================

-- 1. Check current status: Which tenants have user_id linked?
SELECT 
    t.id,
    t.name,
    t.phone,
    t.user_id,
    u.email
FROM public.tenants t
LEFT JOIN auth.users u ON t.user_id = u.id
ORDER BY t.name;

-- 2. Check auth users and their profiles
SELECT 
    u.id,
    u.email,
    p.full_name,
    p.role
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.role = 'tenant' OR p.role IS NULL;

-- =====================================================
-- FIX: Link existing tenant to user by email
-- =====================================================
-- Replace 'TENANT_EMAIL@example.com' with the actual email
-- Replace 'TENANT_PHONE' with the phone from tenants table

/*
-- Option A: Link by email (if you know the tenant's email)
UPDATE public.tenants 
SET user_id = (SELECT id FROM auth.users WHERE email = 'TENANT_EMAIL@example.com')
WHERE phone = 'TENANT_PHONE' AND user_id IS NULL;
*/

/*
-- Option B: Link by name (if profile full_name matches tenant name)
UPDATE public.tenants t
SET user_id = u.id
FROM auth.users u
JOIN public.profiles p ON u.id = p.id
WHERE p.full_name = t.name
AND t.user_id IS NULL
AND p.role = 'tenant';
*/

-- =====================================================
-- CREATE USER FOR EXISTING TENANT (Optional)
-- =====================================================
-- If a tenant exists BUT has no user account, admin should:
-- 1. Go to Admin > Penghuni > Edit the tenant
-- 2. Fill in Email & Password fields
-- 3. Save - this will create the auth user and link it

-- NOTE: The app now automatically handles this in tenant_form_controller.dart
-- When creating a new tenant with email/password, it will:
-- 1. Create auth.users record
-- 2. Create public.profiles record with role='tenant'
-- 3. Insert public.tenants record with user_id = the new user's ID

-- =====================================================
-- VERIFY FIX
-- =====================================================
-- Run this after fixing to confirm user_id is linked:
SELECT 
    t.id as tenant_id,
    t.name,
    t.status,
    t.user_id,
    CASE WHEN t.user_id IS NOT NULL THEN '✅ Linked' ELSE '❌ Not Linked' END as link_status
FROM public.tenants t
ORDER BY t.name;
