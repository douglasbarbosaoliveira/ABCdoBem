// lib/register/ong/register_ong_step3_page.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../utils/responsive.dart';
import '../../ongs/models/ong_cadastro_dto.dart';
import '../../services/ong_auth_service.dart';
import 'widgets/register_step_header.dart';
import 'widgets/secao_resumo_cadastro_ong.dart';
import 'widgets/secao_credenciais_ong.dart';
import 'widgets/secao_termos_lgpd_ong.dart';
import 'widgets/dialog_sucesso_ong.dart';

class RegisterOngStep3Page extends StatefulWidget {
  final Map<String, dynamic> dadosCompletos;

  const RegisterOngStep3Page({super.key, required this.dadosCompletos});

  @override
  State<RegisterOngStep3Page> createState() => _RegisterOngStep3PageState();
}

class _RegisterOngStep3PageState extends State<RegisterOngStep3Page> {
  final OngAuthService _ongAuthService = OngAuthService();

  // Controladores de conta
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final _emailFocus = FocusNode();

  String? _erroEmail;
  bool _obscureSenha = true;
  bool _obscureConfirmarSenha = true;

  // Validações da Senha Forte
  bool _temMinimo = false;
  bool _temMaiuscula = false;
  bool _temMinuscula = false;
  bool _temEspecial = false;
  bool _senhasIguais = false;

