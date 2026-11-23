// lib/ongs/editar_perfil/editar_perfil_ong_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../nlp/ia_sugestao_causa_service.dart';
import '../services/ong_detail_service.dart';
import '../../services/session_service.dart';
import '../../utils/responsive.dart';
import '../../widgets/header/app_header.dart';
import '../models/ong_detail_models.dart';
import 'widgets/secao_como_ajudar_ong.dart';
import 'widgets/secao_endereco_ong.dart';
import 'widgets/secao_identidade_ong.dart';
import 'widgets/secao_redes_contato_ong.dart';

class EditarPerfilOngPage extends StatefulWidget {
  final String ongId;
  final String? token;
  final OngDetalheModel? ongAtual;

  const EditarPerfilOngPage({
    super.key,
    required this.ongId,
    this.token,
    this.ongAtual,
  });

  @override
  State<EditarPerfilOngPage> createState() => _EditarPerfilOngPageState();
}

class _EditarPerfilOngPageState extends State<EditarPerfilOngPage> {
  final OngDetailService _service = OngDetailService();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _nomeController;
  late final TextEditingController _razaoSocialController;
  late final TextEditingController _cnpjController;
  late final TextEditingController _emailController;
  late final TextEditingController _descricaoController;
  late final TextEditingController _avatarController;
  late final TextEditingController _chavePixController;
  late final TextEditingController _horarioDoacoesController;

  late final TextEditingController _cepController;
  late final TextEditingController _logradouroController;
  late final TextEditingController _numeroController;
  late final TextEditingController _bairroController;
  late final TextEditingController _cidadeController;
  late final TextEditingController _estadoController;

  late final TextEditingController _siteController;
  late final TextEditingController _telefoneFixoController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _instagramController;
  late final TextEditingController _facebookController;
  late final TextEditingController _tiktokController;

  late final List<String> _opcoesCausas;
  String _causaSelecionada = '';

  bool _carregandoInicial = false;
  bool _isLoadingCep = false;
  bool _salvando = false;

  final _cepMask = MaskTextInputFormatter(
    mask: '#####-###',
    // ignore: deprecated_member_use
    filter: {"#": RegExp(r'[0-9]')},
  );

  String get _idResolvido {
    final param = widget.ongId.trim();
    if (param.isNotEmpty) return param;
    return SessionService.instance.usuarioId?.trim() ?? '';
  }

  String? get _tokenResolvido =>
      (widget.token != null && widget.token!.trim().isNotEmpty)
          ? widget.token!.trim()
          : SessionService.instance.token;

  @override
  void initState() {
    super.initState();

    _opcoesCausas = IaSugestaoCausaService.obterCausasLimpos();

    _nomeController = TextEditingController();
    _razaoSocialController = TextEditingController();
    _cnpjController = TextEditingController();
    _emailController = TextEditingController();
    _descricaoController = TextEditingController();
    _avatarController = TextEditingController();
    _chavePixController = TextEditingController();
    _horarioDoacoesController = TextEditingController();

    _cepController = TextEditingController();
    _logradouroController = TextEditingController();
    _numeroController = TextEditingController();
    _bairroController = TextEditingController();
    _cidadeController = TextEditingController();
    _estadoController = TextEditingController();

    _siteController = TextEditingController();
    _telefoneFixoController = TextEditingController();
    _whatsappController = TextEditingController();
    _instagramController = TextEditingController();
    _facebookController = TextEditingController();
    _tiktokController = TextEditingController();

    if (widget.ongAtual != null) {
      _preencherComOng(widget.ongAtual!);
    }
    _carregarDadosIniciais();
  }

  ({
    String cep,
    String logradouro,
    String numero,
    String bairro,
    String cidade,
    String estado,
  }) _extrairCamposEndereco(OngDetalheModel ong) {
    String cep = '';
    String logradouro = '';
    String numero = '';
    String bairro = '';
    final String cidade = ong.cidade.trim();
    final String estado = ong.estado.trim();

    var bruto = ong.enderecoCompleto.trim();

    final idxCep = bruto.indexOf('(CEP:');
    if (idxCep != -1) {
      final fimCep = bruto.indexOf(')', idxCep);
      if (fimCep != -1) {
        cep = bruto.substring(idxCep + 5, fimCep).trim();
      }
      bruto = bruto.substring(0, idxCep).trim();
    }

    if (cidade.isNotEmpty && estado.isNotEmpty) {
      final sufixo = ', $cidade - $estado';
      if (bruto.endsWith(sufixo)) {
        bruto = bruto.substring(0, bruto.length - sufixo.length).trim();
      }
    }

    final partesHifen = bruto.split(' - ');
    final ruaENumero = partesHifen.first.trim();
    if (partesHifen.length > 1) {
      bairro = partesHifen.sublist(1).join(' - ').trim();
    }

    final partesVirgula = ruaENumero.split(',');
    if (partesVirgula.length >= 2) {
      logradouro = partesVirgula.first.trim();
      numero = partesVirgula.sublist(1).join(',').trim();
    } else {
      logradouro = ruaENumero;
    }

    return (
      cep: cep,
      logradouro: logradouro,
      numero: numero,
      bairro: bairro,
      cidade: cidade,
      estado: estado,
    );
  }

