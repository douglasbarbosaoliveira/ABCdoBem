import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:flutter/services.dart';

import 'register_step2_page.dart';

class RegisterStep1Page extends StatefulWidget {
  const RegisterStep1Page({super.key});

  @override
  State<RegisterStep1Page> createState() => _RegisterStep1PageState();
}

class _RegisterStep1PageState extends State<RegisterStep1Page> {
  // Controladores de Texto
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController =
      TextEditingController();
  final TextEditingController _documentoController = TextEditingController();
  final TextEditingController _nascimentoController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _ruaController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _estadoController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  // "Olheiros" de Foco (Para validar quando o usuário sai do campo)
  final FocusNode _nomeFocus = FocusNode(); // <-- Adicionar
  String? _erroNome; // <-- Adicionar
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _documentoFocus = FocusNode();
  final FocusNode _nascimentoFocus = FocusNode();

  // Mensagens de Erro Individuais (Ficam debaixo do campo)
  String? _erroEmail;
  String? _erroDocumento;
  String? _erroData;

  // Máscaras de formatação automática
  final _cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _telefoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _dataMask = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _cepMask = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {"#": RegExp(r'[0-9]')},
  );

  // Permite apenas letras (incluindo acentos) e espaços
  bool _isNomeValido(String nome) {
    final nomeRegex = RegExp(r"^[a-zA-ZÀ-ÿ\s]+$");
    return nomeRegex.hasMatch(nome) && nome.trim().isNotEmpty;
  }

  bool _isLoadingCep = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  String _tipoDocumento = 'CPF';

  // Variáveis da Senha
  bool _temMinimo = false;
  bool _temMaiuscula = false;
  bool _temMinuscula = false;
  bool _temEspecial = false;
  bool _senhasIguais = false;

  // --- INICIALIZAÇÃO DOS OLHEIROS (FOCUS NODES) ---
  @override
  void initState() {
    super.initState();
    // Fica escutando o campo de Nome
    _nomeFocus.addListener(() {
      if (!_nomeFocus.hasFocus && _nomeController.text.isNotEmpty) {
        setState(() {
          _erroNome = _isNomeValido(_nomeController.text)
              ? null
              : "O nome não deve conter números ou símbolos.";
        });
      }
    });
    // Fica escutando quando o usuário entra ou sai do campo de E-mail
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus && _emailController.text.isNotEmpty) {
        setState(() {
          _erroEmail = _isEmailValido(_emailController.text)
              ? null
              : "E-mail inválido.";
        });
      }
    });

    // Fica escutando o campo de Documento
    _documentoFocus.addListener(() {
      if (!_documentoFocus.hasFocus && _documentoController.text.isNotEmpty) {
        setState(() {
          if (_tipoDocumento == 'CPF') {
            _erroDocumento =
                _isCpfValidoMatematicamente(_documentoController.text)
                ? null
                : "CPF inválido.";
          } else {
            _erroDocumento = _documentoController.text.length >= 5
                ? null
                : "Passaporte muito curto.";
          }
        });
      }
    });

    // Fica escutando o campo de Data de Nascimento
    _nascimentoFocus.addListener(() {
      if (!_nascimentoFocus.hasFocus && _nascimentoController.text.isNotEmpty) {
        setState(() {
          _erroData = _validarDataNascimento(_nascimentoController.text);
        });
      }
    });
  }

  // --- VALIDADORES INTELIGENTES ---
  bool _isEmailValido(String email) {
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    );
    return emailRegex.hasMatch(email);
  }

  bool _isCpfValidoMatematicamente(String cpf) {
    String numeros = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeros.length != 11) return false;
    if (RegExp(r'^(\d)\1*$').hasMatch(numeros)) return false;

    List<int> digitos = numeros
        .split('')
        .map((String d) => int.parse(d))
        .toList();

    int calcularDigito(int n) {
      int soma = 0;
      for (int i = 0; i < n; i++) soma += digitos[i] * ((n + 1) - i);
      int resto = soma % 11;
      return resto < 2 ? 0 : 11 - resto;
    }

    if (digitos[9] != calcularDigito(9)) return false;
    if (digitos[10] != calcularDigito(10)) return false;

    return true;
  }

  String? _validarDataNascimento(String data) {
    if (data.length != 10) return "Data incompleta.";

    List<String> partes = data.split('/');
    if (partes.length != 3) return "Formato inválido.";

    int? dia = int.tryParse(partes[0]);
    int? mes = int.tryParse(partes[1]);
    int? ano = int.tryParse(partes[2]);

    if (dia == null || mes == null || ano == null) return "Data inválida.";
    if (ano < 1900 || ano > DateTime.now().year) return "Ano inválido.";
    if (mes < 1 || mes > 12) return "Mês inválido.";

    int diasNoMes = DateTime(ano, mes + 1, 0).day;
    if (dia < 1 || dia > diasNoMes) return "Dia inexistente neste mês.";

    DateTime nascimento = DateTime(ano, mes, dia);
    DateTime hoje = DateTime.now();
    int idade = hoje.year - nascimento.year;
    if (hoje.month < nascimento.month ||
        (hoje.month == nascimento.month && hoje.day < nascimento.day)) {
      idade--;
    }

    if (idade < 12) return "É necessário ter no mínimo 12 anos.";
    if (idade > 120) return "Data irreal.";

    return null;
  }

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
    _nomeFocus.dispose();
    _emailFocus.dispose();
    _documentoFocus.dispose();
    _nascimentoFocus.dispose();

    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _documentoController.dispose();
    _nascimentoController.dispose();
    _telefoneController.dispose();
    _cepController.dispose();
    _ruaController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    _numeroController.dispose();
    _bioController.dispose();
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
                            "CADASTRO",
                            style: TextStyle(
                              color: Color(0xFF9FE8D8),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Sou Voluntário",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Crie seu perfil e comece a impactar",
                            style: TextStyle(
                              color: Color(0xFF9FE8D8),
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Row(
                            children: [
                              _buildStepItem("1", "Dados pessoais", true),
                              _buildStepDivider(),
                              _buildStepItem("2", "Habilidades", false),
                              _buildStepDivider(),
                              _buildStepItem("3", "Disponibilidade", false),
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
                          "Seus dados",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF062222),
                          ),
                        ),
                        const SizedBox(height: 24),

                        _buildTextField(
                          "Nome completo",
                          "Digite seu nome completo",
                          controller: _nomeController,
                          focusNode: _nomeFocus, // <-- Conectado
                          errorText: _erroNome, // <-- Conectado
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          "Tipo de Documento",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF062222),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFC2E4DC)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _tipoDocumento,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Color(0xFF0C6B6B),
                              ),
                              items: ['CPF', 'Passaporte / DNI'].map((
                                String value,
                              ) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (novoValor) {
                                setState(() {
                                  _tipoDocumento = novoValor!;
                                  _documentoController.clear();
                                  _erroDocumento =
                                      null; // Limpa o erro ao trocar
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildTextField(
                                _tipoDocumento,
                                _tipoDocumento == 'CPF'
                                    ? "000.000.000-00"
                                    : "Alfanumérico",
                                keyboardType: _tipoDocumento == 'CPF'
                                    ? TextInputType.number
                                    : TextInputType.text,
                                controller: _documentoController,
                                formatters: _tipoDocumento == 'CPF'
                                    ? [_cpfMask]
                                    : [],
                                focusNode:
                                    _documentoFocus, // <-- Conectado aqui!
                                errorText:
                                    _erroDocumento, // <-- Conectado aqui!
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: _buildTextField(
                                "Nascimento",
                                "DD/MM/AAAA",
                                keyboardType: TextInputType.datetime,
                                controller: _nascimentoController,
                                formatters: [_dataMask],
                                focusNode:
                                    _nascimentoFocus, // <-- Conectado aqui!
                                errorText: _erroData, // <-- Conectado aqui!
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          "E-mail",
                          "email@email.com",
                          keyboardType: TextInputType.emailAddress,
                          controller: _emailController,
                          focusNode: _emailFocus, // <-- Conectado aqui!
                          errorText: _erroEmail, // <-- Conectado aqui!
                        ),
                        const SizedBox(height: 16),

                        _buildPasswordField(
                          "Senha",
                          "Crie uma senha forte",
                          obscurePassword,
                          (val) => setState(() => obscurePassword = val),
                          controller: _senhaController,
                          onChanged: (val) {
                            setState(() {
                              _temMinimo = val.length >= 8;
                              _temMaiuscula = val.contains(RegExp(r'[A-Z]'));
                              _temMinuscula = val.contains(RegExp(r'[a-z]'));
                              _temEspecial = val.contains(RegExp(r'[\W_]'));
                              _senhasIguais =
                                  (val == _confirmarSenhaController.text) &&
                                  val.isNotEmpty;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildRequisito("Mínimo de 8 caracteres", _temMinimo),
                        _buildRequisito(
                          "Pelo menos 1 letra maiúscula",
                          _temMaiuscula,
                        ),
                        _buildRequisito(
                          "Pelo menos 1 letra minúscula",
                          _temMinuscula,
                        ),
                        _buildRequisito(
                          "Pelo menos 1 caractere especial (@, #, !, etc)",
                          _temEspecial,
                        ),
                        const SizedBox(height: 16),

                        _buildPasswordField(
                          "Confirmar senha",
                          "Digite a senha novamente",
                          obscureConfirmPassword,
                          (val) => setState(() => obscureConfirmPassword = val),
                          controller: _confirmarSenhaController,
                          onChanged: (val) {
                            setState(() {
                              _senhasIguais =
                                  (val == _senhaController.text) &&
                                  val.isNotEmpty;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildRequisito("As senhas coincidem", _senhasIguais),
                        const SizedBox(height: 16),

                        _buildTextField(
                          "Telefone / WhatsApp",
                          "(11) 99999-9999",
                          keyboardType: TextInputType.phone,
                          controller: _telefoneController,
                          formatters: [_telefoneMask],
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          "Endereço",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF062222),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end, // Modificado para start para lidar com errorText
                          children: [
                            Expanded(
                              child: _buildTextField(
                                "CEP",
                                "09000-000",
                                keyboardType: TextInputType.number,
                                controller: _cepController,
                                formatters: [_cepMask],
                                onChanged: (value) {
                                  if (value.length >= 9) _buscarCep(value);
                                },
                              ),
                            ),
                            if (_isLoadingCep)
                              const Padding(
                                padding: EdgeInsets.only(
                                  left: 12.0,
                                  bottom: 20.0,
                                ),
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
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildTextField(
                                "Rua / Logradouro",
                                "Preenchido via CEP",
                                controller: _ruaController,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: _buildTextField(
                                "Número",
                                "Ex: 123",
                                controller: _numeroController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          "Bairro",
                          "Preenchido via CEP",
                          controller: _bairroController,
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildTextField(
                                "Cidade",
                                "Preenchido via CEP",
                                controller: _cidadeController,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: _buildTextField(
                                "Estado",
                                "UF",
                                controller: _estadoController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        _buildTextField(
                          "Bio (opcional)",
                          "Conte brevemente sobre você e sua motivação...",
                          controller: _bioController,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 32),

                        // --- BOTÃO CONTINUAR E SUPER VALIDAÇÃO ---
                        ElevatedButton(
                          onPressed: () {
                            // Se as mensagens de erro em tempo real estiverem ativas, bloqueia
                            if (_erroEmail != null ||
                                _erroDocumento != null ||
                                _erroData != null) {
                              _mostrarErro(
                                "Por favor, corrija os erros nos campos antes de continuar.",
                              );
                              return;
                            }

                            String nome = _nomeController.text.trim();
                            String email = _emailController.text.trim();
                            String documento = _documentoController.text.trim();
                            String data = _nascimentoController.text.trim();

                            // Trava geral se tentarem pular sem digitar (FocusNode só dispara se entrar e sair)
                            if (nome.isEmpty ||
                                email.isEmpty ||
                                documento.isEmpty ||
                                data.isEmpty ||
                                !_temMinimo) {
                              _mostrarErro(
                                "Por favor, preencha todos os campos obrigatórios (Nome, Documento, Nascimento, E-mail e Senha).",
                              );
                              return;
                            }
                            if (!_temMinimo ||
                                !_temMaiuscula ||
                                !_temMinuscula ||
                                !_temEspecial) {
                              _mostrarErro(
                                "A senha não atende a todos os requisitos de segurança visualizados no checklist.",
                              );
                              return;
                            }
                            if (!_senhasIguais) {
                              _mostrarErro(
                                "A confirmação da senha está diferente. Por favor, verifique.",
                              );
                              return;
                            }

                            final dadosStep1 = {
                              "nome": nome,
                              "email": email,
                              "tipo_documento": _tipoDocumento,
                              "documento": documento,
                              "nascimento": data,
                              "senha": _senhaController.text,
                              "telefone": _telefoneController.text,
                              "cep": _cepController.text,
                              "rua": _ruaController.text,
                              "numero": _numeroController.text,
                              "bairro": _bairroController.text,
                              "cidade": _cidadeController.text,
                              "estado": _estadoController.text,
                              "bio": _bioController.text,
                            };

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    RegisterStep2Page(dadosBasicos: dadosStep1),
                              ),
                            );
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

  // --- MÉTODOS AUXILIARES ---

  Widget _buildRequisito(String texto, bool atendido) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            atendido ? Icons.check_circle : Icons.radio_button_unchecked,
            color: atendido ? Colors.green : Colors.grey.shade400,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              color: atendido ? Colors.green : Colors.grey.shade600,
              fontWeight: atendido ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint, {
    TextInputType? keyboardType,
    TextEditingController? controller,
    Function(String)? onChanged,
    int maxLines = 1,
    List<TextInputFormatter>? formatters,
    FocusNode? focusNode, // Adicionado para receber o olheiro
    String? errorText, // Adicionado para exibir a mensagem vermelha
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
          inputFormatters: formatters,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            errorText: errorText, // A mágica visual do Flutter acontece aqui!
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

  Widget _buildPasswordField(
    String label,
    String hint,
    bool obscure,
    Function(bool) onToggle, {
    TextEditingController? controller,
    Function(String)? onChanged,
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
          obscureText: obscure,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
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
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF3A6868),
              ),
              onPressed: () => onToggle(!obscure),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepItem(String number, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.white : Colors.white.withOpacity(0.2),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: isActive
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
            color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
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
