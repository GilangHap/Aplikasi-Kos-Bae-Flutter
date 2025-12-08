-- SEED AUTH DATA
-- Run this in your Supabase SQL Editor to create initial users

-- Enable pgcrypto for password hashing
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Create ADMIN User (admin@kosbae.com / password123)
INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    recovery_sent_at,
    last_sign_in_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
) VALUES (
    '00000000-0000-0000-0000-000000000000',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', -- Fixed UUID for Admin
    'authenticated',
    'authenticated',
    'admin@kosbae.com',
    crypt('password123', gen_salt('bf')),
    now(),
    NULL,
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    now(),
    now(),
    '',
    '',
    '',
    ''
) ON CONFLICT (id) DO NOTHING;

-- 2. Create ADMIN Profile
INSERT INTO public.profiles (id, full_name, phone, role, avatar_url)
VALUES (
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'Super Admin',
    '081234567890',
    'admin',
    'https://ui-avatars.com/api/?name=Super+Admin&background=random'
) ON CONFLICT (id) DO NOTHING;

-- 3. Create TENANT User (tenant@kosbae.com / password123)
INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    recovery_sent_at,
    last_sign_in_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
) VALUES (
    '00000000-0000-0000-0000-000000000000',
    'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380b22', -- Fixed UUID for Tenant
    'authenticated',
    'authenticated',
    'tenant@kosbae.com',
    crypt('password123', gen_salt('bf')),
    now(),
    NULL,
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    now(),
    now(),
    '',
    '',
    '',
    ''
) ON CONFLICT (id) DO NOTHING;

-- 4. Create TENANT Profile
INSERT INTO public.profiles (id, full_name, phone, role, avatar_url)
VALUES (
    'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380b22',
    'Contoh Penghuni',
    '089876543210',
    'tenant',
    'https://ui-avatars.com/api/?name=Contoh+Penghuni&background=random'
) ON CONFLICT (id) DO NOTHING;

-- 5. Link Tenant User to a Tenant Record (Example)
-- This creates a tenant record linked to the user, so they can see their data
INSERT INTO public.tenants (id, name, phone, status, user_id)
VALUES (
    gen_random_uuid(),
    'Contoh Penghuni',
    '089876543210',
    'aktif',
    'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380b22'
) ON CONFLICT DO NOTHING;
