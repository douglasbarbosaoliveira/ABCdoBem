// lib/ongs/criar_evento/widgets/secao_foto_capa.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/gerador_capa_evento_service.dart';
import '../../../services/session_service.dart';

class SecaoFotoCapa extends StatefulWidget {
  final TextEditingController bannerUrlCtrl;
  final VoidCallback onFotoAlterada;
  final String tituloEvento;
  final List<String> categorias;
  final bool permitirFallbackLocal;

  const SecaoFotoCapa({
    super.key,
    required this.bannerUrlCtrl,
    required this.onFotoAlterada,
    this.tituloEvento = "",
    this.categorias = const [],
    this.permitirFallbackLocal = true,
  });

  static const String _urlPadraoAntiga =
      "https://images.unsplash.com/photo-1559027615-cd4628902d4a";

  static List<String> extrairImagens(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return [];

    if (trimmed.startsWith('[')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) {
          return decoded
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty && !e.contains(_urlPadraoAntiga))
              .take(3)
              .toList();
        }
      } catch (_) {}
    }

    if (trimmed.contains(_urlPadraoAntiga)) return [];
    return [trimmed];
  }

  static String serializarImagens(List<String> imagens) {
    final limpas = imagens
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(3)
        .toList();
    if (limpas.isEmpty) return '';
    if (limpas.length == 1) return limpas.first;
    return jsonEncode(limpas);
  }

  @override
  State<SecaoFotoCapa> createState() => _SecaoFotoCapaState();
}

class _SecaoFotoCapaState extends State<SecaoFotoCapa> {
  final ImagePicker _picker = ImagePicker();
  final GeradorCapaEventoService _geradorIaService = GeradorCapaEventoService();

  late List<String> _imagens;
  bool _processando = false;
  bool _gerandoIa = false;

  @override
  void initState() {
    super.initState();
    _imagens = SecaoFotoCapa.extrairImagens(widget.bannerUrlCtrl.text);
    final serializado = SecaoFotoCapa.serializarImagens(_imagens);
    if (widget.bannerUrlCtrl.text != serializado) {
      widget.bannerUrlCtrl.text = serializado;
    }
  }

  void _sincronizarController() {
    widget.bannerUrlCtrl.text = SecaoFotoCapa.serializarImagens(_imagens);
    widget.onFotoAlterada();
  }

  String _imagemFallbackPorCausa() {
    final texto = widget.categorias.join(" ").toLowerCase();
    if (texto.contains("educa") || texto.contains("aula")) {
      return "https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=1280";
    }
    if (texto.contains("saúde") || texto.contains("saude")) {
      return "https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=1280";
    }
    if (texto.contains("ambient") || texto.contains("animal")) {
      return "https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?w=1280";
    }
    return "https://images.unsplash.com/photo-1559027615-cd4628902d4a?w=1280";
  }

