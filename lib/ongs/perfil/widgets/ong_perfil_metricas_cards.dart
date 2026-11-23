// lib/ongs/perfil/widgets/ong_perfil_metricas_cards.dart

import 'package:flutter/material.dart';

class OngPerfilMetricasCards extends StatelessWidget {
  final int voluntariosAtivos;
  final int eventosRealizados;
  final int anosAtuacao;
  final DateTime? criadoEm;

  const OngPerfilMetricasCards({
    super.key,
    required this.voluntariosAtivos,
    required this.eventosRealizados,
    required this.anosAtuacao,
    this.criadoEm,
  });

  String _formatarTempoPlataforma() {
    if (criadoEm != null) {
      final DateTime agora = DateTime.now();
      final DateTime inicio =
          DateTime(criadoEm!.year, criadoEm!.month, criadoEm!.day);
      final DateTime fim = DateTime(agora.year, agora.month, agora.day);

      if (fim.isBefore(inicio)) {
        return "Hoje";
      }

      final int diasTotais = fim.difference(inicio).inDays;
      if (diasTotais < 1) {
        return "Hoje";
      }
      if (diasTotais == 1) {
        return "1 dia";
      }
      if (diasTotais < 30) {
        return "$diasTotais dias";
      }

      int meses = (fim.year - inicio.year) * 12 + (fim.month - inicio.month);
      if (fim.day < inicio.day) {
        meses -= 1;
      }
      if (meses < 1) meses = 1;

      if (meses < 12) {
        return meses == 1 ? "1 mês" : "$meses meses";
      }

      final int anos = meses ~/ 12;
      return anos == 1 ? "1 ano" : "$anos anos";
    }

    return anosAtuacao == 1 ? "1 ano" : "$anosAtuacao anos";
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildMetricaItem("$voluntariosAtivos", "Voluntários"),
        const SizedBox(width: 10),
        _buildMetricaItem("$eventosRealizados", "Ações e Eventos"),
        const SizedBox(width: 10),
        _buildMetricaItem(_formatarTempoPlataforma(), "no ABC do Bem"),
      ],
    );
  }

  Widget _buildMetricaItem(String valor, String rotulo) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFC2E4DC)),
        ),
        child: Column(
          children: [
            Text(
              valor,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF062222),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              rotulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Color(0xFF7AAAA0)),
            ),
          ],
        ),
      ),
    );
  }
}
