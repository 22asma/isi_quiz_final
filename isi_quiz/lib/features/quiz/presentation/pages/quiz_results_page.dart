import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_quiz/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:isi_quiz/features/auth/presentation/bloc/auth_state.dart';
import 'package:isi_quiz/features/quiz/services/quiz_service.dart';

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
  bool _resultsSaved = false;

  // ── Palette commune ────────────────────────────────────────────────────────
  static const Color primaryColor   = Color(0xFF003366);
  static const Color secondaryColor = Color(0xFF4A5F70);
  static const Color tertiaryColor  = Color(0xFF592300);
  static const Color neutralColor   = Color(0xFFF5F5F5);

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
        final selected = answers.firstWhere(
          (a) => a['id'] == userAnswerId,
          orElse: () => null,
        );
        if (selected != null && selected['is_correct'] == true) {
          _correctAnswers++;
        }
      }
    }
    _scorePercentage =
        _totalQuestions > 0 ? (_correctAnswers / _totalQuestions) * 100 : 0;

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
            final selected = answers.firstWhere(
              (a) => a['id'] == userAnswerId,
              orElse: () => null,
            );
            attempts.add({
              'question_id': question['id'],
              'selected_answer_id': userAnswerId,
              'is_correct': selected?['is_correct'] ?? false,
              'time_taken': _quizData!['time_limit'] ?? 20,
              'answered_at': DateTime.now().toIso8601String(),
            });
          }
        }

        final quizService = QuizService();
        await quizService.saveQuizResult(
          quizId: _quizData!['id'],
          studentId: authState.user.id,
          totalScore: _correctAnswers,
          maxPossibleScore: _totalQuestions,
          percentage: _scorePercentage,
          attempts: attempts,
        );
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
    if (_scorePercentage >= 75) return const Color(0xFF2E7D32);
    if (_scorePercentage >= 60) return const Color(0xFFE65100);
    return const Color(0xFFB71C1C);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: neutralColor,
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: neutralColor,
      body: Column(
        children: [
          // ── Header foncé ─────────────────────────────────────────────────
          Container(
            color: primaryColor,
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Positioned(
                    top: -40, right: -40,
                    child: Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white, size: 20),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Résultats',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _quizData!['title'] as String? ?? 'Quiz',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Voici vos résultats détaillés',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Corps ─────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Score principal
                  _buildScoreCard(),
                  const SizedBox(height: 16),
                  // Détails du quiz
                  _buildQuizInfoCard(),
                  const SizedBox(height: 28),
                  // Boutons d'action
                  _buildPrimaryButton(
                    label: 'Retour à l\'accueil',
                    backgroundColor: primaryColor,
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/home'),
                  ),
                  const SizedBox(height: 12),
                  _buildOutlinedButton(
                    label: 'Voir les classements',
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/ranks'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Widgets helpers ────────────────────────────────────────────────────────

  Widget _buildScoreCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Cercle de score
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getScoreColor().withOpacity(0.1),
              border: Border.all(color: _getScoreColor().withOpacity(0.3), width: 2),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_scorePercentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: _getScoreColor(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _getScoreMessage(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _getScoreColor(),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Correctes', _correctAnswers.toString(),
                  const Color(0xFF2E7D32)),
              Container(
                  width: 1, height: 36, color: const Color(0xFFF0F0F0)),
              _buildStatItem('Total', _totalQuestions.toString(), secondaryColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuizInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label section
          Row(
            children: [
              Container(
                width: 3, height: 14,
                decoration: BoxDecoration(
                  color: tertiaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'DÉTAILS DU QUIZ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _quizData!['title'] as String? ?? 'Quiz',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _quizData!['description'] as String? ?? 'Pas de description',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildInfoChip(
                _quizData!['quiz_type'] as String? ?? 'Quiz',
                Icons.category_outlined,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                '${_quizData!['time_limit']}s',
                Icons.timer_outlined,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                '$_totalQuestions questions',
                Icons.help_outline,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: secondaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: secondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildOutlinedButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor.withOpacity(0.3)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}