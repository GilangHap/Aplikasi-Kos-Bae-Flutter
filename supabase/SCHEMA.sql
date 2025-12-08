-- ================================================================
-- KOS BAE - SUPABASE DATABASE SCHEMA
-- Complete SQL for Rooms Management System
-- ================================================================

-- ================================================================
-- 1. TABLES
-- ================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ----------------------------------------------------------------
-- Profiles Table (extends auth.users)
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  phone TEXT,
  role TEXT NOT NULL CHECK (role IN ('admin', 'tenant')),
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.profiles IS 'User profiles for admin and tenants';

-- ----------------------------------------------------------------
-- Rooms Table
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.rooms (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_number TEXT NOT NULL UNIQUE,
  price NUMERIC(12,2) NOT NULL CHECK (price >= 0),
  status TEXT NOT NULL DEFAULT 'kosong' CHECK (status IN ('kosong', 'terisi', 'maintenance')),
  photos JSONB DEFAULT '[]'::jsonb,
  facilities JSONB DEFAULT '[]'::jsonb,
  description TEXT DEFAULT '',
  current_tenant_name TEXT,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.rooms IS 'Boarding house rooms';
COMMENT ON COLUMN public.rooms.status IS 'kosong = empty, terisi = occupied, maintenance = under maintenance';
COMMENT ON COLUMN public.rooms.photos IS 'Array of photo URLs from Supabase Storage';
COMMENT ON COLUMN public.rooms.facilities IS 'Array of facility strings';

CREATE INDEX idx_rooms_status ON public.rooms(status);
CREATE INDEX idx_rooms_room_number ON public.rooms(room_number);
CREATE INDEX idx_rooms_created_at ON public.rooms(created_at DESC);

-- ----------------------------------------------------------------
-- Tenants Table
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tenants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  nik TEXT,
  address TEXT,
  photo_url TEXT,
  room_id UUID REFERENCES public.rooms(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'aktif' CHECK (status IN ('aktif', 'keluar')),
  check_in_date DATE,
  check_out_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.tenants IS 'Boarding house tenants/residents';
COMMENT ON COLUMN public.tenants.status IS 'aktif = active tenant, keluar = left/moved out';

CREATE INDEX idx_tenants_status ON public.tenants(status);
CREATE INDEX idx_tenants_room_id ON public.tenants(room_id);
CREATE INDEX idx_tenants_name ON public.tenants(name);
CREATE INDEX idx_tenants_created_at ON public.tenants(created_at DESC);

-- ----------------------------------------------------------------
-- Room History Table (tenant occupancy records)
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.room_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id UUID NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tenant_name TEXT NOT NULL,
  contract_start DATE NOT NULL,
  contract_end DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT valid_contract_dates CHECK (contract_end > contract_start)
);

COMMENT ON TABLE public.room_history IS 'History of room occupancy by tenants';

CREATE INDEX idx_room_history_room_id ON public.room_history(room_id);
CREATE INDEX idx_room_history_tenant_id ON public.room_history(tenant_id);
CREATE INDEX idx_room_history_contract_start ON public.room_history(contract_start DESC);

-- ----------------------------------------------------------------
-- Complaints Table
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.complaints (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id UUID NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  media JSONB DEFAULT '[]'::jsonb,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.complaints IS 'Tenant complaints related to rooms';
COMMENT ON COLUMN public.complaints.media IS 'Array of media URLs (photos/videos)';

CREATE INDEX idx_complaints_room_id ON public.complaints(room_id);
CREATE INDEX idx_complaints_tenant_id ON public.complaints(tenant_id);
CREATE INDEX idx_complaints_status ON public.complaints(status);
CREATE INDEX idx_complaints_created_at ON public.complaints(created_at DESC);

-- ================================================================
-- 2. FUNCTIONS & TRIGGERS
-- ================================================================

-- ----------------------------------------------------------------
-- Function: Update updated_at timestamp
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to tables
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_rooms_updated_at ON public.rooms;
CREATE TRIGGER update_rooms_updated_at
  BEFORE UPDATE ON public.rooms
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_complaints_updated_at ON public.complaints;
CREATE TRIGGER update_complaints_updated_at
  BEFORE UPDATE ON public.complaints
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_tenants_updated_at ON public.tenants;
CREATE TRIGGER update_tenants_updated_at
  BEFORE UPDATE ON public.tenants
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ----------------------------------------------------------------
-- Function: Get current tenant name for room
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_current_tenant_name(p_room_id UUID)
RETURNS TEXT AS $$
DECLARE
  v_tenant_name TEXT;
BEGIN
  SELECT rh.tenant_name INTO v_tenant_name
  FROM public.room_history rh
  WHERE rh.room_id = p_room_id
    AND CURRENT_DATE BETWEEN rh.contract_start AND rh.contract_end
  ORDER BY rh.contract_start DESC
  LIMIT 1;
  
  RETURN v_tenant_name;
END;
$$ LANGUAGE plpgsql;

-- ================================================================
-- 3. ROW LEVEL SECURITY (RLS) POLICIES
-- ================================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.room_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaints ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------
-- Profiles Policies
-- ----------------------------------------------------------------
-- Users can view their own profile
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

-- Users can update their own profile
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- Admins can view all profiles
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
CREATE POLICY "Admins can view all profiles"
  ON public.profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ----------------------------------------------------------------
-- Rooms Policies
-- ----------------------------------------------------------------
-- Anyone authenticated can view rooms
DROP POLICY IF EXISTS "Authenticated users can view rooms" ON public.rooms;
CREATE POLICY "Authenticated users can view rooms"
  ON public.rooms FOR SELECT
  TO authenticated
  USING (true);

-- Admins can insert rooms
DROP POLICY IF EXISTS "Admins can insert rooms" ON public.rooms;
CREATE POLICY "Admins can insert rooms"
  ON public.rooms FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admins can update rooms
DROP POLICY IF EXISTS "Admins can update rooms" ON public.rooms;
CREATE POLICY "Admins can update rooms"
  ON public.rooms FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admins can delete rooms
DROP POLICY IF EXISTS "Admins can delete rooms" ON public.rooms;
CREATE POLICY "Admins can delete rooms"
  ON public.rooms FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ----------------------------------------------------------------
-- Tenants Policies
-- ----------------------------------------------------------------
-- Anyone authenticated can view tenants
DROP POLICY IF EXISTS "Authenticated users can view tenants" ON public.tenants;
CREATE POLICY "Authenticated users can view tenants"
  ON public.tenants FOR SELECT
  TO authenticated
  USING (true);

-- Admins can insert tenants
DROP POLICY IF EXISTS "Admins can insert tenants" ON public.tenants;
CREATE POLICY "Admins can insert tenants"
  ON public.tenants FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admins can update tenants
DROP POLICY IF EXISTS "Admins can update tenants" ON public.tenants;
CREATE POLICY "Admins can update tenants"
  ON public.tenants FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admins can delete tenants
DROP POLICY IF EXISTS "Admins can delete tenants" ON public.tenants;
CREATE POLICY "Admins can delete tenants"
  ON public.tenants FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ----------------------------------------------------------------
-- Room History Policies
-- ----------------------------------------------------------------
-- Admins can view all history
DROP POLICY IF EXISTS "Admins can view all room history" ON public.room_history;
CREATE POLICY "Admins can view all room history"
  ON public.room_history FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Tenants can view their own history
DROP POLICY IF EXISTS "Tenants can view own history" ON public.room_history;
CREATE POLICY "Tenants can view own history"
  ON public.room_history FOR SELECT
  TO authenticated
  USING (tenant_id = auth.uid());

-- Admins can insert/update/delete history
DROP POLICY IF EXISTS "Admins can manage room history" ON public.room_history;
CREATE POLICY "Admins can manage room history"
  ON public.room_history FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ----------------------------------------------------------------
-- Complaints Policies
-- ----------------------------------------------------------------
-- Tenants can insert their own complaints
DROP POLICY IF EXISTS "Tenants can create complaints" ON public.complaints;
CREATE POLICY "Tenants can create complaints"
  ON public.complaints FOR INSERT
  TO authenticated
  WITH CHECK (tenant_id = auth.uid());

-- Users can view their own complaints
DROP POLICY IF EXISTS "Users can view own complaints" ON public.complaints;
CREATE POLICY "Users can view own complaints"
  ON public.complaints FOR SELECT
  TO authenticated
  USING (tenant_id = auth.uid());

-- Admins can view all complaints
DROP POLICY IF EXISTS "Admins can view all complaints" ON public.complaints;
CREATE POLICY "Admins can view all complaints"
  ON public.complaints FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admins can update/delete complaints
DROP POLICY IF EXISTS "Admins can manage complaints" ON public.complaints;
CREATE POLICY "Admins can manage complaints"
  ON public.complaints FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

DROP POLICY IF EXISTS "Admins can delete complaints" ON public.complaints;
CREATE POLICY "Admins can delete complaints"
  ON public.complaints FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ================================================================
-- 4. STORAGE BUCKET SETUP
-- ================================================================

-- Create storage bucket for room photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('kos-bae-storage', 'kos-bae-storage', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies
DROP POLICY IF EXISTS "Anyone can view files" ON storage.objects;
CREATE POLICY "Anyone can view files"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'kos-bae-storage');

DROP POLICY IF EXISTS "Authenticated users can upload files" ON storage.objects;
CREATE POLICY "Authenticated users can upload files"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'kos-bae-storage');

DROP POLICY IF EXISTS "Users can update own files" ON storage.objects;
CREATE POLICY "Users can update own files"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (bucket_id = 'kos-bae-storage');

DROP POLICY IF EXISTS "Users can delete own files" ON storage.objects;
CREATE POLICY "Users can delete own files"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (bucket_id = 'kos-bae-storage');

-- ================================================================
-- 5. SEED DATA
-- ================================================================

-- ----------------------------------------------------------------
-- Create admin user (you need to create this in Supabase Auth first)
-- Then insert profile here with the UUID from auth.users
-- ----------------------------------------------------------------

-- Example: Insert admin profile (replace with actual UUID from auth.users)
-- INSERT INTO public.profiles (id, full_name, phone, role)
-- VALUES ('your-admin-uuid-here', 'Admin Kos Bae', '081234567890', 'admin');

-- ----------------------------------------------------------------
-- Sample Rooms
-- ----------------------------------------------------------------
INSERT INTO public.rooms (room_number, price, status, photos, facilities, description)
VALUES
  (
    '101',
    1500000,
    'kosong',
    '["https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af", "https://images.unsplash.com/photo-1631049307264-da0ec9d70304"]'::jsonb,
    '["AC", "Wifi", "Kamar Mandi Dalam", "Kasur", "Lemari"]'::jsonb,
    'Kamar nyaman dengan fasilitas lengkap di lantai 1. Cocok untuk mahasiswa atau pekerja. Dekat dengan kampus dan pusat kota.'
  ),
  (
    '102',
    1750000,
    'terisi',
    '["https://images.unsplash.com/photo-1540518614846-7eded433c457", "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2"]'::jsonb,
    '["AC", "Wifi", "Kamar Mandi Dalam", "Kasur", "Lemari", "Meja Belajar", "Kursi"]'::jsonb,
    'Kamar premium dengan view bagus dan fasilitas lebih lengkap. Sudah termasuk meja belajar dan kursi ergonomis.'
  ),
  (
    '201',
    1600000,
    'maintenance',
    '["https://images.unsplash.com/photo-1560448204-e02f11c3d0e2"]'::jsonb,
    '["AC", "Wifi", "Kamar Mandi Dalam", "Kasur", "Lemari"]'::jsonb,
    'Kamar di lantai 2 dengan pencahayaan natural yang baik. Sedang dalam perbaikan AC.'
  ),
  (
    '202',
    1550000,
    'kosong',
    '["https://images.unsplash.com/photo-1505693416388-ac5ce068fe85"]'::jsonb,
    '["AC", "Wifi", "Kamar Mandi Dalam", "Kasur"]'::jsonb,
    'Kamar standar yang bersih dan nyaman. Lokasi strategis dekat dengan minimarket.'
  );

-- ----------------------------------------------------------------
-- Sample Tenant (you need to create this in Supabase Auth first)
-- ----------------------------------------------------------------

-- Example: Insert tenant profile (replace with actual UUID from auth.users)
-- INSERT INTO public.profiles (id, full_name, phone, role)
-- VALUES ('your-tenant-uuid-here', 'Budi Santoso', '081234567891', 'tenant');

-- ----------------------------------------------------------------
-- Sample Room History
-- ----------------------------------------------------------------

-- Example: Insert room history (replace UUIDs)
-- INSERT INTO public.room_history (room_id, tenant_id, tenant_name, contract_start, contract_end)
-- VALUES (
--   (SELECT id FROM public.rooms WHERE room_number = '102'),
--   'your-tenant-uuid-here',
--   'Budi Santoso',
--   '2024-01-01',
--   '2024-12-31'
-- );

-- ----------------------------------------------------------------
-- Sample Complaint
-- ----------------------------------------------------------------

-- Example: Insert complaint (replace UUIDs)
-- INSERT INTO public.complaints (room_id, tenant_id, title, description, status)
-- VALUES (
--   (SELECT id FROM public.rooms WHERE room_number = '102'),
--   'your-tenant-uuid-here',
--   'AC tidak dingin',
--   'AC kamar tidak dingin sejak 2 hari yang lalu. Sudah dicoba dibersihkan filter tapi tetap sama.',
--   'open'
-- );

-- ================================================================
-- 6. USEFUL QUERIES & VIEWS
-- ================================================================

-- ----------------------------------------------------------------
-- View: Rooms with current tenant info
-- ----------------------------------------------------------------
CREATE OR REPLACE VIEW public.rooms_with_tenant AS
SELECT 
  r.*,
  get_current_tenant_name(r.id) as current_tenant_name
FROM public.rooms r;

-- ----------------------------------------------------------------
-- Query: Get room statistics
-- ----------------------------------------------------------------
-- SELECT 
--   COUNT(*) as total_rooms,
--   COUNT(*) FILTER (WHERE status = 'kosong') as empty_rooms,
--   COUNT(*) FILTER (WHERE status = 'terisi') as occupied_rooms,
--   COUNT(*) FILTER (WHERE status = 'maintenance') as maintenance_rooms,
--   AVG(price) as average_price
-- FROM public.rooms;

-- ================================================================
-- END OF SCHEMA
-- ================================================================

-- Run this entire script in Supabase SQL Editor
-- Make sure to replace placeholder UUIDs with actual auth.users IDs
