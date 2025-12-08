-- Add 'nonaktif' to the allowed values for tenant status
ALTER TABLE public.tenants
DROP CONSTRAINT tenants_status_check;

ALTER TABLE public.tenants
ADD CONSTRAINT tenants_status_check 
CHECK (status = ANY (ARRAY['aktif'::text, 'keluar'::text, 'nonaktif'::text]));
