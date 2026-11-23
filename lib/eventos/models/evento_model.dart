// lib/eventos/models/evento_model.dart

/// Modelo representativo de cada voluntário confirmado no evento
class EventoParticipanteModel {
  final String id;
  final String nome;
  final String? fotoUrl;

  const EventoParticipanteModel({
    required this.id,
    required this.nome,
    this.fotoUrl,
  });

  factory EventoParticipanteModel.fromJson(Map<String, dynamic> json) {
    final userObj = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : (json['voluntario'] is Map<String, dynamic>
            ? json['voluntario'] as Map<String, dynamic>
            : json);

    return EventoParticipanteModel(
      id: (userObj['id'] ?? json['userId'] ?? json['voluntarioId'] ?? '')
          .toString(),
      nome: (userObj['name'] ?? userObj['nome'] ?? 'Voluntário').toString(),
      fotoUrl: (userObj['avatar'] ?? userObj['fotoUrl'] ?? userObj['avatarUrl'])
          ?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'fotoUrl': fotoUrl,
      };
}

class EventoModel {
  final String id;
  final String ongId;
  final String ongNome;
  final String titulo;
  final String descricao;
  final String categoria;
  final String cidade;
  final String? endereco;
  final double? latitude;
  final double? longitude;
  final String data;
  final String horario;
  final DateTime dataHoraInicio;
  final int vagasTotais;
  final int vagasRestantes;
  final String imagemUrl;
  final List<String> tags;
  final List<String> requisitos;
  final List<String> necessidades;
  final bool emiteCertificado;
  final bool isInscrito;
  final String? statusInscricao;
  final String? inscricaoId;
  final DateTime criadoEm;
  final List<EventoParticipanteModel> participantesConfirmados;

  const EventoModel({
    required this.id,
    required this.ongId,
    this.ongNome = 'Instituição Parceira',
    required this.titulo,
    this.descricao = '',
    this.categoria = 'Geral',
    this.cidade = 'Grande ABC',
    this.endereco,
    this.latitude,
    this.longitude,
    required this.data,
    required this.horario,
    required this.dataHoraInicio,
    required this.vagasTotais,
    required this.vagasRestantes,
    required this.imagemUrl,
    this.tags = const [],
    this.requisitos = const [],
    this.necessidades = const [],
    this.emiteCertificado = true,
    this.isInscrito = false,
    this.statusInscricao,
    this.inscricaoId,
    required this.criadoEm,
    this.participantesConfirmados = const [],
  });

  double get progressoOcupacao {
    if (vagasTotais <= 0) return 0.0;
    final ocupadas = vagasTotais - vagasRestantes;
    final r = ocupadas / vagasTotais;
    return r.clamp(0.0, 1.0);
  }

  bool get isEsgotado => vagasRestantes <= 0;
  bool get isQuaseEsgotado => vagasRestantes > 0 && vagasRestantes <= 3;

  EventoModel copyWith({
    String? id,
    String? ongId,
    String? ongNome,
    String? titulo,
    String? descricao,
    String? categoria,
    String? cidade,
    String? endereco,
    double? latitude,
    double? longitude,
    String? data,
    String? horario,
    DateTime? dataHoraInicio,
    int? vagasTotais,
    int? vagasRestantes,
    String? imagemUrl,
    List<String>? tags,
    List<String>? requisitos,
    List<String>? necessidades,
    bool? emiteCertificado,
    bool? isInscrito,
    String? statusInscricao,
    String? inscricaoId,
    DateTime? criadoEm,
    List<EventoParticipanteModel>? participantesConfirmados,
  }) {
    return EventoModel(
      id: id ?? this.id,
      ongId: ongId ?? this.ongId,
      ongNome: ongNome ?? this.ongNome,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      categoria: categoria ?? this.categoria,
      cidade: cidade ?? this.cidade,
      endereco: endereco ?? this.endereco,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      data: data ?? this.data,
      horario: horario ?? this.horario,
      dataHoraInicio: dataHoraInicio ?? this.dataHoraInicio,
      vagasTotais: vagasTotais ?? this.vagasTotais,
      vagasRestantes: vagasRestantes ?? this.vagasRestantes,
      imagemUrl: imagemUrl ?? this.imagemUrl,
      tags: tags ?? this.tags,
      requisitos: requisitos ?? this.requisitos,
      necessidades: necessidades ?? this.necessidades,
      emiteCertificado: emiteCertificado ?? this.emiteCertificado,
      isInscrito: isInscrito ?? this.isInscrito,
      statusInscricao: statusInscricao ?? this.statusInscricao,
      inscricaoId: inscricaoId ?? this.inscricaoId,
      criadoEm: criadoEm ?? this.criadoEm,
      participantesConfirmados:
          participantesConfirmados ?? this.participantesConfirmados,
    );
  }

