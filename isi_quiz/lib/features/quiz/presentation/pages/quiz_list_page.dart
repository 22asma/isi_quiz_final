import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_quiz/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:isi_quiz/features/auth/presentation/bloc/auth_state.dart';
import 'package:isi_quiz/features/quiz/services/quiz_service.dart';
import '../../../../core/constants/app_constants.dart';

class QuizListPage extends StatefulWidget {
  const QuizListPage({
    super.key,
    this.refreshNotifier,
    this.initialTabIndex = 0,
  });

  final ValueNotifier<bool>? refreshNotifier;
  final int initialTabIndex;

  @override
  State<QuizListPage> createState() => QuizListPageState();
}

class QuizListPageState extends State<QuizListPage>
    with SingleTickerProviderStateMixin {
  late final ValueNotifier<bool> _refreshNotifier;
  late final bool _ownsRefreshNotifier;
  late TabController _tabController;
  final QuizService _quizService = QuizService();
  List<Map<String, dynamic>> _myQuizzes = [];
  List<Map<String, dynamic>> _publicQuizzes = [];
  bool _isLoading = true;

  static const Color primaryColor   = Color(0xFF003366);
  static const Color secondaryColor = Color(0xFF4A5F70);
  static const Color tertiaryColor  = Color(0xFF592300);
  static const Color neutralColor   = Color(0xFFF5F5F5);

  void switchTab(int index) {
    if (_tabController.index != index) {
      _tabController.animateTo(index);
    }
  }

  Future<void> refresh() async => _loadQuizzes();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _refreshNotifier =
        widget.refreshNotifier ?? ValueNotifier<bool>(false);
    _ownsRefreshNotifier = widget.refreshNotifier == null;
    _loadQuizzes();
    _refreshNotifier.addListener(_onRefreshRequested);
  }

  void _onRefreshRequested() => _loadQuizzes();

  @override
  void dispose() {
    _refreshNotifier.removeListener(_onRefreshRequested);
    if (_ownsRefreshNotifier) _refreshNotifier.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadQuizzes() async {
    setState(() => _isLoading = true);
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        final myQuizzes =
            await _quizService.getUserQuizzes(authState.user.id);
        final publicQuizzes = await _quizService.getPublicQuizzes();
        setState(() {
          _myQuizzes = myQuizzes;
          _publicQuizzes = publicQuizzes;
          _isLoading = false;
        });
      } else {
        setState(() {
          _myQuizzes = [];
          _publicQuizzes = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: neutralColor,
      body: Column(
        children: [
          // Header
          Container(
            color: primaryColor,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ISI Quiz',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final result = await Navigator.pushNamed(
                                context, '/create-quiz');
                            if (result == true) _loadQuizzes();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: tertiaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.add_rounded,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Créer',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    indicatorColor: tertiaryColor,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                    unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 14),
                    tabs: const [
                      Tab(text: 'Mes Quiz'),
                      Tab(text: 'Quiz Publics'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMyQuizzesTab(),
                _buildPublicQuizzesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyQuizzesTab() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: primaryColor));
    }
    if (_myQuizzes.isEmpty) {
      return _buildEmptyState(
        'Aucun quiz créé',
        'Appuyez sur "Créer" pour ajouter votre premier quiz',
        Icons.quiz_outlined,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      itemCount: _myQuizzes.length,
      itemBuilder: (context, index) =>
          _buildQuizCard(_myQuizzes[index], isMyQuiz: true),
    );
  }

  Widget _buildPublicQuizzesTab() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: primaryColor));
    }
    if (_publicQuizzes.isEmpty) {
      return _buildEmptyState(
        'Aucun quiz public',
        'Les quiz publics apparaîtront ici',
        Icons.public_outlined,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      itemCount: _publicQuizzes.length,
      itemBuilder: (context, index) =>
          _buildQuizCard(_publicQuizzes[index], isMyQuiz: false),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
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
            child: Icon(icon, size: 44, color: primaryColor.withOpacity(0.3)),
          ),
          const SizedBox(height: 20),
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: primaryColor),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(subtitle,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> quiz,
      {required bool isMyQuiz}) {
    final pinCode = quiz['pin_code'] as String?;
    final questionCount = quiz['questions'] != null
        ? (quiz['questions'] as List).length
        : 0;
    final isPublic = quiz['is_public'] == true;
    final maxParticipants = quiz['max_participants'] as int?;
    final currentParticipants = quiz['current_participants'] as int? ?? 0;
    final sessionStatus = quiz['session_status'] as String? ?? 'waiting';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre + PIN
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4, height: 48,
                  decoration: BoxDecoration(
                    color: isMyQuiz ? primaryColor : secondaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz['title'] as String? ?? 'Sans titre',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        quiz['description'] as String? ?? 'Pas de description',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (pinCode != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'PIN: $pinCode',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 12),

            // ✅ CORRIGÉ : Wrap pour les chips → plus d'overflow
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildInfoChip(
                    quiz['quiz_type'] as String? ?? 'Quiz',
                    Icons.category_outlined),
                _buildInfoChip(
                    '$questionCount questions', Icons.help_outline),
                _buildInfoChip(
                  '${quiz['time_limit']?.toString() ?? '20'}s',
                  Icons.timer_outlined,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ✅ CORRIGÉ : Statut sur sa propre ligne → plus d'overflow
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPublic
                        ? Colors.green.shade50
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isPublic
                          ? Colors.green.shade200
                          : Colors.blue.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPublic
                            ? Icons.public_rounded
                            : Icons.group_rounded,
                        size: 12,
                        color: isPublic
                            ? Colors.green.shade600
                            : Colors.blue.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPublic ? 'Public' : 'Classe',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isPublic
                              ? Colors.green.shade600
                              : Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isPublic && maxParticipants != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      '$currentParticipants/$maxParticipants',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
                if (sessionStatus != 'waiting') ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: sessionStatus == 'started'
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: sessionStatus == 'started'
                            ? Colors.green.shade200
                            : Colors.orange.shade200,
                      ),
                    ),
                    child: Text(
                      sessionStatus == 'started' ? 'En cours' : 'Terminé',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: sessionStatus == 'started'
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Boutons
            if (isMyQuiz) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/edit-quiz',
                          arguments: quiz,
                        ).then((_) => _loadQuizzes());
                      },
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Modifier',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: BorderSide(
                            color: Colors.blue.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showDeleteDialog(quiz),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Supprimer',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(
                            color: Colors.red.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
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
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: secondaryColor)),
        ],
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> quiz) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer le quiz'),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer le quiz "${quiz['title']}" ?\n\nCette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final success =
                    await _quizService.deleteQuiz(quiz['id']);
                if (success) {
                  _showSnack('Quiz supprimé avec succès');
                  _loadQuizzes();
                } else {
                  _showSnack('Erreur lors de la suppression du quiz',
                      isError: true);
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}