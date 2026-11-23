// lib/voluntarios/buscar/services/busca_hub_service.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../services/session_service.dart';
import '../models/resultado_busca_model.dart';

class BuscaHubService {
  final String baseUrl = "https://abc-do-bem.onrender.com";

  String? _obterToken(String? tokenParametro) {
    if (tokenParametro != null && tokenParametro.trim().isNotEmpty) {
      return tokenParametro.trim();
    }
    return SessionService.instance.token;
  }

  /// Resolve avatar/imagem real vinda da API (HTTP, caminho relativo ou Base64)
  String _resolverImagemReal(dynamic rawImg) {
    if (rawImg == null) return "";
    final String url = rawImg.toString().trim();
    if (url.isEmpty ||
        url == "null" ||
        url.contains("default.png") ||
        url.contains("placeholder") ||
        url.contains("storage.xyz") ||
        url.contains("example.com")) {
      return "";
    }
    if (url.startsWith("data:image")) return url;
    if (url.startsWith("http://") || url.startsWith("https://")) return url;
    if (url.startsWith("/")) return "$baseUrl$url";
    return "$baseUrl/$url";
  }

  String _extrairCidadeReal(Map<String, dynamic> item,
      {Map<String, dynamic>? ongFallback}) {
    final String c1 = (item['cidade'] ?? item['city'] ?? '').toString().trim();
    if (c1.isNotEmpty && c1.toLowerCase() != 'null') return c1;

    if (ongFallback != null) {
      final String c2 = (ongFallback['cidade'] ?? ongFallback['city'] ?? '')
          .toString()
          .trim();
      if (c2.isNotEmpty && c2.toLowerCase() != 'null') return c2;
    }
    return "Grande ABC";
  }

  String _extrairSegundaCaracteristicaOng(
      Map<String, dynamic> item, String causaPrincipal) {
    final List<dynamic> candidatosTexto = <dynamic>[
      item['publicoAlvo'],
      item['subcategoria'],
      item['areaSecundaria'],
      item['bairro'],
    ];

    for (final dynamic cand in candidatosTexto) {
      final String val = (cand ?? '').toString().trim();
      if (val.isNotEmpty &&
          val.toLowerCase() != 'null' &&
          val.toLowerCase() != causaPrincipal.toLowerCase()) {
        return val;
      }
    }

    if (item['necessidadesAtuais'] is List &&
        (item['necessidadesAtuais'] as List).isNotEmpty) {
      return "Precisa: ${(item['necessidadesAtuais'] as List).first}";
    }

    if (item['causas'] is List && (item['causas'] as List).length > 1) {
      return (item['causas'] as List)[1].toString().trim();
    }

    final int eventos =
        (item['_count']?['opportunities'] as num?)?.toInt() ?? 0;
    if (eventos > 0) {
      return "$eventos ${eventos == 1 ? 'evento' : 'eventos'}";
    }

    return item['aceitaDoacoes'] == true
        ? "Aceita doações"
        : "Instituição parceira";
  }