  static List<String> _extrairListaStrings(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  factory EventoModel.fromJson(
    Map<String, dynamic> json, {
    String? voluntarioId,
  }) {
    bool inscrito = false;
    String? status;
    String? inscricaoId;

    final rawApps = json['applications'] is List
        ? json['applications'] as List
        : (json['inscricoes'] is List ? json['inscricoes'] as List : null);

    if (voluntarioId != null && rawApps != null) {
      final match = rawApps.cast<dynamic>().firstWhere(
        (i) {
          if (i is! Map) return false;
          final uid = (i['userId'] ?? i['voluntarioId'] ?? '').toString();
          final st = (i['status'] ?? '').toString().toUpperCase();
          return uid == voluntarioId &&
              st != 'CANCELADA' &&
              st != 'CANCELLED' &&
              st != 'REJECTED';
        },
        orElse: () => null,
      );
      if (match is Map) {
        inscrito = true;
        status = match['status']?.toString();
        inscricaoId = match['id']?.toString();
      }
    } else {
      inscrito = json['isInscrito'] as bool? ?? false;
      status = json['statusInscricao']?.toString();
      inscricaoId = json['inscricaoId']?.toString();
    }

    // Participantes confirmados vindos da API (applications aprovadas ou participantesConfirmados)
    final List<EventoParticipanteModel> listaParticipantes = [];
    final rawParticipantes =
        json['participantesConfirmados'] ?? json['participantes'] ?? rawApps;

    if (rawParticipantes is List) {
      for (final p in rawParticipantes) {
        if (p is Map<String, dynamic>) {
          final st =
              (p['status'] ?? 'APPROVED').toString().toUpperCase().trim();
          if (st == 'APPROVED' ||
              st == 'CONFIRMED' ||
              st == 'CONFIRMADA' ||
              st == 'APROVADO' ||
              st == 'PRESENTE') {
            final parsed = EventoParticipanteModel.fromJson(p);
            if (parsed.id.isNotEmpty) {
              listaParticipantes.add(parsed);
            }
          }
        }
      }
    }

    // Data e horário reais da API (eventDate + endDate / durationHours)
    final String rawInicio =
        (json['eventDate'] ?? json['dataHoraInicio'] ?? '').toString();
    final DateTime dtInicio =
        DateTime.tryParse(rawInicio)?.toLocal() ?? DateTime.now();

    final int duracao =
        int.tryParse((json['durationHours'] ?? 4).toString()) ?? 4;

    String dataFmt = (json['data'] ?? '').toString().trim();
    String horarioFmt = (json['horario'] ?? '').toString().trim();

    if (rawInicio.isNotEmpty) {
      if (dataFmt.isEmpty) {
        dataFmt =
            '${dtInicio.day.toString().padLeft(2, '0')}/${dtInicio.month.toString().padLeft(2, '0')}/${dtInicio.year}';
      }
      if (horarioFmt.isEmpty) {
        final dtFim = json['endDate'] != null
            ? (DateTime.tryParse(json['endDate'].toString())?.toLocal() ??
                dtInicio.add(Duration(hours: duracao)))
            : dtInicio.add(Duration(hours: duracao));
        final ini =
            '${dtInicio.hour.toString().padLeft(2, '0')}:${dtInicio.minute.toString().padLeft(2, '0')}';
        final fim =
            '${dtFim.hour.toString().padLeft(2, '0')}:${dtFim.minute.toString().padLeft(2, '0')}';
        horarioFmt = '$ini às $fim';
      }
    }

    // Vagas totais e restantes da API
    final int vagasTot = int.tryParse(
          (json['totalVacancies'] ?? json['vagasTotais'] ?? 0).toString(),
        ) ??
        0;

    final countMap = json['_count'] is Map ? json['_count'] as Map : null;
    final int ocupadas = int.tryParse(
          (countMap?['applications'] ??
                  json['inscritosCount'] ??
                  listaParticipantes.length)
              .toString(),
        ) ??
        0;

    final int vagasRest = json['vagasRestantes'] != null
        ? (int.tryParse(json['vagasRestantes'].toString()) ?? 0)
        : (vagasTot - ocupadas).clamp(0, vagasTot);

    // Requisitos e habilidades/necessidades reais da API
    final int? minAge = int.tryParse((json['minAge'] ?? '').toString());
    final reqApi = _extrairListaStrings(
      json['requirements'] ?? json['requisitos'],
    );
    final List<String> requisitosCompletos = [
      if (minAge != null && minAge > 0) 'Idade mínima: $minAge anos',
      ...reqApi,
    ];

    final necessidadesCompletas = _extrairListaStrings(
      json['requiredSkills'] ?? json['necessidades'],
    );

    final ongObj = json['ong'] is Map ? json['ong'] as Map : null;

    return EventoModel(
      id: (json['id'] ?? '').toString(),
      ongId: (json['ongId'] ?? ongObj?['id'] ?? '').toString(),
      ongNome: (json['ongNome'] ??
              ongObj?['name'] ??
              ongObj?['nome'] ??
              'Instituição Parceira')
          .toString(),
      titulo: (json['title'] ?? json['titulo'] ?? 'Ação Solidária').toString(),
      descricao: (json['description'] ?? json['descricao'] ?? '').toString(),
      categoria: (json['cause'] ?? json['categoria'] ?? 'Geral').toString(),
      cidade: (json['city'] ?? json['cidade'] ?? 'Grande ABC').toString(),
      endereco: (json['address'] ?? json['endereco'])?.toString(),
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      data: dataFmt,
      horario: horarioFmt,
      dataHoraInicio: dtInicio,
      vagasTotais: vagasTot,
      vagasRestantes: vagasRest,
      imagemUrl: (json['banner'] ?? json['imagemUrl'] ?? json['imageUrl'] ?? '')
          .toString(),
      tags: _extrairListaStrings(json['tags']),
      requisitos: requisitosCompletos,
      necessidades: necessidadesCompletas,
      emiteCertificado: (json['generatesCertificate'] ??
          json['emiteCertificado'] ??
          true) as bool,
      isInscrito: inscrito,
      statusInscricao: status,
      inscricaoId: inscricaoId,
      criadoEm: DateTime.tryParse(
            (json['createdAt'] ?? json['criadoEm'] ?? '').toString(),
          )?.toLocal() ??
          DateTime.now(),
      participantesConfirmados: listaParticipantes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ongId': ongId,
      'ongNome': ongNome,
      'titulo': titulo,
      'descricao': descricao,
      'categoria': categoria,
      'cidade': cidade,
      'endereco': endereco,
      'latitude': latitude,
      'longitude': longitude,
      'data': data,
      'horario': horario,
      'dataHoraInicio': dataHoraInicio.toIso8601String(),
      'vagasTotais': vagasTotais,
      'vagasRestantes': vagasRestantes,
      'imagemUrl': imagemUrl,
      'tags': tags,
      'requisitos': requisitos,
      'necessidades': necessidades,
      'emiteCertificado': emiteCertificado,
      'isInscrito': isInscrito,
      'statusInscricao': statusInscricao,
      'inscricaoId': inscricaoId,
      'criadoEm': criadoEm.toIso8601String(),
      'participantesConfirmados':
          participantesConfirmados.map((p) => p.toJson()).toList(),
    };
  }
}

/// Modelo de Inscrição com suporte a todas as propriedades de chamada, histórico e contato
class InscricaoEventoModel {
  final String id;
  final String eventoId;
  final String voluntarioId;
  final String status;
  final DateTime dataInscricao;
  final DateTime? criadoEm;
  final EventoModel? evento;
  final int horasComputadas;
  final int horasValidadas;
  final bool autorizouContato;

