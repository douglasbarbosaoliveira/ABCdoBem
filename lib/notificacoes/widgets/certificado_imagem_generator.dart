// lib/notificacoes/widgets/certificado_imagem_generator.dart

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../services/session_service.dart';

class CertificadoImagemResult {
  final XFile imagemPng;
  final String textoSugerido;
  final String tituloEvento;

  const CertificadoImagemResult({
    required this.imagemPng,
    required this.textoSugerido,
    required this.tituloEvento,
  });
}

class CertificadoImagemGenerator {
  static const String _baseUrl = "https://abc-do-bem.onrender.com";

  static Future<CertificadoImagemResult?> gerarPngDoCertificado(
    BuildContext context, {
    required String applicationId,
    String? mensagemFallback,
  }) async {
    final appId = applicationId.trim();
    if (appId.isEmpty) return null;

    String voluntario =
        SessionService.instance.nomeUsuario?.trim().isNotEmpty == true
            ? SessionService.instance.nomeUsuario!.trim()
            : "Voluntário(a)";
    String evento = "Ação Solidária";
    String instituicao = "ABC do Bem";
    String dataStr = "";
    int horas = 0;
    String codigo = appId.toUpperCase();

    try {
      final res = await http
          .get(Uri.parse("$_baseUrl/certificates/verify/$appId"))
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        if (data is Map<String, dynamic> && data['valid'] == true) {
          voluntario = (data['voluntario'] ?? voluntario).toString();
          evento = (data['evento'] ?? evento).toString();
          instituicao = (data['instituicao'] ?? instituicao).toString();
          codigo = (data['codigoValidacao'] ?? codigo).toString();
          horas = (data['cargaHoraria'] as num?)?.toInt() ?? 0;

          final rawDate = data['dataRealizacao']?.toString() ?? '';
          final parsed = DateTime.tryParse(rawDate);
          if (parsed != null) {
            final d = parsed.day.toString().padLeft(2, '0');
            final m = parsed.month.toString().padLeft(2, '0');
            dataStr = "$d/$m/${parsed.year}";
          }
        }
      }
    } catch (_) {
      if (mensagemFallback != null && mensagemFallback.contains('"')) {
        final partes = mensagemFallback.split('"');
        if (partes.length >= 2) evento = partes[1];
      }
    }

