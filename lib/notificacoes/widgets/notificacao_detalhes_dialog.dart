// lib/notificacoes/widgets/notificacao_detalhes_dialog.dart

import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:web/web.dart' as web;

import '../../eventos/detalhe/evento_detalhe_page.dart';
import '../../eventos/voluntario/eventos_page.dart';
import '../../models/notification_models.dart';
import '../../ongs/gestao_eventos/gestao_eventos_page.dart';
import '../../services/notification_service.dart';
import '../../services/session_service.dart';
import '../../voluntarios/perfil/widgets/modal_nova_experiencia.dart';
import '../../voluntarios/services/voluntario_profile_service.dart';
import 'certificado_imagem_generator.dart';

class NotificacaoDetalhesDialog {
  static const String _baseUrl = "https://abc-do-bem.onrender.com";

  static void exibir(
    BuildContext context, {
    required NotificacaoModel notificacao,
    required bool isMobile,
    required bool isOng,
    required void Function(String mensagem) onCompartilhar,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.all(isMobile ? 18 : 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: notificacao.corTema.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(notificacao.icone,
                      color: notificacao.corTema, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notificacao.titulo,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF062222),
                        ),
                      ),
                      Text(
                        notificacao.dataRelativa,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              notificacao.mensagemCompleta,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF3A6868),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            _buildAcoes(
              dialogCtx,
              rootContext: context,
              notificacao: notificacao,
              isMobile: isMobile,
              isOng: isOng,
              onCompartilhar: onCompartilhar,
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _baixarCertificadoPdf(
    BuildContext dialogContext, {
    required String applicationId,
    required void Function(String mensagem) onFeedback,
  }) async {
    final token = SessionService.instance.token?.trim() ?? '';
    if (token.isEmpty) {
      onFeedback(
          "Sessão expirada. Faça login novamente para baixar o certificado.");
      return;
    }

    if (applicationId.trim().isEmpty) {
      onFeedback("Certificado indisponível para esta notificação.");
      return;
    }

    try {
      final url = Uri.parse(
        "$_baseUrl/certificates/applications/${applicationId.trim()}/download",
      );

      final res = await http.get(
        url,
        headers: {
          "Accept": "application/pdf",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 25));

      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        String filename = "certificado-abc-do-bem.pdf";
        final disposition = res.headers['content-disposition'] ?? '';
        final match = RegExp(r'filename="?([^"]+)"?').firstMatch(disposition);
        if (match != null && (match.group(1)?.trim().isNotEmpty ?? false)) {
          filename = match.group(1)!.trim();
        }

        if (kIsWeb) {
          final jsArray = res.bodyBytes.toJS;
          final blobParts = <JSAny>[jsArray].toJS;
          final blob = web.Blob(
            blobParts,
            web.BlobPropertyBag(type: 'application/pdf'),
          );
          final objectUrl = web.URL.createObjectURL(blob);

          final anchor =
              web.document.createElement('a') as web.HTMLAnchorElement;
          anchor.href = objectUrl;
          anchor.download = filename;
          anchor.target = '_blank';
          web.document.body?.append(anchor);
          anchor.click();
          anchor.remove();

          Future.delayed(const Duration(seconds: 10), () {
            web.URL.revokeObjectURL(objectUrl);
          });
        }

        if (dialogContext.mounted) {
          Navigator.of(dialogContext).pop();
        }
        onFeedback("Download do certificado iniciado!");
      } else {
        onFeedback(
          "Não foi possível baixar o certificado agora. Tente novamente.",
        );
      }
    } catch (_) {
      onFeedback(
        "Não foi possível baixar o certificado agora. Tente novamente.",
      );
    }
  }

 static Future<void> _compartilharCertificadoNoFeed(
    BuildContext dialogContext, {
    required BuildContext rootContext,
    required NotificacaoModel notificacao,
    required void Function(String mensagem) onFeedback,
  }) async {
    final resultado = await CertificadoImagemGenerator.gerarPngDoCertificado(
      rootContext,
      applicationId: notificacao.linkId ?? '',
      mensagemFallback: notificacao.mensagemCompleta,
    );

    if (resultado == null) {
      onFeedback("Não foi possível preparar a imagem do certificado agora.");
      return;
    }

    if (dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }
    if (!rootContext.mounted) return;

    final usuarioId = SessionService.instance.usuarioId?.trim() ?? '';
    final token = SessionService.instance.token?.trim() ?? '';
    final profileService = VoluntarioProfileService();

    ModalNovaExperiencia.abrir(
      context: rootContext,
      eventosConcluidos: [resultado.tituloEvento],
      textoInicial: resultado.textoSugerido,
      imagensIniciais: [resultado.imagemPng],
      picker: ImagePicker(),
      onSolicitarConfirmacao: ({
        required String texto,
        required String origem,
        required List<XFile> imagens,
        required BuildContext modalParentContext,
      }) async {
        if (modalParentContext.mounted) {
          Navigator.of(modalParentContext).pop();
        }

        final sucesso = await profileService.publicarExperiencia(
          usuarioId,
          texto,
          null,
          opportunityId: null,
          imagensArquivos: imagens,
          token: token,
        );

        onFeedback(
          sucesso
              ? "Certificado publicado no feed com sucesso!"
              : "Não foi possível publicar no feed agora. Tente novamente.",
        );
      },
    );
  }

  static Widget _buildAcoes(
    BuildContext context, {
    required BuildContext rootContext,
    required NotificacaoModel notificacao,
    required bool isMobile,
    required bool isOng,
    required void Function(String mensagem) onCompartilhar,
  }) {
    final String rawType = (notificacao.rawType ?? '').toUpperCase();

    void navegarParaAcao() {
      final eventoId = notificacao.linkId?.trim() ?? '';
      final usuarioAtualId = SessionService.instance.usuarioId?.trim() ?? '';

      Navigator.pop(context);

      if (eventoId.isNotEmpty) {
        Navigator.push(
          rootContext,
          MaterialPageRoute(
            builder: (_) => EventoDetalhePage(
              eventoId: eventoId,
              usuarioAtualId: usuarioAtualId,
              isOng: isOng,
            ),
          ),
        );
        return;
      }

      if (isOng) {
        Navigator.push(
          rootContext,
          MaterialPageRoute(
            builder: (_) => GestaoEventosPage(
              ongId: usuarioAtualId,
              tipoUsuario: "ong",
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          rootContext,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const EventosPage(),
            transitionDuration: Duration.zero,
          ),
        );
      }
    }

    Widget montarParBotoes(Widget btnPrincipal, Widget btnSecundario) {
      if (isMobile) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            btnPrincipal,
            const SizedBox(height: 8),
            btnSecundario,
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: btnPrincipal),
          const SizedBox(width: 10),
          Expanded(child: btnSecundario),
        ],
      );
    }

