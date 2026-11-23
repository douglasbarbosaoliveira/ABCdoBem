// lib/services/session_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  static const String baseUrl = "https://abc-do-bem.onrender.com";

  String? token;
  String? usuarioId;
  String? nomeUsuario;
  String? email;
  String? role;

  String? fotoUrl;
  String? bio;
  String? cidade;
  String? estado;
  String? telefone;
  String? whatsapp;
  List<String> habilidades = [];
  List<String> disponibilidade = [];
  Map<String, dynamic>? dadosCompletosUsuario;

  final ValueNotifier<String?> fotoUrlNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<int> sessaoAtualizadaNotifier = ValueNotifier<int>(0);

  bool get estaAutenticado =>
      token != null && token!.trim().isNotEmpty && usuarioId != null;

  /// Extrai o `sub` (userId) direto do payload do JWT caso `usuarioId` não tenha sido passado
  String? _extrairIdDoJwt(String jwtToken) {
    try {
      final parts = jwtToken.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final payloadStr = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(payloadStr);
      if (payload is Map) {
        return (payload['sub'] ?? payload['id'] ?? payload['userId'])
            ?.toString();
      }
    } catch (_) {}
    return null;
  }

  void salvarSessao({
    required String novoToken,
    required String novoUsuarioId,
    required String novoNome,
    String? novoEmail,
    String? novoRole,
    String? novaFotoUrl,
  }) {
    token = novoToken.trim();
    final idLimpo = novoUsuarioId.trim();
    usuarioId = idLimpo.isNotEmpty ? idLimpo : _extrairIdDoJwt(token!);
    nomeUsuario = novoNome.trim();
    email = novoEmail?.trim();
    role = novoRole?.trim() ?? "USER";

    if (novaFotoUrl != null && novaFotoUrl.trim().isNotEmpty) {
      final fStr = novaFotoUrl.trim();
      if (fStr.startsWith('http') || fStr.startsWith('data:image')) {
        fotoUrl = fStr;
      } else {
        fotoUrl = 'data:image/jpeg;base64,$fStr';
      }
    } else {
      fotoUrl = null;
    }

    fotoUrlNotifier.value = fotoUrl;
    sessaoAtualizadaNotifier.value++;
  }

  /// Sincroniza os dados cadastrais completos usando GET /users/{id} (e /users/dashboard/me como fallback)
  Future<void> carregarDadosCompletosUsuario() async {
    final tok = token?.trim();
    if ((usuarioId == null || usuarioId!.trim().isEmpty) &&
        tok != null &&
        tok.isNotEmpty) {
      usuarioId = _extrairIdDoJwt(tok);
    }

    final uid = usuarioId?.trim();
    if (uid == null || uid.isEmpty) return;

    final url = Uri.parse("$baseUrl/users/$uid");

    try {
      final response = await http.get(
        url,
        headers: {
          "Accept": "application/json",
          if (tok != null && tok.isNotEmpty) "Authorization": "Bearer $tok",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded =
            jsonDecode(utf8.decode(response.bodyBytes));
        final Map<String, dynamic> data = decoded['user'] is Map
            ? Map<String, dynamic>.from(decoded['user'])
            : decoded;

        dadosCompletosUsuario = Map<String, dynamic>.from(data);

        usuarioId = (data['id'] ?? data['userId'] ?? uid).toString().trim();
        nomeUsuario = data['name'] ?? data['razaoSocial'] ?? nomeUsuario;
        email = data['email'] ?? email;
        role = data['role'] ?? role;

        final rawAvatar = data['avatar'] ?? data['fotoUrl'] ?? data['logoUrl'];
        if (rawAvatar != null && rawAvatar.toString().trim().isNotEmpty) {
          final String avatarStr = rawAvatar.toString().trim();
          if (avatarStr.startsWith('http') ||
              avatarStr.startsWith('data:image')) {
            fotoUrl = avatarStr;
          } else {
            fotoUrl = 'data:image/jpeg;base64,$avatarStr';
          }
        }

        bio = data['bio'] ?? bio;
        cidade = data['cidade'] ?? cidade;
        estado = data['estado'] ?? estado;
        telefone = data['telefone'] ?? telefone;
        whatsapp = data['whatsapp'] ?? whatsapp;

        if (data['habilidades'] is List) {
          habilidades = List<String>.from(data['habilidades']);
        }
        if (data['disponibilidade'] is List) {
          disponibilidade = List<String>.from(data['disponibilidade']);
        }

        fotoUrlNotifier.value = fotoUrl;
        sessaoAtualizadaNotifier.value++;
      }
    } catch (e) {
      debugPrint(">>> SessionService: Erro na sincronização: $e");
    }
  }

  void atualizarFotoUrl(String? novaFoto) {
    if (novaFoto != null && novaFoto.trim().isNotEmpty) {
      final fStr = novaFoto.trim();
      if (fStr.startsWith('http') || fStr.startsWith('data:image')) {
        fotoUrl = fStr;
      } else {
        fotoUrl = 'data:image/jpeg;base64,$fStr';
      }
    } else {
      fotoUrl = null;
    }
    fotoUrlNotifier.value = fotoUrl;
    sessaoAtualizadaNotifier.value++;
  }

  void atualizarDadosCadastrais({
    String? novoNome,
    String? novaBio,
    String? novaCidade,
    String? novoEstado,
    String? novoWhatsapp,
    List<String>? novasHabilidades,
    List<String>? novaDisponibilidade,
  }) {
    if (novoNome != null) nomeUsuario = novoNome;
    if (novaBio != null) bio = novaBio;
    if (novaCidade != null) cidade = novaCidade;
    if (novoEstado != null) estado = novoEstado;
    if (novoWhatsapp != null) whatsapp = novoWhatsapp;
    if (novasHabilidades != null) habilidades = novasHabilidades;
    if (novaDisponibilidade != null) disponibilidade = novaDisponibilidade;

    sessaoAtualizadaNotifier.value++;
  }

  void limpar() {
    token = null;
    usuarioId = null;
    nomeUsuario = null;
    email = null;
    role = null;
    fotoUrl = null;
    bio = null;
    cidade = null;
    estado = null;
    telefone = null;
    whatsapp = null;
    habilidades.clear();
    disponibilidade.clear();

    dadosCompletosUsuario = null;
    fotoUrlNotifier.value = null;
    sessaoAtualizadaNotifier.value++;
  }

  void limparSessao() => limpar();
}
