-- 1. Create marketplace_listings table
CREATE TABLE IF NOT EXISTS marketplace_listings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    price NUMERIC NOT NULL DEFAULT 0,
    category TEXT NOT NULL, -- 'Electronics', 'Books', 'Stationery', 'Other'
    item_type TEXT NOT NULL DEFAULT 'digital', -- 'physical' or 'digital'
    file_url TEXT, -- for digital items
    image_urls TEXT[], -- for physical items (array of image URLs)
    condition TEXT, -- 'New', 'Used - Like New', 'Used - Good', 'Used - Fair'
    status TEXT NOT NULL DEFAULT 'active', -- 'active', 'sold', 'hidden'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Enable RLS
ALTER TABLE marketplace_listings ENABLE ROW LEVEL SECURITY;

-- 3. Policies
DROP POLICY IF EXISTS "Anyone can view active listings" ON marketplace_listings;
CREATE POLICY "Anyone can view active listings" ON marketplace_listings FOR SELECT USING (status = 'active');

DROP POLICY IF EXISTS "Users can create their own listings" ON marketplace_listings;
CREATE POLICY "Users can create their own listings" ON marketplace_listings FOR INSERT WITH CHECK (auth.uid() = vendor_id);

DROP POLICY IF EXISTS "Users can update their own listings" ON marketplace_listings;
CREATE POLICY "Users can update their own listings" ON marketplace_listings FOR UPDATE USING (auth.uid() = vendor_id);

DROP POLICY IF EXISTS "Users can delete their own listings" ON marketplace_listings;
CREATE POLICY "Users can delete their own listings" ON marketplace_listings FOR DELETE USING (auth.uid() = vendor_id);

-- 4. Indexes
CREATE INDEX IF NOT EXISTS idx_marketplace_listings_vendor_id ON marketplace_listings(vendor_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_listings_category ON marketplace_listings(category);
CREATE INDEX IF NOT EXISTS idx_marketplace_listings_status ON marketplace_listings(status);
