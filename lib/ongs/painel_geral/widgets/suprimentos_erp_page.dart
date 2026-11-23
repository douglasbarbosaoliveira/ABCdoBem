// lib/ongs/painel_geral/widgets/suprimentos_erp_page.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../services/session_service.dart';
import '../../../utils/responsive.dart';
import '../../../widgets/bottom_nav/app_bottom_nav.dart';
import '../../../widgets/header/app_header.dart';
import '../../../widgets/sidebar/app_sidebar.dart';
import '../../services/ong_painel_service.dart';
import '../../models/suprimentos_erp_models.dart';
import 'suprimentos_modais.dart';

class OngSuprimentosErpPage extends StatefulWidget {
  final String ongId;
  final String tipoUsuario;
  final OngPainelDados? dadosIniciais;
  final OngSuprimentoItem? itemInicialFoco;
  final bool abrirNovoAoIniciar;

  const OngSuprimentosErpPage({
    super.key,
    required this.ongId,
    this.tipoUsuario = "ong",
    this.dadosIniciais,
    this.itemInicialFoco,
    this.abrirNovoAoIniciar = false,
  });

  @override
  State<OngSuprimentosErpPage> createState() => _OngSuprimentosErpPageState();
}

class _OngSuprimentosErpPageState extends State<OngSuprimentosErpPage> {
  static const Color _corVerde = Color(0xFF0C6B6B);
  static const Color _corVerdeEscuro = Color(0xFF064B4B);
  static const Color _corFundoSuave = Color(0xFFF0FAF7);
  static const Color _corBordaSuave = Color(0xFFC2E4DC);
  static const Color _corTextoEscuro = Color(0xFF062222);
  static const Color _corTextoSecundario = Color(0xFF4C7A70);

  final OngSuprimentosService _suprimentosService =
      const OngSuprimentosService();
  final TextEditingController _buscaController = TextEditingController();

  List<OngSuprimentoItem> _itens = <OngSuprimentoItem>[];
  List<VoluntarioPlataforma> _voluntariosPlataforma = <VoluntarioPlataforma>[];
  final List<LogTransacaoSuprimento> _logs = <LogTransacaoSuprimento>[];
  final Map<String, String> _quemBateuMetaPorItem = <String, String>{};

  String _nomeOng = 'ONG';
  String? _avatarOng;
  bool _carregando = false;
  bool _carregandoVoluntarios = false;
  String? _erroApi;
  String _termoBusca = '';
  FiltroSuprimentos _filtro = FiltroSuprimentos.todos;
  bool _executouAcaoInicial = false;

  String get _idResolvido {
    final param = widget.ongId.trim();
    if (param.isNotEmpty) return param;
    return SessionService.instance.usuarioId?.trim() ?? '';
  }