  void _preencherComOng(OngDetalheModel ong) {
    _nomeController.text = ong.nome;
    _razaoSocialController.text = ong.razaoSocial;
    _cnpjController.text = ong.cnpj;
    _emailController.text = ong.email;
    _descricaoController.text = ong.sobre;
    _avatarController.text = ong.logoUrl;
    _chavePixController.text = ong.chavePix ?? '';
    _horarioDoacoesController.text = ong.horarioRecebimentoDoacoes ?? '';

    final end = _extrairCamposEndereco(ong);
    _cepController.text = end.cep;
    _logradouroController.text = end.logradouro;
    _numeroController.text = end.numero;
    _bairroController.text = end.bairro;
    _cidadeController.text = end.cidade;
    _estadoController.text = end.estado;

    _siteController.text = ong.site ?? '';
    _telefoneFixoController.text = ong.telefone ?? '';
    _whatsappController.text = ong.whatsapp ?? '';
    _instagramController.text = ong.instagram ?? '';
    _facebookController.text = ong.facebook ?? '';
    _tiktokController.text = ong.tiktok ?? '';

    final causaLimpa = IaSugestaoCausaService.removerEmojis(ong.categoria);
    if (causaLimpa.isNotEmpty) {
      if (!_opcoesCausas.contains(causaLimpa)) {
        _opcoesCausas.add(causaLimpa);
      }
      _causaSelecionada = causaLimpa;
    }
  }

