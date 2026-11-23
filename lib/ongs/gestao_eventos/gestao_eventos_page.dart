// lib/ongs/gestao_eventos/gestao_eventos_page.dart

import 'package:flutter/material.dart';

import '../../services/session_service.dart';
import '../../utils/responsive.dart';
import '../../widgets/header/app_header.dart';
import '../../widgets/sidebar/app_sidebar.dart';
import '../../widgets/bottom_nav/app_bottom_nav.dart';
import '../../eventos/models/evento_model.dart';
import '../../eventos/services/evento_service.dart';
import '../criar_evento/criar_evento_page.dart';
import 'widgets/card_evento_gestao.dart';
import 'widgets/banner_criar_evento.dart';
import 'widgets/gestao_eventos_metricas.dart';

class GestaoEventosPage extends StatefulWidget {
  final String ongId;
  final String tipoUsuario;

  const GestaoEventosPage({
    super.key,
    required this.ongId,
    this.tipoUsuario = "ong",
  });

  @override
  State<GestaoEventosPage> createState() => _GestaoEventosPageState();
}

class _GestaoEventosPageState extends State<GestaoEventosPage> {
  final EventoService _eventService = EventoService();

  List<EventoModel> _todosEventos = [];
  bool _carregando = true;
  int _filtroSelecionado = 0; // 0: Todos, 1: Próximos, 2: Encerrados

  String get _ongIdEfetivo {
    final id = widget.ongId.trim();
    if (id.isNotEmpty) return id;
    return SessionService.instance.usuarioId?.trim() ?? '';
  }

  @override
  void initState() {
    super.initState();
    _carregarEventos();
  }

  Future<void> _carregarEventos() async {
    setState(() => _carregando = true);
    try {
      final eventosOng = await _eventService.buscarEventos(
        ongId: _ongIdEfetivo,
        token: SessionService.instance.token,
      );
      if (mounted) {
        setState(() {
          _todosEventos = eventosOng;
          _carregando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  // --- FILTROS TEMPORAIS ---
  List<EventoModel> get _proximosEventos => _todosEventos
      .where((e) => e.dataHoraInicio.isAfter(DateTime.now()))
      .toList();

  List<EventoModel> get _eventosEncerrados => _todosEventos
      .where((e) => e.dataHoraInicio.isBefore(DateTime.now()))
      .toList();

  List<EventoModel> get _eventosFiltrados {
    if (_filtroSelecionado == 1) return _proximosEventos;
    if (_filtroSelecionado == 2) return _eventosEncerrados;
    return _todosEventos;
  }

  // Métricas calculadas
  int get _totalVoluntariosMobilizados => _todosEventos.fold<int>(
        0,
        (acc, ev) => acc + (ev.vagasTotais - ev.vagasRestantes),
      );

  Future<void> _abrirCriarEvento() async {
    final criado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CriarEventoPage(
          ongId: _ongIdEfetivo,
          tipoUsuario: widget.tipoUsuario,
        ),
      ),
    );
    if (criado == true && mounted) {
      _carregarEventos();
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
              currentIndex: 5,
              usuarioId: idAtual,
              tipoUsuario: widget.tipoUsuario,
            ),
          Expanded(
            child: Column(
              children: [
                AppHeader(
                  usuarioId: idAtual,
                  tipoUsuario: widget.tipoUsuario,
                  nomeUsuario: SessionService.instance.nomeUsuario ??
                      "Instituição Parceira",
                  fotoPerfilUrl: SessionService.instance.fotoUrl,
                  showBackButton: true,
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: const Color(0xFF0C6B6B),
                    onRefresh: _carregarEventos,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(isMobile ? 14 : 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 860),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. Card Grande de Chamada para Criação
                              BannerCriarEvento(
                                  onCriarEvento: _abrirCriarEvento),
                              const SizedBox(height: 18),

                              // 2. Barra de Métricas Principais
                              GestaoEventosMetricas(
                                totalRealizados: _eventosEncerrados.length,
                                totalProximos: _proximosEventos.length,
                                totalVoluntarios: _totalVoluntariosMobilizados,
                                taxaAssiduidade: 94.0,
                              ),
                              const SizedBox(height: 22),

                              // 3. Cabeçalho de Ações e Filtros
                              _buildBarraFiltros(isMobile),
                              const SizedBox(height: 14),

                              // 4. Lista de Eventos
                              _buildConteudoLista(),
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

  Widget _buildBarraFiltros(bool isMobile) {
    final opcoes = [
      "Todos (${_todosEventos.length})",
      "Próximos (${_proximosEventos.length})",
      "Encerrados (${_eventosEncerrados.length})",
    ];

    final listaChips = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(opcoes.length, (index) {
          final selecionado = _filtroSelecionado == index;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(
                opcoes[index],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: selecionado ? Colors.white : const Color(0xFF062222),
                ),
              ),
              selected: selecionado,
              selectedColor: const Color(0xFF0C6B6B),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFC2E4DC)),
              onSelected: (val) {
                if (val) setState(() => _filtroSelecionado = index);
              },
            ),
          );
        }),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Histórico de Ações",
            style: TextStyle(
              fontFamily: 'Quicksand',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF062222),
            ),
          ),
          const SizedBox(height: 8),
          listaChips,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Histórico de Ações",
          style: TextStyle(
            fontFamily: 'Quicksand',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF062222),
          ),
        ),
        listaChips,
      ],
    );
  }

  Widget _buildConteudoLista() {
    if (_carregando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child:
            Center(child: CircularProgressIndicator(color: Color(0xFF0C6B6B))),
      );
    }

    final lista = _eventosFiltrados;

    if (lista.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC2E4DC)),
        ),
        child: const Column(
          children: [
            Icon(Icons.event_busy_rounded, size: 44, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              "Nenhuma ação encontrada neste filtro",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              "Utilize o banner acima para criar uma nova oportunidade.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: lista.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return CardEventoGestao(
          evento: lista[index],
          onAtualizar: _carregarEventos,
        );
      },
    );
  }
}
