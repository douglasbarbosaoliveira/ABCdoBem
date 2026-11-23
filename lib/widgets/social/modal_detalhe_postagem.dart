// lib/widgets/social/modal_detalhe_postagem.dart

import 'package:flutter/material.dart';

import '../../services/session_service.dart';
import '../../services/social_interaction_service.dart';
import '../../utils/responsive.dart';
import '../../voluntarios/perfil/widgets/modal_compartilhar_social.dart';

class ModalDetalhePostagem extends StatefulWidget {
  final Map<String, dynamic> postagem;
  final Function(Map<String, dynamic>)? onAutorTap;
  final Function(Map<String, dynamic>)? onPostAtualizado;

  const ModalDetalhePostagem({
    super.key,
    required this.postagem,
    this.onAutorTap,
    this.onPostAtualizado,
  });

  static Future<void> abrir({
    required BuildContext context,
    required Map<String, dynamic> postagem,
    Function(Map<String, dynamic>)? onAutorTap,
    Function(Map<String, dynamic>)? onPostAtualizado,
  }) {
    final bool isMobile = Responsive.isMobile(context);
    final mediaQuery = MediaQuery.of(context);

    if (isMobile) {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => Container(
          constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.88),
          margin: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
          child: ModalDetalhePostagem(
            postagem: postagem,
            onAutorTap: onAutorTap,
            onPostAtualizado: onPostAtualizado,
          ),
        ),
      );
    } else {
      return showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
            child: ModalDetalhePostagem(
              postagem: postagem,
              onAutorTap: onAutorTap,
              onPostAtualizado: onPostAtualizado,
            ),
          ),
        ),
      );
    }
  }

  @override
  State<ModalDetalhePostagem> createState() => _ModalDetalhePostagemState();
}

class _ModalDetalhePostagemState extends State<ModalDetalhePostagem> {
  final SocialInteractionService _socialService = SocialInteractionService();
  final TextEditingController _comentarioController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late bool _curtido;
  late int _totalCurtidas;
  late int _totalComentarios;

  List _comentarios = [];
  bool _carregandoComentarios = true;
  bool _enviandoComentario = false;

  @override
  void initState() {
    super.initState();
    _totalCurtidas =
        int.tryParse(widget.postagem['curtidas']?.toString() ?? '0') ?? 0;
    _totalComentarios =
        int.tryParse(widget.postagem['comentarios']?.toString() ?? '0') ?? 0;
    _curtido = widget.postagem['curtido'] == true;

    _carregarComentarios();
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _urlValida(String? url) {
    if (url == null) return false;
    final limpo = url.trim();
    if (limpo.isEmpty || limpo == 'string' || limpo.startsWith('data:image'))
      return false;
    return limpo.startsWith('http://') || limpo.startsWith('https://');
  }

  void _notificarMudanca() {
    if (widget.onPostAtualizado != null) {
      final mapa = Map<String, dynamic>.from(widget.postagem);
      mapa['curtidas'] = _totalCurtidas;
      mapa['comentarios'] = _totalComentarios;
      mapa['curtido'] = _curtido;
      widget.onPostAtualizado!(mapa);
    }
  }

  Future<void> _alternarCurtida() async {
    final postId = widget.postagem['id']?.toString() ?? '';
    final tipoAutor = widget.postagem['tipoAutor']?.toString() ?? 'VOLUNTARIO';

    if (SessionService.instance.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login para curtir postagens.')),
      );
      return;
    }

    setState(() {
      _curtido = !_curtido;
      _totalCurtidas += _curtido ? 1 : -1;
    });
    _notificarMudanca();

    final sucesso =
        await _socialService.alternarCurtida(postId, tipoAutor: tipoAutor);
    if (!sucesso && mounted) {
      setState(() {
        _curtido = !_curtido;
        _totalCurtidas += _curtido ? 1 : -1;
      });
      _notificarMudanca();
    }
  }

  Future<void> _carregarComentarios() async {
    final postId = widget.postagem['id']?.toString() ?? '';
    final resultado = await _socialService.buscarComentarios(postId);

    if (mounted) {
      setState(() {
        _comentarios = resultado;
        _totalComentarios = _comentarios.length;
        _carregandoComentarios = false;
      });
      _notificarMudanca();
    }
  }

