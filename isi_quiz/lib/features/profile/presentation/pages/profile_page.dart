import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_quiz/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:isi_quiz/features/auth/presentation/bloc/auth_event.dart';
import 'package:isi_quiz/features/auth/presentation/bloc/auth_state.dart';
import '../../../../core/theme/app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profil',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showLogoutDialog(context);
            },
            icon: const Icon(
              Icons.logout,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    user.fullName?.isNotEmpty == true 
                        ? user.fullName[0].toUpperCase()
                        : user.email[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName ?? 'Utilisateur',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.role ?? 'Student',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Quiz Créés',
                  '0',
                  Icons.quiz_outlined,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Quiz Participés',
                  '0',
                  Icons.play_arrow_outlined,
                  Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Menu Items
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  'Mes Quiz',
                  'Voir et gérer vos quiz créés',
                  Icons.quiz_outlined,
                  () {
                    Navigator.pushNamed(context, '/quiz');
                  },
                ),
                _buildDivider(),
                _buildMenuItem(
                  'Historique',
                  'Voir votre historique de participation',
                  Icons.history_outlined,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fonctionnalité bientôt disponible')),
                    );
                  },
                ),
                _buildDivider(),
                _buildMenuItem(
                  'Paramètres',
                  'Personnaliser votre expérience',
                  Icons.settings_outlined,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fonctionnalité bientôt disponible')),
                    );
                  },
                ),
                _buildDivider(),
                _buildMenuItem(
                  'Aide',
                  'Obtenir de l\'aide et du support',
                  Icons.help_outline,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fonctionnalité bientôt disponible')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      subtitleTextStyle: TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.grey[200],
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildNotAuthenticated(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_circle_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Non connecté',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Veuillez vous connecter pour voir votre profil',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/sign-in');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(SignOutEvent());
              Navigator.pushReplacementNamed(context, '/sign-in');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}
