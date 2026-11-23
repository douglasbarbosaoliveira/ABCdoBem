// lib/ongs/services/ong_painel_models.dart

typedef JsonMap = Map<String, dynamic>;

class JsonParsers {
  static double toDouble(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.isFinite ? value.toDouble() : fallback;
    if (value is String) {
      final limpo = value
          .trim()
          .replaceAll('R\$', '')
          .replaceAll(' ', '')
          .replaceAll('.', '')
          .replaceAll(',', '.');
      return double.tryParse(limpo) ?? fallback;
    }
    return fallback;
  }

  static int toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.isFinite ? value.round() : fallback;
    if (value is String) {
      final parsedInt = int.tryParse(value.trim());
      if (parsedInt != null) return parsedInt;
      final parsedDouble = toDouble(value, fallback: double.nan);
      if (!parsedDouble.isNaN && parsedDouble.isFinite) {
        return parsedDouble.round();
      }
    }
    return fallback;
  }

  static List<dynamic> extractList(dynamic decoded, List<String> chaves) {
    if (decoded is List) return decoded;
    if (decoded is JsonMap) {
      for (final chave in chaves) {
        if (decoded[chave] is List) return decoded[chave] as List;
      }
      if (decoded['data'] is List) return decoded['data'] as List;
      if (decoded['data'] is JsonMap) {
        final dataMap = decoded['data'] as JsonMap;
        for (final chave in chaves) {
          if (dataMap[chave] is List) return dataMap[chave] as List;
        }
      }
    }
    return <dynamic>[];
  }

  static JsonMap extractObject(dynamic decoded) {
    if (decoded is JsonMap) {
      if (decoded['data'] is JsonMap) return decoded['data'] as JsonMap;
      return decoded;
    }
    return <String, dynamic>{};
  }
}

class OngMetaItem {
  final String id;
  final String titulo;
  final String? descricao;
  final double valorAtual;
  final double valorMeta;
  final String unidade;
  final String? prazoLimite;
  final String status;

  const OngMetaItem({
    required this.id,
    required this.titulo,
    this.descricao,
    required this.valorAtual,
    required this.valorMeta,
    required this.unidade,
    this.prazoLimite,
    this.status = 'ATIVA',
  });

  double get percentual =>
      valorMeta <= 0 ? 0 : (valorAtual / valorMeta).clamp(0.0, 1.0);

  factory OngMetaItem.fromJson(JsonMap json) {
    return OngMetaItem(
      id: (json['id'] ?? '').toString(),
      titulo:
          (json['titulo'] ?? json['title'] ?? json['nome'] ?? '').toString(),
      descricao:
          json['descricao']?.toString() ?? json['description']?.toString(),
      valorAtual: JsonParsers.toDouble(
        json['valorAtual'] ?? json['currentValue'] ?? json['atual'],
        fallback: 0,
      ),
      valorMeta: JsonParsers.toDouble(
        json['valorMeta'] ?? json['targetValue'] ?? json['meta'],
        fallback: 1,
      ),
      unidade: (json['unidade'] ?? json['unit'] ?? '').toString(),
      prazoLimite:
          json['prazoLimite']?.toString() ?? json['deadline']?.toString(),
      status: (json['status'] ?? 'ATIVA').toString(),
    );
  }
}

class OngCompromissoDoacao {
  final String id;
  final String doadorNome;
  final String? doadorContato;
  final String? volunteerId;
  final double quantidade;
  final String? dataLimiteEntrega;
  final String status; // PROMETIDO, ENTREGUE, ATRASADO, CANCELADO
  final String? observacao;

  const OngCompromissoDoacao({
    required this.id,
    required this.doadorNome,
    this.doadorContato,
    this.volunteerId,
    required this.quantidade,
    this.dataLimiteEntrega,
    required this.status,
    this.observacao,
  });

  factory OngCompromissoDoacao.fromJson(JsonMap json) {
    final volMap = json['volunteer'] is JsonMap
        ? json['volunteer'] as JsonMap
        : (json['user'] is JsonMap
            ? json['user'] as JsonMap
            : <String, dynamic>{});

    return OngCompromissoDoacao(
      id: (json['id'] ?? '').toString(),
      doadorNome: (json['doadorNome'] ??
              json['donorName'] ??
              volMap['name'] ??
              volMap['nome'] ??
              'Voluntário/Doador')
          .toString(),
      doadorContato:
          json['doadorContato']?.toString() ?? json['donorContact']?.toString(),
      volunteerId:
          json['volunteerId']?.toString() ?? json['userId']?.toString(),
      quantidade: JsonParsers.toDouble(
        json['quantidade'] ?? json['quantity'] ?? json['amount'],
        fallback: 0,
      ),
      dataLimiteEntrega: json['dataLimiteEntrega']?.toString() ??
          json['deadline']?.toString() ??
          json['dataLimite']?.toString(),
      status: (json['status'] ?? 'PROMETIDO').toString().toUpperCase(),
      observacao: json['observacao']?.toString() ?? json['notes']?.toString(),
    );
  }
}

