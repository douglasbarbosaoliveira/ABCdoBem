// lib/mensagens/services/chat_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../services/session_service.dart';
import '../models/chat_models.dart';

class ChatService {
  final String baseUrl;
  final String? authToken;

  ChatService({
    this.baseUrl = "https://abc-do-bem.onrender.com",
    this.authToken,
  });

  String? get _tokenFinal => (authToken != null && authToken!.trim().isNotEmpty)
      ? authToken!.trim()
      : SessionService.instance.token;

  Map<String, String> get _headers => {
        "Content-Type": "application/json",
        "Accept": "application/json",
        if (_tokenFinal != null && _tokenFinal!.isNotEmpty)
          "Authorization": "Bearer $_tokenFinal",
      };

  /// 1. GET /chat/conversations
  Future<List<ChatConversation>> buscarConversas({
    required String usuarioId,
    required String tipoUsuario,
  }) async {
    final uri = Uri.parse('$baseUrl/chat/conversations');
    

    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));

      debugPrint("Status Code Conversas: ${response.statusCode}");

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          final List<dynamic> lista = decoded;
          return lista
              .where((item) => item is Map<String, dynamic>)
              .map((c) => ChatConversation.fromJson(c as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint("Erro ao buscar conversas na API: $e");
    }

    return [];
  }

  /// 2. GET /chat/conversations/{id}/messages
  Future<List<ChatMessage>> buscarMensagens(String conversationId) async {
    final uri =
        Uri.parse('$baseUrl/chat/conversations/$conversationId/messages');
    

    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));

      debugPrint("Status Code Mensagens: ${response.statusCode}");

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          final List<dynamic> lista = decoded;
          return lista
              .where((item) => item is Map<String, dynamic>)
              .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint("Erro ao buscar mensagens na API: $e");
    }

    return [];
  }

  /// 3. POST /chat/conversations/{id}/messages
  Future<ChatMessage> enviarMensagem({
    required String conversaId,
    required String remetenteId,
    required String texto,
  }) async {
    final uri = Uri.parse('$baseUrl/chat/conversations/$conversaId/messages');
    final payload = json.encode({
      'content': texto,
      'text': texto,
    });

    try {
      final response = await http
          .post(uri, headers: _headers, body: payload)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final dynamic data = json.decode(utf8.decode(response.bodyBytes));
        if (data is Map<String, dynamic>) {
          return ChatMessage.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint("Erro ao enviar mensagem na API: $e");
    }

    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversaId: conversaId,
      remetenteId: remetenteId,
      texto: texto,
      dataHora: DateTime.now(),
      lida: false,
    );
  }

  /// 4. PATCH /chat/conversations/{id}/read
  Future<void> marcarComoLida(String conversationId) async {
    final uri = Uri.parse('$baseUrl/chat/conversations/$conversationId/read');

    try {
      final response = await http
          .patch(uri, headers: _headers)
          .timeout(const Duration(seconds: 5));

      debugPrint("Status Code Marcar Lida: ${response.statusCode}");
    } catch (e) {
      debugPrint("Erro ao marcar mensagens como lidas na API: $e");
    }
  }
}
