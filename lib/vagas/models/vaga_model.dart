// lib/vagas/models/vaga_model.dart

class VagaModel {
  final String id;
  final String titulo;
  final String descricao;
  final String categoria;
  final String cidade;
  final String? localizacao;
  final DateTime? dataEvento;
  final int vagasTotais;
  final int vagasPreenchidas;
  final String? ongId;
  final String? ongNome;
  final String? ongFoto;
  final bool? jaInscrito;

  const VagaModel({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.categoria,
    required this.cidade,
    this.localizacao,
    this.dataEvento,
    this.vagasTotais = 0,
    this.vagasPreenchidas = 0,
    this.ongId,
    this.ongNome,
    this.ongFoto,
    this.jaInscrito,
  });

  int get vagasRestantes {
    final restantes = vagasTotais - vagasPreenchidas;
    return restantes > 0 ? restantes : 0;
  }

  factory VagaModel.fromJson(Map<String, dynamic> json) {
    // Trata dados da ONG caso venham aninhados em objeto ou em campos planos
    String? resolvedOngId;
    String? resolvedOngNome;
    String? resolvedOngFoto;

    if (json['ong'] is Map<String, dynamic>) {
      final ongMap = json['ong'] as Map<String, dynamic>;
      resolvedOngId = ongMap['id']?.toString();
      resolvedOngNome =
          ongMap['name']?.toString() ?? ongMap['nome']?.toString();
      resolvedOngFoto =
          ongMap['avatar']?.toString() ?? ongMap['fotoUrl']?.toString();
    } else {
      resolvedOngId = json['ongId']?.toString();
      resolvedOngNome =
          json['ongNome']?.toString() ?? json['organization']?.toString();
      resolvedOngFoto = json['ongFoto']?.toString();
    }

    // Parsing seguro de data
    DateTime? resolvedData;
    final rawDate = json['date'] ?? json['data'] ?? json['dataEvento'];
    if (rawDate != null) {
      resolvedData = DateTime.tryParse(rawDate.toString());
    }

    return VagaModel(
      id: json['id']?.toString() ?? '',
      titulo: json['title']?.toString() ??
          json['titulo']?.toString() ??
          'Oportunidade',
      descricao: json['description']?.toString() ??
          json['descricao']?.toString() ??
          '',
      categoria: json['category']?.toString() ??
          json['categoria']?.toString() ??
          'Geral',
      cidade: json['city']?.toString() ??
          json['cidade']?.toString() ??
          'Grande ABC',
      localizacao:
          json['location']?.toString() ?? json['localizacao']?.toString(),
      dataEvento: resolvedData,
      vagasTotais:
          (json['spots'] ?? json['vagasTotais'] ?? json['vagas'] ?? 0) as int,
      vagasPreenchidas:
          (json['filledSpots'] ?? json['vagasPreenchidas'] ?? 0) as int,
      ongId: resolvedOngId,
      ongNome: resolvedOngNome ?? 'Instituição Solidária',
      ongFoto: resolvedOngFoto,
      jaInscrito: json['isApplied'] ?? json['jaInscrito'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': titulo,
      'description': descricao,
      'category': categoria,
      'city': cidade,
      'location': localizacao,
      'date': dataEvento?.toIso8601String(),
      'spots': vagasTotais,
      'filledSpots': vagasPreenchidas,
      'ongId': ongId,
      'ongNome': ongNome,
      'ongFoto': ongFoto,
      'jaInscrito': jaInscrito,
    };
  }
}
