// lib/eventos/services/event_detail_service.dart

import '../../services/session_service.dart';
import '../models/event_detail_models.dart';
import 'evento_service.dart';

class EventDetailService {
  final EventoService _eventoService = EventoService();

  // Cache leve em memória apenas para os eventos reais carregados durante a sessão
  static final Map<String, EventoDetalheCompletoModel> _detalhesCache = {};

  static void invalidarCache([String? eventoId]) {
    if (eventoId != null && eventoId.trim().isNotEmpty) {
      _detalhesCache.remove(eventoId.trim());
    } else {
      _detalhesCache.clear();
    }
  }

  /// Busca os detalhes completos de um evento específico diretamente da API (GET /opportunities/{id})
  Future<EventoDetalheCompletoModel> buscarDetalhesEvento(
    String eventoId, {
    String? voluntarioId,
    bool forcarAtualizacao = false,
  }) async {
    final String idLimpo = eventoId.trim();

    if (!forcarAtualizacao && _detalhesCache.containsKey(idLimpo)) {
      return _detalhesCache[idLimpo]!;
    }

    final raw = await _eventoService.buscarDetalhesBrutosPorId(idLimpo);
    final eventoBase = await _eventoService.buscarPorId(
      idLimpo,
      voluntarioId: voluntarioId,
    );

    if (eventoBase == null) {
      throw Exception("Oportunidade não encontrada na API.");
    }

    // Extrai dados complementares vindos do payload bruto de GET /opportunities/{id}
    final Map<String, dynamic> ongMap = raw?['ong'] is Map<String, dynamic>
        ? raw!['ong'] as Map<String, dynamic>
        : <String, dynamic>{};

    final String ongLogoReal = (ongMap['avatar'] ??
            ongMap['logoUrl'] ??
            ongMap['fotoUrl'] ??
            raw?['ongLogo'] ??
            '')
        .toString()
        .trim();

    final String estadoReal =
        (raw?['estado'] ?? 'SP').toString().trim().isNotEmpty
            ? (raw?['estado'] ?? 'SP').toString().trim()
            : 'SP';

    final String bairroStr = (raw?['bairro'] ?? '').toString().trim();
    final String localNomeReal = bairroStr.isNotEmpty
        ? "$bairroStr - ${eventoBase.cidade}"
        : (eventoBase.endereco ?? eventoBase.cidade);

    final String dicasTrajeto = (raw?['comoChegar'] ??
            raw?['dicasTrajeto'] ??
            "Detalhes adicionais de ponto de encontro são alinhados com a ONG após confirmação.")
        .toString()
        .trim();

    // Extrai participantes confirmados caso o endpoint retorne lista de inscritos/applications
    final List<ParticipanteEventoModel> participantesReais = [];
    final dynamic rawApps = raw?['applications'] ?? raw?['participantes'];
    if (rawApps is List) {
      for (final item in rawApps) {
        if (item is Map<String, dynamic>) {
          final status = (item['status'] ?? '').toString().toUpperCase();
          if (status == 'REJECTED' || status == 'CANCELLED') continue;

          final userMap = item['user'] is Map<String, dynamic>
              ? item['user'] as Map<String, dynamic>
              : item;

          final pId = (userMap['id'] ?? item['userId'] ?? '').toString();
          final pNome =
              (userMap['name'] ?? userMap['nome'] ?? 'Voluntário').toString();
          final pCidade = (userMap['cidade'] ?? eventoBase.cidade).toString();
          final pFoto = (userMap['avatar'] ??
                  userMap['fotoUrl'] ??
                  userMap['photo'] ??
                  '')
              .toString();

          if (pId.isNotEmpty) {
            participantesReais.add(
              ParticipanteEventoModel(
                id: pId,
                nome: pNome,
                cidade: pCidade,
                fotoUrl: pFoto,
              ),
            );
          }
        }
      }
    }

    final int inscritosReais =
        (eventoBase.vagasTotais - eventoBase.vagasRestantes)
            .clamp(0, eventoBase.vagasTotais);

    final detalheReal = EventoDetalheCompletoModel(
      id: eventoBase.id,
      ongId: eventoBase.ongId,
      ongNome: eventoBase.ongNome,
      ongLogo: ongLogoReal,
      titulo: eventoBase.titulo,
      descricao: eventoBase.descricao,
      data: eventoBase.data,
      horario: eventoBase.horario,
      cidade: eventoBase.cidade,
      estado: estadoReal,
      localNome: localNomeReal,
      enderecoCompleto:
          eventoBase.endereco ?? "${eventoBase.cidade} - $estadoReal",
      comoChegarDicas: dicasTrajeto,
      imagemUrl: eventoBase.imagemUrl,
      vagasTotais: eventoBase.vagasTotais,
      vagasRestantes: eventoBase.vagasRestantes,
      inscritosCount: inscritosReais,
      jaInscrito: eventoBase.isInscrito,
      statusInscricao: eventoBase.isInscrito
          ? (eventoBase.statusInscricao ?? "inscrito")
          : "disponivel",
      tags: eventoBase.tags,
      necessidadesOng: eventoBase.necessidades.isNotEmpty
          ? eventoBase.necessidades
          : const ["Apoio presencial geral na data"],
      precisoDeOpcoes: const [
        "Carona saindo da estação CPTM / terminal",
        "Apoio com trajeto",
      ],
      possoOferecerOpcoes: const [
        "Posso oferecer carona",
        "Posso levar materiais",
      ],
      participantesConfirmados: participantesReais,
    );

    _detalhesCache[idLimpo] = detalheReal;
    return detalheReal;
  }

