-- Voir quels student_id n'ont pas de profil correspondant
SELECT DISTINCT qr.student_id
FROM quiz_results qr
LEFT JOIN profiles p ON p.id = qr.student_id
WHERE p.id IS NULL;