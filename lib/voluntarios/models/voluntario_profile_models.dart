// lib/voluntarios/models/voluntario_profile_models.dart

import 'dart:convert';

class AcaoParticipadaVoluntarioModel {
  final String id;
  final String opportunityId;
  final String titulo;
  final String ongNome;
  final String dataFormatada;
  final int duracaoHoras;
  final String status;
  final bool emiteCertificado;
  final String? fotoUrl;

  const AcaoParticipadaVoluntarioModel({
    required this.id,
    required this.opportunityId,
    required this.titulo,
    required this.ongNome,
    required this.dataFormatada,
    required this.duracaoHoras,
    required this.status,
    this.emiteCertificado = false,
    this.fotoUrl,
  });

  bool get isConcluidaOuAprovada {
    final s = status.toUpperCase().trim();
    return s == 'ACCEPTED' ||
        s == 'APPROVED' ||
        s == 'CONFIRMED' ||
        s == 'CONFIRMADA' ||
        s == 'APROVADO' ||
        s == 'PRESENTE' ||
        s == 'ATTENDED' ||
        s == 'COMPLETED';
  }
}

class ExperienciaFeedModel {
  final String id;
  final String ongNome;
  final String dataFormatada;
  final String texto;
  final String? imagemUrl;
  final int curtidas;

  const ExperienciaFeedModel({
    required this.id,
    required this.ongNome,
    required this.dataFormatada,
    required this.texto,
    this.imagemUrl,
    this.curtidas = 0,
  });

  factory ExperienciaFeedModel.fromJson(Map<String, dynamic> json) {
    return ExperienciaFeedModel(
      id: json['id']?.toString() ?? '',
      ongNome: (json['ongNome'] ??
              json['ongName'] ??
              json['opportunity']?['ong']?['name'] ??
              'Instituição Parceira')
          .toString(),
      dataFormatada: (json['data'] ??
              json['dataFormatada'] ??
              json['formattedDate'] ??
              'Recente')
          .toString(),
      texto:
          (json['texto'] ?? json['text'] ?? json['content'] ?? '').toString(),
      imagemUrl:
          (json['imagemUrl'] ?? json['imageUrl'] ?? json['photo'])?.toString(),
      curtidas: (json['curtidas'] ??
                  json['likesCount'] ??
                  json['_count']?['likes'] as num?)
              ?.toInt() ??
          0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ongNome': ongNome,
        'dataFormatada': dataFormatada,
        'texto': texto,
        'imagemUrl': imagemUrl,
        'curtidas': curtidas,
      };

  ExperienciaFeedModel copyWith({
    String? id,
    String? ongNome,
    String? dataFormatada,
    String? texto,
    String? imagemUrl,
    int? curtidas,
  }) {
    return ExperienciaFeedModel(
      id: id ?? this.id,
      ongNome: ongNome ?? this.ongNome,
      dataFormatada: dataFormatada ?? this.dataFormatada,
      texto: texto ?? this.texto,
      imagemUrl: imagemUrl ?? this.imagemUrl,
      curtidas: curtidas ?? this.curtidas,
    );
  }
}

class VoluntarioPerfilModel {
  final String id;
  final String nome;
  final String email;
  final String cpf;
  final String nascimento;
  final String cidade;
  final String estado;
  final String cep;
  final String logradouro;
  final String numero;
  final String bairro;
  final String fotoUrl;
  final String bannerUrl;
  final int totalEventos;
  final int totalHoras;
  final int estrelasEngajamento;
  final String tempoAtivo;
  final String bio;
  final List<String> causasInteresse;
  final List<String> habilidades;
  final List<String> disponibilidade;
  final String escolaridade;
  final String curso;
  final String? instagram;
  final String? facebook;
  final String? linkedin;
  final String? tiktok;
  final String? site;
  final String? whatsapp;
  final List<AcaoParticipadaVoluntarioModel> acoesParticipadas;
  final List<ExperienciaFeedModel> experiencias;

  const VoluntarioPerfilModel({
    required this.id,
    required this.nome,
    this.email = '',
    required this.cpf,
    required this.nascimento,
    required this.cidade,
    required this.estado,
    required this.cep,
    required this.logradouro,
    required this.numero,
    required this.bairro,
    required this.fotoUrl,
    required this.bannerUrl,
    required this.totalEventos,
    required this.totalHoras,
    this.estrelasEngajamento = 1,
    required this.tempoAtivo,
    required this.bio,
    this.causasInteresse = const <String>[],
    required this.habilidades,
    required this.disponibilidade,
    required this.escolaridade,
    required this.curso,
    this.instagram,
    this.facebook,
    this.linkedin,
    this.tiktok,
    this.site,
    this.whatsapp,
    this.acoesParticipadas = const <AcaoParticipadaVoluntarioModel>[],
    required this.experiencias,
  });

