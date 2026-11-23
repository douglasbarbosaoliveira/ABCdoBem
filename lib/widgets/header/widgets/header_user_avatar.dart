// lib/widgets/header/widgets/header_user_avatar.dart

import 'package:flutter/material.dart';
import '../../../services/session_service.dart';
import '../../avatar/app_avatar.dart';

class HeaderUserAvatar extends StatelessWidget {
  final String nomeExibicao;
  final String fotoExibicao;
  final bool isDesktop;
  final bool isOng;
  final VoidCallback onTap;

  const HeaderUserAvatar({
    super.key,
    required this.nomeExibicao,
    required this.fotoExibicao,
    required this.isDesktop,
    required this.isOng,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: SessionService.instance.fotoUrlNotifier,
      builder: (context, fotoSessao, _) {
        final nome = SessionService.instance.nomeUsuario ?? nomeExibicao;

        // Prioriza a foto da sessão ativa; se estiver vazia, usa a fotoExibicao recebida
        final fotoAtiva = (fotoSessao != null && fotoSessao.trim().isNotEmpty)
            ? fotoSessao.trim()
            : fotoExibicao.trim();

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFC2E4DC)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppAvatar(
                  fotoUrl: fotoAtiva.isNotEmpty ? fotoAtiva : null,
                  nome: nome,
                  raio: 18,
                  tamanhoFonte: 12,
                ),
                if (isDesktop) ...[
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Text(
                      nome,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF062222),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down,
                      size: 16, color: Color(0xFF0C6B6B)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
