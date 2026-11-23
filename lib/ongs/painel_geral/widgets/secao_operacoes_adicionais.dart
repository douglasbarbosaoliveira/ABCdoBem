// lib/ongs/painel_geral/widgets/secao_operacoes_adicionais.dart

import 'package:flutter/material.dart';
import '../../services/ong_painel_service.dart';
import 'card_painel_base.dart';

class SecaoOperacoesAdicionais extends StatelessWidget {
  final bool isMobile;
  final ValueChanged<String> onNavegar;
  final List<OngAcaoResumo> acoes;
  final Future<void> Function(String opportunityId)? onFinalizarCertificados;
  final Future<void> Function(
          String applicationId, bool presente, String? feedback)?
      onRegistrarPresenca;

  const SecaoOperacoesAdicionais({
    super.key,
    required this.isMobile,
    required this.onNavegar,
    this.acoes = const <OngAcaoResumo>[],
    this.onFinalizarCertificados,
    this.onRegistrarPresenca,
  });

  Future<void> _abrirFluxoCertificados(BuildContext context) async {
    if (onFinalizarCertificados == null) {
      onNavegar("Certificados");
      return;
    }

    if (acoes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Nenhuma ação disponível para finalizar certificados."),
          backgroundColor: Color(0xFF0C6B6B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Finalizar Evento e Emitir Certificados",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF062222),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Selecione a ação para emitir certificados aos presentes e notificar.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: acoes.length,
                    separatorBuilder: (_, __) => const Divider(height: 8),
                    itemBuilder: (_, index) {
                      final acao = acoes[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.school_rounded,
                          color: Color(0xFF0C6B6B),
                        ),
                        title: Text(
                          acao.titulo.isNotEmpty
                              ? acao.titulo
                              : "Ação sem título",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "${acao.dataFormatada} • ${acao.duracaoHoras}h • ${acao.vagasOcupadas}/${acao.vagasTotais} vagas",
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(ctx).pop();
                            try {
                              await onFinalizarCertificados!(acao.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Certificados emitidos e notificações enviadas.",
                                    ),
                                    backgroundColor: Color(0xFF0C6B6B),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e
                                          .toString()
                                          .replaceAll('Exception: ', ''),
                                    ),
                                    backgroundColor: Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0C6B6B),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Emitir",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _abrirDialogoPresenca(BuildContext context) async {
    if (onRegistrarPresenca == null) {
      onNavegar("Controle de Faltas");
      return;
    }

    final applicationIdCtrl = TextEditingController();
    final feedbackCtrl = TextEditingController();
    bool presente = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text(
                "Registrar Presença / No-Show",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF062222),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: applicationIdCtrl,
                      decoration: const InputDecoration(
                        labelText: "ID da inscrição (applicationId)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFF0C6B6B),
                      title: Text(
                        presente
                            ? "Presença validada (gera horas)"
                            : "Falta registrada (No-Show)",
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: presente,
                      onChanged: (val) => setDialogState(() => presente = val),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: feedbackCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: "Feedback / observação (opcional)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final appId = applicationIdCtrl.text.trim();
                    if (appId.isEmpty) return;
                    Navigator.of(ctx).pop();
                    try {
                      await onRegistrarPresenca!(
                        appId,
                        presente,
                        feedbackCtrl.text.trim(),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              presente
                                  ? "Presença validada e horas geradas."
                                  : "Falta (No-Show) registrada.",
                            ),
                            backgroundColor: const Color(0xFF0C6B6B),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceAll('Exception: ', ''),
                            ),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C6B6B),
                  ),
                  child: const Text(
                    "Salvar",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    applicationIdCtrl.dispose();
    feedbackCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final btnCertificados = OutlinedButton.icon(
      onPressed: () => _abrirFluxoCertificados(context),
      icon: const Icon(
        Icons.school_rounded,
        size: 16,
        color: Color(0xFF0C6B6B),
      ),
      label: const Text(
        "Certificados e Horas",
        style: TextStyle(
          color: Color(0xFF0C6B6B),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12),
        side: const BorderSide(color: Color(0xFF0C6B6B)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
        ),
      ),
    );

    final btnFaltas = OutlinedButton.icon(
      onPressed: () => _abrirDialogoPresenca(context),
      icon: const Icon(
        Icons.event_busy_rounded,
        size: 16,
        color: Color(0xFFD46B08),
      ),
      label: const Text(
        "Controle de Faltas (No-Show)",
        style: TextStyle(
          color: Color(0xFFD46B08),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12),
        side: const BorderSide(color: Color(0xFFD46B08)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
        ),
      ),
    );

    return CardPainelBase(
      titulo: "Operações Adicionais",
      icone: Icons.admin_panel_settings_rounded,
      isMobile: isMobile,
      conteudo: isMobile
          ? Column(
              children: [
                SizedBox(width: double.infinity, child: btnCertificados),
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: btnFaltas),
              ],
            )
          : Row(
              children: [
                Expanded(child: btnCertificados),
                const SizedBox(width: 10),
                Expanded(child: btnFaltas),
              ],
            ),
    );
  }
}
