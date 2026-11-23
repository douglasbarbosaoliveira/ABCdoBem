// lib/ongs/painel_geral/widgets/voluntarios_page.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../../services/session_service.dart';
import '../../../utils/responsive.dart';
import '../../../widgets/bottom_nav/app_bottom_nav.dart';
import '../../../widgets/header/app_header.dart';
import '../../../widgets/sidebar/app_sidebar.dart';
import '../../services/ong_painel_service.dart';

enum _FiltroVoluntarios { todos, recorrentes, maisHoras }

class OngVoluntariosPage extends StatefulWidget {
  final String ongId;
  final String tipoUsuario;
  final OngPainelDados? dadosIniciais;
  final String? acaoInicialId;

  const OngVoluntariosPage({
    super.key,
    required this.ongId,
    this.tipoUsuario = "ong",
    this.dadosIniciais,
    this.acaoInicialId,
  });

  @override
  State<OngVoluntariosPage> createState() => _OngVoluntariosPageState();
}

class _OngVoluntariosPageState extends State<OngVoluntariosPage> {
  final OngPainelService _painelService = OngPainelService();
  final TextEditingController _buscaController = TextEditingController();

  OngPainelDados? _dados;
  bool _carregando = false;
  String _termoBusca = '';
  _FiltroVoluntarios _filtro = _FiltroVoluntarios.todos;

  String? _acaoSelecionadaId;
  int _horasCalculadasEvento = 1;
  List<JsonMap> _inscricoesAcao = <JsonMap>[];
  bool _carregandoInscricoes = false;
  bool _processandoOperacao = false;

  String get _idResolvido {
    final param = widget.ongId.trim();
    if (param.isNotEmpty) return param;
    return SessionService.instance.usuarioId?.trim() ?? '';
  }

