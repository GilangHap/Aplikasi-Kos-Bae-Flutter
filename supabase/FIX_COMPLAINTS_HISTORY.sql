-- ======================================================
-- FIX: Complaints RLS Policies & Missing Tables
-- Run this in Supabase SQL Editor
-- ======================================================

-- STEP 1: Disable RLS temporarily to test
-- ALTER TABLE complaints DISABLE ROW LEVEL SECURITY;

-- STEP 2: Create complaint_status_history table if not exists
CREATE TABLE IF NOT EXISTS complaint_status_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    complaint_id UUID NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
    from_status VARCHAR(50) NOT NULL,
    to_status VARCHAR(50) NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID
);

-- Create index
CREATE INDEX IF NOT EXISTS idx_complaint_status_history_complaint_id 
    ON complaint_status_history(complaint_id);

-- STEP 3: Add missing columns to complaints table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'complaints' AND column_name = 'category') THEN
        ALTER TABLE complaints ADD COLUMN category VARCHAR(50) DEFAULT 'lainnya';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'complaints' AND column_name = 'priority') THEN
        ALTER TABLE complaints ADD COLUMN priority VARCHAR(20) DEFAULT 'normal';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'complaints' AND column_name = 'attachments') THEN
        ALTER TABLE complaints ADD COLUMN attachments TEXT[] DEFAULT '{}';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'complaints' AND column_name = 'admin_notes') THEN
        ALTER TABLE complaints ADD COLUMN admin_notes TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'complaints' AND column_name = 'resolution_notes') THEN
        ALTER TABLE complaints ADD COLUMN resolution_notes TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'complaints' AND column_name = 'resolved_at') THEN
        ALTER TABLE complaints ADD COLUMN resolved_at TIMESTAMPTZ;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'complaints' AND column_name = 'resolved_by') THEN
        ALTER TABLE complaints ADD COLUMN resolved_by UUID;
    END IF;
END $$;

-- STEP 4: Update status constraint
ALTER TABLE complaints DROP CONSTRAINT IF EXISTS complaints_status_check;
ALTER TABLE complaints ADD CONSTRAINT complaints_status_check 
    CHECK (status IN ('submitted', 'open', 'in_progress', 'resolved', 'closed'));

-- STEP 5: Enable RLS
ALTER TABLE complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaint_status_history ENABLE ROW LEVEL SECURITY;

-- STEP 6: Drop ALL existing policies on complaints
DROP POLICY IF EXISTS "Admin full access to complaints" ON complaints;
DROP POLICY IF EXISTS "Authenticated can read complaints" ON complaints;
DROP POLICY IF EXISTS "Tenants can view own complaints" ON complaints;
DROP POLICY IF EXISTS "Tenants can create complaints" ON complaints;
DROP POLICY IF EXISTS "Users can view own complaints" ON complaints;
DROP POLICY IF EXISTS "Admins can view all complaints" ON complaints;
DROP POLICY IF EXISTS "Admins can manage complaints" ON complaints;
DROP POLICY IF EXISTS "Admins can delete complaints" ON complaints;
DROP POLICY IF EXISTS "Enable read for authenticated" ON complaints;
DROP POLICY IF EXISTS "Enable all for authenticated" ON complaints;

-- STEP 7: Create SIMPLE policy - allow ALL authenticated users to read
CREATE POLICY "Enable read for authenticated"
    ON complaints FOR SELECT
    TO authenticated
    USING (true);

-- STEP 8: Allow admin full access
CREATE POLICY "Enable all for admin"
    ON complaints FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- STEP 9: Policies for complaint_status_history
DROP POLICY IF EXISTS "Admin full access to complaint_status_history" ON complaint_status_history;
DROP POLICY IF EXISTS "Tenants can view own complaint history" ON complaint_status_history;
DROP POLICY IF EXISTS "Service role bypass" ON complaint_status_history;
DROP POLICY IF EXISTS "Authenticated can read history" ON complaint_status_history;
DROP POLICY IF EXISTS "Authenticated can insert history" ON complaint_status_history;

CREATE POLICY "Enable read for authenticated"
    ON complaint_status_history FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Enable insert for authenticated"
    ON complaint_status_history FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- STEP 10: Verify data exists
SELECT 'Total complaints:' as info, COUNT(*) as count FROM complaints;
SELECT 'Complaints by status:' as info, status, COUNT(*) as count FROM complaints GROUP BY status;

-- Show sample data
SELECT id, title, status, category, tenant_id, room_id FROM complaints LIMIT 5;
