import 'package:flutter/material.dart';
import '../../../home/presentation/pages/home_page.dart';

class RoleRouterPage extends StatelessWidget {
  const RoleRouterPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Pour l'instant, nous redirigeons directement vers la page home
    // Plus tard, cette page pourrait vérifier le rôle de l'utilisateur 
    // et rediriger vers différentes pages selon le rôle (étudiant, professeur, admin)
    return const HomePage();
  }
}
