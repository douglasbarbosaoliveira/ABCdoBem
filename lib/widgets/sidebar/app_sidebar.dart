// lib/widgets/sidebar/app_sidebar.dart

import 'package:flutter/material.dart';

import '../../services/session_service.dart';
import '../../voluntarios/home/voluntario_home_page.dart';
import '../../ongs/home/ong_home_page.dart';
import '../../voluntarios/buscar/buscar_ongs_page.dart';
import '../../eventos/voluntario/eventos_page.dart';
import '../../../notificacoes/notificacoes_page.dart';
import '../../../mensagens/mensagens_page.dart';
import '../../voluntarios/perfil/voluntario_perfil_page.dart';
import '../../ongs/painel_geral/painel_geral_page.dart';
import '../../ongs/gestao_eventos/gestao_eventos_page.dart';

import 'widgets/sidebar_header.dart';
import 'widgets/sidebar_menu_item.dart';
import 'widgets/sidebar_logout_dialog.dart';

class AppSidebar extends StatelessWidget {
  final int currentIndex;
  final String usuarioId;
  final String tipoUsuario; // "voluntario" ou "ong"

  const AppSidebar({
    super.key,
    required this.currentIndex,
    this.usuarioId = "voluntario-1",
    this.tipoUsuario = "voluntario",
  });

  bool get isOng {
    final roleSessao = SessionService.instance.role?.trim().toUpperCase();
    if (roleSessao != null && roleSessao.isNotEmpty) {
      return roleSessao == "ONG";
    }
    return tipoUsuario.trim().toLowerCase() == "ong";
  }

  String get _tipoEfetivo => isOng ? "ong" : "voluntario";

  /// Retorna sempre o ID da sessão autenticada para a navegação do sidebar
  String get _idUsuarioLogado {
    final sessaoId = SessionService.instance.usuarioId?.trim();
    if (sessaoId != null && sessaoId.isNotEmpty) {
      return sessaoId;
    }
    if (usuarioId.trim().isNotEmpty && usuarioId != "voluntario-1") {
      return usuarioId.trim();
    }
    return "voluntario-1";
  }

