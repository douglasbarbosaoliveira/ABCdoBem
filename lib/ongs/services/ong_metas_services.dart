// lib/ongs/services/ong_metas_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../services/session_service.dart';
import '../models/ong_painel_models.dart';

class OngMetasService {
  final String baseUrl;

  const OngMetasService({this.baseUrl = 'https://abc-do-bem.onrender.com'});

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

  Future<List<OngMetaItem>> listarMetas({String? token}) async {
    final res = await http
        .get(Uri.parse('$baseUrl/ongs/me/goals'), headers: _headers(token))
        .timeout(const Duration(seconds: 12));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Não foi possível carregar as metas institucionais.');
    }

    if (res.bodyBytes.isEmpty) return const <OngMetaItem>[];

    final lista = JsonParsers.extractList(
      jsonDecode(utf8.decode(res.bodyBytes)),
      ['goals', 'metas', 'items'],
    );
    return lista.whereType<JsonMap>().map(OngMetaItem.fromJson).toList();
  }

  Future<void> criarMeta(JsonMap body, {String? token}) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/ongs/me/goals'),
          headers: _headers(token, jsonBody: true),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 12));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Não foi possível criar a meta.');
    }
  }

  Future<void> atualizarMeta(
    String goalId,
    JsonMap body, {
    String? token,
  }) async {
    final res = await http
        .patch(
          Uri.parse('$baseUrl/ongs/me/goals/$goalId'),
          headers: _headers(token, jsonBody: true),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 12));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Não foi possível atualizar a meta.');
    }
  }

  Future<void> excluirMeta(String goalId, {String? token}) async {
    final res = await http
        .delete(
          Uri.parse('$baseUrl/ongs/me/goals/$goalId'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 12));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Não foi possível excluir a meta.');
    }
  }
}
