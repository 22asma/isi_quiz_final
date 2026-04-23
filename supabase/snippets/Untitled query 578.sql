-- Ajouter la FK (maintenant que les données sont propres)
ALTER TABLE quiz_results
  ADD CONSTRAINT quiz_results_student_id_fkey
  FOREIGN KEY (student_id) REFERENCES profiles(id);

-- Même chose pour quiz_attempts si elle existe
ALTER TABLE quiz_attempts
  ADD CONSTRAINT quiz_attempts_student_id_fkey
  FOREIGN KEY (student_id) REFERENCES profiles(id)
  ON DELETE CASCADE;

-- Recharger le schema cache
NOTIFY pgrst, 'reload schema';