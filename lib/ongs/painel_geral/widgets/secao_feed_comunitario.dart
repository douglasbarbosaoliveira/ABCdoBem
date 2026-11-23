// lib/ongs/painel_geral/widgets/secao_feed_comunitario.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../services/session_service.dart';
import '../../../voluntarios/perfil/widgets/modal_nova_experiencia.dart';
import '../../../widgets/feed/post_card_widget.dart';
import '../../services/ong_painel_service.dart';
import 'card_painel_base.dart';

class SecaoFeedComunitario extends StatefulWidget {
  final String ongId;
  final String nomeOng;
  final String? avatarOng;
  final bool isMobile;
  final ValueChanged<String> onNavegar;
  final List<UltimoPostOngResumo> publicacoesOng;
  final List<OngAcaoResumo> acoesOng;
  final VoidCallback? onPostCriado;
  final Future<void> Function(JsonMap payload)? onPublicarPostApi;

  const SecaoFeedComunitario({
    super.key,
    required this.ongId,
    this.nomeOng = 'ONG',
    this.avatarOng,
    required this.isMobile,
    required this.onNavegar,
    this.publicacoesOng = const <UltimoPostOngResumo>[],
    this.acoesOng = const <OngAcaoResumo>[],
    this.onPostCriado,
    this.onPublicarPostApi,
  });

  @override
  State<SecaoFeedComunitario> createState() => _SecaoFeedComunitarioState();
}

class _SecaoFeedComunitarioState extends State<SecaoFeedComunitario> {
  static const Color _corVerde = Color(0xFF0C6B6B);
  static const Color _corFundoSuave = Color(0xFFF0FAF7);
  static const Color _corBordaSuave = Color(0xFFC2E4DC);
  static const Color _corTextoSecundario = Color(0xFF4C7A70);
  static const String _baseUrl = 'https://abc-do-bem.onrender.com';

  final OngPainelService _painelService = OngPainelService();
  final ImagePicker _picker = ImagePicker();

  List<_PostOngDetalhe> _postsProprios = <_PostOngDetalhe>[];
  bool _carregando = false;
  bool _enviandoPost = false;
  String? _erroApi;

  String get _ongIdResolvido {
    final param = widget.ongId.trim();
    if (param.isNotEmpty) return param;
    return SessionService.instance.usuarioId?.trim() ?? '';
  }

