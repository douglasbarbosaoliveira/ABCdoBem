import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:flutter/services.dart';

import 'register_ong_step2_page.dart';

import 'validators_ong.dart'; // <-- IMPORTANTE: Importamos as regras daqui!

// import 'register_ong_step2_page.dart';

class RegisterOngStep1Page extends StatefulWidget {
  const RegisterOngStep1Page({super.key});

  @override
  State<RegisterOngStep1Page> createState() => _RegisterOngStep1PageState();
}

class _RegisterOngStep1PageState extends State<RegisterOngStep1Page> {
  // --- CONTROLADORES ---
  final TextEditingController _razaoSocialController = TextEditingController();
  final TextEditingController _nomeFantasiaController = TextEditingController();
  final TextEditingController _cnpjController = TextEditingController();
  final TextEditingController _anoFundacaoController = TextEditingController();
  final TextEditingController _siteController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _tiktokController = TextEditingController();
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _ruaController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _estadoController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();

  // --- OLHEIROS (FOCUS NODES) ---
  final FocusNode _razaoSocialFocus = FocusNode();
  final FocusNode _nomeFantasiaFocus = FocusNode();
  final FocusNode _cnpjFocus = FocusNode();
  final FocusNode _anoFocus = FocusNode();
  final FocusNode _siteFocus = FocusNode();
  final FocusNode _telefoneFocus = FocusNode();
  final FocusNode _whatsappFocus = FocusNode();
  final FocusNode _cepFocus = FocusNode();
  final FocusNode _ruaFocus = FocusNode();
  final FocusNode _numeroFocus = FocusNode();
  final FocusNode _bairroFocus = FocusNode();
  final FocusNode _cidadeFocus = FocusNode();
  final FocusNode _estadoFocus = FocusNode();

  // --- MENSAGENS DE ERRO INDIVIDUAIS ---
  String? _erroRazaoSocial;
  String? _erroNomeFantasia;
  String? _erroCnpj;
  String? _erroAno;
  String? _erroSite;
  String? _erroTelefone;
  String? _erroWhatsapp;
  String? _erroCep;
  String? _erroRua;
  String? _erroNumero;
  String? _erroBairro;
  String? _erroCidade;
  String? _erroEstado;

  bool _mesmoNumeroWhatsapp = false;
  bool _isLoadingCep = false;

  // --- MÁSCARAS ---
  final _cnpjMask = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _telefoneMask = MaskTextInputFormatter(
    mask: '(##) ####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _whatsappMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _cepMask = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();

    // Olha como fica super limpo chamar as funções lá do AppValidators!
    _configurarFocusNode(
      _razaoSocialFocus,
      _razaoSocialController,
      AppValidators.validarObrigatorio,
      (erro) => _erroRazaoSocial = erro,
    );
    _configurarFocusNode(
      _nomeFantasiaFocus,
      _nomeFantasiaController,
      AppValidators.validarObrigatorio,
      (erro) => _erroNomeFantasia = erro,
    );
    _configurarFocusNode(
      _cnpjFocus,
      _cnpjController,
      AppValidators.validarCnpj,
      (erro) => _erroCnpj = erro,
    );
    _configurarFocusNode(
      _anoFocus,
      _anoFundacaoController,
      AppValidators.validarAno,
      (erro) => _erroAno = erro,
    );
    _configurarFocusNode(
      _siteFocus,
      _siteController,
      AppValidators.validarSite,
      (erro) => _erroSite = erro,
    );
    _configurarFocusNode(
      _telefoneFocus,
      _telefoneController,
      AppValidators.validarTelefone,
      (erro) => _erroTelefone = erro,
    );
    _configurarFocusNode(
      _whatsappFocus,
      _whatsappController,
      AppValidators.validarWhatsapp,
      (erro) => _erroWhatsapp = erro,
    );
    _configurarFocusNode(
      _cepFocus,
      _cepController,
      AppValidators.validarCep,
      (erro) => _erroCep = erro,
    );
    _configurarFocusNode(
      _ruaFocus,
      _ruaController,
      AppValidators.validarObrigatorio,
      (erro) => _erroRua = erro,
    );
    _configurarFocusNode(
      _numeroFocus,
      _numeroController,
      AppValidators.validarObrigatorio,
      (erro) => _erroNumero = erro,
    );
    _configurarFocusNode(
      _bairroFocus,
      _bairroController,
      AppValidators.validarObrigatorio,
      (erro) => _erroBairro = erro,
    );
    _configurarFocusNode(
      _cidadeFocus,
      _cidadeController,
      AppValidators.validarObrigatorio,
      (erro) => _erroCidade = erro,
    );
    _configurarFocusNode(
      _estadoFocus,
      _estadoController,
      AppValidators.validarObrigatorio,
      (erro) => _erroEstado = erro,
    );
  }

