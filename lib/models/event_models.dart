// lib/models/event_models.dart

/// Representa um Evento no sistema (cadastrado por uma ONG e visualizado por voluntários).
class EventoModel {
  final String id;
  final String ongId;
  final String ongNome;
  final String titulo;
  final String descricao;
  final String cidade;
  final String? endereco;
  final String data; // Formato "YYYY-MM-DD"
  final String horario; // Formato "HH:mm - HH:mm"
  final DateTime dataHoraInicio;
  final String imagemUrl;
  final List<String> tags;
  final int vagasTotais;
  final int vagasRestantes;
  final DateTime criadoEm;

  // Informações contextuais da inscrição (quando o voluntário está autenticado)
  final String? statusInscricao; // "Aguardando Aprovação", "Aprovado", etc.
  final String? inscricaoId;

  EventoModel({
    required this.id,
    required this.ongId,
    required this.ongNome,
    required this.titulo,
    required this.descricao,
    required this.cidade,
    this.endereco,
    required this.data,
    required this.horario,
    required this.dataHoraInicio,
    required this.imagemUrl,
    required this.tags,
    required this.vagasTotais,
    required this.vagasRestantes,
    required this.criadoEm,
    this.statusInscricao,
    this.inscricaoId,
  });

  /// Factory para desserializar a resposta JSON da API RESTful
  factory EventoModel.fromJson(Map<String, dynamic> json) {
    DateTime inicio;
    if (json['dataHoraInicio'] != null) {
      inicio =
          DateTime.tryParse(json['dataHoraInicio'].toString()) ??
          DateTime.now();
    } else if (json['data'] != null) {
      inicio = DateTime.tryParse(json['data'].toString()) ?? DateTime.now();
    } else {
      inicio = DateTime.now();
    }

    return EventoModel(
      id: json['id']?.toString() ?? '',
      ongId: json['ongId']?.toString() ?? '',
      ongNome: json['ongNome'] ?? 'Instituição',
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'] ?? '',
      cidade: json['cidade'] ?? 'Grande ABC',
      endereco: json['endereco'],
      data: json['data']?.toString() ?? inicio.toIso8601String().split('T')[0],
      horario: json['horario'] ?? '08:00 - 12:00',
      dataHoraInicio: inicio,
      imagemUrl:
          json['imagemUrl'] ??
          'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?w=600',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : ['Geral'],
      vagasTotais: json['vagasTotais'] ?? 10,
      vagasRestantes: json['vagasRestantes'] ?? 0,
      criadoEm: json['criadoEm'] != null
          ? DateTime.tryParse(json['criadoEm'].toString()) ?? DateTime.now()
          : DateTime.now(),
      statusInscricao: json['statusInscricao'],
      inscricaoId: json['inscricaoId']?.toString(),
    );
  }

  /// Converte para Map/JSON caso precise enviar dados de volta
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ongId': ongId,
      'ongNome': ongNome,
      'titulo': titulo,
      'descricao': descricao,
      'cidade': cidade,
      'endereco': endereco,
      'data': data,
      'horario': horario,
      'dataHoraInicio': dataHoraInicio.toIso8601String(),
      'imagemUrl': imagemUrl,
      'tags': tags,
      'vagasTotais': vagasTotais,
      'vagasRestantes': vagasRestantes,
    };
  }

  // Getters visuais práticos
  bool get isEsgotado => vagasRestantes <= 0;
  bool get isQuaseEsgotado => vagasRestantes <= 3 && !isEsgotado;
  double get progressoOcupacao =>
      vagasTotais > 0 ? (vagasTotais - vagasRestantes) / vagasTotais : 0.0;
  bool get isInscrito =>
      statusInscricao != null && statusInscricao != 'Cancelado';
}

/// DTO (Data Transfer Object) para a ONG cadastrar um novo evento via POST
class CriarEventoDTO {
  final String ongId;
  final String ongNome;
  final String titulo;
  final String descricao;
  final String cidade;
  final String? endereco;
  final String data; // "YYYY-MM-DD"
  final String horario; // "08:00 - 12:00"
  final DateTime dataHoraInicio;
  final String imagemUrl;
  final List<String> tags;
  final int vagasTotais;

  CriarEventoDTO({
    required this.ongId,
    required this.ongNome,
    required this.titulo,
    required this.descricao,
    required this.cidade,
    this.endereco,
    required this.data,
    required this.horario,
    required this.dataHoraInicio,
    required this.imagemUrl,
    required this.tags,
    required this.vagasTotais,
  });

  Map<String, dynamic> toJson() {
    return {
      'ongId': ongId,
      'ongNome': ongNome,
      'titulo': titulo,
      'descricao': descricao,
      'cidade': cidade,
      'endereco': endereco,
      'data': data,
      'horario': horario,
      'dataHoraInicio': dataHoraInicio.toIso8601String(),
      'imagemUrl': imagemUrl,
      'tags': tags,
      'vagasTotais': vagasTotais,
    };
  }
}

/// Representa a inscrição do voluntário em um evento
class InscricaoEventoModel {
  final String id;
  final String eventoId;
  final String voluntarioId;
  final String
  status; // "Aguardando Aprovação", "Aprovado", "Cancelado", "Concluído"
  final bool autorizouContato;
  final String? motivoCancelamento;
  final int horasValidadas;
  final DateTime criadoEm;
  final EventoModel? evento; // Evento aninhado

  InscricaoEventoModel({
    required this.id,
    required this.eventoId,
    required this.voluntarioId,
    required this.status,
    required this.autorizouContato,
    this.motivoCancelamento,
    this.horasValidadas = 0,
    required this.criadoEm,
    this.evento,
  });

  factory InscricaoEventoModel.fromJson(Map<String, dynamic> json) {
    return InscricaoEventoModel(
      id: json['id']?.toString() ?? '',
      eventoId: json['eventoId']?.toString() ?? '',
      voluntarioId: json['voluntarioId']?.toString() ?? '',
      status: json['status'] ?? 'Aguardando Aprovação',
      autorizouContato: json['autorizouContato'] ?? true,
      motivoCancelamento: json['motivoCancelamento'],
      horasValidadas: json['horasValidadas'] ?? 0,
      criadoEm: json['criadoEm'] != null
          ? DateTime.tryParse(json['criadoEm'].toString()) ?? DateTime.now()
          : DateTime.now(),
      evento: json['evento'] != null
          ? EventoModel.fromJson(json['evento'])
          : null,
    );
  }
}
