// lib/ongs/criar_evento/criar_evento_page.dart

import 'package:flutter/material.dart';

import '../../eventos/models/evento_model.dart';
import '../../eventos/services/evento_service.dart';
import '../../nlp/ia_sugestao_causa_service.dart';
import '../../services/session_service.dart';
import '../../utils/app_data.dart';
import '../../utils/responsive.dart';
import '../../widgets/bottom_nav/app_bottom_nav.dart';
import '../../widgets/header/app_header.dart';
import '../../widgets/sidebar/app_sidebar.dart';
import '../widgets/revisao_criar_evento.dart';

import 'widgets/secao_chips_appdata.dart';
import 'widgets/secao_dados_basicos.dart';
import 'widgets/secao_data_vagas.dart';
import 'widgets/secao_foto_capa.dart';
import 'widgets/secao_localizacao_cep.dart';

class CriarEventoPage extends StatefulWidget {
  final String ongId;
  final String tipoUsuario;
  final EventoModel? eventoParaEditar;

  const CriarEventoPage({
    super.key,
    required this.ongId,
    this.tipoUsuario = "ong",
    this.eventoParaEditar,
  });

  @override
  State<CriarEventoPage> createState() => _CriarEventoPageState();
}

class _CriarEventoPageState extends State<CriarEventoPage> {
  final _formKey = GlobalKey<FormState>();
  final EventoService _eventService = EventoService();

  late final TextEditingController _nomeController;
  late final TextEditingController _descricaoController;
  late final TextEditingController _vagasController;
  late final TextEditingController _bannerUrlController;
  late final TextEditingController _cepController;
  late final TextEditingController _logradouroController;
  late final TextEditingController _numeroController;
  late final TextEditingController _bairroController;
  late final TextEditingController _pontoReferenciaController;

  late List<String> _categorias;
  late String _formato;
  late String _cidade;
  late DateTime _data;
  late TimeOfDay _inicio;
  late TimeOfDay _termino;

  final Set<String> _requisitos = {};
  final Set<String> _necessidades = {};
  bool _salvando = false;
  bool _carregandoEdicao = false;
  bool _categoriasEditadasManualmente = false;

  bool get _isEdicao => widget.eventoParaEditar != null;
  bool get _isRemoto => _formato.toLowerCase().contains("remoto");

  String get _modalidadeApi {
    final f = _formato.toLowerCase();
    if (f.contains("remoto")) return "REMOTO";
    if (f.contains("híbrido") || f.contains("hibrido")) return "HIBRIDO";
    return "PRESENCIAL";
  }

  String get _ongIdEfetivo {
    final id = widget.ongId.trim();
    if (id.isNotEmpty) return id;
    return SessionService.instance.usuarioId?.trim() ?? '';
  }

  String get _ongNomeEfetivo {
    final nomeEditar = widget.eventoParaEditar?.ongNome.trim() ?? '';
    if (nomeEditar.isNotEmpty) return nomeEditar;
    final nomeSessao = SessionService.instance.nomeUsuario?.trim() ?? '';
    if (nomeSessao.isNotEmpty) return nomeSessao;
    return "Instituição Parceira";
  }

