enum ModoDaltonismo {
  nenhum,
  protanopia,
  deuteranopia,
  tritanopia,
}

extension ModoDaltonismoExt on ModoDaltonismo {
  String get rotulo {
    switch (this) {
      case ModoDaltonismo.nenhum:
        return 'Padrão';
      case ModoDaltonismo.protanopia:
        return 'Protanopia (vermelho)';
      case ModoDaltonismo.deuteranopia:
        return 'Deuteranopia (verde)';
      case ModoDaltonismo.tritanopia:
        return 'Tritanopia (azul)';
    }
  }
}

class ConfiguracaoAcessibilidade {
  final double escalaFonte;
  final bool altoContraste;
  final ModoDaltonismo modoDaltonismo;
  final bool vlibrasAtivo;

  const ConfiguracaoAcessibilidade({
    this.escalaFonte = 1.0,
    this.altoContraste = false,
    this.modoDaltonismo = ModoDaltonismo.nenhum,
    this.vlibrasAtivo = true,
  });

  static const double escalaMinima = 0.85;
  static const double escalaMaxima = 1.60;
  static const double passoEscala = 0.15;

  int get percentualFonte => (escalaFonte * 100).round();

  bool get podeAumentarFonte => escalaFonte < escalaMaxima - 0.001;

  bool get podeDiminuirFonte => escalaFonte > escalaMinima + 0.001;

  ConfiguracaoAcessibilidade copyWith({
    double? escalaFonte,
    bool? altoContraste,
    ModoDaltonismo? modoDaltonismo,
    bool? vlibrasAtivo,
  }) {
    return ConfiguracaoAcessibilidade(
      escalaFonte: escalaFonte ?? this.escalaFonte,
      altoContraste: altoContraste ?? this.altoContraste,
      modoDaltonismo: modoDaltonismo ?? this.modoDaltonismo,
      vlibrasAtivo: vlibrasAtivo ?? this.vlibrasAtivo,
    );
  }

  ConfiguracaoAcessibilidade aumentarFonte() {
    if (!podeAumentarFonte) return this;

    final proxima = (escalaFonte + passoEscala)
        .clamp(escalaMinima, escalaMaxima)
        .toDouble();

    return copyWith(
      escalaFonte: double.parse(proxima.toStringAsFixed(2)),
    );
  }

  ConfiguracaoAcessibilidade diminuirFonte() {
    if (!podeDiminuirFonte) return this;

    final anterior = (escalaFonte - passoEscala)
        .clamp(escalaMinima, escalaMaxima)
        .toDouble();

    return copyWith(
      escalaFonte: double.parse(anterior.toStringAsFixed(2)),
    );
  }

  ConfiguracaoAcessibilidade resetarFonte() {
    return copyWith(escalaFonte: 1.0);
  }

  ConfiguracaoAcessibilidade restaurarPadrao() {
    return const ConfiguracaoAcessibilidade();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ConfiguracaoAcessibilidade &&
        other.escalaFonte == escalaFonte &&
        other.altoContraste == altoContraste &&
        other.modoDaltonismo == modoDaltonismo &&
        other.vlibrasAtivo == vlibrasAtivo;
  }

  @override
  int get hashCode => Object.hash(
        escalaFonte,
        altoContraste,
        modoDaltonismo,
        vlibrasAtivo,
      );
}
