import 'package:flutter/material.dart';

enum TipoNotificacao {
  evento, // NEW_OPPORTUNITY_MATCH, NEW_CANDIDATE
  aprovacao, // APPLICATION_ACCEPTED, NEW_PLEDGE, PLEDGE_DELIVERED
  conquista, // CERTIFICATE_READY, SUPPLY_NEEDED
  sistema, // Demais notificações
}

class NotificacaoModel {
  final String id;
  final String usuarioId;
  final TipoNotificacao tipo;
  final String titulo;
  final String descricaoCurta;
  final String mensagemCompleta;
  final DateTime criadoEm;
  bool lida;

  // Campos extras vindos do back-end para navegação/ação
  final String?
      rawType; // 'NEW_OPPORTUNITY_MATCH', 'SUPPLY_NEEDED', 'NEW_PLEDGE', 'CERTIFICATE_READY'
  final String? linkId; // ID da vaga, do suprimento ou da inscrição/certificado
  final String? eventoId;
  final String? ongId;
  final String? rotaDestino;

  NotificacaoModel({
    required this.id,
    required this.usuarioId,
    required this.tipo,
    required this.titulo,
    required this.descricaoCurta,
    required this.mensagemCompleta,
    required this.criadoEm,
    this.lida = false,
    this.rawType,
    this.linkId,
    this.eventoId,
    this.ongId,
    this.rotaDestino,
  });

  factory NotificacaoModel.fromJson(Map<String, dynamic> json) {
    final String? tipoBruto = (json['type'] ?? json['tipo'])?.toString();
    final String? link = (json['linkId'] ?? json['eventoId'])?.toString();

    TipoNotificacao parseTipo(String? tipoStr) {
      switch (tipoStr?.toUpperCase()) {
        case 'EVENTO':
        case 'NEW_OPPORTUNITY_MATCH':
        case 'NEW_CANDIDATE':
          return TipoNotificacao.evento;
        case 'APROVACAO':
        case 'APPLICATION_ACCEPTED':
        case 'APPLICATION_APPROVED':
        case 'NEW_PLEDGE':
        case 'PLEDGE_DELIVERED':
          return TipoNotificacao.aprovacao;
        case 'CONQUISTA':
        case 'CERTIFICATE_READY':
        case 'SUPPLY_NEEDED':
          return TipoNotificacao.conquista;
        default:
          return TipoNotificacao.sistema;
      }
    }

    final String tituloApi = (json['title'] ?? json['titulo'] ?? '').toString();
    final String mensagemApi = (json['message'] ??
            json['mensagemCompleta'] ??
            json['descricaoCurta'] ??
            '')
        .toString();

    return NotificacaoModel(
      id: json['id']?.toString() ?? '',
      usuarioId: (json['userId'] ?? json['usuarioId'] ?? '').toString(),
      tipo: parseTipo(tipoBruto),
      rawType: tipoBruto,
      linkId: link,
      titulo: tituloApi,
      descricaoCurta: (json['descricaoCurta'] ?? mensagemApi).toString(),
      mensagemCompleta: mensagemApi,
      criadoEm: (json['createdAt'] ?? json['criadoEm']) != null
          ? DateTime.tryParse(
                  (json['createdAt'] ?? json['criadoEm']).toString()) ??
              DateTime.now()
          : DateTime.now(),
      lida: json['read'] ?? json['lida'] ?? false,
      eventoId: tipoBruto == 'NEW_OPPORTUNITY_MATCH'
          ? link
          : json['eventoId']?.toString(),
      ongId: json['ongId']?.toString(),
      rotaDestino: json['rotaDestino']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': usuarioId,
      'type': rawType ?? tipo.name,
      'linkId': linkId,
      'title': titulo,
      'message': mensagemCompleta,
      'createdAt': criadoEm.toIso8601String(),
      'read': lida,
    };
  }

  IconData get icone {
    switch (rawType?.toUpperCase()) {
      case 'SUPPLY_NEEDED':
      case 'NEW_PLEDGE':
      case 'PLEDGE_DELIVERED':
        return Icons.volunteer_activism_rounded;
      case 'CERTIFICATE_READY':
        return Icons.workspace_premium_rounded;
      default:
        switch (tipo) {
          case TipoNotificacao.evento:
            return Icons.event_available_rounded;
          case TipoNotificacao.aprovacao:
            return Icons.check_circle_outline_rounded;
          case TipoNotificacao.conquista:
            return Icons.emoji_events_rounded;
          case TipoNotificacao.sistema:
            return Icons.notifications_active_outlined;
        }
    }
  }

  Color get corTema {
    switch (tipo) {
      case TipoNotificacao.evento:
        return const Color(0xFF0C6B6B);
      case TipoNotificacao.aprovacao:
        return const Color(0xFF29B0A0);
      case TipoNotificacao.conquista:
        return const Color(0xFFD48806);
      case TipoNotificacao.sistema:
        return const Color(0xFF3A6868);
    }
  }

  String get dataRelativa {
    final diff = DateTime.now().difference(criadoEm);
    if (diff.inMinutes < 1) return "Agora mesmo";
    if (diff.inMinutes < 60) return "Há ${diff.inMinutes} min";
    if (diff.inHours < 24)
      return "Há ${diff.inHours} ${diff.inHours == 1 ? 'hora' : 'horas'}";
    if (diff.inDays == 1) return "Ontem";
    if (diff.inDays < 7) return "Há ${diff.inDays} dias";
    final d = criadoEm.day.toString().padLeft(2, '0');
    final m = criadoEm.month.toString().padLeft(2, '0');
    return "$d/$m";
  }
}
