// lib/ongs/gestao_eventos/widgets/banner_criar_evento.dart

import 'package:flutter/material.dart';

class BannerCriarEvento extends StatelessWidget {
  final VoidCallback onCriarEvento;

  const BannerCriarEvento({
    super.key,
    required this.onCriarEvento,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C6B6B), Color(0xFF095252)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C6B6B).withAlpha(45),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Mobilize Voluntários no ABC",
            style: TextStyle(
              fontFamily: 'Quicksand',
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Publique uma nova ação comunitária, defina o número de vagas e selecione as habilidades necessárias para conectar voluntários à sua causa.",
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withAlpha(230),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCriarEvento,
              icon: const Icon(
                Icons.add_rounded,
                color: Color(0xFF0C6B6B),
                size: 20,
              ),
              label: const Text(
                "Criar Nova Ação",
                style: TextStyle(
                  color: Color(0xFF0C6B6B),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0C6B6B),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
