import 'package:flutter/material.dart';

import '../../utils/responsive.dart';
import '../../services/session_service.dart';
import '../../services/notification_service.dart';
import '../../mensagens/services/chat_service.dart';

import '../../acessibilidade/controllers/acessibilidade_controller.dart';
import '../../acessibilidade/widgets/menu_acessibilidade_modal.dart';

import 'widgets/header_brand_section.dart';
import 'widgets/header_action_icons.dart';
import 'widgets/header_user_avatar.dart';
import 'widgets/header_user_menu_modal.dart';

class AppHeader extends StatefulWidget implements PreferredSizeWidget {
  final String usuarioId;
  final String tipoUsuario; // "voluntario" ou "ong"
  final String? nomeUsuario;
  final String? fotoPerfilUrl;

  /// Controla a visibilidade do botão voltar.
  final bool showBackButton;

  final VoidCallback? onVoltar;
  final VoidCallback? onPerfilAtualizado;

  /// Callback opcional para abrir a acessibilidade.
  ///
  /// Se não for informada, o AppHeader abre diretamente
  /// o MenuAcessibilidadeModal usando o controller global.
  final VoidCallback? onOpenAccessibility;

  const AppHeader({
    super.key,
    this.usuarioId = "voluntario-1",
    this.tipoUsuario = "voluntario",
    this.nomeUsuario,
    this.fotoPerfilUrl,
    this.showBackButton = false,
    this.onVoltar,
    this.onPerfilAtualizado,
    this.onOpenAccessibility,
  });

  @override
  State<AppHeader> createState() => _AppHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(70);
}

class _AppHeaderState extends State<AppHeader> {
  final NotificationService _notificationService = NotificationService();
  final ChatService _chatService = ChatService();

  int _mensagensNaoLidas = 0;

  bool _modalAcessibilidadeAberto = false;

  bool get isOng {
    final roleSessao = SessionService.instance.role?.trim().toUpperCase();

    if (roleSessao != null && roleSessao.isNotEmpty) {
      return roleSessao == "ONG";
    }

    return widget.tipoUsuario.trim().toLowerCase() == "ong";
  }

  String get _tipoEfetivo => isOng ? "ong" : "voluntario";

  /// O ID do cabeçalho deve ser SEMPRE o do usuário autenticado
  /// na sessão ativa.
  String get _idUsuarioLogado {
    final sessaoId = SessionService.instance.usuarioId?.trim();

    if (sessaoId != null && sessaoId.isNotEmpty) {
      return sessaoId;
    }

    if (widget.usuarioId.trim().isNotEmpty &&
        widget.usuarioId != "voluntario-1") {
      return widget.usuarioId.trim();
    }

    return "voluntario-1";
  }

  /// O nome no avatar superior sempre representa o dono
  /// da sessão ativa.
  String get _nomeExibicao {
    final sessaoNome = SessionService.instance.nomeUsuario?.trim();

    if (sessaoNome != null && sessaoNome.isNotEmpty) {
      return sessaoNome;
    }

    if (widget.nomeUsuario != null && widget.nomeUsuario!.trim().isNotEmpty) {
      return widget.nomeUsuario!.trim();
    }

    return isOng ? "Instituição Parceira" : "Voluntário";
  }

  String _sanitizarUrlAvatar(String? rawUrl) {
    if (rawUrl == null) return "";

    final String url = rawUrl.trim();

    if (url.isEmpty ||
        url == "null" ||
        url.contains("default.png") ||
        url.contains("placeholder") ||
        url.contains("storage.xyz") ||
        url.contains("example.com")) {
      return "";
    }

    if (url.startsWith("data:image")) return url;

    if (url.startsWith("http://") || url.startsWith("https://")) {
      return url;
    }

    if (url.startsWith("/")) {
      return "https://abc-do-bem.onrender.com$url";
    }

    return "https://abc-do-bem.onrender.com/$url";
  }

  /// A foto do avatar superior reflete a foto válida
  /// do próprio usuário autenticado.
  String get _fotoExibicao {
    final String sessaoFoto =
        _sanitizarUrlAvatar(SessionService.instance.fotoUrl);

    if (sessaoFoto.isNotEmpty) {
      return sessaoFoto;
    }

    final sessaoId = SessionService.instance.usuarioId?.trim();

    final bool isPerfilDeTerceiros =
        sessaoId != null && widget.usuarioId.trim() != sessaoId;

    if (!isPerfilDeTerceiros) {
      final String widgetFoto = _sanitizarUrlAvatar(widget.fotoPerfilUrl);

      if (widgetFoto.isNotEmpty) {
        return widgetFoto;
      }
    }

    return "";
  }

