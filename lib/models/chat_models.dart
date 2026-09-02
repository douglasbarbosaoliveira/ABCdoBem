// lib/models/chat_models.dart

/// Representa uma mensagem individual trocada no chat.
class ChatMessage {
  final String id;
  final String conversaId;
  final String remetenteId;
  final String texto;
  final DateTime dataHora;
  final bool lida;

  ChatMessage({
    required this.id,
    required this.conversaId,
    required this.remetenteId,
    required this.texto,
    required this.dataHora,
    this.lida = false,
  });

  /// Factory para converter a resposta JSON da API RESTful no modelo Dart.
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      conversaId: json['conversaId']?.toString() ?? '',
      remetenteId: json['remetenteId']?.toString() ?? '',
      texto: json['texto'] ?? '',
      dataHora: json['dataHora'] != null
          ? DateTime.tryParse(json['dataHora'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lida: json['lida'] ?? false,
    );
  }

  /// Converte o objeto para JSON no envio via POST.
  Map<String, dynamic> toJson() {
    return {
      'conversaId': conversaId,
      'remetenteId': remetenteId,
      'texto': texto,
    };
  }

  /// Retorna o horário formatado em HH:mm
  String get horarioFormatado {
    final hora = dataHora.hour.toString().padLeft(2, '0');
    final minuto = dataHora.minute.toString().padLeft(2, '0');
    return '$hora:$minuto';
  }
}

/// Representa um item da lista de conversas ativas.
/// É genérico: se o usuário logado for Voluntário, o interlocutor é a ONG.
/// Se for ONG, o interlocutor é o Voluntário.
class ChatConversation {
  final String id;
  final String interlocutorId;
  final String interlocutorNome;
  final String interlocutorFoto;
  final String
  interlocutorSubtitulo; // Ex: "Santo André" ou "Voluntário • Educação"
  final bool online;
  int naoLidas;
  ChatMessage? ultimaMensagem;

  ChatConversation({
    required this.id,
    required this.interlocutorId,
    required this.interlocutorNome,
    required this.interlocutorFoto,
    required this.interlocutorSubtitulo,
    this.online = false,
    this.naoLidas = 0,
    this.ultimaMensagem,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id']?.toString() ?? '',
      interlocutorId: json['interlocutorId']?.toString() ?? '',
      interlocutorNome: json['interlocutorNome'] ?? '',
      interlocutorFoto:
          json['interlocutorFoto'] ??
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
      interlocutorSubtitulo: json['interlocutorSubtitulo'] ?? '',
      online: json['online'] ?? false,
      naoLidas: json['naoLidas'] ?? 0,
      ultimaMensagem: json['ultimaMensagem'] != null
          ? ChatMessage.fromJson(json['ultimaMensagem'])
          : null,
    );
  }
}
