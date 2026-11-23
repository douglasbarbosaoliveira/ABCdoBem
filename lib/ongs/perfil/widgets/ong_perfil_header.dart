// lib/ongs/perfil/widgets/ong_perfil_header.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_social_button/flutter_social_button.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/ong_detail_models.dart';

class OngPerfilHeader extends StatelessWidget {
  final OngDetalheModel ong;
  final bool isOng;
  final bool isMobile;
  final bool alternandoSeguir;
  final VoidCallback onToggleSeguir;
  final VoidCallback onConversar;
  final VoidCallback onEditarDados;
  final VoidCallback onCriarEvento;

  const OngPerfilHeader({
    super.key,
    required this.ong,
    required this.isOng,
    required this.isMobile,
    this.alternandoSeguir = false,
    required this.onToggleSeguir,
    required this.onConversar,
    required this.onEditarDados,
    required this.onCriarEvento,
  });

  String _sanitizarImagemUrl(String rawUrl) {
    final String url = rawUrl.trim();
    if (url.isEmpty ||
        url == "null" ||
        url.contains("default.png") ||
        url.contains("placeholder") ||
        url.contains("storage.xyz") ||
        url.contains("example.com")) {
      return "";
    }
    if (url.startsWith("data:image")) return url;
    if (!url.startsWith("http://") &&
        !url.startsWith("https://") &&
        !url.startsWith("/")) {
      if (url.length > 20 && !url.contains(" ") && !url.contains("/")) {
        return "data:image/jpeg;base64,$url";
      }
    }
    if (url.startsWith("http://") || url.startsWith("https://")) return url;
    if (url.startsWith("/")) return "https://abc-do-bem.onrender.com$url";
    return "https://abc-do-bem.onrender.com/$url";
  }

  String _resolverBannerPorCategoria() {
    final cat = ong.categoria.toLowerCase().trim();

    if (cat.contains('gestão') ||
        cat.contains('administração') ||
        cat.contains('projeto') ||
        cat.contains('liderança') ||
        cat.contains('finanças') ||
        cat.contains('cidadania') ||
        cat.contains('direitos')) {
      return "assets/images/banners/banner_gestao.jpg";
    }

    if (cat.contains('educação') ||
        cat.contains('ensino') ||
        cat.contains('aula') ||
        cat.contains('idioma') ||
        cat.contains('mentoria') ||
        cat.contains('capacitação') ||
        cat.contains('inclusão')) {
      return "assets/images/banners/banner_educacao.jpg";
    }

    if (cat.contains('saúde') ||
        cat.contains('enfermagem') ||
        cat.contains('psicologia') ||
        cat.contains('nutrição') ||
        cat.contains('socorros') ||
        cat.contains('idoso') ||
        cat.contains('deficiência') ||
        cat.contains('apae') ||
        cat.contains('bem-estar')) {
      return "assets/images/banners/banner_saude.jpg";
    }

    if (cat.contains('tecnologia') ||
        cat.contains('programação') ||
        cat.contains('design') ||
        cat.contains('comunicação') ||
        cat.contains('marketing') ||
        cat.contains('mídia') ||
        cat.contains('digital')) {
      return "assets/images/banners/banner_tecnologia.jpg";
    }

    if (cat.contains('ambiente') ||
        cat.contains('horta') ||
        cat.contains('animal') ||
        cat.contains('sustentabilidade') ||
        cat.contains('reciclagem') ||
        cat.contains('ecologia')) {
      return "assets/images/banners/banner_meio_ambiente.jpg";
    }

    if (cat.contains('cozinha') ||
        cat.contains('alimento') ||
        cat.contains('fome') ||
        cat.contains('segurança alimentar') ||
        cat.contains('logística') ||
        cat.contains('assistência') ||
        cat.contains('social') ||
        cat.contains('doação')) {
      return "assets/images/banners/banner_logistica.jpg";
    }

    if (cat.contains('arte') ||
        cat.contains('música') ||
        cat.contains('esporte') ||
        cat.contains('cultura') ||
        cat.contains('recreação') ||
        cat.contains('lazer')) {
      return "assets/images/banners/banner_cultura.jpg";
    }

    return "assets/images/sou_voluntario.jpg";
  }

