-- ============================================
-- SOLUTION POUR LE PROBLÈME DE CLASSEMENT
-- ============================================

-- 1. Supprimer TOUTES les politiques existantes sur quiz_attempts et quiz_results
DROP POLICY IF EXISTS "Users can insert own quiz attempts" ON quiz_attempts;
DROP POLICY IF EXISTS "Users can view own quiz attempts" ON quiz_attempts;
DROP POLICY IF EXISTS "Users can update own quiz attempts" ON quiz_attempts;
DROP POLICY IF EXISTS "Users can delete own quiz attempts" ON quiz_attempts;
DROP POLICY IF EXISTS "Enable all operations for authenticated users" ON quiz_attempts;
DROP POLICY IF EXISTS "Quiz creators can view attempts of their quizzes" ON quiz_attempts;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON quiz_attempts;

DROP POLICY IF EXISTS "Users can insert own quiz results" ON quiz_results;
DROP POLICY IF EXISTS "Users can view own results" ON quiz_results;
DROP POLICY IF EXISTS "Users can update own quiz results" ON quiz_results;
DROP POLICY IF EXISTS "Users can delete own quiz results" ON quiz_results;
DROP POLICY IF EXISTS "Enable all operations for authenticated users" ON quiz_results;
DROP POLICY IF EXISTS "Quiz creators can view results of their quizzes" ON quiz_results;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON quiz_results;

-- 2. Désactiver complètement RLS pour ces tables
ALTER TABLE quiz_attempts DISABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_results DISABLE ROW LEVEL SECURITY;

-- 3. Vérifier que RLS est bien désactivé
SELECT 
  tablename, 
  rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('quiz_attempts', 'quiz_results');