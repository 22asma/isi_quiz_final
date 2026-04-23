-- Supprimer les quiz_results dont le student_id n'existe NI dans profiles NI dans auth.users
DELETE FROM quiz_results
WHERE student_id NOT IN (SELECT id FROM profiles);