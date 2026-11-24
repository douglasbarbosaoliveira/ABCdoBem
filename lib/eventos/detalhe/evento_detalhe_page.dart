// lib/eventos/detalhe/evento_detalhe_page.dart

import 'package:flutter/material.dart';

import '../../utils/responsive.dart';
import '../../services/session_service.dart';
import '../../widgets/header/app_header.dart';
import '../../widgets/sidebar/app_sidebar.dart';
import '../../widgets/bottom_nav/app_bottom_nav.dart';
import '../models/evento_model.dart';
import '../services/evento_service.dart';
import '../../ongs/criar_evento/criar_evento_page.dart';

import 'widgets/evento_detalhe_banner.dart';
import 'widgets/evento_detalhe_vagas_card.dart';
import 'widgets/evento_detalhe_participantes_list.dart';
import 'widgets/evento_detalhe_necessidades_section.dart';
import 'widgets/evento_detalhe_localizacao_section.dart';
import 'widgets/evento_detalhe_mural_caronas.dart';
import 'widgets/evento_detalhe_bottom_bar.dart';
import 'widgets/modal_confirmar_participacao.dart';
import 'widgets/evento_detalhe_chamada_modal.dart';

enum _StatusTemporalEvento {
  inscricoesAbertas,
  inscricoesEncerradas,
  eventoPassado,
  eventoFinalizado,
}

class EventoDetalhePage extends StatefulWidget {
  final String eventoId;
  final String? usuarioAtualId;
  final String? voluntarioId;
  final bool isOng;

  const EventoDetalhePage({
    super.key,
    required this.eventoId,
    this.usuarioAtualId,
    this.voluntarioId,
    this.isOng = false,
  });

  String get idAtivo {
    if (usuarioAtualId != null &&
        usuarioAtualId!.trim().isNotEmpty &&
        usuarioAtualId != 'voluntario-1') {
      return usuarioAtualId!.trim();
    }
    if (voluntarioId != null &&
        voluntarioId!.trim().isNotEmpty &&
        voluntarioId != 'voluntario-1') {
      return voluntarioId!.trim();
    }
    if (SessionService.instance.usuarioId != null &&
        SessionService.instance.usuarioId!.trim().isNotEmpty) {
      return SessionService.instance.usuarioId!.trim();
    }
    return 'voluntario-1';
  }

  @override
  State<EventoDetalhePage> createState() => _EventoDetalhePageState();
}

class _EventoDetalhePageState extends State<EventoDetalhePage> {
  final EventoService _eventoService = EventoService();

  EventoModel? _evento;
  bool _carregando = true;
  bool _aguardandoAprovacao = false;
  bool _houveAlteracao = false;

  bool get _isPerfilOng {
    final bool sessaoEhOng =
        SessionService.instance.role?.trim().toUpperCase() == 'ONG';
    return widget.isOng || sessaoEhOng;
  }

  String get _tipoUsuarioEfetivo => _isPerfilOng ? 'ong' : 'voluntario';

  bool get _isDonoDoEvento {
    if (_evento == null || !_isPerfilOng) return false;
    return _evento!.ongId.isEmpty || _evento!.ongId == widget.idAtivo;
  }

  DateTime _calcularHorarioConclusao(EventoModel ev) {
    final int idxAs = ev.horario.indexOf('às');
    if (idxAs != -1) {
      final String antes = ev.horario.substring(0, idxAs).trim();
      final String depois = ev.horario.substring(idxAs + 2).trim();
      final List<String> pIni = antes.split(':');
      final List<String> pFim = depois.split(':');

      if (pIni.length == 2 && pFim.length == 2) {
        final int? iniH = int.tryParse(pIni[0].trim());
        final int? iniM = int.tryParse(pIni[1].trim());
        final int? fimH = int.tryParse(pFim[0].trim());
        final int? fimM = int.tryParse(pFim[1].trim());

        if (iniH != null && iniM != null && fimH != null && fimM != null) {
          DateTime conclusao = DateTime(
            ev.dataHoraInicio.year,
            ev.dataHoraInicio.month,
            ev.dataHoraInicio.day,
            fimH,
            fimM,
          );
          if (fimH < iniH || (fimH == iniH && fimM <= iniM)) {
            conclusao = conclusao.add(const Duration(days: 1));
          }
          return conclusao;
        }
      }
    }

    final int idxH = ev.horario.indexOf('h');
    int horas = 4;
    if (idxH > 0) {
      final int? parsed = int.tryParse(ev.horario.substring(0, idxH).trim());
      if (parsed != null && parsed > 0) {
        horas = parsed;
      }
    }
    return ev.dataHoraInicio.add(Duration(hours: horas));
  }

