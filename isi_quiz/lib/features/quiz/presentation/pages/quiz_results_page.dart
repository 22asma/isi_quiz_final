import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_quiz/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:isi_quiz/features/auth/presentation/bloc/auth_state.dart';
import 'package:isi_quiz/features/quiz/services/quiz_service.dart';
import '../../../../core/theme/app_theme.dart';

class QuizResultsPage extends StatefulWidget {
  const QuizResultsPage({super.key});

  @override
  State<QuizResultsPage> createState() => _QuizResultsPageState();
}

class _QuizResultsPageState extends State<QuizResultsPage> {
  Map<String, dynamic>? _quizData;
  List<String>? _userAnswers;
  int _correctAnswers = 0;
  int _totalQuestions = 0;
  double _scorePercentage = 0.0;
  bool _isLoading = true;
  bool _resultsSaved = false; // ← FIX: empêche la double sauvegarde

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _quizData == null) {
      _quizData = args['quiz'] as Map<String, dynamic>;
      _userAnswers = (args['answers'] as List<dynamic>?)?.cast<String>();
      _calculateResults();
    }
  }

  void _calculateResults() {
    if (_quizData == null || _userAnswers == null) return;

    final questions = _quizData!['questions'] as List<dynamic>? ?? [];
    _totalQuestions = questions.length;
    _correctAnswers = 0;

    for (int i = 0; i < questions.length; i++) {
      final question = questions[i] as Map<String, dynamic>;
      final answers = question['answers'] as List<dynamic>? ?? [];
      final userAnswerId = _userAnswers![i];

      if (userAnswerId.isNotEmpty) {
        final selectedAnswer = answers.firstWhere(
          (answer) => answer['id'] == userAnswerId,
          orElse: () => null,
        );

        if (selectedAnswer != null && selectedAnswer['is_correct'] == true) {
          _correctAnswers++;
        }
      }
    }

    _scorePercentage =
        _totalQuestions > 0 ? (_correctAnswers / _totalQuestions) * 100 : 0;

    // FIX: sauvegarde une seule fois
    if (!_resultsSaved) {
      _resultsSaved = true;
      _saveResults();
    }
  }

  Future<void> _saveResults() async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated &&
          _quizData != null &&
          _userAnswers != null) {
        final questions = _quizData!['questions'] as List<dynamic>? ?? [];
        final attempts = <Map<String, dynamic>>[];

        for (int i = 0; i < questions.length; i++) {
          final question = questions[i] as Map<String, dynamic>;
          final answers = question['answers'] as List<dynamic>? ?? [];
          final userAnswerId = _userAnswers![i];

          if (userAnswerId.isNotEmpty) {
            final selectedAnswer = answers.firstWhere(
              (answer) => answer['id'] == userAnswerId,
              orElse: () => null,
            );

            attempts.add({
              'question_id': question['id'],
              'selected_answer_id': userAnswerId,
              'is_correct': selectedAnswer?['is_correct'] ?? false,
              'time_taken': _quizData!['time_limit'] ?? 20,
              'answered_at': DateTime.now().toIso8601String(),
            });
          }
        }

        final quizService = QuizService();
        final success = await quizService.saveQuizResult(
          quizId: _quizData!['id'],
          studentId: authState.user.id,
          totalScore: _correctAnswers,
          maxPossibleScore: _totalQuestions,
          percentage: _scorePercentage,
          attempts: attempts,
        );

        if (success) {
          print('Quiz result saved successfully');
        } else {
          print('Failed to save quiz result');
        }
      }
    } catch (e) {
      print('Error saving results: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getScoreMessage() {
    if (_scorePercentage >= 90) return 'Excellent ! 🏆';
    if (_scorePercentage >= 75) return 'Très bien ! 🌟';
    if (_scorePercentage >= 60) return 'Bien ! 👍';
    if (_scorePercentage >= 40) return 'Passable 📚';
    return 'À revoir 📖';
  }

  Color _getScoreColor() {
    if (_scorePercentage >= 75) return Colors.green;
    if (_scorePercentage >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Résultats',
          style: TextStyle(color: AppTheme.primaryColor),
        ),
        iconTheme: const IconThemeData(color: AppTheme.primaryColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Score Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '${_scorePercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getScoreMessage(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: _getScoreColor(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                          'Correctes', _correctAnswers.toString(), Colors.green),
                      _buildStatItem(
                          'Total', _totalQuestions.toString(), Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Quiz Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _quizData!['title'] as String? ?? 'Quiz',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _quizData!['description'] as String? ?? 'Pas de description',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoChip(
                        (_quizData!['quiz_type'] as String? ?? 'Quiz'),
                        Icons.category_outlined,
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        '${_quizData!['time_limit']}s',
                        Icons.timer_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Retour à l\'accueil',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/ranks');
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Voir les classements',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}