// lib/voluntarios/perfil/widgets/perfil_feed_experiencias.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../models/voluntario_profile_models.dart';
import '../../services/voluntario_profile_service.dart';
import '../../../services/session_service.dart';
import '../../../eventos/detalhe/evento_detalhe_page.dart';
import '../../../widgets/feed/post_card_widget.dart';
import 'modal_compartilhar_social.dart';

class PerfilFeedExperiencias extends StatelessWidget {
  final List<ExperienciaFeedModel> experiencias;
  final List<AcaoParticipadaVoluntarioModel> acoesParticipadas;
  final String fotoUsuario;
  final String nomeUsuario;
  final VoidCallback onPublicarNova;
  final ValueChanged<String>? onAcaoTap;
  final bool isMobile;
  final bool isMeuPerfil;

  const PerfilFeedExperiencias({
    super.key,
    required this.experiencias,
    this.acoesParticipadas = const <AcaoParticipadaVoluntarioModel>[],
    required this.fotoUsuario,
    required this.nomeUsuario,
    required this.onPublicarNova,
    this.onAcaoTap,
    required this.isMobile,
    required this.isMeuPerfil,
  });

  Widget _buildImagem(String rawUrl, {double? width, double? height}) {
    final url = VoluntarioPerfilModel.sanitizarImagem(rawUrl);
    if (url.isEmpty) return const SizedBox.shrink();

    if (url.startsWith('data:image')) {
      try {
        final Uint8List bytes = base64Decode(url.split(',').last);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        );
      } catch (_) {
        return const SizedBox.shrink();
      }
    }

    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  DateTime? _converterData(String dataStr) {
    final limpo = dataStr.trim();
    if (limpo.isEmpty || limpo == 'Recente') return null;
    if (limpo.contains('/')) {
      final partes = limpo.split('/');
      if (partes.length == 3) {
        final dia = int.tryParse(partes[0]);
        final mes = int.tryParse(partes[1]);
        final ano = int.tryParse(partes[2]);
        if (dia != null && mes != null && ano != null) {
          return DateTime(ano, mes, dia);
        }
      }
    }
    return DateTime.tryParse(limpo);
  }

  Widget _buildCardAcao(
    BuildContext context,
    AcaoParticipadaVoluntarioModel acao, {
    required bool isFuturo,
  }) {
    final String fotoOportunidade = VoluntarioPerfilModel.sanitizarImagem(
      (acao as dynamic).fotoUrl ?? '',
    );
    final bool temFoto = fotoOportunidade.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC2E4DC)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            final String idDestino =
                acao.opportunityId.isNotEmpty ? acao.opportunityId : acao.id;
            if (onAcaoTap != null && idDestino.isNotEmpty) {
              onAcaoTap!(idDestino);
            } else if (idDestino.isNotEmpty) {
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
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isFuturo
                        ? const Color(0xFFE6F7ED)
                        : const Color(0xFFD1F5EE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: temFoto
                      ? _buildImagem(fotoOportunidade, width: 48, height: 48)
                      : Icon(
                          isFuturo
                              ? Icons.event_available_rounded
                              : Icons.volunteer_activism_rounded,
                          color: isFuturo
                              ? const Color(0xFF1B8A4B)
                              : const Color(0xFF0C6B6B),
                          size: 22,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        acao.titulo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF062222),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${acao.ongNome} • ${acao.dataFormatada} • ${acao.duracaoHoras}h",
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF5A8A80),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (acao.emiteCertificado && !isFuturo)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3FC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.workspace_premium_rounded,
                          size: 13,
                          color: Color(0xFF0A66C2),
                        ),
                        SizedBox(width: 4),
                        Text(
                          "Certificado",
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A66C2),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isFuturo
                          ? const Color(0xFFE6F7ED)
                          : const Color(0xFFF2F4F4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isFuturo ? "Inscrito" : "Participou",
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isFuturo
                            ? const Color(0xFF1B8A4B)
                            : const Color(0xFF5A8A80),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);

