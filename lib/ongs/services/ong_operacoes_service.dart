// lib/ongs/services/ong_operacoes_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../services/session_service.dart';
import '../models/ong_painel_models.dart';

class OngOperacoesService {
  final String baseUrl;

  const OngOperacoesService({
    this.baseUrl = 'https://abc-do-bem.onrender.com',
  });

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

  Future<void> validarPresencaVoluntario(
    String applicationId, {
    required bool presente,
    String? feedback,
    String? token,
  }) async {
    final res = await http
        .patch(
          Uri.parse(
              '$baseUrl/opportunities/applications/$applicationId/presenca'),
          headers: _headers(token, jsonBody: true),
          body: jsonEncode(<String, dynamic>{
            'presente': presente,
            'attended': presente,
            if (feedback != null && feedback.trim().isNotEmpty)
              'feedback': feedback.trim(),
          }),
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Não foi possível registrar a presença.');
    }
  }

  Future<void> finalizarCertificadosEvento(
    String opportunityId, {
    String? token,
  }) async {
    final res = await http
        .post(
          Uri.parse(
              '$baseUrl/opportunities/$opportunityId/finalize-certificates'),
          headers: _headers(token, jsonBody: true),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Não foi possível finalizar e emitir certificados.');
    }
  }

  Future<void> publicarPostOng(JsonMap body, {String? token}) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/social/ongs/postagens'),
          headers: _headers(token, jsonBody: true),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Não foi possível publicar no mural.');
    }
  }
}
