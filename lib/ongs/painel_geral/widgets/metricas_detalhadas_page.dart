// lib/ongs/painel_geral/metricas_detalhadas_page.dart

import 'package:flutter/material.dart';

import '../../../services/session_service.dart';
import '../../../utils/responsive.dart';
import '../../../widgets/bottom_nav/app_bottom_nav.dart';
import '../../../widgets/header/app_header.dart';
import '../../../widgets/sidebar/app_sidebar.dart';
import '../../services/ong_painel_service.dart';
import '../../services/metricas_relatorio_service.dart';
import '../widgets/grafico_evolucao_horas.dart';
import '../widgets/secao_dashboard_impacto.dart';

class OngMetricasDetalhadasPage extends StatefulWidget {
  final String ongId;
  final String tipoUsuario;
  final OngPainelDados? dadosIniciais;
  final PeriodoIndicadores periodoInicial;

  const OngMetricasDetalhadasPage({
    super.key,
    required this.ongId,
    this.tipoUsuario = "ong",
    this.dadosIniciais,
    this.periodoInicial = PeriodoIndicadores.mensal,
  });

  @override
  State<OngMetricasDetalhadasPage> createState() =>
      _OngMetricasDetalhadasPageState();
}

class _OngMetricasDetalhadasPageState extends State<OngMetricasDetalhadasPage> {
  final OngPainelService _painelService = OngPainelService();
  final MetricasRelatorioService _relatorioService =
      const MetricasRelatorioService();
  final ScrollController _graficoScrollController = ScrollController();

