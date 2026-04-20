-- Fix foreign key constraints to use auth.users instead of profiles

-- Drop existing foreign key constraints
ALTER TABLE quiz_attempts DROP CONSTRAINT IF EXISTS quiz_attempts_student_id_fkey;
ALTER TABLE quiz_results DROP CONSTRAINT IF EXISTS quiz_results_student_id_fkey;

-- Add correct foreign key constraints pointing to auth.users
ALTER TABLE quiz_attempts 
ADD CONSTRAINT quiz_attempts_student_id_fkey 
FOREIGN KEY (student_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE quiz_results 
ADD CONSTRAINT quiz_results_student_id_fkey 
FOREIGN KEY (student_id) REFERENCES auth.users(id) ON DELETE CASCADE;
