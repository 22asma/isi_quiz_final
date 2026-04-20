import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_quiz/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:isi_quiz/features/auth/presentation/bloc/auth_state.dart';
import '../../../../core/theme/app_theme.dart';

class TakeQuizPage extends StatefulWidget {
  const TakeQuizPage({super.key, required this.quiz});

  final Map<String, dynamic> quiz;

  @override
  State<TakeQuizPage> createState() => _TakeQuizPageState();
}

class _TakeQuizPageState extends State<TakeQuizPage> {
  int _currentQuestionIndex = 0;
  Map<String, dynamic>? _selectedAnswer;
  List<String> _userAnswers = [];
  bool _isLoading = false;
  int _timeLeft = 20;
  late int _totalTime;
  bool _quizStarted = false;

  @override
  void initState() {
    super.initState();
    _totalTime = widget.quiz['time_limit'] as int? ?? 20;
    _timeLeft = _totalTime;
    _userAnswers = List.filled(_getQuestions().length, '');
  }

  List<Map<String, dynamic>> _getQuestions() {
    final questions = widget.quiz['questions'] as List<dynamic>? ?? [];
    return List<Map<String, dynamic>>.from(questions);
  }

  void _startQuiz() {
    setState(() {
      _quizStarted = true;
    });
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
        _startTimer();
      } else if (mounted && _timeLeft == 0) {
        _nextQuestion();
      }
    });
  }

  void _selectAnswer(String answerId) {
    setState(() {
      _selectedAnswer = {'id': answerId};
      _userAnswers[_currentQuestionIndex] = answerId;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _getQuestions().length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _timeLeft = _totalTime;
      });
      _startTimer();
    } else {
      _finishQuiz();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _selectedAnswer = _userAnswers[_currentQuestionIndex].isNotEmpty 
            ? {'id': _userAnswers[_currentQuestionIndex]} 
            : null;
        _timeLeft = _totalTime;
      });
    }
  }

  void _finishQuiz() async {
    setState(() => _isLoading = true);

    // TODO: Save quiz results to database
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/quiz-results',
        arguments: {
          'quiz': widget.quiz,
          'answers': _userAnswers,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = _getQuestions();
    final currentQuestion = questions.isNotEmpty ? questions[_currentQuestionIndex] : null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.quiz['title'] as String? ?? 'Quiz',
          style: const TextStyle(color: AppTheme.primaryColor),
        ),
        iconTheme: const IconThemeData(color: AppTheme.primaryColor),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _timeLeft <= 5 ? Colors.red : AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$_timeLeft s',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: !_quizStarted
          ? _buildStartScreen()
          : currentQuestion != null
              ? _buildQuestionScreen(currentQuestion)
              : const Center(child: Text('Aucune question disponible')),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                size: 60,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.quiz['title'] as String? ?? 'Quiz',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '${_getQuestions().length} questions • $_totalTime secondes par question',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _startQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Commencer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionScreen(Map<String, dynamic> question) {
    final answers = question['answers'] as List<dynamic>? ?? [];
    final quizType = widget.quiz['quiz_type'] as String? ?? 'Quiz';

    return Column(
      children: [
        // Progress bar
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1}/${_getQuestions().length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Text(
                    quizType,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / _getQuestions().length,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ],
          ),
        ),
        // Question
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question['question_text'] as String? ?? 'Question',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: answers.length,
                        itemBuilder: (context, index) {
                          final answer = answers[index] as Map<String, dynamic>;
                          final answerId = answer['id'] as String?;
                          final isSelected = _selectedAnswer?['id'] == answerId;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              tileColor: isSelected 
                                  ? AppTheme.primaryColor.withOpacity(0.1)
                                  : Colors.grey[50],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected 
                                      ? AppTheme.primaryColor 
                                      : Colors.grey[300]!,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              title: Text(
                                answer['answer_text'] as String? ?? 'Réponse',
                                style: TextStyle(
                                  fontWeight: isSelected 
                                      ? FontWeight.bold 
                                      : FontWeight.normal,
                                  color: isSelected 
                                      ? AppTheme.primaryColor 
                                      : Colors.black87,
                                ),
                              ),
                              onTap: () => _selectAnswer(answerId!),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Navigation buttons
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_currentQuestionIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousQuestion,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Précédent'),
                  ),
                ),
              if (_currentQuestionIndex > 0) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedAnswer != null ? _nextQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _currentQuestionIndex < _getQuestions().length - 1 
                        ? 'Suivant' 
                        : 'Terminer',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