class OngSuprimentoItem {
  final String id;
  final String nome;
  final String unidade;
  final double quantidadeMeta;
  final double quantidadeRecebida;
  final double quantidadePrometida;
  final String? prazoLimite;
  final String prioridade;
  final bool sincronizarPerfil;
  final List<OngCompromissoDoacao> compromissos;

  const OngSuprimentoItem({
    required this.id,
    required this.nome,
    required this.unidade,
    required this.quantidadeMeta,
    required this.quantidadeRecebida,
    required this.quantidadePrometida,
    this.prazoLimite,
    this.prioridade = 'NORMAL',
    this.sincronizarPerfil = true,
    this.compromissos = const <OngCompromissoDoacao>[],
  });

  double get saldoFaltante =>
      (quantidadeMeta - quantidadeRecebida - quantidadePrometida)
          .clamp(0.0, double.infinity);

  bool get metaAtingida =>
      quantidadeMeta > 0 && quantidadeRecebida >= quantidadeMeta;

  factory OngSuprimentoItem.fromJson(JsonMap json) {
    final List<dynamic> rawPledges = json['pledges'] as List? ??
        json['compromissos'] as List? ??
        json['donations'] as List? ??
        <dynamic>[];

    return OngSuprimentoItem(
      id: (json['id'] ?? '').toString(),
      nome: (json['nome'] ?? json['name'] ?? json['titulo'] ?? '').toString(),
      unidade: (json['unidade'] ?? json['unit'] ?? 'un').toString(),
      quantidadeMeta: JsonParsers.toDouble(
        json['quantidadeMeta'] ?? json['targetQuantity'] ?? json['meta'],
        fallback: 0,
      ),
      quantidadeRecebida: JsonParsers.toDouble(
        json['quantidadeRecebida'] ??
            json['receivedQuantity'] ??
            json['alcandada'] ??
            json['alcancada'],
        fallback: 0,
      ),
      quantidadePrometida: JsonParsers.toDouble(
        json['quantidadePrometida'] ??
            json['pledgedQuantity'] ??
            json['prometida'],
        fallback: 0,
      ),
      prazoLimite:
          json['prazoLimite']?.toString() ?? json['deadline']?.toString(),
      prioridade:
          (json['prioridade'] ?? json['priority'] ?? json['status'] ?? 'NORMAL')
              .toString(),
      sincronizarPerfil: json['sincronizarPerfil'] as bool? ??
          json['syncProfile'] as bool? ??
          true,
      compromissos: rawPledges
          .whereType<JsonMap>()
          .map(OngCompromissoDoacao.fromJson)
          .toList(),
    );
  }
}

class OngAcaoResumo {
  final String id;
  final String titulo;
  final String dataFormatada;
  final String horarioFormatado;
  final DateTime? dataEvento;
  final int vagasOcupadas;
  final int vagasTotais;
  final int duracaoHoras;
  final String status;

  const OngAcaoResumo({
    required this.id,
    required this.titulo,
    required this.dataFormatada,
    required this.horarioFormatado,
    this.dataEvento,
    required this.vagasOcupadas,
    required this.vagasTotais,
    required this.duracaoHoras,
    required this.status,
  });

  double get ocupacao =>
      vagasTotais <= 0 ? 0 : (vagasOcupadas / vagasTotais).clamp(0.0, 1.0);
}

class VoluntarioGuardiaoResumo {
  final String id;
  final String nome;
  final String? avatarUrl;
  final int acoesConcluidas;
  final int horasAcumuladas;

  const VoluntarioGuardiaoResumo({
    required this.id,
    required this.nome,
    this.avatarUrl,
    required this.acoesConcluidas,
    required this.horasAcumuladas,
  });
}

class UltimoPostOngResumo {
  final String id;
  final String tituloOuTexto;
  final int curtidas;
  final int comentarios;
  final String statusLabel;
  final String? nomeAutor;
  final String? fotoAutor;
  final String? dataPostagem;
  final String? nomeEvento;
  final String? imagemUrl;
  final bool curtido;

  const UltimoPostOngResumo({
    required this.id,
    required this.tituloOuTexto,
    required this.curtidas,
    required this.comentarios,
    this.statusLabel = 'Publicado',
    this.nomeAutor,
    this.fotoAutor,
    this.dataPostagem,
    this.nomeEvento,
    this.imagemUrl,
    this.curtido = false,
  });

