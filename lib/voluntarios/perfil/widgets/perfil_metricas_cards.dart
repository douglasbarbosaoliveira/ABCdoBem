// lib/voluntarios/perfil/widgets/perfil_metricas_cards.dart

import 'package:flutter/material.dart';

class PerfilMetricasCards extends StatelessWidget {
  final int totalEventos;
  final int totalHoras;
  final String? tempoAtivo;
  final int
      estrelas; // Nível de reputação/engajamento em causas (padrão: 3 de 5)

  const PerfilMetricasCards({
    super.key,
    required this.totalEventos,
    required this.totalHoras,
    this.tempoAtivo,
    this.estrelas = 3,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMetricaItem(
            valor: "$totalEventos",
            rotulo: "Ações",
            corPrincipal: const Color(0xFF0C6B6B),
            corBorda: const Color(0xFFB3E3D8),
          ),
          const SizedBox(width: 10),
          _buildMetricaItem(
            valor: "${totalHoras}h",
            rotulo: "Doadas",
            corPrincipal: const Color(0xFF0B6E99),
            corBorda: const Color(0xFFB8DCF2),
          ),
          const SizedBox(width: 10),
          _buildEstrelasItem(estrelas, "Engajamento"),
        ],
      ),
    );
  }

  Widget _buildMetricaItem({
    required String valor,
    required String rotulo,
    required Color corPrincipal,
    required Color corBorda,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: corBorda),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A062222),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 24,
              child: Center(
                child: Text(
                  valor,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: corPrincipal,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              rotulo,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5A8A80),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstrelasItem(int qtdEstrelas, String rotulo) {
    final int estrelasValidas = qtdEstrelas.clamp(0, 5);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF5DF9E)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A062222),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 24,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final bool preenchida = index < estrelasValidas;
                      return Icon(
                        preenchida
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 16,
                        color: preenchida
                            ? const Color(0xFFFFB800)
                            : const Color(0xFFE6DEC8),
                      );
                    }),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              rotulo,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5A8A80),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
