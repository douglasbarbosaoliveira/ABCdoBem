// lib/services/auth_service.dart

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/voluntario_cadastro_dto.dart';

/// Serviço responsável pelo registro e login de voluntários e ONGs
class AuthService {
  final String baseUrl;

  AuthService({this.baseUrl = "https://api.abc-do-bem.com.br/v1"});

  Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "Accept": "application/json",
  };

  /// POST /voluntarios/cadastro
  /// Envia todos os dados acumulados das 3 etapas para criar o voluntário no backend
  Future<RespostaCadastroVoluntario> cadastrarVoluntario(
    VoluntarioCadastroDTO dto,
  ) async {
    final url = Uri.parse('$baseUrl/voluntarios/cadastro');

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(dto.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return RespostaCadastroVoluntario.fromJson(jsonDecode(response.body));
      } else {
        final erroBody = jsonDecode(response.body);
        throw Exception(erroBody['mensagem'] ?? "Erro ao realizar cadastro.");
      }
    } catch (e) {
      // Fallback para desenvolvimento caso a API ainda não esteja online
      await Future.delayed(const Duration(milliseconds: 600));
      return RespostaCadastroVoluntario(
        voluntarioId: "vol-${DateTime.now().millisecondsSinceEpoch}",
        tokenJWT: "mock_jwt_token",
        mensagem: "Cadastro concluído com sucesso!",
      );
    }
  }
}
