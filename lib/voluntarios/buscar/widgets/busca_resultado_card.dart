// lib/voluntarios/buscar/widgets/busca_resultado_card.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/resultado_busca_model.dart';

class BuscaResultadoCard extends StatelessWidget {
  final ResultadoBuscaItem item;
  final VoidCallback onTap;

  const BuscaResultadoCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  String _obterIniciais(String nome) {
    final partes = nome
        .trim()
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList();
    if (partes.isEmpty) return 'AB';
    if (partes.length == 1) {
      return partes.first
          .substring(0, partes.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return (partes.first[0] + partes[1][0]).toUpperCase();
  }

  Widget _buildAvatarFallback(Color bgColor, Color textColor) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          _obterIniciais(item.tituloPrincipal),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ),
    );
  }

  Widget _buildFotoPerfil(Color fallbackBg, Color fallbackText) {
    final String url = item.imagemUrl.trim();
    if (url.isEmpty) {
      return _buildAvatarFallback(fallbackBg, fallbackText);
    }

    if (url.startsWith('data:image')) {
      try {
        final Uint8List bytes = base64Decode(url.split(',').last);
        return Image.memory(
          bytes,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _buildAvatarFallback(fallbackBg, fallbackText),
        );
      } catch (_) {
        return _buildAvatarFallback(fallbackBg, fallbackText);
      }
    }

    return Image.network(
      url,
      width: 56,
      height: 56,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          _buildAvatarFallback(fallbackBg, fallbackText),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color tipoBgColor;
    Color tipoTextColor;
    IconData tipoIcon;

    switch (item.tipo) {
      case TipoResultadoBusca.ong:
        tipoBgColor = const Color(0xFF0C6B6B);
        tipoTextColor = Colors.white;
        tipoIcon = Icons.domain_rounded;
        break;
      case TipoResultadoBusca.evento:
        tipoBgColor = const Color(0xFFD46B08);
        tipoTextColor = Colors.white;
        tipoIcon = Icons.event_rounded;
        break;
      case TipoResultadoBusca.voluntario:
        tipoBgColor = const Color(0xFF1A528F);
        tipoTextColor = Colors.white;
        tipoIcon = Icons.person_rounded;
        break;
    }

    final Color fallbackBg = item.tipo == TipoResultadoBusca.ong
        ? const Color(0xFFD1F5EE)
        : (item.tipo == TipoResultadoBusca.evento
            ? const Color(0xFFFFF7E6)
            : const Color(0xFFE3EDF5));

    final Color fallbackText = item.tipo == TipoResultadoBusca.ong
        ? const Color(0xFF0C6B6B)
        : (item.tipo == TipoResultadoBusca.evento
            ? const Color(0xFFD46B08)
            : const Color(0xFF1A528F));

    final bool temSegundaCarac = item.segundaCaracteristica.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC2E4DC)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildFotoPerfil(fallbackBg, fallbackText),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // LINHA 1: Nome em negrito
                    Text(
                      item.tituloPrincipal,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF062222),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),

                    // LINHA 2: Tipo à esquerda + 1ª Característica colada na borda direita
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tipoBgColor,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(tipoIcon, size: 10, color: tipoTextColor),
                              const SizedBox(width: 3),
                              Text(
                                item.tipoLabel,
                                style: TextStyle(
                                  color: tipoTextColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.tagOuCategoria,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Color(0xFF0C6B6B),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // LINHA 3: Cidade expandida à esquerda + 2ª Característica/Eventos colada na borda direita
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: Color(0xFF7AAAA0),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            item.cidade,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF5A8A80),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (temSegundaCarac) ...[
                          const SizedBox(width: 8),
                          Text(
                            item.segundaCaracteristica,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF5A8A80),
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
