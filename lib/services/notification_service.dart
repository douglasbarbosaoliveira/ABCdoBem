import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/notification_models.dart';
import 'session_service.dart';

class NotificationService {
  static final ValueNotifier<int> totalNaoLidasNotifier = ValueNotifier<int>(0);
  static final Set<String> _idsLidosLocalmente = {};

  final String baseUrl;
  final String? authToken;

  NotificationService({
    this.baseUrl = "https://abc-do-bem.onrender.com",
    this.authToken,
  });

  String? get _tokenFinal => (authToken != null && authToken!.trim().isNotEmpty)
      ? authToken!.trim()
      : SessionService.instance.token;

  Map<String, String> _montarHeaders(String? tokenParametro) {
    final token = (tokenParametro != null && tokenParametro.trim().isNotEmpty)
        ? tokenParametro.trim()
        : _tokenFinal;

    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  /// Descobre se o usuário autenticado é ONG lendo o payload do token JWT
  bool _verificarSeEhOng(String? tokenParametro, bool? isOngParametro) {
    if (isOngParametro != null) return isOngParametro;

    final token = (tokenParametro != null && tokenParametro.trim().isNotEmpty)
        ? tokenParametro.trim()
        : _tokenFinal;

    if (token == null || token.isEmpty) return false;

    try {
      final partes = token.split('.');
      if (partes.length != 3) return false;
      final payloadStr =
          utf8.decode(base64Url.decode(base64Url.normalize(partes[1])));
      final payload = jsonDecode(payloadStr);
      if (payload is Map) {
        final role =
            (payload['role'] ?? payload['tipo'] ?? payload['userType'] ?? '')
                .toString()
                .toUpperCase();
        return role == 'ONG';
      }
    } catch (_) {}

    return false;
  }

  /// 1. GET /notificacoes
  Future<List<NotificacaoModel>> buscarNotificacoes(
    String usuarioId, {
    String? token,
    bool? isOng,
  }) async {
    final url = Uri.parse('$baseUrl/notificacoes');
    final headers = _montarHeaders(token);

    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic corpo = jsonDecode(utf8.decode(response.bodyBytes));

        final List listaBruta = corpo is List
            ? corpo
            : (corpo is Map && corpo['data'] is List ? corpo['data'] : []);

        final bool perfilOng = _verificarSeEhOng(token, isOng);
        final Set<String> chavesVistas = {};

        final List<NotificacaoModel> notificacoesApi = [];
        for (final item in listaBruta) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final n = NotificacaoModel.fromJson(map);
            final raw = (n.rawType ?? '').toUpperCase();

            // ONGs não recebem alertas de novas vagas abertas nem pedidos de doação
            if (perfilOng &&
                (raw == 'NEW_OPPORTUNITY_MATCH' ||
                    raw == 'SUPPLY_NEEDED' ||
                    n.titulo.toLowerCase().contains('nova vaga compatível'))) {
              continue;
            }

            // Evita cards duplicados disparados para o mesmo evento/tipo
            final chaveDedupe = '${raw}_${n.linkId ?? n.id}';
            if (n.linkId != null &&
                n.linkId!.isNotEmpty &&
                !chavesVistas.add(chaveDedupe)) {
              continue;
            }

            if (n.titulo.trim().isNotEmpty ||
                n.mensagemCompleta.trim().isNotEmpty) {
              if (_idsLidosLocalmente.contains(n.id)) {
                n.lida = true;
              }
              notificacoesApi.add(n);
            }
          }
        }

        if (notificacoesApi.isNotEmpty) {
          final pendentes = notificacoesApi.where((n) => !n.lida).length;
          totalNaoLidasNotifier.value = pendentes;
          return notificacoesApi;
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar /notificacoes: $e');
    }

