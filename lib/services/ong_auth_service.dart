// lib/services/ong_auth_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../ongs/models/ong_cadastro_dto.dart';

class OngAuthService {
  final String baseUrl;

  OngAuthService({this.baseUrl = "https://abc-do-bem.onrender.com"});

  Map<String, String> get _headers => {
        "Content-Type": "application/json",
        "Accept": "application/json",
      };

  static String _descricaoStatusHttp(int statusCode) {
    switch (statusCode) {
      case 200:
        return "HTTP 200 OK (Sucesso)";
      case 201:
        return "HTTP 201 Created (ONG cadastrada com sucesso)";
      case 400:
        return "HTTP 400 Bad Request (Erro de validação DTO / campos inválidos)";
      case 401:
        return "HTTP 401 Unauthorized (Não autorizado)";
      case 403:
        return "HTTP 403 Forbidden (Acesso negado)";
      case 404:
        return "HTTP 404 Not Found (Endpoint /auth/ongRegister não encontrado)";
      case 409:
        return "HTTP 409 Conflict (CNPJ ou E-mail já cadastrado)";
      case 422:
        return "HTTP 422 Unprocessable Entity (Dados inválidos)";
      case 500:
        return "HTTP 500 Internal Server Error (Erro interno no servidor NestJS/Prisma)";
      case 502:
      case 503:
      case 504:
        return "HTTP $statusCode Gateway/Service Unavailable (Servidor Render acordando)";
      default:
        return "HTTP $statusCode";
    }
  }

  /// POST /auth/ongRegister
  Future<RespostaCadastroOngModel> cadastrarOng(OngCadastroDTO dto) async {
    final url = Uri.parse('$baseUrl/auth/ongRegister');
    final mapaPayload = dto.toJson();
    final payload = jsonEncode(mapaPayload);

    // Log seguro (trunca avatar base64 e oculta senha)
    final logMapa = Map<String, dynamic>.from(mapaPayload);
    if (logMapa.containsKey('password')) logMapa['password'] = '***';
    if (logMapa['avatar'] != null) {
      final av = logMapa['avatar'].toString();
      logMapa['avatar'] = av.length > 50
          ? '${av.substring(0, 50)}... (${av.length} chars)'
          : av;
    }

    

    final response = await http
        .post(
          url,
          headers: _headers,
          body: payload,
        )
        .timeout(const Duration(seconds: 45));

    final String tipoRetorno = _descricaoStatusHttp(response.statusCode);
    final String bodyTexto = utf8.decode(response.bodyBytes);

    debugPrint('=== RESPOSTA DO BACKEND (CADASTRO ONG) ===');
    debugPrint('Tipo de Retorno: $tipoRetorno');
    debugPrint('Body Bruto: $bodyTexto');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final decoded = bodyTexto.isNotEmpty
          ? jsonDecode(bodyTexto) as Map<String, dynamic>
          : <String, dynamic>{};
      return RespostaCadastroOngModel.fromJson(
        decoded,
        emailFallback: dto.emailLogin,
      );
    } else {
      String detalheBackend = bodyTexto;
      try {
        final erro = jsonDecode(bodyTexto);
        final msg = erro['message'] ?? erro['mensagem'];
        if (msg is List) {
          detalheBackend = msg.join('\n');
        } else if (msg != null) {
          detalheBackend = msg.toString();
        }
      } catch (_) {}

      throw Exception(
        "Tipo de resposta: $tipoRetorno\n"
        "Endpoint: POST $url\n"
        "Detalhe do servidor:\n$detalheBackend",
      );
    }
  }
}
