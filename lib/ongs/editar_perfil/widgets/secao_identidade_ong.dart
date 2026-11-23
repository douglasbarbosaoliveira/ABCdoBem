// lib/ongs/editar_perfil/widgets/secao_identidade_ong.dart

import 'package:flutter/material.dart';
import 'editar_perfil_ong_avatar.dart';

class SecaoIdentidadeOng extends StatelessWidget {
  final TextEditingController nomeController;
  final TextEditingController razaoSocialController;
  final TextEditingController cnpjController;
  final TextEditingController emailController;
  final TextEditingController descricaoController;
  final TextEditingController avatarController;
  final String causaSelecionada;
  final List<String> opcoesCausas;
  final ValueChanged<String> onCausaChanged;
  final VoidCallback onSelecionarAvatar;
  final int maxDescricaoChars;

  const SecaoIdentidadeOng({
    super.key,
    required this.nomeController,
    required this.razaoSocialController,
    required this.cnpjController,
    required this.emailController,
    required this.descricaoController,
    required this.avatarController,
    required this.causaSelecionada,
    required this.opcoesCausas,
    required this.onCausaChanged,
    required this.onSelecionarAvatar,
    this.maxDescricaoChars = 600,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditarPerfilOngAvatar(
          avatarUrl: avatarController.text,
          onSelecionarAvatar: onSelecionarAvatar,
        ),
        const SizedBox(height: 18),

        _buildInput("Nome da ONG", nomeController),
        const SizedBox(height: 14),

        // Somente leitura: Razão Social
        _buildReadOnlyInput("Razão Social", razaoSocialController),
        const SizedBox(height: 14),

        // Somente leitura: CNPJ
        _buildReadOnlyInput("CNPJ", cnpjController),
        const SizedBox(height: 14),

        _buildInput("E-mail Institucional", emailController),
        const SizedBox(height: 14),

        const Text(
          "Causa Principal",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF062222),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: opcoesCausas.contains(causaSelecionada) &&
                  causaSelecionada.isNotEmpty
              ? causaSelecionada
              : null,
          hint: const Text(
            "Selecione a causa principal",
            style: TextStyle(fontSize: 13),
          ),
          items: opcoesCausas
              .map(
                (c) => DropdownMenuItem<String>(
                  value: c,
                  child: Text(c, style: const TextStyle(fontSize: 13)),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onCausaChanged(v);
          },
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
        const SizedBox(height: 14),

        // Sobre a Instituição com contador de caracteres
        _buildSobreComContador(),
      ],
    );
  }

  Widget _buildSobreComContador() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: descricaoController,
      builder: (context, value, _) {
        final int atual = value.text.characters.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Sobre a Instituição",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF062222),
                  ),
                ),
                Text(
                  "$atual/$maxDescricaoChars",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: atual >= maxDescricaoChars
                        ? Colors.redAccent
                        : const Color(0xFF4C7A70),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: descricaoController,
              maxLines: 4,
              maxLength: maxDescricaoChars,
              buildCounter: (
                _, {
                required currentLength,
                required isFocused,
                maxLength,
              }) =>
                  null,
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
      },
    );
  }

  Widget _buildReadOnlyInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF062222),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.lock_outline_rounded,
              size: 13,
              color: Color(0xFF6B8E86),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: true,
          enabled: false,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF5A7872),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFE7F0ED),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD0E3DE)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInput(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
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
          maxLines: maxLines,
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
