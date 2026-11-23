// lib/ongs/painel_geral/gestao_acoes_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/session_service.dart';
import '../../../utils/responsive.dart';
import '../../../widgets/bottom_nav/app_bottom_nav.dart';
import '../../../widgets/header/app_header.dart';
import '../../../widgets/sidebar/app_sidebar.dart';
import '../../services/ong_painel_service.dart';

enum _FiltroStatusAcao { todas, ativas, concluidas }

class OngGestaoAcoesPage extends StatefulWidget {
  final String ongId;
  final String tipoUsuario;
  final OngPainelDados? dadosIniciais;
  final OngAcaoResumo? acaoInicialParaEditar;
  final bool usarFallbackVisual;
  final Future<void> Function(OngAcaoResumo acao, {required bool isEdicao})?
      onSalvarApi;
  final Future<void> Function(String acaoId)? onExcluirApi;
  final Future<void> Function(OngAcaoResumo acao, String textoCompartilhado)?
      onCompartilharApi;

  const OngGestaoAcoesPage({
    super.key,
    required this.ongId,
    this.tipoUsuario = "ong",
    this.dadosIniciais,
    this.acaoInicialParaEditar,
    this.usarFallbackVisual = true,
    this.onSalvarApi,
    this.onExcluirApi,
    this.onCompartilharApi,
  });

  @override
  State<OngGestaoAcoesPage> createState() => _OngGestaoAcoesPageState();
}

class _OngGestaoAcoesPageState extends State<OngGestaoAcoesPage> {
  final OngPainelService _painelService = OngPainelService();
  final TextEditingController _buscaController = TextEditingController();

  List<OngAcaoResumo> _acoes = <OngAcaoResumo>[];
  String _nomeOng = 'ONG';
  String? _avatarOng;
  bool _carregando = false;
  bool _usandoFallbackAtivo = false;
  String _termoBusca = '';
  _FiltroStatusAcao _filtro = _FiltroStatusAcao.todas;
  bool _abriuEdicaoInicial = false;

  String get _idResolvido {
    final param = widget.ongId.trim();
    if (param.isNotEmpty) return param;
    return SessionService.instance.usuarioId?.trim() ?? '';
  }

  List<OngAcaoResumo> get _acoesFallback => <OngAcaoResumo>[
        OngAcaoResumo(
          id: "acao-fallback-1",
          titulo: "Mutirão de Alimentos e Cestas Básicas",
          dataEvento: DateTime.now().add(const Duration(days: 3)),
          dataFormatada: "Dom, 22/Nov",
          horarioFormatado: "08:30",
          duracaoHoras: 4,
          vagasOcupadas: 14,
          vagasTotais: 20,
          status: "Ativa",
        ),
        OngAcaoResumo(
          id: "acao-fallback-2",
          titulo: "Oficina de Reforço Escolar e Leitura",
          dataEvento: DateTime.now().add(const Duration(days: 7)),
          dataFormatada: "Qui, 26/Nov",
          horarioFormatado: "14:00",
          duracaoHoras: 3,
          vagasOcupadas: 8,
          vagasTotais: 10,
          status: "Ativa",
        ),
        OngAcaoResumo(
          id: "acao-fallback-3",
          titulo: "Aferição e Cuidado com Idosos",
          dataEvento: DateTime.now().subtract(const Duration(days: 5)),
          dataFormatada: "Sáb, 14/Nov",
          horarioFormatado: "09:00",
          duracaoHoras: 5,
          vagasOcupadas: 12,
          vagasTotais: 12,
          status: "Concluída",
        ),
      ];

