import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/configuracao_acessibilidade.dart';

class AcessibilidadeController extends ChangeNotifier {
  static final AcessibilidadeController instancia = AcessibilidadeController();

  static const _chaveEscala = 'abc_a11y_escala_fonte';
  static const _chaveContraste = 'abc_a11y_alto_contraste';
  static const _chaveDaltonismo = 'abc_a11y_modo_daltonismo';
  static const _chaveVlibras = 'abc_a11y_vlibras_ativo';

  final ValueNotifier<bool> fabVisivel = ValueNotifier<bool>(true);

  final ValueNotifier<double> deslocamentoInferiorFab =
      ValueNotifier<double>(16.0);

  ConfiguracaoAcessibilidade _config = const ConfiguracaoAcessibilidade();

  ConfiguracaoAcessibilidade get config => _config;

  double get escalaFonte => _config.escalaFonte;

  int get percentualFonte => _config.percentualFonte;

  bool get altoContraste => _config.altoContraste;

  ModoDaltonismo get modoDaltonismo => _config.modoDaltonismo;

  // VLibras disponível somente na versão web.
  bool get vlibrasAtivo => kIsWeb && _config.vlibrasAtivo;

  bool get podeAumentarFonte => _config.podeAumentarFonte;

  bool get podeDiminuirFonte => _config.podeDiminuirFonte;

  void configurarFab({bool? visivel, double? bottom}) {
    if (visivel != null && fabVisivel.value != visivel) {
      fabVisivel.value = visivel;
    }

    if (bottom != null && deslocamentoInferiorFab.value != bottom) {
      deslocamentoInferiorFab.value = bottom;
    }
  }

  void restaurarFabPadrao() {
    fabVisivel.value = true;
    deslocamentoInferiorFab.value = 16.0;
  }

  Future<void> carregar() async {
    final prefs = await SharedPreferences.getInstance();

    final escalaSalva = prefs.getDouble(_chaveEscala) ?? 1.0;
    final contraste = prefs.getBool(_chaveContraste) ?? false;
    final indiceDaltonismo = prefs.getInt(_chaveDaltonismo) ?? 0;

    // Na web, VLibras fica ativo por padrão.
    // No aplicativo mobile, fica sempre desativado.
    final vlibras = kIsWeb ? (prefs.getBool(_chaveVlibras) ?? true) : false;

    final escalaSegura = escalaSalva
        .clamp(
          ConfiguracaoAcessibilidade.escalaMinima,
          ConfiguracaoAcessibilidade.escalaMaxima,
        )
        .toDouble();

    final modoSeguro =
        indiceDaltonismo >= 0 && indiceDaltonismo < ModoDaltonismo.values.length
            ? ModoDaltonismo.values[indiceDaltonismo]
            : ModoDaltonismo.nenhum;

    _config = ConfiguracaoAcessibilidade(
      escalaFonte: escalaSegura,
      altoContraste: contraste,
      modoDaltonismo: modoSeguro,
      vlibrasAtivo: vlibras,
    );

    notifyListeners();
  }

  Future<void> aumentarFonte() async {
    if (!podeAumentarFonte) return;

    _config = _config.aumentarFonte();

    notifyListeners();

    await _salvar();
  }

  Future<void> diminuirFonte() async {
    if (!podeDiminuirFonte) return;

    _config = _config.diminuirFonte();

    notifyListeners();

    await _salvar();
  }

  Future<void> resetarFonte() async {
    _config = _config.resetarFonte();

    notifyListeners();

    await _salvar();
  }

  Future<void> alternarAltoContraste(bool valor) async {
    if (_config.altoContraste == valor) return;

    _config = _config.copyWith(
      altoContraste: valor,
    );

    notifyListeners();

    await _salvar();
  }

  Future<void> definirModoDaltonismo(
    ModoDaltonismo modo,
  ) async {
    if (_config.modoDaltonismo == modo) return;

    _config = _config.copyWith(
      modoDaltonismo: modo,
    );

    notifyListeners();

    await _salvar();
  }

  Future<void> alternarVlibras(bool valor) async {
    // VLibras não será ativado na versão mobile.
    if (!kIsWeb) return;

    if (_config.vlibrasAtivo == valor) return;

    _config = _config.copyWith(
      vlibrasAtivo: valor,
    );

    notifyListeners();

    await _salvar();
  }

  Future<void> restaurarPadrao() async {
    _config = _config.restaurarPadrao().copyWith(vlibrasAtivo: kIsWeb);

    restaurarFabPadrao();

    notifyListeners();

    await _salvar();
  }

  Future<void> _salvar() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble(
      _chaveEscala,
      _config.escalaFonte,
    );

    await prefs.setBool(
      _chaveContraste,
      _config.altoContraste,
    );

    await prefs.setInt(
      _chaveDaltonismo,
      _config.modoDaltonismo.index,
    );

    await prefs.setBool(
      _chaveVlibras,
      vlibrasAtivo,
    );
  }
}
