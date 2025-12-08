-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.announcement_reads (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  announcement_id uuid NOT NULL,
  tenant_id uuid NOT NULL,
  read_at timestamp with time zone DEFAULT now(),
  CONSTRAINT announcement_reads_pkey PRIMARY KEY (id),
  CONSTRAINT announcement_reads_announcement_id_fkey FOREIGN KEY (announcement_id) REFERENCES public.announcements(id),
  CONSTRAINT announcement_reads_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id)
);
CREATE TABLE public.announcements (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title character varying NOT NULL,
  content text NOT NULL,
  attachments jsonb DEFAULT '[]'::jsonb,
  is_required boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone,
  created_by uuid,
  CONSTRAINT announcements_pkey PRIMARY KEY (id),
  CONSTRAINT announcements_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id)
);
CREATE TABLE public.bills (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  tenant_id uuid NOT NULL,
  room_id uuid,
  amount numeric NOT NULL,
  type text NOT NULL DEFAULT 'sewa'::text CHECK (type = ANY (ARRAY['sewa'::text, 'listrik'::text, 'air'::text, 'deposit'::text, 'denda'::text, 'lainnya'::text])),
  status text NOT NULL DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'verified'::text, 'paid'::text, 'overdue'::text])),
  due_date date NOT NULL,
  billing_period_start date NOT NULL,
  billing_period_end date NOT NULL,
  notes text,
  admin_notes text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  created_by uuid,
  contract_id uuid,
  CONSTRAINT bills_pkey PRIMARY KEY (id),
  CONSTRAINT bills_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id),
  CONSTRAINT bills_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms(id),
  CONSTRAINT bills_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id),
  CONSTRAINT bills_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contracts(id)
);
CREATE TABLE public.complaint_status_history (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  complaint_id uuid NOT NULL,
  from_status character varying NOT NULL,
  to_status character varying NOT NULL,
  notes text,
  created_at timestamp with time zone DEFAULT now(),
  created_by uuid,
  CONSTRAINT complaint_status_history_pkey PRIMARY KEY (id),
  CONSTRAINT complaint_status_history_complaint_id_fkey FOREIGN KEY (complaint_id) REFERENCES public.complaints(id),
  CONSTRAINT complaint_status_history_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id)
);
CREATE TABLE public.complaints (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  room_id uuid NOT NULL,
  tenant_id uuid NOT NULL,
  title text NOT NULL,
  description text NOT NULL,
  media jsonb DEFAULT '[]'::jsonb,
  status text NOT NULL DEFAULT 'open'::text CHECK (status = ANY (ARRAY['submitted'::text, 'open'::text, 'in_progress'::text, 'resolved'::text, 'closed'::text])),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  category character varying DEFAULT 'lainnya'::character varying,
  priority character varying DEFAULT 'normal'::character varying,
  attachments ARRAY DEFAULT '{}'::text[],
  admin_notes text,
  resolution_notes text,
  resolved_at timestamp with time zone,
  resolved_by uuid,
  CONSTRAINT complaints_pkey PRIMARY KEY (id),
  CONSTRAINT complaints_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms(id),
  CONSTRAINT complaints_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES public.profiles(id),
  CONSTRAINT complaints_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id)
);
CREATE TABLE public.contracts (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL,
  room_id uuid NOT NULL,
  monthly_rent numeric NOT NULL CHECK (monthly_rent > 0::numeric),
  start_date date NOT NULL,
  end_date date NOT NULL,
  document_url text,
  status character varying NOT NULL DEFAULT 'aktif'::character varying CHECK (status::text = ANY (ARRAY['aktif'::character varying, 'akan_habis'::character varying, 'berakhir'::character varying]::text[])),
  notes text,
  parent_contract_id uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  created_by uuid,
  CONSTRAINT contracts_pkey PRIMARY KEY (id),
  CONSTRAINT contracts_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id),
  CONSTRAINT contracts_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms(id),
  CONSTRAINT contracts_parent_contract_id_fkey FOREIGN KEY (parent_contract_id) REFERENCES public.contracts(id)
);
CREATE TABLE public.payments (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  bill_id uuid NOT NULL,
  amount numeric NOT NULL,
  method text NOT NULL DEFAULT 'transfer'::text CHECK (method = ANY (ARRAY['transfer'::text, 'cash'::text, 'ewallet'::text])),
  status text NOT NULL DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'verified'::text, 'rejected'::text])),
  proof_url text,
  notes text,
  payment_date date NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  verified_at timestamp with time zone,
  verified_by uuid,
  rejection_reason text,
  CONSTRAINT payments_pkey PRIMARY KEY (id),
  CONSTRAINT payments_bill_id_fkey FOREIGN KEY (bill_id) REFERENCES public.bills(id),
  CONSTRAINT payments_verified_by_fkey FOREIGN KEY (verified_by) REFERENCES auth.users(id)
);
CREATE TABLE public.profiles (
  id uuid NOT NULL,
  full_name text NOT NULL,
  phone text,
  role text NOT NULL CHECK (role = ANY (ARRAY['admin'::text, 'tenant'::text])),
  avatar_url text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
CREATE TABLE public.room_history (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  room_id uuid NOT NULL,
  tenant_id uuid NOT NULL,
  tenant_name text NOT NULL,
  contract_start date NOT NULL,
  contract_end date NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT room_history_pkey PRIMARY KEY (id),
  CONSTRAINT room_history_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms(id),
  CONSTRAINT room_history_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES auth.users(id)
);
CREATE TABLE public.rooms (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  room_number text NOT NULL UNIQUE,
  price numeric NOT NULL CHECK (price >= 0::numeric),
  status text NOT NULL DEFAULT 'kosong'::text CHECK (status = ANY (ARRAY['kosong'::text, 'terisi'::text, 'maintenance'::text])),
  photos jsonb DEFAULT '[]'::jsonb,
  facilities jsonb DEFAULT '[]'::jsonb,
  description text DEFAULT ''::text,
  created_by uuid,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  current_tenant_name text,
  contract_id uuid,
  CONSTRAINT rooms_pkey PRIMARY KEY (id),
  CONSTRAINT rooms_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id),
  CONSTRAINT rooms_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contracts(id)
);
CREATE TABLE public.tenants (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  phone text NOT NULL,
  nik text,
  address text,
  photo_url text,
  room_id uuid,
  status text NOT NULL DEFAULT 'aktif'::text CHECK (status = ANY (ARRAY['aktif'::text, 'keluar'::text, 'nonaktif'::text])),
  check_in_date date,
  check_out_date date,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  user_id uuid,
  contract_id uuid,
  CONSTRAINT tenants_pkey PRIMARY KEY (id),
  CONSTRAINT tenants_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms(id),
  CONSTRAINT tenants_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT tenants_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.contracts(id)
);