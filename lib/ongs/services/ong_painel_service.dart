// lib/ongs/services/ong_painel_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../services/session_service.dart';
import '../models/ong_painel_models.dart';
import '../painel_geral/widgets/secao_dashboard_impacto.dart';
import '../services/ong_metas_services.dart';
import 'ong_operacoes_service.dart';
import 'ong_suprimentos_service.dart';

export '../models/ong_painel_models.dart';
export '../services/ong_metas_services.dart';
export 'ong_operacoes_service.dart';
export 'ong_suprimentos_service.dart';

class OngPainelService {
  final String baseUrl = 'https://abc-do-bem.onrender.com';

  late final OngMetasService metasService = OngMetasService(baseUrl: baseUrl);
  late final OngSuprimentosService suprimentosService =
      OngSuprimentosService(baseUrl: baseUrl);
  late final OngOperacoesService operacoesService =
      OngOperacoesService(baseUrl: baseUrl);

  Map<String, String> _headers(String? token, {bool jsonBody = false}) {
    final String? t = (token != null && token.trim().isNotEmpty)
        ? token.trim()
        : SessionService.instance.token;
    return <String, String>{
      'Accept': 'application/json',
      if (jsonBody) 'Content-Type': 'application/json',
      if (t != null && t.isNotEmpty) 'Authorization': 'Bearer $t',
    };
  }

  String _queryPeriodo(
    PeriodoIndicadores periodo, {
    bool ultimos30Dias = false,
  }) {
    if (ultimos30Dias) return 'last_30_days';
    switch (periodo) {
      case PeriodoIndicadores.semanal:
        return 'weekly';
      case PeriodoIndicadores.mensal:
        return 'monthly';
      case PeriodoIndicadores.anual:
        return 'yearly';
    }
  }

  bool _dentroDoPeriodo(
    DateTime? data,
    PeriodoIndicadores periodo, {
    bool ultimos30Dias = false,
  }) {
    if (data == null) return true;
    final agora = DateTime.now();
    if (ultimos30Dias) {
      return data.isAfter(agora.subtract(const Duration(days: 30)));
    }
    switch (periodo) {
      case PeriodoIndicadores.semanal:
        return data.isAfter(agora.subtract(const Duration(days: 7)));
      case PeriodoIndicadores.mensal:
        return data.year == agora.year && data.month == agora.month;
      case PeriodoIndicadores.anual:
        return data.year == agora.year;
    }
  }