  @override
  void initState() {
    super.initState();

    final ev = widget.eventoParaEditar;

    if (ev != null) {
      _categoriasEditadasManualmente = true;
      _nomeController = TextEditingController(text: ev.titulo);
      _descricaoController = TextEditingController(text: ev.descricao);
      _vagasController = TextEditingController(text: ev.vagasTotais.toString());
      _bannerUrlController = TextEditingController(text: ev.imagemUrl);

      final parsedEnd = _separarEnderecoLegado(ev.endereco ?? '');
      _cepController = TextEditingController();
      _logradouroController = TextEditingController(text: parsedEnd.logradouro);
      _numeroController = TextEditingController(text: parsedEnd.numero);
      _bairroController = TextEditingController(text: parsedEnd.bairro);
      _pontoReferenciaController =
          TextEditingController(text: parsedEnd.referencia);

      final causaPrimaria = IaSugestaoCausaService.removerEmojis(ev.categoria);
      _categorias = [causaPrimaria];

      final causasPossiveis = IaSugestaoCausaService.obterCausasLimpos();
      for (final tag in ev.tags) {
        final tagLimpa = IaSugestaoCausaService.removerEmojis(tag);
        if (_categorias.length < 2 &&
            tagLimpa != causaPrimaria &&
            causasPossiveis.contains(tagLimpa)) {
          _categorias.add(tagLimpa);
        }
      }

      _formato = ev.cidade.toLowerCase() == "remoto"
          ? "Apenas Remoto (Online)"
          : AppData.formatosVoluntariado.first;
      _cidade = ev.cidade.toLowerCase() == "remoto" ? "Santo André" : ev.cidade;

      _data = ev.dataHoraInicio;
      _inicio = TimeOfDay(
        hour: ev.dataHoraInicio.hour,
        minute: ev.dataHoraInicio.minute,
      );
      _termino = TimeOfDay(
        hour: (ev.dataHoraInicio.hour + 4) % 24,
        minute: ev.dataHoraInicio.minute,
      );

      _requisitos
          .addAll(ev.requisitos.map(IaSugestaoCausaService.removerEmojis));
      _necessidades
          .addAll(ev.necessidades.map(IaSugestaoCausaService.removerEmojis));

      _carregarDadosCompletosEdicao(ev.id);
    } else {
      _nomeController = TextEditingController();
      _descricaoController = TextEditingController();
      _vagasController = TextEditingController(text: "15");
      _bannerUrlController = TextEditingController();
      _cepController = TextEditingController();
      _logradouroController = TextEditingController();
      _numeroController = TextEditingController();
      _bairroController = TextEditingController();
      _pontoReferenciaController = TextEditingController();

      final todasCausas = IaSugestaoCausaService.obterCausasLimpos();
      _categorias = [todasCausas.first];

      _formato = AppData.formatosVoluntariado.first;
      _cidade = SessionService.instance.cidade?.trim().isNotEmpty == true
          ? SessionService.instance.cidade!.trim()
          : "Santo André";

      _data = DateTime.now().add(const Duration(days: 7));
      _inicio = const TimeOfDay(hour: 9, minute: 0);
      _termino = const TimeOfDay(hour: 13, minute: 0);

      final habsIniciais = AppData.habilidadesPorCausa.entries
          .firstWhere(
            (e) =>
                IaSugestaoCausaService.removerEmojis(e.key) ==
                _categorias.first,
            orElse: () => AppData.habilidadesPorCausa.entries.first,
          )
          .value;

      _requisitos.addAll(
        habsIniciais.take(2).map(IaSugestaoCausaService.removerEmojis),
      );

      // Escuta o título para inferência automática de causas via PLN durante a criação
      _nomeController.addListener(_onTituloEventoChanged);
    }
  }

  void _onTituloEventoChanged() {
    if (_isEdicao || _categoriasEditadasManualmente) return;
    final titulo = _nomeController.text.trim();
    if (titulo.length < 4) return;

    final inferidas = IaSugestaoCausaService.inferirCausas(titulo);
    if (inferidas.isNotEmpty) {
      final novas = inferidas.take(2).toList();
      if (novas.join('|') != _categorias.join('|')) {
        setState(() {
          _categorias = novas;
        });
      }
    }
  }