  const InscricaoEventoModel({
    required this.id,
    required this.eventoId,
    required this.voluntarioId,
    this.status = "CONFIRMADA",
    DateTime? dataInscricao,
    DateTime? criadoEm,
    this.evento,
    this.horasComputadas = 0,
    this.horasValidadas = 0,
    this.autorizouContato = true,
  })  : dataInscricao = dataInscricao ?? criadoEm ?? const _DataPadrao(),
        criadoEm = criadoEm ?? dataInscricao;

  factory InscricaoEventoModel.fromJson(Map<String, dynamic> json) {
    final data = json['dataInscricao'] != null
        ? DateTime.tryParse(json['dataInscricao'].toString())
        : (json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : (json['criadoEm'] != null
                ? DateTime.tryParse(json['criadoEm'].toString())
                : null));

    final eventoJson = json['opportunity'] is Map<String, dynamic>
        ? json['opportunity'] as Map<String, dynamic>
        : (json['evento'] is Map<String, dynamic>
            ? json['evento'] as Map<String, dynamic>
            : null);

    return InscricaoEventoModel(
      id: (json['id'] ?? '').toString(),
      eventoId: (json['opportunityId'] ?? json['eventoId'] ?? '').toString(),
      voluntarioId: (json['userId'] ?? json['voluntarioId'] ?? '').toString(),
      status: (json['status'] ?? 'CONFIRMADA').toString(),
      dataInscricao: data ?? DateTime.now(),
      criadoEm: data ?? DateTime.now(),
      evento: eventoJson != null ? EventoModel.fromJson(eventoJson) : null,
      horasComputadas: (json['horasComputadas'] as num?)?.toInt() ?? 0,
      horasValidadas: (json['horasValidadas'] as num?)?.toInt() ??
          (json['horasComputadas'] as num?)?.toInt() ??
          0,
      autorizouContato: json['autorizouContato'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventoId': eventoId,
      'voluntarioId': voluntarioId,
      'status': status,
      'dataInscricao': dataInscricao.toIso8601String(),
      'criadoEm':
          criadoEm?.toIso8601String() ?? dataInscricao.toIso8601String(),
      'evento': evento?.toJson(),
      'horasComputadas': horasComputadas,
      'horasValidadas': horasValidadas,
      'autorizouContato': autorizouContato,
    };
  }
}

class _DataPadrao implements DateTime {
  const _DataPadrao();
  @override
  dynamic noSuchMethod(Invocation invocation) => DateTime.now();
}

/// DTO flexível para criação de ações
class CriarEventoDTO {
  final String ongId;
  final String ongNome;
  final String titulo;
  final String categoria;
  final String descricao;
  final String cidade;
  final String endereco;
  final double? latitude;
  final double? longitude;
  final String data;
  final String horario;
  final String? horarioInicio;
  final String? horarioTermino;
  final DateTime dataHoraInicio;
  final String imagemUrl;
  final List<String> tags;
  final int vagasTotais;
  final List<String> requisitos;
  final List<String> necessidades;
  final bool emiteCertificado;

