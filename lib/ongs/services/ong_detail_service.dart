// lib/ongs/services/ong_detail_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../services/session_service.dart';
import '../../ongs/models/ong_detail_models.dart';

typedef OngPayloadMap = Map<String, dynamic>;

class OngDetailService {
  final String baseUrl = 'https://abc-do-bem.onrender.com';

  Map<String, String> _headers(String? token, {bool jsonBody = false}) {
    final String? t = (token != null && token.trim().isNotEmpty)
        ? token.trim()
        : SessionService.instance.token;
    return <String, String>{
      'Accept': 'application/json',
      if (jsonBody) 'Content-Type': 'application/json',
      if (t != null && t.isNotEmpty) 'Authorization': 'Bearer $t',
    };
  }

  /// Atualiza o perfil da ONG autenticada via PATCH /users/ongs/me
  Future<OngPayloadMap> atualizarPerfilOng(
    OngPayloadMap payload, {
    String? token,
  }) async {
    final Uri uri = Uri.parse('$baseUrl/users/ongs/me');
    final http.Response response = await http
        .patch(
          uri,
          headers: _headers(token, jsonBody: true),
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String mensagem = 'Não foi possível atualizar o perfil da ONG.';
      try {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is OngPayloadMap) {
          final dynamic errMsg = decoded['message'] ?? decoded['error'];
          if (errMsg != null && errMsg.toString().trim().isNotEmpty) {
            mensagem = errMsg.toString().trim();
          }
        }
      } catch (_) {}
      throw Exception(mensagem);
    }