  void _configurarFocusNode(
    FocusNode node,
    TextEditingController controller,
    String? Function(String) validador,
    Function(String?) setErro,
  ) {
    node.addListener(() {
      if (!node.hasFocus) {
        setState(() {
          setErro(validador(controller.text));
        });
      }
    });
  }

  // --- BUSCADOR DE CEP NA API ---
  Future<void> _buscarCep(String cep) async {
    String cepLimpo = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cepLimpo.length != 8) return;

    setState(() => _isLoadingCep = true);

    try {
      final url = Uri.parse('https://viacep.com.br/ws/$cepLimpo/json/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final dados = json.decode(response.body);
        if (dados.containsKey('erro')) {
          _mostrarErro("CEP não encontrado.");
          return;
        }
        setState(() {
          _ruaController.text = dados['logradouro'] ?? '';
          _bairroController.text = dados['bairro'] ?? '';
          _cidadeController.text = dados['localidade'] ?? '';
          _estadoController.text = dados['uf'] ?? '';

          // Limpa os erros desses campos já que a API os preencheu
          _erroRua = null;
          _erroBairro = null;
          _erroCidade = null;
          _erroEstado = null;
        });
      }
    } catch (e) {
      _mostrarErro("Erro ao buscar o CEP. Verifique sua conexão.");
    } finally {
      setState(() => _isLoadingCep = false);
    }
  }

  void _mostrarErro(String mensagem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF062222),
                fontWeight: FontWeight.w500,
              ),
            ),
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

  @override
  void dispose() {
    _razaoSocialFocus.dispose();
    _nomeFantasiaFocus.dispose();
    _cnpjFocus.dispose();
    _anoFocus.dispose();
    _siteFocus.dispose();
    _telefoneFocus.dispose();
    _whatsappFocus.dispose();
    _cepFocus.dispose();
    _ruaFocus.dispose();
    _numeroFocus.dispose();
    _bairroFocus.dispose();
    _cidadeFocus.dispose();
    _estadoFocus.dispose();

    _razaoSocialController.dispose();
    _nomeFantasiaController.dispose();
    _cnpjController.dispose();
    _anoFundacaoController.dispose();
    _siteController.dispose();
    _telefoneController.dispose();
    _whatsappController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    _cepController.dispose();
    _ruaController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    _numeroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Quicksand'),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0FAF7),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // --- TOPO ESCURO ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF062222),
                      Color(0xFF0C5252),
                      Color(0xFF1A8F8F),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xFF9FE8D8),
                              size: 20,
                            ),
                            label: const Text(
                              "Voltar",
                              style: TextStyle(
                                color: Color(0xFF9FE8D8),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "CADASTRO ONG",
                            style: TextStyle(
                              color: Color(0xFF9FE8D8),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Instituição",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Cadastre sua ONG e encontre voluntários incríveis",
                            style: TextStyle(
                              color: Color(0xFF9FE8D8),
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Row(
                            children: [
                              _buildStepItem("1", "Dados Gerais", true),
                              _buildStepDivider(),
                              _buildStepItem("2", "Detalhes", false),
                              _buildStepDivider(),
                              _buildStepItem("3", "Finalizar", false),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // --- FORMULÁRIO ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 48,
                  horizontal: 20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Identificação da ONG",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF062222),
                          ),
                        ),
                        const SizedBox(height: 24),

                        _buildTextField(
                          "Razão Social (Nome Completo)",
                          "Ex: Associação ABC do Bem",
                          controller: _razaoSocialController,
                          focusNode: _razaoSocialFocus,
                          errorText: _erroRazaoSocial,
                        ),
                        const SizedBox(height: 16),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildTextField(
                                "Nome Fantasia",
                                "Ex: ABC do Bem",
                                controller: _nomeFantasiaController,
                                focusNode: _nomeFantasiaFocus,
                                errorText: _erroNomeFantasia,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: _buildTextField(
                                "CNPJ",
                                "00.000.000/0000-00",
                                keyboardType: TextInputType.number,
                                controller: _cnpjController,
                                formatters: [_cnpjMask],
                                focusNode: _cnpjFocus,
                                errorText: _erroCnpj,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: _buildTextField(
                                "Ano de Fundação",
                                "Ex: 2015",
                                keyboardType: TextInputType.number,
                                controller: _anoFundacaoController,
                                maxLength: 4,
                                focusNode: _anoFocus,
                                errorText: _erroAno,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: _buildTextField(
                                "Site (Opcional)",
                                "www.suaong.org.br",
                                keyboardType: TextInputType.url,
                                controller: _siteController,
                                focusNode: _siteFocus,
                                errorText: _erroSite,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          "Contato e Redes Sociais",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF062222),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildTextField(
                                "Telefone Fixo",
                                "(00) 0000-0000",
                                keyboardType: TextInputType.phone,
                                controller: _telefoneController,
                                formatters: [_telefoneMask],
                                focusNode: _telefoneFocus,
                                errorText: _erroTelefone,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildTextField(
                                    "WhatsApp",
                                    "(00) 00000-0000",
                                    keyboardType: TextInputType.phone,
                                    controller: _whatsappController,
                                    formatters: [_whatsappMask],
                                    focusNode: _whatsappFocus,
                                    errorText: _erroWhatsapp,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Checkbox(
                                          value: _mesmoNumeroWhatsapp,
                                          activeColor: const Color(0xFF0C6B6B),
                                          onChanged: (val) {
                                            setState(() {
                                              _mesmoNumeroWhatsapp =
                                                  val ?? false;
                                              if (_mesmoNumeroWhatsapp) {
                                                _whatsappController.text =
                                                    _telefoneController.text;
                                                _erroWhatsapp =
                                                    AppValidators.validarWhatsapp(
                                                      _whatsappController.text,
                                                    );
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        "Mesmo número do fixo",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF3A6868),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Redes sociais não tem focusNode agressivo porque são opcionais
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                "Instagram",
                                "@suaong",
                                controller: _instagramController,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                "Facebook",
                                "Link ou @",
                                controller: _facebookController,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                "TikTok",
                                "@suaong",
                                controller: _tiktokController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          "Endereço Físico",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF062222),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildTextField(
                                "CEP",
                                "00000-000",
                                keyboardType: TextInputType.number,
                                controller: _cepController,
                                formatters: [_cepMask],
                                focusNode: _cepFocus,
                                errorText: _erroCep,
                                onChanged: (value) {
                                  if (value.length >= 9) _buscarCep(value);
                                },
                              ),
                            ),
                            if (_isLoadingCep)
                              const Padding(
                                padding: EdgeInsets.only(left: 12.0, top: 40.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildTextField(
                                "Rua / Logradouro",
                                "Preenchido via CEP",
                                controller: _ruaController,
                                focusNode: _ruaFocus,
                                errorText: _erroRua,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: _buildTextField(
                                "Número",
                                "Ex: 123",
                                controller: _numeroController,
                                focusNode: _numeroFocus,
                                errorText: _erroNumero,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          "Bairro",
                          "Preenchido via CEP",
                          controller: _bairroController,
                          focusNode: _bairroFocus,
                          errorText: _erroBairro,
                        ),
                        const SizedBox(height: 16),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildTextField(
                                "Cidade",
                                "Preenchido via CEP",
                                controller: _cidadeController,
                                focusNode: _cidadeFocus,
                                errorText: _erroCidade,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: _buildTextField(
                                "Estado",
                                "UF",
                                controller: _estadoController,
                                focusNode: _estadoFocus,
                                errorText: _erroEstado,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // --- BOTÃO CONTINUAR ---
                        ElevatedButton(
                          onPressed: () {
                            // Verifica se há ALGUÉM com erro na tela inteira
                            if (_erroRazaoSocial != null ||
                                _erroNomeFantasia != null ||
                                _erroCnpj != null ||
                                _erroAno != null ||
                                _erroSite != null ||
                                _erroTelefone != null ||
                                _erroWhatsapp != null ||
                                _erroCep != null ||
                                _erroRua != null ||
                                _erroNumero != null ||
                                _erroBairro != null ||
                                _erroCidade != null ||
                                _erroEstado != null) {
                              _mostrarErro(
                                "Por favor, corrija os campos em vermelho antes de continuar.",
                              );
                              return;
                            }

                            // Verifica se o usuário tentou pular apertando direto no botão (sem passar pelos campos)
                            if (_razaoSocialController.text.isEmpty ||
                                _nomeFantasiaController.text.isEmpty ||
                                _cnpjController.text.isEmpty ||
                                _anoFundacaoController.text.isEmpty ||
                                _telefoneController.text.isEmpty ||
                                _whatsappController.text.isEmpty ||
                                _cepController.text.isEmpty ||
                                _ruaController.text.isEmpty ||
                                _numeroController.text.isEmpty ||
                                _bairroController.text.isEmpty ||
                                _cidadeController.text.isEmpty ||
                                _estadoController.text.isEmpty) {
                              _mostrarErro(
                                "Por favor, preencha todos os campos obrigatórios.",
                              );
                              return;
                            }

                            final dadosOngStep1 = {
                              "razao_social": _razaoSocialController.text
                                  .trim(),
                              "nome_fantasia": _nomeFantasiaController.text
                                  .trim(),
                              "cnpj": _cnpjController.text.trim(),
                              "ano_fundacao": _anoFundacaoController.text
                                  .trim(),
                              "site": _siteController.text.trim(),
                              "telefone": _telefoneController.text.trim(),
                              "whatsapp": _whatsappController.text.trim(),
                              "instagram": _instagramController.text.trim(),
                              "facebook": _facebookController.text.trim(),
                              "tiktok": _tiktokController.text.trim(),
                              "cep": _cepController.text.trim(),
                              "rua": _ruaController.text.trim(),
                              "numero": _numeroController.text.trim(),
                              "bairro": _bairroController.text.trim(),
                              "cidade": _cidadeController.text.trim(),
                              "estado": _estadoController.text.trim(),
                            };

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterOngStep2Page(
                                  dadosOng: dadosOngStep1,
                                ),
                              ),
                            );

                            print("📦 PACOTE ONG STEP 1 (SUPER BLINDADO):");
                            print(dadosOngStep1);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8CD4C7),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Continuar →",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- MÉTODOS AUXILIARES UI ---
  Widget _buildTextField(
    String label,
    String hint, {
    TextInputType? keyboardType,
    TextEditingController? controller,
    Function(String)? onChanged,
    int maxLines = 1,
    int? maxLength,
    List<TextInputFormatter>? formatters,
    FocusNode? focusNode,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF062222),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          maxLines: maxLines,
          maxLength: maxLength,
          inputFormatters: formatters,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            errorText: errorText,
            counterText: "",
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFC2E4DC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0C6B6B), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepItem(
    String number,
    String label,
    bool isActive, {
    bool isCompleted = false,
  }) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive || isCompleted
                ? Colors.white
                : Colors.white.withOpacity(0.2),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: isActive || isCompleted
                    ? const Color(0xFF062222)
                    : Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive || isCompleted
                ? Colors.white
                : Colors.white.withOpacity(0.7),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider() {
    return Expanded(
      child: Container(
        height: 2,
        color: Colors.white.withOpacity(0.2),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      ),
    );
  }
}
