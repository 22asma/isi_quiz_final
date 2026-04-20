-- Fix RLS policies to be more permissive for authenticated users

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Users can view own quiz attempts" ON quiz_attempts;
DROP POLICY IF EXISTS "Users can update own quiz attempts" ON quiz_attempts;
DROP POLICY IF EXISTS "Users can delete own quiz attempts" ON quiz_attempts;

DROP POLICY IF EXISTS "Users can view own results" ON quiz_results;
DROP POLICY IF EXISTS "Users can update own quiz results" ON quiz_results;
DROP POLICY IF EXISTS "Users can delete own quiz results" ON quiz_results;

DROP POLICY IF EXISTS "Quiz creators can view results of their quizzes" ON quiz_results;
DROP POLICY IF EXISTS "Quiz creators can view attempts of their quizzes" ON quiz_attempts;

-- Create more permissive policies for quiz_attempts
CREATE POLICY "Enable all operations for authenticated users" ON quiz_attempts
  FOR ALL USING (auth.role() = 'authenticated');

-- Create more permissive policies for quiz_results  
CREATE POLICY "Enable all operations for authenticated users" ON quiz_results
  FOR ALL USING (auth.role() = 'authenticated');

-- Créer des politiques qui fonctionnent avec ta structure
CREATE POLICY "Enable insert for authenticated users" ON quiz_attempts
    FOR INSERT TO authenticated
    WITH CHECK (true);  -- Permet tous les inserts pour les utilisateurs authentifiés

CREATE POLICY "Enable insert for authenticated users" ON quiz_results
    FOR INSERT TO authenticated
    WITH CHECK (true);  -- Permet tous les inserts pour les utilisateurs authentifiés

-- Pour la lecture, permettre aux étudiants de voir leurs propres résultats
CREATE POLICY "Users can view own attempts" ON quiz_attempts
    FOR SELECT TO authenticated
    USING (student_id IN (SELECT id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "Users can view own results" ON quiz_results
    FOR SELECT TO authenticated
    USING (student_id IN (SELECT id FROM profiles WHERE id = auth.uid()));

-- Activer RLS (oui, on l'active avec les bonnes politiques)
ALTER TABLE quiz_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_results ENABLE ROW LEVEL SECURITY;
