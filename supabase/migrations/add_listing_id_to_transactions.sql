-- Add listing_id to payment_transactions for general marketplace purchases
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='payment_transactions' AND column_name='listing_id') THEN
        ALTER TABLE payment_transactions ADD COLUMN listing_id UUID REFERENCES marketplace_listings(id) ON DELETE SET NULL;
    END IF;
END $$;

-- Update comment
COMMENT ON COLUMN payment_transactions.listing_id IS 'Reference to the marketplace listing being purchased.';
