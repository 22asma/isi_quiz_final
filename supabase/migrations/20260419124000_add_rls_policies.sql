-- Add RLS policies for quiz_attempts and quiz_results tables

-- Policies for quiz_attempts table
CREATE POLICY "Users can insert own quiz attempts" ON quiz_attempts
  FOR INSERT WITH CHECK (auth.uid() = student_id);

CREATE POLICY "Users can view own quiz attempts" ON quiz_attempts
  FOR SELECT USING (auth.uid() = student_id);

CREATE POLICY "Users can update own quiz attempts" ON quiz_attempts
  FOR UPDATE USING (auth.uid() = student_id);

CREATE POLICY "Users can delete own quiz attempts" ON quiz_attempts
  FOR DELETE USING (auth.uid() = student_id);

-- Policies for quiz_results table
CREATE POLICY "Users can insert own quiz results" ON quiz_results
  FOR INSERT WITH CHECK (auth.uid() = student_id);

CREATE POLICY "Users can view own quiz results" ON quiz_results
  FOR SELECT USING (auth.uid() = student_id);

CREATE POLICY "Users can update own quiz results" ON quiz_results
  FOR UPDATE USING (auth.uid() = student_id);

CREATE POLICY "Users can delete own quiz results" ON quiz_results
  FOR DELETE USING (auth.uid() = student_id);

-- Additional policies for quiz creators to view results of their quizzes
CREATE POLICY "Quiz creators can view results of their quizzes" ON quiz_results
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM quiz_sessions 
      JOIN quizzes ON quiz_sessions.quiz_id = quizzes.id
      WHERE quiz_sessions.id = quiz_results.quiz_session_id 
      AND quizzes.creator_id = auth.uid()
    )
  );

CREATE POLICY "Quiz creators can view attempts of their quizzes" ON quiz_attempts
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM quiz_sessions 
      JOIN quizzes ON quiz_sessions.quiz_id = quizzes.id
      WHERE quiz_sessions.id = quiz_attempts.quiz_session_id 
      AND quizzes.creator_id = auth.uid()
    )
  );
