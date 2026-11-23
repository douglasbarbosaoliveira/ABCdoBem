// lib/voluntarios/home/widgets/evento_capa_widget.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class EventoCapaWidget extends StatelessWidget {
  final String rawUrl;
  final double altura;
  final double? largura;

  const EventoCapaWidget({
    super.key,
    required this.rawUrl,
    required this.altura,
    this.largura,
  });

  String _extrairPrimeiraImagemValida(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('[')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded.first.toString().trim();
        }
      } catch (_) {}
    }
    return trimmed;
  }

  Uint8List? _decodificarBase64(String src) {
    if (src.isEmpty ||
        src.toLowerCase().startsWith('http://') ||
        src.toLowerCase().startsWith('https://')) {
      return null;
    }
    try {
      final base64Puro =
          src.contains(',') ? src.substring(src.indexOf(',') + 1) : src;
      var limpo = base64Puro
          .replaceAll(' ', '')
          .replaceAll('\n', '')
          .replaceAll('\r', '')
          .replaceAll('\t', '');
      while (limpo.length % 4 != 0) {
        limpo += '=';
      }
      if (limpo.length < 32) return null;
      return base64Decode(limpo);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      height: altura,
      width: largura ?? double.infinity,
      color: const Color(0xFFC2E4DC),
      child: const Center(
        child: Icon(
          Icons.volunteer_activism_rounded,
          size: 32,
          color: Color(0xFF0C6B6B),
        ),
      ),
    );

    final src = _extrairPrimeiraImagemValida(rawUrl);
    if (src.isEmpty) return placeholder;

    if (src.toLowerCase().startsWith('http://') ||
        src.toLowerCase().startsWith('https://')) {
      return Image.network(
        src,
        height: altura,
        width: largura ?? double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }

    final bytes = _decodificarBase64(src);
    if (bytes != null) {
      return Image.memory(
        bytes,
        height: altura,
        width: largura ?? double.infinity,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }

    return placeholder;
  }
}
