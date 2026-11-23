// lib/voluntarios/buscar/models/resultado_busca_model.dart

enum TipoResultadoBusca {
  ong,
  voluntario,
  evento,
}

abstract class ResultadoBuscaItem {
  final String id;
  final String tituloPrincipal;
  final String subtitulo;
  final String imagemUrl;
  final String tagOuCategoria;
  final String segundaCaracteristica;
  final String cidade;
  final TipoResultadoBusca tipo;

  const ResultadoBuscaItem({
    required this.id,
    required this.tituloPrincipal,
    required this.subtitulo,
    required this.imagemUrl,
    required this.tagOuCategoria,
    this.segundaCaracteristica = '',
    required this.cidade,
    required this.tipo,
  });

  String get tipoLabel {
    switch (tipo) {
      case TipoResultadoBusca.ong:
        return 'ONG';
      case TipoResultadoBusca.voluntario:
        return 'Voluntário';
      case TipoResultadoBusca.evento:
        return 'Evento';
    }
  }
}

class BuscaOngItem extends ResultadoBuscaItem {
  final int totalVoluntarios;

  const BuscaOngItem({
    required super.id,
    required super.tituloPrincipal,
    required super.subtitulo,
    required super.imagemUrl,
    required super.tagOuCategoria,
    super.segundaCaracteristica = '',
    required super.cidade,
    required this.totalVoluntarios,
  }) : super(tipo: TipoResultadoBusca.ong);

  factory BuscaOngItem.fromJson(Map<String, dynamic> json) {
    final String cidadeParsed =
        (json['cidade'] ?? json['city'] ?? 'Grande ABC').toString().trim();
    return BuscaOngItem(
      id: json['id']?.toString() ?? '',
      tituloPrincipal: (json['nome'] ?? json['name'] ?? 'ONG').toString(),
      subtitulo: cidadeParsed,
      imagemUrl: (json['avatar'] ?? json['logoUrl'] ?? json['imagem'] ?? '')
          .toString(),
      tagOuCategoria:
          (json['causaPrincipal'] ?? json['categoria'] ?? 'Causa Social')
              .toString(),
      segundaCaracteristica:
          (json['publicoAlvo'] ?? json['subcategoria'] ?? '').toString(),
      cidade: cidadeParsed.isNotEmpty ? cidadeParsed : 'Grande ABC',
      totalVoluntarios: (json['totalVoluntarios'] as num?)?.toInt() ?? 0,
    );
  }
}

class BuscaVoluntarioItem extends ResultadoBuscaItem {
  final List<String> habilidades;
  final int totalHoras;

  const BuscaVoluntarioItem({
    required super.id,
    required super.tituloPrincipal,
    required super.subtitulo,
    required super.imagemUrl,
    required super.tagOuCategoria,
    super.segundaCaracteristica = '',
    required super.cidade,
    required this.habilidades,
    required this.totalHoras,
  }) : super(tipo: TipoResultadoBusca.voluntario);

  factory BuscaVoluntarioItem.fromJson(Map<String, dynamic> json) {
    final List<String> habs = json['habilidades'] is List
        ? (json['habilidades'] as List<dynamic>)
            .map((dynamic e) => e.toString())
            .toList()
        : <String>[];
    final int horas = (json['totalHoras'] as num?)?.toInt() ?? 0;
    final String cidadeParsed =
        (json['cidade'] ?? json['city'] ?? 'Grande ABC').toString().trim();

    return BuscaVoluntarioItem(
      id: json['id']?.toString() ?? '',
      tituloPrincipal:
          (json['nome'] ?? json['name'] ?? 'Voluntário').toString(),
      subtitulo: cidadeParsed,
      imagemUrl: (json['avatar'] ?? json['fotoUrl'] ?? '').toString(),
      tagOuCategoria: habs.isNotEmpty ? habs.first : 'Voluntariado Comunitário',
      segundaCaracteristica: habs.length > 1 ? habs[1] : '',
      cidade: cidadeParsed.isNotEmpty ? cidadeParsed : 'Grande ABC',
      habilidades: habs,
      totalHoras: horas,
    );
  }
}

class BuscaEventoItem extends ResultadoBuscaItem {
  final String data;
  final String horario;
  final int vagasRestantes;
  final String ongNome;

  const BuscaEventoItem({
    required super.id,
    required super.tituloPrincipal,
    required super.subtitulo,
    required super.imagemUrl,
    required super.tagOuCategoria,
    super.segundaCaracteristica = '',
    required super.cidade,
    required this.data,
    required this.horario,
    required this.vagasRestantes,
    required this.ongNome,
  }) : super(tipo: TipoResultadoBusca.evento);

  factory BuscaEventoItem.fromJson(Map<String, dynamic> json) {
    final int vagas = (json['vagasRestantes'] as num?)?.toInt() ?? 0;
    final String cidadeParsed = (json['cidade'] ??
            json['city'] ??
            json['ong']?['cidade'] ??
            'Grande ABC')
        .toString()
        .trim();

    return BuscaEventoItem(
      id: json['id']?.toString() ?? '',
      tituloPrincipal: (json['titulo'] ?? json['title'] ?? '').toString(),
      subtitulo: cidadeParsed,
      imagemUrl: (json['imagemUrl'] ?? json['banner'] ?? '').toString(),
      tagOuCategoria: "$vagas vagas abertas",
      segundaCaracteristica: (json['data'] ?? '').toString(),
      cidade: cidadeParsed.isNotEmpty ? cidadeParsed : 'Grande ABC',
      data: (json['data'] ?? '').toString(),
      horario: (json['horario'] ?? '').toString(),
      vagasRestantes: vagas,
      ongNome: (json['ongNome'] ?? '').toString(),
    );
  }
}
