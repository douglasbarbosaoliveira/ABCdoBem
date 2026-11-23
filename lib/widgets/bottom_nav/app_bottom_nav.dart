// lib/widgets/bottom_nav/app_bottom_nav.dart

import 'package:flutter/material.dart';
import '../../services/session_service.dart';
import 'widgets/bottom_nav_item_config.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final String usuarioId;
  final String tipoUsuario;

  const AppBottomNav({
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

  bool get _nenhumaAbaAtiva => currentIndex < 0;

  void _navegar(BuildContext context, Widget pagina) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, a1, a2) => pagina,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<BottomNavItemConfig> itens = isOng
        ? BottomNavItemConfig.itensOng()
        : BottomNavItemConfig.itensVoluntario();

    final int indexValido =
        (currentIndex >= 0 && currentIndex < itens.length) ? currentIndex : 0;

    // ID garantido da sessão ativa
    final String idLogado = SessionService.instance.usuarioId ?? usuarioId;

    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: BottomNavigationBar(
        currentIndex: indexValido,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor:
            _nenhumaAbaAtiva ? Colors.grey : const Color(0xFF0C6B6B),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: TextStyle(
          fontWeight: _nenhumaAbaAtiva ? FontWeight.normal : FontWeight.bold,
          fontSize: 11,
          fontFamily: 'Quicksand',
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontFamily: 'Quicksand',
        ),
        onTap: (index) {
          if (index == currentIndex) return;
          // Dispara a rota passando sempre a identidade e o tipo real da sessão
          final rota = itens[index].builder(context, idLogado, _tipoEfetivo);
          _navegar(context, rota);
        },
        items: itens
            .map(
              (item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
