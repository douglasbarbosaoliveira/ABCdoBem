// lib/ongs/perfil/widgets/ong_perfil_feed_section.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../models/ong_detail_models.dart';

class OngPerfilFeedSection extends StatelessWidget {
  final List<OngPostagemModel> publicacoes;
  final String ongNome;
  final String logoUrl;
  final bool isMobile;

  const OngPerfilFeedSection({
    super.key,
    required this.publicacoes,
    required this.ongNome,
    required this.logoUrl,
    required this.isMobile,
  });

  String _resolverUrl(String raw) {
    final String url = raw.trim();
    if (url.isEmpty) return "";
    if (url.startsWith("data:image")) return url;
    if (url.startsWith("http://") || url.startsWith("https://")) return url;
    if (url.startsWith("/")) return "https://abc-do-bem.onrender.com$url";
    return "https://abc-do-bem.onrender.com/$url";
  }

  Widget _buildImagemPost(String rawUrl) {
    final String url = _resolverUrl(rawUrl);
    if (url.isEmpty) return const SizedBox.shrink();

    if (url.startsWith("data:image")) {
      try {
        final Uint8List bytes = base64Decode(url.split(',').last);
        return Image.memory(
          bytes,
          width: double.infinity,
          height: isMobile ? 180 : 260,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        );
      } catch (_) {
        return const SizedBox.shrink();
      }
    }

    return Image.network(
      url,
      width: double.infinity,
      height: isMobile ? 180 : 260,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String logoResolvida = _resolverUrl(logoUrl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Ações e Relatos Recentes",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF062222),
              ),
            ),
            if (publicacoes.isNotEmpty)
              Text(
                "${publicacoes.length} ${publicacoes.length == 1 ? 'publicação' : 'publicações'}",
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7AAAA0),
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (publicacoes.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFC2E4DC)),
            ),
            child: const Center(
              child: Text(
                "Nenhuma publicação cadastrada por enquanto.",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: publicacoes.length,
            itemBuilder: (ctx, idx) {
              final post = publicacoes[idx];
              final bool temImagem =
                  post.imagemUrl != null && post.imagemUrl!.trim().isNotEmpty;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
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
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFFD1F5EE),
                          backgroundImage: logoResolvida.isNotEmpty
                              ? NetworkImage(logoResolvida)
                              : null,
                          child: logoResolvida.isEmpty
                              ? const Icon(
                                  Icons.business_rounded,
                                  size: 16,
                                  color: Color(0xFF0C6B6B),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ongNome,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF062222),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                post.dataFormatada,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (post.titulo.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        post.titulo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF062222),
                        ),
                      ),
                    ],
                    if (post.texto.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        post.texto,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF3A6868),
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (temImagem) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _buildImagemPost(post.imagemUrl!),
                      ),
                    ],
                    if (post.curtidas > 0) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite_rounded,
                            size: 14,
                            color: Color(0xFFE05252),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${post.curtidas} ${post.curtidas == 1 ? 'curtida' : 'curtidas'}",
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF5A8A80),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