    final btnFechar = OutlinedButton(
      onPressed: () => Navigator.pop(context),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 13),
        side: const BorderSide(color: Color(0xFF0C6B6B)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text(
        "Fechar",
        style: TextStyle(color: Color(0xFF0C6B6B), fontWeight: FontWeight.bold),
      ),
    );

    // 1. CERTIFICADO PRONTO -> Compartilhar no Feed (PNG) + Baixar PDF + Fechar
    if (rawType == 'CERTIFICATE_READY') {
      bool baixandoPdf = false;
      bool preparandoPost = false;

      return StatefulBuilder(
        builder: (ctx, setStateBtn) {
          final ocupado = baixandoPdf || preparandoPost;

          final btnCompartilharFeed = ElevatedButton.icon(
            onPressed: ocupado
                ? null
                : () async {
                    setStateBtn(() => preparandoPost = true);
                    await _compartilharCertificadoNoFeed(
                      context,
                      rootContext: rootContext,
                      notificacao: notificacao,
                      onFeedback: onCompartilhar,
                    );
                    if (ctx.mounted) {
                      setStateBtn(() => preparandoPost = false);
                    }
                  },
            icon: preparandoPost
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.campaign_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
            label: Text(
              preparandoPost ? "Preparando..." : "Publicar no Feed",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0C6B6B),
              padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
          );

          final btnBaixarPdf = OutlinedButton.icon(
            onPressed: ocupado
                ? null
                : () async {
                    setStateBtn(() => baixandoPdf = true);
                    await _baixarCertificadoPdf(
                      context,
                      applicationId: notificacao.linkId ?? '',
                      onFeedback: onCompartilhar,
                    );
                    if (ctx.mounted) {
                      setStateBtn(() => baixandoPdf = false);
                    }
                  },
            icon: baixandoPdf
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF0C6B6B),
                    ),
                  )
                : const Icon(
                    Icons.picture_as_pdf_rounded,
                    size: 17,
                    color: Color(0xFF0C6B6B),
                  ),
            label: Text(
              baixandoPdf ? "Gerando PDF..." : "Baixar PDF",
              style: const TextStyle(
                color: Color(0xFF0C6B6B),
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 13),
              side: const BorderSide(color: Color(0xFF0C6B6B)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              montarParBotoes(btnCompartilharFeed, btnBaixarPdf),
              const SizedBox(height: 8),
              btnFechar,
            ],
          );
        },
      );
    }

    // 2. NECESSIDADE DE SUPRIMENTO -> Botão "Posso Ajudar"
    if (rawType == 'SUPPLY_NEEDED' &&
        notificacao.linkId != null &&
        notificacao.linkId!.isNotEmpty) {
      final btnPossoAjudar = ElevatedButton.icon(
        onPressed: () {
          final supplyId = notificacao.linkId!;
          Navigator.pop(context);
          _abrirDialogCompromissoDoacao(
            rootContext,
            supplyId: supplyId,
            onFeedback: onCompartilhar,
          );
        },
        icon: const Icon(Icons.volunteer_activism_rounded,
            size: 16, color: Colors.white),
        label: const Text(
          "Posso Ajudar",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0C6B6B),
          padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
      );

      return montarParBotoes(btnPossoAjudar, btnFechar);
    }

    // 3. DOAÇÕES RECEBIDAS / PROMESSAS
    if (rawType == 'NEW_PLEDGE' || rawType == 'PLEDGE_DELIVERED') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0C6B6B),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: Text(
            rawType == 'NEW_PLEDGE'
                ? "Ciente, conferir no painel"
                : "Entendido",
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    // 4. EVENTOS / VAGAS E APROVAÇÕES DE CANDIDATURA
    if (notificacao.tipo == TipoNotificacao.evento ||
        notificacao.tipo == TipoNotificacao.aprovacao) {
      final labelPrincipal = notificacao.tipo == TipoNotificacao.evento
          ? (isOng ? "Ver Ação" : "Quero Participar")
          : "Ver em Meus Eventos";

      final btnPrincipal = ElevatedButton(
        onPressed: navegarParaAcao,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0C6B6B),
          padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: Text(
          labelPrincipal,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );

      return montarParBotoes(btnPrincipal, btnFechar);
    }

    // 5. CONQUISTAS GERAIS
    if (notificacao.tipo == TipoNotificacao.conquista) {
      final btnCompartilhar = ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(context);
          onCompartilhar(
              "Link de conquista copiado para a área de transferência!");
        },
        icon: const Icon(Icons.share_rounded, size: 16, color: Colors.white),
        label: const Text(
          "Compartilhar",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0C6B6B),
          padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
      );

      return montarParBotoes(btnCompartilhar, btnFechar);
    }

    // 6. SISTEMA / GERAL
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0C6B6B),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: const Text(
          "Entendido",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// Modal rápido para o voluntário registrar quanto pode doar (POST /ongs/supplies/:id/pledges)
  static void _abrirDialogCompromissoDoacao(
    BuildContext context, {
    required String supplyId,
    required void Function(String mensagem) onFeedback,
  }) {
    final qtdController = TextEditingController();
    final obsController = TextEditingController();
    bool enviando = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "Registrar Compromisso de Doação",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF062222),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: qtdController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Quantidade que você pode doar",
                  hintText: "Ex: 5",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: obsController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Observação / Previsão de entrega (opcional)",
                  hintText: "Ex: Entrego no sábado pela manhã",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: enviando ? null : () => Navigator.pop(ctx),
              child: const Text("Cancelar",
                  style: TextStyle(color: Color(0xFF3A6868))),
            ),
            ElevatedButton(
              onPressed: enviando
                  ? null
                  : () async {
                      final valor = double.tryParse(
                          qtdController.text.trim().replaceAll(',', '.'));
                      if (valor == null || valor <= 0) {
                        onFeedback(
                            "Informe uma quantidade válida maior que zero.");
                        return;
                      }

                      setStateDialog(() => enviando = true);
                      final ok = await NotificationService()
                          .registrarCompromissoDoacao(
                        supplyId: supplyId,
                        quantidade: valor,
                        observacoes: obsController.text,
                      );

                      if (ctx.mounted) Navigator.pop(ctx);
                      onFeedback(
                        ok
                            ? "Compromisso registrado! A ONG já foi notificada."
                            : "Não foi possível registrar a doação agora.",
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C6B6B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: enviando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text("Confirmar Doação",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}