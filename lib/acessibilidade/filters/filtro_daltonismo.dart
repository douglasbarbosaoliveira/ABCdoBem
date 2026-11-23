import 'package:flutter/material.dart';

import '../models/configuracao_acessibilidade.dart';

class FiltroDaltonismo extends StatelessWidget {
  final ModoDaltonismo modo;
  final Widget child;

  const FiltroDaltonismo({
    super.key,
    required this.modo,
    required this.child,
  });

  // Matrizes 5x4 (RGBA) para simulação/compensação cromática.
  static const List<double> _matrizProtanopia = <double>[
    0.567,
    0.433,
    0.000,
    0.0,
    0.0,
    0.558,
    0.442,
    0.000,
    0.0,
    0.0,
    0.000,
    0.242,
    0.758,
    0.0,
    0.0,
    0.000,
    0.000,
    0.000,
    1.0,
    0.0,
  ];

  static const List<double> _matrizDeuteranopia = <double>[
    0.625,
    0.375,
    0.000,
    0.0,
    0.0,
    0.700,
    0.300,
    0.000,
    0.0,
    0.0,
    0.000,
    0.300,
    0.700,
    0.0,
    0.0,
    0.000,
    0.000,
    0.000,
    1.0,
    0.0,
  ];

  static const List<double> _matrizTritanopia = <double>[
    0.950,
    0.050,
    0.000,
    0.0,
    0.0,
    0.000,
    0.433,
    0.567,
    0.0,
    0.0,
    0.000,
    0.475,
    0.525,
    0.0,
    0.0,
    0.000,
    0.000,
    0.000,
    1.0,
    0.0,
  ];

  List<double>? _obterMatriz() {
    switch (modo) {
      case ModoDaltonismo.nenhum:
        return null;
      case ModoDaltonismo.protanopia:
        return _matrizProtanopia;
      case ModoDaltonismo.deuteranopia:
        return _matrizDeuteranopia;
      case ModoDaltonismo.tritanopia:
        return _matrizTritanopia;
    }
  }

  @override
  Widget build(BuildContext context) {
    final matriz = _obterMatriz();

    if (matriz == null) {
      return child;
    }

    return ColorFiltered(
      colorFilter: ColorFilter.matrix(matriz),
      child: child,
    );
  }
}
