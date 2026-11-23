// lib/services/gerador_capa_evento_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class GeradorCapaEventoService {
  static const String _baseUrl = "https://abc-do-bem.onrender.com";
  static const String _rotaGeracaoCapa = "/events/generate-cover";

  /// Monta o prompt em inglês a partir do título e das causas do evento,
  /// reforçando ausência de texto/tipografia e enquadramento de banner.
  String construirPromptSemTexto({
    required String tituloEvento,
    required List<String> categorias,
  }) {
    final tituloLimpo = tituloEvento.trim();
    final causasLimpa =
        categorias.map((c) => c.trim()).where((c) => c.isNotEmpty).join(", ");

    final assunto = [
      if (tituloLimpo.isNotEmpty) "event theme: $tituloLimpo",
      if (causasLimpa.isNotEmpty) "social cause: $causasLimpa",
    ].join(", ");

    return [
      "Clean editorial banner illustration for a community volunteering initiative",
      if (assunto.isNotEmpty) "representing $assunto",
      "warm inviting atmosphere, emerald green and teal accents, balanced composition for horizontal card banner",
      "strictly no text, no letters, no words, no numbers, no typography, no logos, no watermarks",
    ].join(". ");
  }

  /// Envia prompt e dimensões padrão (16:9) para o backend.
  /// Retorna uma URL (https://...) ou data URI (data:image/...;base64,...).
  Future<String?> gerarCapaEvento({
    required String tituloEvento,
    required List<String> categorias,
    String? token,
  }) async {
    final prompt = construirPromptSemTexto(
      tituloEvento: tituloEvento,
      categorias: categorias,
    );

    final uri = Uri.parse("$_baseUrl$_rotaGeracaoCapa");

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        if (token != null && token.trim().isNotEmpty)
          "Authorization": "Bearer ${token.trim()}",
      },
      body: jsonEncode({
        "prompt": prompt,
        "title": tituloEvento.trim(),
        "categories": categorias,
        "aspectRatio": "16:9",
        "width": 1280,
        "height": 720,
        "noText": true,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        "Falha ao gerar imagem no servidor (HTTP ${response.statusCode}).",
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final url =
          (decoded["imageUrl"] ?? decoded["url"] ?? "").toString().trim();
      if (url.isNotEmpty) return url;

      final base64Raw =
          (decoded["imageBase64"] ?? decoded["base64"] ?? "").toString().trim();
      if (base64Raw.isNotEmpty) {
        return base64Raw.startsWith("data:image")
            ? base64Raw
            : "data:image/png;base64,$base64Raw";
      }
    }

    return null;
  }
}
