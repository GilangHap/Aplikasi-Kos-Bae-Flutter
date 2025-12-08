-- ================================================================
-- BILLS & PAYMENTS TABLES - Run this in Supabase SQL Editor
-- ================================================================

-- 1. Create Bills Table
CREATE TABLE IF NOT EXISTS public.bills (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  room_id UUID REFERENCES public.rooms(id) ON DELETE SET NULL,
  amount DECIMAL(12,2) NOT NULL,
  type TEXT NOT NULL DEFAULT 'sewa' CHECK (type IN ('sewa', 'listrik', 'air', 'deposit', 'denda', 'lainnya')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'paid', 'overdue')),
  due_date DATE NOT NULL,
  billing_period_start DATE NOT NULL,
  billing_period_end DATE NOT NULL,
  notes TEXT,
  admin_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id)
);

-- 2. Create Payments Table
CREATE TABLE IF NOT EXISTS public.payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  bill_id UUID NOT NULL REFERENCES public.bills(id) ON DELETE CASCADE,
  amount DECIMAL(12,2) NOT NULL,
  method TEXT NOT NULL DEFAULT 'transfer' CHECK (method IN ('transfer', 'cash', 'ewallet')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'rejected')),
  proof_url TEXT,
  notes TEXT,
  rejection_reason TEXT,
  payment_date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  verified_at TIMESTAMPTZ,
  verified_by UUID REFERENCES auth.users(id)
);

-- 3. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_bills_tenant_id ON public.bills(tenant_id);
CREATE INDEX IF NOT EXISTS idx_bills_room_id ON public.bills(room_id);
CREATE INDEX IF NOT EXISTS idx_bills_status ON public.bills(status);
CREATE INDEX IF NOT EXISTS idx_bills_due_date ON public.bills(due_date);
CREATE INDEX IF NOT EXISTS idx_bills_type ON public.bills(type);
CREATE INDEX IF NOT EXISTS idx_bills_billing_period ON public.bills(billing_period_start, billing_period_end);
CREATE INDEX IF NOT EXISTS idx_payments_bill_id ON public.payments(bill_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON public.payments(status);

-- 4. Create trigger for updated_at on bills
DROP TRIGGER IF EXISTS update_bills_updated_at ON public.bills;
CREATE TRIGGER update_bills_updated_at
  BEFORE UPDATE ON public.bills
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- 5. Disable RLS for development (simple approach)
ALTER TABLE public.bills DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments DISABLE ROW LEVEL SECURITY;

-- 6. Or if you want RLS enabled with permissive policies:
/*
ALTER TABLE public.bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- Bills policies
DROP POLICY IF EXISTS "Allow all for authenticated on bills" ON public.bills;
CREATE POLICY "Allow all for authenticated on bills"
  ON public.bills FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Payments policies
DROP POLICY IF EXISTS "Allow all for authenticated on payments" ON public.payments;
CREATE POLICY "Allow all for authenticated on payments"
  ON public.payments FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);
*/

-- 7. Enable realtime for bills and payments
ALTER PUBLICATION supabase_realtime ADD TABLE public.bills;
ALTER PUBLICATION supabase_realtime ADD TABLE public.payments;

-- 8. Create function to auto-update overdue bills (optional, run daily)
CREATE OR REPLACE FUNCTION update_overdue_bills()
RETURNS void AS $$
BEGIN
  UPDATE public.bills
  SET status = 'overdue', updated_at = NOW()
  WHERE status = 'pending' 
    AND due_date < CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;

-- 9. Sample Data (optional - uncomment to add sample bills)
/*
INSERT INTO public.bills (tenant_id, room_id, amount, type, status, due_date, billing_period_start, billing_period_end, notes)
SELECT 
  t.id as tenant_id,
  t.room_id,
  COALESCE(r.price, 1000000) as amount,
  'sewa' as type,
  'pending' as status,
  DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '10 days' as due_date,
  DATE_TRUNC('month', CURRENT_DATE) as billing_period_start,
  (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day')::DATE as billing_period_end,
  'Tagihan sewa bulan ' || TO_CHAR(CURRENT_DATE, 'Month YYYY') as notes
FROM public.tenants t
LEFT JOIN public.rooms r ON t.room_id = r.id
WHERE t.status = 'aktif' AND t.room_id IS NOT NULL
ON CONFLICT DO NOTHING;
*/

-- 10. Verify tables created
SELECT 
  table_name, 
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public' 
  AND table_name IN ('bills', 'payments');
