import 'dart:async';

import 'package:web/web.dart' as web;

import 'vlibras_bridge.dart';

class VlibrasBridgeWeb implements VlibrasBridge {
  Timer? _timer;
  bool _ativo = true;
  int _tentativas = 0;

  @override
  bool get suportaWidgetEmbutido => true;

  @override
  void atualizarVisibilidade({required bool ativo}) {
    _ativo = ativo;
    _tentativas = 0;

    _timer?.cancel();

    _aplicarVisibilidade();

    // O VLibras pode criar o botão depois da inicialização.
    // Tentamos novamente até encontrar os elementos.
    _timer = Timer.periodic(
      const Duration(milliseconds: 250),
      (timer) {
        _tentativas++;

        final encontrados = _aplicarVisibilidade();

        if (encontrados || _tentativas >= 40) {
          timer.cancel();
          _timer = null;
        }
      },
    );
  }

  bool _aplicarVisibilidade() {
    _instalarRegraDeEstilo();

    // Em telas mobile, o VLibras fica oculto.
    final bool mobile = web.window.matchMedia('(max-width: 767px)').matches;

    final bool ocultar = !_ativo || mobile;

    final container = web.document.querySelector('[vw]');
    final botao = web.document.querySelector('[vw-access-button]');

    if (container != null) {
      if (ocultar) {
        container.setAttribute('data-vlibras-hidden', 'true');
      } else {
        container.removeAttribute('data-vlibras-hidden');
      }
    }

    if (botao != null) {
      if (ocultar) {
        botao.setAttribute('data-vlibras-hidden', 'true');
      } else {
        botao.removeAttribute('data-vlibras-hidden');
      }
    }

    return container != null && botao != null;
  }

  void _instalarRegraDeEstilo() {
    const styleId = 'vlibras-visibility-style';

    if (web.document.getElementById(styleId) != null) {
      return;
    }

    final style = web.document.createElement('style');

    style.id = styleId;
    style.textContent = '''
      [vw][data-vlibras-hidden="true"],
      [vw-access-button][data-vlibras-hidden="true"] {
        display: none !important;
      }
    ''';

    web.document.head?.appendChild(style);
  }

  @override
  void abrirWidget() {
    atualizarVisibilidade(ativo: true);

    final bool mobile = web.window.matchMedia('(max-width: 767px)').matches;

    if (mobile) return;

    final botao = web.document.querySelector('[vw-access-button]');

    botao?.dispatchEvent(web.Event('click'));
  }
}

VlibrasBridge criarBridgePlataforma() => VlibrasBridgeWeb();