  @override
  void initState() {
    super.initState();
    _dados = widget.dadosIniciais;
    if (widget.acaoInicialId != null &&
        widget.acaoInicialId!.trim().isNotEmpty) {
      _acaoSelecionadaId = widget.acaoInicialId!.trim();
    } else if (_dados?.acoes.isNotEmpty == true) {
      _acaoSelecionadaId = _dados!.acoes.first.id;
    }
    _carregarVoluntarios();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  int _calcularHorasDeMapaEvento(JsonMap? ev, OngAcaoResumo? resumo) {
    if (ev != null) {
      final rawInicio =
          ev['startDate'] ?? ev['dataInicio'] ?? ev['startTime'] ?? ev['date'];
      final rawFim = ev['endDate'] ?? ev['dataFim'] ?? ev['endTime'];

      if (rawInicio != null && rawFim != null) {
        final ini = DateTime.tryParse(rawInicio.toString());
        final fim = DateTime.tryParse(rawFim.toString());
        if (ini != null && fim != null && fim.isAfter(ini)) {
          final minutos = fim.difference(ini).inMinutes;
          final horas = (minutos / 60).ceil();
          if (horas > 0) return horas;
        }
      }

      // Tenta extrair de string de horário tipo "09:00 às 12:00" ou "09:00 - 12:00"
      final horarioStr = (ev['horario'] ?? ev['schedule'] ?? '').toString();
      final match = RegExp(r'(\d{1,2}):(\d{2}).*?(\d{1,2}):(\d{2})')
          .firstMatch(horarioStr);
      if (match != null) {
        final h1 = int.parse(match.group(1)!);
        final m1 = int.parse(match.group(2)!);
        final h2 = int.parse(match.group(3)!);
        final m2 = int.parse(match.group(4)!);
        final diffMin = (h2 * 60 + m2) - (h1 * 60 + m1);
        if (diffMin > 0) return (diffMin / 60).ceil();
      }

      final dur = ev['durationHours'] ?? ev['duracaoHoras'] ?? ev['hours'];
      if (dur is num && dur > 0) return dur.round();
    }

    if (resumo != null && resumo.duracaoHoras > 0) {
      return resumo.duracaoHoras;
    }
    return 1;
  }

  Future<void> _carregarVoluntarios() async {
    if (_idResolvido.isEmpty) return;
    setState(() => _carregando = true);
    try {
      final dados = await _painelService.carregarPainelOng(
        _idResolvido,
        ultimos30Dias: false,
      );
      if (mounted) {
        final acoesDisponiveis = dados.acoes;
        String? alvoAcaoId = _acaoSelecionadaId;
        if (acoesDisponiveis.isEmpty) {
          alvoAcaoId = null;
        } else if (alvoAcaoId == null ||
            !acoesDisponiveis.any((a) => a.id == alvoAcaoId)) {
          alvoAcaoId = acoesDisponiveis.first.id;
        }

        setState(() {
          _dados = dados;
          _acaoSelecionadaId = alvoAcaoId;
          _carregando = false;
        });

        if (alvoAcaoId != null && alvoAcaoId.isNotEmpty) {
          await _carregarInscricoesDaAcao(alvoAcaoId);
        }
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

  Future<void> _carregarInscricoesDaAcao(String opportunityId) async {
    if (opportunityId.trim().isEmpty) return;
    setState(() => _carregandoInscricoes = true);

    final resumoAtual = (_dados?.acoes ?? const <OngAcaoResumo>[])
        .cast<OngAcaoResumo?>()
        .firstWhere((a) => a?.id == opportunityId, orElse: () => null);

    try {
      final token = SessionService.instance.token?.trim();
      final headers = <String, String>{
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      List<JsonMap> listaEncontrada = <JsonMap>[];
      int horasCalculadas = _calcularHorasDeMapaEvento(null, resumoAtual);

      // 1. Busca o detalhe da oportunidade (GET /opportunities/:id), que traz applications e datas reais
      final resDetalhe = await http
          .get(
            Uri.parse('${_painelService.baseUrl}/opportunities/$opportunityId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (resDetalhe.statusCode >= 200 && resDetalhe.statusCode < 300) {
        final corpoDetalhe = jsonDecode(utf8.decode(resDetalhe.bodyBytes));
        final JsonMap? objEvento = corpoDetalhe is JsonMap
            ? (corpoDetalhe['data'] is JsonMap
                ? corpoDetalhe['data'] as JsonMap
                : corpoDetalhe)
            : null;

        if (objEvento != null) {
          horasCalculadas = _calcularHorasDeMapaEvento(objEvento, resumoAtual);
          final appsDiretas = JsonParsers.extractList(
            objEvento,
            ['applications', 'inscricoes', 'candidates', 'volunteers'],
          ).whereType<JsonMap>().toList();

          if (appsDiretas.isNotEmpty) {
            listaEncontrada = appsDiretas;
          }
        }
      }

      // 2. Fallback: busca na rota consolidada de candidaturas da ONG e filtra pela vaga
      if (listaEncontrada.isEmpty) {
        final resAppsOng = await http
            .get(
              Uri.parse(
                  '${_painelService.baseUrl}/opportunities/ong/applications'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 10));

        if (resAppsOng.statusCode >= 200 && resAppsOng.statusCode < 300) {
          final todasApps = JsonParsers.extractList(
            jsonDecode(utf8.decode(resAppsOng.bodyBytes)),
            ['applications', 'inscricoes', 'items', 'data'],
          ).whereType<JsonMap>().toList();

          listaEncontrada = todasApps.where((app) {
            final opObj = app['opportunity'] is JsonMap
                ? app['opportunity'] as JsonMap
                : null;
            final opId =
                (app['opportunityId'] ?? app['eventoId'] ?? opObj?['id'] ?? '')
                    .toString()
                    .trim();
            return opId == opportunityId;
          }).toList();
        }
      }

      if (mounted) {
        setState(() {
          _horasCalculadasEvento = horasCalculadas;
          _inscricoesAcao = listaEncontrada;
          _carregandoInscricoes = false;
        });
      }
      return;
    } catch (_) {}

    if (mounted) {
      setState(() {
        _horasCalculadasEvento = _calcularHorasDeMapaEvento(null, resumoAtual);
        _inscricoesAcao = <JsonMap>[];
        _carregandoInscricoes = false;
      });
    }
  }

  Future<void> _validarPresencaInscrito(
    JsonMap app, {
    required bool presente,
  }) async {
    final applicationId = (app['id'] ?? '').toString().trim();
    if (applicationId.isEmpty || _processandoOperacao) return;

    setState(() => _processandoOperacao = true);
    try {
      await _painelService.validarPresencaVoluntario(
        applicationId,
        presente: presente,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            presente
                ? "Presença confirmada (${_horasCalculadasEvento}h registradas automaticamente)."
                : "Falta registrada com sucesso.",
          ),
          backgroundColor: const Color(0xFF1A528F),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _carregarVoluntarios();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processandoOperacao = false);
      }
    }
  }

  Future<void> _finalizarCertificadosDaAcao() async {
    final opportunityId = _acaoSelecionadaId?.trim() ?? '';
    if (opportunityId.isEmpty || _processandoOperacao) return;

    setState(() => _processandoOperacao = true);
    try {
      await _painelService.finalizarCertificadosEvento(opportunityId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Evento finalizado e certificados emitidos (${_horasCalculadasEvento}h)."),
          backgroundColor: const Color(0xFF1A528F),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _carregarVoluntarios();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processandoOperacao = false);
      }
    }
  }

  List<VoluntarioGuardiaoResumo> get _voluntariosRanking {
    final base = List<VoluntarioGuardiaoResumo>.from(
      _dados?.voluntariosGuardioes ?? const <VoluntarioGuardiaoResumo>[],
    );

    base.sort((a, b) {
      if (_filtro == _FiltroVoluntarios.maisHoras) {
        final cmpHoras = b.horasAcumuladas.compareTo(a.horasAcumuladas);
        if (cmpHoras != 0) return cmpHoras;
        return b.acoesConcluidas.compareTo(a.acoesConcluidas);
      }
      final cmpAcoes = b.acoesConcluidas.compareTo(a.acoesConcluidas);
      if (cmpAcoes != 0) return cmpAcoes;
      return b.horasAcumuladas.compareTo(a.horasAcumuladas);
    });

    final termo = _termoBusca.trim().toLowerCase();

    return base.where((v) {
      if (_filtro == _FiltroVoluntarios.recorrentes && v.acoesConcluidas < 2) {
        return false;
      }
      if (termo.isNotEmpty && !v.nome.toLowerCase().contains(termo)) {
        return false;
      }
      return true;
    }).toList();
  }

  String _iniciais(String nome) {
    final partes = nome.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return 'V';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }

  Color _corPosicao(int indice) {
    switch (indice) {
      case 0:
        return const Color(0xFFD46B08);
      case 1:
        return const Color(0xFF1A528F);
      case 2:
        return const Color(0xFF2B6CB0);
      default:
        return const Color(0xFF5A7D9A);
    }
  }

  Future<void> _copiarValor(
      BuildContext ctx, String rotulo, String valor) async {
    final messenger = ScaffoldMessenger.of(ctx);
    await Clipboard.setData(ClipboardData(text: valor));
    messenger.showSnackBar(
      SnackBar(
        content: Text("$rotulo copiado."),
        backgroundColor: const Color(0xFF1A528F),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _abrirDetalhesVoluntario(VoluntarioGuardiaoResumo vol, int posicao) {
    const corAzul = Color(0xFF1A528F);
    const corFundoClaro = Color(0xFFEFF6FC);
    const corBordaClaro = Color(0xFFC8DFF2);

    final temAvatar = vol.avatarUrl != null && vol.avatarUrl!.trim().isNotEmpty;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: corBordaClaro,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: corAzul.withValues(alpha: 0.14),
                      backgroundImage:
                          temAvatar ? NetworkImage(vol.avatarUrl!) : null,
                      child: !temAvatar
                          ? Text(
                              _iniciais(vol.nome),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: corAzul,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vol.nome.isNotEmpty ? vol.nome : "Voluntário",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0B253A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "$posicaoº lugar no ranking • ${vol.acoesConcluidas >= 2 ? 'Participação recorrente' : 'Voluntário ativo'}",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: corAzul,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: corFundoClaro,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: corBordaClaro),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Ações concluídas",
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF4E6E88),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${vol.acoesConcluidas}",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: corAzul,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: corFundoClaro,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: corBordaClaro),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Horas acumuladas",
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF4E6E88),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${vol.horasAcumuladas}h",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: corAzul,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  "Contato e identificação",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B253A),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FAF7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFC2E4DC)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (vol.id.trim().isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "ID: ${vol.id}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF062222),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            InkWell(
                              onTap: () => _copiarValor(ctx, "ID", vol.id),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.copy_rounded,
                                  size: 15,
                                  color: corAzul,
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      const Text(
                        "Telefone e e-mail direto serão exibidos assim que o endpoint de voluntários retornar os dados de contato.",
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF4C7A70),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: corAzul,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    "Fechar",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isDesktop = Responsive.isDesktop(context);
    final dados = _dados;

    final todosVoluntarios =
        dados?.voluntariosGuardioes ?? const <VoluntarioGuardiaoResumo>[];
    final totalVoluntarios = todosVoluntarios.length;
    final totalHorasVoluntarios = todosVoluntarios.fold<int>(
      0,
      (acc, v) => acc + v.horasAcumuladas,
    );
    final double mediaAcoes = totalVoluntarios > 0
        ? todosVoluntarios.fold<int>(0, (acc, v) => acc + v.acoesConcluidas) /
            totalVoluntarios
        : 0;

    final listaFiltrada = _voluntariosRanking;
    final String nomeHeader =
        (dados?.nomeOng.isNotEmpty == true) ? dados!.nomeOng : 'ONG';

    const corAzul = Color(0xFF1A528F);
    const corFundoClaro = Color(0xFFEFF6FC);
    const corBordaClaro = Color(0xFFC8DFF2);

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
                        ? Center(
                            child: CircularProgressIndicator(
                              color: corAzul,
                            ),
                          )
                        : RefreshIndicator(
                            color: corAzul,
                            onRefresh: _carregarVoluntarios,
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
                                      _buildCabecalhoEBuca(
                                        isMobile: isMobile,
                                        corAzul: corAzul,
                                        corFundoClaro: corFundoClaro,
                                        corBordaClaro: corBordaClaro,
                                      ),
                                      const SizedBox(height: 14),
                                      _buildResumoVoluntarios(
                                        totalVoluntarios: totalVoluntarios,
                                        mediaAcoes: mediaAcoes,
                                        totalHoras: totalHorasVoluntarios,
                                        isMobile: isMobile,
                                        corAzul: corAzul,
                                        corFundoClaro: corFundoClaro,
                                        corBordaClaro: corBordaClaro,
                                      ),
                                      const SizedBox(height: 14),
                                      _buildOperacoesPresencaECertificados(
                                        acoes: dados?.acoes ??
                                            const <OngAcaoResumo>[],
                                        corAzul: corAzul,
                                        corFundoClaro: corFundoClaro,
                                        corBordaClaro: corBordaClaro,
                                      ),
                                      const SizedBox(height: 14),
                                      _buildListaRanking(
                                        lista: listaFiltrada,
                                        corAzul: corAzul,
                                        corFundoClaro: corFundoClaro,
                                        corBordaClaro: corBordaClaro,
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

  Widget _buildOperacoesPresencaECertificados({
    required List<OngAcaoResumo> acoes,
    required Color corAzul,
    required Color corFundoClaro,
    required Color corBordaClaro,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: corBordaClaro),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check_outlined, color: corAzul, size: 19),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Presença e Certificados",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B253A),
                  ),
                ),
              ),
              if (acoes.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: _processandoOperacao
                      ? null
                      : _finalizarCertificadosDaAcao,
                  icon: const Icon(
                    Icons.workspace_premium_outlined,
                    size: 14,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Emitir Certificados",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: corAzul,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (acoes.isEmpty)
            const Text(
              "Nenhuma ação cadastrada para gerenciar presenças ou certificados.",
              style: TextStyle(fontSize: 11, color: Color(0xFF4E6E88)),
            )
          else ...[
            DropdownButtonFormField<String>(
              value: _acaoSelecionadaId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: "Selecione o evento",
                isDense: true,
                filled: true,
                fillColor: corFundoClaro,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: corBordaClaro),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: corBordaClaro),
                ),
              ),
              items: acoes.map((acao) {
                return DropdownMenuItem<String>(
                  value: acao.id,
                  child: Text(
                    acao.dataFormatada.isNotEmpty
                        ? "${acao.titulo} (${acao.dataFormatada})"
                        : acao.titulo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF0B253A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _acaoSelecionadaId = val);
                  _carregarInscricoesDaAcao(val);
                }
              },
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: corFundoClaro,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: corBordaClaro),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 15, color: corAzul),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Carga horária automática do evento: $_horasCalculadasEvento ${_horasCalculadasEvento == 1 ? 'hora' : 'horas'}",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: corAzul,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (_carregandoInscricoes)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: corAzul,
                    ),
                  ),
                ),
              )
            else if (_inscricoesAcao.isEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: corFundoClaro,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: corBordaClaro),
                ),
                child: const Text(
                  "Nenhum voluntário inscrito nesta ação.",
                  style: TextStyle(fontSize: 11, color: Color(0xFF4E6E88)),
                ),
              )
            else
              Column(
                children: _inscricoesAcao.map((app) {
                  final volObj = app['volunteer'] is JsonMap
                      ? app['volunteer'] as JsonMap
                      : (app['user'] is JsonMap
                          ? app['user'] as JsonMap
                          : <String, dynamic>{});
                  final nome = (volObj['name'] ??
                          volObj['nome'] ??
                          app['volunteerName'] ??
                          'Voluntário')
                      .toString();
                  final status = (app['status'] ?? '').toString().toUpperCase();
                  final bool jaPresente = app['presente'] == true ||
                      app['attended'] == true ||
                      status == 'PRESENT' ||
                      status == 'ATTENDED' ||
                      status == 'COMPLETED';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: corFundoClaro,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: corBordaClaro),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nome,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0B253A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  jaPresente
                                      ? "Presença confirmada ($_horasCalculadasEvento h)"
                                      : "Status: ${status.isNotEmpty ? status : 'INSCRITO'} • $_horasCalculadasEvento h",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: jaPresente
                                        ? const Color(0xFF389E0D)
                                        : const Color(0xFF4E6E88),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: _processandoOperacao
                                ? null
                                : () => _validarPresencaInscrito(
                                      app,
                                      presente: true,
                                    ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              side: const BorderSide(color: Color(0xFF389E0D)),
                            ),
                            child: const Text(
                              "Presente",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF389E0D),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          OutlinedButton(
                            onPressed: _processandoOperacao
                                ? null
                                : () => _validarPresencaInscrito(
                                      app,
                                      presente: false,
                                    ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              side: const BorderSide(color: Colors.redAccent),
                            ),
                            child: const Text(
                              "Falta",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildCabecalhoEBuca({
    required bool isMobile,
    required Color corAzul,
    required Color corFundoClaro,
    required Color corBordaClaro,
  }) {
    final filtros = [
      (_FiltroVoluntarios.todos, "Todos"),
      (_FiltroVoluntarios.recorrentes, "Recorrentes"),
      (_FiltroVoluntarios.maisHoras, "Mais horas"),
    ];

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: corBordaClaro),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.group_rounded, color: corAzul, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Gestão de voluntários",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B253A),
                  ),
                ),
              ),
              if (_carregando)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: corAzul,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "Ranking de participação, horas acumuladas e detalhes de contato.",
            style: TextStyle(fontSize: 12, color: Color(0xFF4E6E88)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _buscaController,
            onChanged: (val) => setState(() => _termoBusca = val),
            decoration: InputDecoration(
              hintText: "Buscar voluntário por nome...",
              hintStyle:
                  const TextStyle(fontSize: 12, color: Color(0xFF6B89A3)),
              prefixIcon: Icon(Icons.search_rounded, color: corAzul, size: 18),
              suffixIcon: _termoBusca.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      onPressed: () {
                        _buscaController.clear();
                        setState(() => _termoBusca = '');
                      },
                    )
                  : null,
              isDense: true,
              filled: true,
              fillColor: corFundoClaro,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: corBordaClaro),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: corBordaClaro),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: corAzul, width: 1.4),
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
                    color: ativo ? Colors.white : corAzul,
                  ),
                ),
                selected: ativo,
                selectedColor: ativo ? corAzul : corFundoClaro,
                backgroundColor: corFundoClaro,
                side: BorderSide(color: ativo ? corAzul : corBordaClaro),
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

  Widget _buildResumoVoluntarios({
    required int totalVoluntarios,
    required double mediaAcoes,
    required int totalHoras,
    required bool isMobile,
    required Color corAzul,
    required Color corFundoClaro,
    required Color corBordaClaro,
  }) {
    Widget card(String valor, String titulo, IconData icone) {
      return Expanded(
        child: Container(
          padding: EdgeInsets.all(isMobile ? 10 : 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: corBordaClaro),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icone, color: corAzul, size: 18),
              const SizedBox(height: 6),
              Text(
                valor,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 19,
                  fontWeight: FontWeight.bold,
                  color: corAzul,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF4E6E88),
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
        card("$totalVoluntarios", "Voluntários", Icons.people_outline_rounded),
        const SizedBox(width: 8),
        card(
            mediaAcoes.toStringAsFixed(1), "Média ações", Icons.repeat_rounded),
        const SizedBox(width: 8),
        card("${totalHoras}h", "Horas totais", Icons.schedule_rounded),
      ],
    );
  }

  Widget _buildListaRanking({
    required List<VoluntarioGuardiaoResumo> lista,
    required Color corAzul,
    required Color corFundoClaro,
    required Color corBordaClaro,
  }) {
    if (lista.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: corBordaClaro),
        ),
        child: const Text(
          "Nenhum voluntário encontrado para os critérios atuais.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Color(0xFF4E6E88)),
        ),
      );
    }

    return Column(
      children: List.generate(lista.length, (indice) {
        final vol = lista[indice];
        final corRank = _corPosicao(indice);
        final temAvatar =
            vol.avatarUrl != null && vol.avatarUrl!.trim().isNotEmpty;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _abrirDetalhesVoluntario(vol, indice + 1),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: corBordaClaro),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 26,
                      child: Text(
                        "${indice + 1}º",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: corRank,
                        ),
                      ),
                    ),
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: corFundoClaro,
                      backgroundImage:
                          temAvatar ? NetworkImage(vol.avatarUrl!) : null,
                      child: !temAvatar
                          ? Text(
                              _iniciais(vol.nome),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: corAzul,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vol.nome.isNotEmpty ? vol.nome : "Voluntário",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0B253A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${vol.acoesConcluidas} ${vol.acoesConcluidas == 1 ? 'ação' : 'ações'} • ${vol.horasAcumuladas}h",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF4E6E88),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: corFundoClaro,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: corBordaClaro),
                      ),
                      child: Text(
                        "${vol.acoesConcluidas}x",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: corAzul,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Color(0xFF6B89A3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