    try {
      final Uint8List? pngBytes = await _renderizarCertificadoPng(
        voluntario: voluntario,
        evento: evento,
        instituicao: instituicao,
        horas: horas,
        dataStr: dataStr,
        codigo: codigo,
      );
      if (pngBytes == null || pngBytes.isEmpty) return null;

      final xfile = XFile.fromData(
        pngBytes,
        name: "certificado-${appId.toLowerCase()}.png",
        mimeType: "image/png",
      );

      final textoHoras =
          horas > 0 ? " ($horas hora${horas > 1 ? 's' : ''})" : "";
      final sugestao =
          'Concluí minha participação na ação "$evento"$textoHoras pela $instituicao! Muito feliz em contribuir com a comunidade pelo ABC do Bem.';

      return CertificadoImagemResult(
        imagemPng: xfile,
        textoSugerido: sugestao,
        tituloEvento: evento,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List?> _renderizarCertificadoPng({
    required String voluntario,
    required String evento,
    required String instituicao,
    required int horas,
    required String dataStr,
    required String codigo,
  }) async {
    const double width = 800;
    const double height = 500;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));

    // Fundo gradiente
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(width, height),
        const [Color(0xFF062222), Color(0xFF0C6B6B)],
      );
    canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), bgPaint);

    // Cartão interno branco com borda dourada
    final cardRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(28, 28, width - 56, height - 56),
      const Radius.circular(18),
    );
    canvas.drawRRect(cardRect, Paint()..color = const Color(0xFFFAFFFE));
    canvas.drawRRect(
      cardRect,
      Paint()
        ..color = const Color(0xFFD48806)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    void drawCenteredText(
      String text, {
      required double y,
      required double fontSize,
      required FontWeight weight,
      required Color color,
      double maxWidth = width - 120,
      double? letterSpacing,
    }) {
      final builder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          textAlign: TextAlign.center,
          maxLines: 2,
          ellipsis: '...',
        ),
      )..pushStyle(
          ui.TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: weight,
            letterSpacing: letterSpacing,
          ),
        );
      builder.addText(text);
      final paragraph = builder.build()
        ..layout(ui.ParagraphConstraints(width: maxWidth));
      canvas.drawParagraph(paragraph, Offset((width - maxWidth) / 2, y));
    }

    drawCenteredText(
      "ABC do Bem  •  CERTIFICADO DE VOLUNTARIADO",
      y: 56,
      fontSize: 13,
      weight: FontWeight.w700,
      color: const Color(0xFFD48806),
      letterSpacing: 1.0,
    );

    drawCenteredText(
      "Certificamos que",
      y: 105,
      fontSize: 15,
      weight: FontWeight.w500,
      color: const Color(0xFF4C7A70),
    );

    drawCenteredText(
      voluntario.toUpperCase(),
      y: 134,
      fontSize: 30,
      weight: FontWeight.w800,
      color: const Color(0xFF062222),
      letterSpacing: 0.8,
    );

    canvas.drawLine(
      const Offset(230, 205),
      const Offset(570, 205),
      Paint()
        ..color = const Color(0xFF0C6B6B).withValues(alpha: 0.35)
        ..strokeWidth = 2,
    );

    drawCenteredText(
      "participou como voluntário(a) da ação solidária",
      y: 220,
      fontSize: 15,
      weight: FontWeight.w400,
      color: const Color(0xFF455A64),
    );

    drawCenteredText(
      '"$evento"',
      y: 252,
      fontSize: 22,
      weight: FontWeight.w700,
      color: const Color(0xFF0C6B6B),
    );

    final detalhes = [
      if (horas > 0) "Carga horária: ${horas}h",
      if (dataStr.isNotEmpty) "Realizado em $dataStr",
    ].join("  •  ");

    if (detalhes.isNotEmpty) {
      drawCenteredText(
        detalhes,
        y: 300,
        fontSize: 14,
        weight: FontWeight.w600,
        color: const Color(0xFF3A6868),
      );
    }

    void drawLeftText(
        String text, double y, double size, FontWeight w, Color c) {
      final b =
          ui.ParagraphBuilder(ui.ParagraphStyle(maxLines: 1, ellipsis: '...'))
            ..pushStyle(ui.TextStyle(color: c, fontSize: size, fontWeight: w));
      b.addText(text);
      final p = b.build()..layout(const ui.ParagraphConstraints(width: 320));
      canvas.drawParagraph(p, Offset(64, y));
    }

    void drawRightText(
        String text, double y, double size, FontWeight w, Color c) {
      final b = ui.ParagraphBuilder(
        ui.ParagraphStyle(
            textAlign: TextAlign.right, maxLines: 1, ellipsis: '...'),
      )..pushStyle(ui.TextStyle(color: c, fontSize: size, fontWeight: w));
      b.addText(text);
      final p = b.build()..layout(const ui.ParagraphConstraints(width: 320));
      canvas.drawParagraph(p, Offset(width - 64 - 320, y));
    }

    drawLeftText(
        "Organização Responsável", 386, 11, FontWeight.w400, Colors.grey);
    drawLeftText(
        instituicao, 404, 15, FontWeight.w700, const Color(0xFF062222));

    drawRightText(
        "Código de Autenticidade", 386, 11, FontWeight.w400, Colors.grey);
    drawRightText(codigo, 404, 12, FontWeight.w700, const Color(0xFF4C7A70));

    final picture = recorder.endRecording();
    final ui.Image img = await picture.toImage(width.toInt(), height.toInt());
    picture.dispose();

    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();

    return byteData?.buffer.asUint8List();
  }
}