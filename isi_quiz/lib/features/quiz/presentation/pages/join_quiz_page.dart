import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_quiz/features/quiz/presentation/pages/take_quiz_page.dart';
import 'package:isi_quiz/features/quiz/services/quiz_service.dart';
import 'package:isi_quiz/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:isi_quiz/features/auth/presentation/bloc/auth_state.dart';
import '../../../../core/theme/app_theme.dart';

class JoinQuizPage extends StatefulWidget {
  const JoinQuizPage({super.key, required this.quiz});

  final Map<String, dynamic> quiz;

  @override
  State<JoinQuizPage> createState() => _JoinQuizPageState();
}

class _JoinQuizPageState extends State<JoinQuizPage> {
  final QuizService _quizService = QuizService();
  bool _isLoading = false;
  bool _hasJoined = false;
  String _sessionStatus = 'waiting';
  Timer? _pollingTimer;

  static const Color primaryColor = Color(0xFF003366);
  static const Color secondaryColor = Color(0xFF4A5F70);
  static const Color tertiaryColor = Color(0xFF592300);
  static const Color neutralColor = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _sessionStatus =
        widget.quiz['session_status'] as String? ?? 'waiting';

    final isPublic = widget.quiz['is_public'] == true;
    if (!isPublic) {
      _checkIfAlreadyJoined();
      // Polling toutes les 3 secondes pour les quiz de groupe
      _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        _pollSessionStatus();
      });
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkIfAlreadyJoined() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;
    final quizId = widget.quiz['id'] as String;
    final joined =
        await _quizService.isAlreadyJoined(quizId, authState.user.id);
    if (mounted) setState(() => _hasJoined = joined);
  }

  /// Polling pour détecter quand le créateur démarre le quiz
  Future<void> _pollSessionStatus() async {
    if (!mounted) return;
    final quizId = widget.quiz['id'] as String;
    final status = await _quizService.getGroupQuizStatus(quizId);
    if (!mounted) return;

    if (status != _sessionStatus) {
      setState(() => _sessionStatus = status);

      // Si le quiz vient de démarrer et que l'utilisateur avait rejoint → navigate
      if (status == 'started' && _hasJoined) {
        _pollingTimer?.cancel();
        _navigateToQuiz();
      }
    }
  }

  // Recharge le quiz complet (avec questions) avant de naviguer
  // car l'objet widget.quiz du participant peut ne pas avoir les questions
  Future<void> _navigateToQuiz() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final quizId = widget.quiz['id'] as String?;
      final pinCode = widget.quiz['pin_code'] as String?;
      Map<String, dynamic> fullQuiz = widget.quiz;

      // Si les questions sont absentes ou vides, on recharge depuis Supabase
      final questions = widget.quiz['questions'] as List<dynamic>?;
      final needsReload = questions == null || questions.isEmpty;

      if (needsReload) {
        Map<String, dynamic>? reloaded;

        // Essai 1 : par ID (le plus fiable)
        if (quizId != null) {
          reloaded = await _quizService.getQuizById(quizId);
        }
        // Essai 2 : par PIN si l'ID a échoué
        if (reloaded == null && pinCode != null) {
          reloaded = await _quizService.getQuizByPinCode(pinCode);
        }

        if (reloaded != null) {
          fullQuiz = reloaded;
          print('Quiz rechargé avec ${(fullQuiz['questions'] as List?)?.length ?? 0} questions');
        } else {
          print('Impossible de recharger le quiz, utilisation des données locales');
        }
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TakeQuizPage(quiz: fullQuiz),
        ),
      );
    } catch (e) {
      print('Error navigating to quiz: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TakeQuizPage(quiz: widget.quiz),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  Future<void> _startGroupQuiz() async {
    if (_isLoading) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    setState(() => _isLoading = true);
    try {
      final quizId = widget.quiz['id'] as String;
      final success =
          await _quizService.startGroupQuiz(quizId, authState.user.id);

      if (success) {
        setState(() => _sessionStatus = 'started');
        _pollingTimer?.cancel();
        _navigateToQuiz();
      } else {
        _showSnack('Impossible de démarrer le quiz', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinGroupQuiz() async {
    if (_isLoading) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    setState(() => _isLoading = true);
    try {
      final quizId = widget.quiz['id'] as String;
      final result =
          await _quizService.joinGroupQuiz(quizId, authState.user.id);

      switch (result) {
        case GroupJoinResult.waitingForCreator:
          setState(() => _hasJoined = true);
          _showSnack('Vous avez rejoint la salle d\'attente !');
          break;
        case GroupJoinResult.startedCanPlay:
          setState(() => _hasJoined = true);
          _pollingTimer?.cancel();
          _navigateToQuiz();
          break;
        case GroupJoinResult.quizFull:
          _showSnack('Le quiz est complet', isError: true);
          break;
        case GroupJoinResult.quizFinished:
          _showSnack('Ce quiz est terminé', isError: true);
          break;
        default:
          _showSnack('Erreur lors de la participation', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final title = widget.quiz['title'] as String? ?? 'Quiz sans titre';
    final description =
        widget.quiz['description'] as String? ?? 'Aucune description.';
    final pinCode = widget.quiz['pin_code'] as String? ?? '';
    final quizType = widget.quiz['quiz_type'] as String? ?? 'Quiz';
    final timeLimit = widget.quiz['time_limit']?.toString() ?? '0';
    final status = widget.quiz['status'] as String? ?? 'Inconnu';
    final createdAt = widget.quiz['created_at'] as String?;
    final questions = widget.quiz['questions'] as List<dynamic>? ?? [];
    final questionCount = questions.length;
    final isPublic = widget.quiz['is_public'] == true;
    final maxParticipants = widget.quiz['max_participants'] as int?;
    final currentParticipants =
        widget.quiz['current_participants'] as int? ?? 0;

    final authState = context.read<AuthBloc>().state;
    final isCreator = authState is Authenticated &&
        widget.quiz['creator_id'] == authState.user.id;

    return Scaffold(
      backgroundColor: neutralColor,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            color: primaryColor,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
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
                            'PIN: $pinCode',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              height: 1.2,
                            )),
                        const SizedBox(height: 8),
                        Text(description,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 14,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Stats
                  Row(
                    children: [
                      _buildStatCard(
                        icon: Icons.help_outline_rounded,
                        value: '$questionCount',
                        label: 'Questions',
                        color: primaryColor,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        icon: Icons.timer_outlined,
                        value: '${timeLimit}s',
                        label: 'Par question',
                        color: secondaryColor,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        icon: isPublic
                            ? Icons.public_rounded
                            : Icons.group_rounded,
                        value: isPublic ? 'Public' : 'Classe',
                        label: 'Visibilité',
                        color: isPublic
                            ? Colors.green.shade600
                            : Colors.blue.shade600,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Info card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      children: [
                        _buildInfoRow(
                            Icons.category_outlined, 'Type', quizType),
                        _buildDivider(),
                        _buildInfoRow(
                            Icons.info_outline_rounded, 'Statut', status),
                        if (!isPublic) ...[
                          _buildDivider(),
                          _buildInfoRow(
                            Icons.play_circle_outline,
                            'Session',
                            _sessionStatus == 'waiting'
                                ? 'En attente'
                                : _sessionStatus == 'started'
                                    ? 'En cours'
                                    : 'Terminé',
                          ),
                        ],
                        _buildDivider(),
                        _buildInfoRow(
                          Icons.calendar_today_outlined,
                          'Créé le',
                          createdAt != null
                              ? _formatDate(createdAt)
                              : 'Date inconnue',
                        ),
                        _buildDivider(),
                        _buildInfoRow(Icons.quiz_outlined, 'Questions',
                            '$questionCount au total'),
                        if (!isPublic && maxParticipants != null) ...[
                          _buildDivider(),
                          _buildInfoRow(
                            Icons.people_outline,
                            'Participants',
                            '$currentParticipants/$maxParticipants',
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Bannière état pour quiz de groupe ──────────────────
                  if (!isPublic) _buildGroupStatusBanner(isCreator),

                  const SizedBox(height: 32),

                  // ── Boutons d'action ───────────────────────────────────
                  _buildActionButtons(isPublic, isCreator),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupStatusBanner(bool isCreator) {
    if (isCreator) {
      return _buildBanner(
        icon: Icons.admin_panel_settings,
        color: Colors.green,
        message: _sessionStatus == 'waiting'
            ? 'Vous êtes le créateur. Appuyez sur "Démarrer" quand tous les participants sont prêts.'
            : 'Le quiz est en cours.',
      );
    }

    if (_hasJoined && _sessionStatus == 'waiting') {
      return _buildBanner(
        icon: Icons.hourglass_top_rounded,
        color: Colors.orange,
        message: 'Vous avez rejoint la salle d\'attente. En attente du créateur...',
        showLoader: true,
      );
    }

    if (_sessionStatus == 'started') {
      return _buildBanner(
        icon: Icons.play_circle_outline,
        color: Colors.green,
        message: 'Le quiz a commencé ! Vous pouvez maintenant jouer.',
      );
    }

    return _buildBanner(
      icon: Icons.lightbulb_outline_rounded,
      color: primaryColor,
      message: 'Rejoignez la salle d\'attente pour participer quand le créateur démarre le quiz.',
    );
  }

  Widget _buildBanner({
    required IconData icon,
    required Color color,
    required String message,
    bool showLoader = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          showLoader
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: color),
                )
              : Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isPublic, bool isCreator) {
    // ── Quiz public → toujours jouable ────────────────────────────────────
    if (isPublic) {
      return _buildPrimaryButton('Commencer le quiz', _navigateToQuiz);
    }

    // ── Quiz de groupe, vue créateur ──────────────────────────────────────
    if (isCreator) {
      if (_sessionStatus == 'waiting') {
        return _buildPrimaryButton(
          'Démarrer le quiz',
          _isLoading ? null : _startGroupQuiz,
          isLoading: _isLoading,
        );
      }
      if (_sessionStatus == 'started') {
        return _buildPrimaryButton('Voir le quiz en cours', _navigateToQuiz);
      }
      return _buildDisabledButton('Quiz terminé');
    }

    // ── Quiz de groupe, vue participant ───────────────────────────────────
    if (_sessionStatus == 'finished') {
      return _buildDisabledButton('Quiz terminé');
    }

    if (!_hasJoined) {
      return _buildJoinButton();
    }

    // A rejoint + en attente
    if (_sessionStatus == 'waiting') {
      return _buildDisabledButton('En attente du créateur...');
    }

    // A rejoint + démarré
    return _buildPrimaryButton('Jouer maintenant', _navigateToQuiz);
  }

  Widget _buildPrimaryButton(String text, VoidCallback? onPressed,
      {bool isLoading = false}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(text,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _buildJoinButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _joinGroupQuiz,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('Rejoindre la salle d\'attente',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _buildDisabledButton(String text) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade300,
          foregroundColor: Colors.grey.shade500,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(text,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800)),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.3),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: secondaryColor),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  color: primaryColor,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildDivider() => Divider(height: 1, color: Colors.grey.shade100);

  String _formatDate(String rawDate) {
    try {
      final d = DateTime.parse(rawDate);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return 'Date inconnue';
    }
  }
}