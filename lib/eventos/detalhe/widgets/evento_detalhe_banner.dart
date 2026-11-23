// lib/eventos/detalhe/widgets/evento_detalhe_banner.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../models/evento_model.dart';

class EventoDetalheBanner extends StatefulWidget {
  final EventoModel evento;
  final bool isDono;
  final VoidCallback onVoltar;
  final VoidCallback? onEditar;
  final VoidCallback? onPausar;
  final VoidCallback? onCancelarEvento;

  const EventoDetalheBanner({
    super.key,
    required this.evento,
    required this.isDono,
    required this.onVoltar,
    this.onEditar,
    this.onPausar,
    this.onCancelarEvento,
  });

  @override
  State<EventoDetalheBanner> createState() => _EventoDetalheBannerState();
}

class _EventoDetalheBannerState extends State<EventoDetalheBanner> {
  late final PageController _pageController;
  late List<String> _imagens;
  int _indiceAtual = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _imagens = _extrairImagens(widget.evento.imagemUrl);
  }

  @override
  void didUpdateWidget(covariant EventoDetalheBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.evento.imagemUrl != widget.evento.imagemUrl) {
      setState(() {
        _imagens = _extrairImagens(widget.evento.imagemUrl);
        if (_indiceAtual >= _imagens.length) {
          _indiceAtual = 0;
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> _extrairImagens(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return [];

    if (trimmed.startsWith('[')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) {
          return decoded
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .take(3)
              .toList();
        }
      } catch (_) {}
    }

    return [trimmed];
  }

  Uint8List? _decodificarBase64(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty ||
        trimmed.toLowerCase().startsWith('http://') ||
        trimmed.toLowerCase().startsWith('https://')) {
      return null;
    }
    try {
      final base64Puro = trimmed.contains(',')
          ? trimmed.substring(trimmed.indexOf(',') + 1)
          : trimmed;
      var limpo = base64Puro.replaceAll(RegExp(r'\s+'), '');
      while (limpo.length % 4 != 0) {
        limpo += '=';
      }
      if (limpo.length < 32) return null;
      return base64Decode(limpo);
    } catch (_) {
      return null;
    }
  }

  Widget _buildImagem(String src, {BoxFit fit = BoxFit.cover}) {
    final placeholder = Container(
      color: const Color(0xFFD1F5EE),
      child: const Center(
        child: Icon(Icons.event, size: 54, color: Color(0xFF0C6B6B)),
      ),
    );

    if (src.isEmpty) return placeholder;

    if (src.toLowerCase().startsWith('http://') ||
        src.toLowerCase().startsWith('https://')) {
      return Image.network(
        src,
        fit: fit,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }

    final bytes = _decodificarBase64(src);
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }

    return placeholder;
  }

  Color _obterCorPorCausa(String causa) {
    switch (causa.toLowerCase()) {
      case 'meio ambiente':
        return const Color(0xFF2E7D32);
      case 'educação':
        return const Color(0xFF1565C0);
      case 'saúde':
        return const Color(0xFFC62828);
      case 'cultura':
        return const Color(0xFF6A1B9A);
      default:
        return const Color(0xFF0C6B6B);
    }
  }

  void _irParaPagina(int index) {
    if (index < 0 || index >= _imagens.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    );
  }

  void _abrirGaleriaFlutuante(int indiceInicial) {
    if (_imagens.isEmpty) return;
    int paginaDialog = indiceInicial;
    final dialogController = PageController(initialPage: indiceInicial);

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760, maxHeight: 540),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF062222),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: dialogController,
                      itemCount: _imagens.length,
                      onPageChanged: (idx) {
                        setDialogState(() => paginaDialog = idx);
                      },
                      itemBuilder: (_, idx) {
                        return InteractiveViewer(
                          minScale: 1.0,
                          maxScale: 3.5,
                          child: Center(
                            child: _buildImagem(
                              _imagens[idx],
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      top: 12,
                      left: 16,
                      right: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Foto ${paginaDialog + 1} de ${_imagens.length}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  color: Colors.white),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_imagens.length > 1)
                      Positioned(
                        bottom: 14,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_imagens.length, (idx) {
                            final ativo = idx == paginaDialog;
                            return GestureDetector(
                              onTap: () {
                                dialogController.animateToPage(
                                  idx,
                                  duration: const Duration(milliseconds: 240),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                width: ativo ? 22 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: ativo
                                      ? const Color(0xFF4FD1C5)
                                      : Colors.white54,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ).whenComplete(() => dialogController.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final evento = widget.evento;
    final possuiMultiplas = _imagens.length > 1;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Carrossel principal das imagens (até 3)
          if (_imagens.isEmpty)
            _buildImagem('')
          else
            PageView.builder(
              controller: _pageController,
              itemCount: _imagens.length,
              onPageChanged: (idx) => setState(() => _indiceAtual = idx),
              itemBuilder: (_, idx) {
                return GestureDetector(
                  onTap: () => _abrirGaleriaFlutuante(idx),
                  child: _buildImagem(_imagens[idx]),
                );
              },
            ),

          // Gradiente superior/inferior (não bloqueia gestos de toque/arraste)
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.78),
                  ],
                ),
              ),
            ),
          ),

          // Barra superior flutuante (Ampliar, Compartilhar e Menu da ONG)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_imagens.isNotEmpty) ...[
                  CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    child: IconButton(
                      tooltip: "Ampliar fotos",
                      icon: const Icon(Icons.fullscreen_rounded,
                          color: Color(0xFF062222)),
                      onPressed: () => _abrirGaleriaFlutuante(_indiceAtual),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  child: IconButton(
                    icon: const Icon(Icons.share_outlined,
                        color: Color(0xFF062222)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Link da ação copiado!")),
                      );
                    },
                  ),
                ),
                if (widget.isDono) ...[
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded,
                          color: Color(0xFF062222)),
                      onSelected: (value) {
                        if (value == 'editar') widget.onEditar?.call();
                        if (value == 'pausar') widget.onPausar?.call();
                        if (value == 'cancelar') {
                          widget.onCancelarEvento?.call();
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'editar',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text("Editar Ação"),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'pausar',
                          child: Row(
                            children: [
                              Icon(Icons.pause_circle_outline, size: 18),
                              SizedBox(width: 8),
                              Text("Pausar Inscrições"),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'cancelar',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  size: 18, color: Colors.redAccent),
                              SizedBox(width: 8),
                              Text("Cancelar Evento",
                                  style: TextStyle(color: Colors.redAccent)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Rodapé: Badges à esquerda + Card flutuante de miniaturas à direita
          Positioned(
            left: 16,
            bottom: 14,
            right: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildBadge(evento.categoria,
                          _obterCorPorCausa(evento.categoria)),
                      if (evento.emiteCertificado)
                        _buildBadge(
                            "Emite Certificado", const Color(0xFF1565C0)),
                      if (evento.isQuaseEsgotado)
                        _buildBadge("Últimas Vagas", const Color(0xFFC62828)),
                    ],
                  ),
                ),
                if (possuiMultiplas) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_imagens.length, (idx) {
                        final selecionada = idx == _indiceAtual;
                        return GestureDetector(
                          onTap: () => _irParaPagina(idx),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: EdgeInsets.only(
                              right: idx < _imagens.length - 1 ? 6 : 0,
                            ),
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: selecionada
                                    ? const Color(0xFF0C6B6B)
                                    : Colors.transparent,
                                width: 2.2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Opacity(
                                opacity: selecionada ? 1.0 : 0.68,
                                child: _buildImagem(_imagens[idx]),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
