-- Add group quiz features
-- This migration adds support for group/class quizzes with creator-controlled start

-- Add max_participants field to quizzes table (for group quizzes)
ALTER TABLE quizzes ADD COLUMN IF NOT EXISTS max_participants INTEGER;

-- Add current_participants field to track current number of participants
ALTER TABLE quizzes ADD COLUMN IF NOT EXISTS current_participants INTEGER DEFAULT 0;

-- Add session_status field to track group quiz session state
ALTER TABLE quizzes ADD COLUMN IF NOT EXISTS session_status TEXT DEFAULT 'waiting' 
CHECK (session_status IN ('waiting', 'started', 'finished'));

-- Add started_by field to track who started the quiz
ALTER TABLE quizzes ADD COLUMN IF NOT EXISTS started_by UUID REFERENCES auth.users(id);

-- Create indexes for new fields
CREATE INDEX IF NOT EXISTS quizzes_session_status_idx ON quizzes(session_status);
CREATE INDEX IF NOT EXISTS quizzes_started_by_idx ON quizzes(started_by);

-- Add policy for group quiz access
CREATE POLICY "Users can join group quizzes with PIN" ON quizzes
  FOR SELECT USING (
    is_public = false AND 
    pin_code IS NOT NULL AND
    current_participants < COALESCE(max_participants, 999)
  );
