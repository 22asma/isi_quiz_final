-- Create admin functions to bypass RLS for quiz results and attempts

-- Function to insert quiz attempt bypassing RLS
CREATE OR REPLACE FUNCTION admin_insert_quiz_attempt(
  quiz_session_id UUID,
  student_id UUID,
  question_id UUID,
  selected_answer_id UUID,
  is_correct BOOLEAN,
  time_taken INTEGER,
  answered_at TIMESTAMP WITH TIME ZONE
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO quiz_attempts (
    quiz_session_id,
    student_id,
    question_id,
    selected_answer_id,
    is_correct,
    time_taken,
    answered_at
  ) VALUES (
    quiz_session_id,
    student_id,
    question_id,
    selected_answer_id,
    is_correct,
    time_taken,
    answered_at
  );
END;
$$;

-- Function to insert quiz result bypassing RLS
CREATE OR REPLACE FUNCTION admin_insert_quiz_result(
  quiz_session_id UUID,
  student_id UUID,
  total_score INTEGER,
  max_possible_score INTEGER,
  percentage DOUBLE PRECISION,
  completed_at TIMESTAMP WITH TIME ZONE
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO quiz_results (
    quiz_session_id,
    student_id,
    total_score,
    max_possible_score,
    percentage,
    completed_at
  ) VALUES (
    quiz_session_id,
    student_id,
    total_score,
    max_possible_score,
    percentage,
    completed_at
  );
END;
$$;

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION admin_insert_quiz_attempt TO authenticated;
GRANT EXECUTE ON FUNCTION admin_insert_quiz_result TO authenticated;