  ({
    String logradouro,
    String numero,
    String bairro,
    String referencia,
  }) _separarEnderecoLegado(String bruto) {
    var texto = bruto.trim();
    String referencia = '';
    final idxRef = texto.indexOf('(Ref:');
    if (idxRef != -1) {
      referencia = texto.substring(idxRef + 5).replaceAll(')', '').trim();
      texto = texto.substring(0, idxRef).trim();
    }

    String bairro = '';
    final partesHifen = texto.split(' - ');
    final ruaENumero = partesHifen.first.trim();
    if (partesHifen.length > 1) {
      bairro = partesHifen[1].trim();
    }

    String logradouro = ruaENumero;
    String numero = '';
    final partesVirgula = ruaENumero.split(',');
    if (partesVirgula.length >= 2) {
      logradouro = partesVirgula.first.trim();
      numero = partesVirgula[1].trim();
    }

    return (
      logradouro: logradouro,
      numero: numero,
      bairro: bairro,
      referencia: referencia,
    );
  }

  Future<void> _carregarDadosCompletosEdicao(String eventoId) async {
    if (eventoId.isEmpty) return;
    if (mounted) setState(() => _carregandoEdicao = true);

    final raw = await _eventService.buscarDetalhesBrutosPorId(
      eventoId,
      token: SessionService.instance.token,
    );

    if (!mounted) return;

    if (raw != null) {
      setState(() {
        final title = (raw['title'] ?? '').toString().trim();
        if (title.isNotEmpty) _nomeController.text = title;

        final desc = (raw['description'] ?? '').toString().trim();
        if (desc.isNotEmpty) _descricaoController.text = desc;

        final vagas = int.tryParse((raw['totalVacancies'] ?? '').toString());
        if (vagas != null && vagas > 0) {
          _vagasController.text = vagas.toString();
        }

        final banner = (raw['banner'] ?? '').toString().trim();
        if (banner.isNotEmpty) _bannerUrlController.text = banner;

        final cepApi = (raw['cep'] ?? '').toString().trim();
        if (cepApi.isNotEmpty) _cepController.text = cepApi;

        final logrApi = (raw['logradouro'] ?? '').toString().trim();
        final numApi = (raw['numero'] ?? '').toString().trim();
        final bairroApi = (raw['bairro'] ?? '').toString().trim();

        if (numApi.isNotEmpty || bairroApi.isNotEmpty) {
          final parsedLogr = _separarEnderecoLegado(logrApi);
          _logradouroController.text = parsedLogr.logradouro;
          _numeroController.text = numApi;
          _bairroController.text = bairroApi;
          if (parsedLogr.referencia.isNotEmpty) {
            _pontoReferenciaController.text = parsedLogr.referencia;
          }
        } else if (logrApi.isNotEmpty) {
          final parsed = _separarEnderecoLegado(logrApi);
          _logradouroController.text = parsed.logradouro;
          if (parsed.numero.isNotEmpty) _numeroController.text = parsed.numero;
          if (parsed.bairro.isNotEmpty) _bairroController.text = parsed.bairro;
          if (parsed.referencia.isNotEmpty) {
            _pontoReferenciaController.text = parsed.referencia;
          }
        }

        final cidadeApi = (raw['cidade'] ?? '').toString().trim();
        if (cidadeApi.isNotEmpty && cidadeApi.toLowerCase() != 'remoto') {
          _cidade = cidadeApi;
        }

        final modApi = (raw['modality'] ?? '').toString().toUpperCase().trim();
        if (modApi == 'REMOTO') {
          _formato = AppData.formatosVoluntariado.firstWhere(
            (f) => f.toLowerCase().contains('remoto'),
            orElse: () => "Apenas Remoto (Online)",
          );
        } else if (modApi == 'HIBRIDO') {
          _formato = AppData.formatosVoluntariado.firstWhere(
            (f) =>
                f.toLowerCase().contains('híbrido') ||
                f.toLowerCase().contains('hibrido'),
            orElse: () => AppData.formatosVoluntariado.first,
          );
        } else if (modApi == 'PRESENCIAL') {
          _formato = AppData.formatosVoluntariado.first;
        }

        final eventDateStr = (raw['eventDate'] ?? '').toString();
        final endDateStr = (raw['endDate'] ?? '').toString();
        final duracaoApi =
            int.tryParse((raw['durationHours'] ?? 4).toString()) ?? 4;

        final dtIni = DateTime.tryParse(eventDateStr)?.toLocal();
        if (dtIni != null) {
          _data = dtIni;
          _inicio = TimeOfDay(hour: dtIni.hour, minute: dtIni.minute);
          final dtFim = DateTime.tryParse(endDateStr)?.toLocal() ??
              dtIni.add(Duration(hours: duracaoApi));
          _termino = TimeOfDay(hour: dtFim.hour, minute: dtFim.minute);
        }

        if (raw['categories'] is List) {
          final causasPossiveis = IaSugestaoCausaService.obterCausasLimpos();
          final catsApi = (raw['categories'] as List)
              .map((c) => IaSugestaoCausaService.removerEmojis(c.toString()))
              .where((c) => causasPossiveis.contains(c))
              .take(2)
              .toList();
          if (catsApi.isNotEmpty) {
            _categorias = catsApi;
          }
        }

        if (raw['requirements'] is List) {
          _requisitos
            ..clear()
            ..addAll((raw['requirements'] as List)
                .map((r) => IaSugestaoCausaService.removerEmojis(r.toString()))
                .where((r) => r.isNotEmpty));
        }

        if (raw['requiredSkills'] is List) {
          _necessidades
            ..clear()
            ..addAll((raw['requiredSkills'] as List)
                .map((s) => IaSugestaoCausaService.removerEmojis(s.toString()))
                .where((s) => s.isNotEmpty));
        }

        _carregandoEdicao = false;
      });
    } else {
      setState(() => _carregandoEdicao = false);
    }
  }

