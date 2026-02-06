-- Create payment_transactions table if it doesn't exist
CREATE TABLE IF NOT EXISTS payment_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    payment_ref TEXT NOT NULL UNIQUE,
    amount NUMERIC(10, 2) NOT NULL,
    currency TEXT NOT NULL DEFAULT 'XAF',
    status TEXT NOT NULL DEFAULT 'pending',
    department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add missing columns if they don't exist (for existing tables)
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='payment_transactions' AND column_name='material_id') THEN
        ALTER TABLE payment_transactions ADD COLUMN material_id UUID REFERENCES course_materials(id) ON DELETE SET NULL;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='payment_transactions' AND column_name='item_type') THEN
        ALTER TABLE payment_transactions ADD COLUMN item_type TEXT NOT NULL DEFAULT 'department';
    END IF;
END $$;

-- Create index on payment_ref for faster lookups
CREATE INDEX IF NOT EXISTS idx_payment_transactions_payment_ref 
ON payment_transactions(payment_ref);

-- Create index on user_id for user payment history queries
CREATE INDEX IF NOT EXISTS idx_payment_transactions_user_id 
ON payment_transactions(user_id);

-- Create index on status for filtering
CREATE INDEX IF NOT EXISTS idx_payment_transactions_status 
ON payment_transactions(status);

-- Enable Row Level Security
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;

-- Create policy: Users can view their own payment transactions
DROP POLICY IF EXISTS "Users can view own payments" ON payment_transactions;
CREATE POLICY "Users can view own payments" 
ON payment_transactions FOR SELECT 
USING (auth.uid() = user_id);

-- Create policy: Users can insert their own payment transactions
DROP POLICY IF EXISTS "Users can create own payments" ON payment_transactions;
CREATE POLICY "Users can create own payments" 
ON payment_transactions FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- Create policy: Users can update their own payment transactions
DROP POLICY IF EXISTS "Users can update own payments" ON payment_transactions;
CREATE POLICY "Users can update own payments" 
ON payment_transactions FOR UPDATE 
USING (auth.uid() = user_id);

-- Add comment to table
COMMENT ON TABLE payment_transactions IS 'Stores payment transaction records for department creation and other paid features';
