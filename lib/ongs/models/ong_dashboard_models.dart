// lib/ongs/models/ong_dashboard_models.dart

import 'dart:convert';

class CandidatoVoluntarioModel {
  final String solicitacaoId;
  final String voluntarioId;
  final String nome;
  final String fotoUrl;
  final String eventoNome;
  final String cidade;
  final String dataSolicitacao;
  final List<String> habilidades;
  final String? caronaOuSuporte;
  final String? tipoCarona;
  final String? detalhesCarona;
  final String? whatsapp;

  CandidatoVoluntarioModel({
    required this.solicitacaoId,
    required this.voluntarioId,
    required this.nome,
    required this.fotoUrl,
    required this.eventoNome,
    required this.cidade,
    required this.dataSolicitacao,
    required this.habilidades,
    this.caronaOuSuporte,
    this.tipoCarona,
    this.detalhesCarona,
    this.whatsapp,
  });

  factory CandidatoVoluntarioModel.fromJson(
    Map<String, dynamic> json, {
    String? tituloEventoFallback,
  }) {
    final userMap = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : (json['voluntario'] is Map<String, dynamic>
            ? json['voluntario'] as Map<String, dynamic>
            : <String, dynamic>{});

    final oppMap = json['opportunity'] is Map<String, dynamic>
        ? json['opportunity'] as Map<String, dynamic>
        : <String, dynamic>{};

    final rawHabilidades =
        userMap['habilidades'] ?? json['habilidades'] ?? const [];

    // Monta rótulo amigável para carona a partir de ApplyOpportunityDto (tipoCarona + detalhesCarona)
    final String tipoCaronaRaw =
        (json['tipoCarona'] ?? '').toString().toUpperCase().trim();
    final String detalhesCaronaRaw =
        (json['detalhesCarona'] ?? '').toString().trim();

    String? resumoCarona = json['caronaOuSuporte']?.toString();
    if (resumoCarona == null || resumoCarona.trim().isEmpty) {
      if (tipoCaronaRaw == 'PRECISA_CARONA') {
        resumoCarona = detalhesCaronaRaw.isNotEmpty
            ? 'Precisa de carona: $detalhesCaronaRaw'
            : 'Precisa de carona';
      } else if (tipoCaronaRaw == 'OFERECE_CARONA') {
        resumoCarona = detalhesCaronaRaw.isNotEmpty
            ? 'Oferece carona: $detalhesCaronaRaw'
            : 'Oferece carona';
      }
    }

    return CandidatoVoluntarioModel(
      solicitacaoId: (json['id'] ?? json['solicitacaoId'] ?? '').toString(),
      voluntarioId:
          (userMap['id'] ?? json['userId'] ?? json['voluntarioId'] ?? '')
              .toString(),
      nome: (userMap['name'] ?? userMap['nome'] ?? json['nome'] ?? 'Voluntário')
          .toString(),
      fotoUrl:
          (userMap['avatar'] ?? userMap['fotoUrl'] ?? json['fotoUrl'] ?? '')
              .toString(),
      eventoNome: (oppMap['title'] ??
              oppMap['titulo'] ??
              json['eventoNome'] ??
              tituloEventoFallback ??
              '')
          .toString(),
      cidade: (userMap['cidade'] ?? json['cidade'] ?? '').toString(),
      dataSolicitacao: _formatarDataCurta(
          (json['createdAt'] ?? json['dataSolicitacao'] ?? '').toString()),
      habilidades: rawHabilidades is List
          ? rawHabilidades.map((e) => e.toString()).toList()
          : const [],
      caronaOuSuporte: resumoCarona,
      tipoCarona: tipoCaronaRaw.isEmpty ? null : tipoCaronaRaw,
      detalhesCarona: detalhesCaronaRaw.isEmpty ? null : detalhesCaronaRaw,
      whatsapp: (userMap['whatsapp'] ?? userMap['telefone'] ?? '').toString(),
    );
  }

