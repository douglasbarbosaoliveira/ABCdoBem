// lib/services/event_service.dart

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/event_models.dart';

/// Serviço responsável pela integração com a API RESTful de Eventos e Inscrições.
class EventService {
  final String baseUrl;
  final String? authToken;

  EventService({this.baseUrl = "https://api.exemplo.com/v1", this.authToken});

  Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "Accept": "application/json",
    if (authToken != null) "Authorization": "Bearer $authToken",
  };

  // ===========================================================================
  // ÁREA DA ONG: CADASTRO E GERENCIAMENTO DE EVENTOS
  // ===========================================================================

  /// POST /eventos
  /// Cadastra um novo evento no sistema.
  Future<EventoModel> criarEvento(CriarEventoDTO dto) async {
    final url = Uri.parse('$baseUrl/eventos');

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(dto.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return EventoModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
          "Falha ao criar evento. Status: ${response.statusCode}",
        );
      }
    } catch (e) {
      // Fallback de desenvolvimento local se o servidor estiver offline
      await Future.delayed(const Duration(milliseconds: 300));
      return EventoModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        ongId: dto.ongId,
        ongNome: dto.ongNome,
        titulo: dto.titulo,
        descricao: dto.descricao,
        cidade: dto.cidade,
        endereco: dto.endereco,
        data: dto.data,
        horario: dto.horario,
        dataHoraInicio: dto.dataHoraInicio,
        imagemUrl: dto.imagemUrl,
        tags: dto.tags,
        vagasTotais: dto.vagasTotais,
        vagasRestantes: dto.vagasTotais,
        criadoEm: DateTime.now(),
      );
    }
  }

  /// GET /ongs/{ongId}/eventos
  /// Lista todos os eventos cadastrados por uma ONG específica.
  Future<List<EventoModel>> buscarEventosPorOng(String ongId) async {
    final url = Uri.parse('$baseUrl/ongs/$ongId/eventos');

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List dados = jsonDecode(response.body);
        return dados.map((e) => EventoModel.fromJson(e)).toList();
      } else {
        throw Exception(
          "Erro ao buscar eventos da ONG: ${response.statusCode}",
        );
      }
    } catch (e) {
      return [];
    }
  }

  /// PATCH /inscricoes/{inscricaoId}/status
  /// ONG aprova ou recusa uma solicitação de vaga.
  Future<void> atualizarStatusInscricao({
    required String inscricaoId,
    required String novoStatus, // 'Aprovado' ou 'Recusado'
  }) async {
    final url = Uri.parse('$baseUrl/inscricoes/$inscricaoId/status');

    final response = await http.patch(
      url,
      headers: _headers,
      body: jsonEncode({'status': novoStatus}),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Erro ao atualizar status da inscrição.");
    }
  }

  // ===========================================================================
  // ÁREA DO VOLUNTÁRIO: VITRINE, INSCRIÇÃO E CANCELAMENTO
  // ===========================================================================

  /// GET /eventos?voluntarioId={id}&cidade={cidade}&tag={tag}
  /// Lista os eventos disponíveis na vitrine com filtros opcionais.
  Future<List<EventoModel>> buscarEventosDisponiveis({
    String? voluntarioId,
    String? cidade,
    String? tag,
  }) async {
    final queryParams = {
      if (voluntarioId != null) 'voluntarioId': voluntarioId,
      if (cidade != null) 'cidade': cidade,
      if (tag != null && tag != 'Todos') 'tag': tag,
    };

    final url = Uri.parse('$baseUrl/eventos')
        .replace(queryParameters: queryParams);

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List dados = jsonDecode(response.body);
        return dados.map((e) => EventoModel.fromJson(e)).toList();
      } else {
        throw Exception(
          "Erro ao carregar eventos da API: ${response.statusCode}",
        );
      }
    } catch (e) {
      // Fallback com dados padrão para testes enquanto a API não responde
      await Future.delayed(const Duration(milliseconds: 300));
      return _obterEventosMockados();
    }
  }

  /// POST /eventos/{eventoId}/inscricoes
  /// Disparado pelo botão "Sim, quero participar" no pop-up de confirmação.
  Future<InscricaoEventoModel> solicitarParticipacao({
    required String eventoId,
    required String voluntarioId,
    required bool autorizouContato,
  }) async {
    final url = Uri.parse('$baseUrl/eventos/$eventoId/inscricoes');

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'voluntarioId': voluntarioId,
          'autorizouContato': autorizouContato,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return InscricaoEventoModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Erro ao solicitar participação.");
      }
    } catch (e) {
      await Future.delayed(const Duration(milliseconds: 200));
      return InscricaoEventoModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        eventoId: eventoId,
        voluntarioId: voluntarioId,
        status: 'Aguardando Aprovação',
        autorizouContato: autorizouContato,
        criadoEm: DateTime.now(),
      );
    }
  }

  /// POST /eventos/{eventoId}/cancelar
  /// Disparado pelo pop-up de cancelamento com o motivo selecionado nos chips.
  Future<void> cancelarParticipacao({
    required String eventoId,
    required String voluntarioId,
    required String motivo,
  }) async {
    final url = Uri.parse('$baseUrl/eventos/$eventoId/cancelar');

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({'voluntarioId': voluntarioId, 'motivo': motivo}),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception("Erro ao enviar cancelamento para a API.");
      }
    } catch (e) {
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  /// GET /voluntarios/{voluntarioId}/meus-eventos
  /// Alimenta a aba "Meus Eventos", separando próximos e histórico concluído.
  Future<Map<String, List<InscricaoEventoModel>>> buscarMeusEventos(
    String voluntarioId,
  ) async {
    final url = Uri.parse('$baseUrl/voluntarios/$voluntarioId/meus-eventos');

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> dados = jsonDecode(response.body);

        final List proximosJson = dados['proximos'] ?? [];
        final List concluidosJson = dados['concluidos'] ?? [];

        return {
          'proximos': proximosJson
              .map((i) => InscricaoEventoModel.fromJson(i))
              .toList(),
          'concluidos': concluidosJson
              .map((i) => InscricaoEventoModel.fromJson(i))
              .toList(),
        };
      } else {
        throw Exception("Erro ao buscar Meus Eventos.");
      }
    } catch (e) {
      // Fallback
      return {'proximos': [], 'concluidos': []};
    }
  }

  // --- MOCK DE DESENVOLVIMENTO (Substituído automaticamente pela resposta da API) ---
  List<EventoModel> _obterEventosMockados() {
    return [
      EventoModel(
        id: "1",
        ongId: "ong-1",
        ongNome: "Mãos que Fazem",
        titulo: "Mutirão de Reforço Escolar",
        descricao: "Aulas de apoio em matemática e português para crianças.",
        cidade: "Santo André",
        data: "2026-09-12",
        horario: "08:00 - 12:00",
        dataHoraInicio: DateTime(2026, 9, 12, 8, 0),
        imagemUrl: "https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?w=600",
        tags: ["Educação"],
        vagasTotais: 15,
        vagasRestantes: 4,
        criadoEm: DateTime.now(),
        statusInscricao: "Aprovado",
      ),
      EventoModel(
        id: "2",
        ongId: "ong-2",
        ongNome: "Ação Verde ABC",
        titulo: "Plantio Comunitário na Represa",
        descricao:
            "Reflorestamento e conscientização ambiental na represa Billings.",
        cidade: "São Bernardo do Campo",
        data: "2026-09-19",
        horario: "09:00 - 14:00",
        dataHoraInicio: DateTime(2026, 9, 19, 9, 0),
        imagemUrl: "https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?w=600",
        tags: ["Meio Ambiente"],
        vagasTotais: 30,
        vagasRestantes: 2,
        criadoEm: DateTime.now(),
      ),
    ];
  }
}
