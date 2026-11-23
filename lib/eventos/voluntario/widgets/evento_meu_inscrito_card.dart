// lib/eventos/voluntario/widgets/evento_meu_inscrito_card.dart

import 'package:flutter/material.dart';
import '../../models/evento_model.dart';

class EventoMeuInscritoCard extends StatelessWidget {
  final InscricaoEventoModel inscricao;
  final DateTime now;
  final VoidCallback onCancelar;
  final bool isMobile;

  const EventoMeuInscritoCard({
    super.key,
    required this.inscricao,
    required this.now,
    required this.onCancelar,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final ev = inscricao.evento!;
    final diff = ev.dataHoraInicio.difference(now);
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    final String rawStatus = inscricao.status.toUpperCase();
    final bool isPendente = rawStatus == 'PENDING' || rawStatus == 'PENDENTE';
    final bool isAprovado = rawStatus == 'ACCEPTED' ||
        rawStatus == 'APROVADO' ||
        rawStatus == 'CONFIRMED' ||
        rawStatus == 'CONFIRMADO';

    final String statusLabel = isPendente
        ? 'Aguardando Aprovação'
        : isAprovado
            ? 'Confirmado'
            : inscricao.status;

    final Color statusColor = isPendente
        ? const Color(0xFFD46B08)
        : isAprovado
            ? const Color(0xFF0C6B6B)
            : Colors.grey.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPendente ? const Color(0xFFFFD591) : const Color(0xFF9FE8D8),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C6B6B).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPendente
                    ? const [Color(0xFF2A2213), Color(0xFF4A3B1F)]
                    : const [Color(0xFF062222), Color(0xFF0C5252)],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                diff.isNegative
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Em andamento',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: isPendente
                                ? const Color(0xFFFFD591)
                                : const Color(0xFF9FE8D8),
                            size: 15,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Início: ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          _buildUnit('$days', 'd', isPendente),
                          const Text(' : ',
                              style: TextStyle(color: Colors.white)),
                          _buildUnit(hours.toString().padLeft(2, '0'), 'h',
                              isPendente),
                          const Text(' : ',
                              style: TextStyle(color: Colors.white)),
                          _buildUnit(minutes.toString().padLeft(2, '0'), 'm',
                              isPendente),
                        ],
                      ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPendente
                            ? Icons.hourglass_top_rounded
                            : Icons.check_circle_outline_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    ev.imagemUrl,
                    width: isMobile ? 56 : 70,
                    height: isMobile ? 56 : 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: isMobile ? 56 : 70,
                      height: isMobile ? 56 : 70,
                      color: const Color(0xFFC2E4DC),
                      child: const Icon(
                        Icons.volunteer_activism_rounded,
                        color: Color(0xFF0C6B6B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ev.titulo,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 14 : 15,
                          color: const Color(0xFF062222),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '🏢 ${ev.ongNome}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0C6B6B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '📅 ${ev.data} • ${ev.horario} • 📍 ${ev.cidade}',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onCancelar,
                  child: Text(
                    isPendente ? 'Desistir' : 'Cancelar',
                    style: TextStyle(
                      color: isPendente ? Colors.grey : Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnit(String value, String unit, bool isPendente) {
    return Text(
      '$value$unit',
      style: TextStyle(
        color: isPendente ? const Color(0xFFFFD591) : const Color(0xFF9FE8D8),
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
    );
  }
}
