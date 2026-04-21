import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuizRankingPage extends StatefulWidget {
  const QuizRankingPage({super.key});

  @override
  State<QuizRankingPage> createState() => _QuizRankingPageState();
}

class _QuizRankingPageState extends State<QuizRankingPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, dynamic>? _quizData;
  List<Map<String, dynamic>> _rankings = [];
  bool _isLoading = true;
  bool _isMyQuiz = false;

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
      _isMyQuiz = args['isMyQuiz'] as bool? ?? false;
      _loadRankings();
    }
  }

  Future<void> _loadRankings() async {
    try {
      if (_quizData == null) return;
      final sessionsResponse = await _supabase
          .from('quiz_sessions')
          .select('id')
          .eq('quiz_id', _quizData!['id']);

      if (sessionsResponse.isEmpty) {
        setState(() {
          _rankings = [];
          _isLoading = false;
        });
        return;
      }

      final sessionIds =
          sessionsResponse.map((s) => s['id'] as String).toList();

      final response = await _supabase
          .from('quiz_results')
          .select('''
            total_score,
            max_possible_score,
            percentage,
            completed_at,
            student_id,
            profiles!inner (
              full_name,
              email
            ),
            quiz_sessions (
              started_at
            )
          ''')
          .filter('quiz_session_id', 'in', sessionIds)
          .order('percentage', ascending: false);

      setState(() {
        _rankings = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading rankings: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'Date inconnue';
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1: return const Color(0xFFFFB300); // Ambre
      case 2: return const Color(0xFF78909C); // Gris-bleu
      case 3: return const Color(0xFF8D6E63); // Brun
      default: return primaryColor;
    }
  }

  Widget _getRankIcon(int rank) {
    if (rank <= 3) {
      return Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: _getRankColor(rank).withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.emoji_events_rounded,
          color: _getRankColor(rank),
          size: 22,
        ),
      );
    }
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          '$rank',
          style: const TextStyle(
            color: primaryColor,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_quizData == null) {
      return const Scaffold(
        backgroundColor: neutralColor,
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
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
                  Positioned(
                    top: 20, right: 20,
                    child: Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.07),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 16, 28),
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
                              child: Text(
                                _isMyQuiz ? 'Mon Quiz' : 'Quiz Public',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
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
                                'Classement des participants',
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

          // ── Stats bar ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Row(
              children: [
                _buildStatCard(
                  icon: Icons.people_outline_rounded,
                  value: '${_rankings.length}',
                  label: 'Participants',
                  color: primaryColor,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Icons.quiz_outlined,
                  value: '${_quizData!['questions']?.length ?? 0}',
                  label: 'Questions',
                  color: secondaryColor,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Icons.timer_outlined,
                  value: '${_quizData!['time_limit'] ?? 20}s',
                  label: 'Temps',
                  color: tertiaryColor,
                ),
              ],
            ),
          ),

          // ── Liste classements ─────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: primaryColor))
                : _rankings.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadRankings,
                        color: primaryColor,
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          itemCount: _rankings.length,
                          itemBuilder: (context, index) =>
                              _buildRankCard(_rankings[index], index + 1),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ── Widgets helpers ────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.07),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.leaderboard_outlined,
                size: 44, color: primaryColor.withOpacity(0.3)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Aucun participant',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Soyez le premier à compléter ce quiz !',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankCard(Map<String, dynamic> ranking, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _getRankIcon(rank),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ranking['profiles']?['full_name'] as String? ??
                        'Participant #$rank',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    ranking['profiles']?['email'] as String? ??
                        'email@exemple.com',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(ranking['percentage'] as num?)?.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _getRankColor(rank),
                  ),
                ),
                Text(
                  '${ranking['total_score']}/${ranking['max_possible_score']}',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                Text(
                  _formatDate(ranking['completed_at'] as String? ?? ''),
                  style:
                      TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}