  Future<void> _carregarDadosIniciais() async {
    if (_idResolvido.isEmpty) return;
    if (widget.ongAtual == null) {
      setState(() => _carregandoInicial = true);
    }
    try {
      final ong = await _service.buscarDetalhesOng(
        _idResolvido,
        token: _tokenResolvido,
      );
      if (mounted) {
        setState(() {
          _preencherComOng(ong);
          _carregandoInicial = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _carregandoInicial = false);
        _mostrarSnack(
          e.toString().replaceAll('Exception: ', ''),
          isErro: true,
        );
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _razaoSocialController.dispose();
    _cnpjController.dispose();
    _emailController.dispose();
    _descricaoController.dispose();
    _avatarController.dispose();
    _chavePixController.dispose();
    _horarioDoacoesController.dispose();
    _cepController.dispose();
    _logradouroController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    _siteController.dispose();
    _telefoneFixoController.dispose();
    _whatsappController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _tiktokController.dispose();
    super.dispose();
  }

  String _apenasDigitos(String texto) {
    final buffer = StringBuffer();
    for (int i = 0; i < texto.length; i++) {
      final code = texto.codeUnitAt(i);
      if (code >= 48 && code <= 57) {
        buffer.writeCharCode(code);
      }
    }
    return buffer.toString();
  }

  Future<void> _buscarCep(String cep) async {
    final cepLimpo = _apenasDigitos(cep);
    if (cepLimpo.length != 8) return;

    setState(() => _isLoadingCep = true);
    try {
      final res = await http
          .get(Uri.parse('https://viacep.com.br/ws/$cepLimpo/json/'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final dados = json.decode(res.body);
        if (dados['erro'] == true) {
          _mostrarSnack("CEP não localizado.", isErro: true);
          return;
        }
        setState(() {
          _logradouroController.text = dados['logradouro'] ?? '';
          _bairroController.text = dados['bairro'] ?? '';
          _cidadeController.text = dados['localidade'] ?? '';
          _estadoController.text = dados['uf'] ?? '';
        });
      }
    } catch (_) {
      _mostrarSnack("Erro ao consultar CEP.", isErro: true);
    } finally {
      if (mounted) setState(() => _isLoadingCep = false);
    }
  }

  Future<void> _selecionarAvatar() async {
    try {
      final XFile? arquivo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (arquivo == null) return;
      final bytes = await arquivo.readAsBytes();
      final mime = arquivo.name.toLowerCase().endsWith('.png')
          ? 'image/png'
          : 'image/jpeg';
      final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';
      if (mounted) {
        setState(() => _avatarController.text = dataUri);
      }
    } catch (e) {
      _mostrarSnack("Não foi possível carregar a imagem: $e", isErro: true);
    }
  }

  void _mostrarSnack(String msg, {bool isErro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isErro ? Colors.redAccent : const Color(0xFF0C6B6B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _salvarAlteracoes() async {
    final nomeLimpo = _nomeController.text.trim();
    if (nomeLimpo.isEmpty) {
      _mostrarSnack("Por favor, informe o nome da ONG.", isErro: true);
      return;
    }

    setState(() => _salvando = true);

    // Razão Social e CNPJ são somente leitura e não são enviados para alteração
    final Map<String, dynamic> payload = <String, dynamic>{
      "name": nomeLimpo,
      if (_emailController.text.trim().isNotEmpty)
        "email": _emailController.text.trim(),
      if (_causaSelecionada.trim().isNotEmpty)
        "causaPrincipal": _causaSelecionada.trim(),
      "descricao": _descricaoController.text.trim(),
      if (_avatarController.text.trim().isNotEmpty)
        "avatar": _avatarController.text.trim(),
      if (_chavePixController.text.trim().isNotEmpty)
        "chavePix": _chavePixController.text.trim(),
      if (_horarioDoacoesController.text.trim().isNotEmpty)
        "horarioRecebimentoDoacoes": _horarioDoacoesController.text.trim(),
      if (_cepController.text.trim().isNotEmpty)
        "cep": _cepController.text.trim(),
      if (_logradouroController.text.trim().isNotEmpty)
        "logradouro": _logradouroController.text.trim(),
      if (_numeroController.text.trim().isNotEmpty)
        "numero": _numeroController.text.trim(),
      if (_bairroController.text.trim().isNotEmpty)
        "bairro": _bairroController.text.trim(),
      if (_cidadeController.text.trim().isNotEmpty)
        "cidade": _cidadeController.text.trim(),
      if (_estadoController.text.trim().isNotEmpty)
        "estado": _estadoController.text.trim().toUpperCase(),
      if (_siteController.text.trim().isNotEmpty)
        "site": _siteController.text.trim(),
      if (_telefoneFixoController.text.trim().isNotEmpty)
        "telefoneFixo": _telefoneFixoController.text.trim(),
      if (_whatsappController.text.trim().isNotEmpty)
        "whatsapp": _whatsappController.text.trim(),
      if (_instagramController.text.trim().isNotEmpty)
        "instagram": _instagramController.text.trim(),
      if (_facebookController.text.trim().isNotEmpty)
        "facebook": _facebookController.text.trim(),
      if (_tiktokController.text.trim().isNotEmpty)
        "tiktok": _tiktokController.text.trim(),
    };

    try {
      await _service.atualizarPerfilOng(
        payload,
        token: _tokenResolvido,
      );

      final fotoLimpa = _avatarController.text.trim();
      if (fotoLimpa.isNotEmpty) {
        SessionService.instance.atualizarFotoUrl(fotoLimpa);
      }

      if (!mounted) return;
      setState(() => _salvando = false);
      _mostrarSnack("Perfil da ONG atualizado com sucesso!");
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      _mostrarSnack(e.toString().replaceAll("Exception: ", ""), isErro: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF7),
      body: Column(
        children: [
          AppHeader(
            usuarioId: _idResolvido,
            tipoUsuario: "ong",
            showBackButton: true,
          ),
          Expanded(
            child: _carregandoInicial
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF0C6B6B),
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Container(
                          padding: EdgeInsets.all(isMobile ? 18 : 28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFC2E4DC)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                "Editar Perfil da ONG",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF062222),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Atualize os dados institucionais, localização, redes sociais e formas de ajuda.",
                                style:
                                    TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                              const SizedBox(height: 20),
                              SecaoIdentidadeOng(
                                nomeController: _nomeController,
                                razaoSocialController: _razaoSocialController,
                                cnpjController: _cnpjController,
                                emailController: _emailController,
                                descricaoController: _descricaoController,
                                avatarController: _avatarController,
                                causaSelecionada: _causaSelecionada,
                                opcoesCausas: _opcoesCausas,
                                onCausaChanged: (c) =>
                                    setState(() => _causaSelecionada = c),
                                onSelecionarAvatar: _selecionarAvatar,
                              ),
                              const SizedBox(height: 24),
                              SecaoRedesContatoOng(
                                siteController: _siteController,
                                telefoneFixoController: _telefoneFixoController,
                                whatsappController: _whatsappController,
                                instagramController: _instagramController,
                                facebookController: _facebookController,
                                tiktokController: _tiktokController,
                              ),
                              const SizedBox(height: 24),
                              SecaoEnderecoOng(
                                cepController: _cepController,
                                logradouroController: _logradouroController,
                                numeroController: _numeroController,
                                bairroController: _bairroController,
                                cidadeController: _cidadeController,
                                estadoController: _estadoController,
                                cepMask: _cepMask,
                                isLoadingCep: _isLoadingCep,
                                onCepChanged: (v) {
                                  if (v.length >= 9) _buscarCep(v);
                                },
                                isMobile: isMobile,
                              ),
                              const SizedBox(height: 28),
                              SecaoComoAjudarOng(
                                chavePixController: _chavePixController,
                                horarioDoacoesController:
                                    _horarioDoacoesController,
                              ),
                              const SizedBox(height: 32),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _salvando
                                          ? null
                                          : () => Navigator.pop(context),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        side: const BorderSide(
                                          color: Color(0xFF0C6B6B),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text(
                                        "Cancelar",
                                        style: TextStyle(
                                          color: Color(0xFF0C6B6B),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed:
                                          _salvando ? null : _salvarAlteracoes,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF0C6B6B),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _salvando
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              "Salvar Alterações",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
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
                  ),
          ),
        ],
      ),
    );
  }
}
