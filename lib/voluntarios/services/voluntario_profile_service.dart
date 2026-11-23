// lib/voluntarios/services/voluntario_profile_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../services/session_service.dart';
import '../models/voluntario_profile_models.dart';

typedef ItemFeedSocial = Map<String, dynamic>;

class _CachePerfilEntry {
  final VoluntarioPerfilModel perfil;
  final DateTime expiraEm;

  const _CachePerfilEntry({
    required this.perfil,
    required this.expiraEm,
  });

  bool get isValido => DateTime.now().isBefore(expiraEm);
}

class _CacheFeedEntry {
  final List<ItemFeedSocial> itens;
  final DateTime expiraEm;

  const _CacheFeedEntry({
    required this.itens,
    required this.expiraEm,
  });

  bool get isValido => DateTime.now().isBefore(expiraEm);
}

class VoluntarioProfileService {
  final String baseUrl = "https://abc-do-bem.onrender.com";

  static final Map<String, _CachePerfilEntry> _cachePerfis =
      <String, _CachePerfilEntry>{};
  static final Map<String, Future<VoluntarioPerfilModel>> _requisicoesPerfil =
      <String, Future<VoluntarioPerfilModel>>{};

  static _CacheFeedEntry? _cacheFeed;
  static Future<List<ItemFeedSocial>>? _requisicaoFeedEmAndamento;

  static void invalidarCache([String? usuarioId]) {
    if (usuarioId != null && usuarioId.trim().isNotEmpty) {
      _cachePerfis.remove(usuarioId.trim());
    } else {
      _cachePerfis.clear();
    }
    _cacheFeed = null;
  }

  String? _obterToken(String? tokenParametro) {
    if (tokenParametro != null && tokenParametro.trim().isNotEmpty) {
      return tokenParametro.trim();
    }
    return SessionService.instance.token;
  }

  Map<String, String> _headers(String? tokenParametro,
      {bool jsonBody = false}) {
    final tokenFinal = _obterToken(tokenParametro);
    return <String, String>{
      "Accept": "application/json",
      if (jsonBody) "Content-Type": "application/json",
      if (tokenFinal != null && tokenFinal.isNotEmpty)
        "Authorization": "Bearer $tokenFinal",
    };
  }

