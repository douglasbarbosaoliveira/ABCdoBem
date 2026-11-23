// lib/admin/services/admin_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/admin_models.dart';

class AdminService {
  static const String _baseUrl = 'https://abc-do-bem.onrender.com';

  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// 1. GET /admin/stats
  /// Retorna as estatísticas e contadores gerais da plataforma
  Future<AdminStatsModel?> obterEstatisticas({required String? token}) async {
    try {
      final url = Uri.parse('$_baseUrl/admin/stats');
      final res = await http.get(url, headers: _headers(token));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return AdminStatsModel.fromJson(data);
      } else {
        debugPrint(
            '>>> [AdminService] Erro ao obter stats: ${res.statusCode} - ${res.body}');
      }
    } catch (e) {
      debugPrint('>>> [AdminService] Exceção ao obter stats: $e');
    }
    return null;
  }

  /// 2. GET /admin/users
  /// Lista utilizadores registados, com filtro opcional por role (ex: USER, ONG, ADMIN)
  Future<List<AdminUserModel>> listarUsuarios({
    required String? token,
    String? role,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (role != null && role.isNotEmpty && role != 'ALL') {
        queryParams['role'] = role;
      }

      final url = Uri.parse('$_baseUrl/admin/users').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final res = await http.get(url, headers: _headers(token));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          return data.map((u) => AdminUserModel.fromJson(u)).toList();
        } else if (data['users'] is List) {
          return (data['users'] as List)
              .map((u) => AdminUserModel.fromJson(u))
              .toList();
        }
      } else {
        debugPrint(
            '>>> [AdminService] Erro ao listar utilizadores: ${res.statusCode} - ${res.body}');
      }
    } catch (e) {
      debugPrint('>>> [AdminService] Exceção ao listar utilizadores: $e');
    }
    return [];
  }

  /// 3. PATCH /admin/users/{id}/role
  /// Altera o nível de privilégio do utilizador (ex: USER -> ADMIN)
  Future<bool> alterarRoleUsuario({
    required String id,
    required String novoRole,
    required String? token,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/admin/users/$id/role');
      final res = await http.patch(
        url,
        headers: _headers(token),
        body: jsonEncode({'role': novoRole}),
      );

      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('>>> [AdminService] Exceção ao alterar role: $e');
      return false;
    }
  }

  /// 4. DELETE /admin/users/{id}
  /// Bane/remove definitivamente uma conta de voluntário ou ONG
  Future<bool> banirUsuario({
    required String id,
    required String? token,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/admin/users/$id');
      final res = await http.delete(url, headers: _headers(token));

      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('>>> [AdminService] Exceção ao banir utilizador: $e');
      return false;
    }
  }

  /// 5. DELETE /admin/opportunities/{id}
  /// Remove uma vaga ou evento impróprio/fraudulento
  Future<bool> removerOportunidade({
    required String id,
    required String? token,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/admin/opportunities/$id');
      final res = await http.delete(url, headers: _headers(token));

      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('>>> [AdminService] Exceção ao remover oportunidade: $e');
      return false;
    }
  }

  /// 6. DELETE /admin/social/posts/{id}
  /// Remove uma publicação institucional de ONG do feed
  Future<bool> removerPostagemOng({
    required String id,
    required String? token,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/admin/social/posts/$id');
      final res = await http.delete(url, headers: _headers(token));

      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('>>> [AdminService] Exceção ao remover post de ONG: $e');
      return false;
    }
  }

  /// 7. DELETE /admin/social/experiences/{id}
  /// Remove um relato de experiência de voluntário do feed
  Future<bool> removerExperienciaVoluntario({
    required String id,
    required String? token,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/admin/social/experiences/$id');
      final res = await http.delete(url, headers: _headers(token));

      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint(
          '>>> [AdminService] Exceção ao remover experiência de voluntário: $e');
      return false;
    }
  }
}
