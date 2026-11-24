// lib/widgets/feed/post_card_widget.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../voluntarios/models/voluntario_profile_models.dart';

class PostCardWidget extends StatefulWidget {
  final String nomeAutor;
  final String fotoAutor;
  final String dataPostagem;
  final String nomeEvento;
  final String texto;
  final String? imagemUrl;
  final int curtidas;
  final bool curtido;
  final Future<bool> Function()? onCurtirApi;
  final VoidCallback? onCompartilhar;
  final VoidCallback? onAutorTap;
  final VoidCallback? onEventoTap;
  final bool isMobile;

  const PostCardWidget({
    super.key,
    required this.nomeAutor,
    required this.fotoAutor,
    required this.dataPostagem,
    required this.nomeEvento,
    required this.texto,
    this.imagemUrl,
    this.curtidas = 0,
    this.curtido = false,
    this.onCurtirApi,
    this.onCompartilhar,
    this.onAutorTap,
    this.onEventoTap,
    required this.isMobile,
  });

  @override
  State<PostCardWidget> createState() => _PostCardWidgetState();
}

class _PostCardWidgetState extends State<PostCardWidget> {
  late bool _curtidoLocal;
  late int _curtidasLocal;
  bool _processandoCurtida = false;

  @override
  void initState() {
    super.initState();
    _curtidoLocal = widget.curtido;
    _curtidasLocal = widget.curtidas;
  }

  @override
  void didUpdateWidget(covariant PostCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.curtido != widget.curtido ||
        oldWidget.curtidas != widget.curtidas) {
      _curtidoLocal = widget.curtido;
      _curtidasLocal = widget.curtidas;
    }
  }

  String _normalizarDataExibicao(String rawData) {
    final limpo = rawData.trim();
    if (limpo.isEmpty ||
        limpo.toLowerCase().contains('agora') ||
        limpo.toLowerCase().contains('min') ||
        limpo.toLowerCase().contains('hora') ||
        limpo.toLowerCase() == 'recente') {
      final agora = DateTime.now();
      final d = agora.day.toString().padLeft(2, '0');
      final m = agora.month.toString().padLeft(2, '0');
      return '$d/$m/${agora.year}';
    }

    final dtIso = DateTime.tryParse(limpo);
    if (dtIso != null) {
      final d = dtIso.day.toString().padLeft(2, '0');
      final m = dtIso.month.toString().padLeft(2, '0');
      return '$d/$m/${dtIso.year}';
    }

    return limpo;
  }

  Future<void> _alternarCurtida() async {
    if (_processandoCurtida) return;

    final bool estadoAnterior = _curtidoLocal;
    final int contagemAnterior = _curtidasLocal;

    setState(() {
      _curtidoLocal = !_curtidoLocal;
      _curtidasLocal += _curtidoLocal ? 1 : -1;
      if (_curtidasLocal < 0) _curtidasLocal = 0;
      _processandoCurtida = true;
    });

    if (widget.onCurtirApi != null) {
      final bool sucesso = await widget.onCurtirApi!();
      if (!sucesso && mounted) {
        setState(() {
          _curtidoLocal = estadoAnterior;
          _curtidasLocal = contagemAnterior;
        });
      }
    }

    if (mounted) {
      setState(() => _processandoCurtida = false);
    }
  }

  Widget _buildImagem(String rawUrl, {double? width, double? height}) {
    final original = rawUrl.trim();
    if (original.isEmpty) return const SizedBox.shrink();

    if (original.startsWith('data:image')) {
      try {
        final partes = original.split(',');
        if (partes.length < 2) return const SizedBox.shrink();
        final limpo = partes.last.replaceAll(RegExp(r'\s+'), '');
        final Uint8List bytes = base64Decode(limpo);
        if (bytes.isEmpty) return const SizedBox.shrink();
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        );
      } catch (_) {
        return const SizedBox.shrink();
      }
    }

    final url = VoluntarioPerfilModel.sanitizarImagem(original);
    if (url.isEmpty) return const SizedBox.shrink();

    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  Widget _buildAvatar() {
    final url = VoluntarioPerfilModel.sanitizarImagem(widget.fotoAutor);
    if (url.isEmpty) {
      return Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: Color(0xFFD1F5EE),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.person_rounded,
          size: 20,
          color: Color(0xFF0C6B6B),
        ),
      );
    }

    return ClipOval(
      child: SizedBox(
        width: 38,
        height: 38,
        child: _buildImagem(url, width: 38, height: 38),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool temEvento = widget.nomeEvento.isNotEmpty &&
        widget.nomeEvento != 'Postagem Livre' &&
        widget.nomeEvento != 'Ação Comunitária';

    final String dataPadronizada = _normalizarDataExibicao(widget.dataPostagem);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC2E4DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Foto clicável para o perfil
              GestureDetector(
                onTap: widget.onAutorTap,
                child: MouseRegion(
                  cursor: widget.onAutorTap != null
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  child: _buildAvatar(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome do voluntário clicável para o perfil
                    GestureDetector(
                      onTap: widget.onAutorTap,
                      child: MouseRegion(
                        cursor: widget.onAutorTap != null
                            ? SystemMouseCursors.click
                            : SystemMouseCursors.basic,
                        child: Text(
                          widget.nomeAutor,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: Color(0xFF062222),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Data da postagem
                    Text(
                      dataPadronizada,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7AAAA0),
                      ),
                    ),
                    if (temEvento) ...[
                      const SizedBox(height: 3),
                      // Nome do evento sem fundo/sombra, sem sublinhado e clicável para os detalhes do evento
                      GestureDetector(
                        onTap: widget.onEventoTap,
                        child: MouseRegion(
                          cursor: widget.onEventoTap != null
                              ? SystemMouseCursors.click
                              : SystemMouseCursors.basic,
                          child: Text(
                            widget.nomeEvento,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0C6B6B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.texto,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF3A6868),
              height: 1.35,
            ),
          ),
          if (widget.imagemUrl != null &&
              widget.imagemUrl!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildImagem(
                widget.imagemUrl!,
                width: double.infinity,
                height: widget.isMobile ? 180 : 260,
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE3F5F1)),
          const SizedBox(height: 8),
          Row(
            children: [
              // Botão Curtir
              InkWell(
                onTap: _alternarCurtida,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        _curtidoLocal
                            ? Icons.favorite_rounded
                            : Icons.favorite_outline_rounded,
                        size: 18,
                        color: _curtidoLocal
                            ? Colors.redAccent
                            : const Color(0xFF7AAAA0),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "$_curtidasLocal",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _curtidoLocal
                              ? Colors.redAccent
                              : const Color(0xFF7AAAA0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Botão Comentar (sem função por enquanto)
              InkWell(
                onTap: null,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 17,
                        color: Color(0xFF7AAAA0),
                      ),
                      SizedBox(width: 6),
                      Text(
                        "Comentar",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7AAAA0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Botão Compartilhar
              InkWell(
                onTap: widget.onCompartilhar,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.share_outlined,
                        size: 18,
                        color: Color(0xFF7AAAA0),
                      ),
                      SizedBox(width: 6),
                      Text(
                        "Compartilhar",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7AAAA0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
