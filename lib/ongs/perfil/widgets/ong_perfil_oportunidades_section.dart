// lib/ongs/perfil/widgets/ong_perfil_oportunidades_section.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../models/ong_detail_models.dart';

class OngPerfilOportunidadesSection extends StatelessWidget {
  final List<OngOportunidadeModel> oportunidades;
  final Function(OngOportunidadeModel) onVerEvento;
  final bool isMobile;

  const OngPerfilOportunidadesSection({
    super.key,
    required this.oportunidades,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Oportunidades e Eventos Abertos",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF062222),
              ),
            ),
            Text(
              "${oportunidades.length} ${oportunidades.length == 1 ? 'ativa' : 'ativas'}",
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7AAAA0),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (oportunidades.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFC2E4DC)),
            ),
            child: const Center(
              child: Text(
                "Nenhum evento com vagas abertas no momento. Fique atento a novas publicações!",
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: oportunidades.length,
            itemBuilder: (BuildContext ctx, int idx) {
              final OngOportunidadeModel op = oportunidades[idx];
              final double imgSize = isMobile ? 66 : 80;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => onVerEvento(op),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFC2E4DC)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _buildImagemEvento(op.imagemUrl, imgSize),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  op.titulo,
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
                                  "📅 ${op.data} • ⏱️ ${op.horario}",
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF5A8A80),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${op.vagasRestantes} ${op.vagasRestantes == 1 ? 'vaga restante' : 'vagas restantes'}",
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF0C6B6B),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (op.isInscrito)
                            OutlinedButton.icon(
                              onPressed: () => onVerEvento(op),
                              icon: const Icon(
                                Icons.check_circle_rounded,
                                size: 15,
                                color: Color(0xFF0C6B6B),
                              ),
                              label: const Text(
                                "Inscrito",
                                style: TextStyle(
                                  color: Color(0xFF0C6B6B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFFD1F5EE),
                                side:
                                    const BorderSide(color: Color(0xFF0C6B6B)),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            )
                          else
                            ElevatedButton(
                              onPressed: () => onVerEvento(op),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0C6B6B),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                "Ver",
                                style: TextStyle(
                                  color: Colors.white,
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
      color: const Color(0xFFD1F5EE),
      child: const Icon(
        Icons.volunteer_activism_rounded,
        color: Color(0xFF0C6B6B),
        size: 28,
      ),
    );
  }
}
