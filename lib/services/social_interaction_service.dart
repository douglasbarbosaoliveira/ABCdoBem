// lib/services/social_interaction_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'session_service.dart';

class SocialInteractionService {
  final String baseUrl = "https://abc-do-bem.onrender.com";

  String? _obterToken() => SessionService.instance.token;

  /// Alterna a curtida da postagem (POST /social/postagens/{id}/curtir)
  Future<bool> alternarCurtida(String postId,
      {String tipoAutor = 'VOLUNTARIO'}) async {
    final token = _obterToken();
    if (token == null || token.isEmpty || postId.isEmpty) return false;

    final String rota = tipoAutor.toUpperCase() == 'VOLUNTARIO'
        ? "$baseUrl/social/voluntarios/experiencias/$postId/curtir"
        : "$baseUrl/social/postagens/$postId/curtir";

    final headers = {
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    try {
      final response = await http
          .post(Uri.parse(rota), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        return true;
      }

      // Fallback para rota global de postagens
      final fallbackUrl = Uri.parse("$baseUrl/social/postagens/$postId/curtir");
      final fbResponse = await http
          .post(fallbackUrl, headers: headers)
          .timeout(const Duration(seconds: 8));

      return fbResponse.statusCode == 200 ||
          fbResponse.statusCode == 201 ||
          fbResponse.statusCode == 204;
    } catch (e) {
      debugPrint("Erro ao alternar curtida: $e");
      return false;
    }
  }

  /// Busca a lista de comentários da postagem
  Future<List> buscarComentarios(String postId) async {
    final token = _obterToken();
    if (postId.isEmpty) return [];

    final headers = {
      "Accept": "application/json",
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };

    final urls = [
      Uri.parse("$baseUrl/social/postagens/$postId/comentarios"),
      Uri.parse("$baseUrl/social/voluntarios/experiencias/$postId/comentarios"),
    ];

    for (final url in urls) {
      try {
        final response = await http
            .get(url, headers: headers)
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
          final List raw = decoded is List ? decoded : (decoded['data'] ?? []);

          final List normalizada = [];
          for (final item in raw) {
            if (item is! Map) continue;
            final user = item['user'] is Map ? item['user'] as Map : null;
            normalizada.add({
              'id': item['id'] ?? '',
              'autor': user?['nome'] ?? item['autor'] ?? 'Voluntário',
              'foto': user?['avatar'] ?? item['foto'] ?? '',
              'texto': item['texto'] ?? item['text'] ?? '',
              'tempo': item['formattedDate'] ?? 'Recentemente',
            });
          }
          return normalizada;
        }
      } catch (_) {}
    }
    return [];
  }

  /// Envia um novo comentário para o servidor
  Future<bool> enviarComentario(String postId, String texto) async {
    final token = _obterToken();
    if (token == null ||
        token.isEmpty ||
        postId.isEmpty ||
        texto.trim().isEmpty) {
      return false;
    }

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    final payload = jsonEncode({
      "texto": texto.trim(),
      "text": texto.trim(),
    });

    final urls = [
      Uri.parse("$baseUrl/social/postagens/$postId/comentarios"),
      Uri.parse("$baseUrl/social/voluntarios/experiencias/$postId/comentarios"),
    ];

    for (final url in urls) {
      try {
        final response = await http
            .post(url, headers: headers, body: payload)
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200 || response.statusCode == 201) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }
}