  Future<void> _enviarComentario() async {
    final texto = _comentarioController.text.trim();
    final postId = widget.postagem['id']?.toString() ?? '';

    if (texto.isEmpty || postId.isEmpty) return;

    setState(() => _enviandoComentario = true);

    final sucesso = await _socialService.enviarComentario(postId, texto);
    if (!mounted) return;

    if (sucesso) {
      _comentarioController.clear();
      final novoItem = {
        'id': 'local-${DateTime.now().millisecondsSinceEpoch}',
        'autor': SessionService.instance.nomeUsuario ?? 'Você',
        'foto': '',
        'texto': texto,
        'tempo': 'Agora mesmo',
      };

      setState(() {
        _comentarios.add(novoItem);
        _totalComentarios++;
        _enviandoComentario = false;
      });
      _notificarMudanca();

      Future.delayed(const Duration(milliseconds: 200), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      setState(() => _enviandoComentario = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Não foi possível registrar o comentário no servidor.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final fotoAutor = (widget.postagem['fotoAutor'] ?? '').toString();
    final autor =
        (widget.postagem['autor'] ?? 'Membro da Comunidade').toString();
    final tempo = (widget.postagem['tempo'] ?? '').toString();
    final iniciativa = (widget.postagem['iniciativa'] ?? '').toString().trim();
    final texto = (widget.postagem['texto'] ?? '').toString();
    final imagemPost = (widget.postagem['imagemPost'] ?? '').toString();
    final tipoAutor =
        (widget.postagem['tipoAutor'] ?? 'VOLUNTARIO').toString().toUpperCase();

    final bool temFotoValida = _urlValida(fotoAutor);
    final bool temImagemPostValida = _urlValida(imagemPost);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isMobile
            ? const BorderRadius.vertical(top: Radius.circular(24))
            : BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HeaderPost(
            autor: autor,
            tempo: tempo,
            fotoAutor: fotoAutor,
            iniciativa: iniciativa,
            tipoAutor: tipoAutor,
            temFotoValida: temFotoValida,
            isMobile: isMobile,
            onFechar: () => Navigator.pop(context),
            onAutorTap: () {
              if (widget.onAutorTap != null) {
                Navigator.pop(context);
                widget.onAutorTap!({
                  'id': widget.postagem['autorId'] ?? '',
                  'tipo': tipoAutor,
                });
              }
            },
          ),
          const Divider(height: 1, thickness: 0.8, color: Color(0xFFE0F0EC)),
          Flexible(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.all(isMobile ? 14 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    texto,
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      color: const Color(0xFF264646),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (temImagemPostValida) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imagemPost,
                        width: double.infinity,
                        height: isMobile ? 180 : 260,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  _BarraAcoes(
                    curtido: _curtido,
                    totalCurtidas: _totalCurtidas,
                    totalComentarios: _totalComentarios,
                    isMobile: isMobile,
                    onCurtir: _alternarCurtida,
                    onCompartilhar: () {
                      ModalCompartilharSocial.exibir(
                        context,
                        texto: texto,
                        origem: iniciativa.isNotEmpty ? iniciativa : autor,
                        tipo: TipoCompartilhamentoSocial.experiencia,
                      );
                    },
                  ),
                  const Divider(
                      height: 20, thickness: 0.8, color: Color(0xFFE0F0EC)),
                  Text(
                    "Comentários",
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF062222),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_carregandoComentarios)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF0C6B6B),
                        ),
                      ),
                    )
                  else if (_comentarios.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        "Seja o primeiro a deixar uma mensagem de incentivo!",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    )
                  else
                    ..._comentarios.map((item) {
                      final c = item is Map<String, dynamic>
                          ? item
                          : Map<String, dynamic>.from(item as Map);
                      return _ItemComentario(
                          c: c, isMobile: isMobile, urlValida: _urlValida);
                    }),
                ],
              ),
            ),
          ),
          _InputComentarioRodape(
            controller: _comentarioController,
            enviando: _enviandoComentario,
            isMobile: isMobile,
            onEnviar: _enviandoComentario ? null : _enviarComentario,
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// Subcomponentes Modulares Internos
// -------------------------------------------------------------

class _HeaderPost extends StatelessWidget {
  final String autor;
  final String tempo;
  final String fotoAutor;
  final String iniciativa;
  final String tipoAutor;
  final bool temFotoValida;
  final bool isMobile;
  final VoidCallback onFechar;
  final VoidCallback onAutorTap;

  const _HeaderPost({
    required this.autor,
    required this.tempo,
    required this.fotoAutor,
    required this.iniciativa,
    required this.tipoAutor,
    required this.temFotoValida,
    required this.isMobile,
    required this.onFechar,
    required this.onAutorTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 14 : 20,
        isMobile ? 12 : 16,
        isMobile ? 8 : 12,
        isMobile ? 10 : 12,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAutorTap,
            child: CircleAvatar(
              radius: isMobile ? 17 : 20,
              backgroundColor: const Color(0xFFD1F5EE),
              backgroundImage: temFotoValida ? NetworkImage(fotoAutor) : null,
              child: !temFotoValida
                  ? const Icon(Icons.person, color: Color(0xFF0C6B6B), size: 20)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onAutorTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          autor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 13 : 14,
                            color: const Color(0xFF062222),
                          ),
                        ),
                      ),
                      if (tipoAutor == 'ONG') ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified,
                            size: 13, color: Color(0xFF0C6B6B)),
                      ],
                    ],
                  ),
                  Text(
                    tempo,
                    style: TextStyle(
                        fontSize: isMobile ? 10 : 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          if (iniciativa.isNotEmpty) ...[
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isMobile ? 100 : 180),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F5F1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  iniciativa,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isMobile ? 9 : 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0C6B6B),
                  ),
                ),
              ),
            ),
          ],
          IconButton(
            icon: Icon(Icons.close_rounded,
                color: Colors.grey, size: isMobile ? 22 : 24),
            onPressed: onFechar,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}