  Future<void> _gerarCapaComIa() async {
    if (_imagens.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Você já adicionou o limite máximo de 3 imagens."),
          backgroundColor: Color(0xFF0C6B6B),
        ),
      );
      return;
    }

    setState(() => _gerandoIa = true);

    try {
      final imagemGerada = await _geradorIaService.gerarCapaEvento(
        tituloEvento: widget.tituloEvento,
        categorias: widget.categorias,
        token: SessionService.instance.token,
      );

      if (!mounted) return;

      if (imagemGerada != null && imagemGerada.isNotEmpty) {
        setState(() {
          _imagens.insert(0, imagemGerada);
          _gerandoIa = false;
        });
        _sincronizarController();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Foto gerada com IA adicionada ao evento!"),
            backgroundColor: Color(0xFF0C6B6B),
          ),
        );
        return;
      }

      throw Exception("Resposta vazia do serviço de imagem.");
    } catch (_) {
      if (!mounted) return;

      if (widget.permitirFallbackLocal) {
        final fallbackUrl = _imagemFallbackPorCausa();
        setState(() {
          if (!_imagens.contains(fallbackUrl)) {
            _imagens.insert(0, fallbackUrl);
          }
          _gerandoIa = false;
        });
        _sincronizarController();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Capa temática selecionada automaticamente.",
            ),
            backgroundColor: Color(0xFF0C6B6B),
          ),
        );
      } else {
        setState(() => _gerandoIa = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Não foi possível gerar a foto com IA no momento."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _selecionarArquivo() async {
    if (_imagens.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Você já adicionou o limite máximo de 3 imagens."),
          backgroundColor: Color(0xFF0C6B6B),
        ),
      );
      return;
    }

    try {
      setState(() => _processando = true);
      final XFile? arquivo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 900,
        imageQuality: 78,
      );

      if (arquivo == null) {
        if (mounted) setState(() => _processando = false);
        return;
      }

      final bytes = await arquivo.readAsBytes();
      final mime = arquivo.name.toLowerCase().endsWith('.png')
          ? 'image/png'
          : 'image/jpeg';
      final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';

      if (!mounted) return;
      setState(() {
        _imagens.add(dataUri);
        _processando = false;
      });
      _sincronizarController();
    } catch (e) {
      if (!mounted) return;
      setState(() => _processando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Não foi possível carregar a imagem: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _definirComoCapa(int index) {
    if (index <= 0 || index >= _imagens.length) return;
    setState(() {
      final escolhida = _imagens.removeAt(index);
      _imagens.insert(0, escolhida);
    });
    _sincronizarController();
  }

  void _removerImagem(int index) {
    setState(() {
      _imagens.removeAt(index);
    });
    _sincronizarController();
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

  Widget _buildImagemWidget(String src, {double height = 140}) {
    final placeholder = Container(
      height: height,
      width: double.infinity,
      color: const Color(0xFFC7EBE3),
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined,
            color: Color(0xFF0C6B6B), size: 32),
      ),
    );

    if (src.toLowerCase().startsWith('http://') ||
        src.toLowerCase().startsWith('https://')) {
      return Image.network(
        src,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }

    final bytes = _decodificarBase64(src);
    if (bytes != null) {
      return Image.memory(
        bytes,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }

    return placeholder;
  }

  @override
  Widget build(BuildContext context) {
    final podeAdicionar = _imagens.length < 3;
    final ocupado = _processando || _gerandoIa;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC2E4DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.photo_library_rounded,
                      size: 18, color: Color(0xFF0C6B6B)),
                  SizedBox(width: 6),
                  Text(
                    "6. Fotos do Evento (até 3 imagens)",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F5F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${_imagens.length}/3",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0C6B6B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_imagens.isEmpty)
            Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FAF7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFC2E4DC),
                  style: BorderStyle.solid,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 32, color: Color(0xFF0C6B6B)),
                  SizedBox(height: 6),
                  Text(
                    "Nenhuma imagem selecionada",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            )
          else ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildImagemWidget(_imagens[0], height: 150),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C6B6B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Capa Principal",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: InkWell(
                    onTap: () => _removerImagem(0),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
            if (_imagens.length > 1) ...[
              const SizedBox(height: 10),
              Row(
                children: List.generate(_imagens.length - 1, (i) {
                  final idxReal = i + 1;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: idxReal < _imagens.length - 1 ? 8 : 0),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildImagemWidget(_imagens[idxReal],
                                height: 80),
                          ),
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: InkWell(
                              onTap: () => _definirComoCapa(idxReal),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  "Usar como capa",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: InkWell(
                              onTap: () => _removerImagem(idxReal),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded,
                                    color: Colors.white, size: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      (ocupado || !podeAdicionar) ? null : _selecionarArquivo,
                  icon: _processando
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF0C6B6B),
                          ),
                        )
                      : const Icon(Icons.file_upload_outlined,
                          size: 16, color: Color(0xFF0C6B6B)),
                  label: Text(
                    _processando ? "Carregando..." : "Adicionar Foto",
                    style: const TextStyle(
                      color: Color(0xFF0C6B6B),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF0C6B6B)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      (ocupado || !podeAdicionar) ? null : _gerarCapaComIa,
                  icon: _gerandoIa
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome_rounded,
                          size: 15, color: Colors.white),
                  label: Text(
                    _gerandoIa ? "Gerando..." : "Gerar Foto",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C6B6B),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
