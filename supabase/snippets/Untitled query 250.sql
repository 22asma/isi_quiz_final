-- Activer RLS
ALTER TABLE quiz_sessions ENABLE ROW LEVEL SECURITY;

-- Politique pour lire les sessions
CREATE POLICY "Users can view quiz sessions"
ON quiz_sessions FOR SELECT
USING (true);

-- Politique pour insérer des sessions (pendant le jeu)
CREATE POLICY "Users can insert quiz sessions"
ON quiz_sessions FOR INSERT
WITH CHECK (true);