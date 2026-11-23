import 'vlibras_bridge_stub.dart'
    if (dart.library.js_interop) 'vlibras_bridge_web.dart';

abstract class VlibrasBridge {
  bool get suportaWidgetEmbutido;

  void atualizarVisibilidade({required bool ativo});

  void abrirWidget();
}

VlibrasBridge criarVlibrasBridge() => criarBridgePlataforma();
