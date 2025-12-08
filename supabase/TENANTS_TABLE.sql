-- ================================================================
-- TENANTS TABLE - Run this in Supabase SQL Editor
-- ================================================================

-- Create Tenants Table
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

-- Add current_tenant_name column to rooms if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'rooms' 
    AND column_name = 'current_tenant_name') THEN
    ALTER TABLE public.rooms ADD COLUMN current_tenant_name TEXT;
  END IF;
END $$;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_tenants_status ON public.tenants(status);
CREATE INDEX IF NOT EXISTS idx_tenants_room_id ON public.tenants(room_id);
CREATE INDEX IF NOT EXISTS idx_tenants_name ON public.tenants(name);
CREATE INDEX IF NOT EXISTS idx_tenants_created_at ON public.tenants(created_at DESC);

-- Create trigger for updated_at
DROP TRIGGER IF EXISTS update_tenants_updated_at ON public.tenants;
CREATE TRIGGER update_tenants_updated_at
  BEFORE UPDATE ON public.tenants
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS
ALTER TABLE public.tenants ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Authenticated users can view tenants" ON public.tenants;
DROP POLICY IF EXISTS "Admins can insert tenants" ON public.tenants;
DROP POLICY IF EXISTS "Admins can update tenants" ON public.tenants;
DROP POLICY IF EXISTS "Admins can delete tenants" ON public.tenants;

-- RLS Policies
-- Anyone authenticated can view tenants
CREATE POLICY "Authenticated users can view tenants"
  ON public.tenants FOR SELECT
  TO authenticated
  USING (true);

-- Admins can insert tenants
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
CREATE POLICY "Admins can delete tenants"
  ON public.tenants FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Enable realtime for tenants table
ALTER PUBLICATION supabase_realtime ADD TABLE public.tenants;

-- Sample Data (optional)
INSERT INTO public.tenants (name, phone, nik, address, status, check_in_date)
VALUES
  ('Ahmad Fauzi', '081234567890', '3201234567890001', 'Jl. Merdeka No. 123, Jakarta', 'aktif', '2024-01-15'),
  ('Budi Santoso', '081298765432', '3201234567890002', 'Jl. Pahlawan No. 45, Bandung', 'aktif', '2024-02-01'),
  ('Citra Dewi', '081387654321', '3201234567890003', 'Jl. Sudirman No. 78, Surabaya', 'keluar', '2023-06-01')
ON CONFLICT DO NOTHING;

-- Verify table created
SELECT COUNT(*) as tenant_count FROM public.tenants;
