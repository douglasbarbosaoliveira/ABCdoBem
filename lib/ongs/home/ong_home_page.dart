// lib/ongs/home/ong_home_page.dart

import 'package:flutter/material.dart';

import '../../utils/responsive.dart';
import '../../widgets/header/app_header.dart';
import '../../widgets/sidebar/app_sidebar.dart';
import '../../widgets/bottom_nav/app_bottom_nav.dart';
import '../../eventos/detalhe/evento_detalhe_page.dart';
import '../../voluntarios/perfil/meu_perfil_page.dart';
import '../../../mensagens/mensagens_page.dart';
import '../gestao_eventos/gestao_eventos_page.dart';
import '../models/ong_dashboard_models.dart';
import '../services/ong_dashboard_service.dart';
import '../../services/session_service.dart';
import 'widgets/ong_banner_header.dart';
import 'widgets/ong_gestao_rapida_grid.dart';
import 'widgets/ong_candidaturas_section.dart';
import 'widgets/ong_meus_eventos_section.dart';
import 'widgets/ong_necessidades_section.dart';
import '../necessidades/editar_necessidades_page.dart';

class OngHomePage extends StatefulWidget {
  final String? ongId;

  const OngHomePage({super.key, this.ongId});

  @override
  State<OngHomePage> createState() => _OngHomePageState();
}

class _OngHomePageState extends State<OngHomePage> {
  final OngDashboardService _service = OngDashboardService();
  final GlobalKey _candidaturasSectionKey = GlobalKey();

  OngDashboardModel? _dashboard;
  bool _carregando = true;
  String? _mensagemErro;

