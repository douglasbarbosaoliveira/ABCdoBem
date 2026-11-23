// lib/register/ong/register_ong_step1_page.dart

import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../utils/responsive.dart';
import '../../utils/app_validators.dart';
import 'register_ong_step2_page.dart';
import '../../ongs/services/ong_consulta_service.dart';
import 'widgets/register_step_header.dart';
import 'widgets/secao_identificacao_ong.dart';
import 'widgets/secao_contato_redes_ong.dart';
import 'widgets/secao_endereco_ong.dart';

class RegisterOngStep1Page extends StatefulWidget {
  const RegisterOngStep1Page({super.key});

  @override
  State<RegisterOngStep1Page> createState() => _RegisterOngStep1PageState();
}

class _RegisterOngStep1PageState extends State<RegisterOngStep1Page> {
  // --- CONTROLADORES ---
  final _cnpjController = TextEditingController();
  final _razaoSocialController = TextEditingController();
  final _nomeFantasiaController = TextEditingController();
  final _anoFundacaoController = TextEditingController();
  final _siteController = TextEditingController();

  final _telefoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _tiktokController = TextEditingController();

  final _cepController = TextEditingController();
  final _ruaController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();
  final _numeroController = TextEditingController();

  // --- FOCUS NODES ---
  final _cnpjFocus = FocusNode();
  final _razaoSocialFocus = FocusNode();
  final _nomeFantasiaFocus = FocusNode();
  final _anoFocus = FocusNode();
  final _siteFocus = FocusNode();

  final _telefoneFocus = FocusNode();
  final _whatsappFocus = FocusNode();

  final _cepFocus = FocusNode();
  final _ruaFocus = FocusNode();
  final _numeroFocus = FocusNode();
  final _bairroFocus = FocusNode();
  final _cidadeFocus = FocusNode();
  final _estadoFocus = FocusNode();

