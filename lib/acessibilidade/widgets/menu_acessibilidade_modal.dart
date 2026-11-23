import 'package:flutter/material.dart';
import '../controllers/acessibilidade_controller.dart';
import '../models/configuracao_acessibilidade.dart';
import '../vlibras/vlibras_bridge.dart';

class MenuAcessibilidadeModal extends StatefulWidget {
  final AcessibilidadeController controller;
  final VoidCallback? onAbrirAjudaVlibras;

  const MenuAcessibilidadeModal({
    super.key,
    required this.controller,
    this.onAbrirAjudaVlibras,
  });

  static Future<void> exibir(
    BuildContext context, {
    required AcessibilidadeController controller,
    VoidCallback? onAbrirAjudaVlibras,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => MenuAcessibilidadeModal(
        controller: controller,
        onAbrirAjudaVlibras: onAbrirAjudaVlibras,
      ),
    );
  }

  @override
  State<MenuAcessibilidadeModal> createState() =>
      _MenuAcessibilidadeModalState();
}

class _MenuAcessibilidadeModalState extends State<MenuAcessibilidadeModal> {
  final VlibrasBridge _vlibrasBridge = criarVlibrasBridge();

  Future<void> _aoAlternarVlibras(bool ativo) async {
    await widget.controller.alternarVlibras(ativo);
    _vlibrasBridge.atualizarVisibilidade(ativo: ativo);
    if (ativo && _vlibrasBridge.suportaWidgetEmbutido) {
      _vlibrasBridge.abrirWidget();
    }
  }

  void _abrirAjuda(BuildContext context) {
    if (widget.onAbrirAjudaVlibras != null) {
      widget.onAbrirAjudaVlibras!();
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Como usar o VLibras'),
        content: Text(
          _vlibrasBridge.suportaWidgetEmbutido
              ? 'Na versão Web, o ícone do VLibras fica disponível na tela e traduz os textos selecionados ou lidos pela página para Libras.'
              : 'No aplicativo mobile, você pode utilizar o leitor de tela do sistema (TalkBack / VoiceOver) ou o aplicativo oficial VLibras instalado no dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final escala = controller.escalaFonte;
        final percentual = controller.percentualFonte;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.accessibility_new_rounded,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Acessibilidade',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Fechar menu de acessibilidade',
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          tooltip: 'Fechar',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ajuste leitura, cores e recursos de apoio para o ABC do Bem.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.78),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 1. Tamanho da fonte / escala da tela
                  Semantics(
                    container: true,
                    label: 'Tamanho do texto em $percentual por cento',
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Tamanho da fonte e tela',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '$percentual%',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                Semantics(
                                  button: true,
                                  label: 'Diminuir tamanho da fonte',
                                  child: OutlinedButton.icon(
                                    onPressed: controller.podeDiminuirFonte
                                        ? controller.diminuirFonte
                                        : null,
                                    icon: const Icon(Icons.text_decrease),
                                    label: const Text('A-'),
                                  ),
                                ),
                                Semantics(
                                  button: true,
                                  label: 'Aumentar tamanho da fonte',
                                  child: ElevatedButton.icon(
                                    onPressed: controller.podeAumentarFonte
                                        ? controller.aumentarFonte
                                        : null,
                                    icon: const Icon(Icons.text_increase),
                                    label: const Text('A+'),
                                  ),
                                ),
                                if ((escala - 1.0).abs() > 0.001)
                                  Semantics(
                                    button: true,
                                    label:
                                        'Restaurar tamanho padrão da fonte para 100 por cento',
                                    child: TextButton(
                                      onPressed: controller.resetarFonte,
                                      child: const Text('100%'),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Alto contraste
                  Card(
                    child: Semantics(
                      toggled: controller.altoContraste,
                      label: 'Alto contraste',
                      child: SwitchListTile(
                        value: controller.altoContraste,
                        onChanged: controller.alternarAltoContraste,
                        title: const Text(
                          'Alto contraste',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Aumenta o contraste entre textos, fundos e bordas.',
                        ),
                        secondary: const Icon(Icons.contrast),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Daltonismo
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.palette_outlined),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Modo para daltonismo',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<ModoDaltonismo>(
                            value: controller.modoDaltonismo,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            items: ModoDaltonismo.values
                                .map(
                                  (modo) => DropdownMenuItem<ModoDaltonismo>(
                                    value: modo,
                                    child: Text(modo.rotulo),
                                  ),
                                )
                                .toList(),
                            onChanged: (modo) {
                              if (modo != null) {
                                controller.definirModoDaltonismo(modo);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. VLibras
                  Card(
                    child: Column(
                      children: [
                        Semantics(
                          toggled: controller.vlibrasAtivo,
                          label: 'VLibras tradução em Libras',
                          child: SwitchListTile(
                            value: controller.vlibrasAtivo,
                            onChanged: _aoAlternarVlibras,
                            title: const Text(
                              'VLibras (Libras)',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text(
                              'Ativa o recurso de tradução para Língua Brasileira de Sinais.',
                            ),
                            secondary: const Icon(Icons.sign_language),
                          ),
                        ),
                        if (controller.vlibrasAtivo)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () => _abrirAjuda(context),
                                icon: const Icon(Icons.info_outline),
                                label: const Text('Como usar o VLibras'),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Restaurar padrão geral
                  OutlinedButton.icon(
                    onPressed: () async {
                      await controller.restaurarPadrao();
                      _vlibrasBridge.atualizarVisibilidade(ativo: false);
                    },
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Restaurar configurações padrão'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
