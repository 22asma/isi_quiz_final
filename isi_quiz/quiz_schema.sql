-- ============================================
-- Quiz Tables Schema for Supabase
-- ============================================

-- 1. Create quizzes table
CREATE TABLE IF NOT EXISTS quizzes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  instructor_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  quiz_type TEXT DEFAULT 'Quiz' CHECK (quiz_type IN ('Quiz', 'Vrai/Faux', 'Sondage', 'Texte libre')),
  time_limit INTEGER DEFAULT 20, -- in seconds
  points_type TEXT DEFAULT 'Standard' CHECK (points_type IN ('Standard', 'Double', 'Triple')),
  is_public BOOLEAN DEFAULT true,
  answer_limit INTEGER DEFAULT 4,
  status TEXT DEFAULT 'Brouillon' CHECK (status IN ('Brouillon', 'Actif', 'Terminé')),
  pin_code TEXT UNIQUE, -- 4-digit code for joining
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create questions table
CREATE TABLE IF NOT EXISTS questions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  quiz_id UUID REFERENCES quizzes(id) ON DELETE CASCADE,
  question_text TEXT NOT NULL,
  question_order INTEGER NOT NULL,
  multimedia_url TEXT, -- URL for image/video/audio
  multimedia_type TEXT CHECK (multimedia_type IN ('image', 'video', 'audio')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create answers table
CREATE TABLE IF NOT EXISTS answers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  question_id UUID REFERENCES questions(id) ON DELETE CASCADE,
  answer_text TEXT NOT NULL,
  is_correct BOOLEAN DEFAULT false,
  answer_order INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Create quiz_sessions table (for live quiz sessions)
CREATE TABLE IF NOT EXISTS quiz_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  quiz_id UUID REFERENCES quizzes(id) ON DELETE CASCADE,
  session_code TEXT UNIQUE NOT NULL, -- Unique code for live session
  is_active BOOLEAN DEFAULT false,
  started_at TIMESTAMP WITH TIME ZONE,
  ended_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Create quiz_attempts table (for student answers)
CREATE TABLE IF NOT EXISTS quiz_attempts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  quiz_session_id UUID REFERENCES quiz_sessions(id) ON DELETE CASCADE,
  student_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  question_id UUID REFERENCES questions(id) ON DELETE CASCADE,
  selected_answer_id UUID REFERENCES answers(id),
  is_correct BOOLEAN,
  time_taken INTEGER, -- in seconds
  answered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Create quiz_results table (for final scores)
CREATE TABLE IF NOT EXISTS quiz_results (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  quiz_session_id UUID REFERENCES quiz_sessions(id) ON DELETE CASCADE,
  student_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  total_score INTEGER DEFAULT 0,
  max_possible_score INTEGER DEFAULT 0,
  percentage DECIMAL(5,2),
  completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS (Row Level Security) for all tables
ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_results ENABLE ROW LEVEL SECURITY;

-- Create policies for quizzes table
CREATE POLICY "Instructors can view own quizzes" ON quizzes
  FOR SELECT USING (auth.uid() = instructor_id);

CREATE POLICY "Instructors can insert own quizzes" ON quizzes
  FOR INSERT WITH CHECK (auth.uid() = instructor_id);

CREATE POLICY "Instructors can update own quizzes" ON quizzes
  FOR UPDATE USING (auth.uid() = instructor_id);

CREATE POLICY "Instructors can delete own quizzes" ON quizzes
  FOR DELETE USING (auth.uid() = instructor_id);

CREATE POLICY "Students can view public quizzes" ON quizzes
  FOR SELECT USING (is_public = true);

-- Create policies for questions table
CREATE POLICY "Instructors can manage questions for own quizzes" ON questions
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM quizzes 
      WHERE quizzes.id = questions.quiz_id 
      AND quizzes.instructor_id = auth.uid()
    )
  );

