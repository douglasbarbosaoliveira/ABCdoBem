// lib/voluntarios/services/voluntario_home_service.dart

import 'package:flutter/foundation.dart';
import '../../eventos/models/evento_model.dart';
import '../../eventos/services/evento_service.dart';
import '../../models/dashboard_volunteer_models.dart';
import '../../services/session_service.dart';
import 'voluntario_profile_service.dart';

class HomeDadosConsolidados {
  final VoluntarioDashboardModel dashboard;
  final List<EventoModel> eventosInscritos;
  final List<MapaJson> eventosRecomendados;
  final EventoModel? eventoDestaqueFallback;
  final List<String> titulosEventosConcluidos;

  const HomeDadosConsolidados({
    required this.dashboard,
    required this.eventosInscritos,
    required this.eventosRecomendados,
    this.eventoDestaqueFallback,
    required this.titulosEventosConcluidos,
  });
}

class VoluntarioHomeService {
  final EventoService _eventoService = EventoService();
  final VoluntarioProfileService _profileService = VoluntarioProfileService();

  // Cache em memória da sessão para evitar que "Meus Eventos" pisque ou suma ao navegar entre abas
  static List<EventoModel> _cacheInscritosSessao = <EventoModel>[];

  String _normalizarCidadeAbc(String rawCidade) {
    final lower = rawCidade.trim().toLowerCase();
    if (lower.contains('santo andr')) return 'santo andre';
    if (lower.contains('bernardo')) return 'sao bernardo';
    if (lower.contains('caetano')) return 'sao caetano';
    if (lower.contains('diadema')) return 'diadema';
    if (lower.contains('mau')) return 'maua';
    if (lower.contains('ribeir')) return 'ribeirao pires';
    if (lower.contains('rio grande')) return 'rio grande da serra';
    return '';
  }

  List<String> _extrairTitulosInscricoes(List<dynamic> minhasInscricoes) {
    final List<String> titulos = <String>[];
    for (final ins in minhasInscricoes) {
      String nomeEncontrado = '';
      try {
        final map = (ins as dynamic).toJson() as Map<String, dynamic>;
        nomeEncontrado = (map['evento']?['titulo'] ??
                map['evento']?['title'] ??
                map['titulo'] ??
                map['title'] ??
                map['eventoTitulo'] ??
                '')
            .toString()
            .trim();
      } catch (_) {
        try {
          nomeEncontrado = ((ins as dynamic).evento?.titulo ??
                  (ins as dynamic).evento?.title ??
                  '')
              .toString()
              .trim();
        } catch (_) {}
      }

      if (nomeEncontrado.isNotEmpty && !titulos.contains(nomeEncontrado)) {
        titulos.add(nomeEncontrado);
      }
    }
    return titulos;
  }

