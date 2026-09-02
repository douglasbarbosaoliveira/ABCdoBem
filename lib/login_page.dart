import 'package:flutter/material.dart';

import 'widgets/landing_page_sections.dart';
import 'widgets/custom_nav_bar.dart'; // Importa o cabeçalho padrão

import 'volunteer_homepage.dart'; // <-- IMPORTANTE: Importa a página inicial do Voluntário

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isVolunteer = true;
  bool obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Quicksand'),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0FAF7),
        body: Column(
          children: [
            // --- 1. CABEÇALHO PADRÃO DO PROJETO ---
            CustomNavBar(
              onLogin: () {
                // Como já estamos na tela de login, aqui pode ficar vazio ou dar um pop
              },
              onRegisterVolunteer: () {
                // Se quiser redirecionar para cadastro no futuro
                Navigator.pop(context);
              },
            ),

            // --- 2. CONTEÚDO DA PÁGINA (SCROLL) ---
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Área do Topo com o Gradiente Escuro e Logo Grande
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(
                        top: 48,
                        bottom: 48,
                        left: 20,
                        right: 20,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: [0.0, 0.4, 0.8, 1.0],
                          colors: [
                            Color(0xFF062222),
                            Color(0xFF0C5252),
                            Color(0xFF1A8F8F),
                            Color(0xFF3DCFB0),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          // Botão Voltar posicionado de forma elegante dentro do topo
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 24,
                                  left: 20,
                                  right: 20,
                                ),
                                child: TextButton.icon(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(
                                    Icons.home,
                                    color: Color(0xFF9FE8D8),
                                    size: 20,
                                  ),
                                  label: const Text(
                                    "Início",
                                    style: TextStyle(
                                      color: Color(0xFF9FE8D8),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor: Colors.white.withOpacity(
                                      0.1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Logo Maior
                          Image.asset(
                            'assets/images/logo_abcdobem.png',
                            height: 220,
                          ),
                          const SizedBox(height: 24),

                          // Textos Claros
                          const Text(
                            "Bem-vindo ao ABC do Bem",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Entre na sua conta",
                            style: TextStyle(
                              color: Color(0xFF9FE8D8),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // --- 3. FORMULÁRIO DE LOGIN ---
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Toggle (Voluntário / ONG)
                              Container(
                                height: 54,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F5F1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    _buildToggleOption(
                                      title: "🙋 Voluntário",
                                      isSelected: isVolunteer,
                                      onTap: () =>
                                          setState(() => isVolunteer = true),
                                    ),
                                    _buildToggleOption(
                                      title: "🏢 ONG",
                                      isSelected: !isVolunteer,
                                      onTap: () =>
                                          setState(() => isVolunteer = false),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Campo E-mail
                              const Text(
                                "E-mail",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF062222),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: "ana@email.com",
                                  hintStyle: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFC2E4DC),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF0C6B6B),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Campo Senha
                              const Text(
                                "Senha",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF062222),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                obscureText: obscurePassword,
                                decoration: InputDecoration(
                                  hintText: "********",
                                  hintStyle: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFC2E4DC),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF0C6B6B),
                                      width: 2,
                                    ),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: const Color(0xFF3A6868),
                                    ),
                                    onPressed: () => setState(
                                      () => obscurePassword = !obscurePassword,
                                    ),
                                  ),
                                ),
                              ),

                              // Esqueci minha senha
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  child: const Text(
                                    "Esqueci minha senha",
                                    style: TextStyle(
                                      color: Color(0xFF0C6B6B),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Botão Entrar
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8CD4C7),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  isVolunteer
                                      ? "Entrar como Voluntário"
                                      : "Entrar como ONG",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 48),

                              // Área de Demo
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFC2E4DC),
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "ACESSO RÁPIDO (DEMO)",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const VoluntarioHomePage(),
                                                ),
                                              );
                                            },
                                            icon: const Text(
                                              "🙋",
                                              style: TextStyle(fontSize: 14),
                                            ),
                                            label: const Text(
                                              "Entrar como\nVoluntário",
                                              style: TextStyle(
                                                color: Color(0xFF0C6B6B),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                height: 1.2,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFFD1F5EE,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              elevation: 0,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () {},
                                            icon: const Text(
                                              "🏢",
                                              style: TextStyle(fontSize: 14),
                                            ),
                                            label: const Text(
                                              "Entrar como\nONG",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                height: 1.2,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF0C6B6B,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              elevation: 0,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 80),
                    // --- 4. RODAPÉ ---
                    const CustomFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? const Color(0xFF0C6B6B)
                  : const Color(0xFF3A6868),
            ),
          ),
        ),
      ),
    );
  }
}