  @override
  void initState() {
    super.initState();
    _carregarContadoresApi();
  }

  @override
  void didUpdateWidget(covariant AppHeader oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.usuarioId != widget.usuarioId ||
        oldWidget.tipoUsuario != widget.tipoUsuario ||
        oldWidget.fotoPerfilUrl != widget.fotoPerfilUrl ||
        oldWidget.nomeUsuario != widget.nomeUsuario) {
      _carregarContadoresApi();
    }
  }

  /// Abre o modal de acessibilidade.
  ///
  /// Caso a tela pai tenha fornecido uma callback, utiliza-a.
  /// Caso contrário, abre o modal diretamente com o controller
  /// global do aplicativo.
  Future<void> _abrirAcessibilidade() async {
    if (_modalAcessibilidadeAberto) return;

    _modalAcessibilidadeAberto = true;

    try {
      if (widget.onOpenAccessibility != null) {
        widget.onOpenAccessibility!();
      } else {
        await MenuAcessibilidadeModal.exibir(
          context,
          controller: AcessibilidadeController.instancia,
        );
      }
    } catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível abrir as opções de acessibilidade.',
            ),
          ),
        );
      }
    } finally {
      _modalAcessibilidadeAberto = false;
    }
  }

  Future<void> _carregarContadoresApi() async {
    final idAtivo = _idUsuarioLogado;

    try {
      final resultados = await Future.wait([
        _notificationService.buscarTotalNaoLidas(idAtivo),
        _chatService.buscarConversas(
          usuarioId: idAtivo,
          tipoUsuario: _tipoEfetivo,
        ),
      ]);

      if (!mounted) return;

      final conversas = resultados[1] is List ? (resultados[1] as List) : [];

      final totalMensagens = conversas.fold<int>(
        0,
        (acumulado, conversa) {
          int count = 0;

          if (conversa is Map) {
            count = (conversa['naoLidas'] as num?)?.toInt() ?? 0;
          } else {
            try {
              count = (conversa.naoLidas as num?)?.toInt() ?? 0;
            } catch (_) {
              count = 0;
            }
          }

          return acumulado + count;
        },
      );

      setState(() {
        _mensagensNaoLidas = totalMensagens;
      });
    } catch (_) {}
  }

  void _abrirMenuUsuario() {
    HeaderUserMenuModal.exibir(
      context,
      usuarioId: _idUsuarioLogado,
      tipoUsuario: _tipoEfetivo,
      isOng: isOng,
      nomeExibicao: _nomeExibicao,
      fotoExibicao: _fotoExibicao,
    );
  }

  void _aoClicarVoltar() {
    if (widget.onVoltar != null) {
      widget.onVoltar!();
    } else if (Navigator.canPop(context)) {
      Navigator.maybePop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Responsive.isDesktop(context);

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFC2E4DC),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          HeaderBrandSection(
            showBackButton: widget.showBackButton,
            isDesktop: isDesktop,
            isOng: isOng,
            onVoltar: _aoClicarVoltar,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Notificações e mensagens
              ValueListenableBuilder<int>(
                valueListenable: NotificationService.totalNaoLidasNotifier,
                builder: (context, totalNotificacoes, _) {
                  return HeaderActionIcons(
                    usuarioId: _idUsuarioLogado,
                    tipoUsuario: _tipoEfetivo,
                    isOng: isOng,
                    notificacoesNaoLidas: totalNotificacoes,
                    mensagensNaoLidas: _mensagensNaoLidas,
                  );
                },
              ),

              const SizedBox(width: 8),

              // Botão de acessibilidade
              IconButton(
                tooltip: 'Acessibilidade',
                onPressed: _abrirAcessibilidade,
                icon: const Icon(
                  Icons.accessibility_new,
                  color: Color(0xFF007F6D),
                  size: 25,
                ),
              ),

              const SizedBox(width: 8),

              // Avatar do usuário autenticado
              ValueListenableBuilder<String?>(
                valueListenable: SessionService.instance.fotoUrlNotifier,
                builder: (context, _, __) {
                  return HeaderUserAvatar(
                    nomeExibicao: _nomeExibicao,
                    fotoExibicao: _fotoExibicao,
                    isDesktop: isDesktop,
                    isOng: isOng,
                    onTap: _abrirMenuUsuario,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