  Future<HomeDadosConsolidados> carregarPainelVoluntario({
    required String voluntarioId,
    required String nomeFallback,
    String? token,
  }) async {
    final String? tokenEfetivo = (token != null && token.trim().isNotEmpty)
        ? token.trim()
        : SessionService.instance.token;

    final String idEfetivo = voluntarioId.trim().isNotEmpty
        ? voluntarioId.trim()
        : (SessionService.instance.usuarioId ?? '');

    final perfilReal = await _profileService.buscarPerfil(
      idEfetivo,
      token: tokenEfetivo,
      forcarAtualizacao: true,
    );

    final minhasInscricoes = await _eventoService.listarMinhasInscricoes(
      idEfetivo,
      token: tokenEfetivo,
    );
    final Set<String> idsInscritos =
        minhasInscricoes.map((ins) => ins.eventoId).toSet();
    final List<String> titulosConcluidos =
        _extrairTitulosInscricoes(minhasInscricoes);

    EventoModel? proximaVagaFallback;
    EventoModel? proximoEventoInscrito;
    List<EventoModel> inscritosReais = <EventoModel>[];
    List<MapaJson> recomendadosFiltrados = <MapaJson>[];
    Map<String, EventoModel> mapaEventos = <String, EventoModel>{};

    try {
      final todasVagas = await _eventoService.listarEventos(
        token: tokenEfetivo,
        incluirEncerrados: true,
      );
      mapaEventos = <String, EventoModel>{
        for (final ev in todasVagas) ev.id: ev,
      };

      final Set<String> idsAdicionados = <String>{};

      // 1. Prioriza os objetos EventoModel que já vieram embutidos de /users/dashboard/me
      for (final ins in minhasInscricoes) {
        final String statusUp = ins.status.toUpperCase();
        if (statusUp == 'CANCELLED' || statusUp == 'REJECTED') continue;

        final EventoModel? evInscrito = ins.evento ?? mapaEventos[ins.eventoId];
        if (evInscrito != null && !idsAdicionados.contains(evInscrito.id)) {
          idsAdicionados.add(evInscrito.id);
          inscritosReais.add(
            evInscrito.copyWith(
              isInscrito: true,
              statusInscricao: ins.status,
            ),
          );
        }
      }

      // 2. Complementa com vagas marcadas no catálogo geral ou cache local
      for (final v in todasVagas) {
        if ((idsInscritos.contains(v.id) || v.isInscrito) &&
            !idsAdicionados.contains(v.id)) {
          idsAdicionados.add(v.id);
          inscritosReais.add(v);
        }
      }

      // 3. Mantém o cache da sessão caso a requisição falhe momentaneamente na troca de aba
      if (inscritosReais.isNotEmpty) {
        _cacheInscritosSessao = List<EventoModel>.from(inscritosReais);
      } else if (_cacheInscritosSessao.isNotEmpty) {
        inscritosReais = List<EventoModel>.from(_cacheInscritosSessao);
        for (final ev in inscritosReais) {
          idsAdicionados.add(ev.id);
        }
      }

      final agora = DateTime.now();
      final futurosInscritos = inscritosReais
          .where((v) => v.dataHoraInicio.isAfter(agora))
          .toList()
        ..sort((a, b) => a.dataHoraInicio.compareTo(b.dataHoraInicio));

      if (futurosInscritos.isNotEmpty) {
        proximoEventoInscrito = futurosInscritos.first;
      }

      final vagasLivres = todasVagas.where((v) {
        final jaInscrito = idsAdicionados.contains(v.id) || v.isInscrito;
        final limite = v.dataHoraInicio.subtract(const Duration(hours: 1));
        return !jaInscrito && v.vagasRestantes > 0 && agora.isBefore(limite);
      }).toList();

      if (vagasLivres.isNotEmpty) {
        proximaVagaFallback = vagasLivres.first;
      }

      // Busca recomendações de IA/ML (/recommended) + geolocalização (/nearby)
      final recomendadosBrutos =
          await _eventoService.listarRecomendadosEProximos(
        token: tokenEfetivo,
        catalogoBase: todasVagas,
      );

      recomendadosFiltrados = recomendadosBrutos.where((item) {
        final ev = item['evento'] as EventoModel;
        return !idsAdicionados.contains(ev.id) && !ev.isInscrito;
      }).toList();
    } catch (e) {
      debugPrint('VoluntarioHomeService: erro ao consolidar vagas -> $e');
      if (inscritosReais.isEmpty && _cacheInscritosSessao.isNotEmpty) {
        inscritosReais = List<EventoModel>.from(_cacheInscritosSessao);
      }
    }

    // Consolida cidades (0/7 a 7/7) e ONGs reais a partir das ações aprovadas
    final Set<String> cidadesUnicas = <String>{};
    final Set<String> ongsUnicas = <String>{};

    for (final acao in perfilReal.acoesParticipadas) {
      if (acao.isConcluidaOuAprovada) {
        if (acao.ongNome.trim().isNotEmpty) {
          ongsUnicas.add(acao.ongNome.trim().toLowerCase());
        }

        final String idEvento =
            acao.opportunityId.isNotEmpty ? acao.opportunityId : acao.id;
        final EventoModel? evDetalhe = mapaEventos[idEvento];

        String cidadeAcao = '';
        try {
          cidadeAcao = ((acao as dynamic).cidade ?? '').toString();
        } catch (_) {}

        if (cidadeAcao.isEmpty && evDetalhe != null) {
          cidadeAcao = evDetalhe.cidade;
        }

        final cidadeNorm = _normalizarCidadeAbc(cidadeAcao);
        if (cidadeNorm.isNotEmpty) {
          cidadesUnicas.add(cidadeNorm);
        }
      }
    }

    if (cidadesUnicas.isEmpty &&
        ongsUnicas.isNotEmpty &&
        perfilReal.cidade.isNotEmpty) {
      final cidadePerfil = _normalizarCidadeAbc(perfilReal.cidade);
      if (cidadePerfil.isNotEmpty) {
        cidadesUnicas.add(cidadePerfil);
      }
    }

    final metricasReais = MetricasImpactoModel(
      totalCidades: cidadesUnicas.length.clamp(0, 7),
      ongsAjudadas: ongsUnicas.length,
      horasDoadas: '${perfilReal.totalHoras}h',
      rankingEstrelas:
          perfilReal.estrelasEngajamento.toDouble().clamp(0.0, 5.0),
    );

    final dashboard = VoluntarioDashboardModel(
      voluntarioId: idEfetivo,
      nome: perfilReal.nome.isNotEmpty ? perfilReal.nome : nomeFallback,
      fotoUrl: perfilReal.fotoUrl.isNotEmpty
          ? perfilReal.fotoUrl
          : (SessionService.instance.fotoUrl ?? ''),
      cidade: perfilReal.cidade.isNotEmpty ? perfilReal.cidade : 'Grande ABC',
      metricas: metricasReais,
      proximoEvento: proximoEventoInscrito,
    );

    return HomeDadosConsolidados(
      dashboard: dashboard,
      eventosInscritos: inscritosReais,
      eventosRecomendados: recomendadosFiltrados,
      eventoDestaqueFallback: proximaVagaFallback,
      titulosEventosConcluidos: titulosConcluidos,
    );
  }
}
