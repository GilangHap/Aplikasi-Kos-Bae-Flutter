-- ======================================================
-- COMPLAINTS (KELUHAN) TABLE SCHEMA & SEEDER
-- For Kos Bae Admin Panel
-- ======================================================

-- ==================== TABLE: complaints ====================
CREATE TABLE IF NOT EXISTS complaints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,

    -- Complaint details
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(50) NOT NULL DEFAULT 'lainnya',  -- fasilitas, kebersihan, keamanan, listrik, air, lainnya
    status VARCHAR(50) NOT NULL DEFAULT 'submitted',   -- submitted, in_progress, resolved
    priority VARCHAR(20) DEFAULT 'normal',             -- low, normal, high, urgent

    -- Attachments (array of URLs)
    attachments TEXT[] DEFAULT '{}',

    -- Admin response
    admin_notes TEXT,
    resolution_notes TEXT,
    resolved_at TIMESTAMPTZ,
    resolved_by UUID REFERENCES profiles(id),

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add missing columns if table exists but is missing them
DO $$
BEGIN
    -- Add category column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'complaints' AND column_name = 'category') THEN
        ALTER TABLE complaints ADD COLUMN category VARCHAR(50) DEFAULT 'lainnya';
    END IF;

    -- Add priority column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'complaints' AND column_name = 'priority') THEN
        ALTER TABLE complaints ADD COLUMN priority VARCHAR(20) DEFAULT 'normal';
    END IF;

    -- Add attachments column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'complaints' AND column_name = 'attachments') THEN
        ALTER TABLE complaints ADD COLUMN attachments TEXT[] DEFAULT '{}';
    END IF;

    -- Add admin_notes column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'complaints' AND column_name = 'admin_notes') THEN
        ALTER TABLE complaints ADD COLUMN admin_notes TEXT;
    END IF;

    -- Add resolution_notes column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'complaints' AND column_name = 'resolution_notes') THEN
        ALTER TABLE complaints ADD COLUMN resolution_notes TEXT;
    END IF;

    -- Add resolved_at column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'complaints' AND column_name = 'resolved_at') THEN
        ALTER TABLE complaints ADD COLUMN resolved_at TIMESTAMPTZ;
    END IF;

    -- Add resolved_by column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'complaints' AND column_name = 'resolved_by') THEN
        ALTER TABLE complaints ADD COLUMN resolved_by UUID REFERENCES profiles(id);
    END IF;

    -- Add updated_at column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'complaints' AND column_name = 'updated_at') THEN
        ALTER TABLE complaints ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
    END IF;

    -- Add user_id column to tenants table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'tenants' AND column_name = 'user_id') THEN
        ALTER TABLE tenants ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;
    END IF;
END $$;

-- Add comments
COMMENT ON TABLE complaints IS 'Stores tenant complaints and maintenance requests';
COMMENT ON COLUMN complaints.category IS 'Category: fasilitas, kebersihan, keamanan, listrik, air, lainnya';
COMMENT ON COLUMN complaints.status IS 'Status: submitted, in_progress, resolved';
COMMENT ON COLUMN complaints.priority IS 'Priority: low, normal, high, urgent';

-- ==================== TABLE: complaint_status_history ====================
CREATE TABLE IF NOT EXISTS complaint_status_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    complaint_id UUID NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
    from_status VARCHAR(50) NOT NULL,
    to_status VARCHAR(50) NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES profiles(id)
);

COMMENT ON TABLE complaint_status_history IS 'Tracks status changes for complaints';

