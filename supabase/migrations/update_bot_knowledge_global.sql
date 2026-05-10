-- Add is_global column to bot_knowledge
ALTER TABLE public.bot_knowledge ADD COLUMN IF NOT EXISTS is_global BOOLEAN DEFAULT false;

-- Update RLS policies to allow everyone to read global knowledge
DROP POLICY IF EXISTS "Users can manage their own knowledge" ON public.bot_knowledge;

CREATE POLICY "Users can manage their own knowledge"
    ON public.bot_knowledge
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id OR is_global = true)
    WITH CHECK (auth.uid() = user_id);

-- Only admins should be able to create global knowledge (optional, for now anyone can if they set the flag)
-- In a real app, you'd check for an admin role.