class _BarraAcoes extends StatelessWidget {
  final bool curtido;
  final int totalCurtidas;
  final int totalComentarios;
  final bool isMobile;
  final VoidCallback onCurtir;
  final VoidCallback onCompartilhar;

  const _BarraAcoes({
    required this.curtido,
    required this.totalCurtidas,
    required this.totalComentarios,
    required this.isMobile,
    required this.onCurtir,
    required this.onCompartilhar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onCurtir,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              children: [
                Icon(
                  curtido
                      ? Icons.favorite_rounded
                      : Icons.favorite_outline_rounded,
                  color: curtido ? Colors.redAccent : const Color(0xFF3A6868),
                  size: isMobile ? 18 : 20,
                ),
                const SizedBox(width: 5),
                Text(
                  "$totalCurtidas",
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.bold,
                    color: curtido ? Colors.redAccent : const Color(0xFF3A6868),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Row(
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: isMobile ? 17 : 19, color: const Color(0xFF3A6868)),
            const SizedBox(width: 5),
            Text(
              "$totalComentarios",
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3A6868),
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          icon: Icon(Icons.share_outlined,
              size: isMobile ? 18 : 20, color: const Color(0xFF3A6868)),
          tooltip: "Compartilhar",
          onPressed: onCompartilhar,
        ),
      ],
    );
  }
}

class _ItemComentario extends StatelessWidget {
  final Map<String, dynamic> c;
  final bool isMobile;
  final bool Function(String?) urlValida;

  const _ItemComentario({
    required this.c,
    required this.isMobile,
    required this.urlValida,
  });

  @override
  Widget build(BuildContext context) {
    final String foto = (c['foto'] ?? '').toString();
    final String autor = (c['autor'] ?? 'Voluntário').toString();
    final String tempo = (c['tempo'] ?? '').toString();
    final String texto = (c['texto'] ?? '').toString();
    final bool temFoto = urlValida(foto);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isMobile ? 13 : 15,
            backgroundColor: const Color(0xFFE3F5F1),
            backgroundImage: temFoto ? NetworkImage(foto) : null,
            child: !temFoto
                ? const Icon(Icons.person, size: 15, color: Color(0xFF0C6B6B))
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(isMobile ? 8 : 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FCFA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE0F0EC)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          autor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isMobile ? 11.5 : 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF062222),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tempo,
                        style: TextStyle(
                            fontSize: isMobile ? 9.5 : 10, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    texto,
                    style: TextStyle(
                      fontSize: isMobile ? 11.5 : 12,
                      color: const Color(0xFF3A6868),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputComentarioRodape extends StatelessWidget {
  final TextEditingController controller;
  final bool enviando;
  final bool isMobile;
  final VoidCallback? onEnviar;

  const _InputComentarioRodape({
    required this.controller,
    required this.enviando,
    required this.isMobile,
    required this.onEnviar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 8 : 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0F0EC))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(fontSize: isMobile ? 12.5 : 13.5),
              decoration: InputDecoration(
                hintText: "Escreva um comentário...",
                hintStyle:
                    TextStyle(fontSize: isMobile ? 12 : 13, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF0FAF7),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 14 : 16,
                  vertical: isMobile ? 8 : 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onEnviar,
            icon: enviando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF0C6B6B),
                    ),
                  )
                : const Icon(Icons.send_rounded, color: Color(0xFF0C6B6B)),
          ),
        ],
      ),
    );
  }
}
