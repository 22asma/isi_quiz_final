-- S'assurer que RLS est activé
ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;

-- Politique pour que les créateurs puissent tout faire sur leurs quiz
CREATE POLICY "Creators have full access to own quizzes"
ON quizzes FOR ALL
USING (creator_id = auth.uid());

-- Politique pour que tout le monde puisse voir les quiz publics actifs
CREATE POLICY "Anyone can view active public quizzes"
ON quizzes FOR SELECT
USING (
  is_public = true 
  AND status = 'Actif'
  AND session_status = 'waiting'
);