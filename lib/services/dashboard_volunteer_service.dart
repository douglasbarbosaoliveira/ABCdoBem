// lib/services/dashboard_volunteer_service.dart

import 'package:flutter/foundation.dart';
import '../models/dashboard_volunteer_models.dart';
import '../eventos/models/evento_model.dart';
import '../eventos/services/evento_service.dart';
import '../voluntarios/services/voluntario_profile_service.dart';
import 'session_service.dart';

/// Serviço que fornece os dados reais agregados da página inicial do voluntário
class DashboardService {
  final String? authToken;

  DashboardService({this.authToken});

  String get _tokenAtual => (authToken != null && authToken!.trim().isNotEmpty)
      ? authToken!.trim()
      : (SessionService.instance.token ?? '');

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

  /// Busca 100% dos dados reais do perfil e das ações do voluntário na API
  Future<VoluntarioDashboardModel> buscarDashboard(String voluntarioId) async {
    final String idReal = (voluntarioId.trim().isEmpty ||
            voluntarioId == 'voluntario-1' ||
            voluntarioId == 'meu-perfil')
        ? (SessionService.instance.usuarioId ?? voluntarioId)
        : voluntarioId;

    debugPrint('================ [DEBUG DASHBOARD HOME] ================');
    debugPrint('1. idReal resolvido: "$idReal"');
    debugPrint('2. token presente?: ${_tokenAtual.isNotEmpty}');

    final profileService = VoluntarioProfileService();
    final perfil = await profileService.buscarPerfil(
      idReal,
      token: _tokenAtual,
      forcarAtualizacao: true, // <-- Ignora cache antigo em memória
    );

    debugPrint('3. Perfil retornado -> Nome: ${perfil.nome}');
    debugPrint(
        '4. Perfil retornado -> TotalHoras: ${perfil.totalHoras}, TotalEventos: ${perfil.totalEventos}, Estrelas: ${perfil.estrelasEngajamento}');
    debugPrint(
        '5. Qtd acoesParticipadas no perfil: ${perfil.acoesParticipadas.length}');

    Map<String, EventoModel> mapaEventos = {};
    try {
      final eventosCatalogo =
          await EventoService().listarEventos(token: _tokenAtual);
      mapaEventos = {for (final ev in eventosCatalogo) ev.id: ev};
    } catch (e) {
      debugPrint('Erro ao listar catálogo de eventos: $e');
    }

    final Set<String> cidadesUnicas = {};
    final Set<String> ongsUnicas = {};
    EventoModel? proximoEventoReal;
    final agora = DateTime.now();

    for (final acao in perfil.acoesParticipadas) {
      debugPrint(
          '   -> Ação: "${acao.titulo}" | ONG: "${acao.ongNome}" | Status: ${acao.isConcluidaOuAprovada}');
      final String idEvento =
          acao.opportunityId.isNotEmpty ? acao.opportunityId : acao.id;
      final EventoModel? evDetalhe = mapaEventos[idEvento];

      if (acao.isConcluidaOuAprovada) {
        if (acao.ongNome.trim().isNotEmpty) {
          ongsUnicas.add(acao.ongNome.trim().toLowerCase());
        }

        String cidadeAcao = '';
        try {
          cidadeAcao = ((acao as dynamic).cidade ?? '').toString();
        } catch (_) {}

        if (cidadeAcao.isEmpty && evDetalhe != null) {
          cidadeAcao = evDetalhe.cidade;
        }

        final cidadeNormalizada = _normalizarCidadeAbc(cidadeAcao);
        if (cidadeNormalizada.isNotEmpty) {
          cidadesUnicas.add(cidadeNormalizada);
        }
      }

      if (evDetalhe != null && evDetalhe.dataHoraInicio.isAfter(agora)) {
        if (proximoEventoReal == null ||
            evDetalhe.dataHoraInicio
                .isBefore(proximoEventoReal.dataHoraInicio)) {
          proximoEventoReal = evDetalhe;
        }
      }
    }

    if (cidadesUnicas.isEmpty &&
        ongsUnicas.isNotEmpty &&
        perfil.cidade.isNotEmpty) {
      final cidadePerfil = _normalizarCidadeAbc(perfil.cidade);
      if (cidadePerfil.isNotEmpty) {
        cidadesUnicas.add(cidadePerfil);
      }
    }

    final metricasFinais = MetricasImpactoModel(
      totalCidades: cidadesUnicas.length.clamp(0, 7),
      ongsAjudadas: ongsUnicas.length,
      horasDoadas: "${perfil.totalHoras}h",
      rankingEstrelas: perfil.estrelasEngajamento.toDouble().clamp(0.0, 5.0),
    );

    debugPrint(
        '6. MÉTRICAS FINAIS CALCULADAS -> Cidades: ${metricasFinais.cidadesFormatadas} | ONGs: ${metricasFinais.ongsAjudadas} | Horas: ${metricasFinais.horasDoadas} | Ranking: ${metricasFinais.rankingEstrelas}');
    debugPrint('========================================================');

    return VoluntarioDashboardModel(
      voluntarioId: idReal,
      nome: perfil.nome.isNotEmpty
          ? perfil.nome
          : (SessionService.instance.nomeUsuario ?? 'Voluntário'),
      fotoUrl: perfil.fotoUrl.isNotEmpty
          ? perfil.fotoUrl
          : (SessionService.instance.fotoUrl ?? ''),
      cidade: perfil.cidade.isNotEmpty ? perfil.cidade : 'Grande ABC',
      metricas: metricasFinais,
      proximoEvento: proximoEventoReal,
      ongProxima: null,
    );
  }
}