  Future<List<ResultadoBuscaItem>> buscarTodos({String? token}) async {
    final tokenFinal = _obterToken(token);
    final headers = <String, String>{
      "Accept": "application/json",
      if (tokenFinal != null && tokenFinal.isNotEmpty)
        "Authorization": "Bearer $tokenFinal",
    };

    final List<ResultadoBuscaItem> ongsLista = <ResultadoBuscaItem>[];
    final List<ResultadoBuscaItem> eventosLista = <ResultadoBuscaItem>[];
    final List<ResultadoBuscaItem> voluntariosLista = <ResultadoBuscaItem>[];

    final Map<String, Map<String, dynamic>> ongsPorId =
        <String, Map<String, dynamic>>{};
    final Set<String> idsVoluntariosAdicionados = <String>{};

    // 1. ONGS CADASTRADAS (GET /users/ongs)
    try {
      final urlOngs = Uri.parse("$baseUrl/users/ongs");
      final resOngs = await http
          .get(urlOngs, headers: headers)
          .timeout(const Duration(seconds: 12));

      if (resOngs.statusCode == 200) {
        final dynamic corpo = jsonDecode(utf8.decode(resOngs.bodyBytes));
        final List<dynamic> ongs =
            corpo is List ? corpo : (corpo['data'] ?? <dynamic>[]);

        for (final item in ongs) {
          if (item is Map<String, dynamic>) {
            final String id = item['id']?.toString() ?? '';
            if (id.isNotEmpty) {
              ongsPorId[id] = item;
            }

            final String nome = (item['name'] ?? item['nome'] ?? 'ONG Parceira')
                .toString()
                .trim();
            final String cidade = _extrairCidadeReal(item);
            final String causa =
                (item['causaPrincipal'] ?? item['categoria'] ?? 'Ação Social')
                    .toString()
                    .trim();
            final String causaFinal = causa.isNotEmpty ? causa : 'Ação Social';
            final String segundaCarac =
                _extrairSegundaCaracteristicaOng(item, causaFinal);

            final String fotoReal = _resolverImagemReal(
              item['avatar'] ?? item['logoUrl'] ?? item['fotoUrl'],
            );

            ongsLista.add(
              BuscaOngItem(
                id: id,
                tituloPrincipal: nome,
                subtitulo: cidade,
                imagemUrl: fotoReal,
                tagOuCategoria: causaFinal,
                segundaCaracteristica: segundaCarac,
                cidade: cidade,
                totalVoluntarios:
                    (item['_count']?['opportunities'] as num?)?.toInt() ?? 0,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Erro ao processar ONGs: $e");
    }

    // 2. OPORTUNIDADES / EVENTOS (GET /opportunities)
    try {
      final urlVagas = Uri.parse("$baseUrl/opportunities");
      final resVagas = await http
          .get(urlVagas, headers: headers)
          .timeout(const Duration(seconds: 12));

      if (resVagas.statusCode == 200) {
        final dynamic corpo = jsonDecode(utf8.decode(resVagas.bodyBytes));
        final List<dynamic> vagas =
            corpo is List ? corpo : (corpo['data'] ?? <dynamic>[]);

        for (final item in vagas) {
          if (item is Map<String, dynamic>) {
            final String id = item['id']?.toString() ?? '';
            final String titulo =
                (item['title'] ?? 'Oportunidade Voluntária').toString().trim();
            final Map<String, dynamic>? ongMap =
                item['ong'] is Map<String, dynamic>
                    ? item['ong'] as Map<String, dynamic>
                    : ongsPorId[item['ongId']?.toString() ?? ''];

            final String ongNome =
                (ongMap?['name'] ?? item['ongName'] ?? 'ONG Parceira')
                    .toString()
                    .trim();
            final String cidade = _extrairCidadeReal(item, ongFallback: ongMap);

            String dataExibicao = "";
            if (item['eventDate'] != null) {
              try {
                final dt =
                    DateTime.parse(item['eventDate'].toString()).toLocal();
                dataExibicao =
                    "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}";
              } catch (_) {
                dataExibicao = item['eventDate'].toString();
              }
            }

            final int vagasTotais =
                (item['totalVacancies'] as num?)?.toInt() ?? 0;
            final int inscritos =
                (item['_count']?['applications'] as num?)?.toInt() ?? 0;
            final int vagasRestantes = (vagasTotais - inscritos).clamp(0, 999);

            dynamic rawBanner = item['banner'] ??
                item['bannerUrl'] ??
                item['imageUrl'] ??
                item['imagemUrl'];
            if ((rawBanner == null || rawBanner.toString().trim().isEmpty) &&
                item['images'] is List &&
                (item['images'] as List).isNotEmpty) {
              rawBanner = (item['images'] as List).first;
            }
            String fotoReal = _resolverImagemReal(rawBanner);
            if (fotoReal.isEmpty && ongMap != null) {
              fotoReal = _resolverImagemReal(
                ongMap['banner'] ?? ongMap['avatar'] ?? ongMap['logoUrl'],
              );
            }

            final List<dynamic> categorias = item['categories'] is List
                ? item['categories'] as List<dynamic>
                : <dynamic>[];
            final String primeiraCarac = categorias.isNotEmpty
                ? categorias.first.toString()
                : (item['cause']?.toString().trim().isNotEmpty == true
                    ? item['cause'].toString().trim()
                    : ongNome);

            final String segundaCarac = dataExibicao.isNotEmpty
                ? "$dataExibicao • $vagasRestantes vagas"
                : "$vagasRestantes vagas abertas";

            eventosLista.add(
              BuscaEventoItem(
                id: id,
                tituloPrincipal: titulo,
                subtitulo: cidade,
                imagemUrl: fotoReal,
                tagOuCategoria: primeiraCarac,
                segundaCaracteristica: segundaCarac,
                cidade: cidade,
                data: dataExibicao,
                horario: "${item['durationHours'] ?? 4}h de duração",
                vagasRestantes: vagasRestantes,
                ongNome: ongNome,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Erro ao processar oportunidades: $e");
    }

    // 3. VOLUNTÁRIOS CADASTRADOS
    final List<String> rotasVoluntarios = <String>[
      "$baseUrl/users/voluntarios",
      "$baseUrl/users?role=VOLUNTEER",
      "$baseUrl/admin/users?role=USER",
      "$baseUrl/users",
    ];

    for (final String rota in rotasVoluntarios) {
      try {
        final res = await http
            .get(Uri.parse(rota), headers: headers)
            .timeout(const Duration(seconds: 8));

        if (res.statusCode == 200) {
          final dynamic corpo = jsonDecode(utf8.decode(res.bodyBytes));
          final List<dynamic> lista = corpo is List
              ? corpo
              : (corpo['data'] ?? corpo['users'] ?? <dynamic>[]);

          for (final item in lista) {
            if (item is Map<String, dynamic>) {
              final String role =
                  (item['role'] ?? item['tipo'] ?? '').toString().toUpperCase();
              if (role == 'ONG') continue;

              final String id = item['id']?.toString() ?? '';
              if (id.isEmpty || idsVoluntariosAdicionados.contains(id))
                continue;

              final String nome =
                  (item['name'] ?? item['nome'] ?? '').toString().trim();
              if (nome.isEmpty) continue;

              idsVoluntariosAdicionados.add(id);

              final String cidade = _extrairCidadeReal(item);
              final String fotoReal = _resolverImagemReal(
                item['avatar'] ?? item['fotoUrl'] ?? item['photoUrl'],
              );

              final List<dynamic> habs = item['habilidades'] is List
                  ? item['habilidades'] as List<dynamic>
                  : <dynamic>[];
              final List<dynamic> interesses = item['interesses'] is List
                  ? item['interesses'] as List<dynamic>
                  : <dynamic>[];
              final String profissao =
                  (item['profissao'] ?? item['areaAtuacao'] ?? '')
                      .toString()
                      .trim();
              final String disponibilidade =
                  (item['disponibilidade'] ?? '').toString().trim();

              final String primeiraCarac = habs.isNotEmpty
                  ? habs.first.toString()
                  : (profissao.isNotEmpty ? profissao : 'Voluntariado Social');

              final String segundaCarac = habs.length > 1
                  ? habs[1].toString()
                  : (interesses.isNotEmpty
                      ? interesses.first.toString()
                      : (disponibilidade.isNotEmpty
                          ? disponibilidade
                          : 'Voluntário ativo'));

              voluntariosLista.add(
                BuscaVoluntarioItem(
                  id: id,
                  tituloPrincipal: nome,
                  subtitulo: cidade,
                  imagemUrl: fotoReal,
                  tagOuCategoria: primeiraCarac,
                  segundaCaracteristica: segundaCarac,
                  cidade: cidade,
                  habilidades: habs.map((dynamic h) => h.toString()).toList(),
                  totalHoras:
                      (item['_count']?['applications'] as num?)?.toInt() ?? 0,
                ),
              );
            }
          }
          if (idsVoluntariosAdicionados.isNotEmpty) break;
        }
      } catch (_) {}
    }

    // Fallback complementar via /social/feed caso a listagem direta de voluntários seja restrita
    if (idsVoluntariosAdicionados.isEmpty) {
      try {
        final resFeed = await http
            .get(Uri.parse("$baseUrl/social/feed"), headers: headers)
            .timeout(const Duration(seconds: 8));

        if (resFeed.statusCode == 200) {
          final dynamic corpo = jsonDecode(utf8.decode(resFeed.bodyBytes));
          final List<dynamic> posts =
              corpo is List ? corpo : (corpo['data'] ?? <dynamic>[]);

          for (final post in posts) {
            if (post is Map<String, dynamic>) {
              final dynamic autor = post['author'] ?? post['user'];
              if (autor is Map<String, dynamic>) {
                final String role =
                    (autor['role'] ?? '').toString().toUpperCase();
                if (role == 'ONG') continue;

                final String id = autor['id']?.toString() ?? '';
                if (id.isEmpty || idsVoluntariosAdicionados.contains(id))
                  continue;

                final String nome =
                    (autor['name'] ?? autor['nome'] ?? '').toString().trim();
                if (nome.isEmpty) continue;

                idsVoluntariosAdicionados.add(id);
                final String cidade = _extrairCidadeReal(autor);
                final String fotoReal = _resolverImagemReal(
                  autor['avatar'] ?? autor['fotoUrl'],
                );

                voluntariosLista.add(
                  BuscaVoluntarioItem(
                    id: id,
                    tituloPrincipal: nome,
                    subtitulo: cidade,
                    imagemUrl: fotoReal,
                    tagOuCategoria: 'Voluntário Ativo',
                    segundaCaracteristica: 'Comunidade ABC',
                    cidade: cidade,
                    habilidades: const <String>[],
                    totalHoras: 0,
                  ),
                );
              }
            }
          }
        }
      } catch (_) {}
    }

    // Embaralha aleatoriamente cada grupo e intercala (ONG -> Evento -> Voluntário)
    final random = Random();
    ongsLista.shuffle(random);
    eventosLista.shuffle(random);
    voluntariosLista.shuffle(random);

    final List<ResultadoBuscaItem> mesclados = <ResultadoBuscaItem>[];
    final int maxLen = max(
      ongsLista.length,
      max(eventosLista.length, voluntariosLista.length),
    );

    for (int i = 0; i < maxLen; i++) {
      if (i < ongsLista.length) mesclados.add(ongsLista[i]);
      if (i < eventosLista.length) mesclados.add(eventosLista[i]);
      if (i < voluntariosLista.length) mesclados.add(voluntariosLista[i]);
    }

    return mesclados;
  }
}
