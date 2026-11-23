// lib/models/dashboard_volunteer_models.dart

import '../../../eventos/models/evento_model.dart';
import '../ongs/models/ong_models.dart';

/// Métricas de impacto acumuladas pelo voluntário
class MetricasImpactoModel {
  final int totalCidades;
  final int ongsAjudadas;
  final String horasDoadas;
  final double rankingEstrelas;

  MetricasImpactoModel({
    required this.totalCidades,
    required this.ongsAjudadas,
    required this.horasDoadas,
    required this.rankingEstrelas,
  });

  /// Retorna o progresso nas 7 cidades do Grande ABC no formato "0/7" até "7/7"
  String get cidadesFormatadas => '${totalCidades.clamp(0, 7)}/7';

  factory MetricasImpactoModel.fromJson(Map<String, dynamic> json) {
    final int cidadesRaw =
        int.tryParse(json['totalCidades']?.toString() ?? '0') ?? 0;

    return MetricasImpactoModel(
      totalCidades: cidadesRaw.clamp(0, 7),
      ongsAjudadas: int.tryParse(json['ongsAjudadas']?.toString() ?? '0') ?? 0,
      horasDoadas: (json['horasDoadas'] ?? '0h').toString(),
      rankingEstrelas: (json['rankingEstrelas'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalCidades': totalCidades.clamp(0, 7),
        'ongsAjudadas': ongsAjudadas,
        'horasDoadas': horasDoadas,
        'rankingEstrelas': rankingEstrelas,
      };
}

/// Dados completos para renderizar a Home do Voluntário
class VoluntarioDashboardModel {
  final String voluntarioId;
  final String nome;
  final String fotoUrl;
  final String cidade;
  final MetricasImpactoModel metricas;
  final EventoModel? proximoEvento;
  final OngModel? ongProxima;

  VoluntarioDashboardModel({
    required this.voluntarioId,
    required this.nome,
    required this.fotoUrl,
    required this.cidade,
    required this.metricas,
    this.proximoEvento,
    this.ongProxima,
  });

  factory VoluntarioDashboardModel.fromJson(Map<String, dynamic> json) {
    return VoluntarioDashboardModel(
      voluntarioId: json['voluntarioId']?.toString() ?? '',
      nome: (json['nome'] ?? '').toString(),
      fotoUrl: (json['fotoUrl'] ?? '').toString(),
      cidade: (json['cidade'] ?? '').toString(),
      metricas: MetricasImpactoModel.fromJson(
        json['metricas'] != null
            ? Map<String, dynamic>.from(json['metricas'])
            : {},
      ),
      proximoEvento: json['proximoEvento'] != null
          ? EventoModel.fromJson(
              Map<String, dynamic>.from(json['proximoEvento']),
            )
          : null,
      ongProxima: json['ongProxima'] != null
          ? OngModel.fromJson(Map<String, dynamic>.from(json['ongProxima']))
          : null,
    );
  }
}
