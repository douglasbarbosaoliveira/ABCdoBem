// lib/widgets/avatar/app_avatar.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  final String? fotoUrl;
  final File? fotoArquivo;
  final String nome;
  final double raio;
  final double tamanhoFonte;
  final double bordaRaio;
  final bool circular;

  const AppAvatar({
    super.key,
    this.fotoUrl,
    this.fotoArquivo,
    required this.nome,
    this.raio = 18,
    this.tamanhoFonte = 12,
    this.bordaRaio = 14,
    this.circular = true,
  });

  String _extrairIniciais(String texto) {
    if (texto.trim().isEmpty) return "U";
    final partes = texto.trim().split(RegExp(r'\s+'));
    if (partes.length == 1) return partes[0][0].toUpperCase();
    return "${partes.first[0]}${partes.last[0]}".toUpperCase();
  }

  bool _isUrlValida(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final lower = url.trim().toLowerCase();
    return lower.startsWith("http://") || lower.startsWith("https://");
  }

  Uint8List? _decodificarBase64(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final trimmed = raw.trim();
    if (_isUrlValida(trimmed)) return null;

    try {
      final String base64Puro = trimmed.contains(',')
          ? trimmed.substring(trimmed.indexOf(',') + 1)
          : trimmed;

      String limpo = base64Puro.replaceAll(RegExp(r'\s+'), '');
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
    final double tamanho = raio * 2;
    final bool temArquivo = fotoArquivo != null;
    final bool temUrl = _isUrlValida(fotoUrl);
    final Uint8List? bytesMemoria =
        (!temArquivo && !temUrl) ? _decodificarBase64(fotoUrl) : null;

    Widget conteudoInterno;

    if (temArquivo) {
      conteudoInterno = Image.file(
        fotoArquivo!,
        fit: BoxFit.cover,
        width: tamanho,
        height: tamanho,
      );
    } else if (temUrl) {
      conteudoInterno = Image.network(
        fotoUrl!.trim(),
        fit: BoxFit.cover,
        width: tamanho,
        height: tamanho,
        errorBuilder: (_, __, ___) => _buildFallbackIniciais(),
      );
    } else if (bytesMemoria != null) {
      conteudoInterno = Image.memory(
        bytesMemoria,
        fit: BoxFit.cover,
        width: tamanho,
        height: tamanho,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _buildFallbackIniciais(),
      );
    } else {
      conteudoInterno = _buildFallbackIniciais();
    }

    if (circular) {
      return ClipOval(
        child: SizedBox(
          width: tamanho,
          height: tamanho,
          child: conteudoInterno,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(bordaRaio),
      child: SizedBox(width: tamanho, height: tamanho, child: conteudoInterno),
    );
  }

  Widget _buildFallbackIniciais() {
    return Container(
      color: const Color(0xFFD1F5EE),
      alignment: Alignment.center,
      child: Text(
        _extrairIniciais(nome),
        style: TextStyle(
          fontSize: tamanhoFonte,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0C6B6B),
          fontFamily: 'Quicksand',
        ),
      ),
    );
  }
}
