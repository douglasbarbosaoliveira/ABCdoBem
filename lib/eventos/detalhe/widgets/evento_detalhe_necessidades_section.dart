// lib/eventos/detalhe/widgets/evento_detalhe_necessidades_section.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../services/session_service.dart';
import '../../models/evento_model.dart';

class EventoDetalheNecessidadesSection extends StatefulWidget {
  final EventoModel evento;
  final bool isDono;
  final VoidCallback? onEditarItens;

  const EventoDetalheNecessidadesSection({
    super.key,
    required this.evento,
    required this.isDono,
    this.onEditarItens,
  });

  @override
  State<EventoDetalheNecessidadesSection> createState() =>
      _EventoDetalheNecessidadesSectionState();
}

class _EventoDetalheNecessidadesSectionState
    extends State<EventoDetalheNecessidadesSection> {
  static const String _baseUrl = "https://abc-do-bem.onrender.com";

  late List<String> _requisitos;
  late List<String> _necessidades;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _requisitos = List<String>.from(widget.evento.requisitos);
    _necessidades = List<String>.from(widget.evento.necessidades);
    _sincronizarComApi();
  }

  @override
  void didUpdateWidget(covariant EventoDetalheNecessidadesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.evento.id != widget.evento.id ||
        oldWidget.evento.requisitos != widget.evento.requisitos ||
        oldWidget.evento.necessidades != widget.evento.necessidades) {
      _requisitos = List<String>.from(widget.evento.requisitos);
      _necessidades = List<String>.from(widget.evento.necessidades);
      _sincronizarComApi();
    }
  }

  List<String> _extrairListaStrings(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  Future<void> _sincronizarComApi() async {
    if (widget.evento.id.isEmpty) return;

    if (mounted) setState(() => _carregando = true);

    try {
      final token = SessionService.instance.token;
      final url = Uri.parse("$_baseUrl/opportunities/${widget.evento.id}");
      final res = await http.get(
        url,
        headers: <String, String>{
          "Accept": "application/json",
          if (token != null && token.trim().isNotEmpty)
            "Authorization": "Bearer ${token.trim()}",
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          final reqApi = _extrairListaStrings(decoded['requirements']);
          final skillsApi = _extrairListaStrings(decoded['requiredSkills']);
          final minAge = int.tryParse((decoded['minAge'] ?? '').toString());

          final List<String> requisitosFinal = <String>[
            if (minAge != null && minAge > 0) "Idade mínima: $minAge anos",
            ...reqApi,
          ];

          final List<String> necessidadesFinal = <String>[
            ...skillsApi,
            if (skillsApi.isEmpty && widget.evento.necessidades.isNotEmpty)
              ...widget.evento.necessidades,
          ];

          if (mounted) {
            setState(() {
              if (requisitosFinal.isNotEmpty || reqApi.isEmpty) {
                _requisitos = requisitosFinal.isNotEmpty
                    ? requisitosFinal
                    : List<String>.from(widget.evento.requisitos);
              }
              if (necessidadesFinal.isNotEmpty) {
                _necessidades = necessidadesFinal;
              }
              _carregando = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint("Erro ao carregar requisitos/necessidades da API: $e");
    }

    if (mounted) setState(() => _carregando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC2E4DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Requisitos & Necessidades",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF062222),
                ),
              ),
              if (_carregando)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF0C6B6B),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Requisitos para participar:",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0C6B6B),
            ),
          ),
          const SizedBox(height: 4),
          if (_requisitos.isEmpty)
            const Text(
              "• Aberto a qualquer voluntário disposto a ajudar.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            )
          else
            ..._requisitos
                .map((req) => _buildCheckItem(req, Icons.check_circle_outline)),
          const Divider(height: 20, color: Color(0xFFE2F4F0)),
          const Text(
            "Habilidades / Necessidades do dia:",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0C6B6B),
            ),
          ),
          const SizedBox(height: 4),
          if (_necessidades.isEmpty)
            const Text(
              "• A instituição fornecerá todo o material necessário.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            )
          else
            ..._necessidades
                .map((nec) => _buildCheckItem(nec, Icons.inventory_2_outlined)),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String texto, IconData icone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 15, color: const Color(0xFF0C6B6B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 12, color: Color(0xFF333333)),
            ),
          ),
        ],
      ),
    );
  }
}