  @override
  void dispose() {
    _nomeController.removeListener(_onTituloEventoChanged);
    _nomeController.dispose();
    _descricaoController.dispose();
    _vagasController.dispose();
    _bannerUrlController.dispose();
    _cepController.dispose();
    _logradouroController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _pontoReferenciaController.dispose();
    super.dispose();
  }

  int _calcularDuracaoHoras() {
    final iniMin = _inicio.hour * 60 + _inicio.minute;
    final fimMin = _termino.hour * 60 + _termino.minute;
    final diff = fimMin - iniMin;
    if (diff <= 0) return 4;
    return (diff / 60).ceil();
  }

  DateTime _calcularDataHoraTermino(DateTime inicio) {
    final fim = DateTime(
      inicio.year,
      inicio.month,
      inicio.day,
      _termino.hour,
      _termino.minute,
    );
    if (!fim.isAfter(inicio)) {
      return inicio.add(Duration(hours: _calcularDuracaoHoras()));
    }
    return fim;
  }

  CriarEventoDTO _gerarDTO() {
    final horaInicio =
        "${_inicio.hour.toString().padLeft(2, '0')}:${_inicio.minute.toString().padLeft(2, '0')}";
    final horaTermino =
        "${_termino.hour.toString().padLeft(2, '0')}:${_termino.minute.toString().padLeft(2, '0')}";
    final dataStr =
        "${_data.day.toString().padLeft(2, '0')}/${_data.month.toString().padLeft(2, '0')}/${_data.year}";

    final pontoRef = _pontoReferenciaController.text.trim();
    final complementoRef = pontoRef.isNotEmpty ? " (Ref: $pontoRef)" : "";

    final logradouro = _logradouroController.text.trim();
    final numero = _numeroController.text.trim();
    final bairro = _bairroController.text.trim();

    String endereco;
    if (_isRemoto) {
      endereco = "Remoto / Online";
    } else if (numero.isEmpty && bairro.isEmpty) {
      endereco = "$logradouro$complementoRef";
    } else {
      endereco = "$logradouro, $numero - $bairro$complementoRef";
    }

    final causaPrincipal =
        _categorias.isNotEmpty ? _categorias.first : "Assistência social";

    return CriarEventoDTO(
      ongId: _ongIdEfetivo,
      ongNome: _ongNomeEfetivo,
      titulo: _nomeController.text.trim(),
      categoria: causaPrincipal,
      descricao: _descricaoController.text.trim(),
      cidade: _isRemoto ? "Remoto" : _cidade,
      endereco: endereco,
      data: dataStr,
      horario: "$horaInicio - $horaTermino",
      horarioInicio: horaInicio,
      horarioTermino: horaTermino,
      dataHoraInicio: DateTime(
        _data.year,
        _data.month,
        _data.day,
        _inicio.hour,
        _inicio.minute,
      ),
      imagemUrl: _bannerUrlController.text.trim(),
      tags: _categorias.toList(),
      vagasTotais: int.tryParse(_vagasController.text) ?? 15,
      requisitos: _requisitos.toList(),
      necessidades: _necessidades.toList(),
      emiteCertificado: true,
    );
  }

