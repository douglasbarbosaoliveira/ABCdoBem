// lib/ongs/painel_geral/widgets/metas_instituicao_page.dart

import 'package:flutter/material.dart';

import '../../../services/session_service.dart';
import '../../../utils/responsive.dart';
import '../../../widgets/bottom_nav/app_bottom_nav.dart';
import '../../../widgets/header/app_header.dart';
import '../../../widgets/sidebar/app_sidebar.dart';
import '../../services/ong_painel_service.dart';

enum _FiltroMetas { todas, emAndamento, concluidas }

class _PeriodoMeta {
  final DateTime inicio;
  final DateTime fim;

  const _PeriodoMeta({required this.inicio, required this.fim});
}

class OngMetasInstituicaoPage extends StatefulWidget {
  final String ongId;
  final String tipoUsuario;
  final OngPainelDados? dadosIniciais;
  final OngMetaItem? metaInicialParaEditar;
  final bool abrirNovoAoIniciar;
  final bool usarFallbackVisual;
  final Future<void> Function(
    OngMetaItem meta, {
    required bool isEdicao,
    DateTime? dataInicio,
    DateTime? dataFim,
  })? onSalvarMetaApi;
  final Future<void> Function(String metaId)? onExcluirMetaApi;

  const OngMetasInstituicaoPage({
    super.key,
    required this.ongId,
    this.tipoUsuario = "ong",
    this.dadosIniciais,
    this.metaInicialParaEditar,
    this.abrirNovoAoIniciar = false,
    this.usarFallbackVisual = true,
    this.onSalvarMetaApi,
    this.onExcluirMetaApi,
  });

  @override
  State<OngMetasInstituicaoPage> createState() =>
      _OngMetasInstituicaoPageState();
}

class _OngMetasInstituicaoPageState extends State<OngMetasInstituicaoPage> {
  static const Color _corVerde = Color(0xFF0C6B6B);
  static const Color _corFundoSuave = Color(0xFFF0FAF7);
  static const Color _corBordaSuave = Color(0xFFC2E4DC);
  static const Color _corTextoEscuro = Color(0xFF062222);
  static const Color _corTextoSecundario = Color(0xFF4C7A70);

  final OngPainelService _painelService = OngPainelService();
  final TextEditingController _buscaController = TextEditingController();

  List<OngMetaItem> _metas = <OngMetaItem>[];
  final Map<String, _PeriodoMeta> _periodosPorMetaId = <String, _PeriodoMeta>{};
  String _nomeOng = 'ONG';
  String? _avatarOng;
  bool _carregando = false;
  bool _usandoFallbackAtivo = false;
  String _termoBusca = '';
  _FiltroMetas _filtro = _FiltroMetas.todas;
  bool _executouAcaoInicial = false;

  String get _idResolvido {
    final param = widget.ongId.trim();
    if (param.isNotEmpty) return param;
    return SessionService.instance.usuarioId?.trim() ?? '';
  }

  _PeriodoMeta _periodoPadraoParaIndice(int index) {
    final base = DateTime.now();
    final inicio = DateTime(base.year, base.month, 1);
    final fim = DateTime(base.year, base.month + 1 + index, 0);
    return _PeriodoMeta(inicio: inicio, fim: fim);
  }

  List<OngMetaItem> get _metasFallback => const <OngMetaItem>[
        OngMetaItem(
          id: "mock-meta-1",
          titulo: "Horas de voluntariado no mês",
          valorAtual: 84,
          valorMeta: 120,
          unidade: "h",
        ),
        OngMetaItem(
          id: "mock-meta-2",
          titulo: "Famílias atendidas nas ações",
          valorAtual: 45,
          valorMeta: 60,
          unidade: "famílias",
        ),
        OngMetaItem(
          id: "mock-meta-3",
          titulo: "Voluntários recorrentes (2+ ações)",
          valorAtual: 14,
          valorMeta: 20,
          unidade: "voluntários",
        ),
        OngMetaItem(
          id: "mock-meta-4",
          titulo: "Cestas básicas arrecadadas",
          valorAtual: 100,
          valorMeta: 100,
          unidade: "cestas",
        ),
      ];

  void _garantirPeriodos(List<OngMetaItem> lista) {
    for (var i = 0; i < lista.length; i++) {
      final meta = lista[i];
      if (meta.id.isNotEmpty && !_periodosPorMetaId.containsKey(meta.id)) {
        _periodosPorMetaId[meta.id] = _periodoPadraoParaIndice(i);
      }
    }
  }

