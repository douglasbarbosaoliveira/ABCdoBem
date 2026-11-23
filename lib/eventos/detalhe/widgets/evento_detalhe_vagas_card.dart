// lib/eventos/detalhe/widgets/evento_detalhe_vagas_card.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../services/session_service.dart';
import '../../models/evento_model.dart';

class EventoDetalheVagasCard extends StatefulWidget {
  final EventoModel evento;
  final bool isDono;
  final VoidCallback? onAjustarVagas;

  const EventoDetalheVagasCard({
    super.key,
    required this.evento,
    required this.isDono,
    this.onAjustarVagas,
  });

  @override
  State<EventoDetalheVagasCard> createState() => _EventoDetalheVagasCardState();
}

class _EventoDetalheVagasCardState extends State<EventoDetalheVagasCard> {
  static const String _baseUrl = "https://abc-do-bem.onrender.com";
  int? _totalOcupadasApi;

  @override
  void initState() {
    super.initState();
    _buscarConfirmadosApi();
  }

  @override
  void didUpdateWidget(covariant EventoDetalheVagasCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.evento.id != widget.evento.id ||
        oldWidget.evento.vagasTotais != widget.evento.vagasTotais ||
        oldWidget.evento.vagasRestantes != widget.evento.vagasRestantes ||
        oldWidget.evento.isInscrito != widget.evento.isInscrito) {
      _buscarConfirmadosApi();
    }
  }

  bool _isStatusAtivo(String statusRaw) {
    final s = statusRaw.toUpperCase().trim();
    return s == 'ACCEPTED' ||
        s == 'APPROVED' ||
        s == 'CONFIRMED' ||
        s == 'CONFIRMADA' ||
        s == 'APROVADO' ||
        s == 'PRESENTE' ||
        s == 'ATTENDED' ||
        s == 'PENDING' ||
        s == 'PENDENTE';
  }

  Future<void> _buscarConfirmadosApi() async {
    final token = SessionService.instance.token;
    if (token == null || token.trim().isEmpty || widget.evento.id.isEmpty) {
      return;
    }

    try {
      final url =
          Uri.parse("$_baseUrl/opportunities/${widget.evento.id}/applications");
      final res = await http.get(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer ${token.trim()}",
        },
      ).timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        final List<dynamic> listaRaw = decoded is List
            ? decoded
            : (decoded is Map && decoded['data'] is List
                ? decoded['data'] as List
                : (decoded is Map && decoded['applications'] is List
                    ? decoded['applications'] as List
                    : []));

        int count = 0;
        for (final item in listaRaw) {
          if (item is Map<String, dynamic>) {
            final status = (item['status'] ?? '').toString();
            if (_isStatusAtivo(status)) {
              count++;
            }
          }
        }

        if (mounted) {
          setState(() {
            _totalOcupadasApi = count;
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final int total =
        widget.evento.vagasTotais > 0 ? widget.evento.vagasTotais : 0;

    final int ocupadasModelo =
        (widget.evento.vagasTotais - widget.evento.vagasRestantes)
            .clamp(0, total > 0 ? total : 0);

    int ocupadas = _totalOcupadasApi ?? ocupadasModelo;
    if (ocupadasModelo > ocupadas) {
      ocupadas = ocupadasModelo;
    }
    if (widget.evento.isInscrito &&
        !widget.isDono &&
        ocupadas == 0 &&
        total > 0) {
      ocupadas = 1;
    }

    final int preenchidas = ocupadas.clamp(0, total > 0 ? total : 0);
    final int restantes = (total - preenchidas).clamp(0, total > 0 ? total : 0);

    // Cálculo do progresso protegido contra divisão por zero
    final double progressoCalculado = total > 0 ? (preenchidas / total) : 0.0;
    final double progressoValido =
        (progressoCalculado.isNaN || progressoCalculado.isInfinite)
            ? 0.0
            : progressoCalculado.clamp(0.0, 1.0);

    final int porcentagemExibicao = (progressoValido * 100).round();
    final bool esgotado = total > 0 && restantes <= 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC2E4DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                total == 0
                    ? "Vagas a definir"
                    : "Ocupação das Vagas ($preenchidas de $total)",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF062222),
                ),
              ),
              Text(
                "$porcentagemExibicao%",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF0C6B6B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Barra de progresso protegida
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressoValido,
              minHeight: 8,
              backgroundColor: const Color(0xFFD1F5EE),
              valueColor: AlwaysStoppedAnimation<Color>(
                esgotado ? Colors.redAccent : const Color(0xFF0C6B6B),
              ),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                total == 0
                    ? "Defina a quantidade de vagas para abrir inscrições"
                    : esgotado
                        ? "Todas as vagas preenchidas"
                        : "$restantes vagas restantes disponíveis",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: esgotado ? Colors.redAccent : const Color(0xFF3A6868),
                ),
              ),
              if (widget.isDono)
                TextButton.icon(
                  onPressed: widget.onAjustarVagas,
                  icon: const Icon(Icons.tune_rounded, size: 14),
                  label: const Text(
                    "Ajustar Vagas",
                    style: TextStyle(fontSize: 11),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0C6B6B),
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