    final List<AcaoParticipadaVoluntarioModel> proximosEventos = [];
    final List<AcaoParticipadaVoluntarioModel> eventosPassados = [];

    for (final acao in acoesParticipadas) {
      final dt = _converterData(acao.dataFormatada);
      if (dt != null && (dt.isAfter(hoje) || dt.isAtSameMomentAs(hoje))) {
        proximosEventos.add(acao);
      } else if (acao.isConcluidaOuAprovada ||
          dt == null ||
          dt.isBefore(hoje)) {
        eventosPassados.add(acao);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (proximosEventos.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Próximos Eventos",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF062222),
                ),
              ),
              Text(
                "${proximosEventos.length} ${proximosEventos.length == 1 ? 'evento' : 'eventos'}",
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7AAAA0),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...proximosEventos
              .map((acao) => _buildCardAcao(context, acao, isFuturo: true)),
          const SizedBox(height: 16),
        ],
        if (eventosPassados.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Eventos passados",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF062222),
                ),
              ),
              Text(
                "${eventosPassados.length} ${eventosPassados.length == 1 ? 'ação' : 'ações'}",
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7AAAA0),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...eventosPassados
              .map((acao) => _buildCardAcao(context, acao, isFuturo: false)),
          const SizedBox(height: 16),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isMeuPerfil
                  ? "Minhas Experiências no ABC"
                  : "Experiências no ABC",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF062222),
              ),
            ),
            if (isMeuPerfil)
              ElevatedButton.icon(
                onPressed: onPublicarNova,
                icon: const Icon(
                  Icons.add_photo_alternate_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                label: const Text(
                  "Publicar",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C6B6B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (experiencias.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFC2E4DC)),
            ),
            child: Center(
              child: Text(
                isMeuPerfil
                    ? "Nenhuma experiência publicada ainda. Compartilhe suas fotos e relatos!"
                    : "Este voluntário ainda não compartilhou relatos públicos.",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: experiencias.length,
            itemBuilder: (ctx, idx) {
              final exp = experiencias[idx];
              final expMap = exp.toJson();

              String eventoId = (expMap['opportunityId'] ??
                      expMap['eventoId'] ??
                      expMap['eventId'] ??
                      '')
                  .toString()
                  .trim();

              if (eventoId.isEmpty && exp.ongNome.isNotEmpty) {
                for (final acao in acoesParticipadas) {
                  if (acao.titulo.trim().toLowerCase() ==
                      exp.ongNome.trim().toLowerCase()) {
                    eventoId = acao.opportunityId.isNotEmpty
                        ? acao.opportunityId
                        : acao.id;
                    break;
                  }
                }
              }

              return PostCardWidget(
                nomeAutor: nomeUsuario,
                fotoAutor: fotoUsuario,
                dataPostagem: exp.dataFormatada,
                nomeEvento: exp.ongNome,
                texto: exp.texto,
                imagemUrl: exp.imagemUrl,
                curtidas: exp.curtidas,
                isMobile: isMobile,
                onEventoTap: eventoId.isNotEmpty
                    ? () {
                        if (onAcaoTap != null) {
                          onAcaoTap!(eventoId);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventoDetalhePage(
                                eventoId: eventoId,
                                usuarioAtualId:
                                    SessionService.instance.usuarioId,
                              ),
                            ),
                          );
                        }
                      }
                    : null,
                onCurtirApi: () async {
                  if (exp.id.isEmpty) return true;
                  try {
                    await (VoluntarioProfileService() as dynamic)
                        .curtirPostagem(
                      exp.id,
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
                    texto: exp.texto,
                    origem: exp.ongNome,
                    tipo: TipoCompartilhamentoSocial.experiencia,
                  );
                },
              );
            },
          ),
      ],
    );
  }
}
