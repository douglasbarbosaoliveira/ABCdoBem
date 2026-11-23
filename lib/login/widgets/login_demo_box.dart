// lib/login/widgets/login_demo_box.dart

import 'package:flutter/material.dart';

class LoginDemoBox extends StatelessWidget {
  final bool isMobile;
  final VoidCallback onCadastrarVoluntario;
  final VoidCallback onCadastrarOng;

  const LoginDemoBox({
    super.key,
    required this.isMobile,
    required this.onCadastrarVoluntario,
    required this.onCadastrarOng,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFC2E4DC),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "AINDA NÃO TEM CONTA?",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDemoButton(
                  icone: "🙋", // Ícone original de voluntário
                  texto: "Quero ser Voluntário",
                  corFundo: const Color(0xFFD1F5EE),
                  corTexto: const Color(0xFF0C6B6B),
                  onTap: onCadastrarVoluntario,
                ),
                const SizedBox(height: 10),
                _buildDemoButton(
                  icone: "🏢", // Ícone original de ONG
                  texto: "Cadastrar minha ONG",
                  corFundo: const Color(0xFF0C6B6B),
                  corTexto: Colors.white,
                  onTap: onCadastrarOng,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildDemoButton(
                    icone: "🙋", // Ícone original de voluntário
                    texto: "Cadastrar-se como\nVoluntário",
                    corFundo: const Color(0xFFD1F5EE),
                    corTexto: const Color(0xFF0C6B6B),
                    onTap: onCadastrarVoluntario,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDemoButton(
                    icone: "🏢", // Ícone original de ONG
                    texto: "Cadastre sua\nONG",
                    corFundo: const Color(0xFF0C6B6B),
                    corTexto: Colors.white,
                    onTap: onCadastrarOng,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDemoButton({
    required String icone,
    required String texto,
    required Color corFundo,
    required Color corTexto,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Text(icone, style: const TextStyle(fontSize: 14)),
      label: Text(
        texto,
        style: TextStyle(
          color: corTexto,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          height: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: corFundo,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }
}
