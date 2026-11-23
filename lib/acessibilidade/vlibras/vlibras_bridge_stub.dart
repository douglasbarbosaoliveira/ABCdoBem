import 'vlibras_bridge.dart';

class VlibrasBridgeStub implements VlibrasBridge {
  @override
  bool get suportaWidgetEmbutido => false;

  @override
  void atualizarVisibilidade({required bool ativo}) {
    // No mobile/desktop nativo, o widget web do VLibras não é injetado no DOM.
  }

  @override
  void abrirWidget() {
    // Pode ser conectado a um modal de orientação ou ao app oficial do VLibras.
  }
}

VlibrasBridge criarBridgePlataforma() => VlibrasBridgeStub();