    // Fallback de onboarding caso a lista do banco ainda esteja vazia ou offline
    final padrao = _obterNotificacoesPadraoOnboarding(usuarioId);
    totalNaoLidasNotifier.value = padrao.where((n) => !n.lida).length;
    return padrao;
  }

  /// 2. GET /notificacoes/total-nao-lidas
  Future<int> buscarTotalNaoLidas(
    String usuarioId, {
    String? token,
    bool? isOng,
  }) async {
    final lista = await buscarNotificacoes(
      usuarioId,
      token: token,
      isOng: isOng,
    );
    final total = lista.where((n) => !n.lida).length;
    totalNaoLidasNotifier.value = total;
    return total;
  }

  /// 3. PATCH /notificacoes/{id}/ler
  Future<void> marcarComoLida(
    String notificacaoId, {
    String? token,
  }) async {
    _idsLidosLocalmente.add(notificacaoId);
    if (totalNaoLidasNotifier.value > 0) {
      totalNaoLidasNotifier.value = totalNaoLidasNotifier.value - 1;
    }

    final url = Uri.parse('$baseUrl/notificacoes/$notificacaoId/ler');
    final headers = _montarHeaders(token);

    try {
      await http
          .patch(url, headers: headers)
          .timeout(const Duration(seconds: 6));
    } catch (_) {}
  }

  /// 4. PATCH /notificacoes/ler-todas
  Future<void> marcarTodasComoLidas(
    String usuarioId, {
    String? token,
  }) async {
    _idsLidosLocalmente.add("notif-bem-vindo");
    _idsLidosLocalmente.add("notif-complete-perfil");
    totalNaoLidasNotifier.value = 0;

    final url = Uri.parse('$baseUrl/notificacoes/ler-todas');
    final headers = _montarHeaders(token);

    try {
      await http
          .patch(url, headers: headers)
          .timeout(const Duration(seconds: 6));
    } catch (_) {}
  }

  /// 5. POST /ongs/supplies/:supplyId/pledges ("Posso ajudar" direto da notificação)
  Future<bool> registrarCompromissoDoacao({
    required String supplyId,
    required double quantidade,
    DateTime? dataLimiteEntrega,
    String? observacoes,
    String? token,
  }) async {
    final url = Uri.parse('$baseUrl/ongs/supplies/$supplyId/pledges');
    final headers = _montarHeaders(token);

    final body = jsonEncode({
      'quantidade': quantidade,
      if (dataLimiteEntrega != null)
        'dataLimiteEntrega': dataLimiteEntrega.toIso8601String(),
      if (observacoes != null && observacoes.trim().isNotEmpty)
        'observacoes': observacoes.trim(),
    });

    final response = await http
        .post(url, headers: headers, body: body)
        .timeout(const Duration(seconds: 10));

    return response.statusCode == 200 || response.statusCode == 201;
  }

  List<NotificacaoModel> _obterNotificacoesPadraoOnboarding(String usuarioId) {
    final nomeUsuario = SessionService.instance.nomeUsuario;
    final primeiroNome = (nomeUsuario != null && nomeUsuario.trim().isNotEmpty)
        ? nomeUsuario.trim().split(' ').first
        : 'Voluntário';

    return [
      NotificacaoModel(
        id: "notif-bem-vindo",
        usuarioId: usuarioId,
        tipo: TipoNotificacao.sistema,
        titulo: "Boas-vindas ao ABC do Bem! 🤝",
        descricaoCurta:
            "Olá, $primeiroNome! Sua jornada de impacto social começa aqui.",
        mensagemCompleta:
            "Seja muito bem-vindo à nossa rede solidária! Aqui você pode descobrir oportunidades de voluntariado, apoiar ONGs da sua região e transformar vidas através da sua dedicação.",
        criadoEm: DateTime.now().subtract(const Duration(minutes: 5)),
        lida: _idsLidosLocalmente.contains("notif-bem-vindo"),
      ),
      NotificacaoModel(
        id: "notif-complete-perfil",
        usuarioId: usuarioId,
        tipo: TipoNotificacao.conquista,
        titulo: "Atualize e complete o seu perfil 📝",
        descricaoCurta:
            "Adicione sua foto, causas favoritas e habilidades para conectar-se melhor.",
        mensagemCompleta:
            "Com o seu perfil completo e foto atualizada, as instituições locais conseguem conhecer melhor suas habilidades e você terá recomendações mais alinhadas aos seus interesses.",
        criadoEm: DateTime.now().subtract(const Duration(minutes: 15)),
        lida: _idsLidosLocalmente.contains("notif-complete-perfil"),
      ),
    ];
  }
}
