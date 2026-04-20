import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';

class RanksPage extends StatefulWidget {
  const RanksPage({super.key});

  @override
  State<RanksPage> createState() => _RanksPageState();
}

class _RanksPageState extends State<RanksPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _myQuizzes = [];
  List<Map<String, dynamic>> _publicQuizzes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _myQuizzes = [];
          _publicQuizzes = [];
          _isLoading = false;
        });
        return;
      }

      final myResponse = await _supabase
          .from('quizzes')
          .select('''
            id,
            title,
            description,
            quiz_type,
            time_limit,
            answer_limit,
            status,
            pin_code,
            created_at,
            questions (id)
          ''')
          .eq('creator_id', currentUser.id)
          .order('created_at', ascending: false);

      final publicResponse = await _supabase
          .from('quizzes')
          .select('''
            id,
            title,
            description,
            quiz_type,
            time_limit,
            answer_limit,
            status,
            pin_code,
            created_at,
            questions (id)
          ''')
          .eq('is_public', true)
          .eq('status', 'Actif')
          .order('created_at', ascending: false);

      setState(() {
        _myQuizzes = List<Map<String, dynamic>>.from(myResponse);
        _publicQuizzes = List<Map<String, dynamic>>.from(publicResponse);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading quizzes for rankings: $e');
      setState(() {
        _myQuizzes = [];
        _publicQuizzes = [];
        _isLoading = false;
      });
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Date inconnue';
    }
  }

  String _getRankBadge(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return AppTheme.primaryColor;
    }
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> quiz, {required bool isMyQuiz}) {
    final questionCount = (quiz['questions'] as List<dynamic>?)?.length ?? 0;
    final status = quiz['status'] as String? ?? 'Inconnu';
    final quizType = quiz['quiz_type'] as String? ?? 'Quiz';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    quiz['title'] as String? ?? 'Quiz sans titre',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: status == 'Actif' ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: status == 'Actif' ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _smallChip(quizType, Icons.category_outlined),
                _smallChip('$questionCount questions', Icons.help_outline),
                _smallChip('${quiz['time_limit'] ?? 20}s', Icons.timer_outlined),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/quiz-ranking',
                    arguments: {
                      'quiz': quiz,
                      'isMyQuiz': isMyQuiz,
                    },
                  );
                },
                icon: const Icon(Icons.leaderboard_outlined, size: 18),
                label: const Text('Voir le classement'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.25)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Classements',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadQuizzes,
            icon: const Icon(Icons.refresh),
            color: AppTheme.primaryColor,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadQuizzes,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Mes quiz',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_myQuizzes.isEmpty)
                    _buildEmptyState(
                      'Vous n’avez pas encore de quiz',
                      'Créez un quiz pour voir son classement ici.',
                    )
                  else
                    ..._myQuizzes.map((quiz) => _buildQuizCard(quiz, isMyQuiz: true)),
                  const SizedBox(height: 24),
                  const Text(
                    'Quiz publics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_publicQuizzes.isEmpty)
                    _buildEmptyState(
                      'Aucun quiz public disponible',
                      'Les quiz publics actifs apparaîtront ici.',
                    )
                  else
                    ..._publicQuizzes.map((quiz) => _buildQuizCard(quiz, isMyQuiz: false)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
