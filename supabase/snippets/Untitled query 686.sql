-- ============================================
-- CRÉATION DES POLITIQUES (sans erreur)
-- ============================================

-- 1. Table profiles - suppression des anciennes politiques pour les recréer
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can create own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can delete own profile" ON profiles;

-- Maintenant on peut les recréer
CREATE POLICY "Users can view own profile" ON profiles
FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can create own profile" ON profiles
FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can delete own profile" ON profiles
FOR DELETE USING (auth.uid() = id);

-- ============================================
-- CORRECTION DE LA CLÉ ÉTRANGÈRE
-- ============================================

-- Supprimer l'ancienne contrainte si elle existe
ALTER TABLE quiz_results 
DROP CONSTRAINT IF EXISTS quiz_results_student_id_fkey;

-- Créer la bonne contrainte
ALTER TABLE quiz_results
ADD CONSTRAINT quiz_results_student_id_fkey
FOREIGN KEY (student_id)
REFERENCES profiles(id)
ON DELETE CASCADE;

-- ============================================
-- CRÉER LES PROFILS MANQUANTS
-- ============================================

-- Récupérer tous les utilisateurs Auth qui n'ont pas de profil
INSERT INTO profiles (id, email, full_name)
SELECT 
    au.id,
    au.email,
    COALESCE(au.raw_user_meta_data->>'full_name', au.email, 'Utilisateur')
FROM auth.users au
LEFT JOIN profiles p ON au.id = p.id
WHERE p.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- RECRÉER LES POLITIQUES DE quiz_results
-- ============================================

DROP POLICY IF EXISTS "Quiz creators can view all results" ON quiz_results;
DROP POLICY IF EXISTS "Students can view own results" ON quiz_results;
DROP POLICY IF EXISTS "Anyone can insert quiz results" ON quiz_results;

CREATE POLICY "Quiz creators can view all results" ON quiz_results
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM quiz_sessions qs
    JOIN quizzes q ON qs.quiz_id = q.id
    WHERE qs.id = quiz_results.quiz_session_id
    AND q.creator_id = auth.uid()
  )
);

CREATE POLICY "Students can view own results" ON quiz_results
FOR SELECT USING (student_id = auth.uid());

CREATE POLICY "Anyone can insert quiz results" ON quiz_results
FOR INSERT WITH CHECK (true);

-- ============================================
-- VÉRIFICATION
-- ============================================

-- Vérifier que tous les utilisateurs ont un profil
SELECT 
    COUNT(*) as total_users,
    COUNT(p.id) as users_with_profile
FROM auth.users au
LEFT JOIN profiles p ON au.id = p.id;