// lib/ongs/painel_geral/painel_geral_page.dart

import 'package:flutter/material.dart';

import '../../services/session_service.dart';
import '../../utils/responsive.dart';
import '../../widgets/bottom_nav/app_bottom_nav.dart';
import '../../widgets/header/app_header.dart';
import '../../widgets/sidebar/app_sidebar.dart';
import '../services/ong_painel_service.dart';
import 'widgets/gestao_acoes_page.dart';
import 'widgets/metas_instituicao_page.dart';
import 'widgets/metricas_detalhadas_page.dart';
import 'widgets/secao_dashboard_impacto.dart';
import 'widgets/secao_feed_comunitario.dart';
import 'widgets/secao_gestao_acoes.dart';
import 'widgets/secao_itens_suprimentos.dart';
import 'widgets/secao_metas_campanhas.dart';
import 'widgets/secao_voluntarios_destaque.dart';
import 'widgets/suprimentos_erp_page.dart';
import 'widgets/voluntarios_page.dart';

class OngPainelGeralPage extends StatefulWidget {
  final String ongId;
  final String tipoUsuario;
  final OngPainelDados? dadosIniciais;

  const OngPainelGeralPage({
    super.key,
    required this.ongId,
    this.tipoUsuario = "ong",
    this.dadosIniciais,
  });

  @override
  State<OngPainelGeralPage> createState() => _OngPainelGeralPageState();
}

class _OngPainelGeralPageState extends State<OngPainelGeralPage> {
  final OngPainelService _painelService = OngPainelService();

  OngPainelDados? _dados;
  bool _carregando = false;

  String get _idResolvido {
    final param = widget.ongId.trim();
    if (param.isNotEmpty) return param;
    return SessionService.instance.usuarioId?.trim() ?? '';
  }

  @override
  void initState() {
    super.initState();
    _dados = widget.dadosIniciais;
    _carregarPainel();
  }

  Future<void> _carregarPainel() async {
    if (_idResolvido.isEmpty) return;
    setState(() => _carregando = true);
    try {
      final dados = await _painelService.carregarPainelOng(
        _idResolvido,
        ultimos30Dias: true,
      );
      if (mounted) {
        setState(() {
          _dados = dados;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _carregando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onNavegarFallback(String destino) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Navegação para: $destino"),
        backgroundColor: const Color(0xFF0C6B6B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _abrirMetricasDetalhadas() async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => OngMetricasDetalhadasPage(
          ongId: _idResolvido,
          tipoUsuario: widget.tipoUsuario,
          dadosIniciais: _dados,
          periodoInicial: PeriodoIndicadores.mensal,
        ),
      ),
    );
    if (mounted) {
      _carregarPainel();
    }
  }

  Future<void> _abrirVoluntariosPage() async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => OngVoluntariosPage(
          ongId: _idResolvido,
          tipoUsuario: widget.tipoUsuario,
          dadosIniciais: _dados,
        ),
      ),
    );
    if (mounted) {
      _carregarPainel();
    }
  }

