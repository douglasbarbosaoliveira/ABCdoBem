// lib/eventos/services/evento_mapper.dart

import '../models/evento_model.dart';

typedef MapaJson = Map<String, dynamic>;

class EventoMapper {
  static List<String> extrairListaStrings(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  static EventoModel mapearJsonParaEvento(MapaJson item) {
    final String id = item['id']?.toString() ?? '';
    final String titulo =
        (item['title'] ?? item['titulo'] ?? 'Oportunidade Voluntária')
            .toString();
    final String ongNome =
        (item['ong']?['name'] ?? item['ongNome'] ?? 'ONG Parceira').toString();
    final String ongId =
        item['ongId']?.toString() ?? item['ong']?['id']?.toString() ?? '';

    final int duracaoHoras = (item['durationHours'] as num?)?.toInt() ?? 4;

    String dataExibicao = "";
    String horarioExibicao = "${duracaoHoras}h de duração";
    DateTime? dtInicio;

    if (item['eventDate'] != null) {
      try {
        dtInicio = DateTime.parse(item['eventDate'].toString()).toLocal();
        dataExibicao =
            "${dtInicio.day.toString().padLeft(2, '0')}/${dtInicio.month.toString().padLeft(2, '0')}";

        DateTime dtFim;
        if (item['endDate'] != null) {
          dtFim = DateTime.parse(item['endDate'].toString()).toLocal();
        } else {
          dtFim = dtInicio.add(Duration(hours: duracaoHoras));
        }

        final iniFmt =
            "${dtInicio.hour.toString().padLeft(2, '0')}:${dtInicio.minute.toString().padLeft(2, '0')}";
        final fimFmt =
            "${dtFim.hour.toString().padLeft(2, '0')}:${dtFim.minute.toString().padLeft(2, '0')}";
        horarioExibicao = "$iniFmt às $fimFmt";
      } catch (_) {
        dataExibicao = item['eventDate'].toString();
      }
    }

    final int vagasTotais =
        (item['totalVacancies'] ?? item['vagasTotais'] as num?)?.toInt() ?? 0;
    final int inscritosApi = (item['acceptedCount'] ??
                item['_count']?['applications'] ??
                item['inscritos'] as num?)
            ?.toInt() ??
        0;
    final bool jaInscrito =
        item['isApplied'] == true || item['isInscrito'] == true;
    final int inscritosEfetivos =
        (jaInscrito && inscritosApi == 0 && vagasTotais > 0) ? 1 : inscritosApi;
    final int vagasRestantes = (vagasTotais - inscritosEfetivos).clamp(0, 999);

    final List<dynamic> categorias = item['categories'] is List
        ? item['categories'] as List<dynamic>
        : (item['tags'] is List ? item['tags'] as List<dynamic> : <dynamic>[]);

    final String categoriaPrincipal = categorias.isNotEmpty
        ? categorias.first.toString()
        : (item['categoria']?.toString() ?? 'Social');

    final String? banner = item['banner']?.toString() ??
        item['imageUrl']?.toString() ??
        item['imagemUrl']?.toString();
    final String foto = (banner != null && banner.trim().isNotEmpty)
        ? banner
        : "https://images.unsplash.com/photo-1497633762265-9d179a990aa6?w=600";

    final String logradouroStr = (item['logradouro'] ?? '').toString().trim();
    final String numeroStr = (item['numero'] ?? '').toString().trim();
    final String bairroStr = (item['bairro'] ?? '').toString().trim();

    String enderecoFormatado;
    if (logradouroStr.isNotEmpty &&
        (numeroStr.isNotEmpty || bairroStr.isNotEmpty)) {
      final numParte = numeroStr.isNotEmpty ? ", $numeroStr" : "";
      final bairroParte = bairroStr.isNotEmpty ? " - $bairroStr" : "";
      enderecoFormatado = "$logradouroStr$numParte$bairroParte";
    } else if (logradouroStr.isNotEmpty) {
      enderecoFormatado = logradouroStr;
    } else {
      enderecoFormatado =
          item['cidade'] != null ? "${item['cidade']} - SP" : 'Grande ABC';
    }

    final int? minAge = int.tryParse((item['minAge'] ?? '').toString());
    final reqApi = extrairListaStrings(
      item['requirements'] ?? item['requisitos'],
    );
    final List<String> requisitosCompletos = <String>[
      if (minAge != null && minAge > 0) "Idade mínima: $minAge anos",
      ...reqApi,
    ];

    final List<String> necessidadesCompletas = extrairListaStrings(
      item['requiredSkills'] ?? item['necessidades'],
    );

    return EventoModel(
      id: id,
      ongId: ongId,
      ongNome: ongNome,
      titulo: titulo,
      categoria: categoriaPrincipal,
      descricao: (item['description'] ??
              item['descricao'] ??
              'Sem descrição detalhada.')
          .toString(),
      cidade: item['cidade']?.toString() ?? 'Grande ABC',
      endereco: enderecoFormatado,
      latitude: (item['latitude'] as num?)?.toDouble() ?? -23.668,
      longitude: (item['longitude'] as num?)?.toDouble() ?? -46.461,
      data: dataExibicao,
      horario: horarioExibicao,
      dataHoraInicio: dtInicio ?? DateTime.now(),
      imagemUrl: foto,
      tags: categorias.map((c) => c.toString()).toList(),
      requisitos: requisitosCompletos,
      necessidades: necessidadesCompletas,
      vagasTotais: vagasTotais,
      vagasRestantes: vagasRestantes,
      criadoEm: DateTime.tryParse(item['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      status: (item['status'] ?? 'OPEN').toString().trim().toUpperCase(),
      isInscrito: jaInscrito,
      statusInscricao: item['applicationStatus']?.toString() ??
          item['statusInscricao']?.toString(),
    );
  }
}