  Future<OngPainelDados> carregarPainelOng(
    String ongId, {
    String? token,
    PeriodoIndicadores periodo = PeriodoIndicadores.mensal,
    bool ultimos30Dias = false,
  }) async {
    final headers = _headers(token);

    JsonMap perfil = <String, dynamic>{};
    JsonMap dashboardApi = <String, dynamic>{};
    List<dynamic> oportunidadesRaw = <dynamic>[];
    List<dynamic> metasRaw = <dynamic>[];
    List<dynamic> suprimentosRaw = <dynamic>[];
    List<dynamic> postagensRaw = <dynamic>[];

    // 1. Perfil da ONG
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/users/$ongId'), headers: headers)
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        perfil =
            JsonParsers.extractObject(jsonDecode(utf8.decode(res.bodyBytes)));
      }
    } catch (e) {
      debugPrint('OngPainelService: erro ao buscar perfil -> $e');
    }

    // 2. Dashboard da ONG (/users/dashboard/ong)
    try {
      final periodoParam = _queryPeriodo(periodo, ultimos30Dias: ultimos30Dias);
      final res = await http
          .get(
            Uri.parse('$baseUrl/users/dashboard/ong?period=$periodoParam'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is JsonMap) {
          dashboardApi = JsonParsers.extractObject(decoded);
        }
      }
    } catch (e) {
      debugPrint('OngPainelService: erro em /users/dashboard/ong -> $e');
    }

    // 3. Oportunidades/ações da ONG (/opportunities/ong/{ongId})
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/opportunities/ong/$ongId'), headers: headers)
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        oportunidadesRaw = JsonParsers.extractList(
          jsonDecode(utf8.decode(res.bodyBytes)),
          ['opportunities', 'acoes', 'events', 'items'],
        );
      }
    } catch (e) {
      debugPrint('OngPainelService: erro em /opportunities/ong/$ongId -> $e');
    }

    // 4. Metas institucionais (/ongs/me/goals)
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/ongs/me/goals'), headers: headers)
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        metasRaw = JsonParsers.extractList(
          jsonDecode(utf8.decode(res.bodyBytes)),
          ['goals', 'metas', 'items'],
        );
      }
    } catch (e) {
      debugPrint('OngPainelService: erro em /ongs/me/goals -> $e');
    }

    // 5. Suprimentos / ERP de doações (/ongs/me/supplies)
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/ongs/me/supplies'), headers: headers)
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        suprimentosRaw = JsonParsers.extractList(
          jsonDecode(utf8.decode(res.bodyBytes)),
          ['supplies', 'suprimentos', 'items'],
        );
      }
    } catch (e) {
      debugPrint('OngPainelService: erro em /ongs/me/supplies -> $e');
    }

    // 6. Postagens da ONG (/social/ongs/{ongId}/postagens)
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/social/ongs/$ongId/postagens'),
              headers: headers)
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        postagensRaw = JsonParsers.extractList(
          jsonDecode(utf8.decode(res.bodyBytes)),
          ['posts', 'postagens', 'items'],
        );
      }
    } catch (e) {
      debugPrint(
          'OngPainelService: erro em /social/ongs/$ongId/postagens -> $e');
    }

    // Monta ações + conta inscrições/voluntários
    final List<OngAcaoResumo> acoes = <OngAcaoResumo>[];
    final Map<String, VoluntarioGuardiaoResumo> mapaVoluntarios =
        <String, VoluntarioGuardiaoResumo>{};

    int vagasOcupadasPeriodo = 0;
    int vagasOfertaPeriodo = 0;
    int horasPeriodo = 0;

    for (final raw in oportunidadesRaw) {
      if (raw is! JsonMap) continue;
      final String id = (raw['id'] ?? '').toString();
      final String titulo = (raw['title'] ?? raw['titulo'] ?? '').toString();
      final int vagasTotais = JsonParsers.toInt(
        raw['totalVacancies'] ?? raw['vagasTotais'],
        fallback: 0,
      );
      final int duracaoHoras = JsonParsers.toInt(
        raw['durationHours'] ?? raw['duracaoHoras'],
        fallback: 0,
      );
      final String status = (raw['status'] ?? 'ATIVA').toString();

      List<dynamic> inscricoes = raw['applications'] as List? ?? <dynamic>[];
      if (inscricoes.isEmpty && id.isNotEmpty) {
        try {
          final resApps = await http
              .get(Uri.parse('$baseUrl/opportunities/$id/applications'),
                  headers: headers)
              .timeout(const Duration(seconds: 8));
          if (resApps.statusCode == 200) {
            inscricoes = JsonParsers.extractList(
              jsonDecode(utf8.decode(resApps.bodyBytes)),
              ['applications', 'inscricoes', 'items'],
            );
          }
        } catch (_) {}
      }

      int presentesOuInscritos = 0;
      for (final app in inscricoes) {
        if (app is! JsonMap) continue;
        final String appStatus = (app['status'] ?? '').toString().toUpperCase();
        if (appStatus == 'REJECTED' ||
            appStatus == 'CANCELLED' ||
            appStatus == 'CANCELED') {
          continue;
        }
        presentesOuInscritos += 1;

        final volObj = app['volunteer'] is JsonMap
            ? app['volunteer'] as JsonMap
            : (app['user'] is JsonMap
                ? app['user'] as JsonMap
                : <String, dynamic>{});
        final String volId =
            (app['volunteerId'] ?? app['userId'] ?? volObj['id'] ?? '')
                .toString();
        final String volNome = (volObj['name'] ??
                volObj['nome'] ??
                app['volunteerName'] ??
                'Voluntário')
            .toString();
        final String? volAvatar =
            (volObj['avatar'] ?? volObj['fotoUrl'])?.toString();

        final bool presente = app['presente'] == true ||
            app['attended'] == true ||
            appStatus == 'PRESENT' ||
            appStatus == 'ATTENDED' ||
            appStatus == 'COMPLETED';

        final int horasApp = presente
            ? JsonParsers.toInt(
                app['horasGeradas'] ?? app['earnedHours'],
                fallback: duracaoHoras,
              )
            : 0;

        if (volId.isNotEmpty) {
          final anterior = mapaVoluntarios[volId];
          mapaVoluntarios[volId] = VoluntarioGuardiaoResumo(
            id: volId,
            nome: volNome,
            avatarUrl: volAvatar,
            acoesConcluidas: (anterior?.acoesConcluidas ?? 0) +
                (presente || appStatus == 'APPROVED' ? 1 : 0),
            horasAcumuladas: (anterior?.horasAcumuladas ?? 0) + horasApp,
          );
        }
      }

      final int vagasOcupadas = presentesOuInscritos > 0
          ? presentesOuInscritos
          : JsonParsers.toInt(
              raw['acceptedCount'] ?? raw['_count']?['applications'],
              fallback: 0,
            );

      String dataFmt = '';
      String horaFmt = '';
      final dtRaw =
          DateTime.tryParse((raw['eventDate'] ?? raw['data'] ?? '').toString())
              ?.toLocal();
      if (dtRaw != null) {
        const meses = [
          'Jan',
          'Fev',
          'Mar',
          'Abr',
          'Mai',
          'Jun',
          'Jul',
          'Ago',
          'Set',
          'Out',
          'Nov',
          'Dez'
        ];
        const dias = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
        dataFmt =
            '${dias[dtRaw.weekday % 7]}, ${dtRaw.day.toString().padLeft(2, '0')}/${meses[dtRaw.month - 1]}';
        horaFmt =
            '${dtRaw.hour.toString().padLeft(2, '0')}:${dtRaw.minute.toString().padLeft(2, '0')}';
      }

      if (_dentroDoPeriodo(dtRaw, periodo, ultimos30Dias: ultimos30Dias)) {
        vagasOcupadasPeriodo += vagasOcupadas;
        vagasOfertaPeriodo += vagasTotais;
        horasPeriodo += vagasOcupadas * duracaoHoras;
      }

      acoes.add(
        OngAcaoResumo(
          id: id,
          titulo: titulo,
          dataFormatada: dataFmt,
          horarioFormatado: horaFmt,
          dataEvento: dtRaw,
          vagasOcupadas: vagasOcupadas,
          vagasTotais: vagasTotais,
          duracaoHoras: duracaoHoras,
          status: status,
        ),
      );
    }

    final voluntariosLista = mapaVoluntarios.values.toList()
      ..sort((a, b) => b.acoesConcluidas.compareTo(a.acoesConcluidas));

    final int recorrentes =
        voluntariosLista.where((v) => v.acoesConcluidas > 1).length;
    final int retencaoCalculada = voluntariosLista.isEmpty
        ? 0
        : ((recorrentes / voluntariosLista.length) * 100).round();

    final int vagasPctCalculado = vagasOfertaPeriodo <= 0
        ? 0
        : ((vagasOcupadasPeriodo / vagasOfertaPeriodo) * 100)
            .clamp(0, 100)
            .round();

    final int horasDoadas = JsonParsers.toInt(
      dashboardApi['horasDoadas'] ?? dashboardApi['totalHours'],
      fallback: horasPeriodo,
    );
    final int pctVagas = JsonParsers.toInt(
      dashboardApi['percentualVagasPreenchidas'] ??
          dashboardApi['occupancyRate'],
      fallback: vagasPctCalculado,
    );
    final int pctRetencao = JsonParsers.toInt(
      dashboardApi['percentualRetencaoVoluntarios'] ??
          dashboardApi['retentionRate'],
      fallback: retencaoCalculada,
    );

    final double valorArrecadado = JsonParsers.toDouble(
      dashboardApi['valorArrecadadoDinheiro'] ??
          dashboardApi['arrecadadoDinheiro'] ??
          dashboardApi['cashRaised'] ??
          dashboardApi['donationsAmount'],
      fallback: 0,
    );

    final double gastosTotal = JsonParsers.toDouble(
      dashboardApi['gastos'] ??
          dashboardApi['despesas'] ??
          dashboardApi['expenses'],
      fallback: 0,
    );

    final String nomeOngResolvido =
        (perfil['name'] ?? perfil['nome'] ?? 'ONG').toString();
    final String? avatarOngResolvido =
        (perfil['avatar'] ?? perfil['logoUrl'])?.toString();

    final String ongIdLimpo = ongId.trim();
    final List<UltimoPostOngResumo> publicacoesOng = <UltimoPostOngResumo>[];
    for (final rawPost in postagensRaw) {
      if (rawPost is! JsonMap) continue;

      final String tipoAutor = (rawPost['authorType'] ??
              rawPost['tipoAutor'] ??
              rawPost['role'] ??
              '')
          .toString()
          .trim()
          .toUpperCase();
      if (tipoAutor == 'VOLUNTEER' || tipoAutor == 'VOLUNTARIO') {
        continue;
      }

      final String autorId = (rawPost['authorId'] ??
              rawPost['ongId'] ??
              rawPost['userId'] ??
              rawPost['author']?['id'] ??
              rawPost['ong']?['id'] ??
              '')
          .toString()
          .trim();

      if (autorId.isNotEmpty && autorId != ongIdLimpo) {
        continue;
      }

      publicacoesOng.add(
        UltimoPostOngResumo.fromJson(
          rawPost,
          nomeOngFallback: nomeOngResolvido,
          avatarOngFallback: avatarOngResolvido,
        ),
      );
    }

    final UltimoPostOngResumo? ultimoPost =
        publicacoesOng.isNotEmpty ? publicacoesOng.first : null;

    return OngPainelDados(
      nomeOng: nomeOngResolvido,
      avatarOng: avatarOngResolvido,
      cidadeOng: (perfil['cidade'] ?? 'Grande ABC').toString(),
      horasDoadas: horasDoadas,
      percentualVagasPreenchidas: pctVagas,
      percentualRetencaoVoluntarios: pctRetencao,
      valorArrecadadoDinheiro: valorArrecadado,
      gastos: gastosTotal,
      acoes: acoes,
      voluntariosGuardioes: voluntariosLista,
      metas: metasRaw.whereType<JsonMap>().map(OngMetaItem.fromJson).toList(),
      suprimentos: suprimentosRaw
          .whereType<JsonMap>()
          .map(OngSuprimentoItem.fromJson)
          .toList(),
      publicacoesOng: publicacoesOng,
      ultimoPost: ultimoPost,
    );
  }

  Future<OngPainelDados> carregarMetricasPorPeriodo(
    String ongId, {
    required PeriodoIndicadores periodo,
    String? token,
  }) {
    return carregarPainelOng(
      ongId,
      token: token,
      periodo: periodo,
      ultimos30Dias: false,
    );
  }

  // ---------------------------------------------------------------------------
  // Metas institucionais (/ongs/me/goals)
  // ---------------------------------------------------------------------------

  Future<List<OngMetaItem>> listarMetasOng({String? token}) async {
    final res = await http
        .get(Uri.parse('$baseUrl/ongs/me/goals'), headers: _headers(token))
        .timeout(const Duration(seconds: 12));

    if (res.statusCode != 200) {
      throw Exception('Falha ao listar metas (${res.statusCode}).');
    }

    final listaRaw = JsonParsers.extractList(
      jsonDecode(utf8.decode(res.bodyBytes)),
      ['goals', 'metas', 'items'],
    );
    return listaRaw.whereType<JsonMap>().map(OngMetaItem.fromJson).toList();
  }

  JsonMap _montarPayloadMeta(
    OngMetaItem meta, {
    DateTime? dataInicio,
    DateTime? dataFim,
  }) {
    return <String, dynamic>{
      'title': meta.titulo,
      'titulo': meta.titulo,
      'currentValue': meta.valorAtual,
      'valorAtual': meta.valorAtual,
      'targetValue': meta.valorMeta,
      'valorMeta': meta.valorMeta,
      'unit': meta.unidade,
      'unidade': meta.unidade,
      if (dataInicio != null) ...{
        'startDate': dataInicio.toUtc().toIso8601String(),
        'dataInicio': dataInicio.toUtc().toIso8601String(),
      },
      if (dataFim != null) ...{
        'endDate': dataFim.toUtc().toIso8601String(),
        'dataFim': dataFim.toUtc().toIso8601String(),
      },
    };
  }

  Future<void> salvarMetaInstitucional(
    OngMetaItem meta, {
    required bool isEdicao,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? token,
  }) async {
    final payload = _montarPayloadMeta(
      meta,
      dataInicio: dataInicio,
      dataFim: dataFim,
    );

    if (isEdicao && meta.id.isNotEmpty && !meta.id.startsWith('mock-')) {
      await metasService.atualizarMeta(meta.id, payload, token: token);
    } else {
      await metasService.criarMeta(payload, token: token);
    }
  }

  Future<void> removerMetaInstitucional(String goalId, {String? token}) async {
    if (goalId.isEmpty || goalId.startsWith('mock-')) return;
    await metasService.excluirMeta(goalId, token: token);
  }

  Future<void> criarMeta(JsonMap body, {String? token}) =>
      metasService.criarMeta(body, token: token);

  Future<void> atualizarMeta(String goalId, JsonMap body, {String? token}) =>
      metasService.atualizarMeta(goalId, body, token: token);

  Future<void> excluirMeta(String goalId, {String? token}) =>
      metasService.excluirMeta(goalId, token: token);

  // ---------------------------------------------------------------------------
  // Ações / Oportunidades (/opportunities)
  // ---------------------------------------------------------------------------

  Future<void> salvarAcaoOng(
    OngAcaoResumo acao, {
    required bool isEdicao,
    String? token,
  }) async {
    final String statusApi =
        acao.status.toLowerCase().contains('conclu') ? 'CONCLUIDA' : 'ATIVA';

    final payload = <String, dynamic>{
      'title': acao.titulo,
      'totalVacancies': acao.vagasTotais,
      'durationHours': acao.duracaoHoras,
      'status': statusApi,
      if (acao.dataEvento != null)
        'eventDate': acao.dataEvento!.toUtc().toIso8601String(),
    };

    if (isEdicao &&
        acao.id.isNotEmpty &&
        !acao.id.startsWith('acao-fallback-')) {
      final res = await http
          .patch(
            Uri.parse('$baseUrl/opportunities/${acao.id}'),
            headers: _headers(token, jsonBody: true),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('Erro ao atualizar ação (${res.statusCode}).');
      }
    } else {
      final res = await http
          .post(
            Uri.parse('$baseUrl/opportunities'),
            headers: _headers(token, jsonBody: true),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('Erro ao criar ação (${res.statusCode}).');
      }
    }
  }

  Future<void> excluirAcaoOng(String opportunityId, {String? token}) async {
    if (opportunityId.isEmpty || opportunityId.startsWith('acao-fallback-')) {
      return;
    }
    final res = await http
        .delete(
          Uri.parse('$baseUrl/opportunities/$opportunityId'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Erro ao excluir ação (${res.statusCode}).');
    }
  }

  // ---------------------------------------------------------------------------
  // Suprimentos (/ongs/me/supplies)
  // ---------------------------------------------------------------------------

  Future<List<OngSuprimentoItem>> listarSuprimentosPublicosOng(
    String ongId, {
    String? token,
  }) =>
      suprimentosService.listarSuprimentosPublicosOng(ongId, token: token);

  Future<void> criarSuprimento(JsonMap body, {String? token}) =>
      suprimentosService.criarSuprimento(body, token: token);

  Future<void> atualizarSuprimento(
    String supplyId,
    JsonMap body, {
    String? token,
  }) =>
      suprimentosService.atualizarSuprimento(supplyId, body, token: token);

  Future<void> excluirSuprimento(String supplyId, {String? token}) =>
      suprimentosService.excluirSuprimento(supplyId, token: token);

  Future<void> registrarCompromissoDoacao(
    String supplyId,
    JsonMap body, {
    String? token,
  }) =>
      suprimentosService.registrarCompromissoDoacao(supplyId, body,
          token: token);

  Future<void> atualizarStatusCompromisso(
    String pledgeId,
    String status, {
    String? token,
  }) =>
      suprimentosService.atualizarStatusCompromisso(pledgeId, status,
          token: token);

  // ---------------------------------------------------------------------------
  // Operações adicionais & Social (/social/ongs/postagens)
  // ---------------------------------------------------------------------------

  Future<void> validarPresencaVoluntario(
    String applicationId, {
    required bool presente,
    String? feedback,
    String? token,
  }) =>
      operacoesService.validarPresencaVoluntario(
        applicationId,
        presente: presente,
        feedback: feedback,
        token: token,
      );

  Future<void> finalizarCertificadosEvento(
    String opportunityId, {
    String? token,
  }) =>
      operacoesService.finalizarCertificadosEvento(opportunityId, token: token);

  Future<void> publicarPostOng(JsonMap body, {String? token}) async {
    final uri = Uri.parse('$baseUrl/social/ongs/postagens');
    final headers = _headers(token, jsonBody: true);
    final encoded = jsonEncode(body);

    debugPrint('[SOCIAL][POST_ONG] $uri');
    debugPrint('[SOCIAL][POST_ONG][PAYLOAD] $encoded');

    final res = await http
        .post(uri, headers: headers, body: encoded)
        .timeout(const Duration(seconds: 12));

    final corpo = utf8.decode(res.bodyBytes);
    debugPrint('[SOCIAL][POST_ONG][STATUS] ${res.statusCode}');
    debugPrint('[SOCIAL][POST_ONG][BODY] $corpo');

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'Não foi possível publicar no mural da ONG (HTTP ${res.statusCode}): ${corpo.isNotEmpty ? corpo : 'sem corpo na resposta'}',
      );
    }
  }

  Future<bool> curtirPostOng(String postId, {String? token}) async {
    if (postId.trim().isEmpty) return false;
    final res = await http
        .post(
          Uri.parse('$baseUrl/social/ongs/postagens/$postId/like'),
          headers: _headers(token, jsonBody: true),
        )
        .timeout(const Duration(seconds: 10));
    return res.statusCode >= 200 && res.statusCode < 300;
  }
}
