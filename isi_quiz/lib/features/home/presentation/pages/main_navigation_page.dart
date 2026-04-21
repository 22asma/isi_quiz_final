import 'package:flutter/material.dart';
import 'package:isi_quiz/features/home/presentation/pages/home_page.dart';
import 'package:isi_quiz/features/quiz/presentation/pages/quiz_list_page.dart';
import 'package:isi_quiz/features/ranks/presentation/pages/ranks_page.dart';
import 'package:isi_quiz/features/profile/presentation/pages/profile_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  final ValueNotifier<bool> _quizRefreshNotifier = ValueNotifier<bool>(false);

  // GlobalKey pour accéder à l'état de QuizListPage (changer d'onglet)
  final GlobalKey<QuizListPageState> _quizListKey = GlobalKey<QuizListPageState>();

  late final List<Widget> _pages;

  static const Color primaryColor = Color(0xFF003366);

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(
        onNavigate: (index, {int? quizTab}) {
          setState(() => _currentIndex = index);
          // Si on veut ouvrir un onglet spécifique dans QuizListPage
          if (index == 1 && quizTab != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _quizListKey.currentState?.switchTab(quizTab);
            });
          }
        },
      ),
      QuizListPage(
        key: _quizListKey,
        refreshNotifier: _quizRefreshNotifier,
      ),
      const RanksPage(),
      ProfilePage(
        onNavigate: (index, {int? quizTab}) {
          setState(() => _currentIndex = index);
          if (index == 1 && quizTab != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _quizListKey.currentState?.switchTab(quizTab);
            });
          }
        },
      ),
    ];
  }

  @override
  void dispose() {
    _quizRefreshNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Accueil',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.quiz_outlined,
                  activeIcon: Icons.quiz_rounded,
                  label: 'Quiz',
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.leaderboard_outlined,
                  activeIcon: Icons.leaderboard_rounded,
                  label: 'Classements',
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person_rounded,
                  label: 'Profil',
                  index: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        if (index == 1) {
          _quizRefreshNotifier.value = !_quizRefreshNotifier.value;
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? primaryColor : Colors.grey[500],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? primaryColor : Colors.grey[500],
                fontSize: 12,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}