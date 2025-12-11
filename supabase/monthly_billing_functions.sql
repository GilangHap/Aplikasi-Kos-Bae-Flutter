-- ================================================
-- MONTHLY BILLING SYSTEM FUNCTIONS
-- Run this in Supabase SQL Editor
-- ================================================

-- 1. Function to generate monthly bills for active contracts
CREATE OR REPLACE FUNCTION generate_monthly_bills()
RETURNS TABLE (
  generated_count INTEGER,
  message TEXT
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  due_day INTEGER;
  current_month DATE;
  bills_created INTEGER := 0;
  contract_record RECORD;
  existing_bill_count INTEGER;
  new_bill_id UUID;
BEGIN
  -- Get due date day from settings (default 10)
  SELECT COALESCE(
    (SELECT due_date_day FROM app_settings WHERE id = 'default'),
    10
  ) INTO due_day;
  
  -- Current month start
  current_month := date_trunc('month', CURRENT_DATE)::DATE;
  
  -- Loop through active contracts
  FOR contract_record IN 
    SELECT c.id, c.tenant_id, c.room_id, c.monthly_rent, c.start_date, c.end_date
    FROM contracts c
    WHERE c.status = 'aktif'
      AND c.start_date <= current_month + INTERVAL '1 month' - INTERVAL '1 day'
      AND c.end_date >= current_month
  LOOP
    -- Check if bill already exists for this contract and month
    SELECT COUNT(*) INTO existing_bill_count
    FROM bills b
    WHERE b.contract_id = contract_record.id
      AND b.billing_period_start = current_month
      AND b.type = 'sewa';
    
    -- If no bill exists, create one
    IF existing_bill_count = 0 THEN
      INSERT INTO bills (
        tenant_id,
        room_id,
        contract_id,
        amount,
        type,
        status,
        due_date,
        billing_period_start,
        billing_period_end,
        notes
      ) VALUES (
        contract_record.tenant_id,
        contract_record.room_id,
        contract_record.id,
        contract_record.monthly_rent,
        'sewa',
        'pending',
        (current_month + (due_day - 1) * INTERVAL '1 day')::DATE,
        current_month,
        (current_month + INTERVAL '1 month' - INTERVAL '1 day')::DATE,
        'Tagihan otomatis bulan ' || to_char(current_month, 'Month YYYY')
      )
      RETURNING id INTO new_bill_id;
      
      bills_created := bills_created + 1;
    END IF;
  END LOOP;
  
  RETURN QUERY SELECT bills_created, 
    CASE 
      WHEN bills_created > 0 THEN bills_created || ' tagihan berhasil dibuat'
      ELSE 'Tidak ada tagihan baru yang dibuat'
    END;
END;
$$;

-- 2. Function to update expired contracts status
CREATE OR REPLACE FUNCTION update_expired_contracts()
RETURNS TABLE (
  updated_count INTEGER,
  message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  contracts_updated INTEGER := 0;
BEGIN
  -- Update contracts where end_date has passed
  UPDATE contracts
  SET status = 'berakhir',
      updated_at = NOW()
  WHERE status = 'aktif'
    AND end_date < CURRENT_DATE;
  
  GET DIAGNOSTICS contracts_updated = ROW_COUNT;
  
  -- Also update tenant status to 'keluar' for expired contracts
  UPDATE tenants t
  SET status = 'keluar',
      updated_at = NOW()
  FROM contracts c
  WHERE t.contract_id = c.id
    AND c.status = 'berakhir'
    AND t.status = 'aktif';
  
  -- Update room status to 'kosong' for expired contracts
  UPDATE rooms r
  SET status = 'kosong',
      current_tenant_name = NULL,
      contract_id = NULL,
      updated_at = NOW()
  FROM contracts c
  WHERE r.contract_id = c.id
    AND c.status = 'berakhir'
    AND r.status = 'terisi';
  
  RETURN QUERY SELECT contracts_updated,
    CASE 
      WHEN contracts_updated > 0 THEN contracts_updated || ' kontrak berakhir diperbarui'
      ELSE 'Tidak ada kontrak yang berakhir'
    END;
END;
$$;

-- 3. Function to update contracts nearing expiry (akan_habis)
CREATE OR REPLACE FUNCTION update_expiring_contracts()
RETURNS TABLE (
  updated_count INTEGER,
  message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  contracts_updated INTEGER := 0;
BEGIN
  -- Update contracts ending within 30 days
  UPDATE contracts
  SET status = 'akan_habis',
      updated_at = NOW()
  WHERE status = 'aktif'
    AND end_date >= CURRENT_DATE
    AND end_date <= CURRENT_DATE + INTERVAL '30 days';
  
  GET DIAGNOSTICS contracts_updated = ROW_COUNT;
  
  RETURN QUERY SELECT contracts_updated,
    CASE 
      WHEN contracts_updated > 0 THEN contracts_updated || ' kontrak akan habis'
      ELSE 'Tidak ada kontrak yang akan habis'
    END;
END;
$$;

-- 4. Combined function for daily maintenance (call this manually or via cron)
CREATE OR REPLACE FUNCTION run_daily_maintenance()
RETURNS TABLE (
  operation TEXT,
  result TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  bills_result RECORD;
  expired_result RECORD;
  expiring_result RECORD;
BEGIN
  -- Generate monthly bills
  SELECT * INTO bills_result FROM generate_monthly_bills();
  RETURN QUERY SELECT 'Generate Bills'::TEXT, bills_result.message;
  
  -- Update expired contracts
  SELECT * INTO expired_result FROM update_expired_contracts();
  RETURN QUERY SELECT 'Update Expired'::TEXT, expired_result.message;
  
  -- Update expiring contracts
  SELECT * INTO expiring_result FROM update_expiring_contracts();
  RETURN QUERY SELECT 'Update Expiring'::TEXT, expiring_result.message;
END;
$$;

-- 5. Grant access to authenticated users (for admin to call)
GRANT EXECUTE ON FUNCTION generate_monthly_bills() TO authenticated;
GRANT EXECUTE ON FUNCTION update_expired_contracts() TO authenticated;
GRANT EXECUTE ON FUNCTION update_expiring_contracts() TO authenticated;
GRANT EXECUTE ON FUNCTION run_daily_maintenance() TO authenticated;

-- ================================================
-- HOW TO USE:
-- 1. Call SELECT * FROM run_daily_maintenance(); from admin panel
-- 2. Or set up pg_cron to run daily:
--    SELECT cron.schedule('daily-maintenance', '0 0 * * *', 'SELECT * FROM run_daily_maintenance()');
-- ================================================
