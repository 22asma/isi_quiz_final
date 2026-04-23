-- Vérifier qu'il ne reste plus d'orphelins
SELECT COUNT(*) as orphelins
FROM quiz_results qr
LEFT JOIN profiles p ON p.id = qr.student_id
WHERE p.id IS NULL;
-- Doit retourner 0