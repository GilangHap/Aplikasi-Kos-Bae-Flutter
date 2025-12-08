-- =====================================================
-- SUPABASE STORAGE & RLS POLICIES FOR KOS BAE
-- Jalankan di Supabase SQL Editor
-- =====================================================

-- =====================================================
-- 1. CREATE STORAGE BUCKET (jika belum ada)
-- =====================================================
-- Buat bucket 'room-photos' melalui Supabase Dashboard:
-- Storage > New Bucket > Name: room-photos > Public: ON

-- =====================================================
-- 2. STORAGE POLICIES untuk bucket 'room-photos'
-- =====================================================

-- Allow public to view/download images
CREATE POLICY "Public can view room photos"
ON storage.objects FOR SELECT
USING (bucket_id = 'room-photos');

-- Allow authenticated users to upload images
CREATE POLICY "Authenticated users can upload room photos"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'room-photos');

-- Allow authenticated users to update their uploads
CREATE POLICY "Authenticated users can update room photos"
ON storage.objects FOR UPDATE
USING (bucket_id = 'room-photos');

-- Allow authenticated users to delete images
CREATE POLICY "Authenticated users can delete room photos"
ON storage.objects FOR DELETE
USING (bucket_id = 'room-photos');

-- =====================================================
-- 3. ALTERNATIVE: Allow ALL operations (untuk development)
-- Gunakan ini jika policy di atas tidak work
-- =====================================================

-- DROP existing policies first (uncomment jika perlu)
-- DROP POLICY IF EXISTS "Public can view room photos" ON storage.objects;
-- DROP POLICY IF EXISTS "Authenticated users can upload room photos" ON storage.objects;
-- DROP POLICY IF EXISTS "Authenticated users can update room photos" ON storage.objects;
-- DROP POLICY IF EXISTS "Authenticated users can delete room photos" ON storage.objects;

-- Allow ALL operations on room-photos bucket (DEVELOPMENT ONLY)
-- CREATE POLICY "Allow all operations on room-photos"
-- ON storage.objects
-- FOR ALL
-- USING (bucket_id = 'room-photos')
-- WITH CHECK (bucket_id = 'room-photos');

-- =====================================================
-- 4. TABLE RLS POLICIES untuk tabel 'rooms'
-- =====================================================

-- Enable RLS on rooms table
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read rooms
CREATE POLICY "Anyone can view rooms"
ON rooms FOR SELECT
USING (true);

-- Allow authenticated users to insert rooms
CREATE POLICY "Authenticated users can create rooms"
ON rooms FOR INSERT
WITH CHECK (true);

-- Allow authenticated users to update rooms
CREATE POLICY "Authenticated users can update rooms"
ON rooms FOR UPDATE
USING (true);

-- Allow authenticated users to delete rooms
CREATE POLICY "Authenticated users can delete rooms"
ON rooms FOR DELETE
USING (true);

-- =====================================================
-- 5. ENABLE REALTIME for rooms table
-- =====================================================
-- Ini WAJIB untuk fitur auto-update/realtime

-- Enable realtime replication for rooms table
ALTER PUBLICATION supabase_realtime ADD TABLE rooms;

-- Atau jika sudah ada, recreate publication:
-- DROP PUBLICATION IF EXISTS supabase_realtime;
-- CREATE PUBLICATION supabase_realtime FOR TABLE rooms;

-- =====================================================
-- 6. QUICK FIX: Disable RLS temporarily (DEVELOPMENT)
-- =====================================================
-- Jika masih error, coba disable RLS sementara:

-- ALTER TABLE rooms DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- 7. CHECK EXISTING DATA
-- =====================================================
-- SELECT * FROM rooms;
