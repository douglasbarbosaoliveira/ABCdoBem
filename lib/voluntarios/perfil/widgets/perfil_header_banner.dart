// lib/voluntarios/perfil/widgets/perfil_header_banner.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/voluntario_profile_models.dart';
import '../editar_perfil_page.dart';
import '../../../../widgets/avatar/app_avatar.dart';

class PerfilHeaderBanner extends StatelessWidget {
  final VoluntarioPerfilModel perfil;
  final File? novaFotoPerfilArquivo;
  final VoidCallback onAlterarFoto;
  final VoidCallback onPerfilAtualizado;
  final bool isMobile;
  final bool isMeuPerfil;
  final VoidCallback? onConectarOuConvidar;
  final VoidCallback? onConversar;
  final String? token;

  const PerfilHeaderBanner({
    super.key,
    required this.perfil,
    this.novaFotoPerfilArquivo,
    required this.onAlterarFoto,
    required this.onPerfilAtualizado,
    required this.isMobile,
    required this.isMeuPerfil,
    this.onConectarOuConvidar,
    this.onConversar,
    this.token,
  });

  String _resolverBannerPorHabilidades() {
    if (perfil.habilidades.isEmpty) {
      return "assets/images/sou_voluntario.jpg";
    }

    final primeiraHabilidade = perfil.habilidades.first.toLowerCase();

    if (primeiraHabilidade.contains('gestão') ||
        primeiraHabilidade.contains('administração') ||
        primeiraHabilidade.contains('projeto') ||
        primeiraHabilidade.contains('liderança') ||
        primeiraHabilidade.contains('finanças')) {
      return "assets/images/banners/banner_gestao.jpg";
    }

    if (primeiraHabilidade.contains('educação') ||
        primeiraHabilidade.contains('ensino') ||
        primeiraHabilidade.contains('aula') ||
        primeiraHabilidade.contains('idioma') ||
        primeiraHabilidade.contains('fotografia')) {
      return "assets/images/banners/banner_educacao.jpg";
    }

    if (primeiraHabilidade.contains('saúde') ||
        primeiraHabilidade.contains('enfermagem') ||
        primeiraHabilidade.contains('psicologia') ||
        primeiraHabilidade.contains('nutrição') ||
        primeiraHabilidade.contains('socorros')) {
      return "assets/images/banners/banner_saude.jpg";
    }

    if (primeiraHabilidade.contains('tecnologia') ||
        primeiraHabilidade.contains('programação') ||
        primeiraHabilidade.contains('design') ||
        primeiraHabilidade.contains('comunicação') ||
        primeiraHabilidade.contains('marketing') ||
        primeiraHabilidade.contains('mídia')) {
      return "assets/images/banners/banner_tecnologia.jpg";
    }

    if (primeiraHabilidade.contains('ambiente') ||
        primeiraHabilidade.contains('horta') ||
        primeiraHabilidade.contains('animal') ||
        primeiraHabilidade.contains('sustentabilidade') ||
        primeiraHabilidade.contains('reciclagem')) {
      return "assets/images/banners/banner_meio_ambiente.jpg";
    }

    if (primeiraHabilidade.contains('cozinha') ||
        primeiraHabilidade.contains('alimento') ||
        primeiraHabilidade.contains('logística') ||
        primeiraHabilidade.contains('transporte') ||
        primeiraHabilidade.contains('organização')) {
      return "assets/images/banners/banner_logistica.jpg";
    }

    if (primeiraHabilidade.contains('arte') ||
        primeiraHabilidade.contains('música') ||
        primeiraHabilidade.contains('esporte') ||
        primeiraHabilidade.contains('cultura') ||
        primeiraHabilidade.contains('recreação')) {
      return "assets/images/banners/banner_cultura.jpg";
    }

    return "assets/images/banners/banner_cultura.jpg";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC2E4DC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08062222),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. FAIXA SUPERIOR COM O BANNER DINÂMICO BASEADO NAS HABILIDADES
          Container(
            height: isMobile ? 55 : 68,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(_resolverBannerPorHabilidades()),
                fit: BoxFit.cover,
                colorFilter: const ColorFilter.mode(
                  Color(
                      0x660C6B6B), // Máscara suave para destacar as cores vivas
                  BlendMode.srcATop,
                ),
              ),
            ),
          ),

          // 2. CORPO DO CARD COM AVATAR E NOME COMPLETO
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 12 : 16,
              0,
              isMobile ? 12 : 16,
              14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AVATAR EM DESTAQUE COM INICIAIS OU FOTO REAL
                    Transform.translate(
                      offset: Offset(0, isMobile ? -24 : -30),
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: AppAvatar(
                              fotoArquivo: novaFotoPerfilArquivo,
                              fotoUrl: perfil.fotoUrl,
                              nome: perfil.nome,
                              raio: isMobile ? 31 : 38,
                              tamanhoFonte: isMobile ? 20 : 24,
                              circular: false,
                              bordaRaio: 13,
                            ),
                          ),
                          if (isMeuPerfil)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: onAlterarFoto,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0C6B6B),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // ÁREA COM NOME COMPLETO E CIDADE
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              perfil.nome,
                              style: TextStyle(
                                fontSize: isMobile ? 17 : 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF062222),
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 13,
                                  color: Color(0xFF7AAAA0),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  "${perfil.cidade} - ${perfil.estado}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF5A8585),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // 3. BOTÕES DE AÇÃO REPOSICIONADOS (EDITAR OU CONVERSAR)
                SizedBox(
                  width: double.infinity,
                  child: isMeuPerfil
                      ? OutlinedButton.icon(
                          onPressed: () async {
                            final alterado = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditarPerfilPage(
                                  usuarioId: perfil.id,
                                  token: token,
                                ),
                              ),
                            );
                            if (alterado == true) onPerfilAtualizado();
                          },
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 14,
                            color: Color(0xFF0C6B6B),
                          ),
                          label: const Text(
                            "Editar perfil",
                            style: TextStyle(
                              color: Color(0xFF0C6B6B),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFF0C6B6B),
                              width: 1.2,
                            ),
                            backgroundColor: const Color(0xFFF0FAF7),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: onConversar ??
                              onConectarOuConvidar ??
                              () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Iniciando conversa com ${perfil.nome}...",
                                    ),
                                    backgroundColor: const Color(0xFF0C6B6B),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                          icon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Conversar",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0C6B6B),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
