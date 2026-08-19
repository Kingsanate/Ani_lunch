-- Phase 2: Vendor Architecture
-- Create vendors table
CREATE TABLE IF NOT EXISTS public.vendors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    address TEXT,
    phone TEXT,
    location_lat DOUBLE PRECISION,
    location_lng DOUBLE PRECISION,
    is_open BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Link products to vendors
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS vendor_id UUID REFERENCES public.vendors(id) ON DELETE CASCADE;

-- Link orders to vendors
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS vendor_id UUID REFERENCES public.vendors(id) ON DELETE SET NULL;

-- Enable RLS on vendors
ALTER TABLE public.vendors ENABLE ROW LEVEL SECURITY;

-- Allow public read access to vendors
CREATE POLICY "Allow public read access to vendors" ON public.vendors
    FOR SELECT USING (true);

-- Allow authenticated users to insert/update vendors (Admin/Vendor role logic)
CREATE POLICY "Allow authenticated full access to vendors" ON public.vendors
    FOR ALL USING (auth.role() = 'authenticated');
