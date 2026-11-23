// lib/ongs/perfil/widgets/ong_perfil_necessidades_section.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OngPerfilNecessidadesSection extends StatelessWidget {
  final List<String> necessidades;
  final String? chavePix;
  final String? horarioRecebimento;
  final bool mostrarBotaoAjudar;
  final VoidCallback? onQueroAjudar;

  const OngPerfilNecessidadesSection({
    super.key,
    required this.necessidades,
    this.chavePix,
    this.horarioRecebimento,
    this.mostrarBotaoAjudar = true,
    this.onQueroAjudar,
  });

  void _copiarChavePix(BuildContext context, String pix) {
    Clipboard.setData(ClipboardData(text: pix));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Chave PIX copiada para a área de transferência!"),
        backgroundColor: Color(0xFF0C6B6B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool temPix = chavePix != null && chavePix!.trim().isNotEmpty;
    final bool temHorario =
        horarioRecebimento != null && horarioRecebimento!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC2E4DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Necessidades Atuais e Doações",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF062222),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Itens e apoios que a instituição mais precisa neste momento:",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),

          if (necessidades.isEmpty)
            const Text(
              "A instituição não listou necessidades específicas no momento. Entre em contato pelo chat para saber como apoiar.",
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF5A8A80),
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: necessidades.map((String item) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFD591)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        size: 14,
                        color: Color(0xFFD46B08),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD46B08),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          // Informações reais de logística de doação (Horário e Chave PIX)
          if (temHorario || temPix) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6FCFA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDDF2EC)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (temHorario)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 15,
                          color: Color(0xFF0C6B6B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Recebimento de doações: ${horarioRecebimento!.trim()}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF2D5555),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (temHorario && temPix) const SizedBox(height: 10),
                  if (temPix)
                    Row(
                      children: [
                        const Icon(
                          Icons.pix_rounded,
                          size: 16,
                          color: Color(0xFF0C6B6B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "PIX: ${chavePix!.trim()}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF062222),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () =>
                              _copiarChavePix(context, chavePix!.trim()),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1F5EE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.copy_rounded,
                                  size: 12,
                                  color: Color(0xFF0C6B6B),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "Copiar",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0C6B6B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],

          // Botão "Quero Ajudar" redirecionando para o chat da ONG
          if (mostrarBotaoAjudar && onQueroAjudar != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onQueroAjudar,
                icon: const Icon(
                  Icons.volunteer_activism_rounded,
                  size: 17,
                  color: Colors.white,
                ),
                label: const Text(
                  "Quero Ajudar",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C6B6B),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
