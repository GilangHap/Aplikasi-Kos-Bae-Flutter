-- =====================================================
-- RESET DATABASE - Keep Only Rooms
-- Run this in Supabase SQL Editor
-- =====================================================
-- WARNING: This will DELETE all data except rooms!
-- Make sure you have a backup if needed.
-- =====================================================

-- 1. Disable triggers temporarily (optional, for speed)
-- ALTER TABLE public.tenants DISABLE TRIGGER ALL;
-- ALTER TABLE public.contracts DISABLE TRIGGER ALL;

-- 2. Delete in order of dependencies (child tables first)

-- Delete announcement reads first (references announcements and tenants)
DELETE FROM public.announcement_reads;

-- Delete announcements
DELETE FROM public.announcements;

-- Delete complaint status history (references complaints)
DELETE FROM public.complaint_status_history;

-- Delete complaints (references tenants and rooms)
DELETE FROM public.complaints;

-- Delete payments (references bills)
DELETE FROM public.payments;

-- Delete bills (references tenants, rooms, contracts)
DELETE FROM public.bills;

-- Delete contracts (references tenants and rooms)
DELETE FROM public.contracts;

-- Delete tenants (references auth.users via user_id)
DELETE FROM public.tenants;

-- Delete profiles (except admin)
DELETE FROM public.profiles WHERE role != 'admin';

-- 3. Delete auth users (except admin)
-- Note: This also cascades to profiles if ON DELETE CASCADE is set
DELETE FROM auth.users 
WHERE id NOT IN (
    SELECT id FROM public.profiles WHERE role = 'admin'
);

-- 4. Reset rooms to 'kosong' status (keep the rooms but clear tenant info)
UPDATE public.rooms 
SET 
    status = 'kosong',
    current_tenant_name = NULL,
    contract_id = NULL,
    updated_at = NOW();

-- 5. Verify cleanup
SELECT 'announcements' as table_name, COUNT(*) as count FROM public.announcements
UNION ALL
SELECT 'announcement_reads', COUNT(*) FROM public.announcement_reads
UNION ALL
SELECT 'complaints', COUNT(*) FROM public.complaints
UNION ALL
SELECT 'payments', COUNT(*) FROM public.payments
UNION ALL
SELECT 'bills', COUNT(*) FROM public.bills
UNION ALL
SELECT 'contracts', COUNT(*) FROM public.contracts
UNION ALL
SELECT 'tenants', COUNT(*) FROM public.tenants
UNION ALL
SELECT 'rooms', COUNT(*) FROM public.rooms
UNION ALL
SELECT 'profiles', COUNT(*) FROM public.profiles
UNION ALL
SELECT 'auth.users', COUNT(*) FROM auth.users;

-- 6. Re-enable triggers if disabled
-- ALTER TABLE public.tenants ENABLE TRIGGER ALL;
-- ALTER TABLE public.contracts ENABLE TRIGGER ALL;

-- =====================================================
-- DONE! Your rooms are preserved, all other data cleared.
-- =====================================================