  static String _formatarDataCurta(String raw) {
    if (raw.isEmpty) return 'Recente';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final d = dt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

class EventoGerenciadoModel {
  final String id;
  final String titulo;
  final String dataFormatada;
  final String horario;
  final int inscritosCount;
  final int vagasTotais;
  final String imagemUrl;
  final String status; // "ativo", "lotado", "concluido", "cancelado"
  final String modality; // "PRESENCIAL", "REMOTO", "HIBRIDO"

  EventoGerenciadoModel({
    required this.id,
    required this.titulo,
    required this.dataFormatada,
    required this.horario,
    required this.inscritosCount,
    required this.vagasTotais,
    required this.imagemUrl,
    required this.status,
    this.modality = 'PRESENCIAL',
  });

  static String _extrairBannerPrincipal(dynamic raw) {
    final texto = (raw ?? '').toString().trim();
    if (texto.isEmpty) return '';
    if (texto.startsWith('[')) {
      try {
        final decoded = jsonDecode(texto);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded.first.toString().trim();
        }
      } catch (_) {}
    }
    return texto;
  }

  factory EventoGerenciadoModel.fromJson(Map<String, dynamic> json) {
    final int vagas = int.tryParse((json['totalVacancies'] ??
                json['vagasTotais'] ??
                json['spots'] ??
                json['vagas'] ??
                0)
            .toString()) ??
        0;

    final countMap = json['_count'] is Map<String, dynamic>
        ? json['_count'] as Map<String, dynamic>
        : null;

    final int inscritos = int.tryParse((json['inscritosCount'] ??
                countMap?['applications'] ??
                json['applicationsCount'] ??
                0)
            .toString()) ??
        0;

    final String statusBruto =
        (json['status'] ?? '').toString().toLowerCase().trim();
    String statusNormalizado = 'ativo';
    if (statusBruto == 'concluida' ||
        statusBruto == 'concluido' ||
        statusBruto == 'closed' ||
        statusBruto == 'finished') {
      statusNormalizado = 'concluido';
    } else if (statusBruto == 'cancelada' || statusBruto == 'cancelado') {
      statusNormalizado = 'cancelado';
    } else if (statusBruto == 'lotada' ||
        statusBruto == 'lotado' ||
        (vagas > 0 && inscritos >= vagas)) {
      statusNormalizado = 'lotado';
    } else if (statusBruto == 'ativa' || statusBruto == 'ativo') {
      statusNormalizado = 'ativo';
    } else if (statusBruto.isNotEmpty) {
      statusNormalizado = statusBruto;
    }

    final String dataInicioBruta = (json['eventDate'] ??
            json['startDate'] ??
            json['date'] ??
            json['data'] ??
            '')
        .toString();

    final String dataFimBruta = (json['endDate'] ?? '').toString();
    final int durationHours =
        int.tryParse((json['durationHours'] ?? 0).toString()) ?? 0;

    String horarioCalculado =
        (json['horario'] ?? json['time'] ?? '').toString().trim();
    if (horarioCalculado.isEmpty) {
      horarioCalculado = _formatarFaixaHorario(
        dataInicioBruta,
        dataFimBruta,
        durationHours,
      );
    }

    final String bannerPrincipal = _extrairBannerPrincipal(
      json['banner'] ?? json['imageUrl'] ?? json['imagemUrl'] ?? '',
    );

    return EventoGerenciadoModel(
      id: (json['id'] ?? '').toString(),
      titulo: (json['title'] ?? json['titulo'] ?? '').toString(),
      dataFormatada: _formatarDataEvento(dataInicioBruta),
      horario: horarioCalculado,
      inscritosCount: inscritos,
      vagasTotais: vagas,
      imagemUrl: bannerPrincipal,
      status: statusNormalizado,
      modality: (json['modality'] ?? 'PRESENCIAL').toString().toUpperCase(),
    );
  }

  static String _formatarDataEvento(String raw) {
    if (raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final d = dt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  static String _formatarFaixaHorario(
    String inicioRaw,
    String fimRaw,
    int durationHours,
  ) {
    final inicio = DateTime.tryParse(inicioRaw)?.toLocal();
    if (inicio == null) return '';

    final horaIni =
        '${inicio.hour.toString().padLeft(2, '0')}:${inicio.minute.toString().padLeft(2, '0')}';

    DateTime? fim = DateTime.tryParse(fimRaw)?.toLocal();
    if (fim == null && durationHours > 0) {
      fim = inicio.add(Duration(hours: durationHours));
    }

    if (fim != null) {
      final horaFim =
          '${fim.hour.toString().padLeft(2, '0')}:${fim.minute.toString().padLeft(2, '0')}';
      return '$horaIni às $horaFim';
    }

    return horaIni;
  }
}

class OngDashboardModel {
  final String id;
  final String nome;
  final String categoria;
  final String cidade;
  final String logoUrl;
  final int totalVoluntariosEngajados;
  final int vagasAbertas;
  final int horasGeradas;
  final int candidaturasPendentesCount;
  final List<String> necessidadesAtuais;
  final String? chavePix;
  final String? horarioRecebimentoDoacoes;
  final List<CandidatoVoluntarioModel> candidaturasPendentes;
  final List<EventoGerenciadoModel> eventosAtivos;

  OngDashboardModel({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.cidade,
    required this.logoUrl,
    required this.totalVoluntariosEngajados,
    required this.vagasAbertas,
    required this.horasGeradas,
    required this.candidaturasPendentesCount,
    required this.necessidadesAtuais,
    this.chavePix,
    this.horarioRecebimentoDoacoes,
    required this.candidaturasPendentes,
    required this.eventosAtivos,
  });
}
