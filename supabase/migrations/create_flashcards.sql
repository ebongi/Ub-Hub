-- Flashcard decks generated from a course material (a PDF) plus the cards
-- inside them. A deck is owned by the user who generated it; storing it means
-- they can re-study without spending AI credits again. Applied by hand in the
-- Supabase SQL editor, like the other migrations here.

-- 1. Deck table. course_id / department_id are denormalized from the source
--    material at creation time so a course/department screen can list all of
--    its decks with a plain .eq() (Supabase realtime streams allow one filter).
CREATE TABLE IF NOT EXISTS flashcard_decks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    material_id UUID NOT NULL REFERENCES course_materials(id) ON DELETE CASCADE,
    course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
    department_id UUID REFERENCES departments(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    card_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Card table.
CREATE TABLE IF NOT EXISTS flashcards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deck_id UUID NOT NULL REFERENCES flashcard_decks(id) ON DELETE CASCADE,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    position INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS flashcard_decks_material_id_idx ON flashcard_decks(material_id);
CREATE INDEX IF NOT EXISTS flashcard_decks_course_id_idx ON flashcard_decks(course_id);
CREATE INDEX IF NOT EXISTS flashcard_decks_department_id_idx ON flashcard_decks(department_id);
CREATE INDEX IF NOT EXISTS flashcard_decks_user_id_idx ON flashcard_decks(user_id);
CREATE INDEX IF NOT EXISTS flashcards_deck_id_idx ON flashcards(deck_id);

-- 3. RLS — decks are private to their creator (house style: auth.uid() = user_id).
ALTER TABLE flashcard_decks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own decks" ON flashcard_decks;
CREATE POLICY "Users can manage own decks" ON flashcard_decks
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

ALTER TABLE flashcards ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage cards in own decks" ON flashcards;
CREATE POLICY "Users can manage cards in own decks" ON flashcards
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM flashcard_decks d
            WHERE d.id = flashcards.deck_id AND d.user_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM flashcard_decks d
            WHERE d.id = flashcards.deck_id AND d.user_id = auth.uid()
        )
    );

-- 4. Realtime — the deck list on the material/course/department screens streams.
DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE flashcard_decks;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;
