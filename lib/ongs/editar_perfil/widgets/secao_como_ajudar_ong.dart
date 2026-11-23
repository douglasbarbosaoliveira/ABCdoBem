// lib/ongs/editar_perfil/widgets/secao_como_ajudar_ong.dart

import 'package:flutter/material.dart';

class SecaoComoAjudarOng extends StatelessWidget {
  final TextEditingController chavePixController;
  final TextEditingController horarioDoacoesController;

  const SecaoComoAjudarOng({
    super.key,
    required this.chavePixController,
    required this.horarioDoacoesController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FBF9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC2E4DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.volunteer_activism_rounded,
                size: 18,
                color: Color(0xFF0C6B6B),
              ),
              SizedBox(width: 8),
              Text(
                "Como ajudar",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF062222),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "Informe os dados de doação via PIX e os horários para entrega presencial de donativos.",
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF4C7A70),
            ),
          ),
          const SizedBox(height: 14),
          _buildField(
            "Chave PIX",
            chavePixController,
            hint: "Ex.: e-mail, CNPJ, telefone ou chave aleatória",
          ),
          const SizedBox(height: 12),
          _buildField(
            "Horário de Recebimento de Doações",
            horarioDoacoesController,
            hint: "Ex.: Segunda a sexta, das 08h às 17h",
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String? hint,
  }) {
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
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
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
