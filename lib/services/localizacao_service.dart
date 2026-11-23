// lib/services/localizacao_service.dart

import 'package:geolocator/geolocator.dart';
import 'session_service.dart';

class CoordenadasUsuario {
  final double latitude;
  final double longitude;
  final bool isRealGps;

  const CoordenadasUsuario({
    required this.latitude,
    required this.longitude,
    required this.isRealGps,
  });
}

class LocalizacaoService {
  LocalizacaoService._();
  static final LocalizacaoService instance = LocalizacaoService._();

  CoordenadasUsuario? _ultimaLocalizacao;
  Future<CoordenadasUsuario>? _leituraEmAndamento;

  Future<CoordenadasUsuario> obterLocalizacaoAtual({
    bool forcarNovaLeitura = false,
  }) {
    if (!forcarNovaLeitura && _ultimaLocalizacao != null) {
      return Future<CoordenadasUsuario>.value(_ultimaLocalizacao!);
    }

    if (_leituraEmAndamento != null) {
      return _leituraEmAndamento!;
    }

    _leituraEmAndamento = _executarLeitura().whenComplete(() {
      _leituraEmAndamento = null;
    });

    return _leituraEmAndamento!;
  }

  Future<CoordenadasUsuario> _executarLeitura() async {
    try {
      final bool servicoAtivo = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 2));
      if (servicoAtivo) {
        LocationPermission permissao = await Geolocator.checkPermission()
            .timeout(const Duration(seconds: 2));

        if (permissao == LocationPermission.denied) {
          permissao = await Geolocator.requestPermission()
              .timeout(const Duration(seconds: 4));
        }

        if (permissao == LocationPermission.whileInUse ||
            permissao == LocationPermission.always) {
          final Position pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 3),
            ),
          ).timeout(const Duration(seconds: 3));

          _ultimaLocalizacao = CoordenadasUsuario(
            latitude: pos.latitude,
            longitude: pos.longitude,
            isRealGps: true,
          );
          return _ultimaLocalizacao!;
        }
      }
    } catch (_) {
      // Fallback imediato caso o navegador/iframe bloqueie ou demore > 3s
    }

    final dadosUsuario = SessionService.instance.dadosCompletosUsuario;
    final double? latPerfil = (dadosUsuario?['latitude'] as num?)?.toDouble();
    final double? lngPerfil = (dadosUsuario?['longitude'] as num?)?.toDouble();

    if (latPerfil != null && lngPerfil != null && latPerfil != 0) {
      _ultimaLocalizacao = CoordenadasUsuario(
        latitude: latPerfil,
        longitude: lngPerfil,
        isRealGps: false,
      );
      return _ultimaLocalizacao!;
    }

    _ultimaLocalizacao = const CoordenadasUsuario(
      latitude: -23.6677,
      longitude: -46.4613,
      isRealGps: false,
    );
    return _ultimaLocalizacao!;
  }
}
