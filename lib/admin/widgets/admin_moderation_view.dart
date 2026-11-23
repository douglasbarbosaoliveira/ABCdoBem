// lib/admin/widgets/admin_moderation_view.dart

import 'package:flutter/material.dart';
import 'admin_moderation_input_card.dart';

class AdminModerationView extends StatelessWidget {
  final TextEditingController oportunidadeCtrl;
  final TextEditingController postOngCtrl;
  final TextEditingController experienciaCtrl;
  final VoidCallback onRemoverOportunidade;
  final VoidCallback onRemoverPostOng;
  final VoidCallback onRemoverExperiencia;

  const AdminModerationView({
    super.key,
    required this.oportunidadeCtrl,
    required this.postOngCtrl,
    required this.experienciaCtrl,
    required this.onRemoverOportunidade,
    required this.onRemoverPostOng,
    required this.onRemoverExperiencia,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Moderação e Remoção Direta',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF062222),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Utilize os identificadores únicos (IDs) para remover elementos que violem as normas da comunidade.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          AdminModerationInputCard(
            titulo: 'Remover Vaga / Oportunidade',
            hint: 'ID da Oportunidade (UUID)',
            controller: oportunidadeCtrl,
            onRemover: onRemoverOportunidade,
            icone: Icons.event_busy,
          ),
          const SizedBox(height: 16),
          AdminModerationInputCard(
            titulo: 'Remover Publicação de ONG do Feed',
            hint: 'ID da Publicação (UUID)',
            controller: postOngCtrl,
            onRemover: onRemoverPostOng,
            icone: Icons.article_outlined,
          ),
          const SizedBox(height: 16),
          AdminModerationInputCard(
            titulo: 'Remover Relato de Voluntário',
            hint: 'ID do Relato de Experiência (UUID)',
            controller: experienciaCtrl,
            onRemover: onRemoverExperiencia,
            icone: Icons.speaker_notes_off_outlined,
          ),
        ],
      ),
    );
  }
}
