-- 1. Vérifier que student_id référence bien profiles(id)
ALTER TABLE quiz_results
DROP CONSTRAINT IF EXISTS quiz_results_student_id_fkey;

ALTER TABLE quiz_results
ADD CONSTRAINT quiz_results_student_id_fkey
FOREIGN KEY (student_id)
REFERENCES profiles(id)
ON DELETE CASCADE;

-- 2. Activer RLS sur quiz_results
ALTER TABLE quiz_results ENABLE ROW LEVEL SECURITY;

-- 3. Politique pour lire les résultats (les créateurs du quiz peuvent voir tous les résultats)
CREATE POLICY "Quiz creators can view all results"
ON quiz_results FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM quiz_sessions qs
    JOIN quizzes q ON qs.quiz_id = q.id
    WHERE qs.id = quiz_results.quiz_session_id
    AND q.creator_id = auth.uid()
  )
);

-- 4. Politique pour que les étudiants voient leurs propres résultats
CREATE POLICY "Students can view own results"
ON quiz_results FOR SELECT
USING (student_id = auth.uid());

-- 5. Politique pour insérer des résultats
CREATE POLICY "Anyone can insert quiz results"
ON quiz_results FOR INSERT
WITH CHECK (true);