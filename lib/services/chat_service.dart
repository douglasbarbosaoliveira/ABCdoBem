// lib/services/chat_service.dart

import 'dart:convert';

import '../models/chat_models.dart';

/// Serviço responsável por fazer as requisições HTTP RESTful do chat.
/// Substitua [baseUrl] pelo endereço real da API (ex: https://api.abc-do-bem.com.br/v1).
class ChatService {
  final String baseUrl;
  final String? authToken; // Token JWT do usuário autenticado

  ChatService({this.baseUrl = "https://api.exemplo.com/v1", this.authToken});

  /// Headers padrão para requisições autenticadas
  Map<String, String> get _headers => {
    "Content-Type": "application/json",
    if (authToken != null) "Authorization": "Bearer $authToken",
  };

  /// 1. GET /conversas?usuarioId={id}&tipo={voluntario|ong}
  /// Retorna a lista de todas as conversas do usuário logado.
  Future<List<ChatConversation>> buscarConversas({
    required String usuarioId,
    required String tipoUsuario,
  }) async {
    // -------------------------------------------------------------
    // INTEGRAÇÃO REAL COM API:
    // final response = await http.get(
    //   Uri.parse('$baseUrl/conversas?usuarioId=$usuarioId&tipo=$tipoUsuario'),
    //   headers: _headers,
    // );
    // if (response.statusCode == 200) {
    //   final List dados = json.decode(response.body);
    //   return dados.map((c) => ChatConversation.fromJson(c)).toList();
    // } else {
    //   throw Exception('Erro ao carregar conversas: ${response.statusCode}');
    // }
    // -------------------------------------------------------------

    // SIMULAÇÃO LOCAL / MOCK DIDÁTICO (Caso API ainda esteja em desenvolvimento)
    await Future.delayed(const Duration(milliseconds: 300));

    if (tipoUsuario == 'ong') {
      // Se a ONG estiver logada, a lista exibe os voluntários interessados
      return [
        ChatConversation(
          id: "chat-101",
          interlocutorId: "vol-1",
          interlocutorNome: "Ana Carolina",
          interlocutorFoto: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400",
          interlocutorSubtitulo: "Voluntária • Santo André",
          online: true,
          naoLidas: 1,
          ultimaMensagem: ChatMessage(
            id: "m-1",
            conversaId: "chat-101",
            remetenteId: "vol-1",
            texto:
                "Que ótimo! Preciso levar algum material didático específico?",
            dataHora: DateTime.now().subtract(const Duration(minutes: 5)),
            lida: false,
          ),
        ),
        ChatConversation(
          id: "chat-102",
          interlocutorId: "vol-2",
          interlocutorNome: "Carlos Mendes",
          interlocutorFoto: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400",
          interlocutorSubtitulo: "Voluntário • São Bernardo",
          online: false,
          naoLidas: 0,
          ultimaMensagem: ChatMessage(
            id: "m-2",
            conversaId: "chat-102",
            remetenteId: "ong-1",
            texto: "Confirmamos sua presença no evento de sábado!",
            dataHora: DateTime.now().subtract(const Duration(hours: 3)),
            lida: true,
          ),
        ),
      ];
    } else {
      // Se o Voluntário estiver logado, a lista exibe as ONGs
      return [
        ChatConversation(
          id: "chat-1",
          interlocutorId: "ong-1",
          interlocutorNome: "Mãos que Fazem",
          interlocutorFoto: "https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?w=200",
          interlocutorSubtitulo: "Santo André • Educação",
          online: true,
          naoLidas: 2,
          ultimaMensagem: ChatMessage(
            id: "m-10",
            conversaId: "chat-1",
            remetenteId: "ong-1",
            texto: "Todo o material já estará separado na sala.",
            dataHora: DateTime.now().subtract(const Duration(minutes: 2)),
            lida: false,
          ),
        ),
        ChatConversation(
          id: "chat-2",
          interlocutorId: "ong-2",
          interlocutorNome: "Ação Verde ABC",
          interlocutorFoto: "https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?w=200",
          interlocutorSubtitulo: "São Bernardo • Meio Ambiente",
          online: false,
          naoLidas: 0,
          ultimaMensagem: ChatMessage(
            id: "m-20",
            conversaId: "chat-2",
            remetenteId: "ong-2",
            texto: "O ponto de encontro será na portaria principal.",
            dataHora: DateTime.now().subtract(const Duration(days: 1)),
            lida: true,
          ),
        ),
      ];
    }
  }

  /// 2. GET /conversas/{conversaId}/mensagens
  /// Carrega as mensagens de uma conversa específica.
  Future<List<ChatMessage>> buscarMensagens(String conversaId) async {
    // -------------------------------------------------------------
    // INTEGRAÇÃO REAL COM API:
    // final response = await http.get(
    //   Uri.parse('$baseUrl/conversas/$conversaId/mensagens'),
    //   headers: _headers,
    // );
    // if (response.statusCode == 200) {
    //   final List dados = json.decode(response.body);
    //   return dados.map((m) => ChatMessage.fromJson(m)).toList();
    // } else {
    //   throw Exception('Erro ao buscar mensagens');
    // }
    // -------------------------------------------------------------

    await Future.delayed(const Duration(milliseconds: 200));

    return [
      ChatMessage(
        id: "msg-1",
        conversaId: conversaId,
        remetenteId: "outro",
        texto: "Olá! Confirmamos sua solicitação para a ação voluntária.",
        dataHora: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
      ChatMessage(
        id: "msg-2",
        conversaId: conversaId,
        remetenteId: "meu_id",
        texto: "Excelente notícia! Muito obrigado pelo retorno.",
        dataHora: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      ChatMessage(
        id: "msg-3",
        conversaId: conversaId,
        remetenteId: "outro",
        texto: "Estaremos te aguardando pontualmente no local combinado!",
        dataHora: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    ];
  }

  /// 3. POST /conversas/{conversaId}/mensagens
  /// Envia uma nova mensagem para a API RESTful.
  Future<ChatMessage> enviarMensagem({
    required String conversaId,
    required String remetenteId,
    required String texto,
  }) async {
    // -------------------------------------------------------------
    // INTEGRAÇÃO REAL COM API:
    // final payload = json.encode({
    //   'remetenteId': remetenteId,
    //   'texto': texto,
    // });
    // final response = await http.post(
    //   Uri.parse('$baseUrl/conversas/$conversaId/mensagens'),
    //   headers: _headers,
    //   body: payload,
    // );
    // if (response.statusCode == 201) {
    //   return ChatMessage.fromJson(json.decode(response.body));
    // } else {
    //   throw Exception('Erro ao enviar mensagem');
    // }
    // -------------------------------------------------------------

    await Future.delayed(const Duration(milliseconds: 150));

    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversaId: conversaId,
      remetenteId: remetenteId,
      texto: texto,
      dataHora: DateTime.now(),
      lida: false,
    );
  }

  /// 4. PATCH /conversas/{conversaId}/marcar-lida
  /// Notifica a API que as mensagens pendentes foram abertas e lidas.
  Future<void> marcarComoLida(String conversaId) async {
    // -------------------------------------------------------------
    // await http.patch(
    //   Uri.parse('$baseUrl/conversas/$conversaId/marcar-lida'),
    //   headers: _headers,
    // );
    // -------------------------------------------------------------
    await Future.delayed(const Duration(milliseconds: 50));
  }
}