  // Consentimentos Legais
  bool _aceitouTermos = false;
  bool _aceitouLgpd = false;
  bool _isCarregando = false;
  String _statusRequisicao = "";

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus && _emailController.text.isNotEmpty) {
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        setState(() {
          _erroEmail = emailRegex.hasMatch(_emailController.text.trim())
              ? null
              : "E-mail inválido.";
        });
      }
    });
  }

  void _atualizarValidacoesSenha(String senha, String confirmacao) {
    setState(() {
      _temMinimo = senha.length >= 8;
      _temMaiuscula = senha.contains(RegExp(r'[A-Z]'));
      _temMinuscula = senha.contains(RegExp(r'[a-z]'));
      _temEspecial = senha.contains(RegExp(r'[\W_]'));
      _senhasIguais = senha.isNotEmpty && (senha == confirmacao);
    });
  }

  void _mostrarAlerta(String mensagem,
      {String? tipoRetorno, String? detalheTecnico}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline_rounded,
                color: Color(0xFF0C6B6B), size: 40),
            const SizedBox(height: 12),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF062222)),
            ),
            if (tipoRetorno != null && tipoRetorno.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F5F1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "Retorno: $tipoRetorno",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0C6B6B),
                  ),
                ),
              ),
            ],
            if (detalheTecnico != null && detalheTecnico.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8F7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD5E6E2)),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    detalheTecnico,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: Color(0xFF334E4E),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "OK",
                style: TextStyle(
                  color: Color(0xFF0C6B6B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _logDadosEnvio(OngCadastroDTO dto) {
    final mapaLog = Map<String, dynamic>.from(widget.dadosCompletos);
    if (mapaLog['logo_bytes'] != null) {
      mapaLog['logo_bytes'] = '<Uint8List removido do JSON>';
    }
    if (mapaLog['logo_base64'] != null) {
      final b64 = mapaLog['logo_base64'].toString();
      mapaLog['logo_base64'] = b64.length > 45
          ? '${b64.substring(0, 45)}... (${b64.length} chars)'
          : b64;
    }

    debugPrint('================ [CADASTRO ONG - INÍCIO] ================');
    debugPrint('Método: HTTP POST (application/json)');
    debugPrint('Endpoint: https://abc-do-bem.onrender.com/ongs/cadastro');
    debugPrint('E-mail de acesso: ${dto.emailLogin}');
    debugPrint('Payload Etapas 1 e 2: ${jsonEncode(mapaLog)}');
    debugPrint('=========================================================');
  }

  Future<void> _processarFinalizacao() async {
    if (_erroEmail != null) {
      _mostrarAlerta("Verifique o campo de E-mail antes de finalizar.");
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      _mostrarAlerta("O E-mail institucional é obrigatório (*).");
      return;
    }
    if (!_temMinimo || !_temMaiuscula || !_temMinuscula || !_temEspecial) {
      _mostrarAlerta("A senha não atende aos requisitos de segurança.");
      return;
    }
    if (!_senhasIguais) {
      _mostrarAlerta("A confirmação da senha não coincide.");
      return;
    }
    if (!_aceitouTermos || !_aceitouLgpd) {
      _mostrarAlerta(
          "É obrigatório aceitar os Termos e a Política de Privacidade (*).");
      return;
    }

    setState(() {
      _isCarregando = true;
      _statusRequisicao = "Preparando dados da ONG...";
    });

    final dto = OngCadastroDTO(
      dadosCompletosEtapasAnteriores: widget.dadosCompletos,
      habilidadesBuscadas: const [],
      doacoesAceitas: const [],
      formatoVoluntariado: "Definido por evento",
      emailLogin: _emailController.text.trim(),
      senhaLogin: _senhaController.text,
      termosAceitos: _aceitouTermos,
      lgpdAceita: _aceitouLgpd,
    );

    _logDadosEnvio(dto);

    final cronometro = Stopwatch()..start();

    try {
      setState(
          () => _statusRequisicao = "Enviando POST para /ongs/cadastro...");
      debugPrint('[CADASTRO ONG] Aguardando resposta HTTP do backend...');

      final resposta = await _ongAuthService.cadastrarOng(dto);

      cronometro.stop();
      debugPrint(
          '[CADASTRO ONG - RETORNO SUCESSO] HTTP 200/201 JSON em ${cronometro.elapsedMilliseconds}ms | ID: ${resposta.ongId} | E-mail: ${resposta.email}');

      if (!mounted) return;
      setState(() {
        _isCarregando = false;
        _statusRequisicao = "";
      });

      DialogSucessoOng.exibir(context, resposta.email);
    } on TimeoutException catch (e) {
      cronometro.stop();
      debugPrint(
          '[CADASTRO ONG - TIPO DE RETORNO: TimeoutException] Após ${cronometro.elapsedMilliseconds}ms: $e');
      if (!mounted) return;
      setState(() {
        _isCarregando = false;
        _statusRequisicao = "";
      });
      _mostrarAlerta(
        "O servidor demorou mais que o esperado para responder.",
        tipoRetorno:
            "TimeoutException (Sem resposta em ${cronometro.elapsed.inSeconds}s)",
        detalheTecnico:
            "O backend no Render pode estar iniciando (cold start). Tente clicar em Finalizar novamente.",
      );
    } on SocketException catch (e) {
      cronometro.stop();
      debugPrint('[CADASTRO ONG - TIPO DE RETORNO: SocketException] $e');
      if (!mounted) return;
      setState(() {
        _isCarregando = false;
        _statusRequisicao = "";
      });
      _mostrarAlerta(
        "Falha de conexão de rede com o servidor.",
        tipoRetorno: "SocketException (Sem conexão / DNS)",
        detalheTecnico: e.message,
      );
    } on http.ClientException catch (e) {
      cronometro.stop();
      debugPrint('[CADASTRO ONG - TIPO DE RETORNO: http.ClientException] $e');
      if (!mounted) return;
      setState(() {
        _isCarregando = false;
        _statusRequisicao = "";
      });
      _mostrarAlerta(
        "A requisição HTTP foi bloqueada ou interrompida antes de obter resposta do servidor.",
        tipoRetorno: "http.ClientException (Bloqueio CORS ou queda de conexão)",
        detalheTecnico: e.toString(),
      );
    } catch (e, stackTrace) {
      cronometro.stop();
      final erroLimpo = e.toString().replaceFirst('Exception: ', '');
      final primeiraLinha = erroLimpo.split('\n').first;

      debugPrint(
          '[CADASTRO ONG - TIPO DE RETORNO: Erro HTTP / Exceção] Em ${cronometro.elapsedMilliseconds}ms');
      debugPrint(erroLimpo);
      debugPrint('StackTrace: $stackTrace');

      if (!mounted) return;
      setState(() {
        _isCarregando = false;
        _statusRequisicao = "";
      });
      _mostrarAlerta(
        "O backend retornou uma resposta de erro ao processar o cadastro.",
        tipoRetorno: primeiraLinha,
        detalheTecnico: erroLimpo,
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF7),
      body: SingleChildScrollView(
        child: Column(
          children: [
            RegisterStepHeader(
              stepAtual: 3,
              isMobile: isMobile,
              onVoltar: _isCarregando ? () {} : () => Navigator.pop(context),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 24 : 36,
                horizontal: isMobile ? 16 : 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Resumo do que foi preenchido nos Steps 1 e 2
                      SecaoResumoCadastroOng(dados: widget.dadosCompletos),
                      const SizedBox(height: 24),

                      // 2. Credenciais de Acesso (Email e Senha Forte)
                      SecaoCredenciaisOng(
                        emailCtrl: _emailController,
                        senhaCtrl: _senhaController,
                        confirmarSenhaCtrl: _confirmarSenhaController,
                        emailFocus: _emailFocus,
                        erroEmail: _erroEmail,
                        obscureSenha: _obscureSenha,
                        obscureConfirmarSenha: _obscureConfirmarSenha,
                        onToggleObscureSenha: () =>
                            setState(() => _obscureSenha = !_obscureSenha),
                        onToggleObscureConfirmarSenha: () => setState(() =>
                            _obscureConfirmarSenha = !_obscureConfirmarSenha),
                        temMinimo: _temMinimo,
                        temMaiuscula: _temMaiuscula,
                        temMinuscula: _temMinuscula,
                        temEspecial: _temEspecial,
                        senhasIguais: _senhasIguais,
                        onSenhaChanged: (s) => _atualizarValidacoesSenha(
                            s, _confirmarSenhaController.text),
                        onConfirmarSenhaChanged: (c) =>
                            _atualizarValidacoesSenha(_senhaController.text, c),
                      ),
                      const SizedBox(height: 24),

                      // 3. Termos e LGPD
                      SecaoTermosLgpdOng(
                        aceitouTermos: _aceitouTermos,
                        aceitouLgpd: _aceitouLgpd,
                        onAlternarTermos: (v) =>
                            setState(() => _aceitouTermos = v),
                        onAlternarLgpd: (v) => setState(() => _aceitouLgpd = v),
                      ),
                      const SizedBox(height: 32),

                      // Indicador textual de progresso durante o envio
                      if (_isCarregando && _statusRequisicao.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _statusRequisicao,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0C6B6B),
                            ),
                          ),
                        ),
                      ],

                      // Botões Voltar / Finalizar
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isCarregando
                                  ? null
                                  : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(
                                  color: Color(0xFF0C6B6B),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                "← Voltar",
                                style: TextStyle(
                                  color: Color(0xFF0C6B6B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed:
                                  _isCarregando ? null : _processarFinalizacao,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0C6B6B),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: _isCarregando
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "Finalizar Cadastro ✓",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