  Widget _buildBannerTematico() {
    final String assetPath = _resolverBannerPorCategoria();
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(
        "assets/images/sou_voluntario.jpg",
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _bannerFallback(),
      ),
    );
  }

  Widget _buildAvatarOng(double radius) {
    final double diameter = radius * 2;
    final String url = _sanitizarImagemUrl(ong.logoUrl);

    Widget fallback() {
      return Container(
        width: diameter,
        height: diameter,
        color: const Color(0xFFD1F5EE),
        child: Icon(
          Icons.business_rounded,
          color: const Color(0xFF0C6B6B),
          size: radius * 0.85,
        ),
      );
    }

    if (url.isEmpty) {
      return fallback();
    }

    if (url.startsWith("data:image")) {
      try {
        final Uint8List bytes = base64Decode(url.split(',').last);
        return Image.memory(
          bytes,
          width: diameter,
          height: diameter,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback(),
        );
      } catch (_) {
        return fallback();
      }
    }

    return Image.network(
      url,
      width: diameter,
      height: diameter,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback(),
    );
  }

  Future<void> _abrirLinkExterno(BuildContext context, String urlBruta) async {
    String urlFinal = urlBruta.trim();
    if (urlFinal.isEmpty) return;

    if (!urlFinal.startsWith('http://') &&
        !urlFinal.startsWith('https://') &&
        !urlFinal.startsWith('tel:')) {
      urlFinal = 'https://$urlFinal';
    }

    final Uri? uri = Uri.tryParse(urlFinal);
    if (uri != null) {
      final bool abriu = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
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
    final String limpo = raw.trim();
    if (limpo.startsWith('http://') || limpo.startsWith('https://')) {
      return limpo;
    }
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < limpo.length; i++) {
      final int code = limpo.codeUnitAt(i);
      if (code >= 48 && code <= 57) {
        buffer.writeCharCode(code);
      }
    }
    String digitos = buffer.toString();
    if (digitos.length == 10 || digitos.length == 11) {
      digitos = '55$digitos';
    }
    return 'https://wa.me/$digitos';
  }

  String _formatarSocialUrl(String raw, String dominioBase) {
    final String limpo = raw.trim();
    if (limpo.startsWith('http://') || limpo.startsWith('https://')) {
      return limpo;
    }
    final String handle = limpo.startsWith('@') ? limpo.substring(1) : limpo;
    if (handle.contains('.com') || handle.contains('/')) {
      return 'https://$handle';
    }
    return 'https://$dominioBase/$handle';
  }

  @override
  Widget build(BuildContext context) {
    final double bannerHeight = isMobile ? 85 : 110;
    final double avatarRadius = isMobile ? 34 : 40;
    final String bannerLimpo = _sanitizarImagemUrl(ong.bannerUrl);

    final bool temWhatsapp =
        ong.whatsapp != null && ong.whatsapp!.trim().isNotEmpty;
    final bool temInstagram =
        ong.instagram != null && ong.instagram!.trim().isNotEmpty;
    final bool temLinkedin =
        ong.linkedin != null && ong.linkedin!.trim().isNotEmpty;
    final bool temFacebook =
        ong.facebook != null && ong.facebook!.trim().isNotEmpty;
    final bool temTiktok = ong.tiktok != null && ong.tiktok!.trim().isNotEmpty;
    final bool temSite = ong.site != null && ong.site!.trim().isNotEmpty;

    final List<Widget> botoesSociais = <Widget>[
      if (temWhatsapp)
        _buildSocialSquareButton(
          tooltip: "WhatsApp",
          icon: FontAwesomeIcons.whatsapp,
          corIcone: const Color(0xFF1B8A4B),
          corFundo: const Color(0xFFE6F7ED),
          corBorda: const Color(0xFFB7E4C7),
          onTap: () => _abrirLinkExterno(
            context,
            _formatarWhatsappUrl(ong.whatsapp!),
          ),
        ),
      if (temInstagram)
        _buildSocialSquareButton(
          tooltip: "Instagram",
          icon: FontAwesomeIcons.instagram,
          corIcone: const Color(0xFFC13584),
          corFundo: const Color(0xFFFCEEF5),
          corBorda: const Color(0xFFF5C2DC),
          onTap: () => _abrirLinkExterno(
            context,
            _formatarSocialUrl(ong.instagram!, 'instagram.com'),
          ),
        ),
      if (temLinkedin)
        _buildSocialSquareButton(
          tooltip: "LinkedIn",
          icon: FontAwesomeIcons.linkedinIn,
          corIcone: const Color(0xFF0A66C2),
          corFundo: const Color(0xFFEAF3FC),
          corBorda: const Color(0xFFBDD8F5),
          onTap: () => _abrirLinkExterno(
            context,
            _formatarSocialUrl(ong.linkedin!, 'linkedin.com/company'),
          ),
        ),
      if (temFacebook)
        _buildSocialSquareButton(
          tooltip: "Facebook",
          icon: FontAwesomeIcons.facebookF,
          corIcone: const Color(0xFF1877F2),
          corFundo: const Color(0xFFEBF3FE),
          corBorda: const Color(0xFFBDD6FA),
          onTap: () => _abrirLinkExterno(
            context,
            _formatarSocialUrl(ong.facebook!, 'facebook.com'),
          ),
        ),
      if (temTiktok)
        _buildSocialSquareButton(
          tooltip: "TikTok",
          icon: FontAwesomeIcons.tiktok,
          corIcone: const Color(0xFF111111),
          corFundo: const Color(0xFFF2F4F4),
          corBorda: const Color(0xFFD5D8DC),
          onTap: () => _abrirLinkExterno(
            context,
            _formatarSocialUrl(
              ong.tiktok!.startsWith('@') ? ong.tiktok! : '@${ong.tiktok!}',
              'tiktok.com',
            ),
          ),
        ),
      if (temSite)
        _buildSocialSquareButton(
          tooltip: "Site Oficial",
          icon: FontAwesomeIcons.globe,
          corIcone: const Color(0xFF0C6B6B),
          corFundo: const Color(0xFFD1F5EE),
          corBorda: const Color(0xFFA3E4D7),
          onTap: () => _abrirLinkExterno(context, ong.site!),
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF3FAF8),
            Color(0xFFFFFFFF),
          ],
          stops: [0.0, 0.35],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA8D8CE), width: 1.15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF062222).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Faixa Superior Compacta + Avatar
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                height: bannerHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (bannerLimpo.isNotEmpty)
                      bannerLimpo.startsWith("data:image")
                          ? Image.memory(
                              base64Decode(bannerLimpo.split(',').last),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildBannerTematico(),
                            )
                          : Image.network(
                              bannerLimpo,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildBannerTematico(),
                            )
                    else
                      _buildBannerTematico(),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF041A1A).withValues(alpha: 0.12),
                            const Color(0xFF041A1A).withValues(alpha: 0.25),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: isMobile ? 16 : 24,
                bottom: -avatarRadius,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFA8D8CE),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 7,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _buildAvatarOng(avatarRadius),
                  ),
                ),
              ),
            ],
          ),

          // 2. Espaço reservado para a metade inferior do Avatar
          SizedBox(height: avatarRadius + 8),

          // 3. Nome, Categoria, Localização, Botões na mesma linha e Redes Sociais abaixo
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 24,
              0,
              isMobile ? 16 : 24,
              isMobile ? 16 : 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ong.nome,
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF041A1A),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1F5EE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ong.categoria,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF095656),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: Color(0xFFE05252),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${ong.cidade}, ${ong.estado}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4C7A70),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Linha 1: Criar Evento e Editar Perfil na mesma linha
                if (isOng)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onCriarEvento,
                          icon: const Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Criar Evento",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF095656),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onEditarDados,
                          icon: const Icon(
                            Icons.edit_rounded,
                            size: 16,
                            color: Color(0xFF095656),
                          ),
                          label: const Text(
                            "Editar Perfil",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF095656),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF095656)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: onConversar,
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Conversar",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF095656),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                        ),
                      ),
                    ],
                  ),

                // Linha 2: Ícones de redes sociais e site dentro das caixinhas
                if (botoesSociais.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: botoesSociais,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSquareButton({
    required String tooltip,
    required IconData icon,
    required Color corIcone,
    required Color corFundo,
    required Color corBorda,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: corFundo,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: corBorda),
          ),
          alignment: Alignment.center,
          child: FaIcon(
            icon,
            size: 16,
            color: corIcone,
          ),
        ),
      ),
    );
  }

  Widget _bannerFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF095656),
            Color(0xFF0C6B6B),
          ],
        ),
      ),
    );
  }
}