  Future<void> _abrirGestaoAcoes({OngAcaoResumo? acaoParaEditar}) async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => OngGestaoAcoesPage(
          ongId: _idResolvido,
          tipoUsuario: widget.tipoUsuario,
          dadosIniciais: _dados,
          acaoInicialParaEditar: acaoParaEditar,
          usarFallbackVisual: true,
          onSalvarApi: (acao, {required bool isEdicao}) =>
              _painelService.salvarAcaoOng(acao, isEdicao: isEdicao),
          onExcluirApi: (acaoId) => _painelService.excluirAcaoOng(acaoId),
        ),
      ),
    );
    if (mounted) {
      _carregarPainel();
    }
  }

  Future<void> _abrirMetasInstituicao({bool abrirNovo = false}) async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => OngMetasInstituicaoPage(
          ongId: _idResolvido,
          tipoUsuario: widget.tipoUsuario,
          dadosIniciais: _dados,
          abrirNovoAoIniciar: abrirNovo,
          usarFallbackVisual: true,
          onSalvarMetaApi: (
            meta, {
            required bool isEdicao,
            DateTime? dataInicio,
            DateTime? dataFim,
          }) =>
              _painelService.salvarMetaInstitucional(
            meta,
            isEdicao: isEdicao,
            dataInicio: dataInicio,
            dataFim: dataFim,
          ),
          onExcluirMetaApi: (metaId) =>
              _painelService.removerMetaInstitucional(metaId),
        ),
      ),
    );
    if (mounted) {
      _carregarPainel();
    }
  }

  Future<void> _abrirSuprimentosErp({
    OngSuprimentoItem? itemFoco,
    bool abrirNovo = false,
  }) async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => OngSuprimentosErpPage(
          ongId: _idResolvido,
          tipoUsuario: widget.tipoUsuario,
          dadosIniciais: _dados,
          itemInicialFoco: itemFoco,
          abrirNovoAoIniciar: abrirNovo,
        ),
      ),
    );
    if (mounted) {
      _carregarPainel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isDesktop = Responsive.isDesktop(context);
    final dados = _dados;

    final String nomeHeader =
        (dados?.nomeOng.isNotEmpty == true) ? dados!.nomeOng : 'ONG';

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
                    nomeUsuario: nomeHeader,
                    fotoPerfilUrl: dados?.avatarOng,
                    showBackButton: true,
                  ),
                  Expanded(
                    child: _carregando && dados == null
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF0C6B6B),
                            ),
                          )
                        : RefreshIndicator(
                            color: const Color(0xFF0C6B6B),
                            onRefresh: _carregarPainel,
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
                                      SecaoDashboardImpacto(
                                        isMobile: isMobile,
                                        onNavegar: _onNavegarFallback,
                                        onAbrirDetalhes:
                                            _abrirMetricasDetalhadas,
                                        horasDoadas: dados?.horasDoadas ?? 0,
                                        percentualVagasPreenchidas:
                                            dados?.percentualVagasPreenchidas ??
                                                0,
                                        percentualRetencaoVoluntarios: dados
                                                ?.percentualRetencaoVoluntarios ??
                                            0,
                                        valorArrecadadoDinheiro:
                                            dados?.valorArrecadadoDinheiro ?? 0,
                                        gastos: dados?.gastos ?? 0,
                                      ),
                                      const SizedBox(height: 14),
                                      SecaoGestaoAcoes(
                                        ongId: _idResolvido,
                                        tipoUsuario: widget.tipoUsuario,
                                        isMobile: isMobile,
                                        onNavegar: _onNavegarFallback,
                                        onEventoCriado: _carregarPainel,
                                        onEditarAcao: (acao) =>
                                            _abrirGestaoAcoes(
                                                acaoParaEditar: acao),
                                        acoes: dados?.acoes ??
                                            const <OngAcaoResumo>[],
                                      ),
                                      const SizedBox(height: 14),
                                      SecaoVoluntariosDestaque(
                                        isMobile: isMobile,
                                        onNavegar: _onNavegarFallback,
                                        onAbrirTodos: _abrirVoluntariosPage,
                                        voluntarios: dados
                                                ?.voluntariosGuardioes ??
                                            const <VoluntarioGuardiaoResumo>[],
                                      ),
                                      const SizedBox(height: 14),
                                      SecaoMetasCampanhas(
                                        isMobile: isMobile,
                                        onNavegar: _onNavegarFallback,
                                        onAdicionarMeta: () =>
                                            _abrirMetasInstituicao(
                                                abrirNovo: true),
                                        onAbrirPainelMetas: () =>
                                            _abrirMetasInstituicao(),
                                        metas: dados?.metas ??
                                            const <OngMetaItem>[],
                                      ),
                                      const SizedBox(height: 14),
                                      SecaoItensSuprimentos(
                                        isMobile: isMobile,
                                        onNavegar: _onNavegarFallback,
                                        onGerenciar: () =>
                                            _abrirSuprimentosErp(),
                                        onSelecionarItem: (item) =>
                                            _abrirSuprimentosErp(
                                                itemFoco: item),
                                        suprimentos: dados?.suprimentos ??
                                            const <OngSuprimentoItem>[],
                                      ),
                                      const SizedBox(height: 14),
                                      SecaoFeedComunitario(
                                        ongId: _idResolvido,
                                        nomeOng: nomeHeader,
                                        avatarOng: dados?.avatarOng,
                                        isMobile: isMobile,
                                        onNavegar: _onNavegarFallback,
                                        onPostCriado: _carregarPainel,
                                        onPublicarPostApi: (payload) =>
                                            _painelService
                                                .publicarPostOng(payload),
                                        acoesOng: dados?.acoes ??
                                            const <OngAcaoResumo>[],
                                        publicacoesOng: dados?.publicacoesOng ??
                                            const <UltimoPostOngResumo>[],
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
}