  factory UltimoPostOngResumo.fromJson(
    JsonMap json, {
    String? nomeOngFallback,
    String? avatarOngFallback,
  }) {
    final titulo = (json['title'] ?? json['titulo'] ?? '').toString().trim();
    final corpo = (json['content'] ?? json['text'] ?? json['descricao'] ?? '')
        .toString()
        .trim();
    final textoFinal = titulo.isNotEmpty && corpo.isNotEmpty && titulo != corpo
        ? '$titulo\n$corpo'
        : (corpo.isNotEmpty
            ? corpo
            : (titulo.isNotEmpty ? titulo : 'Publicação recente da ONG'));

    final countMap = json['_count'] is JsonMap
        ? json['_count'] as JsonMap
        : <String, dynamic>{};
    final curtidas = JsonParsers.toInt(
      countMap['likes'] ?? json['likesCount'] ?? json['curtidas'],
      fallback: 0,
    );
    final comentarios = JsonParsers.toInt(
      countMap['comments'] ?? json['commentsCount'] ?? json['comentarios'],
      fallback: 0,
    );

    final autorObj = json['author'] is JsonMap
        ? json['author'] as JsonMap
        : (json['ong'] is JsonMap
            ? json['ong'] as JsonMap
            : <String, dynamic>{});

    final nomeAutor =
        (autorObj['name'] ?? autorObj['nome'] ?? nomeOngFallback ?? '')
            .toString()
            .trim();
    final fotoAutor =
        (autorObj['avatar'] ?? autorObj['logoUrl'] ?? avatarOngFallback ?? '')
            .toString()
            .trim();

    final dataPostagem =
        (json['createdAt'] ?? json['dataPostagem'] ?? json['data'] ?? '')
            .toString()
            .trim();

    final nomeEvento = (json['opportunity'] is JsonMap
            ? (json['opportunity'] as JsonMap)['title']
            : null) ??
        json['eventTitle'] ??
        json['nomeEvento'] ??
        '';

    String? imagemUrl;
    final rawImg = (json['imageUrl'] ??
            json['imagemUrl'] ??
            json['image'] ??
            json['fotoUrl'] ??
            '')
        .toString()
        .trim();
    if (rawImg.isNotEmpty) {
      imagemUrl = rawImg;
    } else if (json['images'] is List && (json['images'] as List).isNotEmpty) {
      final primeira = (json['images'] as List).first;
      if (primeira is String && primeira.trim().isNotEmpty) {
        imagemUrl = primeira.trim();
      } else if (primeira is JsonMap) {
        final u =
            (primeira['url'] ?? primeira['imageUrl'] ?? '').toString().trim();
        if (u.isNotEmpty) imagemUrl = u;
      }
    }

    return UltimoPostOngResumo(
      id: (json['id'] ?? '').toString(),
      tituloOuTexto: textoFinal,
      curtidas: curtidas,
      comentarios: comentarios,
      statusLabel: (json['status'] ?? 'Publicado').toString(),
      nomeAutor: nomeAutor.isNotEmpty ? nomeAutor : null,
      fotoAutor: fotoAutor.isNotEmpty ? fotoAutor : null,
      dataPostagem: dataPostagem.isNotEmpty ? dataPostagem : null,
      nomeEvento: nomeEvento.toString().trim().isNotEmpty
          ? nomeEvento.toString().trim()
          : null,
      imagemUrl: imagemUrl,
      curtido: json['liked'] == true || json['curtido'] == true,
    );
  }
}

class OngPainelDados {
  final String nomeOng;
  final String? avatarOng;
  final String cidadeOng;
  final int horasDoadas;
  final int percentualVagasPreenchidas;
  final int percentualRetencaoVoluntarios;
  final double valorArrecadadoDinheiro;
  final double gastos;
  final List<OngAcaoResumo> acoes;
  final List<VoluntarioGuardiaoResumo> voluntariosGuardioes;
  final List<OngMetaItem> metas;
  final List<OngSuprimentoItem> suprimentos;
  final List<UltimoPostOngResumo> publicacoesOng;
  final UltimoPostOngResumo? ultimoPost;

  const OngPainelDados({
    required this.nomeOng,
    this.avatarOng,
    required this.cidadeOng,
    required this.horasDoadas,
    required this.percentualVagasPreenchidas,
    required this.percentualRetencaoVoluntarios,
    this.valorArrecadadoDinheiro = 0,
    this.gastos = 0,
    required this.acoes,
    required this.voluntariosGuardioes,
    required this.metas,
    required this.suprimentos,
    this.publicacoesOng = const <UltimoPostOngResumo>[],
    this.ultimoPost,
  });
}
