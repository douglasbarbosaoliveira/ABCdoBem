import 'dart:ui';

import 'package:flutter/material.dart';

import '../utils/responsive.dart';

class CustomNavBar extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onOpenAccessibility;

  const CustomNavBar({
    super.key,
    required this.onLogin,
    required this.onOpenAccessibility,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 10,
          sigmaY: 10,
        ),
        child: Container(
          height: isMobile ? 64 : 70,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 14 : 20,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            border: const Border(
              bottom: BorderSide(
                color: Color(0xFFC2E4DC),
              ),
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1100,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo ABC do Bem.
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Image.asset(
                        'assets/images/abcdobem_texto.png',
                        height: isMobile ? 16 : 24,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.eco_rounded,
                            size: isMobile ? 18 : 26,
                            color: const Color(0xFF0C6B6B),
                          );
                        },
                      ),
                    ),
                  ),

                  // Ações do header.
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: onLogin,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF0C6B6B),
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 8 : 16,
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text('Entrar'),
                      ),

                      const SizedBox(width: 8),

                      // Botão de acessibilidade.
                      Tooltip(
                        message: 'Acessibilidade',
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: Material(
                            color: const Color(0xFF0C6B6B),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: onOpenAccessibility,
                              child: const Center(
                                child: Icon(
                                  Icons.accessibility_new_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
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
