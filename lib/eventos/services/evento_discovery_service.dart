// lib/eventos/services/evento_discovery_service.dart

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../services/localizacao_service.dart';
import '../../services/session_service.dart';
import '../models/evento_model.dart';
import 'evento_mapper.dart';

class EventoDiscoveryService {
  final String baseUrl = "https://abc-do-bem.onrender.com";

  String? _obterToken(String? tokenParametro) {
    if (tokenParametro != null && tokenParametro.trim().isNotEmpty) {
      return tokenParametro.trim();
    }
    return SessionService.instance.token;
  }

  Map<String, String> _headers(String? tokenParametro) {
    final tokenFinal = _obterToken(tokenParametro);
    return <String, String>{
      "Accept": "application/json",
      if (tokenFinal != null && tokenFinal.isNotEmpty)
        "Authorization": "Bearer $tokenFinal",
    };
  }

  List<dynamic> _extrairListaBruta(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      if (decoded['data'] is List) return decoded['data'] as List<dynamic>;
      if (decoded['opportunities'] is List) {
        return decoded['opportunities'] as List<dynamic>;
      }
      if (decoded['items'] is List) return decoded['items'] as List<dynamic>;
    }
    return <dynamic>[];
  }

  double _calcularDistanciaKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double raioTerraKm = 6371.0;
    final double dLat = (lat2 - lat1) * (math.pi / 180.0);
    final double dLon = (lon2 - lon1) * (math.pi / 180.0);
    final double rLat1 = lat1 * (math.pi / 180.0);
    final double rLat2 = lat2 * (math.pi / 180.0);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rLat1) *
            math.cos(rLat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return raioTerraKm * c;
  }

  /// GET /opportunities — Lista vagas ativas com filtros de cidade, categoria e busca textual
  Future<List<EventoModel>> listarEventos({
    String? cidade,
    String? categoria,
    String? busca,
    String? token,
    bool incluirEncerrados = false,
    Map<String, String> inscricoesLocais = const <String, String>{},
  }) async {
    final queryParams = <String, String>{};
    if (cidade != null && cidade.isNotEmpty && cidade != "Todas") {
      queryParams["cidade"] = cidade;
    }
    if (categoria != null && categoria.isNotEmpty && categoria != "Todos") {
      queryParams["categoria"] = categoria;
    }

    final uri = Uri.parse("$baseUrl/opportunities").replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    try {
      final res = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(res.bodyBytes));
        final List<dynamic> listaBruta = _extrairListaBruta(decoded);

        final List<EventoModel> eventos = <EventoModel>[];
        final DateTime agora = DateTime.now();

        for (final dynamic item in listaBruta) {
          if (item is MapaJson) {
            final ev = EventoMapper.mapearJsonParaEvento(item);
            final statusLocal = inscricoesLocais[ev.id];
            final bool jaInscrito = statusLocal != null || ev.isInscrito;

            if (!incluirEncerrados) {
              if (ev.isFinalizado) {
                continue;
              }
              final DateTime limiteInscricao =
                  ev.dataHoraInicio.subtract(const Duration(hours: 1));
              if (!jaInscrito && !agora.isBefore(limiteInscricao)) {
                continue;
              }
            }

            if (statusLocal != null) {
              final int novasVagasRestantes =
                  (!ev.isInscrito && ev.vagasRestantes > 0)
                      ? ev.vagasRestantes - 1
                      : ev.vagasRestantes;
              eventos.add(ev.copyWith(
                isInscrito: true,
                statusInscricao: statusLocal,
                vagasRestantes: novasVagasRestantes,
              ));
            } else {
              eventos.add(ev);
            }
          }
        }

        if (busca != null && busca.trim().isNotEmpty) {
          final termo = busca.trim().toLowerCase();
          return eventos.where((ev) {
            return ev.titulo.toLowerCase().contains(termo) ||
                ev.descricao.toLowerCase().contains(termo) ||
                ev.ongNome.toLowerCase().contains(termo);
          }).toList();
        }

        return eventos;
      }
    } catch (e) {
      debugPrint("EventoDiscoveryService.listarEventos erro: $e");
    }

    return <EventoModel>[];
  }

  /// GET /opportunities/recommended — Vagas recomendadas com base em IA/ML
  Future<List<MapaJson>> listarEventosRecomendados({
    String? token,
    Map<String, EventoModel>? mapaCatalogo,
  }) async {
    final List<MapaJson> resultado = <MapaJson>[];
    final uri = Uri.parse("$baseUrl/opportunities/recommended");

    try {
      final res = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(res.bodyBytes));
        final List<dynamic> lista = _extrairListaBruta(decoded);

        for (final dynamic item in lista) {
          if (item is MapaJson) {
            final id = item['id']?.toString() ?? '';
            if (id.isEmpty) continue;
            final ev =
                mapaCatalogo?[id] ?? EventoMapper.mapearJsonParaEvento(item);
            if (ev.isFinalizado) continue;

            resultado.add(<String, dynamic>{
              'evento': ev,
              'matchScore': (item['matchScore'] as num?)?.toInt() ?? 0,
              'distanciaKm': (item['distanceKm'] ?? item['distanciaKm'] as num?)
                  ?.toDouble(),
              'origem': 'IA',
            });
          }
        }
      }
    } catch (e) {
      debugPrint("EventoDiscoveryService.listarEventosRecomendados erro: $e");
    }
    return resultado;
  }

  /// GET /opportunities/nearby — Vagas ativas mais próximas por geolocalização (em KM)
  Future<List<MapaJson>> listarEventosProximos({
    String? token,
    Map<String, EventoModel>? mapaCatalogo,
    double? latitude,
    double? longitude,
    double radiusKm = 25,
  }) async {
    final List<MapaJson> resultado = <MapaJson>[];
    final coords = await LocalizacaoService.instance.obterLocalizacaoAtual();

    final double lat = latitude ?? coords.latitude;
    final double lng = longitude ?? coords.longitude;

    final uri = Uri.parse("$baseUrl/opportunities/nearby").replace(
      queryParameters: <String, String>{
        'lat': lat.toString(),
        'lng': lng.toString(),
        'radius': radiusKm.toString(),
      },
    );

    try {
      final res = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(res.bodyBytes));
        final List<dynamic> lista = _extrairListaBruta(decoded);

        for (final dynamic item in lista) {
          if (item is MapaJson) {
            final id = item['id']?.toString() ?? '';
            if (id.isEmpty) continue;
            final ev =
                mapaCatalogo?[id] ?? EventoMapper.mapearJsonParaEvento(item);
            if (ev.isFinalizado) continue;

            resultado.add(<String, dynamic>{
              'evento': ev,
              'matchScore': (item['matchScore'] as num?)?.toInt() ?? 0,
              'distanciaKm': (item['distanceKm'] ??
                      item['distanciaKm'] ??
                      item['distance'] as num?)
                  ?.toDouble(),
              'origem': 'PROXIMO',
            });
          }
        }
      }
    } catch (_) {
      // Caso /nearby falhe no servidor, o fallback Haversine assume abaixo
    }
    return resultado;
  }

  /// Consolida recomendações de IA/ML (/recommended) + proximidade (/nearby) para a Home
  Future<List<MapaJson>> listarRecomendadosEProximos({
    String? token,
    List<EventoModel>? catalogoBase,
  }) async {
    final List<EventoModel> base =
        catalogoBase ?? await listarEventos(token: token);
    final Map<String, EventoModel> mapaCatalogo = <String, EventoModel>{
      for (final ev in base) ev.id: ev,
    };

    final Future<List<MapaJson>> futureIa = listarEventosRecomendados(
      token: token,
      mapaCatalogo: mapaCatalogo,
    );
    final Future<CoordenadasUsuario> futureCoords =
        LocalizacaoService.instance.obterLocalizacaoAtual();

    final List<MapaJson> listaIa = await futureIa;
    final CoordenadasUsuario coords = await futureCoords;

    final List<MapaJson> listaProximos = await listarEventosProximos(
      token: token,
      mapaCatalogo: mapaCatalogo,
      latitude: coords.latitude,
      longitude: coords.longitude,
    );

    final Map<String, MapaJson> consolidado = <String, MapaJson>{};

    for (final MapaJson item in listaIa) {
      final ev = item['evento'] as EventoModel;
      consolidado[ev.id] = MapaJson.from(item);
    }

    for (final MapaJson item in listaProximos) {
      final ev = item['evento'] as EventoModel;
      if (consolidado.containsKey(ev.id)) {
        consolidado[ev.id]!['distanciaKm'] ??= item['distanciaKm'];
      } else {
        consolidado[ev.id] = MapaJson.from(item);
      }
    }

    if (consolidado.isEmpty && base.isNotEmpty) {
      for (final ev in base) {
        consolidado[ev.id] = <String, dynamic>{
          'evento': ev,
          'matchScore': 0,
          'distanciaKm': null,
          'origem': 'CATALOGO',
        };
      }
    }

    final List<MapaJson> listaFinal = consolidado.values.toList();

    for (final MapaJson item in listaFinal) {
      if (item['distanciaKm'] == null) {
        final ev = item['evento'] as EventoModel;
        final double evLat = ev.latitude ?? 0.0;
        final double evLng = ev.longitude ?? 0.0;
        if (evLat != 0.0 && evLng != 0.0) {
          item['distanciaKm'] = _calcularDistanciaKm(
            coords.latitude,
            coords.longitude,
            evLat,
            evLng,
          );
        }
      }
    }

    listaFinal.sort((a, b) {
      final int scoreA = (a['matchScore'] as int?) ?? 0;
      final int scoreB = (b['matchScore'] as int?) ?? 0;
      if (scoreB != scoreA) return scoreB.compareTo(scoreA);

      final double distA = (a['distanciaKm'] as double?) ?? 9999.0;
      final double distB = (b['distanciaKm'] as double?) ?? 9999.0;
      return distA.compareTo(distB);
    });

    return listaFinal;
  }

  /// GET /opportunities/{id} — Payload bruto
  Future<MapaJson?> buscarDetalhesBrutosPorId(
    String id, {
    String? token,
  }) async {
    try {
      final res = await http
          .get(
            Uri.parse("$baseUrl/opportunities/$id"),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is MapaJson) return decoded;
      }
    } catch (e) {
      debugPrint("EventoDiscoveryService.buscarDetalhesBrutosPorId erro: $e");
    }
    return null;
  }

  /// GET /opportunities/{id} — Mapeado para EventoModel
  Future<EventoModel?> buscarPorId(
    String id, {
    String? token,
    Map<String, String> inscricoesLocais = const <String, String>{},
  }) async {
    final item = await buscarDetalhesBrutosPorId(id, token: token);
    if (item != null) {
      final ev = EventoMapper.mapearJsonParaEvento(item);
      final statusLocal = inscricoesLocais[id];
      if (statusLocal != null) {
        final int novasVagasRestantes =
            (!ev.isInscrito && ev.vagasRestantes > 0)
                ? ev.vagasRestantes - 1
                : ev.vagasRestantes;
        return ev.copyWith(
          isInscrito: true,
          statusInscricao: statusLocal,
          vagasRestantes: novasVagasRestantes,
        );
      }
      return ev;
    }
    return null;
  }

  /// GET /opportunities/ong/{ongId} — Vagas publicadas por uma ONG específica
  Future<List<EventoModel>> listarEventosPorOng(
    String ongId, {
    String? token,
  }) async {
    try {
      final res = await http
          .get(
            Uri.parse("$baseUrl/opportunities/ong/$ongId"),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(res.bodyBytes));
        final List<dynamic> lista = _extrairListaBruta(decoded);
        return lista
            .whereType<MapaJson>()
            .map(EventoMapper.mapearJsonParaEvento)
            .toList();
      }
    } catch (e) {
      debugPrint("EventoDiscoveryService.listarEventosPorOng erro: $e");
    }
    return <EventoModel>[];
  }
}