// lib/register/ong/widgets/secao_resumo_cadastro_ong.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';

class SecaoResumoCadastroOng extends StatelessWidget {
  final Map<String, dynamic> dados;

  const SecaoResumoCadastroOng({super.key, required this.dados});

  Widget _linhaInfo(String rotulo, String valor) {
    if (valor.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              rotulo,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A6868),
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF062222),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Uint8List? logoBytes = dados['logo_bytes'] as Uint8List?;
    final String nomeFantasia = (dados['nome_fantasia'] ?? '').toString();
    final String razaoSocial = (dados['razao_social'] ?? '').toString();
    final String cnpj = (dados['cnpj'] ?? '').toString();
    final String ano = (dados['ano_fundacao'] ?? '').toString();
    final String causa = (dados['causa_principal'] ?? '').toString();
    final String whatsapp = (dados['whatsapp'] ?? '').toString();
    final String cidade = (dados['cidade'] ?? '').toString();
    final String estado = (dados['estado'] ?? '').toString();
    final String bairro = (dados['bairro'] ?? '').toString();

    final List servicos = (dados['servicos_oferecidos'] as List?) ?? [];
    final List publicos = (dados['publico_atendido'] as List?) ?? [];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC2E4DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do Resumo com Logo (se houver)
          Row(
            children: [
              if (logoBytes != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    logoBytes,
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
              ] else ...[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F5F1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.volunteer_activism_outlined,
                    color: Color(0xFF0C6B6B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Resumo do Cadastro",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0C6B6B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nomeFantasia.isNotEmpty ? nomeFantasia : razaoSocial,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF062222),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFE0F0EC), height: 1),
          ),
          _linhaInfo("Razão Social:", razaoSocial),
          _linhaInfo("CNPJ:", cnpj),
          _linhaInfo("Fundação:", ano),
          _linhaInfo("Localização:", "$bairro — $cidade/$estado"),
          _linhaInfo("WhatsApp:", whatsapp),
          _linhaInfo("Causa Principal:", causa),
          if (servicos.isNotEmpty) _linhaInfo("Serviços:", servicos.join(", ")),
          if (publicos.isNotEmpty) _linhaInfo("Público:", publicos.join(", ")),
        ],
      ),
    );
  }
}
