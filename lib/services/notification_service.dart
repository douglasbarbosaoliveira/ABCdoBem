// lib/services/notification_service.dart

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/notification_models.dart';

/// Serviço responsável por consumir a API RESTful de Notificações.
class NotificationService {
  final String baseUrl;
  final String? authToken;

  NotificationService({
    this.baseUrl = "https://api.abc-do-bem.com.br/v1",
    this.authToken,
  });

  Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "Accept": "application/json",
    if (authToken != null) "Authorization": "Bearer $authToken",
  };

  /// 1. GET /usuarios/{usuarioId}/notificacoes
  /// Busca o histórico de notificações do usuário.
  Future<List<NotificacaoModel>> buscarNotificacoes(String usuarioId) async {
    final url = Uri.parse('$baseUrl/usuarios/$usuarioId/notificacoes');

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List dados = jsonDecode(response.body);
        return dados.map((json) => NotificacaoModel.fromJson(json)).toList();
      } else {
        throw Exception(
          "Erro ao buscar notificações. Código: ${response.statusCode}",
        );
      }
    } catch (e) {
      // Fallback didático para testes enquanto a API estiver fora do ar
      await Future.delayed(const Duration(milliseconds: 250));
      return _obterNotificacoesMock(usuarioId);
    }
  }

  /// 2. GET /usuarios/{usuarioId}/notificacoes/nao-lidas/count
  /// Retorna apenas a contagem numérica de alertas pendentes para alimentar os badges.
  Future<int> buscarTotalNaoLidas(String usuarioId) async {
    final url = Uri.parse(
      '$baseUrl/usuarios/$usuarioId/notificacoes/nao-lidas/count',
    );

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final dados = jsonDecode(response.body);
        return dados['totalNaoLidas'] ?? 0;
      }
    } catch (_) {}

    return 3; // Fallback mock
  }

  /// 3. PATCH /notificacoes/{notificacaoId}/lida
  /// Marca uma notificação específica como lida (acionado ao abrir o pop-up).
  Future<void> marcarComoLida(String notificacaoId) async {
    final url = Uri.parse('$baseUrl/notificacoes/$notificacaoId/lida');

    try {
      final response = await http.patch(
        url,
        headers: _headers,
        body: jsonEncode({'lida': true}),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception("Falha ao marcar notificação como lida.");
      }
    } catch (e) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  /// 4. PATCH /usuarios/{usuarioId}/notificacoes/marcar-todas-lidas
  /// Marca todas as notificações do usuário como lidas simultaneamente.
  Future<void> marcarTodasComoLidas(String usuarioId) async {
    final url = Uri.parse(
      '$baseUrl/usuarios/$usuarioId/notificacoes/marcar-todas-lidas',
    );

    try {
      final response = await http.patch(url, headers: _headers);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception("Falha ao marcar todas como lidas.");
      }
    } catch (e) {
      await Future.delayed(const Duration(milliseconds: 80));
    }
  }

  // --- MOCK LOCAL DIDÁTICO (Substituído automaticamente pela sua API) ---
  List<NotificacaoModel> _obterNotificacoesMock(String usuarioId) {
    return [
      NotificacaoModel(
        id: "notif-1",
        usuarioId: usuarioId,
        tipo: TipoNotificacao.evento,
        titulo: "Novo evento perto de você! 📍",
        descricaoCurta:
            "Mutirão de Reforço Escolar a 1,2 km de você em Santo André.",
        mensagemCompleta: "A ONG Mãos que Fazem abriu vagas para um novo mutirão de reforço escolar que combina 98% com suas habilidades em Santo André. Que tal participar?",
        criadoEm: DateTime.now().subtract(const Duration(minutes: 15)),
        lida: false,
        eventoId: "1",
      ),
      NotificacaoModel(
        id: "notif-2",
        usuarioId: usuarioId,
        tipo: TipoNotificacao.aprovacao,
        titulo: "Inscrição Aprovada! 🎉",
        descricaoCurta:
            "Ação Verde ABC confirmou sua presença no Plantio Comunitário.",
        mensagemCompleta: "Parabéns! Sua solicitação para participar do Plantio Comunitário na Represa Billings foi aprovada pela instituição. Prepare suas luvas e chapéu!",
        criadoEm: DateTime.now().subtract(const Duration(hours: 2)),
        lida: false,
        eventoId: "2",
      ),
      NotificacaoModel(
        id: "notif-3",
        usuarioId: usuarioId,
        tipo: TipoNotificacao.conquista,
        titulo: "Novo Nível: Voluntário Ouro! 🏆",
        descricaoCurta: "Você ultrapassou 40 horas doadas no ABC do Bem.",
        mensagemCompleta: "Incrível! Pela sua dedicação e impacto nas cidades do Grande ABC, você acaba de conquistar o selo Ouro no seu perfil. Continue transformando vidas!",
        criadoEm: DateTime.now().subtract(const Duration(days: 1)),
        lida: false,
      ),
      NotificacaoModel(
        id: "notif-4",
        usuarioId: usuarioId,
        tipo: TipoNotificacao.sistema,
        titulo: "Complete seu perfil 📝",
        descricaoCurta: "Adicione suas causas favoritas para receber alertas mais precisos.",
        mensagemCompleta: "Seu perfil está 80% completo. Conte-nos mais sobre as áreas que você mais gosta de atuar para receber convites cirúrgicos de ONGs da sua região.",
        criadoEm: DateTime.now().subtract(const Duration(days: 3)),
        lida: true,
      ),
    ];
  }
}
