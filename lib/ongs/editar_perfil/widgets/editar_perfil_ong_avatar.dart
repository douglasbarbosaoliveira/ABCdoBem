// lib/ongs/editar_perfil/widgets/editar_perfil_ong_avatar.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class EditarPerfilOngAvatar extends StatelessWidget {
  final String avatarUrl;
  final VoidCallback onSelecionarAvatar;
  final double size;

  const EditarPerfilOngAvatar({
    super.key,
    required this.avatarUrl,
    required this.onSelecionarAvatar,
    this.size = 96,
  });

  Uint8List? _decodificarBase64(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty ||
        trimmed.startsWith('http://') ||
        trimmed.startsWith('https://')) {
      return null;
    }
    try {
      final base64Puro = trimmed.contains(',')
          ? trimmed.substring(trimmed.indexOf(',') + 1)
          : trimmed;
      var limpo = base64Puro
          .replaceAll(' ', '')
          .replaceAll('\n', '')
          .replaceAll('\r', '')
          .replaceAll('\t', '');
      while (limpo.length % 4 != 0) {
        limpo += '=';
      }
      if (limpo.length < 32) return null;
      return base64Decode(limpo);
    } catch (_) {
      return null;
    }
  }

  Widget _buildAvatarImagem() {
    final src = avatarUrl.trim();
    Widget fallback() {
      return Icon(
        Icons.business_rounded,
        size: size * 0.42,
        color: const Color(0xFF0C6B6B),
      );
    }

    if (src.isEmpty) return fallback();

    if (src.startsWith('http://') || src.startsWith('https://')) {
      return Image.network(
        src,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback(),
      );
    }

    final bytes = _decodificarBase64(src);
    if (bytes != null) {
      return Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback(),
      );
    }

    return fallback();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Tooltip(
        message: "Atualizar logo da instituição",
        child: InkWell(
          onTap: onSelecionarAvatar,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1F5EE),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0C6B6B),
                      width: 2.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF062222).withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: _buildAvatarImagem(),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C6B6B),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.photo_camera_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