  String _formatarData(DateTime dt) {
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    return "$dia/$mes/${dt.year}";
  }

  String _textoPeriodoMeta(OngMetaItem meta) {
    final periodo = _periodosPorMetaId[meta.id] ?? _periodoPadraoParaIndice(0);
    return "${_formatarData(periodo.inicio)} até ${_formatarData(periodo.fim)}";
  }

  @override
  void initState() {
    super.initState();
    final inicial = widget.dadosIniciais;
    if (inicial != null) {
      _nomeOng = inicial.nomeOng.isNotEmpty ? inicial.nomeOng : 'ONG';
      _avatarOng = inicial.avatarOng;
      if (inicial.metas.isNotEmpty) {
        _metas = List<OngMetaItem>.from(inicial.metas);
        _garantirPeriodos(_metas);
      }
    }
    _carregarMetas().then((_) {
      if (mounted && !_executouAcaoInicial) {
        _executouAcaoInicial = true;
        if (widget.metaInicialParaEditar != null) {
          _abrirFormularioMeta(metaExistente: widget.metaInicialParaEditar);
        } else if (widget.abrirNovoAoIniciar) {
          _abrirFormularioMeta();
        }
      }
    });
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarMetas() async {
    if (_idResolvido.isEmpty) {
      if (widget.usarFallbackVisual && _metas.isEmpty) {
        final mock = _metasFallback;
        _garantirPeriodos(mock);
        setState(() {
          _metas = mock;
          _usandoFallbackAtivo = true;
        });
      }
      return;
    }

    setState(() => _carregando = true);
    try {
      final dados = await _painelService.carregarPainelOng(
        _idResolvido,
        ultimos30Dias: false,
      );
      if (!mounted) return;

      final listaApi = List<OngMetaItem>.from(dados.metas);
      final usarMock = listaApi.isEmpty && widget.usarFallbackVisual;
      final efetiva = usarMock ? _metasFallback : listaApi;
      _garantirPeriodos(efetiva);

      setState(() {
        _nomeOng = dados.nomeOng.isNotEmpty ? dados.nomeOng : _nomeOng;
        _avatarOng = dados.avatarOng ?? _avatarOng;
        _metas = efetiva;
        _usandoFallbackAtivo = usarMock;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      final usarMock = _metas.isEmpty && widget.usarFallbackVisual;
      if (usarMock) {
        final mock = _metasFallback;
        _garantirPeriodos(mock);
      }
      setState(() {
        if (usarMock) {
          _metas = _metasFallback;
          _usandoFallbackAtivo = true;
        }
        _carregando = false;
      });
    }
  }

  Future<void> _persistirMetaNaApi(
    OngMetaItem meta, {
    required bool isEdicao,
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    if (widget.onSalvarMetaApi != null) {
      await widget.onSalvarMetaApi!(
        meta,
        isEdicao: isEdicao,
        dataInicio: dataInicio,
        dataFim: dataFim,
      );
      return;
    }

    final dynamic servico = _painelService;
    try {
      if (isEdicao) {
        await servico.atualizarMetaOng(
          _idResolvido,
          meta,
          dataInicio: dataInicio,
          dataFim: dataFim,
        );
      } else {
        await servico.criarMetaOng(
          _idResolvido,
          meta,
          dataInicio: dataInicio,
          dataFim: dataFim,
        );
      }
    } on NoSuchMethodError {
      // Método ainda não implementado no serviço: mantém estado local/fallback.
    }
  }

  Future<void> _removerMetaNaApi(String metaId) async {
    if (widget.onExcluirMetaApi != null) {
      await widget.onExcluirMetaApi!(metaId);
      return;
    }

    final dynamic servico = _painelService;
    try {
      await servico.excluirMetaOng(_idResolvido, metaId);
    } on NoSuchMethodError {
      // Método ainda não implementado no serviço: mantém estado local/fallback.
    }
  }

  double _calcularPercentual(OngMetaItem meta) {
    if (meta.valorMeta <= 0) return 0.0;
    return (meta.valorAtual / meta.valorMeta).clamp(0.0, 1.0);
  }

  bool _isConcluida(OngMetaItem meta) {
    return meta.valorMeta > 0 && meta.valorAtual >= meta.valorMeta;
  }

  String _formatarValor(double valor) {
    if (valor == valor.roundToDouble()) {
      return valor.toInt().toString();
    }
    return valor.toStringAsFixed(1);
  }

  List<OngMetaItem> get _metasFiltradas {
    final termo = _termoBusca.trim().toLowerCase();
    return _metas.where((meta) {
      if (_filtro == _FiltroMetas.emAndamento && _isConcluida(meta)) {
        return false;
      }
      if (_filtro == _FiltroMetas.concluidas && !_isConcluida(meta)) {
        return false;
      }
      if (termo.isNotEmpty && !meta.titulo.toLowerCase().contains(termo)) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _incrementarAndamento(OngMetaItem meta, double delta) async {
    final novoAtual = (meta.valorAtual + delta).clamp(0.0, meta.valorMeta * 2);
    final atualizada = OngMetaItem(
      id: meta.id,
      titulo: meta.titulo,
      valorAtual: novoAtual,
      valorMeta: meta.valorMeta,
      unidade: meta.unidade,
    );
    final periodo = _periodosPorMetaId[meta.id] ?? _periodoPadraoParaIndice(0);

    setState(() {
      _metas = _metas.map((m) => m.id == meta.id ? atualizada : m).toList();
    });

    try {
      await _persistirMetaNaApi(
        atualizada,
        isEdicao: true,
        dataInicio: periodo.inicio,
        dataFim: periodo.fim,
      );
    } catch (_) {}
  }

  Future<void> _excluirMeta(OngMetaItem meta) async {
    setState(() {
      _metas = _metas.where((m) => m.id != meta.id).toList();
      _periodosPorMetaId.remove(meta.id);
    });

    try {
      await _removerMetaNaApi(meta.id);
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Meta removida."),
        backgroundColor: _corVerde,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _abrirFormularioMeta({OngMetaItem? metaExistente}) async {
    final isEdicao = metaExistente != null;
    final periodoInicial = metaExistente != null
        ? (_periodosPorMetaId[metaExistente.id] ?? _periodoPadraoParaIndice(0))
        : _periodoPadraoParaIndice(0);

    final tituloCtrl = TextEditingController(text: metaExistente?.titulo ?? '');
    final atualCtrl = TextEditingController(
      text: metaExistente != null
          ? _formatarValor(metaExistente.valorAtual)
          : '0',
    );
    final alvoCtrl = TextEditingController(
      text: metaExistente != null
          ? _formatarValor(metaExistente.valorMeta)
          : '50',
    );
    final unidadeCtrl =
        TextEditingController(text: metaExistente?.unidade ?? 'h');

    DateTime dataInicio = periodoInicial.inicio;
    DateTime dataFim = periodoInicial.fim;

    final salva = await showModalBottomSheet<(OngMetaItem, _PeriodoMeta)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            Future<void> escolherInicio() async {
              final picked = await showDatePicker(
                context: ctx,
                initialDate: dataInicio,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) {
                setModalState(() {
                  dataInicio = picked;
                  if (dataFim.isBefore(dataInicio)) {
                    dataFim = dataInicio.add(const Duration(days: 30));
                  }
                });
              }
            }

            Future<void> escolherFim() async {
              final picked = await showDatePicker(
                context: ctx,
                initialDate:
                    dataFim.isBefore(dataInicio) ? dataInicio : dataFim,
                firstDate: dataInicio,
                lastDate: DateTime(2035),
              );
              if (picked != null) {
                setModalState(() => dataFim = picked);
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  14,
                  20,
                  MediaQuery.of(ctx).viewInsets.bottom + 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _corBordaSuave,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isEdicao ? "Editar Meta" : "Nova Meta Institucional",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _corTextoEscuro,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: tituloCtrl,
                        decoration: const InputDecoration(
                          labelText: "Título da meta",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: atualCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                labelText: "Andamento atual",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: alvoCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                labelText: "Valor meta",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: unidadeCtrl,
                              decoration: const InputDecoration(
                                labelText: "Unidade (ex.: h)",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: escolherInicio,
                              icon: const Icon(Icons.calendar_today_rounded,
                                  size: 14, color: _corVerde),
                              label: Text(
                                "Início: ${_formatarData(dataInicio)}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _corTextoEscuro,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: _corBordaSuave),
                                backgroundColor: _corFundoSuave,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: escolherFim,
                              icon: const Icon(Icons.event_available_rounded,
                                  size: 14, color: _corVerde),
                              label: Text(
                                "Fim: ${_formatarData(dataFim)}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _corTextoEscuro,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: _corBordaSuave),
                                backgroundColor: _corFundoSuave,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          final titulo = tituloCtrl.text.trim();
                          if (titulo.isEmpty) return;

                          final alvo = (double.tryParse(alvoCtrl.text
                                      .trim()
                                      .replaceAll(',', '.')) ??
                                  10)
                              .clamp(1.0, 9999999.0);
                          final atual = (double.tryParse(atualCtrl.text
                                      .trim()
                                      .replaceAll(',', '.')) ??
                                  0)
                              .clamp(0.0, 9999999.0);

                          final modelo = OngMetaItem(
                            id: metaExistente?.id.isNotEmpty == true
                                ? metaExistente!.id
                                : "meta-${DateTime.now().millisecondsSinceEpoch}",
                            titulo: titulo,
                            valorAtual: atual,
                            valorMeta: alvo,
                            unidade: unidadeCtrl.text.trim(),
                          );
                          Navigator.of(ctx).pop(
                            (
                              modelo,
                              _PeriodoMeta(inicio: dataInicio, fim: dataFim)
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _corVerde,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          isEdicao ? "Salvar Meta" : "Adicionar Meta",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    tituloCtrl.dispose();
    atualCtrl.dispose();
    alvoCtrl.dispose();
    unidadeCtrl.dispose();

    if (salva == null || !mounted) return;

    final metaSalva = salva.$1;
    final periodoSalvo = salva.$2;

    setState(() {
      _periodosPorMetaId[metaSalva.id] = periodoSalvo;
      if (isEdicao) {
        _metas = _metas
            .map((item) => item.id == metaExistente.id ? metaSalva : item)
            .toList();
      } else {
        _metas = <OngMetaItem>[metaSalva, ..._metas];
      }
    });

    try {
      await _persistirMetaNaApi(
        metaSalva,
        isEdicao: isEdicao,
        dataInicio: periodoSalvo.inicio,
        dataFim: periodoSalvo.fim,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isDesktop = Responsive.isDesktop(context);
    final lista = _metasFiltradas;

    final concluidasCount = _metas.where(_isConcluida).length;
    final mediaPct = _metas.isEmpty
        ? 0
        : ((_metas.fold<double>(0, (acc, m) => acc + _calcularPercentual(m)) /
                    _metas.length) *
                100)
            .round();

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Quicksand'),
      ),
      child: Scaffold(
        backgroundColor: _corFundoSuave,
        bottomNavigationBar: isMobile
            ? AppBottomNav(
                currentIndex: 4,
                usuarioId: _idResolvido,
                tipoUsuario: widget.tipoUsuario,
              )
            : null,
        body: Row(
          children: [
            if (isDesktop)
              AppSidebar(
                currentIndex: 4,
                usuarioId: _idResolvido,
                tipoUsuario: widget.tipoUsuario,
              ),
            Expanded(
              child: Column(
                children: [
                  AppHeader(
                    usuarioId: _idResolvido,
                    tipoUsuario: widget.tipoUsuario,
                    nomeUsuario: _nomeOng,
                    fotoPerfilUrl: _avatarOng,
                    showBackButton: true,
                  ),
                  Expanded(
                    child: _carregando && _metas.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: _corVerde,
                            ),
                          )
                        : RefreshIndicator(
                            color: _corVerde,
                            onRefresh: _carregarMetas,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 12 : 24,
                                vertical: isMobile ? 14 : 20,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 920),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildCabecalhoMetas(isMobile: isMobile),
                                      const SizedBox(height: 12),
                                      _buildResumoMetas(
                                        total: _metas.length,
                                        concluidas: concluidasCount,
                                        mediaPct: mediaPct,
                                      ),
                                      const SizedBox(height: 12),
                                      if (lista.isEmpty)
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                                color: _corBordaSuave),
                                          ),
                                          child: const Text(
                                            "Nenhuma meta encontrada para o filtro atual.",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: _corTextoSecundario,
                                            ),
                                          ),
                                        )
                                      else
                                        ...lista.map(
                                          (meta) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 10),
                                            child: _buildCardMeta(meta: meta),
                                          ),
                                        ),
                                      const SizedBox(height: 28),
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
      ),
    );
  }

  Widget _buildCabecalhoMetas({required bool isMobile}) {
    const filtros = [
      (_FiltroMetas.todas, "Todas"),
      (_FiltroMetas.emAndamento, "Em andamento"),
      (_FiltroMetas.concluidas, "Concluídas"),
    ];

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _corBordaSuave),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: _corVerde, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Metas da Instituição",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _corTextoEscuro,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _abrirFormularioMeta(),
                icon: const Icon(Icons.add_rounded,
                    size: 15, color: Colors.white),
                label: const Text(
                  "Nova Meta",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _corVerde,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          if (_usandoFallbackAtivo) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _corFundoSuave,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _corBordaSuave),
              ),
              child: const Text(
                "Exibição de fallback ativa: simule andamentos, crie ou edite metas enquanto a API não retorna dados.",
                style: TextStyle(fontSize: 10, color: _corTextoSecundario),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _buscaController,
            onChanged: (val) => setState(() => _termoBusca = val),
            decoration: InputDecoration(
              hintText: "Buscar meta por título...",
              hintStyle:
                  const TextStyle(fontSize: 12, color: Color(0xFF6B8E87)),
              prefixIcon:
                  const Icon(Icons.search_rounded, color: _corVerde, size: 18),
              isDense: true,
              filled: true,
              fillColor: _corFundoSuave,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _corBordaSuave),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _corBordaSuave),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filtros.map((item) {
              final ativo = _filtro == item.$1;
              return ChoiceChip(
                label: Text(
                  item.$2,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: ativo ? Colors.white : _corVerde,
                  ),
                ),
                selected: ativo,
                selectedColor: _corVerde,
                backgroundColor: _corFundoSuave,
                side: BorderSide(color: ativo ? _corVerde : _corBordaSuave),
                onSelected: (sel) {
                  if (sel) setState(() => _filtro = item.$1);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoMetas({
    required int total,
    required int concluidas,
    required int mediaPct,
  }) {
    Widget item(String valor, String rotulo) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _corBordaSuave),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _corVerde,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                rotulo,
                style: const TextStyle(
                  fontSize: 10,
                  color: _corTextoSecundario,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        item("$total", "Total de metas"),
        const SizedBox(width: 8),
        item("$concluidas", "Concluídas"),
        const SizedBox(width: 8),
        item("$mediaPct%", "Progresso médio"),
      ],
    );
  }

  Widget _buildCardMeta({required OngMetaItem meta}) {
    final pct = _calcularPercentual(meta);
    final atualFmt = _formatarValor(meta.valorAtual);
    final alvoFmt = _formatarValor(meta.valorMeta);
    final sufixo =
        meta.unidade.trim().isNotEmpty ? " ${meta.unidade.trim()}" : "";
    final periodoTexto = _textoPeriodoMeta(meta);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _corBordaSuave),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  meta.titulo.isNotEmpty ? meta.titulo : "Meta institucional",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _corTextoEscuro,
                  ),
                ),
              ),
              Text(
                "${(pct * 100).round()}%",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _corVerde,
                ),
              ),
              IconButton(
                tooltip: "Editar meta",
                icon:
                    const Icon(Icons.edit_outlined, size: 18, color: _corVerde),
                onPressed: () => _abrirFormularioMeta(metaExistente: meta),
              ),
            ],
          ),
          Text(
            "$atualFmt de $alvoFmt$sufixo",
            style: const TextStyle(fontSize: 11, color: _corTextoSecundario),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.date_range_rounded,
                  size: 12, color: _corTextoSecundario),
              const SizedBox(width: 4),
              Text(
                periodoTexto,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _corTextoSecundario,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 7,
              backgroundColor: _corFundoSuave,
              color: _corVerde,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => _incrementarAndamento(meta, 1),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _corBordaSuave),
                  backgroundColor: _corFundoSuave,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                child: const Text(
                  "+1",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _corVerde,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                onPressed: () => _incrementarAndamento(meta, 5),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _corBordaSuave),
                  backgroundColor: _corFundoSuave,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                child: const Text(
                  "+5",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _corVerde,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: "Excluir meta",
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: Colors.redAccent),
                onPressed: () => _excluirMeta(meta),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