  Map<String, String> _headers({bool jsonBody = false}) {
    final token = SessionService.instance.token?.trim();
    return <String, String>{
      'Accept': 'application/json',
      if (jsonBody) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  @override
  void initState() {
    super.initState();
    _postsProprios = _mapearResumos(widget.publicacoesOng);
    _buscarPostagensDaOng();
  }

  @override
  void didUpdateWidget(covariant SecaoFeedComunitario oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ongId != widget.ongId ||
        !_mesmaListaResumo(oldWidget.publicacoesOng, widget.publicacoesOng)) {
      if (widget.publicacoesOng.isNotEmpty) {
        _postsProprios = _mapearResumos(widget.publicacoesOng);
      }
      _buscarPostagensDaOng();
    }
  }

  List<_PostOngDetalhe> _mapearResumos(List<UltimoPostOngResumo> lista) {
    return lista
        .map(
          (p) => _PostOngDetalhe(
            id: p.id,
            nomeAutor: widget.nomeOng.trim().isNotEmpty
                ? widget.nomeOng.trim()
                : 'ONG',
            fotoAutor: widget.avatarOng ?? '',
            dataPostagem: '',
            nomeEvento: '',
            texto: p.tituloOuTexto,
            imagemUrl: null,
            curtidas: p.curtidas,
            comentarios: p.comentarios,
            statusLabel: p.statusLabel,
          ),
        )
        .toList();
  }

  bool _mesmaListaResumo(
    List<UltimoPostOngResumo> a,
    List<UltimoPostOngResumo> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].tituloOuTexto != b[i].tituloOuTexto ||
          a[i].curtidas != b[i].curtidas ||
          a[i].comentarios != b[i].comentarios) {
        return false;
      }
    }
    return true;
  }

  bool _pertenceAoAutorDaOng(JsonMap rawPost, String ongIdLimpo) {
    if (ongIdLimpo.isEmpty) return true;

    final tipoAutor =
        (rawPost['authorType'] ?? rawPost['tipoAutor'] ?? rawPost['role'] ?? '')
            .toString()
            .trim()
            .toUpperCase();
    if (tipoAutor == 'VOLUNTEER' || tipoAutor == 'VOLUNTARIO') {
      return false;
    }

    final autorId = (rawPost['authorId'] ??
            rawPost['ongId'] ??
            rawPost['userId'] ??
            rawPost['author']?['id'] ??
            rawPost['ong']?['id'] ??
            '')
        .toString()
        .trim();

    if (autorId.isNotEmpty && autorId != ongIdLimpo) {
      return false;
    }

    return true;
  }

  Future<void> _buscarPostagensDaOng() async {
    final ongIdLimpo = _ongIdResolvido;
    if (ongIdLimpo.isEmpty) return;

    setState(() {
      _carregando = true;
      _erroApi = null;
    });

    try {
      final uri = Uri.parse('$_baseUrl/social/ongs/$ongIdLimpo/postagens');
      final res = await http
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 12));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception(
          'Falha ao carregar postagens da ONG (HTTP ${res.statusCode}).',
        );
      }

      final listaRaw = res.bodyBytes.isEmpty
          ? <dynamic>[]
          : JsonParsers.extractList(
              jsonDecode(utf8.decode(res.bodyBytes)),
              ['posts', 'postagens', 'items'],
            );

      final filtradas = <_PostOngDetalhe>[];
      for (final raw in listaRaw) {
        if (raw is! JsonMap) continue;
        if (!_pertenceAoAutorDaOng(raw, ongIdLimpo)) continue;

        final titulo = (raw['title'] ?? raw['titulo'] ?? '').toString().trim();
        final corpo = (raw['content'] ?? raw['text'] ?? raw['descricao'] ?? '')
            .toString()
            .trim();
        final textoFinal = titulo.isNotEmpty &&
                corpo.isNotEmpty &&
                titulo != corpo
            ? '$titulo\n$corpo'
            : (corpo.isNotEmpty
                ? corpo
                : (titulo.isNotEmpty ? titulo : 'Publicação recente da ONG'));

        final curtidas = JsonParsers.toInt(
          raw['_count']?['likes'] ?? raw['likesCount'] ?? raw['curtidas'],
          fallback: 0,
        );
        final comentarios = JsonParsers.toInt(
          raw['_count']?['comments'] ??
              raw['commentsCount'] ??
              raw['comentarios'],
          fallback: 0,
        );

        final autorObj = raw['author'] is JsonMap
            ? raw['author'] as JsonMap
            : (raw['ong'] is JsonMap
                ? raw['ong'] as JsonMap
                : <String, dynamic>{});

        final nomeAutor = (autorObj['name'] ??
                autorObj['nome'] ??
                (widget.nomeOng.trim().isNotEmpty
                    ? widget.nomeOng.trim()
                    : 'ONG'))
            .toString();
        final fotoAutor = (autorObj['avatar'] ??
                autorObj['logoUrl'] ??
                widget.avatarOng ??
                '')
            .toString();

        final dataPostagem =
            (raw['createdAt'] ?? raw['dataPostagem'] ?? raw['data'] ?? '')
                .toString();

        final nomeEvento = (raw['opportunity']?['title'] ??
                raw['eventTitle'] ??
                raw['nomeEvento'] ??
                '')
            .toString();

        String? imagemUrl;
        final rawImage = (raw['imageUrl'] ??
                raw['imagemUrl'] ??
                raw['image'] ??
                raw['fotoUrl'] ??
                '')
            .toString()
            .trim();
        if (rawImage.isNotEmpty) {
          imagemUrl = rawImage;
        } else if (raw['images'] is List &&
            (raw['images'] as List).isNotEmpty) {
          final primeira = (raw['images'] as List).first;
          if (primeira is String && primeira.trim().isNotEmpty) {
            imagemUrl = primeira.trim();
          } else if (primeira is JsonMap) {
            final u = (primeira['url'] ?? primeira['imageUrl'] ?? '')
                .toString()
                .trim();
            if (u.isNotEmpty) imagemUrl = u;
          }
        }

        filtradas.add(
          _PostOngDetalhe(
            id: (raw['id'] ?? '').toString(),
            nomeAutor: nomeAutor,
            fotoAutor: fotoAutor,
            dataPostagem: dataPostagem,
            nomeEvento: nomeEvento,
            texto: textoFinal,
            imagemUrl: imagemUrl,
            curtidas: curtidas,
            comentarios: comentarios,
            statusLabel: (raw['status'] ?? 'Publicado').toString(),
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _postsProprios = filtradas;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erroApi = e.toString().replaceAll('Exception: ', '');
        _carregando = false;
      });
    }
  }

  Future<bool> _curtirPostApi(String postId) async {
    if (postId.isEmpty) return false;
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/social/ongs/postagens/$postId/like'),
            headers: _headers(jsonBody: true),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  String _detectarMimeType(String nomeArquivo) {
    final ext = nomeArquivo.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _enviarPostagemOng({
    required String texto,
    required String origem,
    required List<XFile> imagens,
    required BuildContext modalParentContext,
  }) async {
    if (_enviandoPost) return;
    setState(() => _enviandoPost = true);

    try {
      String? imagemFinal;
      if (imagens.isNotEmpty) {
        final XFile img = imagens.first;
        final Uint8List bytes = await img.readAsBytes();
        final mime = _detectarMimeType(img.name);
        imagemFinal = 'data:$mime;base64,${base64Encode(bytes)}';
      }

      final String tituloPost = (origem.trim().isNotEmpty &&
              origem.trim() != 'Postagem Livre')
          ? origem.trim()
          : (texto.length > 60 ? '${texto.substring(0, 60).trim()}...' : texto);

      final payload = <String, dynamic>{
        'title': tituloPost,
        'text': texto,
        if (imagemFinal != null) 'imageUrl': imagemFinal,
      };

      if (widget.onPublicarPostApi != null) {
        await widget.onPublicarPostApi!(payload);
      } else {
        await _painelService.publicarPostOng(payload);
      }

      if (modalParentContext.mounted) {
        Navigator.of(modalParentContext).pop();
      }
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Publicação enviada com sucesso."),
          backgroundColor: _corVerde,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _buscarPostagensDaOng();
      widget.onPostCriado?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _enviandoPost = false);
      }
    }
  }

  void _abrirModalPublicarPost() {
    final opcoesEventos = widget.acoesOng
        .map(
          (a) => (
            id: a.id,
            titulo: a.titulo,
            dataFormatada: a.dataFormatada,
          ),
        )
        .toList();

    ModalNovaExperiencia.abrir(
      context: context,
      eventosOpcoes: opcoesEventos,
      picker: _picker,
      onSolicitarConfirmacao: ({
        required String texto,
        required String origem,
        required List<XFile> imagens,
        required BuildContext modalParentContext,
      }) {
        _enviarPostagemOng(
          texto: texto,
          origem: origem,
          imagens: imagens,
          modalParentContext: modalParentContext,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CardPainelBase(
      titulo: "6. Posts da ONG",
      icone: Icons.campaign_rounded,
      isMobile: widget.isMobile,
      botaoAcao: ElevatedButton.icon(
        onPressed: _enviandoPost ? null : _abrirModalPublicarPost,
        icon: _enviandoPost
            ? const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.post_add_rounded, size: 13, color: Colors.white),
        label: const Text(
          "Publicar",
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _corVerde,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
      conteudo: _carregando && _postsProprios.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _corVerde,
                  ),
                ),
              ),
            )
          : _erroApi != null && _postsProprios.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _corFundoSuave,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    _erroApi!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.redAccent,
                    ),
                  ),
                )
              : _postsProprios.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _corFundoSuave,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _corBordaSuave),
                      ),
                      child: const Text(
                        "Nenhuma publicação feita pela sua ONG até o momento.",
                        style: TextStyle(
                          fontSize: 11,
                          color: _corTextoSecundario,
                        ),
                      ),
                    )
                  : Column(
                      children: _postsProprios.take(3).map((post) {
                        return PostCardWidget(
                          nomeAutor: post.nomeAutor,
                          fotoAutor: post.fotoAutor,
                          dataPostagem: post.dataPostagem,
                          nomeEvento: post.nomeEvento,
                          texto: post.texto,
                          imagemUrl: post.imagemUrl,
                          curtidas: post.curtidas,
                          onCurtirApi: post.id.isNotEmpty
                              ? () => _curtirPostApi(post.id)
                              : null,
                          onCompartilhar: () =>
                              widget.onNavegar("Compartilhar Publicação"),
                          isMobile: widget.isMobile,
                        );
                      }).toList(),
                    ),
    );
  }
}

class _PostOngDetalhe {
  final String id;
  final String nomeAutor;
  final String fotoAutor;
  final String dataPostagem;
  final String nomeEvento;
  final String texto;
  final String? imagemUrl;
  final int curtidas;
  final int comentarios;
  final String statusLabel;

  const _PostOngDetalhe({
    required this.id,
    required this.nomeAutor,
    required this.fotoAutor,
    required this.dataPostagem,
    required this.nomeEvento,
    required this.texto,
    this.imagemUrl,
    required this.curtidas,
    required this.comentarios,
    required this.statusLabel,
  });
}
