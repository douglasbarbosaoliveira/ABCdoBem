// lib/widgets/mapa/localizacao_mapa_card.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LocalizacaoMapaCard extends StatefulWidget {
  final String tituloSecao;
  final String endereco;
  final String cidade;
  final double? latitude;
  final double? longitude;
  final double alturaMapa;
  final bool mostrarBotaoEditar;
  final VoidCallback? onEditarEndereco;
  final String tooltipCentralizar;

  const LocalizacaoMapaCard({
    super.key,
    required this.tituloSecao,
    required this.endereco,
    required this.cidade,
    this.latitude,
    this.longitude,
    this.alturaMapa = 200,
    this.mostrarBotaoEditar = false,
    this.onEditarEndereco,
    this.tooltipCentralizar = "Centralizar no endereço",
  });

  @override
  State<LocalizacaoMapaCard> createState() => _LocalizacaoMapaCardState();
}

class _LocalizacaoMapaCardState extends State<LocalizacaoMapaCard> {
  static const LatLng _pontoPadraoGrandeABC = LatLng(-23.6638, -46.5383);
  static final Map<String, LatLng> _cacheGeocoding = <String, LatLng>{};

  static const double _zoomMin = 12.0;
  static const double _zoomMax = 19.0;

  final MapController _mapController = MapController();
  LatLng? _coordenadaResolvida;
  double _zoomAtual = 17.5;
  bool _buscandoCoordenadas = false;

  @override
  void initState() {
    super.initState();
    _resolverLocalizacaoExata();
  }

