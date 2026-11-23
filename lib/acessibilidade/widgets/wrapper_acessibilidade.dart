import 'package:flutter/material.dart';

import '../filters/filtro_daltonismo.dart';
import '../models/configuracao_acessibilidade.dart';

class WrapperAcessibilidade extends StatelessWidget {
  final ConfiguracaoAcessibilidade config;
  final Widget child;

  const WrapperAcessibilidade({
    super.key,
    required this.config,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    // Aplica o aumento de fonte globalmente.
    final mediaQueryAcessibilidade = mediaQuery.copyWith(
      textScaler: TextScaler.linear(config.escalaFonte),
    );

    return MediaQuery(
      data: mediaQueryAcessibilidade,
      child: FiltroDaltonismo(
        modo: config.modoDaltonismo,
        child: child,
      ),
    );
  }
}