  void _navegarSemAnimacao(BuildContext context, Widget destino) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, a1, a2) => destino,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFC2E4DC))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Topo: Logo + Identificador do Perfil
          SidebarHeader(isOng: isOng),
          const Divider(height: 1, color: Color(0xFFC2E4DC)),

          // 2. Card Compacto do Usuário Logado (Lendo do SessionService)
          _buildUserSessionCard(),
          const Divider(height: 1, color: Color(0xFFC2E4DC)),
          const SizedBox(height: 12),

          // 3. Lista de Menus (ONG ou Voluntário)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: isOng
                  ? _buildMenusOng(context)
                  : _buildMenusVoluntario(context),
            ),
          ),

          // 4. Rodapé: Logout
          const Divider(height: 1, color: Color(0xFFC2E4DC)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SidebarMenuItem(
              icon: Icons.logout_rounded,
              label: "Sair da conta",
              selecionado: false,
              corTexto: Colors.redAccent,
              onTap: () => SidebarLogoutDialog.exibir(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSessionCard() {
    return ValueListenableBuilder<String?>(
      valueListenable: SessionService.instance.fotoUrlNotifier,
      builder: (context, fotoUrl, _) {
        final nome = SessionService.instance.nomeUsuario ??
            (isOng ? "Instituição Parceira" : "Voluntário");
        final cidade = SessionService.instance.cidade ?? "Grande ABC";
        final bool temFotoValida =
            fotoUrl != null && fotoUrl.startsWith("http");

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          color: const Color(0xFFF7FCFA),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFD1F5EE),
                backgroundImage: temFotoValida ? NetworkImage(fotoUrl) : null,
                child: !temFotoValida
                    ? const Icon(
                        Icons.person_rounded,
                        color: Color(0xFF0C6B6B),
                        size: 20,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF062222),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isOng ? "Instituição Parceira" : cidade,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7AAAA0),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildMenusOng(BuildContext context) {
    final String idAtivo = _idUsuarioLogado;

    return [
      SidebarMenuItem(
        icon: Icons.home_rounded,
        label: "Home",
        selecionado: currentIndex == 0,
        onTap: () => _navegarSemAnimacao(
          context,
          OngHomePage(ongId: idAtivo),
        ),
      ),
      SidebarMenuItem(
        icon: Icons.search_rounded,
        label: "Buscar",
        selecionado: currentIndex == 1,
        onTap: () => _navegarSemAnimacao(
          context,
          BuscarOngsPage(voluntarioId: idAtivo),
        ),
      ),
      SidebarMenuItem(
        icon: Icons.notifications_rounded,
        label: "Avisos",
        selecionado: currentIndex == 2,
        onTap: () => _navegarSemAnimacao(
          context,
          NotificacoesPage(
            usuarioId: idAtivo,
            tipoUsuario: _tipoEfetivo,
          ),
        ),
      ),
      SidebarMenuItem(
        icon: Icons.chat_bubble_rounded,
        label: "Chat",
        selecionado: currentIndex == 3,
        onTap: () => _navegarSemAnimacao(
          context,
          MensagensPage(
            usuarioId: idAtivo,
            tipoUsuario: _tipoEfetivo,
          ),
        ),
      ),
      SidebarMenuItem(
        icon: Icons.settings_rounded,
        label: "Painel Geral",
        selecionado: currentIndex == 4,
        onTap: () => _navegarSemAnimacao(
          context,
          OngPainelGeralPage(
            ongId: idAtivo,
            tipoUsuario: _tipoEfetivo,
          ),
        ),
      ),
      SidebarMenuItem(
        icon: Icons.event_note_rounded,
        label: "Eventos",
        selecionado: currentIndex == 5,
        onTap: () => _navegarSemAnimacao(
          context,
          GestaoEventosPage(
            ongId: idAtivo,
            tipoUsuario: _tipoEfetivo,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildMenusVoluntario(BuildContext context) {
    final String idAtivo = _idUsuarioLogado;

    return [
      SidebarMenuItem(
        icon: Icons.home_rounded,
        label: "Início",
        selecionado: currentIndex == 0,
        onTap: () => _navegarSemAnimacao(
          context,
          VoluntarioHomePage(
            voluntarioId: idAtivo,
            nomeUsuario: SessionService.instance.nomeUsuario,
            token: SessionService.instance.token,
          ),
        ),
      ),
      SidebarMenuItem(
        icon: Icons.search_rounded,
        label: "Buscar ONGs",
        selecionado: currentIndex == 1,
        onTap: () => _navegarSemAnimacao(
          context,
          BuscarOngsPage(voluntarioId: idAtivo),
        ),
      ),
      SidebarMenuItem(
        icon: Icons.event_available_rounded,
        label: "Eventos",
        selecionado: currentIndex == 2,
        onTap: () => _navegarSemAnimacao(
          context,
          EventosPage(voluntarioId: idAtivo),
        ),
      ),
      SidebarMenuItem(
        icon: Icons.chat_bubble_rounded,
        label: "Mensagens",
        selecionado: currentIndex == 3,
        onTap: () => _navegarSemAnimacao(
          context,
          MensagensPage(
            usuarioId: idAtivo,
            tipoUsuario: _tipoEfetivo,
          ),
        ),
      ),
      SidebarMenuItem(
        icon: Icons.person_rounded,
        label: "Meu Painel",
        selecionado: currentIndex == 4,
        onTap: () => _navegarSemAnimacao(
          context,
          VoluntarioPerfilPage(
            usuarioId: idAtivo,
            tipoUsuario: _tipoEfetivo,
            token: SessionService.instance.token,
          ),
        ),
      ),
    ];
  }
}
