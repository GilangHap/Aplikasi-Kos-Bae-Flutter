-- ================================================================
-- REMOVE REDUNDANT FIELDS FROM TENANTS TABLE
-- Migration Script - Run this in Supabase SQL Editor
-- ================================================================

-- IMPORTANT: This will drop columns. Make sure you have backups!
-- If you have existing data with room_id but no contract_id,
-- consider creating contracts first before running this migration.

-- 1. Drop redundant columns from tenants table
ALTER TABLE public.tenants DROP COLUMN IF EXISTS room_id;
ALTER TABLE public.tenants DROP COLUMN IF EXISTS check_in_date;
ALTER TABLE public.tenants DROP COLUMN IF EXISTS check_out_date;

-- 2. Verify columns were dropped
SELECT 
  column_name, 
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'tenants'
ORDER BY ordinal_position;

-- 3. Expected columns after migration:
-- id, name, phone, nik, address, photo_url, status, 
-- created_at, updated_at, user_id, contract_id

COMMENT ON TABLE public.tenants IS 'Tenant information - room and dates retrieved from contracts table via contract_id';
