import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_quiz/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:isi_quiz/features/auth/presentation/bloc/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RanksPage extends StatefulWidget {
  const RanksPage({super.key});

  @override
  State<RanksPage> createState() => _RanksPageState();
}

class _RanksPageState extends State<RanksPage>
    with TickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _myQuizzes     = [];
  List<Map<String, dynamic>> _publicQuizzes = [];
  bool _isLoading    = true;
  bool _isInstructor = false;

  late TabController _tabController;

  static const Color primary   = Color(0xFF003366);
  static const Color secondary = Color(0xFF4A5F70);
  static const Color bg        = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadQuizzes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadQuizzes() async {
    setState(() => _isLoading = true);
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        setState(() => _isLoading = false);
        return;
      }

      _isInstructor = authState.user.isInstructor;

      final myQuizzes     = <Map<String, dynamic>>[];
      final publicQuizzes = <Map<String, dynamic>>[];

      // ── Quiz publics (tout le monde) ──────────────────────────────────────
      try {
        final r = await _supabase.from('quizzes').select('''
          id, title, description, quiz_type, time_limit,
          answer_limit, status, pin_code, is_public, created_at,
          questions (id)
        ''').eq('is_public', true).eq('status', 'Actif')
            .order('created_at', ascending: false);
        publicQuizzes.addAll(List<Map<String, dynamic>>.from(r));
      } catch (e) {
        debugPrint('Error loading public quizzes: $e');
      }

      // ── Mes quiz (instructor uniquement) ──────────────────────────────────
      if (_isInstructor) {
        try {
          final r = await _supabase.from('quizzes').select('''
            id, title, description, quiz_type, time_limit,
            answer_limit, status, pin_code, is_public, created_at,
            questions (id)
          ''').eq('creator_id', authState.user.id)
              .order('created_at', ascending: false);
          myQuizzes.addAll(List<Map<String, dynamic>>.from(r));
        } catch (e) {
          debugPrint('Error loading my quizzes: $e');
        }
      }

      // ── Reconstruire le TabController selon le rôle ───────────────────────
      final tabLength = _isInstructor ? 2 : 1;
      if (mounted) {
        _tabController.dispose();
        _tabController = TabController(length: tabLength, vsync: this);
      }

      setState(() {
        _myQuizzes     = myQuizzes;
        _publicQuizzes = publicQuizzes;
        _isLoading     = false;
      });
    } catch (e) {
      debugPrint('Error loading quizzes for rankings: $e');
      setState(() => _isLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: primary))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      if (_isInstructor)
                        _buildTab(_myQuizzes, isMyQuiz: true),
                      _buildTab(_publicQuizzes, isMyQuiz: false),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: primary,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Classements',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isInstructor
                            ? 'Vos quiz et les quiz publics'
                            : 'Classements des quiz publics',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _loadQuizzes,
                    icon: const Icon(Icons.refresh_rounded,
                        color: Colors.white, size: 22),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Compteurs (adaptatifs selon le rôle)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  if (_isInstructor) ...[
                    _headerStat(
                      icon: Icons.lock_outline_rounded,
                      value: '${_myQuizzes.length}',
                      label: 'Mes quiz',
                    ),
                    const SizedBox(width: 12),
                  ],
                  _headerStat(
                    icon: Icons.public_rounded,
                    value: '${_publicQuizzes.length}',
                    label: 'Publics',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // TabBar (adaptatif)
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 13),
              tabs: [
                if (_isInstructor)
                  const Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 14),
                        SizedBox(width: 6),
                        Text('Mes Quiz'),
                      ],
                    ),
                  ),
                const Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.public_rounded, size: 14),
                      SizedBox(width: 6),
                      Text('Quiz Publics'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 12)),
        ],
      ),
    );
  }

  // ── Tab ───────────────────────────────────────────────────────────────────
  Widget _buildTab(List<Map<String, dynamic>> quizzes,
      {required bool isMyQuiz}) {
    if (quizzes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isMyQuiz ? Icons.lock_outline_rounded : Icons.public_rounded,
                size: 36,
                color: primary.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isMyQuiz ? 'Aucun quiz créé' : 'Aucun quiz public actif',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: primary),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                isMyQuiz
                    ? 'Créez un quiz pour voir son classement ici.'
                    : 'Les quiz publics actifs apparaîtront ici.',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQuizzes,
      color: primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: quizzes.length,
        itemBuilder: (ctx, i) =>
            _buildQuizCard(quizzes[i], isMyQuiz: isMyQuiz),
      ),
    );
  }

  // ── Carte ─────────────────────────────────────────────────────────────────
  Widget _buildQuizCard(Map<String, dynamic> quiz,
      {required bool isMyQuiz}) {
    final questionCount =
        (quiz['questions'] as List<dynamic>?)?.length ?? 0;
    final status   = quiz['status'] as String? ?? 'Inconnu';
    final quizType = quiz['quiz_type'] as String? ?? 'Quiz';
    final pinCode  = quiz['pin_code'] as String? ?? '------';
    final isActive = status == 'Actif';
    final borderColor =
        isMyQuiz ? primary : const Color(0xFF1565C0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barre colorée gauche
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre + PIN
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            quiz['title'] as String? ?? 'Sans titre',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'PIN: $pinCode',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quiz avec $questionCount question${questionCount > 1 ? 's' : ''}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 10),
                    // Chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _chip(quizType, Icons.category_outlined),
                        _chip('$questionCount questions',
                            Icons.help_outline_rounded),
                        _chip('${quiz['time_limit'] ?? 20}s',
                            Icons.timer_outlined),
                        _statusChip(status, isActive),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Bouton classement
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/quiz-ranking',
                          arguments: {
                            'quiz': quiz,
                            'isMyQuiz': isMyQuiz,
                          },
                        ),
                        icon: const Icon(Icons.leaderboard_outlined,
                            size: 16),
                        label: const Text('Voir le classement'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primary,
                          side: BorderSide(
                              color: primary.withOpacity(0.25)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          textStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: secondary),
          const SizedBox(width: 5),
          Text(text,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: secondary)),
        ],
      ),
    );
  }

  Widget _statusChip(String status, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? Colors.green.shade600
                  : Colors.orange.shade600,
            ),
          ),
          const SizedBox(width: 5),
          Text(status,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? Colors.green.shade700
                      : Colors.orange.shade700)),
        ],
      ),
    );
  }
}