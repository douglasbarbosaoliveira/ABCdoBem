// lib/ongs/services/ong_suprimentos_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../services/session_service.dart';
import '../models/ong_painel_models.dart';

class OngSuprimentosService {
  final String baseUrl;

  const OngSuprimentosService({
    this.baseUrl = 'https://abc-do-bem.onrender.com',
  });

  String? _resolverToken(String? token) {
    if (token != null && token.trim().isNotEmpty) {
      return token.trim();
    }
    final sessaoToken = SessionService.instance.token?.trim();
    if (sessaoToken != null && sessaoToken.isNotEmpty) {
      return sessaoToken;
    }
    return null;
  }

  Map<String, String> _headers(String? token, {bool jsonBody = false}) {
    final String? t = _resolverToken(token);
    return <String, String>{
      'Accept': 'application/json',
      if (jsonBody) 'Content-Type': 'application/json',
      if (t != null && t.isNotEmpty) 'Authorization': 'Bearer $t',
    };
  }

  String _formatarErroHttp(String acao, http.Response res) {
    final corpo = utf8.decode(res.bodyBytes).trim();
    if (corpo.isEmpty) {
      return '$acao (HTTP ${res.statusCode} - resposta vazia).';
    }
    return '$acao (HTTP ${res.statusCode}): $corpo';
  }

  void _logRequisicao({
    required String metodo,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) {
    final temAuth = headers.containsKey('Authorization');
    debugPrint('[SUPRIMENTOS][$metodo] $uri');
    debugPrint('[SUPRIMENTOS][AUTH] Bearer presente: $temAuth');
    if (body != null) {
      debugPrint('[SUPRIMENTOS][PAYLOAD] $body');
    }
  }

  void _logResposta(String metodo, http.Response res) {
    final corpo = utf8.decode(res.bodyBytes);
    debugPrint('[SUPRIMENTOS][$metodo][STATUS] ${res.statusCode}');
    debugPrint('[SUPRIMENTOS][$metodo][BODY] $corpo');
  }

  Future<List<OngSuprimentoItem>> listarMeusSuprimentos({String? token}) async {
    final uri = Uri.parse('$baseUrl/ongs/me/supplies');
    final headers = _headers(token);
    _logRequisicao(metodo: 'GET_ME', uri: uri, headers: headers);

    final res = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 12));

    _logResposta('GET_ME', res);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        _formatarErroHttp(
            'Não foi possível carregar os suprimentos da ONG', res),
      );
    }
    if (res.bodyBytes.isEmpty) return const <OngSuprimentoItem>[];

    final lista = JsonParsers.extractList(
      jsonDecode(utf8.decode(res.bodyBytes)),
      ['supplies', 'suprimentos', 'items'],
    );
    return lista.whereType<JsonMap>().map(OngSuprimentoItem.fromJson).toList();
  }

  Future<List<OngSuprimentoItem>> listarSuprimentosPublicosOng(
    String ongId, {
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl/ongs/$ongId/supplies');
    final headers = _headers(token);
    _logRequisicao(metodo: 'GET_PUBLIC', uri: uri, headers: headers);

    final res = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 12));

    _logResposta('GET_PUBLIC', res);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        _formatarErroHttp(
            'Não foi possível carregar os suprimentos da ONG', res),
      );
    }
    if (res.bodyBytes.isEmpty) return const <OngSuprimentoItem>[];

    final lista = JsonParsers.extractList(
      jsonDecode(utf8.decode(res.bodyBytes)),
      ['supplies', 'suprimentos', 'items'],
    );
    return lista.whereType<JsonMap>().map(OngSuprimentoItem.fromJson).toList();
  }

  Future<void> criarSuprimento(JsonMap body, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ongs/me/supplies');
    final headers = _headers(token, jsonBody: true);
    final encoded = jsonEncode(body);

    _logRequisicao(metodo: 'POST', uri: uri, headers: headers, body: encoded);

    final res = await http
        .post(uri, headers: headers, body: encoded)
        .timeout(const Duration(seconds: 12));

    _logResposta('POST', res);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        _formatarErroHttp(
          'Não foi possível cadastrar o item de suprimento',
          res,
        ),
      );
    }
  }

  Future<void> atualizarSuprimento(
    String supplyId,
    JsonMap body, {
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl/ongs/me/supplies/$supplyId');
    final headers = _headers(token, jsonBody: true);
    final encoded = jsonEncode(body);

    _logRequisicao(metodo: 'PATCH', uri: uri, headers: headers, body: encoded);

    final res = await http
        .patch(uri, headers: headers, body: encoded)
        .timeout(const Duration(seconds: 12));

    _logResposta('PATCH', res);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        _formatarErroHttp(
          'Não foi possível atualizar o item de suprimento',
          res,
        ),
      );
    }
  }

  Future<void> excluirSuprimento(String supplyId, {String? token}) async {
    final uri = Uri.parse('$baseUrl/ongs/me/supplies/$supplyId');
    final headers = _headers(token);

    _logRequisicao(metodo: 'DELETE', uri: uri, headers: headers);

    final res = await http
        .delete(uri, headers: headers)
        .timeout(const Duration(seconds: 12));

    _logResposta('DELETE', res);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        _formatarErroHttp(
          'Não foi possível excluir o item de suprimento',
          res,
        ),
      );
    }
  }

  Future<void> registrarCompromissoDoacao(
    String supplyId,
    JsonMap body, {
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl/ongs/supplies/$supplyId/pledges');
    final headers = _headers(token, jsonBody: true);
    final encoded = jsonEncode(body);

    _logRequisicao(
      metodo: 'POST_PLEDGE',
      uri: uri,
      headers: headers,
      body: encoded,
    );

    final res = await http
        .post(uri, headers: headers, body: encoded)
        .timeout(const Duration(seconds: 12));

    _logResposta('POST_PLEDGE', res);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        _formatarErroHttp(
          'Não foi possível registrar o compromisso de doação',
          res,
        ),
      );
    }
  }

  Future<void> atualizarStatusCompromisso(
    String pledgeId,
    String status, {
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl/ongs/me/supplies/pledges/$pledgeId/status');
    final headers = _headers(token, jsonBody: true);
    final encoded = jsonEncode(<String, dynamic>{'status': status});

    _logRequisicao(
      metodo: 'PATCH_PLEDGE',
      uri: uri,
      headers: headers,
      body: encoded,
    );

    final res = await http
        .patch(uri, headers: headers, body: encoded)
        .timeout(const Duration(seconds: 12));

    _logResposta('PATCH_PLEDGE', res);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        _formatarErroHttp('Não foi possível atualizar o status da doação', res),
      );
    }
  }
}