  @override
  void initState() {
    super.initState();
    final inicial = widget.dadosIniciais;
    if (inicial != null) {
      _nomeOng = inicial.nomeOng.isNotEmpty ? inicial.nomeOng : 'ONG';
      _avatarOng = inicial.avatarOng;
      if (inicial.suprimentos.isNotEmpty) {
        _itens = List<OngSuprimentoItem>.from(inicial.suprimentos);
        _avaliarQuemBateuMeta(_itens);
      }
    }
    _carregarVoluntariosPlataforma();
    _carregarSuprimentos().then((_) {
      if (!mounted || _executouAcaoInicial) return;
      _executouAcaoInicial = true;
      if (widget.abrirNovoAoIniciar) {
        _onNovoOuEditarItem();
      } else if (widget.itemInicialFoco != null) {
        final alvo = _itens.firstWhere(
          (i) => i.id == widget.itemInicialFoco!.id,
          orElse: () => widget.itemInicialFoco!,
        );
        _onAbrirCompromissos(alvo);
      }
    });
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  void _registrarLog({
    required String itemId,
    required String itemNome,
    required String tipo,
    required String descricao,
    required String ator,
    String? quemBateuMeta,
  }) {
    final log = LogTransacaoSuprimento(
      id: "log-${DateTime.now().microsecondsSinceEpoch}",
      itemId: itemId,
      itemNome: itemNome,
      tipo: tipo,
      descricao: descricao,
      ator: ator.trim().isEmpty ? _nomeOng : ator.trim(),
      timestamp: DateTime.now(),
    );
    setState(() {
      if (quemBateuMeta != null && quemBateuMeta.trim().isNotEmpty) {
        _quemBateuMetaPorItem[itemId] = quemBateuMeta.trim();
      }
      _logs.insert(0, log);
    });
  }

  void _avaliarQuemBateuMeta(List<OngSuprimentoItem> lista) {
    for (final item in lista) {
      if (!item.metaAtingida) {
        _quemBateuMetaPorItem.remove(item.id);
        continue;
      }
      if (_quemBateuMetaPorItem[item.id] == null) {
        final entregue = item.compromissos
            .where((c) => c.status.toUpperCase() == 'ENTREGUE')
            .toList();
        if (entregue.isNotEmpty) {
          _quemBateuMetaPorItem[item.id] = entregue.last.doadorNome;
        } else if (item.compromissos.isNotEmpty) {
          _quemBateuMetaPorItem[item.id] = item.compromissos.last.doadorNome;
        } else {
          _quemBateuMetaPorItem[item.id] = _nomeOng;
        }
      }
    }
  }

  Future<void> _carregarVoluntariosPlataforma() async {
    setState(() => _carregandoVoluntarios = true);
    try {
      final token = SessionService.instance.token;
      final headers = <String, String>{
        'Accept': 'application/json',
        if (token != null && token.trim().isNotEmpty)
          'Authorization': 'Bearer ${token.trim()}',
      };
      final res = await http
          .get(
            Uri.parse('${_suprimentosService.baseUrl}/users/voluntarios'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final rawList = JsonParsers.extractList(
          jsonDecode(utf8.decode(res.bodyBytes)),
          ['volunteers', 'voluntarios', 'users', 'items'],
        );
        final parsed = <VoluntarioPlataforma>[];
        for (final raw in rawList) {
          if (raw is! JsonMap) continue;
          final id = (raw['id'] ?? '').toString().trim();
          final nome =
              (raw['name'] ?? raw['nome'] ?? 'Voluntário').toString().trim();
          if (nome.isEmpty) continue;
          final cidade = (raw['cidade'] ?? raw['city'] ?? '').toString().trim();
          final email = (raw['email'] ?? '').toString().trim();
          final info =
              cidade.isNotEmpty ? cidade : (email.isNotEmpty ? email : null);
          parsed.add(
            VoluntarioPlataforma(
              id: id.isEmpty ? nome : id,
              nome: nome,
              infoSecundaria: info,
            ),
          );
        }
        if (mounted) {
          setState(() {
            _voluntariosPlataforma = parsed;
            _carregandoVoluntarios = false;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _carregandoVoluntarios = false);
    }
  }

  Future<void> _carregarSuprimentos() async {
    setState(() {
      _carregando = true;
      _erroApi = null;
    });

    try {
      final lista = await _suprimentosService.listarMeusSuprimentos();
      if (!mounted) return;
      _avaliarQuemBateuMeta(lista);
      setState(() {
        _itens = lista;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erroApi = e.toString().replaceAll('Exception: ', '');
        _carregando = false;
      });
    }
  }

  bool _isUrgente(OngSuprimentoItem item) {
    if (item.metaAtingida) return false;
    if (item.prioridade.toUpperCase() == 'URGENTE') return true;
    return item.quantidadeMeta > 0 &&
        (item.quantidadeRecebida / item.quantidadeMeta) < 0.35;
  }

  List<OngSuprimentoItem> get _itensFiltrados {
    final termo = _termoBusca.trim().toLowerCase();
    return _itens.where((item) {
      switch (_filtro) {
        case FiltroSuprimentos.todos:
          break;
        case FiltroSuprimentos.pendentes:
          if (item.metaAtingida) return false;
          break;
        case FiltroSuprimentos.urgentes:
          if (!_isUrgente(item)) return false;
          break;
        case FiltroSuprimentos.atingidos:
          if (!item.metaAtingida) return false;
          break;
      }
      if (termo.isNotEmpty && !item.nome.toLowerCase().contains(termo)) {
        return false;
      }
      return true;
    }).toList();
  }

  void _mostrarFeedback(String mensagem, {bool erro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: erro ? Colors.redAccent : _corVerde,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onNovoOuEditarItem({OngSuprimentoItem? itemExistente}) async {
    final salvo = await SuprimentosModais.abrirFormularioSuprimento(
      context,
      itemExistente: itemExistente,
      nomeOng: _nomeOng,
      service: _suprimentosService,
      voluntarios: _voluntariosPlataforma,
      carregandoVoluntarios: _carregandoVoluntarios,
      onRecarregarVoluntarios: _carregarVoluntariosPlataforma,
      onFeedback: _mostrarFeedback,
      onRegistrarLog: _registrarLog,
    );

    if (salvo) {
      _mostrarFeedback(
        itemExistente != null
            ? "Suprimento atualizado."
            : "Suprimento cadastrado.",
      );
      await _carregarSuprimentos();
    }
  }

  Future<void> _onExcluirItem(OngSuprimentoItem item) async {
    try {
      await _suprimentosService.excluirSuprimento(item.id);
      _registrarLog(
        itemId: item.id,
        itemNome: item.nome,
        tipo: "EXCLUSAO",
        descricao: "Item removido do controle de suprimentos.",
        ator: _nomeOng,
      );
      _mostrarFeedback("Suprimento removido.");
      await _carregarSuprimentos();
    } catch (e) {
      _mostrarFeedback(
        e.toString().replaceAll('Exception: ', ''),
        erro: true,
      );
    }
  }

  Future<void> _onRegistrarDoacao(OngSuprimentoItem item) async {
    final salvo = await SuprimentosModais.abrirRegistrarDoacao(
      context,
      item: item,
      service: _suprimentosService,
      voluntarios: _voluntariosPlataforma,
      carregandoVoluntarios: _carregandoVoluntarios,
      onRecarregarVoluntarios: _carregarVoluntariosPlataforma,
      onFeedback: _mostrarFeedback,
      onRegistrarLog: _registrarLog,
    );

    if (salvo) {
      _mostrarFeedback("Doação registrada e estoque atualizado.");
      await _carregarSuprimentos();
    }
  }

  Future<void> _onAlterarStatusCompromisso(
    OngSuprimentoItem item,
    OngCompromissoDoacao pledge,
    String novoStatus,
  ) async {
    try {
      await _suprimentosService.atualizarStatusCompromisso(
        pledge.id,
        novoStatus,
      );

      String? quemBateuMeta;
      final statusAnterior = pledge.status.toUpperCase();
      if (novoStatus == 'ENTREGUE' && statusAnterior != 'ENTREGUE') {
        final novaRecebida = item.quantidadeRecebida + pledge.quantidade;
        await _suprimentosService.atualizarSuprimento(
          item.id,
          <String, dynamic>{
            'quantidadeRecebida': novaRecebida,
          },
        );
        if (item.quantidadeMeta > 0 && novaRecebida >= item.quantidadeMeta) {
          quemBateuMeta = pledge.doadorNome;
        }
      }

      _registrarLog(
        itemId: item.id,
        itemNome: item.nome,
        tipo: "STATUS_COMPROMISSO",
        descricao:
            "${pledge.doadorNome} (${SuprimentosModais.formatarQtd(pledge.quantidade)} ${item.unidade}) -> $novoStatus",
        ator: pledge.doadorNome,
        quemBateuMeta: quemBateuMeta,
      );

      _mostrarFeedback("Status atualizado para $novoStatus.");
      await _carregarSuprimentos();
    } catch (e) {
      _mostrarFeedback(
        e.toString().replaceAll('Exception: ', ''),
        erro: true,
      );
    }
  }

  void _onAbrirCompromissos(OngSuprimentoItem item) {
    SuprimentosModais.abrirCompromissos(
      context,
      item: item,
      onRegistrarNovaDoacao: () => _onRegistrarDoacao(item),
      onAlterarStatus: _onAlterarStatusCompromisso,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isDesktop = Responsive.isDesktop(context);
    final lista = _itensFiltrados;

    final totalItens = _itens.length;
    final totalAtingidos = _itens.where((i) => i.metaAtingida).length;
    final totalCompromissos = _itens.fold<int>(
      0,
      (acc, i) => acc + i.compromissos.length,
    );

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
                    child: _carregando && _itens.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(color: _corVerde),
                          )
                        : RefreshIndicator(
                            color: _corVerde,
                            onRefresh: _carregarSuprimentos,
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
                                      _buildTopoErp(isMobile: isMobile),
                                      const SizedBox(height: 12),
                                      _buildResumoErp(
                                        totalItens: totalItens,
                                        atingidos: totalAtingidos,
                                        compromissos: totalCompromissos,
                                      ),
                                      const SizedBox(height: 12),
                                      if (_erroApi != null && _itens.isEmpty)
                                        Container(
                                          padding: const EdgeInsets.all(18),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                                color: Colors.redAccent
                                                    .withValues(alpha: 0.4)),
                                          ),
                                          child: Text(
                                            _erroApi!,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                        )
                                      else if (lista.isEmpty)
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
                                            "Nenhum item ou suprimento encontrado.",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: _corTextoSecundario,
                                            ),
                                          ),
                                        )
                                      else
                                        ...lista.map(
                                          (item) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 12),
                                            child: _buildCardSuprimento(item),
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

  Widget _buildTopoErp({required bool isMobile}) {
    const filtros = [
      (FiltroSuprimentos.todos, "Todos"),
      (FiltroSuprimentos.pendentes, "Pendentes"),
      (FiltroSuprimentos.urgentes, "Urgentes"),
      (FiltroSuprimentos.atingidos, "Meta atingida"),
    ];

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _corBordaSuave),
        boxShadow: [
          BoxShadow(
            color: _corVerde.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _corFundoSuave,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _corBordaSuave),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: _corVerde,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Mini ERP • Suprimentos",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _corTextoEscuro,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => SuprimentosModais.abrirLogs(
                  context,
                  logs: _logs,
                ),
                icon: const Icon(Icons.history_rounded,
                    size: 15, color: _corVerde),
                label: Text(
                  "Logs (${_logs.length})",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _corVerde,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _corBordaSuave),
                  backgroundColor: _corFundoSuave,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                onPressed: () => _onNovoOuEditarItem(),
                icon: const Icon(Icons.add_rounded,
                    size: 15, color: Colors.white),
                label: const Text(
                  "Novo Item",
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
          const SizedBox(height: 12),
          TextField(
            controller: _buscaController,
            onChanged: (val) => setState(() => _termoBusca = val),
            decoration: InputDecoration(
              hintText: "Buscar suprimento por nome...",
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

  Widget _buildResumoErp({
    required int totalItens,
    required int atingidos,
    required int compromissos,
  }) {
    Widget cardResumo(String valor, String rotulo) {
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
        cardResumo("$totalItens", "Itens cadastrados"),
        const SizedBox(width: 8),
        cardResumo("$atingidos", "Metas atingidas"),
        const SizedBox(width: 8),
        cardResumo("$compromissos", "Compromissos"),
      ],
    );
  }

  Widget _buildCardSuprimento(OngSuprimentoItem item) {
    final pct = item.quantidadeMeta <= 0
        ? 0.0
        : (item.quantidadeRecebida / item.quantidadeMeta).clamp(0.0, 1.0);
    final urgente = _isUrgente(item);
    final sufixo =
        item.unidade.trim().isNotEmpty ? " ${item.unidade.trim()}" : "";
    final quemBateuMeta = _quemBateuMetaPorItem[item.id];
    final logsItemCount = _logs.where((l) => l.itemId == item.id).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: urgente ? const Color(0xFFFFCCC7) : _corBordaSuave,
        ),
        boxShadow: [
          BoxShadow(
            color: _corVerdeEscuro.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.nome.isNotEmpty ? item.nome : "Item de suprimento",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _corTextoEscuro,
                  ),
                ),
              ),
              if (item.metaAtingida)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6FFED),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFB7EB8F)),
                  ),
                  child: const Text(
                    "Meta Atingida",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF389E0D),
                    ),
                  ),
                )
              else if (urgente)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFCCC7)),
                  ),
                  child: const Text(
                    "URGENTE",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFCF1322),
                    ),
                  ),
                ),
              IconButton(
                tooltip: "Editar suprimento",
                icon:
                    const Icon(Icons.edit_outlined, size: 18, color: _corVerde),
                onPressed: () => _onNovoOuEditarItem(itemExistente: item),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _corFundoSuave,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _corBordaSuave),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Recebido: ${SuprimentosModais.formatarQtd(item.quantidadeRecebida)} / ${SuprimentosModais.formatarQtd(item.quantidadeMeta)}$sufixo",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _corTextoEscuro,
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
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 7,
                    backgroundColor: Colors.white,
                    color: urgente ? const Color(0xFFCF1322) : _corVerde,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Prometido: ${SuprimentosModais.formatarQtd(item.quantidadePrometida)}$sufixo • Faltam: ${SuprimentosModais.formatarQtd(item.saldoFaltante)}$sufixo",
                  style:
                      const TextStyle(fontSize: 10, color: _corTextoSecundario),
                ),
                if (item.prazoLimite != null &&
                    item.prazoLimite!.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.event_available_rounded,
                          size: 12, color: _corTextoSecundario),
                      const SizedBox(width: 4),
                      Text(
                        "Prazo: ${item.prazoLimite}",
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _corTextoSecundario,
                        ),
                      ),
                    ],
                  ),
                ],
                if (item.metaAtingida &&
                    quemBateuMeta != null &&
                    quemBateuMeta.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded,
                          size: 13, color: Color(0xFF389E0D)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "Meta atingida por: $quemBateuMeta",
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF389E0D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _onAbrirCompromissos(item),
                icon: const Icon(Icons.handshake_outlined,
                    size: 14, color: _corVerde),
                label: Text(
                  "Compromissos (${item.compromissos.length})",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _corVerde,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _corBordaSuave),
                  backgroundColor: _corFundoSuave,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _onRegistrarDoacao(item),
                icon: const Icon(Icons.add_circle_outline_rounded,
                    size: 14, color: _corVerde),
                label: const Text(
                  "Registrar Doação",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _corVerde,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _corBordaSuave),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => SuprimentosModais.abrirLogs(
                  context,
                  logs: _logs,
                  filtrarItemId: item.id,
                  tituloItem: item.nome,
                ),
                icon: const Icon(Icons.receipt_long_outlined,
                    size: 14, color: _corTextoSecundario),
                label: Text(
                  "Logs ($logsItemCount)",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _corTextoSecundario,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _corBordaSuave),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
              IconButton(
                tooltip: "Excluir item",
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: Colors.redAccent),
                onPressed: () => _onExcluirItem(item),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
