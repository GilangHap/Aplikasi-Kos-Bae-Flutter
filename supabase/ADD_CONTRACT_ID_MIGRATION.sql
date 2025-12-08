-- ================================================================
-- ADD CONTRACT_ID TO TENANTS AND ROOMS TABLES
-- Migration Script - Run this in Supabase SQL Editor
-- ================================================================

-- 1. Add contract_id column to tenants table
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'tenants' 
    AND column_name = 'contract_id') THEN
    ALTER TABLE public.tenants ADD COLUMN contract_id UUID REFERENCES public.contracts(id) ON DELETE SET NULL;
    CREATE INDEX IF NOT EXISTS idx_tenants_contract_id ON public.tenants(contract_id);
    COMMENT ON COLUMN public.tenants.contract_id IS 'Current active contract for this tenant';
  END IF;
END $$;

-- 2. Add contract_id column to rooms table
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'rooms' 
    AND column_name = 'contract_id') THEN
    ALTER TABLE public.rooms ADD COLUMN contract_id UUID REFERENCES public.contracts(id) ON DELETE SET NULL;
    CREATE INDEX IF NOT EXISTS idx_rooms_contract_id ON public.rooms(contract_id);
    COMMENT ON COLUMN public.rooms.contract_id IS 'Current active contract for this room';
  END IF;
END $$;

-- 3. Verify columns were added
SELECT 
  table_name, 
  column_name, 
  data_type
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name IN ('tenants', 'rooms')
  AND column_name = 'contract_id';

-- 4. Sync existing contracts (if any)
-- Update tenants and rooms with their active contracts
UPDATE public.tenants t
SET contract_id = c.id
FROM public.contracts c
WHERE c.tenant_id = t.id 
  AND c.status IN ('aktif', 'akan_habis')
  AND t.contract_id IS NULL;

UPDATE public.rooms r
SET contract_id = c.id
FROM public.contracts c
WHERE c.room_id = r.id 
  AND c.status IN ('aktif', 'akan_habis')
  AND r.contract_id IS NULL;
