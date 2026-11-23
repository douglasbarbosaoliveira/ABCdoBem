// lib/ongs/perfil/widgets/ong_perfil_eventos_passados_section.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../models/ong_detail_models.dart';

class OngPerfilEventosPassadosSection extends StatelessWidget {
  final List<OngOportunidadeModel> eventosPassados;
  final Function(OngOportunidadeModel) onVerEvento;
  final bool isMobile;

  const OngPerfilEventosPassadosSection({
    super.key,
    required this.eventosPassados,
    required this.onVerEvento,
    required this.isMobile,
  });

  String _resolverUrlImagem(String rawUrl) {
    final String url = rawUrl.trim();
    if (url.isEmpty) return "";
    if (url.startsWith("data:image")) return url;
    if (url.startsWith("http://") || url.startsWith("https://")) {
      return url;
    }
    if (url.startsWith("/")) {
      return "https://abc-do-bem.onrender.com$url";
    }
    return "https://abc-do-bem.onrender.com/$url";
  }

  Widget _buildImagemEvento(String rawUrl, double size) {
    final String url = _resolverUrlImagem(rawUrl);
    if (url.isEmpty) {
      return _imagemFallback(size);
    }

    if (url.startsWith("data:image")) {
      try {
        final String base64Str = url.split(',').last;
        final Uint8List bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _imagemFallback(size),
        );
      } catch (_) {
        return _imagemFallback(size);
      }
    }

    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _imagemFallback(size),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (eventosPassados.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Eventos Passados",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF062222),
              ),
            ),
            Text(
              "${eventosPassados.length} ${eventosPassados.length == 1 ? 'realizado' : 'realizados'}",
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7AAAA0),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: eventosPassados.length,
          itemBuilder: (BuildContext ctx, int idx) {
            final OngOportunidadeModel ev = eventosPassados[idx];
            final double imgSize = isMobile ? 64 : 76;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => onVerEvento(ev),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD9EAE6)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _buildImagemEvento(ev.imagemUrl, imgSize),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ev.titulo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: Color(0xFF062222),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "📅 ${ev.data} • ⏱️ ${ev.horario}",
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF5A8A80),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECEFF1),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Text(
                                  "Evento Passado",
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xFF546E7A),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => onVerEvento(ev),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0C6B6B),
                            side: const BorderSide(color: Color(0xFFC2E4DC)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Detalhes",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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

  Widget _imagemFallback(double size) {
    return Container(
      width: size,
      height: size,
      color: const Color(0xFFECEFF1),
      child: const Icon(
        Icons.history_rounded,
        color: Color(0xFF546E7A),
        size: 26,
      ),
    );
  }
}