-- ==================== INDEXES ====================
CREATE INDEX IF NOT EXISTS idx_complaints_tenant_id ON complaints(tenant_id);
CREATE INDEX IF NOT EXISTS idx_complaints_room_id ON complaints(room_id);
CREATE INDEX IF NOT EXISTS idx_complaints_status ON complaints(status);
CREATE INDEX IF NOT EXISTS idx_complaints_category ON complaints(category);
CREATE INDEX IF NOT EXISTS idx_complaints_created_at ON complaints(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_complaint_status_history_complaint_id ON complaint_status_history(complaint_id);

-- ==================== TRIGGERS ====================
-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_complaints_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_complaints_updated_at ON complaints;
CREATE TRIGGER trigger_complaints_updated_at
    BEFORE UPDATE ON complaints
    FOR EACH ROW
    EXECUTE FUNCTION update_complaints_updated_at();

ALTER TABLE complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaint_status_history ENABLE ROW LEVEL SECURITY;
-- Ensure `tenants.user_id` exists so policies referencing it won't fail
ALTER TABLE IF EXISTS tenants ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

DROP POLICY IF EXISTS "Admin full access to complaints" ON complaints;
DROP POLICY IF EXISTS "Tenants can view own complaints" ON complaints;
DROP POLICY IF EXISTS "Tenants can create complaints" ON complaints;
DROP POLICY IF EXISTS "Admin full access to complaint_status_history" ON complaint_status_history;
DROP POLICY IF EXISTS "Tenants can view own complaint history" ON complaint_status_history;

-- Admin: Full access
CREATE POLICY "Admin full access to complaints"
    ON complaints FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- Tenant: View own complaints
CREATE POLICY "Tenants can view own complaints"
    ON complaints FOR SELECT
    TO authenticated
    USING (
        tenant_id IN (
            SELECT id FROM tenants WHERE user_id = auth.uid()
        )
    );

-- Tenant: Create complaints
CREATE POLICY "Tenants can create complaints"
    ON complaints FOR INSERT
    TO authenticated
    WITH CHECK (
        tenant_id IN (
            SELECT id FROM tenants WHERE user_id = auth.uid()
        )
    );

-- Admin: Full access to status history
CREATE POLICY "Admin full access to complaint_status_history"
    ON complaint_status_history FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- Tenant: View own complaint history
CREATE POLICY "Tenants can view own complaint history"
    ON complaint_status_history FOR SELECT
    TO authenticated
    USING (
        complaint_id IN (
            SELECT c.id FROM complaints c
            JOIN tenants t ON c.tenant_id = t.id
            WHERE t.user_id = auth.uid()
        )
    );


-- ======================================================
-- SEEDER DATA
-- ======================================================

-- Make sure the status check constraint allows the application's status values.
-- Some existing schema used 'open' as initial state; application uses 'submitted'.
-- We'll drop and recreate the constraint to include both values.
ALTER TABLE IF EXISTS complaints DROP CONSTRAINT IF EXISTS complaints_status_check;
ALTER TABLE IF EXISTS complaints
    ADD CONSTRAINT complaints_status_check CHECK (status IN ('submitted','open','in_progress','resolved','closed'));

-- Fix foreign key: original SCHEMA.sql pointed tenant_id to auth.users, but we need it to point to tenants table
ALTER TABLE IF EXISTS complaints DROP CONSTRAINT IF EXISTS complaints_tenant_id_fkey;
ALTER TABLE IF EXISTS complaints
    ADD CONSTRAINT complaints_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;

-- NOTE: Replace UUIDs with actual tenant_id and room_id from your database
-- You can get these by running:
-- SELECT id, name FROM tenants LIMIT 10;
-- SELECT id, room_number FROM rooms LIMIT 10;

-- Create temporary function for seeding
DO $$
DECLARE
    v_tenant_1 UUID;
    v_tenant_2 UUID;
    v_tenant_3 UUID;
    v_room_1 UUID;
    v_room_2 UUID;
    v_room_3 UUID;
    v_complaint_1 UUID;
    v_complaint_2 UUID;
    v_complaint_3 UUID;
    v_complaint_4 UUID;
    v_complaint_5 UUID;
    v_complaint_6 UUID;
    v_complaint_7 UUID;
    v_admin_id UUID;
    v_existing_count INTEGER;
BEGIN
    -- Check if seeder data already exists
    SELECT COUNT(*) INTO v_existing_count FROM complaints
    WHERE title IN (
        'AC Kamar Tidak Dingin',
        'Kran Kamar Mandi Bocor',
        'Lampu Koridor Lantai 2 Mati',
        'Pintu Kamar Susah Dikunci',
        'Toilet Mampet',
        'WiFi Sangat Lambat',
        'Jendela Kamar Tidak Bisa Ditutup Rapat'
    );

    -- Skip if data already exists
    IF v_existing_count > 0 THEN
        RAISE NOTICE 'Seeder data already exists. Skipping...';
        RETURN;
    END IF;

    -- Get existing tenants (adjust as needed based on your data)
    SELECT id INTO v_tenant_1 FROM tenants ORDER BY created_at ASC LIMIT 1 OFFSET 0;
    SELECT id INTO v_tenant_2 FROM tenants ORDER BY created_at ASC LIMIT 1 OFFSET 1;
    SELECT id INTO v_tenant_3 FROM tenants ORDER BY created_at ASC LIMIT 1 OFFSET 2;

    -- Get existing rooms
    SELECT id INTO v_room_1 FROM rooms ORDER BY room_number ASC LIMIT 1 OFFSET 0;
    SELECT id INTO v_room_2 FROM rooms ORDER BY room_number ASC LIMIT 1 OFFSET 1;
    SELECT id INTO v_room_3 FROM rooms ORDER BY room_number ASC LIMIT 1 OFFSET 2;

    -- Get admin profile
    SELECT id INTO v_admin_id FROM profiles WHERE role = 'admin' LIMIT 1;

    -- Exit if no tenants/rooms found
    IF v_tenant_1 IS NULL OR v_room_1 IS NULL THEN
        RAISE NOTICE 'No tenants or rooms found. Skipping seeder...';
        RETURN;
    END IF;

    -- Use defaults if not enough data
    v_tenant_2 := COALESCE(v_tenant_2, v_tenant_1);
    v_tenant_3 := COALESCE(v_tenant_3, v_tenant_1);
    v_room_2 := COALESCE(v_room_2, v_room_1);
    v_room_3 := COALESCE(v_room_3, v_room_1);

    -- ==================== SEEDER: Submitted Complaints ====================
    
    -- 1. AC Rusak (Submitted - New)
    INSERT INTO complaints (id, tenant_id, room_id, title, description, category, status, priority, attachments, created_at)
    VALUES (
        gen_random_uuid(),
        v_tenant_1,
        v_room_1,
        'AC Kamar Tidak Dingin',
        'AC di kamar saya sudah 2 hari ini tidak dingin sama sekali. Sudah coba matikan dan hidupkan ulang tetapi tetap tidak berfungsi dengan baik. Mohon segera diperbaiki karena cuaca sangat panas.',
        'fasilitas',
        'submitted',
        'high',
        ARRAY[]::TEXT[],
        NOW() - INTERVAL '2 hours'
    ) RETURNING id INTO v_complaint_1;
    
    -- 2. Kran Air Bocor (Submitted - New)
    INSERT INTO complaints (id, tenant_id, room_id, title, description, category, status, priority, attachments, created_at)
    VALUES (
        gen_random_uuid(),
        v_tenant_2,
        v_room_2,
        'Kran Kamar Mandi Bocor',
        'Kran air di kamar mandi bocor dan mengeluarkan air terus menerus. Sudah mencoba memutar kencang tapi tetap bocor. Khawatir akan membuat tagihan air naik.',
        'air',
        'submitted',
        'normal',
        ARRAY[]::TEXT[],
        NOW() - INTERVAL '1 day'
    ) RETURNING id INTO v_complaint_2;
    
    -- 3. Lampu Koridor Mati (Submitted)
    INSERT INTO complaints (id, tenant_id, room_id, title, description, category, status, priority, attachments, created_at)
    VALUES (
        gen_random_uuid(),
        v_tenant_1,
        v_room_1,
        'Lampu Koridor Lantai 2 Mati',
        'Beberapa lampu di koridor lantai 2 sudah mati dan membuat koridor menjadi gelap saat malam hari. Mohon untuk diganti lampunya agar tidak berbahaya.',
        'listrik',
        'submitted',
        'normal',
        ARRAY[]::TEXT[],
        NOW() - INTERVAL '3 days'
    ) RETURNING id INTO v_complaint_3;

    -- ==================== SEEDER: In Progress Complaints ====================
    
    -- 4. Pintu Kamar Susah Dikunci (In Progress)
    INSERT INTO complaints (id, tenant_id, room_id, title, description, category, status, priority, admin_notes, attachments, created_at)
    VALUES (
        gen_random_uuid(),
        v_tenant_2,
        v_room_2,
        'Pintu Kamar Susah Dikunci',
        'Kunci pintu kamar saya sudah mulai susah untuk dikunci. Harus berkali-kali mencoba baru bisa terkunci. Khawatir kalau nanti tidak bisa dikunci sama sekali.',
        'keamanan',
        'in_progress',
        'high',
        'Teknisi sudah dijadwalkan datang besok pagi. Akan diganti kunci baru.',
        ARRAY[]::TEXT[],
        NOW() - INTERVAL '4 days'
    ) RETURNING id INTO v_complaint_4;
    
    -- Add status history for complaint 4
    INSERT INTO complaint_status_history (complaint_id, from_status, to_status, notes, created_at, created_by)
    VALUES (
        v_complaint_4,
        'submitted',
        'in_progress',
        'Sudah koordinasi dengan teknisi. Akan datang besok.',
        NOW() - INTERVAL '2 days',
        v_admin_id
    );
    
    -- 5. Toilet Mampet (In Progress)
    INSERT INTO complaints (id, tenant_id, room_id, title, description, category, status, priority, admin_notes, attachments, created_at)
    VALUES (
        gen_random_uuid(),
        v_tenant_3,
        v_room_3,
        'Toilet Mampet',
        'Toilet di kamar mandi mampet dan air tidak mengalir dengan lancar. Sudah coba pakai plunger tapi tidak berhasil. Mohon segera ditangani.',
        'kebersihan',
        'in_progress',
        'urgent',
        'Sedang dalam proses perbaikan oleh tukang ledeng.',
        ARRAY[]::TEXT[],
        NOW() - INTERVAL '1 day'
    ) RETURNING id INTO v_complaint_5;
    
    -- Add status history for complaint 5
    INSERT INTO complaint_status_history (complaint_id, from_status, to_status, notes, created_at, created_by)
    VALUES (
        v_complaint_5,
        'submitted',
        'in_progress',
        'Tukang ledeng sudah dipanggil dan sedang dalam perjalanan.',
        NOW() - INTERVAL '12 hours',
        v_admin_id
    );

    -- ==================== SEEDER: Resolved Complaints ====================
    
    -- 6. WiFi Lambat (Resolved)
    INSERT INTO complaints (id, tenant_id, room_id, title, description, category, status, priority, admin_notes, resolution_notes, resolved_at, resolved_by, attachments, created_at)
    VALUES (
        gen_random_uuid(),
        v_tenant_1,
        v_room_1,
        'WiFi Sangat Lambat',
        'Koneksi WiFi di kamar saya sangat lambat beberapa hari ini. Untuk streaming atau video call sangat susah. Mohon dicek koneksinya.',
        'fasilitas',
        'resolved',
        'normal',
        'Sudah dicek, ternyata ada masalah di router.',
        'Router sudah direset dan dikonfigurasi ulang. Koneksi sudah normal kembali. Pengecekan berkala akan dilakukan setiap minggu.',
        NOW() - INTERVAL '1 day',
        v_admin_id,
        ARRAY[]::TEXT[],
        NOW() - INTERVAL '5 days'
    ) RETURNING id INTO v_complaint_6;
    
    -- Add status history for complaint 6
    INSERT INTO complaint_status_history (complaint_id, from_status, to_status, notes, created_at, created_by)
    VALUES 
    (
        v_complaint_6,
        'submitted',
        'in_progress',
        'Sedang dilakukan pengecekan jaringan.',
        NOW() - INTERVAL '4 days',
        v_admin_id
    ),
    (
        v_complaint_6,
        'in_progress',
        'resolved',
        'Router sudah direset dan konfigurasi ulang.',
        NOW() - INTERVAL '1 day',
        v_admin_id
    );
    
    -- 7. Jendela Tidak Bisa Ditutup (Resolved)
    INSERT INTO complaints (id, tenant_id, room_id, title, description, category, status, priority, admin_notes, resolution_notes, resolved_at, resolved_by, attachments, created_at)
    VALUES (
        gen_random_uuid(),
        v_tenant_2,
        v_room_2,
        'Jendela Kamar Tidak Bisa Ditutup Rapat',
        'Jendela kamar saya tidak bisa ditutup dengan rapat. Ada celah yang membuat debu dan serangga bisa masuk. Mohon diperbaiki.',
        'fasilitas',
        'resolved',
        'normal',
        'Engsel jendela perlu disesuaikan.',
        'Engsel jendela sudah disesuaikan dan diberi pelumas. Jendela sudah bisa ditutup dengan rapat. Karet pelapis juga sudah diganti dengan yang baru.',
        NOW() - INTERVAL '3 days',
        v_admin_id,
        ARRAY[]::TEXT[],
        NOW() - INTERVAL '7 days'
    ) RETURNING id INTO v_complaint_7;
    
    -- Add status history for complaint 7
    INSERT INTO complaint_status_history (complaint_id, from_status, to_status, notes, created_at, created_by)
    VALUES 
    (
        v_complaint_7,
        'submitted',
        'in_progress',
        'Teknisi akan datang untuk memeriksa.',
        NOW() - INTERVAL '6 days',
        v_admin_id
    ),
    (
        v_complaint_7,
        'in_progress',
        'resolved',
        'Engsel dan karet pelapis sudah diperbaiki.',
        NOW() - INTERVAL '3 days',
        v_admin_id
    );
    
    RAISE NOTICE 'Seeder completed! Created 7 complaints with status history.';
    RAISE NOTICE 'Submitted: 3, In Progress: 2, Resolved: 2';
END $$;


-- ======================================================
-- VERIFICATION QUERIES (Run to check data)
-- ======================================================

-- Count complaints by status
-- SELECT status, COUNT(*) as count FROM complaints GROUP BY status;

-- List all complaints with tenant and room info
-- SELECT 
--     c.title,
--     c.category,
--     c.status,
--     c.priority,
--     t.name as tenant_name,
--     r.room_number,
--     c.created_at
-- FROM complaints c
-- JOIN tenants t ON c.tenant_id = t.id
-- JOIN rooms r ON c.room_id = r.id
-- ORDER BY c.created_at DESC;

-- View status history for a specific complaint
-- SELECT 
--     csh.from_status,
--     csh.to_status,
--     csh.notes,
--     csh.created_at
-- FROM complaint_status_history csh
-- JOIN complaints c ON csh.complaint_id = c.id
-- WHERE c.title = 'WiFi Sangat Lambat'
-- ORDER BY csh.created_at ASC;
