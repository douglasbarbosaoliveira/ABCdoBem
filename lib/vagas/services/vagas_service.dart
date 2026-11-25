// lib/vagas/services/vagas_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../services/session_service.dart';
import '../models/vaga_model.dart';

class VagasService {
  final String baseUrl;

  VagasService({
    this.baseUrl = 'https://abc-do-bem.onrender.com',
  });

  Map<String, String> get _headers {
    final token = SessionService.instance.token?.trim();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ==========================================
  // ROTAS DO VOLUNTÁRIO
  // ==========================================

  Future<List<VagaModel>> listarVagas({
    String? cidade,
    String? categoria,
  }) async {
    final queryParams = <String, String>{};
    if (cidade != null && cidade.trim().isNotEmpty) {
      queryParams['cidade'] = cidade.trim();
    }
    if (categoria != null && categoria.trim().isNotEmpty) {
      queryParams['categoria'] = categoria.trim();
    }

    final uri = Uri.parse('$baseUrl/opportunities').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

   

    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('Status Code Listar Vagas: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is List) {
          return data
              .map((item) => VagaModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('>>> ERRO ao listar vagas: $e');
    }

    return <VagaModel>[];
  }

  Future<List<VagaModel>> buscarRecomendadas() async {
    final uri = Uri.parse('$baseUrl/opportunities/recommended');
    
    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('Status Code Recomendadas: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is List) {
          return data
              .map((item) => VagaModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('>>> ERRO ao buscar vagas recomendadas: $e');
    }

    return <VagaModel>[];
  }

  Future<List<VagaModel>> buscarProximas({
    required double latitude,
    required double longitude,
    double? raioKm,
  }) async {
    final queryParams = <String, String>{
      'lat': latitude.toString(),
      'lng': longitude.toString(),
    };
    if (raioKm != null) {
      queryParams['radius'] = raioKm.toString();
    }

    final uri = Uri.parse('$baseUrl/opportunities/nearby')
        .replace(queryParameters: queryParams);

   

    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('Status Code Vagas Próximas: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is List) {
          return data
              .map((item) => VagaModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('>>> ERRO ao buscar vagas próximas: $e');
    }

    return <VagaModel>[];
  }

  Future<VagaModel?> obterDetalhes(String vagaId) async {
    final uri = Uri.parse('$baseUrl/opportunities/$vagaId');
  
    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('Status Code Detalhes: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map<String, dynamic>) {
          return VagaModel.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('>>> ERRO ao buscar detalhes da vaga: $e');
    }

    return null;
  }

  Future<bool> candidatar(String vagaId) async {
    final uri = Uri.parse('$baseUrl/opportunities/$vagaId/apply');
    
    try {
      final response = await http
          .post(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('Status Code Candidatura: ${response.statusCode}');
      debugPrint('Body Resposta: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
    } catch (e) {
      debugPrint('>>> ERRO ao submeter candidatura: $e');
    }

    return false;
  }

  // ==========================================
  // ROTAS DA ONG (GESTÃO)
  // ==========================================

  Future<VagaModel?> criarVaga(Map<String, dynamic> dadosVaga) async {
    final uri = Uri.parse('$baseUrl/opportunities');
    

    try {
      final response = await http
          .post(uri, headers: _headers, body: jsonEncode(dadosVaga))
          .timeout(const Duration(seconds: 10));

      debugPrint('Status Code Criar Vaga: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map<String, dynamic>) {
          return VagaModel.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('>>> ERRO ao criar vaga: $e');
    }

    return null;
  }

  Future<List<VagaModel>> listarPorOng(String ongId) async {
    final uri = Uri.parse('$baseUrl/opportunities/ong/$ongId');
    

    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('Status Code Vagas da ONG: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is List) {
          return data
              .map((item) => VagaModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('>>> ERRO ao buscar vagas da ONG: $e');
    }

    return <VagaModel>[];
  }

  Future<bool> atualizarVaga(String vagaId, Map<String, dynamic> dados) async {
    final uri = Uri.parse('$baseUrl/opportunities/$vagaId');
    

    try {
      final response = await http
          .patch(uri, headers: _headers, body: jsonEncode(dados))
          .timeout(const Duration(seconds: 10));

      debugPrint('Status Code Atualizar Vaga: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('>>> ERRO ao atualizar vaga: $e');
    }

    return false;
  }

  Future<bool> excluirVaga(String vagaId) async {
    final uri = Uri.parse('$baseUrl/opportunities/$vagaId');
    

    try {
      final response = await http
          .delete(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('Status Code Excluir Vaga: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('>>> ERRO ao excluir vaga: $e');
    }

    return false;
  }

  Future<List<dynamic>> listarInscritos(String vagaId) async {
    final uri = Uri.parse('$baseUrl/opportunities/$vagaId/applications');
    

    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('Status Code Listar Inscritos: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is List) {
          return data;
        }
      }
    } catch (e) {
      debugPrint('>>> ERRO ao listar inscritos: $e');
    }

    return <dynamic>[];
  }

  Future<bool> atualizarStatusCandidato(
    String applicationId,
    String novoStatus,
  ) async {
    final uri =
        Uri.parse('$baseUrl/opportunities/applications/$applicationId/status');
    

    try {
      final response = await http
          .patch(
            uri,
            headers: _headers,
            body: jsonEncode(<String, dynamic>{'status': novoStatus}),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('Status Code Alterar Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('>>> ERRO ao alterar status do candidato: $e');
    }

    return false;
  }

  Future<bool> validarPresenca(String applicationId) async {
    final uri = Uri.parse(
        '$baseUrl/opportunities/applications/$applicationId/presenca');
    

    try {
      final response = await http
          .patch(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('Status Code Validar Presença: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('>>> ERRO ao validar presença: $e');
    }

    return false;
  }
}
