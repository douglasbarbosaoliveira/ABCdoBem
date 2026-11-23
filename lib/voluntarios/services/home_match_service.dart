// lib/voluntarios/services/home_match_service.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class HomeMatchService {
  final String baseUrl = 'https://abc-do-bem.onrender.com';

  /// Busca perfis e ONGs recomendadas pela API independente de Match.
  /// Caso a API de Match não esteja ativa ou retorne vazio, faz fallback
  /// automático sorteando perfis 100% reais de ONGs e Voluntários da API.
  Future<List<dynamic>> buscarPerfisRecomendados({
    required String usuarioAtualId,
    String? token,
    int limite = 10,
  }) async {
    final Map<String, String> headers = <String, String>{
      'Accept': 'application/json',
      if (token != null && token.trim().isNotEmpty)
        'Authorization': 'Bearer ${token.trim()}',
    };

    // 1. Tenta consumir a API independente de Match (pronta para ativação via --dart-define)
    const String matchApiBaseUrl = String.fromEnvironment(
      'MATCH_API_URL',
      defaultValue: '',
    );

    if (matchApiBaseUrl.isNotEmpty) {
      try {
        final uriMatch =
            Uri.parse('$matchApiBaseUrl/recommendations/$usuarioAtualId');
        final resMatch = await http
            .get(uriMatch, headers: headers)
            .timeout(const Duration(seconds: 6));

        if (resMatch.statusCode == 200) {
          final dynamic decoded = jsonDecode(utf8.decode(resMatch.bodyBytes));
          final List<dynamic> listaMatch =
              decoded is List ? decoded : (decoded['data'] ?? <dynamic>[]);

          final List<dynamic> itensMatch = <dynamic>[];
          for (final item in listaMatch) {
            if (item is! Map) continue;
            final String id = (item['id'] ?? '').toString().trim();
            if (id.isEmpty || id == usuarioAtualId) continue;

            final String role = (item['role'] ?? item['tipo'] ?? 'ONG')
                .toString()
                .toUpperCase();
            final bool isOng = role == 'ONG';

            itensMatch.add(<String, dynamic>{
              'id': id,
              'nome': (item['name'] ?? item['nome'] ?? 'Perfil').toString(),
              'tipo': isOng ? 'ONG' : 'VOLUNTARIO',
              'subtitulo': isOng
                  ? (item['causaPrincipal'] ?? item['cidade'] ?? 'Grande ABC')
                      .toString()
                  : (item['cidade'] ?? 'Voluntário • ABC').toString(),
              'foto': (item['avatar'] ?? item['logoUrl'] ?? '').toString(),
              'matchScore': item['matchScore'] ?? item['score'],
            });
          }

          if (itensMatch.isNotEmpty) {
            return itensMatch.take(limite).toList();
          }
        }
      } catch (e) {
        debugPrint('API de Match indisponível, ativando fallback real: $e');
      }
    }

    // 2. Fallback automático: coleta perfis 100% reais das rotas do backend
    return _buscarFallbackPerfisReais(
      usuarioAtualId: usuarioAtualId,
      headers: headers,
      limite: limite,
    );
  }

  Future<List<dynamic>> _buscarFallbackPerfisReais({
    required String usuarioAtualId,
    required Map<String, String> headers,
    required int limite,
  }) async {
    final Map<String, Map<String, dynamic>> ongsMap =
        <String, Map<String, dynamic>>{};
    final Map<String, Map<String, dynamic>> voluntariosMap =
        <String, Map<String, dynamic>>{};

    void registrarUsuario(dynamic raw, {String? roleForcada}) {
      if (raw is! Map)
        continueLoop:
        if (raw is! Map) return;
      final String id = (raw['id'] ?? '').toString().trim();
      if (id.isEmpty || id == usuarioAtualId) return;

      final String rawRole = (roleForcada ?? raw['role'] ?? raw['tipo'] ?? '')
          .toString()
          .toUpperCase();

      // Normaliza papéis para evitar ignorar variações de voluntários
      final String role =
          (rawRole.contains('ONG') || rawRole.contains('ORGANIZATION'))
              ? 'ONG'
              : 'VOLUNTARIO';

      final String nome =
          (raw['name'] ?? raw['nome'] ?? raw['razaoSocial'] ?? '')
              .toString()
              .trim();
      if (nome.isEmpty) return;

      final String cidade =
          (raw['cidade'] ?? raw['city'] ?? 'Grande ABC').toString().trim();
      final String foto =
          (raw['avatar'] ?? raw['logoUrl'] ?? raw['fotoUrl'] ?? '')
              .toString()
              .trim();

      if (role == 'ONG') {
        final String causa =
            (raw['causaPrincipal'] ?? raw['categoria'] ?? 'Ação Social')
                .toString()
                .trim();
        ongsMap[id] = <String, dynamic>{
          'id': id,
          'nome': nome,
          'tipo': 'ONG',
          'subtitulo': '$causa • $cidade',
          'foto': foto,
        };
      } else {
        final List<dynamic> habilidades = raw['habilidades'] is List
            ? raw['habilidades'] as List<dynamic>
            : const <dynamic>[];
        final String subtituloVol = habilidades.isNotEmpty
            ? '${habilidades.first} • $cidade'
            : 'Voluntário • $cidade';

        voluntariosMap[id] = <String, dynamic>{
          'id': id,
          'nome': nome,
          'tipo': 'VOLUNTARIO',
          'subtitulo': subtituloVol,
          'foto': foto,
        };
      }
    }

    // Etapa A: Endpoints gerais de usuários e ONGs
    final List<String> endpointsUsuarios = <String>[
      '$baseUrl/users/ongs',
      '$baseUrl/users?role=ONG',
      '$baseUrl/users?role=VOLUNTEER',
      '$baseUrl/users?role=USER',
      '$baseUrl/users',
    ];

    for (final String endpoint in endpointsUsuarios) {
      try {
        final res = await http
            .get(Uri.parse(endpoint), headers: headers)
            .timeout(const Duration(seconds: 8));

        if (res.statusCode == 200) {
          final dynamic decoded = jsonDecode(utf8.decode(res.bodyBytes));
          final List<dynamic> lista =
              decoded is List ? decoded : (decoded['data'] ?? <dynamic>[]);

          final String? roleHint =
              endpoint.contains('ongs') || endpoint.contains('role=ONG')
                  ? 'ONG'
                  : (endpoint.contains('role=VOLUNTEER') ||
                          endpoint.contains('role=USER')
                      ? 'VOLUNTARIO'
                      : null);

          for (final item in lista) {
            registrarUsuario(item, roleForcada: roleHint);
          }
        }
      } catch (_) {}
    }

    // Etapa B: Captura voluntários e ONGs ativas através de /opportunities (Inscrições / Candidaturas)
    try {
      final resOps = await http
          .get(Uri.parse('$baseUrl/opportunities'), headers: headers)
          .timeout(const Duration(seconds: 8));

      if (resOps.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(resOps.bodyBytes));
        final List<dynamic> lista =
            decoded is List ? decoded : (decoded['data'] ?? <dynamic>[]);

        for (final op in lista) {
          if (op is! Map) continue;
          if (op['ong'] is Map) {
            registrarUsuario(op['ong'], roleForcada: 'ONG');
          } else if (op['ongId'] != null && op['ongName'] != null) {
            registrarUsuario(<String, dynamic>{
              'id': op['ongId'],
              'name': op['ongName'],
              'cidade': op['city'] ?? op['cidade'] ?? 'Grande ABC',
            }, roleForcada: 'ONG');
          }

          if (op['applications'] is List) {
            for (final app in (op['applications'] as List)) {
              if (app is Map) {
                final dynamic vol =
                    app['volunteer'] ?? app['voluntario'] ?? app['user'];
                if (vol is Map) {
                  registrarUsuario(vol, roleForcada: 'VOLUNTARIO');
                }
              }
            }
          }
        }
      }
    } catch (_) {}

    // Etapa C: Captura autores de posts em /social/feed
    try {
      final resFeed = await http
          .get(Uri.parse('$baseUrl/social/feed'), headers: headers)
          .timeout(const Duration(seconds: 8));

      if (resFeed.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(resFeed.bodyBytes));
        final List<dynamic> lista =
            decoded is List ? decoded : (decoded['data'] ?? <dynamic>[]);

        for (final post in lista) {
          if (post is! Map) continue;
          final dynamic autor = post['author'] ?? post['user'] ?? post['ong'];
          if (autor is Map) {
            registrarUsuario(autor);
          }
        }
      }
    } catch (_) {}

    final List<dynamic> ongsReais = ongsMap.values.toList();
    final List<dynamic> voluntariosReais = voluntariosMap.values.toList();

    final random = Random();
    ongsReais.shuffle(random);
    voluntariosReais.shuffle(random);

    final List<dynamic> combinados = <dynamic>[];

    // Distribuição proporcional desejada para até 10 itens:
    // Ex: ~70% ONGs (até 7) e ~30% Voluntários (até 3)
    final int maxOngs = (limite * 0.7).ceil(); // Ex: 7
    final int maxVoluntarios = limite - maxOngs; // Ex: 3

    final List<dynamic> ongsSelecionadas = ongsReais.take(maxOngs).toList();
    final List<dynamic> voluntariosSelecionados =
        voluntariosReais.take(maxVoluntarios).toList();

    // Se houver espaço sobrando porque faltou voluntário, preenche com mais ONGs (ou vice-versa)
    if (ongsSelecionadas.length < maxOngs &&
        voluntariosReais.length > maxVoluntarios) {
      final int defasagem = maxOngs - ongsSelecionadas.length;
      voluntariosSelecionados
          .addAll(voluntariosReais.skip(maxVoluntarios).take(defasagem));
    }
    if (voluntariosSelecionados.length < maxVoluntarios &&
        ongsReais.length > maxOngs) {
      final int defasagem = maxVoluntarios - voluntariosSelecionados.length;
      ongsSelecionadas.addAll(ongsReais.skip(maxOngs).take(defasagem));
    }

    combinados.addAll(ongsSelecionadas);
    combinados.addAll(voluntariosSelecionados);
    combinados.shuffle(random); // Mistura a ordem final no carrossel

    return combinados.take(limite).toList();
  }
}
