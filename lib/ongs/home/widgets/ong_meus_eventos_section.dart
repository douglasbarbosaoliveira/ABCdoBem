// lib/ongs/home/widgets/ong_meus_eventos_section.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class OngMeusEventosSection extends StatelessWidget {
  final List eventos;
  final Function(String) onEditarEvento;
  final VoidCallback onGerenciarTodos;
  final bool isMobile;

  const OngMeusEventosSection({
    super.key,
    required this.eventos,
    required this.onEditarEvento,
    required this.onGerenciarTodos,
    required this.isMobile,
  });

  String _extrairCapaPrincipal(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('[')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded.first.toString().trim();
        }
      } catch (_) {}
    }
    return trimmed;
  }

  Uint8List? _decodificarBase64(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty ||
        trimmed.toLowerCase().startsWith('http://') ||
        trimmed.toLowerCase().startsWith('https://')) {
      return null;
    }
    try {
      final base64Puro = trimmed.contains(',')
          ? trimmed.substring(trimmed.indexOf(',') + 1)
          : trimmed;
      var limpo = base64Puro.replaceAll(RegExp(r'\s+'), '');
      while (limpo.length % 4 != 0) {
        limpo += '=';
      }
      if (limpo.length < 32) return null;
      return base64Decode(limpo);
    } catch (_) {
      return null;
    }
  }

  Widget _buildCapaEvento(String rawUrl, double size) {
    final url = _extrairCapaPrincipal(rawUrl);
    final placeholder = Container(
      width: size,
      height: size,
      color: const Color(0xFFE3F5F1),
      child: const Icon(
        Icons.event_rounded,
        color: Color(0xFF0C6B6B),
      ),
    );

    if (url.isEmpty) return placeholder;

    if (url.toLowerCase().startsWith('http://') ||
        url.toLowerCase().startsWith('https://')) {
      return Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }

    final bytes = _decodificarBase64(url);
    if (bytes != null) {
      return Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }

    return placeholder;
  }

  (String, Color, Color) _badgeStatus(String statusRaw) {
    switch (statusRaw.trim().toLowerCase()) {
      case 'lotado':
        return ('Lotado', const Color(0xFFFFF3E0), const Color(0xFFE65100));
      case 'concluido':
      case 'concluída':
      case 'concluida':
        return ('Concluído', const Color(0xFFECEFF1), const Color(0xFF455A64));
      case 'cancelado':
      case 'cancelada':
        return ('Cancelado', const Color(0xFFFFEBEE), const Color(0xFFC62828));
      default:
        return ('Ativo', const Color(0xFFE3F5F1), const Color(0xFF0C6B6B));
    }
  }

  @override
  Widget build(BuildContext context) {
    final double imgSize = isMobile ? 65 : 85;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Meus Eventos Cadastrados",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF062222),
              ),
            ),
            TextButton(
              onPressed: onGerenciarTodos,
              child: const Text(
                "Gerenciar todos",
                style: TextStyle(
                  color: Color(0xFF0C6B6B),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (eventos.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC2E4DC)),
            ),
            child: const Center(
              child: Text(
                "Nenhum evento ativo cadastrado no momento.",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: eventos.length,
            itemBuilder: (context, index) {
              final ev = eventos[index];
              final String eventoId = (ev.id ?? '').toString();
              final int inscritos = ev.inscritosCount ?? 0;
              final int vagas = ev.vagasTotais > 0 ? ev.vagasTotais : 1;
              final pct = (inscritos / vagas).clamp(0.0, 1.0);
              final (labelStatus, bgStatus, corStatus) =
                  _badgeStatus((ev.status ?? 'ativo').toString());

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: eventoId.isEmpty
                        ? null
                        : () => onEditarEvento(eventoId),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFC2E4DC)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _buildCapaEvento(
                              (ev.imagemUrl ?? '').toString(),
                              imgSize,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        (ev.titulo ?? '').toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Color(0xFF062222),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: bgStatus,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        labelStatus,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: corStatus,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  "📅 ${ev.dataFormatada ?? ''} • ${ev.horario ?? ''}",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: pct,
                                          backgroundColor:
                                              const Color(0xFFE3F5F1),
                                          color: const Color(0xFF0C6B6B),
                                          minHeight: 6,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "$inscritos/${ev.vagasTotais} vagas",
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0C6B6B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: eventoId.isEmpty
                                ? null
                                : () => onEditarEvento(eventoId),
                            icon: const Icon(
                              Icons.edit_note_rounded,
                              color: Color(0xFF0C6B6B),
                              size: 24,
                            ),
                            tooltip: "Gerenciar e editar evento",
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
