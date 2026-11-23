// lib/eventos/services/evento_inscricao_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../services/session_service.dart';
import '../models/evento_model.dart';
import 'evento_discovery_service.dart';
import 'evento_mapper.dart';

typedef MapaInscricoes = Map<String, String>;

class EventoInscricaoService {
  final String baseUrl = "https://abc-do-bem.onrender.com";
  final EventoDiscoveryService _discoveryService = EventoDiscoveryService();

  // Cache em memória estático para persistir as inscrições na sessão ativa
  static final MapaInscricoes _cacheInscricoesLocais = <String, String>{};

  String? _obterToken(String? tokenParametro) {
    if (tokenParametro != null && tokenParametro.trim().isNotEmpty) {
      return tokenParametro.trim();
    }
    return SessionService.instance.token;
  }

  Map<String, String> _headers(String? tokenParametro,
      {bool jsonBody = false}) {
    final tokenFinal = _obterToken(tokenParametro);
    return <String, String>{
      "Accept": "application/json",
      if (jsonBody) "Content-Type": "application/json",
      if (tokenFinal != null && tokenFinal.isNotEmpty)
        "Authorization": "Bearer $tokenFinal",
    };
  }

  Future<void> registrarInscricaoLocal(
    String vagaId, {
    String status = "PENDING",
  }) async {
    _cacheInscricoesLocais[vagaId] = status;
  }

  Future<void> removerInscricaoLocal(String vagaId) async {
    _cacheInscricoesLocais.remove(vagaId);
  }

  Future<MapaInscricoes> obterInscricoesLocais() async {
    return MapaInscricoes.from(_cacheInscricoesLocais);
  }

  /// GET /users/dashboard/me — Histórico de candidaturas do voluntário logado
  Future<List<InscricaoEventoModel>> listarMinhasInscricoes(
    String voluntarioId, {
    String? token,
  }) async {
    final tokenFinal = _obterToken(token);
    final url = Uri.parse("$baseUrl/users/dashboard/me");
    final List<InscricaoEventoModel> resultado = <InscricaoEventoModel>[];

    try {
      final res = await http
          .get(url, headers: _headers(tokenFinal))
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final dynamic dados = jsonDecode(utf8.decode(res.bodyBytes));

        dynamic rawInscricoes;
        if (dados is Map) {
          rawInscricoes = dados['applications'] ??
              dados['inscricoes'] ??
              dados['candidaturas'] ??
              dados['historico'] ??
              dados['history'] ??
              dados['data']?['applications'] ??
              dados['user']?['applications'];
        } else if (dados is List) {
          rawInscricoes = dados;
        }

        if (rawInscricoes is List) {
          for (final dynamic item in rawInscricoes) {
            if (item is MapaJson) {
              final dynamic opp =
                  item['opportunity'] ?? item['vaga'] ?? item['evento'];
              EventoModel? ev;
              if (opp is MapaJson) {
                ev = EventoMapper.mapearJsonParaEvento(opp).copyWith(
                  isInscrito: true,
                  statusInscricao: item['status']?.toString() ?? 'PENDING',
                );
              }

              final String vagaId =
                  (item['opportunityId'] ?? item['eventoId'] ?? ev?.id ?? '')
                      .toString();
              final String statusReal = item['status']?.toString() ?? 'PENDING';

              if (vagaId.isNotEmpty) {
                _cacheInscricoesLocais[vagaId] = statusReal;
              }

              resultado.add(
                InscricaoEventoModel(
                  id: item['id']?.toString() ?? '',
                  eventoId: vagaId,
                  voluntarioId: item['userId']?.toString() ?? voluntarioId,
                  status: statusReal,
                  autorizouContato: item['autorizouContato'] == true,
                  criadoEm:
                      DateTime.tryParse(item['createdAt']?.toString() ?? '') ??
                          DateTime.now(),
                  evento: ev,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint("EventoInscricaoService.listarMinhasInscricoes erro: $e");
    }

    final locais = await obterInscricoesLocais();
    if (locais.isNotEmpty) {
      final todasVagas = await _discoveryService.listarEventos(
        token: tokenFinal,
        incluirEncerrados: true,
        inscricoesLocais: locais,
      );
      final Map<String, EventoModel> mapaVagas = <String, EventoModel>{
        for (final v in todasVagas) v.id: v,
      };

      for (final entry in locais.entries) {
        final vagaId = entry.key;
        final status = entry.value;

        final jaExiste = resultado.any((ins) => ins.eventoId == vagaId);
        if (!jaExiste) {
          resultado.add(
            InscricaoEventoModel(
              id: "local-$vagaId",
              eventoId: vagaId,
              voluntarioId: voluntarioId,
              status: status,
              autorizouContato: true,
              criadoEm: DateTime.now(),
              evento: mapaVagas[vagaId],
            ),
          );
        }
      }
    }

    return resultado;
  }

  /// POST /opportunities/{id}/apply — Inscreve o voluntário logado na vaga
  Future<bool> inscreverVoluntario(
    String eventoId,
    String voluntarioId, {
    String? tipoCarona,
    String? detalhesCarona,
    String? token,
  }) async {
    final url = Uri.parse("$baseUrl/opportunities/$eventoId/apply");
    final payload = <String, dynamic>{
      if (tipoCarona != null && tipoCarona.trim().isNotEmpty)
        "tipoCarona": tipoCarona.trim(),
      if (detalhesCarona != null && detalhesCarona.trim().isNotEmpty)
        "detalhesCarona": detalhesCarona.trim(),
    };

    try {
      final res = await http
          .post(
            url,
            headers: _headers(token, jsonBody: true),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      final bodyTexto = utf8.decode(res.bodyBytes);

      if (res.statusCode == 200 ||
          res.statusCode == 201 ||
          res.statusCode == 409) {
        await registrarInscricaoLocal(eventoId, status: "PENDING");
        return true;
      }

      String mensagemApi = "HTTP ${res.statusCode}";
      try {
        final dynamic erroJson = jsonDecode(bodyTexto);
        if (erroJson is Map && erroJson['message'] != null) {
          final dynamic msg = erroJson['message'];
          mensagemApi =
              "HTTP ${res.statusCode}: ${msg is List ? msg.join(', ') : msg}";
        } else if (bodyTexto.isNotEmpty) {
          mensagemApi = "HTTP ${res.statusCode}: $bodyTexto";
        }
      } catch (_) {
        if (bodyTexto.isNotEmpty) {
          mensagemApi = "HTTP ${res.statusCode}: $bodyTexto";
        }
      }

      throw Exception(mensagemApi);
    } catch (e) {
      debugPrint("EventoInscricaoService.inscreverVoluntario erro: $e");
      rethrow;
    }
  }

  /// DELETE /opportunities/{id}/apply — Cancela a candidatura do voluntário
  Future<bool> cancelarInscricao(
    String eventoId,
    String voluntarioId, {
    String? token,
    String? motivo,
  }) async {
    final url = Uri.parse("$baseUrl/opportunities/$eventoId/apply");

    try {
      final res = await http.delete(
        url,
        headers: _headers(token, jsonBody: true),
        body: jsonEncode(<String, dynamic>{"motivo": motivo}),
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        await removerInscricaoLocal(eventoId);
        return true;
      }
    } catch (e) {
      debugPrint("EventoInscricaoService.cancelarInscricao erro: $e");
    }

    await removerInscricaoLocal(eventoId);
    return true;
  }
}
