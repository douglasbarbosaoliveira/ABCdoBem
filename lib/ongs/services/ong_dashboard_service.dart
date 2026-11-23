// lib/ongs/services/ong_dashboard_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/ong_dashboard_models.dart';
import '../../services/session_service.dart';

class OngDashboardService {
  final String baseUrl;

  OngDashboardService({this.baseUrl = "https://abc-do-bem.onrender.com"});

  Map<String, String> get _headers {
    final token = SessionService.instance.token?.trim();
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  /// Consolida o painel da ONG utilizando os endpoints oficiais do Swagger:
  /// 1. GET /users/{id}
  /// 2. GET /users/dashboard/ong
  /// 3. GET /opportunities/ong/{ongId}
  /// 4. GET /opportunities/{id}/applications (para fila de aprovação pendente)
  Future<OngDashboardModel> buscarDashboardOng(String ongId) async {
    final idAlvo = ongId.trim().isNotEmpty
        ? ongId.trim()
        : (SessionService.instance.usuarioId ?? '');

    if (idAlvo.isEmpty) {
      throw Exception("ID da ONG não identificado na sessão.");
    }

    final urlPerfil = Uri.parse("$baseUrl/users/$idAlvo");
    final urlDashboard = Uri.parse("$baseUrl/users/dashboard/ong");
    final urlEventos = Uri.parse("$baseUrl/opportunities/ong/$idAlvo");

    debugPrint("=== [GET] INICIANDO CARGA CONSOLIDADA DA ONG ($idAlvo) ===");

    // Executa as 3 consultas principais em paralelo
    final responses = await Future.wait([
      http
          .get(urlPerfil, headers: _headers)
          .timeout(const Duration(seconds: 30)),
      http
          .get(urlDashboard, headers: _headers)
          .timeout(const Duration(seconds: 30)),
      http
          .get(urlEventos, headers: _headers)
          .timeout(const Duration(seconds: 30)),
    ]);

    final resPerfil = responses[0];
    final resDashboard = responses[1];
    final resEventos = responses[2];

    if (resPerfil.statusCode != 200) {
      throw Exception(
          "Falha ao carregar perfil da ONG (HTTP ${resPerfil.statusCode}).");
    }

    final dadosOng =
        jsonDecode(utf8.decode(resPerfil.bodyBytes)) as Map<String, dynamic>;

    // Extrai indicadores consolidados de GET /users/dashboard/ong
    Map<String, dynamic> dadosDashboard = {};
    if (resDashboard.statusCode == 200) {
      final decodedDash = jsonDecode(utf8.decode(resDashboard.bodyBytes));
      if (decodedDash is Map<String, dynamic>) {
        dadosDashboard = decodedDash['data'] is Map<String, dynamic>
            ? decodedDash['data'] as Map<String, dynamic>
            : decodedDash;
      }
    } else {
      debugPrint(
          "Aviso: GET /users/dashboard/ong retornou HTTP ${resDashboard.statusCode}");
    }

    // Extrai eventos publicados pela ONG
    final List<EventoGerenciadoModel> eventosAtivos = [];
    List<dynamic> listaBrutaEventos = [];

    if (resEventos.statusCode == 200) {
      final decodedEventos = jsonDecode(utf8.decode(resEventos.bodyBytes));
      if (decodedEventos is List) {
        listaBrutaEventos = decodedEventos;
      } else if (decodedEventos is Map) {
        if (decodedEventos['data'] is List) {
          listaBrutaEventos = decodedEventos['data'] as List;
        } else if (decodedEventos['opportunities'] is List) {
          listaBrutaEventos = decodedEventos['opportunities'] as List;
        }
      }
    } else {
      debugPrint(
          "Aviso: GET /opportunities/ong/$idAlvo retornou HTTP ${resEventos.statusCode}");
    }

    // Fallback: se /opportunities/ong/{id} veio vazio, verifica se /users/dashboard/ong trouxe a lista
    if (listaBrutaEventos.isEmpty) {
      final dashOpps = dadosDashboard['opportunities'] ??
          dadosDashboard['eventos'] ??
          dadosDashboard['oportunidades'];
      if (dashOpps is List && dashOpps.isNotEmpty) {
        listaBrutaEventos = dashOpps;
      }
    }

    debugPrint(
        "=== [ONG DASHBOARD] Eventos encontrados para $idAlvo: ${listaBrutaEventos.length} ===");

    for (final item in listaBrutaEventos) {
      if (item is Map<String, dynamic>) {
        eventosAtivos.add(EventoGerenciadoModel.fromJson(item));
      }
    }

    // Busca candidaturas pendentes das oportunidades da ONG em paralelo
    final List<CandidatoVoluntarioModel> candidaturasPendentes = [];
    final eventosValidos = [];
    for (final ev in listaBrutaEventos) {
      if (ev is Map && (ev['id'] ?? '').toString().trim().isNotEmpty) {
        eventosValidos.add(ev);
      }
    }

    if (eventosValidos.isNotEmpty) {
      final appsResponses = await Future.wait(
        eventosValidos.map((ev) async {
          final evId = ev['id'].toString();
          final evTitulo = (ev['title'] ?? ev['titulo'] ?? '').toString();
          try {
            final urlApps =
                Uri.parse("$baseUrl/opportunities/$evId/applications");
            final resApps = await http
                .get(urlApps, headers: _headers)
                .timeout(const Duration(seconds: 15));
            return (resApps, evTitulo);
          } catch (e) {
            debugPrint("Erro ao buscar candidaturas do evento $evId: $e");
            return (null, evTitulo);
          }
        }),
      );

      for (final (resApps, evTitulo) in appsResponses) {
        if (resApps != null && resApps.statusCode == 200) {
          final decodedApps = jsonDecode(utf8.decode(resApps.bodyBytes));
          final List<dynamic> listaApps = decodedApps is List
              ? decodedApps
              : (decodedApps is Map && decodedApps['data'] is List
                  ? decodedApps['data'] as List
                  : const []);

          for (final item in listaApps) {
            if (item is! Map<String, dynamic>) continue;
            final status =
                (item['status'] ?? '').toString().toUpperCase().trim();

            if (status == 'PENDING' || status == 'PENDENTE') {
              candidaturasPendentes.add(
                CandidatoVoluntarioModel.fromJson(
                  item,
                  tituloEventoFallback: evTitulo,
                ),
              );
            }
          }
        }
      }
    }

    // Lê as métricas oficiais do endpoint /users/dashboard/ong (com fallback seguro)
    int parseInt(dynamic v) => int.tryParse((v ?? 0).toString()) ?? 0;

    final int totalVoluntariosEngajados = parseInt(
      dadosDashboard['totalVoluntariosEngajados'] ??
          dadosDashboard['voluntariosEngajados'] ??
          dadosDashboard['approvedVolunteers'],
    );

    final int vagasAbertas = parseInt(
      dadosDashboard['vagasAbertas'] ??
          dadosDashboard['openVacancies'] ??
          eventosAtivos.fold<int>(0, (acc, ev) {
            if (ev.status == 'ativo') {
              final r = ev.vagasTotais - ev.inscritosCount;
              return acc + (r > 0 ? r : 0);
            }
            return acc;
          }),
    );

    final int horasGeradas = parseInt(
      dadosDashboard['horasGeradas'] ??
          dadosDashboard['totalHours'] ??
          dadosDashboard['generatedHours'],
    );

    final int candidaturasPendentesCount =
        dadosDashboard.containsKey('candidaturasPendentesCount')
            ? parseInt(dadosDashboard['candidaturasPendentesCount'])
            : candidaturasPendentes.length;

    // Extrai necessidades atuais (priorizando o novo campo necessidadesAtuais do UpdateOngDto)
    final rawNecessidades =
        dadosOng['necessidadesAtuais'] ?? dadosOng['aceitaDoacoes'] ?? const [];

    final List<String> necessidades = rawNecessidades is List
        ? rawNecessidades.map((e) => e.toString()).toList()
        : const [];

    return OngDashboardModel(
      id: (dadosOng['id'] ?? idAlvo).toString(),
      nome: (dadosOng['name'] ??
              dadosOng['razaoSocial'] ??
              SessionService.instance.nomeUsuario ??
              'Instituição')
          .toString(),
      categoria: (dadosOng['causaPrincipal'] ??
              dadosOng['categoria'] ??
              'Impacto Social')
          .toString(),
      cidade: (dadosOng['cidade'] ?? '').toString(),
      logoUrl: (dadosOng['avatar'] ??
              dadosOng['logoUrl'] ??
              SessionService.instance.fotoUrl ??
              '')
          .toString(),
      totalVoluntariosEngajados: totalVoluntariosEngajados,
      vagasAbertas: vagasAbertas,
      horasGeradas: horasGeradas,
      candidaturasPendentesCount: candidaturasPendentesCount,
      necessidadesAtuais: necessidades,
      candidaturasPendentes: candidaturasPendentes,
      eventosAtivos: eventosAtivos,
    );
  }

  /// PATCH /opportunities/applications/{applicationId}/status
  /// PATCH /opportunities/applications/{applicationId}/status
  Future<bool> responderCandidatura(String solicitacaoId, bool aprovado) async {
    final url =
        Uri.parse("$baseUrl/opportunities/applications/$solicitacaoId/status");
    final statusEnvio = aprovado ? "ACCEPTED" : "REJECTED";

    debugPrint("=== [PATCH] RESPONDER CANDIDATURA ===");
    debugPrint("URL: $url");
    debugPrint("Payload: ${jsonEncode({"status": statusEnvio})}");

    final response = await http
        .patch(
          url,
          headers: _headers,
          body: jsonEncode({"status": statusEnvio}),
        )
        .timeout(const Duration(seconds: 20));

    final bodyTexto = utf8.decode(response.bodyBytes);
    debugPrint("Status Code PATCH Candidatura: ${response.statusCode}");
    debugPrint("Body Resposta PATCH Candidatura: $bodyTexto");

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    }

    String detalheErro = "HTTP ${response.statusCode}";
    try {
      final decoded = jsonDecode(bodyTexto);
      if (decoded is Map && decoded['message'] != null) {
        final msg = decoded['message'];
        detalheErro =
            "HTTP ${response.statusCode}:${msg is List ? msg.join(', ') : msg}";
      }
    } catch (_) {
      if (bodyTexto.isNotEmpty) {
        detalheErro = "HTTP ${response.statusCode}:$bodyTexto";
      }
    }

    throw Exception(detalheErro);
  }
  /// PATCH /users/ongs/me (Atualiza necessidadesAtuais via UpdateOngDto)
  Future<bool> atualizarNecessidades(
      String ongId, List<String> necessidades) async {
    final url = Uri.parse("$baseUrl/users/ongs/me");

    debugPrint("=== [PATCH] ATUALIZAR NECESSIDADES ONG: $url ===");

    final response = await http
        .patch(
          url,
          headers: _headers,
          body: jsonEncode({"necessidadesAtuais": necessidades}),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    }

    throw Exception(
        "Erro HTTP ${response.statusCode} ao atualizar necessidades da ONG.");
  }
}
