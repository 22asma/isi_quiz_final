-- Temporarily disable RLS for quiz_attempts and quiz_results tables
-- This allows authenticated users to insert data without restrictions

ALTER TABLE quiz_attempts DISABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_results DISABLE ROW LEVEL SECURITY;

-- Note: This is a temporary solution
-- In production, you should enable RLS and create proper policies
-- To re-enable later:
-- ALTER TABLE quiz_attempts ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE quiz_results ENABLE ROW LEVEL SECURITY;