  @override
  void didUpdateWidget(covariant LocalizacaoMapaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endereco != widget.endereco ||
        oldWidget.cidade != widget.cidade ||
        oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      _resolverLocalizacaoExata();
    }
  }

  /// Identifica coordenadas padrão genéricas inseridas pelos serviços quando a API não envia lat/lng
  bool _isCoordenadaFallbackGenerica(double lat, double lng) {
    final bool fallbackEvento =
        (lat - (-23.668)).abs() < 0.002 && (lng - (-46.461)).abs() < 0.002;
    final bool fallbackOng =
        (lat - (-23.6687)).abs() < 0.002 && (lng - (-46.4614)).abs() < 0.002;
    final bool fallbackAbc =
        (lat - (-23.6638)).abs() < 0.002 && (lng - (-46.5383)).abs() < 0.002;
    return fallbackEvento || fallbackOng || fallbackAbc;
  }

  bool get _temCoordenadasReais {
    final lat = widget.latitude;
    final lng = widget.longitude;
    if (lat == null || lng == null) return false;
    if (lat.isNaN || lng.isNaN || (lat == 0.0 && lng == 0.0)) return false;
    if (lat < -90.0 || lat > 90.0 || lng < -180.0 || lng > 180.0) return false;
    if (_isCoordenadaFallbackGenerica(lat, lng)) return false;
    return true;
  }

  String _limparEnderecoParaBusca(String bruto) {
    var limpo = bruto.trim();
    final idxRef = limpo.indexOf('(Ref:');
    if (idxRef != -1) {
      limpo = limpo.substring(0, idxRef).trim();
    }
    final idxCep = limpo.indexOf('(CEP:');
    if (idxCep != -1) {
      limpo = limpo.substring(0, idxCep).trim();
    }
    return limpo;
  }

  bool _isEnderecoApenasCidadeGenerica(String enderecoLimpo, String cidade) {
    if (enderecoLimpo.isEmpty) return true;
    final lower = enderecoLimpo.toLowerCase();
    final cidadeLower = cidade.toLowerCase().trim();
    if (lower.contains('a confirmar') || lower.contains('grande abc')) {
      return true;
    }
    if (cidadeLower.isNotEmpty &&
        (lower == cidadeLower ||
            lower == '$cidadeLower - sp' ||
            lower == '$cidadeLower, sp')) {
      return true;
    }
    return false;
  }

  ({String rua, String numero, String bairro}) _extrairPartesEndereco(
    String enderecoLimpo,
  ) {
    final partesHifen = enderecoLimpo.split(' - ');
    final ruaENumero = partesHifen.first.trim();
    final bairro = partesHifen.length > 1 ? partesHifen[1].trim() : '';

    final partesVirgula = ruaENumero.split(',');
    if (partesVirgula.length >= 2) {
      final rua = partesVirgula.first.trim();
      final resto = partesVirgula[1].trim();
      final primeiroToken = resto.split(' ').first.trim();
      final ehNumero =
          primeiroToken.isNotEmpty && int.tryParse(primeiroToken) != null;
      if (ehNumero) {
        return (rua: rua, numero: primeiroToken, bairro: bairro);
      }
    }
    return (rua: ruaENumero, numero: '', bairro: bairro);
  }

  Future<void> _resolverLocalizacaoExata() async {
    if (_temCoordenadasReais) {
      final destino = LatLng(widget.latitude!, widget.longitude!);
      setState(() {
        _coordenadaResolvida = destino;
        _zoomAtual = 17.5;
      });
      _moverMapaComSeguranca(destino, 17.5);
      return;
    }

    final cidade = widget.cidade.trim();
    if (cidade.toLowerCase() == 'remoto') return;

    final enderecoLimpo = _limparEnderecoParaBusca(widget.endereco);
    if (_isEnderecoApenasCidadeGenerica(enderecoLimpo, cidade)) {
      setState(() {
        _coordenadaResolvida = _pontoPadraoGrandeABC;
        _zoomAtual = 14.0;
      });
      return;
    }

    final chaveCache = '$enderecoLimpo|$cidade'.toLowerCase();
    if (_cacheGeocoding.containsKey(chaveCache)) {
      final cached = _cacheGeocoding[chaveCache]!;
      setState(() {
        _coordenadaResolvida = cached;
        _zoomAtual = 17.5;
      });
      _moverMapaComSeguranca(cached, 17.5);
      return;
    }

    if (mounted) setState(() => _buscandoCoordenadas = true);

    final parsed = _extrairPartesEndereco(enderecoLimpo);
    LatLng? encontrada;

    // 1. ArcGIS World Geocoder
    final enderecoArcGis = <String>[
      if (parsed.rua.isNotEmpty && parsed.numero.isNotEmpty)
        '${parsed.rua}, ${parsed.numero}'
      else if (parsed.rua.isNotEmpty)
        parsed.rua,
      if (parsed.bairro.isNotEmpty &&
          !parsed.bairro.toLowerCase().contains(cidade.toLowerCase()))
        parsed.bairro,
      if (cidade.isNotEmpty &&
          !enderecoLimpo.toLowerCase().contains(cidade.toLowerCase()))
        cidade,
      'SP',
      'Brasil',
    ].join(', ');
    encontrada = await _consultarArcGis(enderecoArcGis);

    // 2. Fallback: Photon (Komoot)
    if (encontrada == null) {
      final queryPhoton = <String>[
        if (parsed.rua.isNotEmpty) parsed.rua,
        if (parsed.numero.isNotEmpty) parsed.numero,
        if (cidade.isNotEmpty) cidade,
        'São Paulo',
        'Brasil',
      ].join(', ');
      encontrada = await _consultarPhoton(queryPhoton, cidade);
    }

    // 3. Fallback: Nominatim estruturado
    if (encontrada == null && parsed.rua.isNotEmpty && cidade.isNotEmpty) {
      final streetParam = parsed.numero.isNotEmpty
          ? '${parsed.numero} ${parsed.rua}'
          : parsed.rua;
      encontrada = await _consultarNominatimEstruturado(
        street: streetParam,
        city: cidade,
      );
    }

    if (!mounted) return;

    final destino = encontrada ??
        (widget.latitude != null && widget.longitude != null
            ? LatLng(widget.latitude!, widget.longitude!)
            : _pontoPadraoGrandeABC);

    if (encontrada != null) {
      _cacheGeocoding[chaveCache] = encontrada;
    }

    final zoomInicial = encontrada != null ? 17.5 : 14.5;

    setState(() {
      _coordenadaResolvida = destino;
      _zoomAtual = zoomInicial;
      _buscandoCoordenadas = false;
    });

    _moverMapaComSeguranca(destino, zoomInicial);
  }

  Future<LatLng?> _consultarArcGis(String singleLineAddress) async {
    try {
      final uri = Uri.https(
        'geocode.arcgis.com',
        '/arcgis/rest/services/World/GeocodeServer/findAddressCandidates',
        <String, String>{
          'SingleLine': singleLineAddress,
          'countryCode': 'BRA',
          'maxLocations': '1',
          'f': 'pjson',
        },
      );

      final res = await http.get(
        uri,
        headers: const <String, String>{'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is Map<String, dynamic> && decoded['candidates'] is List) {
          final candidates = decoded['candidates'] as List<dynamic>;
          if (candidates.isNotEmpty && candidates.first is Map) {
            final first = candidates.first as Map;
            final score = (first['score'] as num?)?.toDouble() ?? 0;
            final loc = first['location'];
            if (score >= 75 && loc is Map) {
              final lat = (loc['y'] as num?)?.toDouble();
              final lon = (loc['x'] as num?)?.toDouble();
              if (lat != null && lon != null) {
                return LatLng(lat, lon);
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ArcGIS geocoding ($singleLineAddress): $e');
    }
    return null;
  }

  Future<LatLng?> _consultarPhoton(String query, String cidadeEsperada) async {
    try {
      final uri = Uri.https(
        'photon.komoot.io',
        '/api/',
        <String, String>{
          'q': query,
          'limit': '5',
          'lat': '-23.668',
          'lon': '-46.461',
        },
      );

      final res = await http.get(
        uri,
        headers: const <String, String>{
          'Accept': 'application/json',
          'User-Agent': 'ABCdoBemApp/1.0 (contato@abcdobem.org)',
        },
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is Map<String, dynamic> && decoded['features'] is List) {
          final features = decoded['features'] as List<dynamic>;
          LatLng? primeiroValido;

          for (final f in features) {
            if (f is Map<String, dynamic>) {
              final geom = f['geometry'];
              final props = f['properties'];
              if (geom is Map && geom['coordinates'] is List) {
                final coords = geom['coordinates'] as List<dynamic>;
                if (coords.length >= 2) {
                  final lon = double.tryParse(coords[0].toString());
                  final lat = double.tryParse(coords[1].toString());
                  if (lat != null && lon != null) {
                    final candidato = LatLng(lat, lon);
                    primeiroValido ??= candidato;

                    final cityProp = (props is Map
                            ? (props['city'] ?? props['county'] ?? '')
                            : '')
                        .toString()
                        .toLowerCase();
                    final hasHouseNumber =
                        props is Map && props['housenumber'] != null;

                    if (hasHouseNumber &&
                        (cidadeEsperada.isEmpty ||
                            cityProp.contains(cidadeEsperada.toLowerCase()))) {
                      return candidato;
                    }
                  }
                }
              }
            }
          }
          return primeiroValido;
        }
      }
    } catch (e) {
      debugPrint('Erro Photon geocoding ($query): $e');
    }
    return null;
  }

  Future<LatLng?> _consultarNominatimEstruturado({
    required String street,
    required String city,
  }) async {
    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        <String, String>{
          'street': street,
          'city': city,
          'state': 'São Paulo',
          'country': 'Brazil',
          'format': 'json',
          'limit': '1',
        },
      );

      final res = await http.get(
        uri,
        headers: const <String, String>{
          'Accept': 'application/json',
          'User-Agent': 'ABCdoBemApp/1.0 (contato@abcdobem.org)',
        },
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is List && decoded.isNotEmpty) {
          final first = decoded.first;
          if (first is Map<String, dynamic>) {
            final lat = double.tryParse(first['lat']?.toString() ?? '');
            final lon = double.tryParse(first['lon']?.toString() ?? '');
            if (lat != null && lon != null) {
              return LatLng(lat, lon);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Erro Nominatim estruturado ($street): $e');
    }
    return null;
  }

  void _moverMapaComSeguranca(LatLng destino, double zoom) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapController.move(destino, zoom);
      } catch (_) {}
    });
  }

  void _alterarZoom(double delta, LatLng pontoAtual) {
    final novoZoom = (_zoomAtual + delta).clamp(_zoomMin, _zoomMax);
    if (novoZoom == _zoomAtual) return;
    setState(() => _zoomAtual = novoZoom);
    try {
      _mapController.move(pontoAtual, novoZoom);
    } catch (_) {}
  }

  void _centralizarNoPino(LatLng pontoAtual) {
    setState(() => _zoomAtual = 17.5);
    try {
      _mapController.move(pontoAtual, 17.5);
    } catch (_) {}
  }

  String get _enderecoFormatadoExibicao {
    final end = widget.endereco.trim();
    final cid = widget.cidade.trim();
    if (end.isEmpty) {
      return cid.isNotEmpty
          ? "$cid (Endereço exato a confirmar com a organização)"
          : "Grande ABC - SP";
    }
    if (cid.isNotEmpty && !end.toLowerCase().contains(cid.toLowerCase())) {
      return "$end - $cid";
    }
    return end;
  }

  void _copiarEndereco(BuildContext context) {
    final textoCompleto = _enderecoFormatadoExibicao;
    if (textoCompleto.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: textoCompleto));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Endereço copiado para a área de transferência!"),
          backgroundColor: Color(0xFF0C6B6B),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildBotaoControleMapa({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    final desabilitado = onPressed == null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        elevation: 2,
        shadowColor: Colors.black26,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              icon,
              size: 19,
              color:
                  desabilitado ? Colors.grey.shade400 : const Color(0xFF062222),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LatLng pontoFinal = _coordenadaResolvida ??
        (widget.latitude != null && widget.longitude != null
            ? LatLng(widget.latitude!, widget.longitude!)
            : _pontoPadraoGrandeABC);

    final podeAproximar = _zoomAtual < _zoomMax;
    final podeAfastar = _zoomAtual > _zoomMin;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC2E4DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.tituloSecao,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF062222),
                ),
              ),
              if (widget.mostrarBotaoEditar)
                TextButton.icon(
                  onPressed: widget.onEditarEndereco,
                  icon: const Icon(Icons.edit_location_alt_outlined, size: 14),
                  label: const Text(
                    "Editar Local",
                    style: TextStyle(fontSize: 11),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0C6B6B),
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF0C6B6B),
                  size: 16,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _enderecoFormatadoExibicao,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5A8A80),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: double.infinity,
              height: widget.alturaMapa,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: pontoFinal,
                      initialZoom: _zoomAtual,
                      minZoom: _zoomMin,
                      maxZoom: _zoomMax,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
                      ),
                      onPositionChanged: (camera, hasGesture) {
                        if (hasGesture && camera.zoom != _zoomAtual) {
                          setState(() => _zoomAtual = camera.zoom);
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.abcdobem.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: pontoFinal,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFF0C6B6B),
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_buscandoCoordenadas)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF0C6B6B),
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              "Localizando endereço...",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF062222),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildBotaoControleMapa(
                          icon: Icons.my_location_rounded,
                          tooltip: widget.tooltipCentralizar,
                          onPressed: () => _centralizarNoPino(pontoFinal),
                        ),
                        const SizedBox(height: 6),
                        _buildBotaoControleMapa(
                          icon: Icons.add_rounded,
                          tooltip: "Aproximar (+)",
                          onPressed: podeAproximar
                              ? () => _alterarZoom(1.0, pontoFinal)
                              : null,
                        ),
                        const SizedBox(height: 4),
                        _buildBotaoControleMapa(
                          icon: Icons.remove_rounded,
                          tooltip: "Afastar (-)",
                          onPressed: podeAfastar
                              ? () => _alterarZoom(-1.0, pontoFinal)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _copiarEndereco(context),
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text("Copiar Endereço Completo"),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0C6B6B),
                side: const BorderSide(color: Color(0xFF0C6B6B)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
