-- Activer RLS
ALTER TABLE quiz_attempts ENABLE ROW LEVEL SECURITY;

-- Politique pour insérer des tentatives
CREATE POLICY "Users can insert attempts"
ON quiz_attempts FOR INSERT
WITH CHECK (true);

-- Politique pour lire les tentatives
CREATE POLICY "Users can view attempts"
ON quiz_attempts FOR SELECT
USING (true);