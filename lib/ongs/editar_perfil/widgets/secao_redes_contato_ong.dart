// lib/ongs/editar_perfil/widgets/secao_redes_contato_ong.dart

import 'package:flutter/material.dart';

class SecaoRedesContatoOng extends StatelessWidget {
  final TextEditingController siteController;
  final TextEditingController telefoneFixoController;
  final TextEditingController whatsappController;
  final TextEditingController instagramController;
  final TextEditingController facebookController;
  final TextEditingController tiktokController;

  const SecaoRedesContatoOng({
    super.key,
    required this.siteController,
    required this.telefoneFixoController,
    required this.whatsappController,
    required this.instagramController,
    required this.facebookController,
    required this.tiktokController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Contato e Redes Sociais",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF062222),
          ),
        ),
        const SizedBox(height: 10),
        _buildField("Site Oficial", siteController),
        const SizedBox(height: 12),
        _buildField("Telefone Fixo", telefoneFixoController),
        const SizedBox(height: 12),
        _buildField("WhatsApp", whatsappController),
        const SizedBox(height: 12),
        _buildField("Instagram", instagramController),
        const SizedBox(height: 12),
        _buildField("Facebook", facebookController),
        const SizedBox(height: 12),
        _buildField("TikTok", tiktokController),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF062222),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF0FAF7),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFC2E4DC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF0C6B6B), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
