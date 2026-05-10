-- Create bot_knowledge table
CREATE TABLE IF NOT EXISTS public.bot_knowledge (
    id UUID DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Enable RLS
ALTER TABLE public.bot_knowledge ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can manage their own knowledge"
    ON public.bot_knowledge
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Index for performance
CREATE INDEX IF NOT EXISTS idx_bot_knowledge_user ON public.bot_knowledge(user_id);