  static String sanitizarImagem(dynamic rawImg, {String fallback = ''}) {
    if (rawImg == null) return fallback;
    final String url = rawImg.toString().trim();
    if (url.isEmpty ||
        url == 'null' ||
        url.contains('default.png') ||
        url.contains('placeholder') ||
        url.contains('storage.xyz') ||
        url.contains('example.com')) {
      return fallback;
    }
    if (url.startsWith('data:image')) return url;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return 'https://abc-do-bem.onrender.com$url';
    return 'https://abc-do-bem.onrender.com/$url';
  }

  static List<String> extrairLista(dynamic raw) {
    if (raw == null) return <String>[];
    if (raw is List) {
      return raw
          .map((dynamic e) => e.toString().trim())
          .where((String s) => s.isNotEmpty && s != 'null')
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      final str = raw.trim();
      if (str.startsWith('[')) {
        try {
          final decoded = jsonDecode(str);
          if (decoded is List) {
            return decoded
                .map((dynamic e) => e.toString().trim())
                .where((String s) => s.isNotEmpty && s != 'null')
                .toList();
          }
        } catch (_) {}
      }
      return str
          .split(',')
          .map((String e) => e.trim())
          .where((String s) => s.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  static String? sanitizarContato(dynamic raw) {
    if (raw == null) return null;
    final str = raw.toString().trim();
    if (str.isEmpty ||
        str == 'null' ||
        str == '(11) 99999-9999' ||
        str == '11999999999') {
      return null;
    }
    return str;
  }

  VoluntarioPerfilModel copyWith({
    String? id,
    String? nome,
    String? email,
    String? cpf,
    String? nascimento,
    String? cidade,
    String? estado,
    String? cep,
    String? logradouro,
    String? numero,
    String? bairro,
    String? fotoUrl,
    String? bannerUrl,
    int? totalEventos,
    int? totalHoras,
    int? estrelasEngajamento,
    String? tempoAtivo,
    String? bio,
    List<String>? causasInteresse,
    List<String>? habilidades,
    List<String>? disponibilidade,
    String? escolaridade,
    String? curso,
    String? instagram,
    String? facebook,
    String? linkedin,
    String? tiktok,
    String? site,
    String? whatsapp,
    List<AcaoParticipadaVoluntarioModel>? acoesParticipadas,
    List<ExperienciaFeedModel>? experiencias,
  }) {
    return VoluntarioPerfilModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      cpf: cpf ?? this.cpf,
      nascimento: nascimento ?? this.nascimento,
      cidade: cidade ?? this.cidade,
      estado: estado ?? this.estado,
      cep: cep ?? this.cep,
      logradouro: logradouro ?? this.logradouro,
      numero: numero ?? this.numero,
      bairro: bairro ?? this.bairro,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      totalEventos: totalEventos ?? this.totalEventos,
      totalHoras: totalHoras ?? this.totalHoras,
      estrelasEngajamento: estrelasEngajamento ?? this.estrelasEngajamento,
      tempoAtivo: tempoAtivo ?? this.tempoAtivo,
      bio: bio ?? this.bio,
      causasInteresse: causasInteresse ?? this.causasInteresse,
      habilidades: habilidades ?? this.habilidades,
      disponibilidade: disponibilidade ?? this.disponibilidade,
      escolaridade: escolaridade ?? this.escolaridade,
      curso: curso ?? this.curso,
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      linkedin: linkedin ?? this.linkedin,
      tiktok: tiktok ?? this.tiktok,
      site: site ?? this.site,
      whatsapp: whatsapp ?? this.whatsapp,
      acoesParticipadas: acoesParticipadas ?? this.acoesParticipadas,
      experiencias: experiencias ?? this.experiencias,
    );
  }

  factory VoluntarioPerfilModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data =
        json['data'] is Map<String, dynamic> ? json['data'] : json;

    final List<dynamic> rawExp = data['experiencias'] is List
        ? data['experiencias'] as List<dynamic>
        : <dynamic>[];

    final List<ExperienciaFeedModel> listaExperiencias =
        <ExperienciaFeedModel>[];
    for (final dynamic e in rawExp) {
      if (e is Map<String, dynamic>) {
        listaExperiencias.add(ExperienciaFeedModel.fromJson(e));
      } else if (e is Map) {
        listaExperiencias.add(
          ExperienciaFeedModel.fromJson(Map<String, dynamic>.from(e)),
        );
      }
    }

    final List<String> habilidadesList = <String>{
      ...extrairLista(data['habilidades']),
      ...extrairLista(data['skills']),
    }.toList();

    final List<String> disponibilidadeList = <String>{
      ...extrairLista(data['disponibilidade']),
      ...extrairLista(data['availability']),
    }.toList();

    final List<String> causasList = <String>{
      ...extrairLista(data['causasInteresse']),
      ...extrairLista(data['causas']),
      ...extrairLista(data['causes']),
      ...extrairLista(data['interests']),
    }.toList();

    String tempoAtivoFmt = (data['tempoAtivo'] ?? '').toString().trim();
    if (tempoAtivoFmt.isEmpty && data['createdAt'] != null) {
      final dt = DateTime.tryParse(data['createdAt'].toString());
      if (dt != null) {
        final meses = DateTime.now().difference(dt).inDays ~/ 30;
        tempoAtivoFmt = meses <= 1 ? 'Recente no ABC' : '$meses meses no ABC';
      }
    }
    if (tempoAtivoFmt.isEmpty) tempoAtivoFmt = 'Ativo no ABC';

    final int eventosCount =
        (data['totalEventos'] ?? data['totalEvents'] as num?)?.toInt() ?? 0;
    final int horasCount =
        (data['totalHoras'] ?? data['totalHours'] as num?)?.toInt() ?? 0;

    return VoluntarioPerfilModel(
      id: data['id']?.toString() ?? 'voluntario-1',
      nome: (data['name'] ?? data['nome'] ?? 'Voluntário').toString().trim(),
      email: (data['email'] ?? '').toString().trim(),
      cpf: (data['cpf'] ?? '').toString().trim(),
      nascimento:
          (data['nascimento'] ?? data['birthDate'] ?? '').toString().trim(),
      cidade:
          (data['cidade'] ?? data['city'] ?? 'Grande ABC').toString().trim(),
      estado: (data['estado'] ?? data['state'] ?? 'SP').toString().trim(),
      cep: (data['cep'] ?? '').toString().trim(),
      logradouro: (data['logradouro'] ?? '').toString().trim(),
      numero: (data['numero'] ?? '').toString().trim(),
      bairro: (data['bairro'] ?? '').toString().trim(),
      fotoUrl: sanitizarImagem(data['avatar'] ?? data['fotoUrl']),
      bannerUrl: sanitizarImagem(data['banner'] ?? data['bannerUrl']),
      totalEventos: eventosCount,
      totalHoras: horasCount,
      estrelasEngajamento:
          (data['estrelas'] ?? data['rating'] as num?)?.toInt() ?? 1,
      tempoAtivo: tempoAtivoFmt,
      bio: (data['bio'] ?? data['descricao'] ?? data['about'] ?? '')
          .toString()
          .trim(),
      causasInteresse: causasList,
      habilidades: habilidadesList,
      disponibilidade: disponibilidadeList,
      escolaridade:
          (data['escolaridade'] ?? data['education'] ?? '').toString().trim(),
      curso: (data['curso'] ?? data['course'] ?? '').toString().trim(),
      instagram: sanitizarContato(data['instagram']),
      facebook: sanitizarContato(data['facebook']),
      linkedin: sanitizarContato(data['linkedin']),
      tiktok: sanitizarContato(data['tiktok']),
      site: sanitizarContato(data['site'] ?? data['portfolio']),
      whatsapp: sanitizarContato(data['whatsapp'] ?? data['telefone']),
      experiencias: listaExperiencias,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'email': email,
        'cpf': cpf,
        'nascimento': nascimento,
        'cidade': cidade,
        'estado': estado,
        'cep': cep,
        'logradouro': logradouro,
        'numero': numero,
        'bairro': bairro,
        'fotoUrl': fotoUrl,
        'bannerUrl': bannerUrl,
        'totalEventos': totalEventos,
        'totalHoras': totalHoras,
        'estrelasEngajamento': estrelasEngajamento,
        'tempoAtivo': tempoAtivo,
        'bio': bio,
        'causasInteresse': causasInteresse,
        'habilidades': habilidades,
        'disponibilidade': disponibilidade,
        'escolaridade': escolaridade,
        'curso': curso,
        'instagram': instagram,
        'facebook': facebook,
        'linkedin': linkedin,
        'tiktok': tiktok,
        'site': site,
        'whatsapp': whatsapp,
        'experiencias': experiencias.map((e) => e.toJson()).toList(),
      };
}