CREATE POLICY "Students can view questions for public quizzes" ON questions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM quizzes 
      WHERE quizzes.id = questions.quiz_id 
      AND quizzes.is_public = true
    )
  );

-- Create policies for answers table
CREATE POLICY "Instructors can manage answers for own quiz questions" ON answers
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM questions q
      JOIN quizzes quiz ON q.quiz_id = quiz.id
      WHERE q.id = answers.question_id 
      AND quiz.instructor_id = auth.uid()
    )
  );

CREATE POLICY "Students can view answers for public quiz questions" ON answers
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM questions q
      JOIN quizzes quiz ON q.quiz_id = quiz.id
      WHERE q.id = answers.question_id 
      AND quiz.is_public = true
    )
  );

-- Create policies for quiz_sessions table
CREATE POLICY "Instructors can manage own quiz sessions" ON quiz_sessions
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM quizzes 
      WHERE quizzes.id = quiz_sessions.quiz_id 
      AND quizzes.instructor_id = auth.uid()
    )
  );

CREATE POLICY "Students can view active quiz sessions" ON quiz_sessions
  FOR SELECT USING (is_active = true);

-- Create policies for quiz_attempts table
CREATE POLICY "Students can manage own attempts" ON quiz_attempts
  FOR ALL USING (auth.uid() = student_id);

CREATE POLICY "Instructors can view attempts for their quizzes" ON quiz_attempts
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM quiz_sessions qs
      JOIN quizzes q ON qs.quiz_id = q.id
      WHERE qs.id = quiz_attempts.quiz_session_id 
      AND q.instructor_id = auth.uid()
    )
  );

-- Create policies for quiz_results table
CREATE POLICY "Students can view own results" ON quiz_results
  FOR SELECT USING (auth.uid() = student_id);

CREATE POLICY "Instructors can view results for their quizzes" ON quiz_results
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM quiz_sessions qs
      JOIN quizzes q ON qs.quiz_id = q.id
      WHERE qs.id = quiz_results.quiz_session_id 
      AND q.instructor_id = auth.uid()
    )
  );

-- Create updated_at trigger for all tables
CREATE TRIGGER set_quizzes_updated_at
  BEFORE UPDATE ON quizzes
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_questions_updated_at
  BEFORE UPDATE ON questions
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS quizzes_instructor_id_idx ON quizzes(instructor_id);
CREATE INDEX IF NOT EXISTS quizzes_is_public_idx ON quizzes(is_public);
CREATE INDEX IF NOT EXISTS quizzes_pin_code_idx ON quizzes(pin_code);
CREATE INDEX IF NOT EXISTS questions_quiz_id_idx ON questions(quiz_id);
CREATE INDEX IF NOT EXISTS answers_question_id_idx ON answers(question_id);
CREATE INDEX IF NOT EXISTS quiz_sessions_quiz_id_idx ON quiz_sessions(quiz_id);
CREATE INDEX IF NOT EXISTS quiz_sessions_session_code_idx ON quiz_sessions(session_code);
CREATE INDEX IF NOT EXISTS quiz_attempts_session_id_idx ON quiz_attempts(quiz_session_id);
CREATE INDEX IF NOT EXISTS quiz_attempts_student_id_idx ON quiz_attempts(student_id);
CREATE INDEX IF NOT EXISTS quiz_results_session_id_idx ON quiz_results(quiz_session_id);
CREATE INDEX IF NOT EXISTS quiz_results_student_id_idx ON quiz_results(student_id);

-- Grant permissions
GRANT ALL ON quizzes TO authenticated;
GRANT SELECT ON quizzes TO anon;
GRANT ALL ON questions TO authenticated;
GRANT SELECT ON questions TO anon;
GRANT ALL ON answers TO authenticated;
GRANT SELECT ON answers TO anon;
GRANT ALL ON quiz_sessions TO authenticated;
GRANT SELECT ON quiz_sessions TO anon;
GRANT ALL ON quiz_attempts TO authenticated;
GRANT ALL ON quiz_results TO authenticated;
