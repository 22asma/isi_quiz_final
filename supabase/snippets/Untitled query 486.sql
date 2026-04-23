-- ── 1. RLS profiles : autoriser INSERT/UPDATE pour l'utilisateur lui-même ──
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Lecture : tout le monde peut lire les profils
CREATE POLICY "profiles_select" ON profiles
  FOR SELECT USING (true);

-- Insertion : uniquement son propre profil
CREATE POLICY "profiles_insert" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Modification : uniquement son propre profil
CREATE POLICY "profiles_update" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- ── 2. FK manquante entre quiz_results et profiles ─────────────────────────
-- quiz_results.student_id doit pointer vers profiles.id
-- (si la FK n'existe pas encore)
ALTER TABLE quiz_results
  ADD CONSTRAINT quiz_results_student_id_fkey
  FOREIGN KEY (student_id) REFERENCES profiles(id);

-- ── 3. Recharger le schema cache PostgREST ─────────────────────────────────
NOTIFY pgrst, 'reload schema';