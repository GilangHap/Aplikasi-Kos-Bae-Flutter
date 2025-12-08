-- ============================================
-- CONTRACTS TABLE SCHEMA
-- Kos Bae - Rental Contract Management
-- ============================================

-- Create contracts table
CREATE TABLE IF NOT EXISTS public.contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    room_id UUID NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
    monthly_rent DECIMAL(12, 2) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    document_url TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'aktif' CHECK (status IN ('aktif', 'akan_habis', 'berakhir')),
    notes TEXT,
    parent_contract_id UUID REFERENCES public.contracts(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT valid_date_range CHECK (end_date > start_date),
    CONSTRAINT positive_rent CHECK (monthly_rent > 0)
);

-- Add contract_id column to bills table for linking bills to contracts
ALTER TABLE public.bills 
ADD COLUMN IF NOT EXISTS contract_id UUID REFERENCES public.contracts(id) ON DELETE SET NULL;

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_contracts_tenant_id ON public.contracts(tenant_id);
CREATE INDEX IF NOT EXISTS idx_contracts_room_id ON public.contracts(room_id);
CREATE INDEX IF NOT EXISTS idx_contracts_status ON public.contracts(status);
CREATE INDEX IF NOT EXISTS idx_contracts_start_date ON public.contracts(start_date);
CREATE INDEX IF NOT EXISTS idx_contracts_end_date ON public.contracts(end_date);
CREATE INDEX IF NOT EXISTS idx_contracts_parent_id ON public.contracts(parent_contract_id);
CREATE INDEX IF NOT EXISTS idx_bills_contract_id ON public.bills(contract_id);

-- Enable Row Level Security
ALTER TABLE public.contracts ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Admins can do everything
CREATE POLICY "Admins can manage contracts" ON public.contracts
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );

-- Tenants can view their own contracts
CREATE POLICY "Tenants can view own contracts" ON public.contracts
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.tenants t
            WHERE t.id = contracts.tenant_id
        )
        OR
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.contracts;

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_contracts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for auto-updating updated_at
DROP TRIGGER IF EXISTS trigger_contracts_updated_at ON public.contracts;
CREATE TRIGGER trigger_contracts_updated_at
    BEFORE UPDATE ON public.contracts
    FOR EACH ROW
    EXECUTE FUNCTION update_contracts_updated_at();

-- Function to auto-update contract status based on dates
-- This can be called by a cron job daily
CREATE OR REPLACE FUNCTION update_contract_statuses()
RETURNS void AS $$
BEGIN
    -- Mark contracts as 'akan_habis' if within 30 days of expiration
    UPDATE public.contracts
    SET status = 'akan_habis'
    WHERE status = 'aktif'
    AND end_date <= CURRENT_DATE + INTERVAL '30 days'
    AND end_date > CURRENT_DATE;

    -- Mark contracts as 'berakhir' if past end date
    UPDATE public.contracts
    SET status = 'berakhir'
    WHERE status IN ('aktif', 'akan_habis')
    AND end_date < CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- STORAGE BUCKET FOR CONTRACT DOCUMENTS
-- ============================================

-- Create storage bucket for contract documents (run this via Supabase Dashboard or API)
-- INSERT INTO storage.buckets (id, name, public) 
-- VALUES ('contracts', 'contracts', true)
-- ON CONFLICT (id) DO NOTHING;

-- Storage policy for contracts bucket - Admins can upload
-- CREATE POLICY "Admins can upload contract documents" 
-- ON storage.objects FOR INSERT 
-- WITH CHECK (
--     bucket_id = 'contracts' AND
--     EXISTS (
--         SELECT 1 FROM public.users
--         WHERE users.id = auth.uid()
--         AND users.role = 'admin'
--     )
-- );

-- Storage policy - Authenticated users can view contract documents
-- CREATE POLICY "Authenticated users can view contract documents" 
-- ON storage.objects FOR SELECT 
-- USING (
--     bucket_id = 'contracts' AND
--     auth.role() = 'authenticated'
-- );

-- Storage policy - Admins can delete contract documents
-- CREATE POLICY "Admins can delete contract documents" 
-- ON storage.objects FOR DELETE 
-- USING (
--     bucket_id = 'contracts' AND
--     EXISTS (
--         SELECT 1 FROM public.users
--         WHERE users.id = auth.uid()
--         AND users.role = 'admin'
--     )
-- );

-- ============================================
-- VIEW FOR CONTRACT WITH TENANT AND ROOM INFO
-- ============================================

CREATE OR REPLACE VIEW public.contracts_with_details AS
SELECT 
    c.*,
    t.name as tenant_name,
    t.phone as tenant_phone,
    r.room_number as room_number,
    r.price as room_price
FROM public.contracts c
LEFT JOIN public.tenants t ON c.tenant_id = t.id
LEFT JOIN public.rooms r ON c.room_id = r.id;

-- Grant access to the view
GRANT SELECT ON public.contracts_with_details TO authenticated;

-- ============================================
-- EXAMPLE QUERIES
-- ============================================

-- Get all active contracts with tenant info
-- SELECT * FROM contracts_with_details WHERE status = 'aktif';

-- Get contracts expiring within 30 days
-- SELECT * FROM contracts_with_details 
-- WHERE status IN ('aktif', 'akan_habis') 
-- AND end_date <= CURRENT_DATE + INTERVAL '30 days';

-- Get contract history for a tenant
-- SELECT * FROM contracts_with_details 
-- WHERE tenant_id = 'tenant-uuid-here' 
-- ORDER BY start_date DESC;

-- Get bills for a specific contract
-- SELECT * FROM bills WHERE contract_id = 'contract-uuid-here';

-- ============================================
-- NOTES
-- ============================================
-- 
-- Status values:
-- - 'aktif': Active contract, end_date > 30 days from now
-- - 'akan_habis': Contract expiring within 30 days
-- - 'berakhir': Contract has ended (end_date < today)
--
-- The parent_contract_id is used for tracking contract renewals.
-- When a contract is renewed:
-- 1. Old contract status -> 'berakhir'
-- 2. New contract is created with parent_contract_id = old contract id
-- 3. Monthly bills are auto-generated for the new contract period
--
-- Monthly bills are generated with:
-- - type: 'sewa' (rent)
-- - due_date: 10th of each month
-- - amount: monthly_rent from contract
-- - tenant_id: from contract
-- - contract_id: linked to the contract
