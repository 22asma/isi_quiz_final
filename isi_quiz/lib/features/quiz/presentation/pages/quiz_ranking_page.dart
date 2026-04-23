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
  bool _isMyQuiz  = false;

  static const Color primary   = Color(0xFF003366);
  static const Color secondary = Color(0xFF4A5F70);
  static const Color accent    = Color(0xFF592300);
  static const Color bg        = Color(0xFFF5F5F5);

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
          _rankings  = [];
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
        _rankings  = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading rankings: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '—';
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:  return const Color(0xFFFFB300);
      case 2:  return const Color(0xFF78909C);
      case 3:  return const Color(0xFF8D6E63);
      default: return primary;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_quizData == null) {
      return const Scaffold(
        backgroundColor: bg,
        body: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    final questionCount =
        (_quizData!['questions'] as List<dynamic>?)?.length ?? 0;
    final pinCode = _quizData!['pin_code'] as String? ?? '------';

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            color: primary,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barre nav
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 10, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        // Badge PIN (cohérent avec la carte)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'PIN: $pinCode',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Titre quiz
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _quizData!['title'] as String? ?? 'Quiz',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Quiz avec $questionCount question${questionCount > 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Stats bar (participants, questions, temps)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Row(
                      children: [
                        _headerStat(
                          icon: Icons.people_outline_rounded,
                          value: '${_rankings.length}',
                          label: 'Participants',
                        ),
                        const SizedBox(width: 10),
                        _headerStat(
                          icon: Icons.help_outline_rounded,
                          value: '$questionCount',
                          label: 'Questions',
                        ),
                        const SizedBox(width: 10),
                        _headerStat(
                          icon: Icons.timer_outlined,
                          value: '${_quizData!['time_limit'] ?? 20}s',
                          label: 'Temps/Q',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Liste ─────────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: primary))
                : _rankings.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadRankings,
                        color: primary,
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          itemCount: _rankings.length,
                          itemBuilder: (context, i) =>
                              _buildRankCard(_rankings[i], i + 1),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ── Widgets helpers ───────────────────────────────────────────────────────

  Widget _headerStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.07),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.leaderboard_outlined,
                size: 38, color: primary.withOpacity(0.3)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun participant',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: primary,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Soyez le premier à compléter ce quiz !',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankCard(Map<String, dynamic> ranking, int rank) {
    final rankColor  = _getRankColor(rank);
    final name       = ranking['profiles']?['full_name'] as String?
        ?? 'Participant #$rank';
    final email      = ranking['profiles']?['email'] as String? ?? '';
    final pct        = (ranking['percentage'] as num?)?.toStringAsFixed(1) ?? '0.0';
    final score      = ranking['total_score'] ?? 0;
    final maxScore   = ranking['max_possible_score'] ?? 0;
    final date       = _formatDate(ranking['completed_at'] as String? ?? '');
    final isTop3     = rank <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barre colorée à gauche (même principe que les cartes quiz)
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: rankColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),

            // Rang
            Container(
              width: 52,
              alignment: Alignment.center,
              child: isTop3
                  ? Text(
                      rank == 1
                          ? '🥇'
                          : rank == 2
                              ? '🥈'
                              : '🥉',
                      style: const TextStyle(fontSize: 22),
                    )
                  : Text(
                      '#$rank',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: primary.withOpacity(0.5),
                      ),
                    ),
            ),

            // Séparateur vertical léger
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Colors.grey.shade100,
              indent: 12,
              endIndent: 12,
            ),

            // Infos participant
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade400),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Barre de progression du score
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: maxScore > 0 ? score / maxScore : 0,
                        minHeight: 5,
                        backgroundColor:
                            rankColor.withOpacity(0.12),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(rankColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            ),

            // Score à droite
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 16, 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: rankColor,
                    ),
                  ),
                  Text(
                    '$score/$maxScore',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}