  @override
  void initState() {
    super.initState();
    final inicial = widget.dadosIniciais;
    if (inicial != null) {
      _nomeOng = inicial.nomeOng.isNotEmpty ? inicial.nomeOng : 'ONG';
      _avatarOng = inicial.avatarOng;
      if (inicial.acoes.isNotEmpty) {
        _acoes = List<OngAcaoResumo>.from(inicial.acoes);
      }
    }
    _carregarAcoes().then((_) {
      if (mounted &&
          !_abriuEdicaoInicial &&
          widget.acaoInicialParaEditar != null) {
        _abriuEdicaoInicial = true;
        _abrirFormularioAcao(acaoExistente: widget.acaoInicialParaEditar);
      }
    });
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarAcoes() async {
    if (_idResolvido.isEmpty) {
      if (widget.usarFallbackVisual && _acoes.isEmpty) {
        setState(() {
          _acoes = _acoesFallback;
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

      final listaApi = List<OngAcaoResumo>.from(dados.acoes);
      final usarMock = listaApi.isEmpty && widget.usarFallbackVisual;

      setState(() {
        _nomeOng = dados.nomeOng.isNotEmpty ? dados.nomeOng : _nomeOng;
        _avatarOng = dados.avatarOng ?? _avatarOng;
        _acoes = usarMock ? _acoesFallback : listaApi;
        _usandoFallbackAtivo = usarMock;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      final usarMock = _acoes.isEmpty && widget.usarFallbackVisual;
      setState(() {
        if (usarMock) {
          _acoes = _acoesFallback;
          _usandoFallbackAtivo = true;
        }
        _carregando = false;
      });
    }
  }

  bool _isConcluida(OngAcaoResumo acao) {
    final st = acao.status.trim().toLowerCase();
    return st.contains('conclu') ||
        st.contains('encerr') ||
        st.contains('final');
  }

  List<OngAcaoResumo> get _acoesFiltradas {
    final termo = _termoBusca.trim().toLowerCase();
    return _acoes.where((acao) {
      if (_filtro == _FiltroStatusAcao.ativas && _isConcluida(acao)) {
        return false;
      }
      if (_filtro == _FiltroStatusAcao.concluidas && !_isConcluida(acao)) {
        return false;
      }
      if (termo.isNotEmpty && !acao.titulo.toLowerCase().contains(termo)) {
        return false;
      }
      return true;
    }).toList();
  }

  String _montarTextoCompartilhamento(OngAcaoResumo acao) {
    final vagasLivres =
        (acao.vagasTotais - acao.vagasOcupadas).clamp(0, acao.vagasTotais);
    final dataParte = [
      if (acao.dataFormatada.isNotEmpty) acao.dataFormatada,
      if (acao.horarioFormatado.isNotEmpty) acao.horarioFormatado,
    ].join(' às ');

    final linhas = <String>[
      "Participe da ação: ${acao.titulo}",
      "Instituição: $_nomeOng",
      if (dataParte.isNotEmpty) "Quando: $dataParte (${acao.duracaoHoras}h)",
      "Vagas disponíveis: $vagasLivres de ${acao.vagasTotais}",
      if (acao.id.isNotEmpty) "Código da ação: ${acao.id}",
    ];
    return linhas.join('\n');
  }

  Future<void> _compartilharAcao(OngAcaoResumo acao) async {
    final texto = _montarTextoCompartilhamento(acao);
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: texto));

    if (widget.onCompartilharApi != null) {
      try {
        await widget.onCompartilharApi!(acao, texto);
      } catch (_) {}
    }

    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5D5B0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Row(
                  children: [
                    Icon(Icons.share_rounded,
                        color: Color(0xFFD46B08), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Compartilhar Ação",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3B1D04),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  "O convite foi copiado para a área de transferência. Revise ou copie novamente abaixo:",
                  style: TextStyle(fontSize: 11, color: Color(0xFF7A5433)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7EE),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF5D5B0)),
                  ),
                  child: SelectableText(
                    texto,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF3B1D04),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: texto));
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text("Texto da ação copiado."),
                              backgroundColor: Color(0xFF0C6B6B),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded,
                            size: 16, color: Color(0xFF0C6B6B)),
                        label: const Text(
                          "Copiar texto",
                          style: TextStyle(
                            color: Color(0xFF0C6B6B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF0C6B6B)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD46B08),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Concluir",
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
        );
      },
    );
  }

  Future<void> _alternarStatusAcao(OngAcaoResumo acao) async {
    final novoStatus = _isConcluida(acao) ? "Ativa" : "Concluída";
    final atualizada = OngAcaoResumo(
      id: acao.id,
      titulo: acao.titulo,
      dataEvento: acao.dataEvento,
      dataFormatada: acao.dataFormatada,
      horarioFormatado: acao.horarioFormatado,
      duracaoHoras: acao.duracaoHoras,
      vagasOcupadas: acao.vagasOcupadas,
      vagasTotais: acao.vagasTotais,
      status: novoStatus,
    );

    setState(() {
      _acoes = _acoes.map((a) => a.id == acao.id ? atualizada : a).toList();
    });

    if (widget.onSalvarApi != null) {
      try {
        await widget.onSalvarApi!(atualizada, isEdicao: true);
      } catch (_) {}
    }
  }

  Future<void> _excluirAcao(OngAcaoResumo acao) async {
    setState(() {
      _acoes = _acoes.where((a) => a.id != acao.id).toList();
    });

    if (widget.onExcluirApi != null && acao.id.isNotEmpty) {
      try {
        await widget.onExcluirApi!(acao.id);
      } catch (_) {}
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Ação removida da lista."),
        backgroundColor: Color(0xFF0C6B6B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _abrirFormularioAcao({OngAcaoResumo? acaoExistente}) async {
    final isEdicao = acaoExistente != null;
    final tituloCtrl = TextEditingController(text: acaoExistente?.titulo ?? '');
    final dataCtrl = TextEditingController(
        text: acaoExistente?.dataFormatada ?? 'Sáb, 28/Nov');
    final horaCtrl =
        TextEditingController(text: acaoExistente?.horarioFormatado ?? '09:00');
    final duracaoCtrl = TextEditingController(
      text: (acaoExistente?.duracaoHoras ?? 3).toString(),
    );
    final vagasTotaisCtrl = TextEditingController(
      text: (acaoExistente?.vagasTotais ?? 15).toString(),
    );
    final vagasOcupadasCtrl = TextEditingController(
      text: (acaoExistente?.vagasOcupadas ?? 0).toString(),
    );
    String statusSelecionado = acaoExistente?.status.isNotEmpty == true
        ? acaoExistente!.status
        : 'Ativa';

    final salvar = await showModalBottomSheet<OngAcaoResumo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
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
                            color: const Color(0xFFF5D5B0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isEdicao ? "Editar Ação" : "Definir / Criar Nova Ação",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3B1D04),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: tituloCtrl,
                        decoration: const InputDecoration(
                          labelText: "Título da ação",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: dataCtrl,
                              decoration: const InputDecoration(
                                labelText: "Data (ex.: Sáb, 28/Nov)",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: horaCtrl,
                              decoration: const InputDecoration(
                                labelText: "Horário (ex.: 09:00)",
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
                            child: TextField(
                              controller: vagasOcupadasCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Vagas confirmadas",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: vagasTotaisCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Vagas totais",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: duracaoCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Horas",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: statusSelecionado,
                        decoration: const InputDecoration(
                          labelText: "Status da ação",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: "Ativa", child: Text("Ativa")),
                          DropdownMenuItem(
                              value: "Concluída", child: Text("Concluída")),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => statusSelecionado = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          final titulo = tituloCtrl.text.trim();
                          if (titulo.isEmpty) return;

                          final totais =
                              (int.tryParse(vagasTotaisCtrl.text.trim()) ?? 10)
                                  .clamp(1, 9999);
                          final ocupadas =
                              (int.tryParse(vagasOcupadasCtrl.text.trim()) ?? 0)
                                  .clamp(0, totais);
                          final horas =
                              (int.tryParse(duracaoCtrl.text.trim()) ?? 3)
                                  .clamp(1, 200);

                          final modelo = OngAcaoResumo(
                            id: acaoExistente?.id.isNotEmpty == true
                                ? acaoExistente!.id
                                : "acao-${DateTime.now().millisecondsSinceEpoch}",
                            titulo: titulo,
                            dataEvento: acaoExistente?.dataEvento ??
                                DateTime.now().add(const Duration(days: 2)),
                            dataFormatada: dataCtrl.text.trim(),
                            horarioFormatado: horaCtrl.text.trim(),
                            duracaoHoras: horas,
                            vagasOcupadas: ocupadas,
                            vagasTotais: totais,
                            status: statusSelecionado,
                          );
                          Navigator.of(ctx).pop(modelo);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0C6B6B),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          isEdicao ? "Salvar Alterações" : "Criar Ação",
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
    dataCtrl.dispose();
    horaCtrl.dispose();
    duracaoCtrl.dispose();
    vagasTotaisCtrl.dispose();
    vagasOcupadasCtrl.dispose();

    if (salvar == null || !mounted) return;

    setState(() {
      if (isEdicao) {
        _acoes = _acoes
            .map((item) => item.id == acaoExistente.id ? salvar : item)
            .toList();
      } else {
        _acoes = <OngAcaoResumo>[salvar, ..._acoes];
      }
    });

    if (widget.onSalvarApi != null) {
      try {
        await widget.onSalvarApi!(salvar, isEdicao: isEdicao);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isDesktop = Responsive.isDesktop(context);
    final lista = _acoesFiltradas;

    const corLaranja = Color(0xFFD46B08);
    const corTitulo = Color(0xFF3B1D04);
    const corFundoItem = Color(0xFFFFF7EE);
    const corBordaItem = Color(0xFFF5D5B0);

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Quicksand'),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0FAF7),
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
                    child: _carregando && _acoes.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF0C6B6B),
                            ),
                          )
                        : RefreshIndicator(
                            color: const Color(0xFF0C6B6B),
                            onRefresh: _carregarAcoes,
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
                                      _buildTopoAcoes(
                                        isMobile: isMobile,
                                        corLaranja: corLaranja,
                                        corTitulo: corTitulo,
                                        corFundoItem: corFundoItem,
                                        corBordaItem: corBordaItem,
                                      ),
                                      const SizedBox(height: 14),
                                      if (lista.isEmpty)
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border:
                                                Border.all(color: corBordaItem),
                                          ),
                                          child: const Text(
                                            "Nenhuma ação encontrada para o filtro atual.",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF7A5433),
                                            ),
                                          ),
                                        )
                                      else
                                        ...lista.map(
                                          (acao) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 10),
                                            child: _buildCardAcao(
                                              acao: acao,
                                              corLaranja: corLaranja,
                                              corTitulo: corTitulo,
                                              corFundoItem: corFundoItem,
                                              corBordaItem: corBordaItem,
                                            ),
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

  Widget _buildTopoAcoes({
    required bool isMobile,
    required Color corLaranja,
    required Color corTitulo,
    required Color corFundoItem,
    required Color corBordaItem,
  }) {
    final filtros = [
      (_FiltroStatusAcao.todas, "Todas"),
      (_FiltroStatusAcao.ativas, "Ativas"),
      (_FiltroStatusAcao.concluidas, "Concluídas"),
    ];

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: corBordaItem),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.event_available_rounded, color: corLaranja, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Definir e Gerenciar Ações",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: corTitulo,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _abrirFormularioAcao(),
                icon: const Icon(Icons.add_rounded,
                    size: 15, color: Colors.white),
                label: const Text(
                  "Nova Ação",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C6B6B),
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
                color: corFundoItem,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: corBordaItem),
              ),
              child: const Text(
                "Exibição de fallback ativa: você pode criar, editar e compartilhar ações enquanto a API retorna dados.",
                style: TextStyle(fontSize: 10, color: Color(0xFF7A5433)),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _buscaController,
            onChanged: (val) => setState(() => _termoBusca = val),
            decoration: InputDecoration(
              hintText: "Buscar ação por nome...",
              hintStyle:
                  const TextStyle(fontSize: 12, color: Color(0xFF9C724B)),
              prefixIcon:
                  Icon(Icons.search_rounded, color: corLaranja, size: 18),
              isDense: true,
              filled: true,
              fillColor: corFundoItem,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: corBordaItem),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: corBordaItem),
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
                    color: ativo ? Colors.white : corLaranja,
                  ),
                ),
                selected: ativo,
                selectedColor: ativo ? corLaranja : corFundoItem,
                backgroundColor: corFundoItem,
                side: BorderSide(color: ativo ? corLaranja : corBordaItem),
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

  Widget _buildCardAcao({
    required OngAcaoResumo acao,
    required Color corLaranja,
    required Color corTitulo,
    required Color corFundoItem,
    required Color corBordaItem,
  }) {
    final dataHora = [
      if (acao.dataFormatada.isNotEmpty) acao.dataFormatada,
      if (acao.horarioFormatado.isNotEmpty) acao.horarioFormatado,
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: corBordaItem),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      acao.titulo.isNotEmpty ? acao.titulo : "Ação sem título",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: corTitulo,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "$dataHora • ${acao.duracaoHoras}h • ${acao.status}",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7A5433),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: "Editar ação",
                icon: Icon(Icons.edit_outlined, size: 19, color: corLaranja),
                onPressed: () => _abrirFormularioAcao(acaoExistente: acao),
              ),
              IconButton(
                tooltip: "Compartilhar ação",
                icon: const Icon(Icons.share_outlined,
                    size: 19, color: Color(0xFF0C6B6B)),
                onPressed: () => _compartilharAcao(acao),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: acao.ocupacao,
                    minHeight: 6,
                    backgroundColor: corFundoItem,
                    color: corLaranja,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "${acao.vagasOcupadas}/${acao.vagasTotais} vagas",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: corLaranja,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _abrirFormularioAcao(acaoExistente: acao),
                icon: Icon(Icons.tune_rounded, size: 14, color: corLaranja),
                label: Text(
                  "Definir detalhes",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: corLaranja,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: corBordaItem),
                  backgroundColor: corFundoItem,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _alternarStatusAcao(acao),
                icon: Icon(
                  _isConcluida(acao)
                      ? Icons.replay_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 14,
                  color: const Color(0xFF0C6B6B),
                ),
                label: Text(
                  _isConcluida(acao) ? "Reativar" : "Marcar concluída",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0C6B6B),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFC2E4DC)),
                  backgroundColor: const Color(0xFFF0FAF7),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
              IconButton(
                tooltip: "Excluir ação",
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: Colors.redAccent),
                onPressed: () => _excluirAcao(acao),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
