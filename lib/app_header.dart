// lib/app_header.dart

import 'package:flutter/material.dart';

import 'notifications_page.dart';
import 'messages_page.dart';
import 'services/notification_service.dart';
import 'services/chat_service.dart';

class AppHeader extends StatefulWidget implements PreferredSizeWidget {
  final String usuarioId;
  final String tipoUsuario;
  final String nomeUsuario;
  final String fotoPerfilUrl;

  const AppHeader({
    super.key,
    this.usuarioId = "voluntario-1",
    this.tipoUsuario = "voluntario",
    this.nomeUsuario = "Ana Carolina",
    this.fotoPerfilUrl =
        "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400",
  });

  @override
  State<AppHeader> createState() => _AppHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(70);
}

class _AppHeaderState extends State<AppHeader> {
  final NotificationService _notificationService = NotificationService();
  final ChatService _chatService = ChatService();

  int _notificacoesNaoLidas = 0;
  int _mensagensNaoLidas = 0;

  @override
  void initState() {
    super.initState();
    _carregarContadoresApi();
  }

  /// Busca os contadores da API RESTful em paralelo
  Future<void> _carregarContadoresApi() async {
    try {
      final resultados = await Future.wait([
        _notificationService.buscarTotalNaoLidas(widget.usuarioId),
        _chatService.buscarConversas(
          usuarioId: widget.usuarioId,
          tipoUsuario: widget.tipoUsuario,
        ),
      ]);

      if (mounted) {
        final totalNotif = resultados[0] as int;
        final conversas = resultados[1] as List;

        final totalMensagens = conversas.fold<int>(
          0,
          (acumulado, conversa) => acumulado + (conversa.naoLidas as int),
        );

        setState(() {
          _notificacoesNaoLidas = totalNotif;
          _mensagensNaoLidas = totalMensagens;
        });
      }
    } catch (_) {
      // Falha silenciosa para evitar inconsistências no layout durante carregamento
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Ícone de Notificações com Badge
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, a1, a2) =>
                      NotificacoesPage(usuarioId: widget.usuarioId),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            },
            tooltip: "Notificações",
            icon: Badge(
              isLabelVisible: _notificacoesNaoLidas > 0,
              label: Text("$_notificacoesNaoLidas"),
              backgroundColor: const Color(0xFFE53935), // Vermelho de alerta
              child: const Icon(
                Icons.notifications_outlined,
                color: Color(0xFF0C6B6B),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Ícone de Mensagens com Badge Vermelho
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, a1, a2) => MensagensPage(
                    usuarioId: widget.usuarioId,
                    tipoUsuario: widget.tipoUsuario,
                  ),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            },
            tooltip: "Mensagens",
            icon: Badge(
              isLabelVisible: _mensagensNaoLidas > 0,
              label: Text("$_mensagensNaoLidas"),
              backgroundColor: const Color(0xFFE53935), // Vermelho de alerta
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Color(0xFF0C6B6B),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Perfil do usuário logado
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(widget.fotoPerfilUrl),
                radius: 18,
              ),
              const SizedBox(width: 10),
              Text(
                widget.nomeUsuario,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF062222),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
