// lib/register/ong/widgets/secao_identidade_visual_ong.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';

class SecaoIdentidadeVisualOng extends StatelessWidget {
  final Uint8List? logoBytes;
  final String? nomeArquivo;
  final VoidCallback onSelecionarLogo;
  final VoidCallback onRemoverLogo;

  const SecaoIdentidadeVisualOng({
    super.key,
    required this.logoBytes,
    required this.nomeArquivo,
    required this.onSelecionarLogo,
    required this.onRemoverLogo,
  });

  @override
  Widget build(BuildContext context) {
    final bool temLogo = logoBytes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              "Identidade Visual",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF062222),
              ),
            ),
            SizedBox(width: 4),
            Text(
              "(opcional)",
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onSelecionarLogo,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            height: temLogo ? 120 : 100,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: temLogo ? const Color(0xFFE3F5F1) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    temLogo ? const Color(0xFF0C6B6B) : const Color(0xFFC2E4DC),
                width: 1.5,
              ),
            ),
            child: temLogo
                ? Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          logoBytes!,
                          width: 84,
                          height: 84,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF0C6B6B),
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "Logo selecionado",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0C6B6B),
                                  ),
                                ),
                              ],
                            ),
                            if (nomeArquivo != null &&
                                nomeArquivo!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                nomeArquivo!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF4A6868),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                InkWell(
                                  onTap: onSelecionarLogo,
                                  child: const Text(
                                    "Trocar imagem",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0C6B6B),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                InkWell(
                                  onTap: onRemoverLogo,
                                  child: const Text(
                                    "Remover",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_upload_outlined,
                        color: Color(0xFF0C6B6B),
                        size: 32,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Toque para enviar o Logo ou Foto da ONG",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