  const CriarEventoDTO({
    required this.ongId,
    this.ongNome = '',
    required this.titulo,
    this.categoria = 'Assistência Social',
    this.descricao = '',
    required this.cidade,
    this.endereco = '',
    this.latitude,
    this.longitude,
    this.data = '',
    this.horario = '',
    this.horarioInicio,
    this.horarioTermino,
    required this.dataHoraInicio,
    this.imagemUrl = '',
    this.tags = const [],
    required this.vagasTotais,
    this.requisitos = const [],
    this.necessidades = const [],
    this.emiteCertificado = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'ongId': ongId,
      'ongNome': ongNome,
      'titulo': titulo,
      'categoria': categoria,
      'descricao': descricao,
      'cidade': cidade,
      'endereco': endereco,
      'latitude': latitude,
      'longitude': longitude,
      'data': data,
      'horario': horario.isNotEmpty
          ? horario
          : "${horarioInicio ?? ''} - ${horarioTermino ?? ''}".trim(),
      'dataHoraInicio': dataHoraInicio.toIso8601String(),
      'imagemUrl': imagemUrl,
      'tags': tags,
      'vagasTotais': vagasTotais,
      'requisitos': requisitos,
      'necessidades': necessidades,
      'emiteCertificado': emiteCertificado,
    };
  }
}
