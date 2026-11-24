// lib/eventos/services/evento_gestao_ong_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../services/session_service.dart';
import '../models/evento_model.dart';
import 'evento_mapper.dart';

class EventoGestaoOngService {
  final String baseUrl = "https://abc-do-bem.onrender.com";

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

  /// POST /opportunities [ONG] — Cria uma nova vaga de voluntariado
  Future<EventoModel?> criarEvento(
    CriarEventoDTO dto, {
    String? modality,
    int? durationHours,
    DateTime? endDate,
    String? cep,
    String? logradouro,
    String? numero,
    String? bairro,
    String? estado,
    int? minAge,
    String? token,
  }) async {
    final url = Uri.parse("$baseUrl/opportunities");
    final String modalidadeFinal =
        (modality != null && modality.trim().isNotEmpty)
            ? modality.trim().toUpperCase()
            : (dto.cidade.trim().toLowerCase() == "remoto"
                ? "REMOTO"
                : "PRESENCIAL");

    final int duracaoFinal = durationHours ?? 4;
    final DateTime dataFimFinal =
        endDate ?? dto.dataHoraInicio.add(Duration(hours: duracaoFinal));

    final String logradouroFinal =
        (logradouro != null && logradouro.trim().isNotEmpty)
            ? logradouro.trim()
            : dto.endereco;

    final payloadMap = <String, dynamic>{
      "title": dto.titulo,
      "description": dto.descricao,
      if (dto.imagemUrl.trim().isNotEmpty) "banner": dto.imagemUrl.trim(),
      "modality": modalidadeFinal,
      "eventDate": dto.dataHoraInicio.toUtc().toIso8601String(),
      "endDate": dataFimFinal.toUtc().toIso8601String(),
      "durationHours": duracaoFinal,
      "totalVacancies": dto.vagasTotais,
      "categories": dto.tags,
      "requiredSkills": dto.necessidades,
      "requirements": dto.requisitos,
      if (minAge != null && minAge > 0) "minAge": minAge,
      if (cep != null && cep.trim().isNotEmpty) "cep": cep.trim(),
      "logradouro": logradouroFinal,
      if (numero != null && numero.trim().isNotEmpty) "numero": numero.trim(),
      if (bairro != null && bairro.trim().isNotEmpty) "bairro": bairro.trim(),
      "cidade": dto.cidade,
      "estado":
          (estado != null && estado.trim().isNotEmpty) ? estado.trim() : "SP",
      if (dto.latitude != null) "latitude": dto.latitude,
      if (dto.longitude != null) "longitude": dto.longitude,
    };

    try {
      final res = await http
          .post(
            url,
            headers: _headers(token, jsonBody: true),
            body: jsonEncode(payloadMap),
          )
          .timeout(const Duration(seconds: 20));

      final bodyTexto = utf8.decode(res.bodyBytes);

      if (res.statusCode == 201 || res.statusCode == 200) {
        final dynamic dados = jsonDecode(bodyTexto);
        if (dados is MapaJson) {
          return EventoMapper.mapearJsonParaEvento(dados);
        }
      } else {
        String mensagemErro = "HTTP ${res.statusCode}";
        try {
          final dynamic erroJson = jsonDecode(bodyTexto);
          if (erroJson is Map && erroJson['message'] != null) {
            final dynamic msg = erroJson['message'];
            mensagemErro = msg is List ? msg.join(', ') : msg.toString();
          } else {
            mensagemErro = bodyTexto;
          }
        } catch (_) {
          if (bodyTexto.isNotEmpty) mensagemErro = bodyTexto;
        }
        throw Exception(mensagemErro);
      }
    } catch (e) {
      debugPrint("EventoGestaoOngService.criarEvento erro: $e");
      rethrow;
    }

    return null;
  }

