// lib/ongs/models/ong_detail_models.dart

class OngPostagemModel {
  final String id;
  final String titulo;
  final String texto;
  final String dataFormatada;
  final String? imagemUrl;
  final int curtidas;

  OngPostagemModel({
    required this.id,
    required this.titulo,
    required this.texto,
    required this.dataFormatada,
    this.imagemUrl,
    this.curtidas = 0,
  });

  factory OngPostagemModel.fromJson(Map<String, dynamic> json) {
    return OngPostagemModel(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo'] ?? '',
      texto: json['texto'] ?? '',
      dataFormatada: json['data'] ?? 'Recente',
      imagemUrl: json['imagemUrl'],
      curtidas: json['curtidas'] ?? 0,
    );
  }
}

class OngOportunidadeModel {
  final String id;
  final String titulo;
  final String data;
  final String horario;
  final int vagasRestantes;
  final String imagemUrl;
  final bool isInscrito;

  OngOportunidadeModel({
    required this.id,
    required this.titulo,
    required this.data,
    required this.horario,
    required this.vagasRestantes,
    required this.imagemUrl,
    this.isInscrito = false,
  });

  factory OngOportunidadeModel.fromJson(Map<String, dynamic> json) {
    return OngOportunidadeModel(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo'] ?? '',
      data: json['data'] ?? '',
      horario: json['horario'] ?? '',
      vagasRestantes: json['vagasRestantes'] ?? 0,
      imagemUrl: json['imagemUrl']?.toString() ?? '',
      isInscrito: json['isInscrito'] == true || json['isApplied'] == true,
    );
  }
}

class OngDetalheModel {
  final String id;
  final String nome;
  final String razaoSocial;
  final String cnpj;
  final String email;
  final String categoria;
  final String cidade;
  final String estado;
  final String enderecoCompleto;
  final String logoUrl;
  final String bannerUrl;
  final String sobre;
  final int voluntariosAtivos;
  final int eventosRealizados;
  final int anosAtuacao;
  final DateTime? criadoEm;
  final int totalSeguidores;
  final bool isSeguindo;
  final List<String> necessidadesUrgentes;
  final String? site;
  final String? instagram;
  final String? facebook;
  final String? tiktok;
  final String? linkedin;
  final String? whatsapp;
  final String? telefone;
  final String? chavePix;
  final String? horarioRecebimentoDoacoes;
  final double latitude;
  final double longitude;
  final List<OngOportunidadeModel> oportunidadesAbertas;
  final List<OngOportunidadeModel> eventosPassados;
  final List<OngPostagemModel> publicacoes;

  OngDetalheModel({
    required this.id,
    required this.nome,
    this.razaoSocial = '',
    this.cnpj = '',
    this.email = '',
    required this.categoria,
    required this.cidade,
    required this.estado,
    required this.enderecoCompleto,
    required this.logoUrl,
    required this.bannerUrl,
    required this.sobre,
    required this.voluntariosAtivos,
    required this.eventosRealizados,
    required this.anosAtuacao,
    this.criadoEm,
    required this.totalSeguidores,
    required this.isSeguindo,
    required this.necessidadesUrgentes,
    this.site,
    this.instagram,
    this.facebook,
    this.tiktok,
    this.linkedin,
    this.whatsapp,
    this.telefone,
    this.chavePix,
    this.horarioRecebimentoDoacoes,
    required this.latitude,
    required this.longitude,
    required this.oportunidadesAbertas,
    this.eventosPassados = const <OngOportunidadeModel>[],
    required this.publicacoes,
  });

  factory OngDetalheModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawOp = json['oportunidades'] as List? ?? [];
    final List<dynamic> rawPassados = json['eventosPassados'] as List? ?? [];
    final List<dynamic> rawPosts = json['publicacoes'] as List? ?? [];

    return OngDetalheModel(
      id: json['id']?.toString() ?? '',
      nome: json['name'] ?? json['nome'] ?? '',
      razaoSocial: json['razaoSocial']?.toString() ?? '',
      cnpj: json['cnpj']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      categoria: json['causaPrincipal'] ?? json['categoria'] ?? '',
      cidade: json['cidade'] ?? '',
      estado: json['estado'] ?? '',
      enderecoCompleto: json['enderecoCompleto'] ?? '',
      logoUrl: json['avatar'] ?? json['logoUrl'] ?? '',
      bannerUrl: json['banner'] ?? json['bannerUrl'] ?? '',
      sobre: json['descricao'] ?? json['sobre'] ?? '',
      voluntariosAtivos: json['voluntariosAtivos'] ?? 0,
      eventosRealizados: json['eventosRealizados'] ?? 0,
      anosAtuacao: json['anosAtuacao'] ?? 1,
      criadoEm:
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal(),
      totalSeguidores: json['totalSeguidores'] ?? 0,
      isSeguindo: json['isSeguindo'] ?? false,
      necessidadesUrgentes: List<String>.from(json['necessidadesAtuais'] ?? []),
      site: json['site']?.toString(),
      instagram: json['instagram']?.toString(),
      facebook: json['facebook']?.toString(),
      tiktok: json['tiktok']?.toString(),
      linkedin: json['linkedin']?.toString(),
      whatsapp: json['whatsapp']?.toString(),
      telefone: (json['telefoneFixo'] ?? json['telefone'])?.toString(),
      chavePix: json['chavePix']?.toString(),
      horarioRecebimentoDoacoes: json['horarioRecebimentoDoacoes']?.toString(),
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 0,
      oportunidadesAbertas:
          rawOp.map((o) => OngOportunidadeModel.fromJson(o)).toList(),
      eventosPassados:
          rawPassados.map((p) => OngOportunidadeModel.fromJson(p)).toList(),
      publicacoes: rawPosts.map((p) => OngPostagemModel.fromJson(p)).toList(),
    );
  }
}
