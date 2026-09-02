// lib/app_sidebar.dart

import 'package:flutter/material.dart';

import 'volunteer_homepage.dart';
import 'search_ongs_page.dart';
import 'events_page.dart';
import 'notifications_page.dart';
import 'messages_page.dart';
import 'services/notification_service.dart';
import 'services/chat_service.dart';

class AppSidebar extends StatefulWidget {
  final int currentIndex;
  final String usuarioId;
  final String tipoUsuario;
  final String nomeUsuario;
  final String subtituloUsuario;
  final String fotoPerfilUrl;

  const AppSidebar({
    super.key,
    required this.currentIndex,
    this.usuarioId = "voluntario-1",
    this.tipoUsuario = "voluntario",
    this.nomeUsuario = "Ana Carolina",
    this.subtituloUsuario = "Voluntária • Santo André",
    this.fotoPerfilUrl =
        "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400",
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  final NotificationService _notificationService = NotificationService();
  final ChatService _chatService = ChatService();

  int _notificacoesNaoLidas = 0;
  int _mensagensNaoLidas = 0;

  @override
  void initState() {
    super.initState();
    _carregarContadoresApi();
  }

  /// Busca os contadores reais de alertas e mensagens pendentes da API RESTful
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

        // Soma as mensagens não lidas de todos os canais de conversa
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
      // Caso a API esteja em inicialização, mantém seguro sem quebrar o layout
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 24.0,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.eco_rounded,
                  color: Color(0xFF0C6B6B),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        "ABC do Bem",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF062222),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "Grande ABC Paulista",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 16),

          _buildSidebarItem(
            context,
            Icons.home_rounded,
            "Início",
            0,
            const VoluntarioHomePage(),
          ),
          _buildSidebarItem(
            context,
            Icons.search_rounded,
            "Buscar ONGs",
            1,
            const BuscarOngsPage(),
          ),
          _buildSidebarItem(
            context,
            Icons.event_rounded,
            "Eventos",
            2,
            const EventosPage(),
          ),
          _buildSidebarItem(
            context,
            Icons.notifications_active_rounded,
            "Notificações",
            3,
            const NotificacoesPage(),
            badgeCount: _notificacoesNaoLidas,
            badgeColor: const Color(0xFFE53935), // Vermelho
          ),
          _buildSidebarItem(
            context,
            Icons.chat_bubble_rounded,
            "Mensagens",
            4,
            MensagensPage(
              usuarioId: widget.usuarioId,
              tipoUsuario: widget.tipoUsuario,
            ),
            badgeCount: _mensagensNaoLidas,
            badgeColor: const Color(0xFFE53935), // Vermelho
          ),
          _buildSidebarItem(
            context,
            Icons.person_rounded,
            "Meu Perfil",
            5,
            null,
          ),

          const Spacer(),

          // Card inferior com dados do usuário autenticado
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FAF7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(widget.fotoPerfilUrl),
                  radius: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.nomeUsuario,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF062222),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.subtituloUsuario,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    Widget? destino, {
    int badgeCount = 0,
    Color badgeColor = const Color(0xFFE53935),
  }) {
    bool isSelected = widget.currentIndex == index;
    return InkWell(
      onTap: () {
        if (!isSelected && destino != null) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, a1, a2) => destino,
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD1F5EE) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Badge(
              isLabelVisible: badgeCount > 0,
              label: Text("$badgeCount"),
              backgroundColor: badgeColor,
              child: Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF0C6B6B)
                    : Colors.grey.shade600,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF0C6B6B)
                      : const Color(0xFF062222),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