  /// PATCH /opportunities/{id} [ONG] — Atualiza dados ou status (ATIVA, LOTADA, CONCLUIDA, CANCELADA)
  Future<EventoModel?> atualizarEvento(
    String eventoId,
    MapaJson payloadAtualizado, {
    String? token,
  }) async {
    final url = Uri.parse("$baseUrl/opportunities/$eventoId");

    try {
      final res = await http
          .patch(
            url,
            headers: _headers(token, jsonBody: true),
            body: jsonEncode(payloadAtualizado),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final dynamic dados = jsonDecode(utf8.decode(res.bodyBytes));
        if (dados is MapaJson) {
          return EventoMapper.mapearJsonParaEvento(dados);
        }
      } else {
        throw Exception(
          "Erro ao atualizar evento (${res.statusCode}): ${res.body}",
        );
      }
    } catch (e) {
      debugPrint("EventoGestaoOngService.atualizarEvento erro: $e");
      rethrow;
    }

    return null;
  }

  Future<bool> atualizarStatusEvento(
    String eventoId,
    String novoStatus, {
    String? token,
  }) async {
    final atualizado = await atualizarEvento(
      eventoId,
      <String, dynamic>{"status": novoStatus},
      token: token,
    );
    return atualizado != null;
  }

  /// POST /opportunities/{id}/finalize-certificates [ONG] — Finaliza o evento e emite certificados aos presentes
  Future<bool> finalizarEvento(String eventoId, {String? token}) async {
    final url = Uri.parse("$baseUrl/opportunities/$eventoId/finalize-certificates");

    try {
      final res = await http
          .post(
            url,
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 200 || res.statusCode == 201) {
        return true;
      } else {
        final bodyTexto = utf8.decode(res.bodyBytes);
        String mensagemErro = "HTTP ${res.statusCode}";
        try {
          final dynamic erroJson = jsonDecode(bodyTexto);
          if (erroJson is Map && erroJson['message'] != null) {
            final dynamic msg = erroJson['message'];
            mensagemErro = msg is List ? msg.join(', ') : msg.toString();
          }
        } catch (_) {}
        throw Exception(mensagemErro);
      }
    } catch (e) {
      debugPrint("EventoGestaoOngService.finalizarEvento erro: $e");
      rethrow;
    }
  }

  /// DELETE /opportunities/{id} [ONG] — Exclui uma vaga
  Future<bool> excluirEvento(String eventoId, {String? token}) async {
    try {
      final res = await http
          .delete(
            Uri.parse("$baseUrl/opportunities/$eventoId"),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 15));
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint("EventoGestaoOngService.excluirEvento erro: $e");
      return false;
    }
  }

  /// GET /opportunities/{id}/applications [ONG] — Lista voluntários inscritos na vaga
  Future<List<MapaJson>> listarCandidatosDaVaga(
    String eventoId, {
    String? token,
  }) async {
    try {
      final res = await http
          .get(
            Uri.parse("$baseUrl/opportunities/$eventoId/applications"),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is List) {
          return decoded.whereType<MapaJson>().toList();
        }
      }
    } catch (e) {
      debugPrint("EventoGestaoOngService.listarCandidatosDaVaga erro: $e");
    }
    return <MapaJson>[];
  }

  /// PATCH /opportunities/applications/{applicationId}/status [ONG]
  Future<bool> atualizarStatusCandidatura(
    String applicationId,
    String status, {
    String? token,
  }) async {
    try {
      final res = await http
          .patch(
            Uri.parse(
                "$baseUrl/opportunities/applications/$applicationId/status"),
            headers: _headers(token, jsonBody: true),
            body: jsonEncode(<String, dynamic>{"status": status}),
          )
          .timeout(const Duration(seconds: 15));
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint("EventoGestaoOngService.atualizarStatusCandidatura erro: $e");
      return false;
    }
  }

  /// PATCH /opportunities/applications/{applicationId}/presenca [ONG]
  Future<bool> validarPresencaCandidato(
    String applicationId, {
    bool presente = true,
    String? token,
  }) async {
    try {
      final res = await http
          .patch(
            Uri.parse(
              "$baseUrl/opportunities/applications/$applicationId/presenca",
            ),
            headers: _headers(token, jsonBody: true),
            body: jsonEncode(<String, dynamic>{"attended": presente}),
          )
          .timeout(const Duration(seconds: 15));
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint("EventoGestaoOngService.validarPresencaCandidato erro: $e");
      return false;
    }
  }
}