  // --- MENSAGENS DE ERRO ---
  String? _erroCnpj;
  String? _erroRazaoSocial;
  String? _erroNomeFantasia;
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
  bool _isLoadingCnpj = false;
  bool _dadosImportadosReceita = false;
  String _ultimoCnpjConsultado = "";

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
    _vincularValidadores();
    _cnpjController.addListener(() {
      final cnpjLimpo = _cnpjController.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (cnpjLimpo.length == 14 && cnpjLimpo != _ultimoCnpjConsultado) {
        _buscarCnpj(cnpjLimpo);
      }
    });
  }

  void _vincularValidadores() {
    _configurarFocusNode(_cnpjFocus, _cnpjController, AppValidators.validarCnpj,
        (e) => _erroCnpj = e);
    _configurarFocusNode(_razaoSocialFocus, _razaoSocialController,
        AppValidators.validarObrigatorio, (e) => _erroRazaoSocial = e);
    _configurarFocusNode(_nomeFantasiaFocus, _nomeFantasiaController,
        AppValidators.validarObrigatorio, (e) => _erroNomeFantasia = e);
    _configurarFocusNode(_anoFocus, _anoFundacaoController,
        AppValidators.validarAno, (e) => _erroAno = e);
    _configurarFocusNode(_siteFocus, _siteController, AppValidators.validarSite,
        (e) => _erroSite = e);
    _configurarFocusNode(_telefoneFocus, _telefoneController,
        AppValidators.validarTelefone, (e) => _erroTelefone = e);
    _configurarFocusNode(_whatsappFocus, _whatsappController,
        AppValidators.validarWhatsapp, (e) => _erroWhatsapp = e);
    _configurarFocusNode(_cepFocus, _cepController, AppValidators.validarCep,
        (e) => _erroCep = e);
    _configurarFocusNode(_ruaFocus, _ruaController,
        AppValidators.validarObrigatorio, (e) => _erroRua = e);
    _configurarFocusNode(_numeroFocus, _numeroController,
        AppValidators.validarObrigatorio, (e) => _erroNumero = e);
    _configurarFocusNode(_bairroFocus, _bairroController,
        AppValidators.validarObrigatorio, (e) => _erroBairro = e);
    _configurarFocusNode(_cidadeFocus, _cidadeController,
        AppValidators.validarObrigatorio, (e) => _erroCidade = e);
    _configurarFocusNode(_estadoFocus, _estadoController,
        AppValidators.validarObrigatorio, (e) => _erroEstado = e);
  }

  void _configurarFocusNode(
    FocusNode node,
    TextEditingController controller,
    String? Function(String) validador,
    Function(String?) setErro,
  ) {
    node.addListener(() {
      if (!node.hasFocus) {
        setState(() => setErro(validador(controller.text)));
      }
    });
  }

  Future<void> _buscarCnpj(String cnpjLimpo) async {
    _ultimoCnpjConsultado = cnpjLimpo;
    setState(() => _isLoadingCnpj = true);

    try {
      final resultado = await OngConsultaService.consultarCnpj(cnpjLimpo);
      if (!mounted) return;

      if (resultado['permitido'] != true) {
        setState(() {
          _dadosImportadosReceita = false;
          _erroCnpj = "CNPJ fora da área de atuação (Grande ABC).";
          _limparCamposImportados();
        });

        _mostrarAlerta(
          "Cadastro restrito ao Grande ABC!\n\n"
          "O CNPJ informado está registrado em ${resultado['municipio']} - ${resultado['uf']}. "
          "Aceitamos apenas instituições sediadas nos 7 municípios do Grande ABC.",
        );
        return;
      }

      setState(() {
        _razaoSocialController.text = resultado['razao_social'] ?? '';
        final String fantasia = resultado['nome_fantasia'] ?? '';
        if (fantasia.isNotEmpty) {
          _nomeFantasiaController.text = fantasia;
        } else if (_nomeFantasiaController.text.trim().isEmpty) {
          _nomeFantasiaController.text = _razaoSocialController.text;
        }

        _anoFundacaoController.text = resultado['ano_fundacao'] ?? '';
        if ((resultado['telefone'] ?? '').isNotEmpty) {
          _telefoneController.text = resultado['telefone'];
        }

        _cepController.text = resultado['cep'] ?? '';
        _ruaController.text = resultado['rua'] ?? '';
        _numeroController.text = resultado['numero'] ?? '';
        _bairroController.text = resultado['bairro'] ?? '';
        _cidadeController.text = resultado['cidade'] ?? '';
        _estadoController.text = resultado['estado'] ?? '';

        _dadosImportadosReceita = true;
        _limparErrosCamposImportados();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF0C6B6B),
          content:
              Text("CNPJ do Grande ABC validado! Dados oficiais carregados."),
          duration: Duration(seconds: 3),
        ),
      );
    } on FormatException catch (e) {
      if (mounted) _mostrarAlerta(e.message);
    } catch (e) {
      debugPrint("Erro na consulta de CNPJ: $e");
      _ultimoCnpjConsultado = ""; // Permite nova tentativa sem apagar dígitos
      if (mounted) {
        _mostrarAlerta(
            "Instabilidade ao consultar CNPJ. Por favor, preencha as informações manualmente.");
      }
    } finally {
      if (mounted) setState(() => _isLoadingCnpj = false);
    }
  }

  Future<void> _buscarCep(String cep) async {
    final cepLimpo = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cepLimpo.length != 8) return;

    setState(() => _isLoadingCep = true);
    try {
      final resultado = await OngConsultaService.consultarCep(cepLimpo);
      if (!mounted) return;

      if (resultado['permitido'] != true) {
        setState(() {
          _erroCep = "CEP fora do Grande ABC.";
          _ruaController.clear();
          _bairroController.clear();
          _cidadeController.clear();
          _estadoController.clear();
        });

        _mostrarAlerta(
          "Endereço não permitido!\n\n"
          "O CEP informado pertence a ${resultado['municipio']} - ${resultado['uf']}. "
          "Cadastre apenas endereços localizados nos 7 municípios do Grande ABC.",
        );
        return;
      }

      setState(() {
        _ruaController.text = resultado['rua'] ?? '';
        _bairroController.text = resultado['bairro'] ?? '';
        _cidadeController.text = resultado['cidade'] ?? '';
        _estadoController.text = resultado['estado'] ?? '';

        _erroCep = null;
        _erroRua = null;
        _erroBairro = null;
        _erroCidade = null;
        _erroEstado = null;
      });
    } on FormatException catch (e) {
      if (mounted) _mostrarAlerta(e.message);
    } catch (_) {
      if (mounted) {
        _mostrarAlerta("Erro ao buscar CEP. Verifique sua conexão.");
      }
    } finally {
      if (mounted) setState(() => _isLoadingCep = false);
    }
  }

  void _limparCamposImportados() {
    _razaoSocialController.clear();
    _nomeFantasiaController.clear();
    _anoFundacaoController.clear();
    _cepController.clear();
    _ruaController.clear();
    _numeroController.clear();
    _bairroController.clear();
    _cidadeController.clear();
    _estadoController.clear();
  }

  void _limparErrosCamposImportados() {
    _erroRazaoSocial = null;
    _erroNomeFantasia = null;
    _erroCnpj = null;
    _erroAno = null;
    _erroCep = null;
    _erroRua = null;
    _erroNumero = null;
    _erroBairro = null;
    _erroCidade = null;
    _erroEstado = null;
  }

  void _mostrarAlerta(String mensagem) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_rounded,
                color: Color(0xFF0C6B6B), size: 40),
            const SizedBox(height: 12),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF062222)),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Entendi",
                style: TextStyle(
                    color: Color(0xFF0C6B6B), fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _avancarStep() {
    final temErro = [
      _erroRazaoSocial,
      _erroNomeFantasia,
      _erroCnpj,
      _erroAno,
      _erroSite,
      _erroTelefone,
      _erroWhatsapp,
      _erroCep,
      _erroRua,
      _erroNumero,
      _erroBairro,
      _erroCidade,
      _erroEstado
    ].any((e) => e != null);

    if (temErro) {
      _mostrarAlerta(
          "Por favor, corrija os campos inválidos antes de continuar.");
      return;
    }

    final camposObrigatorios = [
      _cnpjController.text,
      _razaoSocialController.text,
      _nomeFantasiaController.text,
      _anoFundacaoController.text,
      _telefoneController.text,
      _whatsappController.text,
      _cepController.text,
      _ruaController.text,
      _numeroController.text,
      _bairroController.text,
      _cidadeController.text,
      _estadoController.text
    ];

    if (camposObrigatorios.any((c) => c.trim().isEmpty)) {
      _mostrarAlerta("Por favor, preencha todos os campos obrigatórios (*).");
      return;
    }

    if (!OngConsultaService.pertenceAoGrandeAbc(
        _cidadeController.text, _estadoController.text)) {
      setState(() => _erroCidade = "Município fora do Grande ABC.");
      _mostrarAlerta(
        "Área de atuação restrita!\n\n"
        "O cadastro no ABC do Bem é exclusivo para ONGs com sede no Grande ABC "
        "(Santo André, São Bernardo do Campo, São Caetano do Sul, Diadema, Mauá, Ribeirão Pires ou Rio Grande da Serra).",
      );
      return;
    }

    final dadosStep1 = {
      "cnpj": _cnpjController.text.trim(),
      "razao_social": _razaoSocialController.text.trim(),
      "nome_fantasia": _nomeFantasiaController.text.trim(),
      "ano_fundacao": _anoFundacaoController.text.trim(),
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
        builder: (_) => RegisterOngStep2Page(dadosOng: dadosStep1),
      ),
    );
  }

  @override
  void dispose() {
    _cnpjFocus.dispose();
    _razaoSocialFocus.dispose();
    _nomeFantasiaFocus.dispose();
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

    _cnpjController.dispose();
    _razaoSocialController.dispose();
    _nomeFantasiaController.dispose();
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
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF7),
      body: SingleChildScrollView(
        child: Column(
          children: [
            RegisterStepHeader(
              stepAtual: 1,
              isMobile: isMobile,
              onVoltar: () => Navigator.pop(context),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F5F1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFC2E4DC)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 18, color: Color(0xFF0C6B6B)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _isLoadingCnpj
                                    ? "Validando CNPJ e localização na Receita Federal..."
                                    : "Exclusivo para ONGs do Grande ABC. Digite o CNPJ para validar e preencher automaticamente.",
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF0C6B6B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (_isLoadingCnpj) ...[
                              const SizedBox(width: 8),
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF0C6B6B),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SecaoIdentificacaoOng(
                        cnpjCtrl: _cnpjController,
                        razaoSocialCtrl: _razaoSocialController,
                        nomeFantasiaCtrl: _nomeFantasiaController,
                        anoFundacaoCtrl: _anoFundacaoController,
                        siteCtrl: _siteController,
                        cnpjFocus: _cnpjFocus,
                        razaoSocialFocus: _razaoSocialFocus,
                        nomeFantasiaFocus: _nomeFantasiaFocus,
                        anoFocus: _anoFocus,
                        siteFocus: _siteFocus,
                        erroCnpj: _erroCnpj,
                        erroRazaoSocial: _erroRazaoSocial,
                        erroNomeFantasia: _erroNomeFantasia,
                        erroAno: _erroAno,
                        erroSite: _erroSite,
                        cnpjMask: _cnpjMask,
                        isMobile: isMobile,
                        dadosBloqueados: _dadosImportadosReceita,
                        onDestravarDados: () {
                          setState(() => _dadosImportadosReceita = false);
                        },
                      ),
                      const SizedBox(height: 24),
                      SecaoContatoRedesOng(
                        telefoneCtrl: _telefoneController,
                        whatsappCtrl: _whatsappController,
                        instagramCtrl: _instagramController,
                        facebookCtrl: _facebookController,
                        tiktokCtrl: _tiktokController,
                        telefoneFocus: _telefoneFocus,
                        whatsappFocus: _whatsappFocus,
                        erroTelefone: _erroTelefone,
                        erroWhatsapp: _erroWhatsapp,
                        mesmoNumeroWhatsapp: _mesmoNumeroWhatsapp,
                        onAlternarMesmoNumero: (val) {
                          setState(() {
                            _mesmoNumeroWhatsapp = val;
                            if (_mesmoNumeroWhatsapp) {
                              _whatsappController.text =
                                  _telefoneController.text;
                              _erroWhatsapp = AppValidators.validarWhatsapp(
                                  _whatsappController.text);
                            }
                          });
                        },
                        telefoneMask: _telefoneMask,
                        whatsappMask: _whatsappMask,
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 24),
                      SecaoEnderecoOng(
                        cepCtrl: _cepController,
                        ruaCtrl: _ruaController,
                        numeroCtrl: _numeroController,
                        bairroCtrl: _bairroController,
                        cidadeCtrl: _cidadeController,
                        estadoCtrl: _estadoController,
                        cepFocus: _cepFocus,
                        ruaFocus: _ruaFocus,
                        numeroFocus: _numeroFocus,
                        bairroFocus: _bairroFocus,
                        cidadeFocus: _cidadeFocus,
                        estadoFocus: _estadoFocus,
                        erroCep: _erroCep,
                        erroRua: _erroRua,
                        erroNumero: _erroNumero,
                        erroBairro: _erroBairro,
                        erroCidade: _erroCidade,
                        erroEstado: _erroEstado,
                        isLoadingCep: _isLoadingCep,
                        onCepChanged: (v) {
                          if (v.length >= 9) _buscarCep(v);
                        },
                        cepMask: _cepMask,
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _isLoadingCnpj ? null : _avancarStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0C6B6B),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoadingCnpj
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Continuar →",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
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
    );
  }
}