  Future<http.Response> _getComRetry429(
    Uri url,
    Map<String, String> headers,
  ) async {
    http.Response res = await http
        .get(url, headers: headers)
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 429) {
      await Future<void>.delayed(const Duration(milliseconds: 1600));
      res = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
    }
    return res;
  }

  int _calcularEstrelasEngajamento({
    required int acoesConcluidas,
    required int horasDoadas,
    required int relatosPublicados,
    required int habilidadesCount,
  }) {
    int pontos = 1;
    if (acoesConcluidas >= 1 || relatosPublicados >= 1) pontos++;
    if (acoesConcluidas >= 3 || horasDoadas >= 8) pontos++;
    if (acoesConcluidas >= 6 || horasDoadas >= 20) pontos++;
    if ((acoesConcluidas >= 10 || horasDoadas >= 40) && habilidadesCount > 0) {
      pontos++;
    }
    return pontos.clamp(1, 5);
  }

  Future<VoluntarioPerfilModel> buscarPerfil(
    String usuarioId, {
    String? token,
    bool forcarAtualizacao = false,
  }) {
    String idLimpo = usuarioId.trim();
    final String? sessaoId = SessionService.instance.usuarioId?.trim();

    if ((idLimpo.isEmpty ||
            idLimpo == 'meu-perfil' ||
            idLimpo == 'voluntario-1') &&
        sessaoId != null &&
        sessaoId.isNotEmpty) {
      idLimpo = sessaoId;
    }

    if (!forcarAtualizacao) {
      final cached = _cachePerfis[idLimpo];
      if (cached != null && cached.isValido) {
        return Future<VoluntarioPerfilModel>.value(cached.perfil);
      }
    }

    final emAndamento = _requisicoesPerfil[idLimpo];
    if (emAndamento != null) {
      return emAndamento;
    }

    final future = _executarBuscaPerfil(idLimpo, token: token).whenComplete(() {
      _requisicoesPerfil.remove(idLimpo);
    });

    _requisicoesPerfil[idLimpo] = future;
    return future;
  }

  List<dynamic> _extrairListaCandidaturas(Map<String, dynamic> fonte) {
    final dynamic raw = fonte['applications'] ??
        fonte['inscricoes'] ??
        fonte['candidaturas'] ??
        fonte['historico'] ??
        fonte['history'] ??
        (fonte['user'] is Map ? fonte['user']['applications'] : null) ??
        (fonte['data'] is Map ? fonte['data']['applications'] : null);
    return raw is List ? raw : <dynamic>[];
  }

  Future<VoluntarioPerfilModel> _executarBuscaPerfil(
    String usuarioId, {
    String? token,
  }) async {
    final headers = _headers(token);
    final String? sessaoId = SessionService.instance.usuarioId?.trim();
    final bool isProprioUsuario =
        sessaoId != null && sessaoId.isNotEmpty && sessaoId == usuarioId;

    Map<String, dynamic> dadosUsuario = <String, dynamic>{};
    List<dynamic> rawApplications = <dynamic>[];
    bool carregouBase = false;

    // 1. Se for o próprio usuário e a sessão já sincronizou /users/{id}, reutiliza
    if (isProprioUsuario &&
        SessionService.instance.dadosCompletosUsuario != null &&
        SessionService.instance.dadosCompletosUsuario!.isNotEmpty) {
      dadosUsuario.addAll(SessionService.instance.dadosCompletosUsuario!);
      rawApplications = _extrairListaCandidaturas(dadosUsuario);
      carregouBase = true;
    }

    // 2. Busca o perfil completo em GET /users/{id}
    if (!carregouBase) {
      final response = await _getComRetry429(
        Uri.parse("$baseUrl/users/$usuarioId"),
        headers,
      );

      final String responseBody = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(responseBody);
        if (decoded is Map<String, dynamic>) {
          Map<String, dynamic> userMap = decoded['data'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(decoded['data'])
              : Map<String, dynamic>.from(decoded);
          if (userMap['user'] is Map<String, dynamic>) {
            userMap = <String, dynamic>{
              ...userMap,
              ...(userMap['user'] as Map<String, dynamic>),
            };
          }
          dadosUsuario.addAll(userMap);
          rawApplications = _extrairListaCandidaturas(userMap);
          carregouBase = dadosUsuario.isNotEmpty;
          if (isProprioUsuario && carregouBase) {
            SessionService.instance.dadosCompletosUsuario =
                Map<String, dynamic>.from(dadosUsuario);
          }
        }
      } else {
        final cachedAntigo = _cachePerfis[usuarioId]?.perfil;
        if (cachedAntigo != null) return cachedAntigo;

        if (response.statusCode == 429) {
          throw Exception(
            "Muitas requisições seguidas ao servidor. Aguarde alguns segundos e toque em Tentar Novamente.",
          );
        }

        String mensagemErro = "Erro ao buscar perfil (${response.statusCode}).";
        try {
          final erroJson = jsonDecode(responseBody);
          if (erroJson is Map && erroJson.containsKey('message')) {
            final msg = erroJson['message'];
            mensagemErro = msg is List ? msg.join(', ') : msg.toString();
          }
        } catch (_) {}
        throw Exception(mensagemErro);
      }
    }

    // Garante preenchimento com os dados básicos da SessionService
    if (isProprioUsuario) {
      final s = SessionService.instance;
      if ((dadosUsuario['name'] ?? '').toString().trim().isEmpty &&
          (s.nomeUsuario ?? '').trim().isNotEmpty) {
        dadosUsuario['name'] = s.nomeUsuario;
      }
      if ((dadosUsuario['email'] ?? '').toString().trim().isEmpty &&
          (s.email ?? '').trim().isNotEmpty) {
        dadosUsuario['email'] = s.email;
      }
      if ((dadosUsuario['avatar'] ?? '').toString().trim().isEmpty &&
          (s.fotoUrl ?? '').trim().isNotEmpty) {
        dadosUsuario['avatar'] = s.fotoUrl;
      }
      if ((dadosUsuario['bio'] ?? '').toString().trim().isEmpty &&
          (s.bio ?? '').trim().isNotEmpty) {
        dadosUsuario['bio'] = s.bio;
      }
      if ((dadosUsuario['cidade'] ?? '').toString().trim().isEmpty &&
          (s.cidade ?? '').trim().isNotEmpty) {
        dadosUsuario['cidade'] = s.cidade;
      }
      if ((dadosUsuario['estado'] ?? '').toString().trim().isEmpty &&
          (s.estado ?? '').trim().isNotEmpty) {
        dadosUsuario['estado'] = s.estado;
      }
      if ((dadosUsuario['whatsapp'] ?? '').toString().trim().isEmpty &&
          (s.whatsapp ?? s.telefone ?? '').trim().isNotEmpty) {
        dadosUsuario['whatsapp'] = s.whatsapp ?? s.telefone;
      }
      if ((dadosUsuario['habilidades'] == null ||
              (dadosUsuario['habilidades'] is List &&
                  (dadosUsuario['habilidades'] as List).isEmpty)) &&
          s.habilidades.isNotEmpty) {
        dadosUsuario['habilidades'] = s.habilidades;
      }
      if ((dadosUsuario['disponibilidade'] == null ||
              (dadosUsuario['disponibilidade'] is List &&
                  (dadosUsuario['disponibilidade'] as List).isEmpty)) &&
          s.disponibilidade.isNotEmpty) {
        dadosUsuario['disponibilidade'] = s.disponibilidade;
      }
    }

    // 3. Se for o próprio usuário, complementa histórico de candidaturas e estatísticas via GET /users/dashboard/me
    Map<String, dynamic> statsDashboard = <String, dynamic>{};
    if (isProprioUsuario) {
      try {
        await Future<void>.delayed(const Duration(milliseconds: 180));
        final resDash = await _getComRetry429(
          Uri.parse("$baseUrl/users/dashboard/me"),
          headers,
        );
        if (resDash.statusCode == 200) {
          final dashDecoded = jsonDecode(utf8.decode(resDash.bodyBytes));
          if (dashDecoded is Map<String, dynamic>) {
            final Map<String, dynamic> rootDash =
                dashDecoded['data'] is Map<String, dynamic>
                    ? dashDecoded['data'] as Map<String, dynamic>
                    : dashDecoded;
            statsDashboard = rootDash;
            final appsDash = _extrairListaCandidaturas(rootDash);
            if (appsDash.isNotEmpty) {
              rawApplications = appsDash;
            }
          }
        }
      } catch (e) {
        debugPrint(
            "VoluntarioProfileService: falha em /users/dashboard/me -> $e");
      }
    }

    final VoluntarioPerfilModel perfilBase =
        VoluntarioPerfilModel.fromJson(dadosUsuario);

    // 4. Processa ações participadas e soma horas doadas reais
    final List<AcaoParticipadaVoluntarioModel> acoes =
        <AcaoParticipadaVoluntarioModel>[];
    int acoesConfirmadas = 0;
    int horasDoadasCalculadas = 0;

    for (final dynamic app in rawApplications) {
      if (app is! Map<String, dynamic>) continue;
      final Map<String, dynamic> opp =
          app['opportunity'] is Map<String, dynamic>
              ? app['opportunity'] as Map<String, dynamic>
              : (app['vaga'] is Map<String, dynamic>
                  ? app['vaga'] as Map<String, dynamic>
                  : <String, dynamic>{});

      final String oppId = (app['opportunityId'] ?? opp['id'] ?? '').toString();
      final String titulo =
          (opp['title'] ?? opp['titulo'] ?? app['title'] ?? 'Ação Voluntária')
              .toString()
              .trim();
      final String ongNome = (opp['ong']?['name'] ??
              opp['ongNome'] ??
              app['ongNome'] ??
              'ONG Parceira')
          .toString()
          .trim();
      final int duracao = (opp['durationHours'] as num?)?.toInt() ??
          (app['durationHours'] as num?)?.toInt() ??
          4;
      final String statusApp = (app['status'] ?? 'PENDING').toString();
      final bool certificado = opp['emiteCertificado'] == true ||
          opp['hasCertificate'] == true ||
          app['hasCertificate'] == true;

      final String? fotoOportunidade = VoluntarioPerfilModel.sanitizarImagem(
        opp['banner'] ??
            opp['imageUrl'] ??
            opp['bannerUrl'] ??
            opp['photo'] ??
            app['imageUrl'] ??
            app['photo'],
        fallback: '',
      );

      String dataFmt = 'Recente';
      if (opp['eventDate'] != null) {
        final dt = DateTime.tryParse(opp['eventDate'].toString())?.toLocal();
        if (dt != null) {
          dataFmt =
              "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
        }
      }

      final itemAcao = AcaoParticipadaVoluntarioModel(
        id: (app['id'] ?? oppId).toString(),
        opportunityId: oppId,
        titulo: titulo,
        ongNome: ongNome,
        dataFormatada: dataFmt,
        duracaoHoras: duracao,
        status: statusApp,
        emiteCertificado: certificado,
        fotoUrl: fotoOportunidade != null && fotoOportunidade.isNotEmpty
            ? fotoOportunidade
            : null,
      );

      acoes.add(itemAcao);

      if (itemAcao.isConcluidaOuAprovada) {
        acoesConfirmadas++;
        horasDoadasCalculadas += duracao;
      }
    }

    // 5. Busca experiências do voluntário na rota dedicada GET /social/voluntarios/{userId}/experiencias
    final List<ExperienciaFeedModel> relatosFeed = <ExperienciaFeedModel>[
      ...perfilBase.experiencias,
    ];
    final Set<String> idsRelatos = relatosFeed.map((e) => e.id).toSet();

    try {
      await Future<void>.delayed(const Duration(milliseconds: 180));
      final resExp = await _getComRetry429(
        Uri.parse("$baseUrl/social/voluntarios/$usuarioId/experiencias"),
        headers,
      );

      if (resExp.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(resExp.bodyBytes));
        final List<dynamic> posts = decoded is List
            ? decoded
            : (decoded is Map ? (decoded['data'] ?? <dynamic>[]) : <dynamic>[]);

        for (final dynamic p in posts) {
          if (p is! Map<String, dynamic>) continue;

          final String postId = (p['id'] ?? '').toString();
          if (postId.isNotEmpty && idsRelatos.contains(postId)) continue;
          if (postId.isNotEmpty) idsRelatos.add(postId);

          String dataPost = (p['formattedDate'] ?? 'Recente').toString();
          if (p['createdAt'] != null) {
            final dt = DateTime.tryParse(p['createdAt'].toString())?.toLocal();
            if (dt != null) {
              dataPost =
                  "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
            }
          }

          String fotoPost = '';
          if (p['images'] is List && (p['images'] as List).isNotEmpty) {
            fotoPost = VoluntarioPerfilModel.sanitizarImagem(
              (p['images'] as List).first,
            );
          } else {
            fotoPost = VoluntarioPerfilModel.sanitizarImagem(
              p['imageUrl'] ?? p['imagemUrl'] ?? p['photo'],
            );
          }

          final String ongOuAcao = (p['opportunity']?['ong']?['name'] ??
                  p['opportunity']?['title'] ??
                  p['ongName'] ??
                  p['iniciativa'] ??
                  'Ação Comunitária')
              .toString()
              .trim();

          final String textoRelato =
              (p['content'] ?? p['text'] ?? p['texto'] ?? '').toString().trim();

          final int curtidas = (p['_count']?['likes'] as num?)?.toInt() ??
              (p['likesCount'] as num?)?.toInt() ??
              (p['curtidas'] as num?)?.toInt() ??
              0;

          if (textoRelato.isNotEmpty || fotoPost.isNotEmpty) {
            relatosFeed.add(
              ExperienciaFeedModel(
                id: postId,
                ongNome: ongOuAcao,
                dataFormatada: dataPost,
                texto: textoRelato.isNotEmpty
                    ? textoRelato
                    : 'Registro de ação voluntária no Grande ABC.',
                imagemUrl: fotoPost.isNotEmpty ? fotoPost : null,
                curtidas: curtidas,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint(
          "VoluntarioProfileService: falha em /social/voluntarios/$usuarioId/experiencias -> $e");
    }

    final int eventosStats = (statsDashboard['totalEventos'] ??
                statsDashboard['acoesConcluidas'] as num?)
            ?.toInt() ??
        0;
    final int horasStats =
        (statsDashboard['totalHoras'] ?? statsDashboard['horasDoadas'] as num?)
                ?.toInt() ??
            0;

    final int totalEventosFinal = [
      acoesConfirmadas,
      eventosStats,
      perfilBase.totalEventos,
    ].reduce((a, b) => a > b ? a : b);

    final int totalHorasFinal = [
      horasDoadasCalculadas,
      horasStats,
      perfilBase.totalHoras,
    ].reduce((a, b) => a > b ? a : b);

    final int estrelasReais = _calcularEstrelasEngajamento(
      acoesConcluidas: totalEventosFinal,
      horasDoadas: totalHorasFinal,
      relatosPublicados: relatosFeed.length,
      habilidadesCount: perfilBase.habilidades.length,
    );

    final resultadoFinal = perfilBase.copyWith(
      totalEventos: totalEventosFinal,
      totalHoras: totalHorasFinal,
      estrelasEngajamento: estrelasReais,
      acoesParticipadas: acoes,
      experiencias: relatosFeed,
    );

    _cachePerfis[usuarioId] = _CachePerfilEntry(
      perfil: resultadoFinal,
      expiraEm: DateTime.now().add(const Duration(seconds: 45)),
    );

    return resultadoFinal;
  }

  /// PATCH /users/profile/me [Voluntário]
  Future<void> atualizarPerfil(
    String usuarioId,
    Map<String, dynamic> dadosAtualizados, {
    String? token,
  }) async {
    final url = Uri.parse("$baseUrl/users/profile/me");
    final headers = _headers(token, jsonBody: true);

    final Map<String, dynamic> payload =
        Map<String, dynamic>.from(dadosAtualizados);
    if (payload.containsKey('fotoUrl') && !payload.containsKey('avatar')) {
      payload['avatar'] = payload['fotoUrl'];
      payload.remove('fotoUrl');
    }

    try {
      final response = await http
          .patch(
            url,
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      final String responseBody = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200 || response.statusCode == 204) {
        invalidarCache(usuarioId);
        if (SessionService.instance.usuarioId?.trim() == usuarioId.trim()) {
          SessionService.instance.dadosCompletosUsuario = <String, dynamic>{
            ...?SessionService.instance.dadosCompletosUsuario,
            ...payload,
          };
          await SessionService.instance.carregarDadosCompletosUsuario();
        }
        return;
      } else {
        String mensagemErro = "Erro ao salvar alterações no servidor.";
        try {
          final erroJson = jsonDecode(responseBody);
          if (erroJson is Map && erroJson.containsKey('message')) {
            final msg = erroJson['message'];
            mensagemErro = msg is List ? msg.join(', ') : msg.toString();
          }
        } catch (_) {}
        throw Exception(mensagemErro);
      }
    } catch (e) {
      debugPrint("Erro ao atualizar perfil: $e");
      rethrow;
    }
  }

  /// POST /social/voluntarios/experiencias [Voluntário]
  Future<bool> publicarExperiencia(
    String usuarioId,
    String texto,
    String? imagemUrl, {
    String? opportunityId,
    List<XFile> imagensArquivos = const [],
    String? token,
  }) async {
    final url = Uri.parse("$baseUrl/social/voluntarios/experiencias");
    final headers = _headers(token, jsonBody: true);

    try {
      String? fotoBase64;
      if (imagensArquivos.isNotEmpty) {
        final bytes = await imagensArquivos.first.readAsBytes();
        fotoBase64 = "data:image/jpeg;base64,${base64Encode(bytes)}";
      } else if (imagemUrl != null && imagemUrl.trim().isNotEmpty) {
        fotoBase64 = imagemUrl.trim();
      }

      final agora = DateTime.now();
      final dia = agora.day.toString().padLeft(2, '0');
      final mes = agora.month.toString().padLeft(2, '0');
      final dataFormatada = "$dia/$mes/${agora.year}";

      final Map<String, dynamic> body = {
        "text": texto.trim(),
        "ongName": (opportunityId != null && opportunityId.trim().isNotEmpty)
            ? opportunityId.trim()
            : "Ação Solidária",
        "formattedDate": dataFormatada,
        if (fotoBase64 != null) "imageUrl": fotoBase64,
      };

      final response = await http
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201) {
        invalidarCache(usuarioId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Erro ao publicar experiência: $e");
      return false;
    }
  }

  /// GET /social/feed [Comunidade]
  Future<List<ItemFeedSocial>> buscarFeedComunidade({
    String? token,
    int dias = 10,
    int limit = 20,
    bool forcarAtualizacao = false,
  }) {
    if (!forcarAtualizacao && _cacheFeed != null && _cacheFeed!.isValido) {
      return Future<List<ItemFeedSocial>>.value(_cacheFeed!.itens);
    }

    if (_requisicaoFeedEmAndamento != null) {
      return _requisicaoFeedEmAndamento!;
    }

    final future = _executarBuscaFeedComunidade(
      token: token,
      dias: dias,
      limit: limit,
    ).whenComplete(() {
      _requisicaoFeedEmAndamento = null;
    });

    _requisicaoFeedEmAndamento = future;
    return future;
  }

  Future<List<ItemFeedSocial>> _executarBuscaFeedComunidade({
    String? token,
    int dias = 10,
    int limit = 20,
  }) async {
    final url = Uri.parse("$baseUrl/social/feed?dias=$dias&limit=$limit");
    final headers = _headers(token);

    try {
      final response = await _getComRetry429(url, headers);
      final String responseBody = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final dynamic jsonDecoded = jsonDecode(responseBody);
        final List<dynamic> listaRaw = jsonDecoded is List
            ? jsonDecoded
            : (jsonDecoded['data'] as List<dynamic>? ?? <dynamic>[]);

        final agora = DateTime.now();
        final List<ItemFeedSocial> postagensMapeadas = <ItemFeedSocial>[];

        for (final dynamic item in listaRaw) {
          if (item is! Map) continue;

          DateTime? dataCriacao;
          if (item['createdAt'] != null) {
            dataCriacao = DateTime.tryParse(item['createdAt'].toString());
          }

          String tempoRelativo =
              (item['formattedDate'] ?? 'Recentemente').toString();
          if (dataCriacao != null) {
            final diffHoras = agora.difference(dataCriacao).inHours;
            final diffDias = agora.difference(dataCriacao).inDays;
            if (diffHoras < 1) {
              tempoRelativo = 'Agora mesmo';
            } else if (diffHoras < 24) {
              tempoRelativo = 'Há ${diffHoras}h';
            } else if (diffDias == 1) {
              tempoRelativo = 'Ontem';
            } else {
              tempoRelativo = 'Há $diffDias dias';
            }
          }

          final String fotoAutorSanitizada =
              VoluntarioPerfilModel.sanitizarImagem(
            item['autorFoto'] ?? item['fotoAutor'] ?? item['author']?['avatar'],
          );

          final String imagemPostSanitizada =
              VoluntarioPerfilModel.sanitizarImagem(
            item['imagemUrl'] ?? item['imageUrl'] ?? item['photo'],
          );

          postagensMapeadas.add(<String, dynamic>{
            'id': item['id'] ?? '',
            'autor':
                item['autorNome'] ?? item['autor'] ?? 'Membro da Comunidade',
            'tipoAutor':
                (item['tipoAutor'] ?? 'VOLUNTARIO').toString().toUpperCase(),
            'autorId': item['autorId'] ?? item['authorId'] ?? '',
            'fotoAutor': fotoAutorSanitizada,
            'tempo': tempoRelativo,
            'texto': item['texto'] ?? item['text'] ?? item['content'] ?? '',
            'iniciativa': item['iniciativa'] ?? item['ongName'] ?? '',
            'imagemPost': imagemPostSanitizada,
            'curtidas': item['curtidas'] ?? item['likesCount'] ?? 0,
            'comentarios': item['comentarios'] ?? item['commentsCount'] ?? 0,
          });
        }

        _cacheFeed = _CacheFeedEntry(
          itens: postagensMapeadas,
          expiraEm: DateTime.now().add(const Duration(seconds: 30)),
        );

        return postagensMapeadas;
      }
    } catch (e) {
      debugPrint("Erro ao buscar feed unificado: $e");
    }

    return _cacheFeed?.itens ?? <ItemFeedSocial>[];
  }
}
