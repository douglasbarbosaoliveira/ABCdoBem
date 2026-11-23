// lib/utils/social_share_helper.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialShareHelper {
  static const String _plataformaUrl = 'https://abc-do-bem.onrender.com';

  /// Monta a mensagem padrão com formatação para redes sociais
  static String formatarMensagem({
    required String texto,
    required String origem,
  }) {
    return '✨ Participei de uma ação voluntária incrível no ABC do Bem!\n\n'
        '🤝 Iniciativa: $origem\n'
        '💬 Relato: "$texto"\n\n'
        'Junte-se a nós e transforme a nossa comunidade:\n'
        '🔗 $_plataformaUrl';
  }

  /// 1. Compartilhamento Nativo do Sistema (Android, iOS e Web)
  static Future<void> compartilharNativo({
    required String texto,
    required String origem,
  }) async {
    final mensagem = formatarMensagem(texto: texto, origem: origem);
    await Share.share(
      mensagem,
      subject: 'Minha experiência de voluntariado no ABC do Bem',
    );
  }

  /// 2. Compartilhar diretamente no WhatsApp
  static Future<bool> compartilharWhatsApp({
    required String texto,
    required String origem,
  }) async {
    final mensagem = formatarMensagem(texto: texto, origem: origem);
    final url =
        Uri.parse('https://wa.me/?text=${Uri.encodeComponent(mensagem)}');

    try {
      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Erro ao abrir WhatsApp: $e');
    }
    return false;
  }

  /// 3. Compartilhar no LinkedIn
  static Future<bool> compartilharLinkedIn({
    required String texto,
    required String origem,
  }) async {
    // LinkedIn prioriza URL para gerar o card de pré-visualização
    final url = Uri.parse(
      'https://www.linkedin.com/sharing/share-offsite/?url=${Uri.encodeComponent(_plataformaUrl)}',
    );

    try {
      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Erro ao abrir LinkedIn: $e');
    }
    return false;
  }

  /// 4. Compartilhar no X (Twitter)
  static Future<bool> compartilharTwitter({
    required String texto,
    required String origem,
  }) async {
    // Reduz o texto se for muito longo para respeitar limites do post
    final textoResumido =
        texto.length > 140 ? '${texto.substring(0, 137)}...' : texto;
    final tweet =
        'Participei da ação "$origem" no ABC do Bem! "$textoResumido"';

    final url = Uri.parse(
      'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(tweet)}&url=${Uri.encodeComponent(_plataformaUrl)}&hashtags=ABCdoBem,Voluntariado',
    );

    try {
      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Erro ao abrir X/Twitter: $e');
    }
    return false;
  }

  /// 5. Copiar texto formatado para a Área de Transferência
  static Future<void> copiarParaAreaTransferencia(
    BuildContext context, {
    required String texto,
    required String origem,
  }) async {
    final mensagem = formatarMensagem(texto: texto, origem: origem);
    await Clipboard.setData(ClipboardData(text: mensagem));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Texto copiado para a área de transferência!'),
          backgroundColor: Color(0xFF0C6B6B),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