  late PeriodoIndicadores _periodo;
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
    _periodo = widget.periodoInicial;
    _dados = widget.dadosIniciais;
    _carregarMetricas();
  }

  @override
  void dispose() {
    _graficoScrollController.dispose();
    super.dispose();
  }

  Future<void> _carregarMetricas() async {
    if (_idResolvido.isEmpty) return;
    setState(() => _carregando = true);
    try {
      final dados = await _painelService.carregarMetricasPorPeriodo(
        _idResolvido,
        periodo: _periodo,
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

  void _rolarGrafico(double delta) {
    if (!_graficoScrollController.hasClients) return;
    final pos = _graficoScrollController.position;
    final destino = (_graficoScrollController.offset + delta).clamp(
      pos.minScrollExtent,
      pos.maxScrollExtent,
    );
    _graficoScrollController.animateTo(
      destino,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  String _rotuloPeriodo(PeriodoIndicadores periodo) {
    switch (periodo) {
      case PeriodoIndicadores.semanal:
        return "Semanal";
      case PeriodoIndicadores.mensal:
        return "Mensal";
      case PeriodoIndicadores.anual:
        return "Anual";
    }
  }

  String _nomeDiaCurto(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Seg';
      case DateTime.tuesday:
        return 'Ter';
      case DateTime.wednesday:
        return 'Qua';
      case DateTime.thursday:
        return 'Qui';
      case DateTime.friday:
        return 'Sex';
      case DateTime.saturday:
        return 'Sáb';
      case DateTime.sunday:
      default:
        return 'Dom';
    }
  }

  String _nomeMesCurto(int month) {
    const meses = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    return meses[(month - 1).clamp(0, 11)];
  }

  bool _mesmoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatarMoedaBr(double valor) {
    final bool negativo = valor < 0;
    final double absValor = valor.abs();
    final String fixo = absValor.toStringAsFixed(2);
    final List<String> partes = fixo.split('.');
    final String inteiro = partes[0];
    final String centavos = partes.length > 1 ? partes[1] : '00';

    final StringBuffer comMilhares = StringBuffer();
    for (int i = 0; i < inteiro.length; i++) {
      if (i > 0 && (inteiro.length - i) % 3 == 0) {
        comMilhares.write('.');
      }
      comMilhares.write(inteiro[i]);
    }

    return "${negativo ? '-' : ''}R\$ ${comMilhares.toString()},$centavos";
  }

  List<PontoGraficoHoras> _serieHorasPeriodo(OngPainelDados dados) {
    final agora = DateTime.now();
    final hojeMeiaNoite = DateTime(agora.year, agora.month, agora.day);
    final ontemFimDia = hojeMeiaNoite.subtract(const Duration(seconds: 1));

    if (_periodo == PeriodoIndicadores.semanal) {
      final inicioJanela = hojeMeiaNoite.subtract(const Duration(days: 7));
      final List<DateTime> diasJanela = List.generate(
        7,
        (i) => inicioJanela.add(Duration(days: i)),
      );
      final List<int> totais = List<int>.filled(7, 0);

      for (final acao in dados.acoes) {
        final dt = acao.dataEvento;
        if (dt == null) continue;
        if (dt.isBefore(inicioJanela) || dt.isAfter(ontemFimDia)) continue;
        final diaAcao = DateTime(dt.year, dt.month, dt.day);
        final idx = diasJanela.indexWhere((d) => _mesmoDia(d, diaAcao));
        if (idx != -1) {
          totais[idx] += acao.vagasOcupadas * acao.duracaoHoras;
        }
      }

      return List.generate(7, (i) {
        final d = diasJanela[i];
        final diaNum = d.day.toString().padLeft(2, '0');
        return PontoGraficoHoras(
          rotulo: "${_nomeDiaCurto(d.weekday)} $diaNum",
          valor: totais[i].toDouble(),
          detalhe: "${totais[i]}h",
        );
      });
    }

    if (_periodo == PeriodoIndicadores.mensal) {
      final ontemData = hojeMeiaNoite.subtract(const Duration(days: 1));
      final inicio28Dias = ontemData.subtract(const Duration(days: 27));
      final List<int> totaisSemanas = List<int>.filled(4, 0);

      final List<(DateTime inicio, DateTime fim)> blocos =
          List.generate(4, (i) {
        final ini = inicio28Dias.add(Duration(days: i * 7));
        final fim = ini.add(const Duration(days: 6));
        return (ini, fim);
      });

      for (final acao in dados.acoes) {
        final dt = acao.dataEvento;
        if (dt == null) continue;
        final diaAcao = DateTime(dt.year, dt.month, dt.day);
        for (int i = 0; i < blocos.length; i++) {
          final (ini, fim) = blocos[i];
          if (!diaAcao.isBefore(ini) && !diaAcao.isAfter(fim)) {
            totaisSemanas[i] += acao.vagasOcupadas * acao.duracaoHoras;
            break;
          }
        }
      }

      return List.generate(4, (i) {
        final (ini, fim) = blocos[i];
        final dIni = ini.day.toString().padLeft(2, '0');
        final dFim = fim.day.toString().padLeft(2, '0');
        final mesRotulo = ini.month == fim.month
            ? _nomeMesCurto(fim.month)
            : "${_nomeMesCurto(ini.month)}/${_nomeMesCurto(fim.month)}";
        return PontoGraficoHoras(
          rotulo: "$dIni-$dFim",
          subrotulo: mesRotulo,
          valor: totaisSemanas[i].toDouble(),
          detalhe: "${totaisSemanas[i]}h",
        );
      });
    }

    final List<int> porMes = List<int>.filled(12, 0);
    for (final acao in dados.acoes) {
      final dt = acao.dataEvento;
      if (dt != null && dt.year == agora.year) {
        porMes[dt.month - 1] += acao.vagasOcupadas * acao.duracaoHoras;
      }
    }

    return List.generate(
      12,
      (i) => PontoGraficoHoras(
        rotulo: _nomeMesCurto(i + 1),
        valor: porMes[i].toDouble(),
        detalhe: "${porMes[i]}h",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isDesktop = Responsive.isDesktop(context);
    final dados = _dados;

    final String nomeOng =
        (dados?.nomeOng.isNotEmpty == true) ? dados!.nomeOng : 'ONG';
    final int horasDoadas = dados?.horasDoadas ?? 0;
    final int pctVagas = dados?.percentualVagasPreenchidas ?? 0;
    final int pctRetencao = dados?.percentualRetencaoVoluntarios ?? 0;
    final double arrecadado = dados?.valorArrecadadoDinheiro ?? 0;
    final double gastos = dados?.gastos ?? 0;
    final double saldoLiquido = arrecadado - gastos;

    final int totalAcoes = dados?.acoes.length ?? 0;
    final int totalGuardioes = dados?.voluntariosGuardioes.length ?? 0;
    final double mediaHorasPorAcao =
        totalAcoes > 0 ? horasDoadas / totalAcoes : 0;

    final int suprimentosMetaBatida =
        dados?.suprimentos.where((s) => s.metaAtingida).length ?? 0;
    final int totalSuprimentos = dados?.suprimentos.length ?? 0;

    final serieHoras =
        dados != null ? _serieHorasPeriodo(dados) : const <PontoGraficoHoras>[];

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
                    nomeUsuario: nomeOng,
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
                            onRefresh: _carregarMetricas,
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
                                      _buildCabecalhoPeriodo(
                                        isMobile: isMobile,
                                        nomeOng: nomeOng,
                                        dados: dados,
                                        serieHoras: serieHoras,
                                      ),
                                      const SizedBox(height: 14),
                                      _buildResumoIndicadores(
                                        horasDoadas: horasDoadas,
                                        pctVagas: pctVagas,
                                        pctRetencao: pctRetencao,
                                        isMobile: isMobile,
                                      ),
                                      const SizedBox(height: 14),
                                      _buildBlocoFinanceiroEComparativo(
                                        arrecadado: arrecadado,
                                        gastos: gastos,
                                        saldoLiquido: saldoLiquido,
                                        isMobile: isMobile,
                                      ),
                                      const SizedBox(height: 14),
                                      GraficoEvolucaoHoras(
                                        pontos: serieHoras,
                                        horasTotais: horasDoadas,
                                        mostrarSetas: _periodo ==
                                            PeriodoIndicadores.anual,
                                        distribuirNaLargura: _periodo ==
                                            PeriodoIndicadores.mensal,
                                        scrollController:
                                            _graficoScrollController,
                                        onRolar: _rolarGrafico,
                                      ),
                                      const SizedBox(height: 14),
                                      _buildIndicadoresComplementares(
                                        totalAcoes: totalAcoes,
                                        mediaHorasPorAcao: mediaHorasPorAcao,
                                        totalGuardioes: totalGuardioes,
                                        suprimentosMetaBatida:
                                            suprimentosMetaBatida,
                                        totalSuprimentos: totalSuprimentos,
                                        isMobile: isMobile,
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

  Widget _buildCabecalhoPeriodo({
    required bool isMobile,
    required String nomeOng,
    required OngPainelDados? dados,
    required List<PontoGraficoHoras> serieHoras,
  }) {
    final btnImprimirIcone = IconButton(
      tooltip: "Imprimir",
      onPressed: () => _relatorioService.abrirVisualizacaoImpressao(
        context,
        nomeOng: nomeOng,
        periodo: _periodo,
        dados: dados,
        serieHoras: serieHoras,
      ),
      icon: const Icon(
        Icons.print_rounded,
        size: 18,
        color: Color(0xFF0C6B6B),
      ),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFFF0FAF7),
        side: const BorderSide(color: Color(0xFFC2E4DC)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    final btnExportarIcone = IconButton(
      tooltip: "Exportar",
      onPressed: () => _relatorioService.exportarCsv(
        context,
        nomeOng: nomeOng,
        periodo: _periodo,
        dados: dados,
        serieHoras: serieHoras,
      ),
      icon: const Icon(
        Icons.file_download_outlined,
        size: 18,
        color: Color(0xFF0C6B6B),
      ),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFFF0FAF7),
        side: const BorderSide(color: Color(0xFFC2E4DC)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6ECE6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_rounded,
                color: Color(0xFF0C6B6B),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Métricas, Gráficos e Indicadores",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF062222),
                  ),
                ),
              ),
              if (_carregando) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF0C6B6B),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Análise detalhada da instituição no recorte ${_rotuloPeriodo(_periodo).toLowerCase()}.",
            style: const TextStyle(fontSize: 12, color: Color(0xFF4C7A70)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: PeriodoIndicadores.values.map((periodo) {
                    final bool selecionado = periodo == _periodo;
                    return ChoiceChip(
                      label: Text(
                        _rotuloPeriodo(periodo),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: selecionado
                              ? Colors.white
                              : const Color(0xFF0C6B6B),
                        ),
                      ),
                      selected: selecionado,
                      selectedColor: const Color(0xFF0C6B6B),
                      backgroundColor: const Color(0xFFF0FAF7),
                      side: BorderSide(
                        color: selecionado
                            ? const Color(0xFF0C6B6B)
                            : const Color(0xFFC2E4DC),
                      ),
                      onSelected: (ativo) {
                        if (ativo && _periodo != periodo) {
                          setState(() => _periodo = periodo);
                          _carregarMetricas();
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  btnImprimirIcone,
                  const SizedBox(width: 6),
                  btnExportarIcone,
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumoIndicadores({
    required int horasDoadas,
    required int pctVagas,
    required int pctRetencao,
    required bool isMobile,
  }) {
    Widget card(String valor, String titulo, IconData icone, Color cor) {
      return Expanded(
        child: Container(
          padding: EdgeInsets.all(isMobile ? 10 : 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD6ECE6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icone, color: cor, size: 18),
              const SizedBox(height: 6),
              Text(
                valor,
                style: TextStyle(
                  fontSize: isMobile ? 17 : 20,
                  fontWeight: FontWeight.bold,
                  color: cor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF4C7A70),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        card(
          "${horasDoadas}h",
          "Horas doadas",
          Icons.schedule_rounded,
          const Color(0xFF0C6B6B),
        ),
        const SizedBox(width: 8),
        card(
          "$pctVagas%",
          "Vagas preenchidas",
          Icons.pie_chart_rounded,
          const Color(0xFF1A528F),
        ),
        const SizedBox(width: 8),
        card(
          "$pctRetencao%",
          "Retenção vol.",
          Icons.repeat_rounded,
          const Color(0xFFD46B08),
        ),
      ],
    );
  }

  Widget _buildBlocoFinanceiroEComparativo({
    required double arrecadado,
    required double gastos,
    required double saldoLiquido,
    required bool isMobile,
  }) {
    final double maiorValor = [
      arrecadado.abs(),
      gastos.abs(),
      1.0,
    ].reduce((a, b) => a > b ? a : b);
    final double pctArrecadado =
        (arrecadado.abs() / maiorValor).clamp(0.0, 1.0);
    final double pctGastos = (gastos.abs() / maiorValor).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6ECE6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Color(0xFF0C6B6B),
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                "Movimentação Financeira",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF062222),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMiniFinanceiro(
                  "Valor arrecadado em dinheiro",
                  _formatarMoedaBr(arrecadado),
                  const Color(0xFF0C6B6B),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniFinanceiro(
                  "Gastos",
                  _formatarMoedaBr(gastos),
                  const Color(0xFFD46B08),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FAF7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Saldo líquido do período",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF062222),
                  ),
                ),
                Text(
                  _formatarMoedaBr(saldoLiquido),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: saldoLiquido >= 0
                        ? const Color(0xFF0C6B6B)
                        : const Color(0xFFCF1322),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildBarraComparativa(
            rotulo: "Arrecadado",
            valorTexto: _formatarMoedaBr(arrecadado),
            fracao: pctArrecadado,
            cor: const Color(0xFF0C6B6B),
          ),
          const SizedBox(height: 8),
          _buildBarraComparativa(
            rotulo: "Gastos",
            valorTexto: _formatarMoedaBr(gastos),
            fracao: pctGastos,
            cor: const Color(0xFFD46B08),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniFinanceiro(String titulo, String valor, Color cor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF4C7A70),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            valor,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarraComparativa({
    required String rotulo,
    required String valorTexto,
    required double fracao,
    required Color cor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              rotulo,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF062222),
              ),
            ),
            Text(
              valorTexto,
              style: const TextStyle(fontSize: 10, color: Color(0xFF4C7A70)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: fracao,
            minHeight: 8,
            backgroundColor: const Color(0xFFE3F5F1),
            color: cor,
          ),
        ),
      ],
    );
  }

  Widget _buildIndicadoresComplementares({
    required int totalAcoes,
    required double mediaHorasPorAcao,
    required int totalGuardioes,
    required int suprimentosMetaBatida,
    required int totalSuprimentos,
    required bool isMobile,
  }) {
    final itens = [
      (
        "Ações cadastradas",
        "$totalAcoes",
        Icons.event_available_rounded,
      ),
      (
        "Média de horas / ação",
        "${mediaHorasPorAcao.toStringAsFixed(1)}h",
        Icons.timelapse_rounded,
      ),
      (
        "Voluntários guardiões",
        "$totalGuardioes",
        Icons.workspace_premium_rounded,
      ),
      (
        "Suprimentos na meta",
        "$suprimentosMetaBatida/$totalSuprimentos",
        Icons.inventory_2_outlined,
      ),
    ];

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6ECE6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Outros Dados Operacionais",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF062222),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: itens.map((item) {
              return SizedBox(
                width: isMobile ? double.infinity : 200,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FAF7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFC2E4DC)),
                  ),
                  child: Row(
                    children: [
                      Icon(item.$3, size: 18, color: const Color(0xFF0C6B6B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$1,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF4C7A70),
                              ),
                            ),
                            Text(
                              item.$2,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF062222),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
