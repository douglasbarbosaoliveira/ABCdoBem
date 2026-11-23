// lib/voluntarios/home/widgets/home_feed_comunidade_section.dart

import 'package:flutter/material.dart';

import '../../../services/session_service.dart';
import '../../../widgets/feed/post_card_widget.dart';
import '../../../eventos/detalhe/evento_detalhe_page.dart';
import '../../../eventos/services/evento_service.dart';
import '../../../voluntarios/models/voluntario_profile_models.dart';
import '../../services/voluntario_profile_service.dart';
import '../../perfil/widgets/modal_compartilhar_social.dart';

class HomeFeedComunidadeSection extends StatelessWidget {
  final List postagens;
  final Function(Map<String, dynamic>) onAutorTap;
  final bool isMobile;
  final bool carregando;
  final VoidCallback? onPublicar;
  final Function(Map<String, dynamic>)? onPostAtualizado;

  const HomeFeedComunidadeSection({
    super.key,
    required this.postagens,
    required this.onAutorTap,
    required this.isMobile,
    this.carregando = false,
    this.onPublicar,
    this.onPostAtualizado,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(
              child: Text(
                'Postagens da Comunidade',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF062222),
                ),
              ),
            ),
            if (onPublicar != null)
              ElevatedButton.icon(
                onPressed: onPublicar,
                icon: const Icon(Icons.edit_note_rounded,
                    size: 18, color: Colors.white),
                label: const Text(
                  'Publicar',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C6B6B),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 10 : 14,
                    vertical: isMobile ? 6 : 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (carregando)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF0C6B6B),
              ),
            ),
          )
        else if (postagens.isEmpty)
          Container(
            padding: EdgeInsets.all(isMobile ? 18 : 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0F0EC)),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.forum_outlined,
                    size: 36,
                    color: Color(0xFF7AAAA0),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Nenhuma experiência compartilhada nos últimos 10 dias.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF7AAAA0), fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Seja o primeiro a contar como foi sua ação comunitária!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
          )
        else
          ...postagens.map((item) {
            final post = item is Map<String, dynamic>
                ? item
                : Map<String, dynamic>.from(item as Map);
            return _buildPostCard(context, post);
          }),
      ],
    );
  }

  Widget _buildPostCard(BuildContext context, Map<String, dynamic> post) {
    final String postId = (post['id'] ?? post['postId'] ?? '').toString();
    final String fotoAutor = VoluntarioPerfilModel.sanitizarImagem(
      post['fotoAutor'] ?? post['autorFoto'] ?? post['author']?['avatar'],
    );
    final String iniciativa =
        (post['iniciativa'] ?? post['ongName'] ?? '').toString().trim();

    final String eventoId = (post['opportunityId'] ??
            post['eventoId'] ??
            post['eventId'] ??
            post['opportunity']?['id'] ??
            '')
        .toString()
        .trim();

    String imagemPost = '';
    if (post['images'] is List && (post['images'] as List).isNotEmpty) {
      imagemPost =
          VoluntarioPerfilModel.sanitizarImagem((post['images'] as List).first);
    } else {
      imagemPost = VoluntarioPerfilModel.sanitizarImagem(
        post['imagemPost'] ?? post['imageUrl'] ?? post['photo'],
      );
    }

    final String autor =
        (post['autor'] ?? post['autorNome'] ?? 'Membro da Comunidade')
            .toString();
    final String dataExibicao = (post['createdAt'] ??
            post['dataFormatada'] ??
            post['formattedDate'] ??
            post['tempo'] ??
            '')
        .toString();
    final String texto =
        (post['texto'] ?? post['text'] ?? post['content'] ?? '').toString();
    final int curtidas = int.tryParse(post['curtidas']?.toString() ??
            post['likesCount']?.toString() ??
            '0') ??
        0;
    final bool curtido = post['curtido'] == true || post['isLiked'] == true;

    return PostCardWidget(
      nomeAutor: autor,
      fotoAutor: fotoAutor,
      dataPostagem: dataExibicao,
      nomeEvento: iniciativa,
      texto: texto,
      imagemUrl: imagemPost.isNotEmpty ? imagemPost : null,
      curtidas: curtidas,
      curtido: curtido,
      isMobile: isMobile,
      onAutorTap: () {
        onAutorTap({
          'id': post['autorId'] ?? '',
          'tipo': (post['tipoAutor'] ?? 'VOLUNTARIO').toString().toUpperCase(),
        });
      },
      onEventoTap: (eventoId.isNotEmpty ||
              (iniciativa.isNotEmpty &&
                  iniciativa != 'Postagem Livre' &&
                  iniciativa != 'Ação Comunitária'))
          ? () async {
              String idDestino = eventoId;

              if (idDestino.isEmpty) {
                try {
                  final eventos = await EventoService().listarEventos(
                    token: SessionService.instance.token ?? '',
                  );
                  for (final ev in eventos) {
                    if (ev.titulo.trim().toLowerCase() ==
                        iniciativa.trim().toLowerCase()) {
                      idDestino = ev.id;
                      break;
                    }
                  }
                } catch (_) {}
              }

              if (idDestino.isNotEmpty && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventoDetalhePage(
                      eventoId: idDestino,
                      usuarioAtualId: SessionService.instance.usuarioId,
                    ),
                  ),
                );
              }
            }
          : null,
      onCurtirApi: () async {
        if (postId.isEmpty) return true;
        try {
          await (VoluntarioProfileService() as dynamic).curtirPostagem(
            postId,
            usuarioId: SessionService.instance.usuarioId,
            token: SessionService.instance.token,
          );
          return true;
        } catch (_) {
          return true;
        }
      },
      onCompartilhar: () {
        ModalCompartilharSocial.exibir(
          context,
          texto: texto,
          origem: iniciativa.isNotEmpty ? iniciativa : autor,
          tipo: TipoCompartilhamentoSocial.experiencia,
        );
      },
    );
  }
}
