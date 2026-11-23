// lib/login/login_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';

import '../utils/responsive.dart';
import '../widgets/landing_page_sections.dart';
import '../voluntarios/home/voluntario_home_page.dart';
import '../ongs/home/ong_home_page.dart';
import '../register/voluntario/register_step1_page.dart';
import '../register/ong/register_ong_step1_page.dart';

import 'services/login_service.dart';
import 'models/login_dto.dart';
import '../services/session_service.dart';
import 'widgets/login_hero_header.dart';
import 'widgets/login_perfil_toggle.dart';
import 'widgets/login_form.dart';
import 'widgets/login_demo_box.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LoginService _loginService = LoginService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  bool isVolunteer = true;
  bool obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _mostrarAlerta(String mensagem, {bool erro = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem, textAlign: TextAlign.center),
        backgroundColor: erro ? Colors.redAccent : const Color(0xFF0C6B6B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Decodifica o payload do JWT retornado pelo backend
  Map<String, dynamic> _decodificarPayloadJwt(String? token) {
    if (token == null || token.isEmpty) return {};
    try {
      final partes = token.split('.');
      if (partes.length != 3) return {};

      String payloadB64 = partes[1].replaceAll('-', '+').replaceAll('_', '/');
      while (payloadB64.length % 4 != 0) {
        payloadB64 += '=';
      }

      final payloadString = utf8.decode(base64Url.decode(payloadB64));
      final decoded = jsonDecode(payloadString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  void _navegarParaHome({
    required bool comoVoluntario,
    required String id,
    String? nome,
    String? token,
  }) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, a1, a2) => comoVoluntario
            ? VoluntarioHomePage(
                voluntarioId: id,
                nomeUsuario: nome,
                token: token,
              )
            : OngHomePage(ongId: id),
        transitionDuration: Duration.zero,
      ),
    );
  }

  Future<void> _fazerLogin() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      _mostrarAlerta("Por favor, preencha o e-mail e a senha.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dto = LoginDto(
        email: email,
        password: senha,
      );

      final resposta = await _loginService.autenticar(dto);

      // 1. Extrai ID ('sub') e role real do JWT
      final payloadJwt = _decodificarPayloadJwt(resposta.accessToken);
      final String? idJwt =
          payloadJwt['sub']?.toString() ?? payloadJwt['id']?.toString();
      final String roleJwt =
          (payloadJwt['role'] ?? '').toString().toUpperCase().trim();

      final String idAutenticado = idJwt ??
          resposta.usuarioId ??
          (isVolunteer ? 'bc7cab2e-1351-4384-b2f4-3a1343e75058' : 'ong-1');

      final String roleInicial =
          roleJwt.isNotEmpty ? roleJwt : (isVolunteer ? "USER" : "ONG");

      debugPrint("Nome recebido no login: ${resposta.name}");
      debugPrint(
          "ID autenticado resolvido: $idAutenticado | Role JWT: $roleJwt");

      // 2. Salva as credenciais iniciais na sessão global
      SessionService.instance.salvarSessao(
        novoToken: resposta.accessToken,
        novoUsuarioId: idAutenticado,
        novoNome: resposta.name,
        novoEmail: email,
        novoRole: roleInicial,
      );

      // 3. Sincroniza os dados cadastrais e a role oficial da API (GET /users/{id})
      await SessionService.instance.carregarDadosCompletosUsuario();

      if (!mounted) return;
      setState(() => _isLoading = false);

      // 4. Define o destino pela role oficial da conta (e não apenas pelo toggle visual)
      final String roleOficial =
          (SessionService.instance.role ?? roleInicial).toUpperCase().trim();
      final bool destinoVoluntario = roleOficial != 'ONG';

      _navegarParaHome(
        comoVoluntario: destinoVoluntario,
        id: idAutenticado,
        nome: SessionService.instance.nomeUsuario ?? resposta.name,
        token: resposta.accessToken,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _mostrarAlerta(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Quicksand'),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0FAF7),
        body: SingleChildScrollView(
          child: Column(
            children: [
              LoginHeroHeader(isMobile: isMobile),
              SizedBox(height: isMobile ? 28 : 48),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LoginPerfilToggle(
                          isVolunteer: isVolunteer,
                          onToggle: (val) => setState(() => isVolunteer = val),
                        ),
                        const SizedBox(height: 24),
                        LoginForm(
                          emailController: _emailController,
                          senhaController: _senhaController,
                          isVolunteer: isVolunteer,
                          obscurePassword: obscurePassword,
                          isLoading: _isLoading,
                          onToggleObscure: () => setState(
                            () => obscurePassword = !obscurePassword,
                          ),
                          onSubmit: _fazerLogin,
                          onEsqueciSenha: () {},
                        ),
                        const SizedBox(height: 36),
                        LoginDemoBox(
                          isMobile: isMobile,
                          onCadastrarVoluntario: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterStep1Page(),
                              ),
                            );
                          },
                          onCadastrarOng: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RegisterOngStep1Page(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 48 : 80),
              const CustomFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
