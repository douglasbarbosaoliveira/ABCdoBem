// lib/voluntarios/perfil/widgets/perfil_redes_sociais_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_social_button/flutter_social_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'perfil_info_card.dart';

class PerfilRedesSociaisCard extends StatelessWidget {
  final String? instagram;
  final String? facebook;
  final String? linkedin;
  final String? tiktok;
  final String? site;
  final String? whatsapp;

  const PerfilRedesSociaisCard({
    super.key,
    this.instagram,
    this.facebook,
    this.linkedin,
    this.tiktok,
    this.site,
    this.whatsapp,
  });

  bool _valido(String? s) {
    if (s == null) return false;
    final t = s.trim();
    return t.isNotEmpty && t != 'null' && t != '(11) 99999-9999';
  }

  bool get _temAlgumaRede =>
      _valido(instagram) ||
      _valido(facebook) ||
      _valido(linkedin) ||
      _valido(tiktok) ||
      _valido(site) ||
      _valido(whatsapp);

  Future<void> _abrirLink(BuildContext context, String urlFinal) async {
    final uri = Uri.tryParse(urlFinal);
    if (uri != null) {
      final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!abriu && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Não foi possível abrir o link no momento."),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatarWhatsappUrl(String raw) {
    final limpo = raw.trim();
    if (limpo.startsWith('http://') || limpo.startsWith('https://')) {
      return limpo;
    }
    final buffer = StringBuffer();
    for (int i = 0; i < limpo.length; i++) {
      final code = limpo.codeUnitAt(i);
      if (code >= 48 && code <= 57) buffer.writeCharCode(code);
    }
    var digitos = buffer.toString();
    if (digitos.length == 10 || digitos.length == 11) {
      digitos = '55$digitos';
    }
    return 'https://wa.me/$digitos';
  }

  String _formatarSocialUrl(String raw, String dominioBase) {
    final limpo = raw.trim();
    if (limpo.startsWith('http://') || limpo.startsWith('https://')) {
      return limpo;
    }
    final handle = limpo.startsWith('@') ? limpo.substring(1) : limpo;
    if (handle.contains('.com') || handle.contains('/')) {
      return 'https://$handle';
    }
    return 'https://$dominioBase/$handle';
  }

  @override
  Widget build(BuildContext context) {
    if (!_temAlgumaRede) {
      return const SizedBox.shrink();
    }

    return PerfilInfoCard(
      titulo: "Redes Sociais e Contato",
      conteudo: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          if (_valido(whatsapp))
            _buildRedeButton(
              context,
              icon: FontAwesomeIcons.whatsapp,
              label: whatsapp!.trim(),
              url: _formatarWhatsappUrl(whatsapp!),
            ),
          if (_valido(instagram))
            _buildRedeButton(
              context,
              icon: FontAwesomeIcons.instagram,
              label: instagram!.trim(),
              url: _formatarSocialUrl(instagram!, 'instagram.com'),
            ),
          if (_valido(linkedin))
            _buildRedeButton(
              context,
              icon: FontAwesomeIcons.linkedin,
              label: linkedin!.trim(),
              url: _formatarSocialUrl(linkedin!, 'linkedin.com/in'),
            ),
          if (_valido(facebook))
            _buildRedeButton(
              context,
              icon: FontAwesomeIcons.facebook,
              label: facebook!.trim(),
              url: _formatarSocialUrl(facebook!, 'facebook.com'),
            ),
          if (_valido(tiktok))
            _buildRedeButton(
              context,
              icon: FontAwesomeIcons.tiktok,
              label: tiktok!.trim(),
              url: _formatarSocialUrl(
                tiktok!.trim().startsWith('@')
                    ? tiktok!.trim()
                    : '@${tiktok!.trim()}',
                'tiktok.com',
              ),
            ),
          if (_valido(site))
            _buildRedeButton(
              context,
              icon: FontAwesomeIcons.globe,
              label: site!.trim(),
              url: site!.trim().startsWith('http')
                  ? site!.trim()
                  : 'https://${site!.trim()}',
            ),
        ],
      ),
    );
  }

  Widget _buildRedeButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String url,
  }) {
    return InkWell(
      onTap: () => _abrirLink(context, url),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FAF7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFC2E4DC)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, size: 14, color: const Color(0xFF0C6B6B)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C6B6B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
