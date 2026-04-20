import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_quiz/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:isi_quiz/features/auth/presentation/bloc/auth_state.dart';
import 'package:isi_quiz/features/home/presentation/pages/home_page.dart';
import 'package:isi_quiz/features/quiz/presentation/pages/quiz_list_page.dart';
import 'package:isi_quiz/features/ranks/presentation/pages/ranks_page.dart';
import 'package:isi_quiz/features/profile/presentation/pages/profile_page.dart';
import '../../../../core/theme/app_theme.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  final ValueNotifier<bool> _quizRefreshNotifier = ValueNotifier<bool>(false);

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomePage(),
      QuizListPage(refreshNotifier: _quizRefreshNotifier),
      const RanksPage(),
      const ProfilePage(),
    ];
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
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
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
                  activeIcon: Icons.home,
                  label: 'Accueil',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.quiz_outlined,
                  activeIcon: Icons.quiz,
                  label: 'Quiz',
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.leaderboard_outlined,
                  activeIcon: Icons.leaderboard,
                  label: 'Classements',
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppTheme.primaryColor : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.primaryColor : Colors.grey[600],
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
