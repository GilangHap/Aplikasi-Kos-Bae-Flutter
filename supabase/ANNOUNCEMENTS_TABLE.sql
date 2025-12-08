-- =====================================================
-- ANNOUNCEMENTS TABLE SCHEMA FOR KOS BAE
-- Run this in Supabase SQL Editor
-- =====================================================

-- =====================================================
-- 1. CREATE ANNOUNCEMENTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    attachments JSONB DEFAULT '[]'::jsonb,
    is_required BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

-- Add comments for documentation
COMMENT ON TABLE public.announcements IS 'Announcements for kos tenants';
COMMENT ON COLUMN public.announcements.title IS 'Announcement title';
COMMENT ON COLUMN public.announcements.content IS 'Full announcement content/body';
COMMENT ON COLUMN public.announcements.attachments IS 'Array of attachment URLs stored as JSON';
COMMENT ON COLUMN public.announcements.is_required IS 'Whether the announcement is mandatory to read';
COMMENT ON COLUMN public.announcements.created_by IS 'Admin who created the announcement';

-- =====================================================
-- 2. CREATE ANNOUNCEMENT_READS TABLE (Read Tracking)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.announcement_reads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    announcement_id UUID NOT NULL REFERENCES public.announcements(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    read_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(announcement_id, tenant_id)
);

-- Add comments for documentation
COMMENT ON TABLE public.announcement_reads IS 'Tracks which tenants have read announcements';
COMMENT ON COLUMN public.announcement_reads.announcement_id IS 'Reference to the announcement';
COMMENT ON COLUMN public.announcement_reads.tenant_id IS 'Reference to the tenant who read it';
COMMENT ON COLUMN public.announcement_reads.read_at IS 'Timestamp when the tenant read the announcement';

-- =====================================================
-- 3. CREATE INDEXES FOR PERFORMANCE
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_announcements_created_at ON public.announcements(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_announcements_is_required ON public.announcements(is_required);
CREATE INDEX IF NOT EXISTS idx_announcement_reads_announcement ON public.announcement_reads(announcement_id);
CREATE INDEX IF NOT EXISTS idx_announcement_reads_tenant ON public.announcement_reads(tenant_id);

-- =====================================================
-- 4. ENABLE ROW LEVEL SECURITY
-- =====================================================
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcement_reads ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 5. DROP OLD POLICIES (if any)
-- =====================================================
DROP POLICY IF EXISTS "Allow authenticated to read announcements" ON public.announcements;
DROP POLICY IF EXISTS "Allow admin to manage announcements" ON public.announcements;
DROP POLICY IF EXISTS "Allow authenticated to read announcement_reads" ON public.announcement_reads;
DROP POLICY IF EXISTS "Allow tenant to mark as read" ON public.announcement_reads;
DROP POLICY IF EXISTS "Allow admin to view all reads" ON public.announcement_reads;

-- =====================================================
-- 6. CREATE RLS POLICIES FOR ANNOUNCEMENTS
-- =====================================================

-- All authenticated users can read announcements
CREATE POLICY "Allow authenticated to read announcements"
ON public.announcements
FOR SELECT
TO authenticated
USING (true);

-- Only admin can insert, update, delete announcements
-- Admin check: user has 'admin' role in metadata or is the creator
CREATE POLICY "Allow admin to manage announcements"
ON public.announcements
FOR ALL
TO authenticated
USING (
    auth.jwt() ->> 'role' = 'admin' OR
    auth.jwt() -> 'user_metadata' ->> 'role' = 'admin' OR
    created_by = auth.uid()
)
WITH CHECK (
    auth.jwt() ->> 'role' = 'admin' OR
    auth.jwt() -> 'user_metadata' ->> 'role' = 'admin'
);

-- =====================================================
-- 7. CREATE RLS POLICIES FOR ANNOUNCEMENT_READS
-- =====================================================

-- All authenticated users can view reads (for admin to see stats, tenant to see their own)
CREATE POLICY "Allow authenticated to read announcement_reads"
ON public.announcement_reads
FOR SELECT
TO authenticated
USING (true);

-- Tenants can mark announcements as read (only for themselves)
CREATE POLICY "Allow tenant to mark as read"
ON public.announcement_reads
FOR INSERT
TO authenticated
WITH CHECK (
    -- Tenant can only insert for themselves
    EXISTS (
        SELECT 1 FROM public.tenants t 
        WHERE t.id = announcement_reads.tenant_id 
        AND t.user_id = auth.uid()
    ) OR
    -- Or user is admin
    auth.jwt() ->> 'role' = 'admin' OR
    auth.jwt() -> 'user_metadata' ->> 'role' = 'admin'
);

-- =====================================================
-- 8. SAMPLE DATA (Optional - for testing)
-- =====================================================
/*
-- Insert sample announcements
INSERT INTO public.announcements (title, content, is_required, created_at) VALUES
(
    'Jadwal Pembersihan Gedung',
    'Kepada seluruh penghuni kos, kami informasikan bahwa akan dilakukan pembersihan gedung secara menyeluruh pada hari Sabtu, 7 Desember 2024 mulai pukul 08:00 WIB. 

Mohon kerjasama untuk:
1. Memastikan barang-barang di depan kamar sudah dirapikan
2. Tidak membuang sampah di lorong
3. Merapikan area kamar mandi bersama

Terima kasih atas kerjasamanya.',
    TRUE,
    NOW() - INTERVAL '2 days'
),
(
    'Pemadaman Listrik Sementara',
    'Diberitahukan kepada seluruh penghuni bahwa akan ada pemadaman listrik sementara untuk perawatan instalasi pada:

Tanggal: Minggu, 8 Desember 2024
Waktu: 13:00 - 16:00 WIB

Mohon persiapkan peralatan yang diperlukan. Genset hanya akan menyala untuk penerangan lorong.

Terima kasih atas pengertiannya.',
    TRUE,
    NOW() - INTERVAL '1 day'
),
(
    'Kegiatan Arisan Penghuni Bulan Desember',
    'Hai penghuni kos!

Arisan bulanan akan diadakan pada:
Hari/Tanggal: Jumat, 13 Desember 2024
Waktu: 19:30 WIB
Tempat: Ruang tamu lantai 1

Iuran: Rp 50.000
Snack dan minuman disediakan!

Bagi yang berminat, silakan konfirmasi ke grup WhatsApp ya.

Salam hangat,
Pengurus Kos',
    FALSE,
    NOW()
);
*/

-- =====================================================
-- 9. GRANT PERMISSIONS
-- =====================================================
GRANT ALL ON public.announcements TO authenticated;
GRANT ALL ON public.announcement_reads TO authenticated;

-- =====================================================
-- VERIFICATION: Run these queries to check
-- =====================================================
/*
-- Check tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name IN ('announcements', 'announcement_reads');

-- Check columns
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'announcements';

SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'announcement_reads';

-- Check RLS policies
SELECT tablename, policyname, cmd 
FROM pg_policies 
WHERE tablename IN ('announcements', 'announcement_reads');

-- Test query: Get announcements with read count
SELECT 
    a.*,
    COALESCE(
        (SELECT COUNT(*) FROM announcement_reads ar WHERE ar.announcement_id = a.id),
        0
    ) as read_count
FROM announcements a
ORDER BY a.created_at DESC;
*/