    if (response.bodyBytes.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is OngPayloadMap) {
        if (decoded['data'] is OngPayloadMap) {
          return decoded['data'] as OngPayloadMap;
        }
        return decoded;
      }
    } catch (_) {}

    return <String, dynamic>{};
  }

  String _resolverImagemReal(dynamic rawImg, {String fallback = ''}) {
    if (rawImg == null) return fallback;
    final String url = rawImg.toString().trim();
    if (url.isEmpty ||
        url == 'null' ||
        url.contains('default.png') ||
        url.contains('placeholder')) {
      return fallback;
    }
    if (url.startsWith('data:image')) return url;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '$baseUrl$url';
    return '$baseUrl/$url';
  }

  String _extrairImagemEvento(OngPayloadMap item) {
    final dynamic candidates = item['banner'] ??
        item['bannerUrl'] ??
        item['imageUrl'] ??
        item['imagemUrl'] ??
        item['fotoUrl'] ??
        item['image'];

    if (candidates is List && candidates.isNotEmpty) {
      return _resolverImagemReal(candidates.first);
    }

    if (candidates is String) {
      final String trimmed = candidates.trim();
      if (trimmed.startsWith('[')) {
        try {
          final dynamic decoded = jsonDecode(trimmed);
          if (decoded is List && decoded.isNotEmpty) {
            return _resolverImagemReal(decoded.first);
          }
        } catch (_) {}
      }
      return _resolverImagemReal(trimmed);
    }

    if (item['images'] is List && (item['images'] as List).isNotEmpty) {
      return _resolverImagemReal((item['images'] as List).first);
    }

    return '';
  }

  List<String> _extrairListaStrings(dynamic raw) {
    if (raw == null) return <String>[];
    if (raw is List) {
      return raw
          .map((dynamic e) => e.toString().trim())
          .where((String s) => s.isNotEmpty && s != 'null')
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      final String str = raw.trim();
      if (str.startsWith('[')) {
        try {
          final dynamic decoded = jsonDecode(str);
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

  void _coletarIdsVoluntariosDeLista(
    List<dynamic> lista,
    Set<String> destino,
  ) {
    for (final dynamic app in lista) {
      if (app is! OngPayloadMap) continue;
      final String status = (app['status'] ?? '').toString().toUpperCase();
      // Ignora candidaturas explicitamente rejeitadas ou canceladas
      if (status == 'REJECTED' ||
          status == 'CANCELLED' ||
          status == 'CANCELED') {
        continue;
      }
      final String volId = (app['volunteerId'] ??
              app['userId'] ??
              app['volunteer']?['id'] ??
              app['user']?['id'] ??
              '')
          .toString()
          .trim();
      if (volId.isNotEmpty) {
        destino.add(volId);
      }
    }
  }

  Future<OngDetalheModel> buscarDetalhesOng(
    String ongId, {
    String? voluntarioId,
    String? token,
  }) async {
    final Map<String, String> headers = _headers(token);
    OngPayloadMap perfilBruto = <String, dynamic>{};

    // 1. Tenta GET /users/{id}
    try {
      final http.Response resUser = await http
          .get(Uri.parse('$baseUrl/users/$ongId'), headers: headers)
          .timeout(const Duration(seconds: 12));
      if (resUser.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(resUser.bodyBytes));
        if (decoded is OngPayloadMap) {
          perfilBruto = decoded['data'] is OngPayloadMap
              ? decoded['data'] as OngPayloadMap
              : decoded;
        }
      }
    } catch (e) {
      debugPrint('OngDetailService: falha em /users/$ongId -> $e');
    }

    // 2. Fallback em GET /users/ongs
    if (perfilBruto.isEmpty) {
      try {
        final http.Response resOngs = await http
            .get(Uri.parse('$baseUrl/users/ongs'), headers: headers)
            .timeout(const Duration(seconds: 12));
        if (resOngs.statusCode == 200) {
          final dynamic decoded = jsonDecode(utf8.decode(resOngs.bodyBytes));
          final List<dynamic> lista =
              decoded is List ? decoded : (decoded['data'] ?? <dynamic>[]);
          for (final dynamic item in lista) {
            if (item is OngPayloadMap && item['id']?.toString() == ongId) {
              perfilBruto = item;
              break;
            }
          }
        }
      } catch (e) {
        debugPrint('OngDetailService: falha em /users/ongs -> $e');
      }
    }

    // 3. Busca oportunidades e eventos reais da ONG
    final List<dynamic> eventosBrutos = <dynamic>[];
    final Set<String> idsEventosColetados = <String>{};

    try {
      final http.Response resOps = await http
          .get(Uri.parse('$baseUrl/opportunities/ong/$ongId'), headers: headers)
          .timeout(const Duration(seconds: 12));
      if (resOps.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(resOps.bodyBytes));
        final List<dynamic> lista =
            decoded is List ? decoded : (decoded['data'] ?? <dynamic>[]);
        for (final dynamic item in lista) {
          if (item is OngPayloadMap) {
            final String evId = item['id']?.toString() ?? '';
            if (evId.isNotEmpty) idsEventosColetados.add(evId);
            eventosBrutos.add(item);
          }
        }
      }
    } catch (e) {
      debugPrint('OngDetailService: falha em /opportunities/ong/$ongId -> $e');
    }

    try {
      final http.Response resAllOps = await http
          .get(Uri.parse('$baseUrl/opportunities'), headers: headers)
          .timeout(const Duration(seconds: 12));
      if (resAllOps.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(resAllOps.bodyBytes));
        final List<dynamic> lista =
            decoded is List ? decoded : (decoded['data'] ?? <dynamic>[]);
        for (final dynamic item in lista) {
          if (item is OngPayloadMap) {
            final String itemOngId = item['ongId']?.toString() ??
                item['ong']?['id']?.toString() ??
                '';
            final String evId = item['id']?.toString() ?? '';
            if (itemOngId == ongId &&
                (evId.isEmpty || !idsEventosColetados.contains(evId))) {
              if (evId.isNotEmpty) idsEventosColetados.add(evId);
              eventosBrutos.add(item);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('OngDetailService: falha em /opportunities -> $e');
    }

    // 4. Contagem real de voluntários independentes únicos que já ajudaram a ONG
    final Set<String> idsVoluntariosUnicos = <String>{};
    int somaContadoresEventos = 0;

    for (final dynamic rawItem in eventosBrutos) {
      if (rawItem is! OngPayloadMap) continue;

      final List<dynamic> appsEmbutidas = rawItem['applications'] as List? ??
          rawItem['inscricoes'] as List? ??
          rawItem['volunteers'] as List? ??
          <dynamic>[];

      if (appsEmbutidas.isNotEmpty) {
        _coletarIdsVoluntariosDeLista(appsEmbutidas, idsVoluntariosUnicos);
      } else {
        final String oppId = (rawItem['id'] ?? '').toString().trim();
        if (oppId.isNotEmpty) {
          try {
            final http.Response resApps = await http
                .get(
                  Uri.parse('$baseUrl/opportunities/$oppId/applications'),
                  headers: headers,
                )
                .timeout(const Duration(seconds: 8));
            if (resApps.statusCode == 200) {
              final dynamic decodedApps =
                  jsonDecode(utf8.decode(resApps.bodyBytes));
              final List<dynamic> listaApps = decodedApps is List
                  ? decodedApps
                  : (decodedApps['data'] ??
                      decodedApps['applications'] ??
                      <dynamic>[]);
              _coletarIdsVoluntariosDeLista(listaApps, idsVoluntariosUnicos);
            }
          } catch (_) {}
        }
      }

      somaContadoresEventos += (rawItem['acceptedCount'] as num?)?.toInt() ??
          (rawItem['_count']?['applications'] as num?)?.toInt() ??
          0;
    }

    // 5. Busca postagens / relatos reais da ONG na comunidade (GET /social/feed)
    final List<OngPostagemModel> publicacoes = <OngPostagemModel>[];
    try {
      final http.Response resFeed = await http
          .get(Uri.parse('$baseUrl/social/feed?limit=50'), headers: headers)
          .timeout(const Duration(seconds: 12));
      if (resFeed.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(resFeed.bodyBytes));
        final List<dynamic> posts =
            decoded is List ? decoded : (decoded['data'] ?? <dynamic>[]);

        for (final dynamic p in posts) {
          if (p is! OngPayloadMap) continue;

          final String authorId = p['authorId']?.toString() ??
              p['userId']?.toString() ??
              p['author']?['id']?.toString() ??
              p['user']?['id']?.toString() ??
              '';
          final String oppOngId = p['opportunity']?['ongId']?.toString() ??
              p['opportunity']?['ong']?['id']?.toString() ??
              '';

          if (authorId == ongId || oppOngId == ongId) {
            String dataPost = '';
            if (p['createdAt'] != null) {
              try {
                final DateTime dt =
                    DateTime.parse(p['createdAt'].toString()).toLocal();
                dataPost =
                    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
              } catch (_) {}
            }

            String fotoPost = '';
            if (p['images'] is List && (p['images'] as List).isNotEmpty) {
              fotoPost = _resolverImagemReal((p['images'] as List).first);
            } else {
              fotoPost = _resolverImagemReal(
                p['imageUrl'] ?? p['imagemUrl'] ?? p['photo'],
              );
            }

            final String tituloAcao =
                p['opportunity']?['title']?.toString().trim() ??
                    p['title']?.toString().trim() ??
                    '';

            final String relato =
                (p['content'] ?? p['text'] ?? p['descricao'] ?? '')
                    .toString()
                    .trim();

            final int curtidas = (p['_count']?['likes'] as num?)?.toInt() ??
                (p['likesCount'] as num?)?.toInt() ??
                (p['curtidas'] as num?)?.toInt() ??
                0;

            if (relato.isNotEmpty || fotoPost.isNotEmpty) {
              publicacoes.add(
                OngPostagemModel(
                  id: (p['id'] ?? '').toString(),
                  titulo: tituloAcao,
                  texto: relato,
                  dataFormatada: dataPost,
                  imagemUrl: fotoPost.isNotEmpty ? fotoPost : null,
                  curtidas: curtidas,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('OngDetailService: falha em /social/feed -> $e');
    }

    final String nome =
        (perfilBruto['name'] ?? perfilBruto['nome'] ?? '').toString().trim();
    final String razaoSocial =
        (perfilBruto['razaoSocial'] ?? '').toString().trim();
    final String cnpj = (perfilBruto['cnpj'] ?? '').toString().trim();
    final String email = (perfilBruto['email'] ?? '').toString().trim();
    final String cidade =
        (perfilBruto['cidade'] ?? perfilBruto['city'] ?? '').toString().trim();
    final String estado =
        (perfilBruto['estado'] ?? perfilBruto['state'] ?? '').toString().trim();
    final String categoria =
        (perfilBruto['causaPrincipal'] ?? perfilBruto['categoria'] ?? '')
            .toString()
            .trim();

    final String logoUrl = _resolverImagemReal(
      perfilBruto['avatar'] ?? perfilBruto['logoUrl'] ?? perfilBruto['fotoUrl'],
    );
    final String bannerUrl = _resolverImagemReal(
      perfilBruto['banner'] ??
          perfilBruto['bannerUrl'] ??
          perfilBruto['capaUrl'],
    );

    final String sobre = (perfilBruto['bio'] ??
            perfilBruto['descricao'] ??
            perfilBruto['about'] ??
            '')
        .toString()
        .trim();

    final String horarioDoacao = (perfilBruto['horarioDoacao'] ??
            perfilBruto['horarioRecebimento'] ??
            perfilBruto['horarioRecebimentoDoacoes'] ??
            perfilBruto['donationHours'] ??
            perfilBruto['horarioFuncionamento'] ??
            '')
        .toString()
        .trim();

    final String chavePix = (perfilBruto['chavePix'] ??
            perfilBruto['pixKey'] ??
            perfilBruto['pix'] ??
            '')
        .toString()
        .trim();

    final Set<String> necessidadesSet = <String>{
      ..._extrairListaStrings(perfilBruto['necessidadesAtuais']),
      ..._extrairListaStrings(perfilBruto['necessidades']),
      ..._extrairListaStrings(perfilBruto['needs']),
    };

    final DateTime agora = DateTime.now();
    final List<OngOportunidadeModel> oportunidadesAbertas =
        <OngOportunidadeModel>[];
    final List<OngOportunidadeModel> eventosPassados = <OngOportunidadeModel>[];

    for (final dynamic rawItem in eventosBrutos) {
      final OngPayloadMap item = rawItem as OngPayloadMap;

      final String id = item['id']?.toString() ?? '';
      final String titulo = item['title']?.toString().trim() ?? '';
      final int total = (item['totalVacancies'] as num?)?.toInt() ?? 0;
      final int inscritos = (item['acceptedCount'] as num?)?.toInt() ??
          (item['_count']?['applications'] as num?)?.toInt() ??
          0;
      final int vagasRestantes = (total - inscritos).clamp(0, 999);

      final int duracao = (item['durationHours'] as num?)?.toInt() ?? 0;
      final DateTime? dtInicioEvento =
          DateTime.tryParse(item['eventDate']?.toString() ?? '')?.toLocal();
      final DateTime? dtFimApi =
          DateTime.tryParse(item['endDate']?.toString() ?? '')?.toLocal();
      final DateTime? dtConclusaoEvento = dtFimApi ??
          (dtInicioEvento != null && duracao > 0
              ? dtInicioEvento.add(Duration(hours: duracao))
              : null);

      String dataFmt = '';
      if (dtInicioEvento != null) {
        dataFmt =
            '${dtInicioEvento.day.toString().padLeft(2, '0')}/${dtInicioEvento.month.toString().padLeft(2, '0')}/${dtInicioEvento.year}';
      } else if (item['eventDate'] != null) {
        dataFmt = item['eventDate'].toString();
      }

      final String imgEvento = _extrairImagemEvento(item);

      final OngOportunidadeModel opModel = OngOportunidadeModel(
        id: id,
        titulo: titulo,
        data: dataFmt,
        horario: duracao > 0 ? '${duracao}h de duração' : '',
        vagasRestantes: vagasRestantes,
        imagemUrl: imgEvento.isNotEmpty ? imgEvento : logoUrl,
        isInscrito: item['isInscrito'] == true || item['isApplied'] == true,
      );

      if (dtConclusaoEvento != null && !agora.isBefore(dtConclusaoEvento)) {
        eventosPassados.add(opModel);
        continue;
      }

      if (dtInicioEvento != null) {
        final DateTime limiteInscricao =
            dtInicioEvento.subtract(const Duration(hours: 1));
        if (!agora.isBefore(limiteInscricao)) {
          continue;
        }
      }

      if (vagasRestantes > 0) {
        for (final String reqSkill
            in _extrairListaStrings(item['requiredSkills'])) {
          necessidadesSet.add(reqSkill);
        }
        oportunidadesAbertas.add(opModel);
      }
    }

    final String logradouro =
        (perfilBruto['logradouro'] ?? '').toString().trim();
    final String numero = (perfilBruto['numero'] ?? '').toString().trim();
    final String bairro = (perfilBruto['bairro'] ?? '').toString().trim();
    final String cep = (perfilBruto['cep'] ?? '').toString().trim();
    final String enderecoBruto =
        (perfilBruto['endereco'] ?? '').toString().trim();

    String enderecoCompleto = '';
    if (logradouro.isNotEmpty) {
      enderecoCompleto = logradouro;
      if (numero.isNotEmpty) enderecoCompleto += ', $numero';
      if (bairro.isNotEmpty) enderecoCompleto += ' - $bairro';
      if (cidade.isNotEmpty && estado.isNotEmpty) {
        enderecoCompleto += ', $cidade - $estado';
      }
      if (cep.isNotEmpty) enderecoCompleto += ' (CEP: $cep)';
    } else if (enderecoBruto.isNotEmpty) {
      enderecoCompleto = enderecoBruto;
    }

    final int countDiretoPerfil =
        (perfilBruto['voluntariosAtivos'] as num?)?.toInt() ??
            (perfilBruto['_count']?['applications'] as num?)?.toInt() ??
            0;

    final int voluntarioCount = idsVoluntariosUnicos.isNotEmpty
        ? idsVoluntariosUnicos.length
        : (somaContadoresEventos > 0
            ? somaContadoresEventos
            : countDiretoPerfil);

    final int totalEventosOng = eventosBrutos.length;
    final int acoesEEventosCount =
        totalEventosOng > 0 ? totalEventosOng : publicacoes.length;

    final DateTime? criadoEm =
        DateTime.tryParse(perfilBruto['createdAt']?.toString() ?? '')
            ?.toLocal();

    int anosAtuacao = (perfilBruto['anosAtuacao'] as num?)?.toInt() ?? 0;
    if (anosAtuacao <= 0 && criadoEm != null) {
      final int diffAnos = DateTime.now().year - criadoEm.year;
      anosAtuacao = diffAnos > 0 ? diffAnos : 1;
    }
    if (anosAtuacao <= 0) anosAtuacao = 1;

    final int totalSeguidores =
        (perfilBruto['totalSeguidores'] as num?)?.toInt() ??
            (perfilBruto['_count']?['followers'] as num?)?.toInt() ??
            0;

    final bool isSeguindo =
        perfilBruto['isSeguindo'] == true || perfilBruto['isFollowing'] == true;

    return OngDetalheModel(
      id: ongId,
      nome: nome,
      razaoSocial: razaoSocial,
      cnpj: cnpj,
      email: email,
      categoria: categoria,
      cidade: cidade,
      estado: estado,
      enderecoCompleto: enderecoCompleto,
      logoUrl: logoUrl,
      bannerUrl: bannerUrl,
      sobre: sobre,
      voluntariosAtivos: voluntarioCount,
      eventosRealizados: acoesEEventosCount,
      anosAtuacao: anosAtuacao,
      criadoEm: criadoEm,
      totalSeguidores: totalSeguidores,
      isSeguindo: isSeguindo,
      necessidadesUrgentes: necessidadesSet.toList(),
      site: perfilBruto['site']?.toString(),
      instagram: perfilBruto['instagram']?.toString(),
      facebook: perfilBruto['facebook']?.toString(),
      tiktok: perfilBruto['tiktok']?.toString(),
      linkedin: perfilBruto['linkedin']?.toString(),
      whatsapp: perfilBruto['whatsapp']?.toString(),
      telefone:
          (perfilBruto['telefoneFixo'] ?? perfilBruto['telefone'])?.toString(),
      chavePix: chavePix.isNotEmpty ? chavePix : null,
      horarioRecebimentoDoacoes:
          horarioDoacao.isNotEmpty ? horarioDoacao : null,
      latitude: (perfilBruto['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (perfilBruto['longitude'] as num?)?.toDouble() ?? 0,
      oportunidadesAbertas: oportunidadesAbertas,
      eventosPassados: eventosPassados,
      publicacoes: publicacoes,
    );
  }
}
