import 'package:flutter/material.dart';

// Importe o seu novo arquivo de Tema Global
import 'core/theme/app_theme.dart';

import 'landing_page.dart';
import 'login_page.dart';
import 'register_step1_page.dart';
import 'register_ong_step1_page.dart';

void main() {
  runApp(const MyApp());
}

// 1. O Ponto de Partida
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ABC do Bem',
      debugShowCheckedModeBanner: false,

      // ✨ A MÁGICA ACONTECE AQUI! O app inteiro agora obedece a esta regra:
      theme: AppTheme.lightTheme,

      home: const AppRouter(),
    );
  }
}

// 2. O Roteador Seguro
class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingPage(
      onLogin: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      },
      onRegisterVolunteer: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RegisterStep1Page()),
        );
      },
      onRegisterOng: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RegisterOngStep1Page()),
        );
      },
    );
  }
}