  String get _ongIdEfetivo {
    final paramId = widget.ongId?.trim() ?? '';
    if (paramId.isNotEmpty) return paramId;
    return SessionService.instance.usuarioId?.trim() ?? '';
  }

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
      _mensagemErro = null;
    });

    try {
      final dados = await _service.buscarDashboardOng(_ongIdEfetivo);
      if (!mounted) return;
      setState(() {
        _dashboard = dados;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _mensagemErro = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _responderCandidatura(
    CandidatoVoluntarioModel candidato,
    bool aprovado,
  ) async {
    try {
      await _service.responderCandidatura(candidato.solicitacaoId, aprovado);
      if (!mounted) return;

      setState(() {
        final atual = _dashboard!;
        final novaListaPendentes = atual.candidaturasPendentes
            .where((c) => c.solicitacaoId != candidato.solicitacaoId)
            .toList();

        final novoTotalPendentes = atual.candidaturasPendentesCount > 0
            ? atual.candidaturasPendentesCount - 1
            : novaListaPendentes.length;

        _dashboard = OngDashboardModel(
          id: atual.id,
          nome: atual.nome,
          categoria: atual.categoria,
          cidade: atual.cidade,
          logoUrl: atual.logoUrl,
          totalVoluntariosEngajados: aprovado
              ? atual.totalVoluntariosEngajados + 1
              : atual.totalVoluntariosEngajados,
          vagasAbertas: aprovado && atual.vagasAbertas > 0
              ? atual.vagasAbertas - 1
              : atual.vagasAbertas,
          horasGeradas: atual.horasGeradas,
          candidaturasPendentesCount: novoTotalPendentes,
          necessidadesAtuais: atual.necessidadesAtuais,
          chavePix: atual.chavePix,
          horarioRecebimentoDoacoes: atual.horarioRecebimentoDoacoes,
          candidaturasPendentes: novaListaPendentes,
          eventosAtivos: atual.eventosAtivos,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            aprovado
                ? "Candidatura de ${candidato.nome} aprovada com sucesso!"
                : "Candidatura de ${candidato.nome} recusada.",
          ),
          backgroundColor:
              aprovado ? const Color(0xFF0C6B6B) : Colors.grey.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Não foi possível processar a candidatura: ${e.toString().replaceFirst('Exception: ', '')}",
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _abrirModalNecessidades() {
    EditarNecessidadesPage.abrir(
      context,
      ongId: _ongIdEfetivo,
      necessidadesIniciais: _dashboard!.necessidadesAtuais,
      causaOng: _dashboard!.categoria,
      nomeOng: _dashboard!.nome,
      fotoPerfilUrl: _dashboard!.logoUrl,
      textosEventosAtivos: _dashboard!.eventosAtivos
          .map((ev) => ev.titulo)
          .where((t) => t.trim().isNotEmpty)
          .toList(),
      onSalvar: (tempLista) async {
        await _service.atualizarNecessidades(_ongIdEfetivo, tempLista);
        if (!mounted) return;

        setState(() {
          final atual = _dashboard!;
          _dashboard = OngDashboardModel(
            id: atual.id,
            nome: atual.nome,
            categoria: atual.categoria,
            cidade: atual.cidade,
            logoUrl: atual.logoUrl,
            totalVoluntariosEngajados: atual.totalVoluntariosEngajados,
            vagasAbertas: atual.vagasAbertas,
            horasGeradas: atual.horasGeradas,
            candidaturasPendentesCount: atual.candidaturasPendentesCount,
            necessidadesAtuais: tempLista,
            chavePix: atual.chavePix,
            horarioRecebimentoDoacoes: atual.horarioRecebimentoDoacoes,
            candidaturasPendentes: atual.candidaturasPendentes,
            eventosAtivos: atual.eventosAtivos,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Necessidades da instituição atualizadas!"),
            backgroundColor: Color(0xFF0C6B6B),
          ),
        );
      },
    );
  }

  void _rolarParaCandidaturas() {
    final ctx = _candidaturasSectionKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _abrirGestaoEventos() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GestaoEventosPage(
          ongId: _ongIdEfetivo,
          tipoUsuario: "ong",
        ),
      ),
    );
    if (mounted) {
      _carregarDados();
    }
  }

  Future<void> _abrirEdicaoEvento(String evId) async {
    final alterou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EventoDetalhePage(
          eventoId: evId,
          usuarioAtualId: _ongIdEfetivo,
          isOng: true,
        ),
      ),
    );
    if (alterou == true && mounted) {
      _carregarDados();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isDesktop = Responsive.isDesktop(context);
    final String idAtual = _ongIdEfetivo;

    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF7),
      bottomNavigationBar: isMobile
          ? AppBottomNav(
              currentIndex: 0,
              usuarioId: idAtual,
              tipoUsuario: "ong",
            )
          : null,
      body: Row(
        children: [
          if (isDesktop)
            AppSidebar(
              currentIndex: 0,
              usuarioId: idAtual,
              tipoUsuario: "ong",
            ),
          Expanded(
            child: Column(
              children: [
                AppHeader(
                  usuarioId: idAtual,
                  tipoUsuario: "ong",
                  nomeUsuario: _dashboard?.nome ??
                      SessionService.instance.nomeUsuario ??
                      "Instituição Parceira",
                  fotoPerfilUrl:
                      _dashboard?.logoUrl ?? SessionService.instance.fotoUrl,
                ),
                Expanded(
                  child: _carregando
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF0C6B6B),
                          ),
                        )
                      : _mensagemErro != null || _dashboard == null
                          ? Center(child: _buildErrorState())
                          : RefreshIndicator(
                              color: const Color(0xFF0C6B6B),
                              onRefresh: _carregarDados,
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.all(isMobile ? 14 : 24),
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 880),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // 1. Banner com métricas reais
                                        OngBannerHeader(
                                          dashboard: _dashboard!,
                                          isMobile: isMobile,
                                        ),
                                        SizedBox(height: isMobile ? 18 : 24),

                                        // 2. Ações rápidas
                                        OngGestaoRapidaGrid(
                                          totalCandidaturas: _dashboard!
                                              .candidaturasPendentesCount,
                                          onNovoEvento: _abrirGestaoEventos,
                                          onEditarNecessidades:
                                              _abrirModalNecessidades,
                                          onAbrirCandidatos:
                                              _rolarParaCandidaturas,
                                          onAbrirMensagens: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => MensagensPage(
                                                  usuarioId: idAtual,
                                                  tipoUsuario: "ong",
                                                ),
                                              ),
                                            );
                                          },
                                          isMobile: isMobile,
                                        ),
                                        SizedBox(height: isMobile ? 22 : 30),

                                        // 3. Aprovações de Voluntários
                                        KeyedSubtree(
                                          key: _candidaturasSectionKey,
                                          child: OngCandidaturasSection(
                                            candidaturas: _dashboard!
                                                .candidaturasPendentes,
                                            onResponder: _responderCandidatura,
                                            onVerPerfil: (vId) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => MeuPerfilPage(
                                                    usuarioId: vId,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        SizedBox(height: isMobile ? 22 : 30),

                                        // 4. Meus Eventos Ativos
                                        OngMeusEventosSection(
                                          eventos: _dashboard!.eventosAtivos,
                                          onEditarEvento: _abrirEdicaoEvento,
                                          onGerenciarTodos: _abrirGestaoEventos,
                                          isMobile: isMobile,
                                        ),
                                        SizedBox(height: isMobile ? 22 : 30),

                                        // 5. Necessidades e Doações
                                        OngNecessidadesSection(
                                          necessidades:
                                              _dashboard!.necessidadesAtuais,
                                          onEditar: _abrirModalNecessidades,
                                        ),
                                        const SizedBox(height: 36),
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

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: Colors.redAccent,
              size: 40,
            ),
            const SizedBox(height: 12),
            const Text(
              "Erro ao carregar o painel da ONG",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF062222),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _mensagemErro ?? "Verifique sua conexão e tente novamente.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _carregarDados,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C6B6B),
              ),
              child: const Text(
                "Tentar novamente",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
