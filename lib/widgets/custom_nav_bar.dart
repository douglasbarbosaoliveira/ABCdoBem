import 'dart:ui';

import 'package:flutter/material.dart';

class CustomNavBar extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegisterVolunteer;

  const CustomNavBar({
    super.key,
    required this.onLogin,
    required this.onRegisterVolunteer,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            border: const Border(bottom: BorderSide(color: Color(0xFFC2E4DC))),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/logo_abcdobem.png',
                        width: 36,
                        height: 36,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "ABC do Bem",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF062222),
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: onLogin,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF0C6B6B),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text("Entrar"),
                      ),
                      const SizedBox(width: 8),
                      if (isDesktop)
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0C6B6B), Color(0xFF29B0A0)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: onRegisterVolunteer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: const Text("Cadastrar-se"),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
