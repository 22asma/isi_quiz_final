import 'package:flutter/material.dart';
import 'package:isi_quiz/features/quiz/presentation/pages/take_quiz_page.dart';
import '../../../../core/theme/app_theme.dart';

class JoinQuizPage extends StatelessWidget {
  const JoinQuizPage({super.key, required this.quiz});

  final Map<String, dynamic> quiz;

  static const Color primaryColor   = Color(0xFF003366);
  static const Color secondaryColor = Color(0xFF4A5F70);
  static const Color tertiaryColor  = Color(0xFF592300);
  static const Color neutralColor   = Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    final title       = quiz['title'] as String? ?? 'Quiz sans titre';
    final description = quiz['description'] as String? ?? 'Aucune description disponible.';
    final pinCode     = quiz['pin_code'] as String? ?? '';
    final quizType    = quiz['quiz_type'] as String? ?? 'Quiz';
    final timeLimit   = quiz['time_limit']?.toString() ?? '0';
    final status      = quiz['status'] as String? ?? 'Inconnu';
    final createdAt   = quiz['created_at'] as String?;
    final createdAtString = createdAt != null ? _formatDate(createdAt) : 'Date inconnue';
    final questions   = quiz['questions'] as List<dynamic>? ?? [];
    final questionCount = questions.length;
    final isPublic    = quiz['is_public'] == true;

    return Scaffold(
      backgroundColor: neutralColor,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────
          Container(
            color: primaryColor,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back row
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

                  // Title block
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 14,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [

                  // ── Stats row ──────────────────────────────────────────
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
                        icon: isPublic ? Icons.public_rounded : Icons.lock_rounded,
                        value: isPublic ? 'Public' : 'Privé',
                        label: 'Accès',
                        color: isPublic ? Colors.green.shade600 : Colors.orange.shade600,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Info Card ──────────────────────────────────────────
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
                        _buildInfoRow(Icons.category_outlined, 'Type', quizType),
                        _buildDivider(),
                        _buildInfoRow(Icons.info_outline_rounded, 'Statut', status),
                        _buildDivider(),
                        _buildInfoRow(Icons.calendar_today_outlined, 'Créé le', createdAtString),
                        _buildDivider(),
                        _buildInfoRow(Icons.quiz_outlined, 'Questions', '$questionCount au total'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Notice box ─────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primaryColor.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline_rounded,
                            color: primaryColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Les questions seront révélées une fois le quiz commencé. Préparez-vous !',
                            style: TextStyle(
                              fontSize: 13,
                              color: primaryColor,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Start Button ───────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TakeQuizPage(quiz: quiz),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow_rounded, size: 24),
                      label: const Text(
                        'Commencer le quiz',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF4A5F70)),
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
                  color: Color(0xFF003366),
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildDivider() =>
      Divider(height: 1, color: Colors.grey.shade100);

  String _formatDate(String rawDate) {
    try {
      final d = DateTime.parse(rawDate);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return 'Date inconnue';
    }
  }
}