  _StatusTemporalEvento _avaliarStatusTemporal(EventoModel ev) {
    if (ev.isFinalizado) {
      return _StatusTemporalEvento.eventoFinalizado;
    }

    final DateTime agora = DateTime.now();
    final DateTime conclusao = _calcularHorarioConclusao(ev);

    if (!agora.isBefore(conclusao)) {
      return _StatusTemporalEvento.eventoPassado;
    }

    final DateTime limiteInscricao =
        ev.dataHoraInicio.subtract(const Duration(hours: 1));
    if (!agora.isBefore(limiteInscricao) || ev.isEsgotado) {
      return _StatusTemporalEvento.inscricoesEncerradas;
    }

    return _StatusTemporalEvento.inscricoesAbertas;
  }

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    if (!mounted) return;
    setState(() => _carregando = true);

    try {
      final ev = await _eventoService.buscarPorId(
        widget.eventoId,
        voluntarioId: widget.idAtivo,
        token: SessionService.instance.token,
      );

      if (mounted) {
        setState(() {
          _evento = ev;
          _carregando = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  void _voltar() {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop(_houveAlteracao);
    }
  }

  void _exibirDialogoSucessoCandidatura() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.schedule_rounded, color: Color(0xFFD46B08)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Inscrição Enviada!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF062222),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Sua solicitação de participação na ação solidária da ${_evento?.ongNome ?? "ONG"} foi registrada com sucesso.\n\nEla está atualmente em análise pela instituição. Você receberá o retorno por e-mail e em seus eventos.',
          style: const TextStyle(
              fontSize: 13, height: 1.4, color: Color(0xFF333333)),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0C6B6B),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child:
                const Text('Entendido', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _inscrever() {
    if (_evento == null) return;
    if (_avaliarStatusTemporal(_evento!) !=
        _StatusTemporalEvento.inscricoesAbertas) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'As inscrições para este evento já foram encerradas (limite de 1h antes do início).',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    ModalConfirmarParticipacao.exibir(
      context,
      evento: _evento!,
      onConfirmar: () async {
        try {
          final ok = await _eventoService.inscreverVoluntario(
            _evento!.id,
            widget.idAtivo,
            token: SessionService.instance.token,
          );

          if (!mounted) return;

          if (ok) {
            setState(() {
              _aguardandoAprovacao = true;
              _houveAlteracao = true;
            });
            _exibirDialogoSucessoCandidatura();
            _carregarDados();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Falha ao registrar candidatura. Tente novamente.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString().replaceAll('Exception: ', '')),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      },
    );
  }

  Future<void> _cancelar() async {
    if (_evento == null) return;
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Inscrição?'),
        content: const Text(
          'Sua vaga ou candidatura será liberada para outros voluntários do Grande ABC.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Manter'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text(
              'Cancelar Candidatura',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmou == true) {
      try {
        await _eventoService.cancelarInscricao(
          _evento!.id,
          widget.idAtivo,
          token: SessionService.instance.token,
        );
        if (mounted) {
          setState(() {
            _aguardandoAprovacao = false;
            _houveAlteracao = true;
          });
        }
        _carregarDados();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Future<void> _abrirGestaoChamada(EventoModel ev) async {
    final alterou = await EventoDetalheChamadaModal.exibir(context, ev);
    if (alterou == true && mounted) {
      _houveAlteracao = true;
      _carregarDados();
    }
  }

  Future<void> _abrirEdicaoEvento(EventoModel ev) async {
    final alterou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CriarEventoPage(
          ongId: widget.idAtivo,
          tipoUsuario: 'ong',
          eventoParaEditar: ev,
        ),
      ),
    );
    if (alterou == true && mounted) {
      _houveAlteracao = true;
      _carregarDados();
    }
  }

  Future<void> _confirmarFinalizacaoEvento(EventoModel ev) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: Color(0xFF0C6B6B)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Finalizar Evento?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF062222),
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Antes de confirmar, certifique-se de já ter salvo a Lista de Chamada acima.\n\n'
          'Ao finalizar este evento:\n'
          '• O status será alterado definitivamente para Concluído;\n'
          '• Os certificados serão emitidos para todos os voluntários marcados como presentes;\n'
          '• Os participantes receberão a notificação de conclusão.\n\n'
          'Deseja continuar?',
          style: TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF333333)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF546E7A)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0C6B6B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Sim, Finalizar Evento',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmou == true && mounted) {
      setState(() => _carregando = true);
      try {
        final ok = await _eventoService.finalizarEvento(
          ev.id,
          token: SessionService.instance.token,
        );

        if (!mounted) return;

        if (ok) {
          setState(() {
            _houveAlteracao = true;
            _evento = ev.copyWith(status: 'CONCLUIDA');
            _carregando = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Evento finalizado e certificados emitidos com sucesso!',
              ),
              backgroundColor: Color(0xFF0C6B6B),
            ),
          );
          await _carregarDados();
        } else {
          setState(() => _carregando = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível finalizar o evento.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _carregando = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Widget _buildBadgeStatusTemporal(_StatusTemporalEvento status) {
    late final String label;
    late final Color bgColor;
    late final Color textColor;
    late final IconData icon;

    switch (status) {
      case _StatusTemporalEvento.inscricoesAbertas:
        label = 'Inscrições Abertas';
        bgColor = const Color(0xFFD1F5EE);
        textColor = const Color(0xFF0C6B6B);
        icon = Icons.event_available_rounded;
        break;
      case _StatusTemporalEvento.inscricoesEncerradas:
        label = 'Inscrições Encerradas';
        bgColor = const Color(0xFFFFF7E6);
        textColor = const Color(0xFFD46B08);
        icon = Icons.lock_clock_rounded;
        break;
      case _StatusTemporalEvento.eventoPassado:
        label = 'Evento Passado';
        bgColor = const Color(0xFFECEFF1);
        textColor = const Color(0xFF546E7A);
        icon = Icons.history_rounded;
        break;
      case _StatusTemporalEvento.eventoFinalizado:
        label = 'Evento Concluído';
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF1B5E20);
        icon = Icons.verified_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: status == _StatusTemporalEvento.eventoFinalizado
            ? Border.all(color: const Color(0xFFA5D6A7))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerEventoConcluido() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF81C784), width: 1.2),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_rounded, color: Color(0xFF2E7D32), size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ação Solidária Concluída',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Este evento já foi encerrado pela organização e os certificados dos voluntários presentes foram emitidos.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecaoFinalizarEvento(EventoModel ev) {
    if (ev.isFinalizado) {
      return _buildBannerEventoConcluido();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD591)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.flag_circle_rounded,
                color: Color(0xFFD46B08),
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Chamada & Encerramento da Ação',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF062222),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '1º Confira a presença dos voluntários na Lista de Chamada.\n'
            '2º Finalize o evento para encerrar as inscrições e emitir os certificados aos presentes.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: Color(0xFF546E7A),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => _abrirGestaoChamada(ev),
              icon: const Icon(
                Icons.checklist_rtl_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '1. Fazer / Conferir Lista de Chamada',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C6B6B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () => _confirmarFinalizacaoEvento(ev),
              icon: const Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFFD46B08),
                size: 18,
              ),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '2. Finalizar Evento e Emitir Certificados',
                  style: TextStyle(
                    color: Color(0xFFD46B08),
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFD46B08), width: 1.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarraInferior(
    EventoModel ev,
    _StatusTemporalEvento statusTemporal, {
    required bool incluirSafeAreaBottom,
  }) {
    final bool isEncerradoOuPassado =
        statusTemporal == _StatusTemporalEvento.eventoPassado ||
            statusTemporal == _StatusTemporalEvento.eventoFinalizado;

    return EventoDetalheBottomBar(
      evento: ev,
      isDono: _isDonoDoEvento,
      isEventoPassado: isEncerradoOuPassado,
      isInscricoesEncerradas:
          statusTemporal == _StatusTemporalEvento.inscricoesEncerradas,
      aguardandoAprovacaoLocal: _aguardandoAprovacao,
      incluirSafeAreaBottom: incluirSafeAreaBottom,
      onInscrever: _inscrever,
      onCancelar: _cancelar,
      onEditarEvento: () => _abrirEdicaoEvento(ev),
      onAbrirChamada: () => _abrirGestaoChamada(ev),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isDesktop = Responsive.isDesktop(context);
    final int navIndex = _isPerfilOng ? 1 : 2;
    final String idSessao = widget.idAtivo;

    final EventoModel? ev = _evento;
    final _StatusTemporalEvento? statusTemporal =
        ev != null ? _avaliarStatusTemporal(ev) : null;
    final bool isEventoPassado =
        statusTemporal == _StatusTemporalEvento.eventoPassado ||
            statusTemporal == _StatusTemporalEvento.eventoFinalizado;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _voltar();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0FAF7),
        bottomNavigationBar: !isDesktop
            ? Column(
                key: const ValueKey('mobile_bottom_container'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (ev != null && statusTemporal != null)
                    _buildBarraInferior(
                      ev,
                      statusTemporal,
                      incluirSafeAreaBottom: false,
                    ),
                  AppBottomNav(
                    currentIndex: navIndex,
                    usuarioId: idSessao,
                    tipoUsuario: _tipoUsuarioEfetivo,
                  ),
                ],
              )
            : null,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isDesktop)
              AppSidebar(
                key: const ValueKey('desktop_sidebar'),
                currentIndex: navIndex,
                usuarioId: idSessao,
                tipoUsuario: _tipoUsuarioEfetivo,
              ),
            Expanded(
              child: Column(
                children: [
                  AppHeader(
                    usuarioId: idSessao,
                    tipoUsuario: _tipoUsuarioEfetivo,
                    nomeUsuario: SessionService.instance.nomeUsuario,
                    showBackButton: true,
                    onVoltar: _voltar,
                  ),
                  Expanded(
                    child: _carregando
                        ? const Center(
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: CircularProgressIndicator(
                                strokeWidth: 3.0,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF0C6B6B),
                                ),
                              ),
                            ),
                          )
                        : ev == null
                            ? _buildEstadoNaoEncontrado()
                            : _buildConteudoEvento(
                                ev,
                                statusTemporal!,
                                isEventoPassado: isEventoPassado,
                                isMobile: isMobile,
                                idSessao: idSessao,
                              ),
                  ),
                  if (isDesktop && ev != null && statusTemporal != null)
                    _buildBarraInferior(
                      ev,
                      statusTemporal,
                      incluirSafeAreaBottom: true,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoNaoEncontrado() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          const Text(
            'Ação solidária não encontrada.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF062222),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _voltar,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0C6B6B),
            ),
            child: const Text('Voltar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildConteudoEvento(
    EventoModel ev,
    _StatusTemporalEvento statusTemporal, {
    required bool isEventoPassado,
    required bool isMobile,
    required String idSessao,
  }) {
    final Widget banner = EventoDetalheBanner(
      evento: ev,
      isDono: _isDonoDoEvento,
      onVoltar: _voltar,
    );

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 0 : 24,
              vertical: isMobile ? 0 : 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isMobile)
                  banner
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: banner,
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16.0 : 4.0,
                    16.0,
                    isMobile ? 16.0 : 4.0,
                    36.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBadgeStatusTemporal(statusTemporal),
                      const SizedBox(height: 8),
                      Text(
                        ev.titulo,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF062222),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ev.ongNome} • ${ev.data} às ${ev.horario}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0C6B6B),
                        ),
                      ),
                      if (ev.isFinalizado) ...[
                        const SizedBox(height: 14),
                        _buildBannerEventoConcluido(),
                      ],
                      const SizedBox(height: 16),
                      if (!isEventoPassado) ...[
                        EventoDetalheVagasCard(
                          evento: ev,
                          isDono: _isDonoDoEvento,
                        ),
                        const SizedBox(height: 14),
                      ],
                      EventoDetalheParticipantesList(
                        evento: ev,
                        isDono: _isDonoDoEvento,
                        isEventoPassado: isEventoPassado,
                        usuarioLogadoId: idSessao,
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFC2E4DC)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sobre a Ação',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF062222),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ev.descricao,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      EventoDetalheNecessidadesSection(
                        evento: ev,
                        isDono: _isDonoDoEvento,
                      ),
                      const SizedBox(height: 14),
                      EventoDetalheLocalizacaoSection(
                        evento: ev,
                        isDono: _isDonoDoEvento,
                      ),
                      const SizedBox(height: 14),
                      EventoDetalheMuralCaronas(
                        evento: ev,
                        usuarioAtualId: idSessao,
                        isDono: _isDonoDoEvento,
                      ),
                      if (_isDonoDoEvento) ...[
                        const SizedBox(height: 18),
                        _buildSecaoFinalizarEvento(ev),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}