// lib/vagas/widgets/modal_candidatura_vaga.dart

import 'package:flutter/material.dart';
import '../../services/session_service.dart';
import '../services/vagas_service.dart';

class ModalCandidaturaVaga {
  static void exibir(
    BuildContext context, {
    required String vagaId,
    required String tituloVaga,
    required String ongNome,
    required String dataHorario,
    required VoidCallback onInscricaoSucesso,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        bool enviando = false;

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC2E4DC),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Confirmar Inscrição',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF062222),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Irá candidatar-se para a oportunidade promovida por $ongNome.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF5A8585),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FAF7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFC2E4DC)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tituloVaga,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0C6B6B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: Color(0xFF7AAAA0),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dataHorario,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF3A6868),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline_rounded,
                              size: 14,
                              color: Color(0xFF7AAAA0),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Voluntário: ${SessionService.instance.nomeUsuario ?? "Voluntário"}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF3A6868),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: enviando
                              ? null
                              : () => Navigator.pop(bottomSheetContext),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFC2E4DC)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: enviando
                              ? null
                              : () async {
                                  setModalState(() => enviando = true);
                                  final service = VagasService();
                                  final sucesso =
                                      await service.candidatar(vagaId);

                                  if (!bottomSheetContext.mounted) return;
                                  Navigator.pop(bottomSheetContext);

                                  if (sucesso) {
                                    onInscricaoSucesso();
                                    scaffoldMessenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Inscrição confirmada com sucesso! A ONG foi notificada.',
                                        ),
                                        backgroundColor: Color(0xFF0C6B6B),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } else {
                                    scaffoldMessenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Não foi possível concluir a inscrição. Tente novamente.',
                                        ),
                                        backgroundColor: Colors.redAccent,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0C6B6B),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: enviando
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Quero Ajudar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