  /// Submete a solicitação de participação do voluntário na API (POST /opportunities/{id}/apply)
  Future<bool> solicitarInscricaoEvento({
    required String eventoId,
    required String voluntarioId,
    required List<String> precisoDe,
    required List<String> possoOferecer,
    required String observacoes,
  }) async {
    final String? tipoCarona = precisoDe.isNotEmpty
        ? "PRECISO_DE_CARONA"
        : (possoOferecer.isNotEmpty ? "OFERECO_CARONA" : null);

    final List<String> partesDetalhes = [
      if (precisoDe.isNotEmpty) "Preciso de: ${precisoDe.join(', ')}",
      if (possoOferecer.isNotEmpty)
        "Posso oferecer: ${possoOferecer.join(', ')}",
      if (observacoes.trim().isNotEmpty) "Obs: ${observacoes.trim()}",
    ];

    final bool sucesso = await _eventoService.inscreverVoluntario(
      eventoId,
      voluntarioId,
      tipoCarona: tipoCarona,
      detalhesCarona:
          partesDetalhes.isNotEmpty ? partesDetalhes.join(' | ') : null,
    );

    if (sucesso) {
      final atual = _detalhesCache[eventoId];
      if (atual != null) {
        final novosParticipantes = List<ParticipanteEventoModel>.from(
          atual.participantesConfirmados,
        );

        final uid = voluntarioId.trim().isNotEmpty
            ? voluntarioId.trim()
            : (SessionService.instance.usuarioId ?? '');

        if (uid.isNotEmpty && !novosParticipantes.any((p) => p.id == uid)) {
          novosParticipantes.insert(
            0,
            ParticipanteEventoModel(
              id: uid,
              nome: SessionService.instance.nomeUsuario ?? "Você",
              cidade: SessionService.instance.cidade ?? atual.cidade,
              fotoUrl: SessionService.instance.fotoUrl ?? "",
            ),
          );
        }

        _detalhesCache[eventoId] = EventoDetalheCompletoModel(
          id: atual.id,
          ongId: atual.ongId,
          ongNome: atual.ongNome,
          ongLogo: atual.ongLogo,
          titulo: atual.titulo,
          descricao: atual.descricao,
          data: atual.data,
          horario: atual.horario,
          cidade: atual.cidade,
          estado: atual.estado,
          localNome: atual.localNome,
          enderecoCompleto: atual.enderecoCompleto,
          comoChegarDicas: atual.comoChegarDicas,
          imagemUrl: atual.imagemUrl,
          vagasTotais: atual.vagasTotais,
          vagasRestantes:
              (atual.vagasRestantes - 1).clamp(0, atual.vagasTotais),
          inscritosCount:
              (atual.inscritosCount + 1).clamp(0, atual.vagasTotais),
          jaInscrito: true,
          statusInscricao: "PENDING",
          tags: atual.tags,
          necessidadesOng: atual.necessidadesOng,
          precisoDeOpcoes: [
            ...atual.precisoDeOpcoes,
            ...precisoDe.where((p) => !atual.precisoDeOpcoes.contains(p)),
          ],
          possoOferecerOpcoes: [
            ...atual.possoOferecerOpcoes,
            ...possoOferecer
                .where((o) => !atual.possoOferecerOpcoes.contains(o)),
          ],
          participantesConfirmados: novosParticipantes,
        );
      }
    }

    return sucesso;
  }

  /// Cancela a participação prévia do voluntário na API (DELETE /opportunities/{id}/apply)
  Future<bool> cancelarInscricaoEvento({
    required String eventoId,
    required String voluntarioId,
    required String motivo,
  }) async {
    final bool sucesso = await _eventoService.cancelarInscricao(
      eventoId,
      voluntarioId,
      motivo: motivo,
    );

    if (sucesso) {
      final atual = _detalhesCache[eventoId];
      if (atual != null) {
        final novosParticipantes = atual.participantesConfirmados
            .where((p) => p.id != voluntarioId)
            .toList();

        _detalhesCache[eventoId] = EventoDetalheCompletoModel(
          id: atual.id,
          ongId: atual.ongId,
          ongNome: atual.ongNome,
          ongLogo: atual.ongLogo,
          titulo: atual.titulo,
          descricao: atual.descricao,
          data: atual.data,
          horario: atual.horario,
          cidade: atual.cidade,
          estado: atual.estado,
          localNome: atual.localNome,
          enderecoCompleto: atual.enderecoCompleto,
          comoChegarDicas: atual.comoChegarDicas,
          imagemUrl: atual.imagemUrl,
          vagasTotais: atual.vagasTotais,
          vagasRestantes:
              (atual.vagasRestantes + 1).clamp(0, atual.vagasTotais),
          inscritosCount:
              (atual.inscritosCount - 1).clamp(0, atual.vagasTotais),
          jaInscrito: false,
          statusInscricao: "cancelado",
          tags: atual.tags,
          necessidadesOng: atual.necessidadesOng,
          precisoDeOpcoes: atual.precisoDeOpcoes,
          possoOferecerOpcoes: atual.possoOferecerOpcoes,
          participantesConfirmados: novosParticipantes,
        );
      }
    }

    return sucesso;
  }
}
