import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_quiz/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:isi_quiz/features/auth/presentation/bloc/auth_event.dart';
import 'package:isi_quiz/features/auth/presentation/bloc/auth_state.dart';
import 'package:isi_quiz/features/quiz/services/quiz_service.dart';

class ProfilePage extends StatefulWidget {
  /// Callback pour naviguer vers un onglet de MainNavigationPage.
  /// [index] = index de l'onglet, [quizTab] = sous-onglet de QuizListPage (optionnel).
  final void Function(int index, {int? quizTab})? onNavigate;

  const ProfilePage({super.key, this.onNavigate});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final QuizService _quizService = QuizService();
  int _createdQuizzesCount = 0;
  int _participatedQuizzesCount = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      try {
        final createdCount = await _quizService.getUserCreatedQuizzesCount(authState.user.id);
        final participatedCount = await _quizService.getUserParticipatedQuizzesCount(authState.user.id);
        
        if (mounted) {
          setState(() {
            _createdQuizzesCount = createdCount;
            _participatedQuizzesCount = participatedCount;
            _isLoadingStats = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoadingStats = false);
        }
      }
    }
  }

  // ── Palette commune ────────────────────────────────────────────────────────
  static const Color primaryColor   = Color(0xFF003366);
  static const Color secondaryColor = Color(0xFF4A5F70);
  static const Color tertiaryColor  = Color(0xFF592300);
  static const Color neutralColor   = Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: neutralColor,
      body: BlocBuilder<AuthBloc, AuthStatus>(
        builder: (context, state) {
          if (state is Authenticated) {
            return _buildProfileContent(context, state.user);
          } else {
            return _buildNotAuthenticated(context);
          }
        },
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, dynamic user) {
    return Column(
      children: [
        // ── Header foncé ─────────────────────────────────────────────────
        Container(
          color: primaryColor,
          child: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                // Cercles décoratifs
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Barre titre + bouton déconnexion
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ISI Quiz',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showLogoutDialog(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.2)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.logout_rounded,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Déconnexion',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Avatar + infos
                      Row(
                        children: [
                          Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.15),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2),
                            ),
                            child: Center(
                              child: Text(
                                user.fullName?.isNotEmpty == true
                                    ? user.fullName[0].toUpperCase()
                                    : user.email[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.fullName ?? 'Utilisateur',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  user.email ?? '',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.65),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: tertiaryColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    user.role ?? 'Student',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Corps ──────────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                          'Quiz Créés', 
                          _isLoadingStats ? '...' : '$_createdQuizzesCount',
                          Icons.quiz_outlined, primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                          'Quiz Participés', 
                          _isLoadingStats ? '...' : '$_participatedQuizzesCount',
                          Icons.play_arrow_outlined, secondaryColor),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _buildSectionLabel('MENU'),
                const SizedBox(height: 12),

                // Menu items
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.07),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // ── "Mes Quiz" → change l'onglet via onNavigate ──────
                      _buildMenuItem(
                        context,
                        'Mes Quiz',
                        'Voir et gérer vos quiz créés',
                        Icons.quiz_outlined,
                        () => widget.onNavigate?.call(1, quizTab: 0),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        context,
                        'Historique',
                        'Voir votre historique de participation',
                        Icons.history_outlined,
                        () => _showComingSoon(context),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        context,
                        'Paramètres',
                        'Personnaliser votre expérience',
                        Icons.settings_outlined,
                        () => _showComingSoon(context),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        context,
                        'Aide',
                        'Obtenir de l\'aide et du support',
                        Icons.help_outline,
                        () => _showComingSoon(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Widgets helpers ────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    return Row(
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
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: primaryColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: secondaryColor, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
        height: 1,
        color: Colors.grey.shade100,
        indent: 18,
        endIndent: 18);
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Fonctionnalité bientôt disponible'),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildNotAuthenticated(BuildContext context) {
    return Column(
      children: [
        Container(
          color: primaryColor,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: const Text(
                'ISI Quiz',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.07),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.account_circle_outlined,
                        size: 44,
                        color: primaryColor.withOpacity(0.3)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Non connecté',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Veuillez vous connecter pour voir votre profil',
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                          context, '/sign-in'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Se connecter',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Déconnexion',
          style: TextStyle(
              color: primaryColor, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler',
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(SignOutEvent());
              Navigator.pushReplacementNamed(context, '/sign-in');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Déconnexion',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}