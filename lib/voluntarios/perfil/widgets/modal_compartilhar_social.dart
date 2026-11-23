// lib/voluntarios/perfil/widgets/modal_compartilhar_social.dart

import 'package:flutter/material.dart';
import 'package:flutter_social_button/flutter_social_button.dart';
import '../../../utils/social_share_helper.dart';

/// Define o contexto do compartilhamento no ecossistema do voluntário
enum TipoCompartilhamentoSocial {
  experiencia, // Relato publicado no mural/feed
  inscricao, // Candidatura realizada em uma vaga
  conquista, // Total de horas acumuladas ou medalha
  generico, // Compartilhamento livre
}

class ModalCompartilharSocial {
  static void exibir(
    BuildContext context, {
    required String texto,
    required String origem,
    TipoCompartilhamentoSocial tipo = TipoCompartilhamentoSocial.experiencia,
  }) {
    // Configurações contextuais com base no tipo de ação
    final IconData icone;
    final String titulo;
    final String subtitulo;
    final String mensagemSocial;

    switch (tipo) {
      case TipoCompartilhamentoSocial.inscricao:
        icone = Icons.how_to_reg_rounded;
        titulo = "Candidatura Confirmada!";
        subtitulo =
            "Inspire amigos a também participarem de ações solidárias no Grande ABC.";
        mensagemSocial =
            "Acabei de me candidatar para a ação \"$origem\" no ABC do Bem! 🤝\nVenha ser voluntário também!";
        break;

      case TipoCompartilhamentoSocial.conquista:
        icone = Icons.emoji_events_outlined;
        titulo = "Nova Conquista!";
        subtitulo =
            "Celebre seu impacto comunitário e compartilhe essa vitória com sua rede.";
        mensagemSocial =
            "Alcancei uma nova marca como voluntário no ABC do Bem: $origem! 🏅\n$texto";
        break;

      case TipoCompartilhamentoSocial.generico:
        icone = Icons.volunteer_activism_outlined;
        titulo = "Compartilhar Ação";
        subtitulo =
            "Divulgue esta iniciativa para mais pessoas se voluntariarem.";
        mensagemSocial =
            "Conheça a iniciativa \"$origem\" no ABC do Bem!\n$texto";
        break;

      case TipoCompartilhamentoSocial.experiencia:
      default:
        icone = Icons.check_circle_outline_rounded;
        titulo = "Experiência Publicada!";
        subtitulo =
            "Que tal divulgar seu impacto e inspirar amigos nas suas redes sociais?";
        mensagemSocial = texto;
        break;
    }

    showDialog(
      context: context,
      builder: (shareCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(22),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFFD1F5EE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icone,
                color: const Color(0xFF0C6B6B),
                size: 38,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF062222),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitulo,
              style: const TextStyle(
                  fontSize: 12, color: Colors.grey, height: 1.3),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Botões de redes sociais acionando o SocialShareHelper
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                FlutterSocialButton(
                  mini: true,
                  buttonType: ButtonType.whatsapp,
                  onTap: () {
                    Navigator.pop(shareCtx);
                    SocialShareHelper.compartilharWhatsApp(
                      texto: mensagemSocial,
                      origem: origem,
                    );
                  },
                ),
                FlutterSocialButton(
                  mini: true,
                  buttonType: ButtonType.linkedin,
                  onTap: () {
                    Navigator.pop(shareCtx);
                    SocialShareHelper.compartilharLinkedIn(
                      texto: mensagemSocial,
                      origem: origem,
                    );
                  },
                ),
                FlutterSocialButton(
                  mini: true,
                  buttonType: ButtonType.twitter,
                  onTap: () {
                    Navigator.pop(shareCtx);
                    SocialShareHelper.compartilharTwitter(
                      texto: mensagemSocial,
                      origem: origem,
                    );
                  },
                ),
                // Botão de compartilhamento nativo do sistema operacional
                InkWell(
                  onTap: () {
                    Navigator.pop(shareCtx);
                    SocialShareHelper.compartilharNativo(
                      texto: mensagemSocial,
                      origem: origem,
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0C6B6B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.share_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                // Copiar link/mensagem para área de transferência
                InkWell(
                  onTap: () {
                    Navigator.pop(shareCtx);
                    SocialShareHelper.copiarParaAreaTransferencia(
                      context,
                      texto: mensagemSocial,
                      origem: origem,
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F5F1),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFC2E4DC)),
                    ),
                    child: const Icon(
                      Icons.copy_rounded,
                      color: Color(0xFF0C6B6B),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(shareCtx),
              child: const Text(
                "Agora não, obrigado",
                style: TextStyle(
                  color: Color(0xFF7AAAA0),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