  Future<void> _submeterAcao() async {
    if (!_formKey.currentState!.validate()) return;
    final dto = _gerarDTO();
    final duracaoHoras = _calcularDuracaoHoras();
    final dataFim = _calcularDataHoraTermino(dto.dataHoraInicio);
    final modalidade = _modalidadeApi;

    final String cepLimpo = _cepController.text.trim();
    final String pontoRef = _pontoReferenciaController.text.trim();
    final String logradouroComRef = pontoRef.isNotEmpty
        ? "${_logradouroController.text.trim()} (Ref: $pontoRef)"
        : _logradouroController.text.trim();
    final String numeroLimpo = _numeroController.text.trim();
    final String bairroLimpo = _bairroController.text.trim();

    if (_isEdicao) {
      setState(() => _salvando = true);
      try {
        final payload = <String, dynamic>{
          "title": dto.titulo,
          "description": dto.descricao,
          "modality": modalidade,
          "banner": dto.imagemUrl,
          "eventDate": dto.dataHoraInicio.toUtc().toIso8601String(),
          "endDate": dataFim.toUtc().toIso8601String(),
          "durationHours": duracaoHoras,
          "totalVacancies": dto.vagasTotais,
          "categories": _categorias.toList(),
          "requiredSkills": dto.necessidades,
          "requirements": dto.requisitos,
          if (!_isRemoto && cepLimpo.isNotEmpty) "cep": cepLimpo,
          if (!_isRemoto) "logradouro": logradouroComRef,
          if (!_isRemoto && numeroLimpo.isNotEmpty) "numero": numeroLimpo,
          if (!_isRemoto && bairroLimpo.isNotEmpty) "bairro": bairroLimpo,
          "cidade": dto.cidade,
          if (!_isRemoto) "estado": "SP",
        };

        final atualizado = await _eventService.atualizarEvento(
          widget.eventoParaEditar!.id,
          payload,
          token: SessionService.instance.token,
        );

        if (!mounted) return;
        setState(() => _salvando = false);

        if (atualizado != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Evento atualizado com sucesso!"),
              backgroundColor: Color(0xFF0C6B6B),
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Não foi possível atualizar o evento."),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } else {
      RevisaoCriarEventoDialog.exibir(
        context,
        dto: dto,
        onConfirmar: (dtoConfirmado, canais) async {
          setState(() => _salvando = true);
          try {
            final criado = await _eventService.criarEvento(
              dtoConfirmado,
              modality: modalidade,
              durationHours: duracaoHoras,
              endDate: dataFim,
              cep: _isRemoto ? null : cepLimpo,
              logradouro: _isRemoto ? "Remoto / Online" : logradouroComRef,
              numero: _isRemoto ? null : numeroLimpo,
              bairro: _isRemoto ? null : bairroLimpo,
              estado: "SP",
              token: SessionService.instance.token,
            );
            if (!mounted) return;
            setState(() => _salvando = false);

            if (criado != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Evento '${dtoConfirmado.titulo}' cadastrado com sucesso!",
                  ),
                  backgroundColor: const Color(0xFF0C6B6B),
                ),
              );
              Navigator.pop(context, true);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "A API não confirmou o cadastro. Verifique os campos e tente novamente.",
                  ),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          } catch (e) {
            if (!mounted) return;
            setState(() => _salvando = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Erro ao cadastrar evento: ${e.toString().replaceAll('Exception: ', '')}",
                ),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isDesktop = Responsive.isDesktop(context);
    final idAtual = _ongIdEfetivo;

    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF7),
      bottomNavigationBar: isMobile
          ? AppBottomNav(
              currentIndex: 4,
              usuarioId: idAtual,
              tipoUsuario: widget.tipoUsuario,
            )
          : null,
      body: Row(
        children: [
          if (isDesktop)
            AppSidebar(
              currentIndex: 4,
              usuarioId: idAtual,
              tipoUsuario: widget.tipoUsuario,
            ),
          Expanded(
            child: Column(
              children: [
                AppHeader(
                  usuarioId: idAtual,
                  tipoUsuario: widget.tipoUsuario,
                  nomeUsuario: _ongNomeEfetivo,
                  fotoPerfilUrl: SessionService.instance.fotoUrl,
                  showBackButton: true,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 14 : 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _isEdicao
                                          ? "Editar evento"
                                          : "Cadastrar novo evento",
                                      style: TextStyle(
                                        fontSize: isMobile ? 22 : 26,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF062222),
                                      ),
                                    ),
                                  ),
                                  if (_carregandoEdicao)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF0C6B6B),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // 1. Dados Básicos com suporte a até 2 causas
                              SecaoDadosBasicos(
                                nomeCtrl: _nomeController,
                                descCtrl: _descricaoController,
                                categoriasSelecionadas: _categorias,
                                formato: _formato,
                                onCategoriasChanged: (novas) => setState(() {
                                  _categoriasEditadasManualmente = true;
                                  _categorias = novas;
                                }),
                                onFormatoChanged: (v) =>
                                    setState(() => _formato = v),
                              ),
                              const SizedBox(height: 14),

                              // 2. Data, Horário e Vagas
                              SecaoDataVagas(
                                data: _data,
                                inicio: _inicio,
                                termino: _termino,
                                vagasCtrl: _vagasController,
                                onDataChanged: (d) => setState(() => _data = d),
                                onInicioChanged: (h) =>
                                    setState(() => _inicio = h),
                                onTerminoChanged: (h) =>
                                    setState(() => _termino = h),
                              ),
                              const SizedBox(height: 14),

                              // 3. Localização com ViaCEP e Ponto de Referência
                              if (!_isRemoto) ...[
                                SecaoLocalizacaoCep(
                                  cepCtrl: _cepController,
                                  logradouroCtrl: _logradouroController,
                                  numeroCtrl: _numeroController,
                                  bairroCtrl: _bairroController,
                                  pontoReferenciaCtrl:
                                      _pontoReferenciaController,
                                  cidade: _cidade,
                                  isEdicao: _isEdicao,
                                  onCidadeChanged: (c) =>
                                      setState(() => _cidade = c),
                                ),
                                const SizedBox(height: 14),
                              ],

                              // 4 e 5. Habilidades e Necessidades
                              SecaoChipsAppData(
                                categorias: _categorias,
                                requisitos: _requisitos,
                                necessidades: _necessidades,
                              ),
                              const SizedBox(height: 14),

                              // 6. Capa do Evento
                              SecaoFotoCapa(
                                bannerUrlCtrl: _bannerUrlController,
                                tituloEvento: _nomeController.text.trim(),
                                categorias: _categorias,
                                permitirFallbackLocal:
                                    true, // mude para false quando a rota real estiver ativa
                                onFotoAlterada: () => setState(() {}),
                              ),
                              const SizedBox(height: 24),

                              // Botão Final de Submissão
                              ElevatedButton(
                                onPressed: _salvando ? null : _submeterAcao,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0C6B6B),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
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
                                    : Text(
                                        _isEdicao
                                            ? "Salvar Alterações"
                                            : "Criar Evento",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
