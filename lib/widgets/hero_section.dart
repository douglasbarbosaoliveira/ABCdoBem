import 'package:flutter/material.dart';

class HeroSection extends StatelessWidget {
  final VoidCallback onRegisterVolunteer;
  final VoidCallback onRegisterOng;

  const HeroSection({
    super.key,
    required this.onRegisterVolunteer,
    required this.onRegisterOng,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final List<String> cities = [
      "Santo André",
      "São Bernardo do Campo",
      "São Caetano do Sul",
      "Mauá",
      "Diadema",
      "Ribeirão Pires",
      "Rio Grande da Serra",
    ];

    Widget textContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Conectando\nvoluntários e ONGs",
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "A plataforma que une quem quer ajudar com quem precisa de apoio no Grande ABC. Simples, rápida e gratuita.",
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF9FE8D8),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9FE8D8), Color(0xFF3DCFB0)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                onPressed: onRegisterVolunteer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  "Sou Voluntário — Quero Ajudar",
                  style: TextStyle(
                    color: Color(0xFF062222),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            OutlinedButton(
              onPressed: onRegisterOng,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "Sou uma ONG — Quero Cadastrar",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    Widget citiesWidget = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      children: cities
          .map(
            (c) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Text(
                "📍 $c",
                style: const TextStyle(
                  color: Color(0xFF9FE8D8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
          .toList(),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 120, bottom: 80, left: 20, right: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.4, 0.8, 1.0],
          colors: [
            Color(0xFF062222),
            Color(0xFF0C5252),
            Color(0xFF1A8F8F),
            Color(0xFF3DCFB0),
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isDesktop)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(flex: 3, child: textContent),
                    const SizedBox(width: 40),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Image.asset(
                          'assets/images/logo_abcdobem.png',
                          width: 350,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    textContent,
                    const SizedBox(height: 48),
                    Center(
                      child: Image.asset(
                        'assets/images/logo_abcdobem.png',
                        width: 250,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 48),
              citiesWidget,
            ],
          ),
        ),
      ),
    );
  }
}
