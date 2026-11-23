// lib/ongs/perfil/ong_perfil_page.dart

import 'package:flutter/material.dart';

import '../../utils/responsive.dart';
import '../../services/session_service.dart';
import '../../widgets/header/app_header.dart';
import '../../widgets/sidebar/app_sidebar.dart';
import '../../widgets/bottom_nav/app_bottom_nav.dart';
import '../../widgets/match/match_compatibilidade_card.dart';
import '../../mensagens/mensagens_page.dart';
import '../../mensagens/models/chat_models.dart';
import '../../eventos/detalhe/evento_detalhe_page.dart';
import '../models/ong_detail_models.dart';
import '../../ongs/services/ong_detail_service.dart';

import 'widgets/ong_perfil_header.dart';
import 'widgets/ong_perfil_metricas_cards.dart';
import 'widgets/ong_perfil_oportunidades_section.dart';
import 'widgets/ong_perfil_eventos_passados_section.dart';
import 'widgets/ong_perfil_necessidades_section.dart';
import 'widgets/ong_perfil_localizacao_section.dart';
import 'widgets/ong_perfil_feed_section.dart';
import '../../ongs/criar_evento/criar_evento_page.dart';
import '../editar_perfil/editar_perfil_ong_page.dart';

class OngPerfilPage extends StatefulWidget {
  final String ongId;
  final String voluntarioId;
  final String tipoUsuario; // "ong" ou "voluntario"

  const OngPerfilPage({
    super.key,
    required this.ongId,
    required this.voluntarioId,
    this.tipoUsuario = "voluntario",
  });

  @override
  State<OngPerfilPage> createState() => _OngPerfilPageState();
}

class _OngPerfilPageState extends State<OngPerfilPage> {
  final OngDetailService _service = OngDetailService();

  OngDetalheModel? _ong;
  bool _carregando = true;

  bool get isOng => widget.tipoUsuario.trim().toLowerCase() == "ong";

  String get _idResolvido {
    if (widget.voluntarioId.trim().isNotEmpty &&
        widget.voluntarioId != "voluntario-1") {
      return widget.voluntarioId.trim();
    }
    if (SessionService.instance.usuarioId != null &&
        SessionService.instance.usuarioId!.trim().isNotEmpty) {
      return SessionService.instance.usuarioId!.trim();
    }
    return widget.voluntarioId.trim();
  }

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);
    final dados = await _service.buscarDetalhesOng(
      widget.ongId,
      voluntarioId: _idResolvido,
    );
    if (mounted) {
      setState(() {
        _ong = dados;
        _carregando = false;
      });
    }
  }

  void _abrirChatComOng() {
    if (_ong == null) return;
    final conversaDireta = ChatConversation(
      id: _ong!.id,
      interlocutorId: _ong!.id,
      interlocutorNome: _ong!.nome,
      interlocutorFoto: _ong!.logoUrl,
      interlocutorSubtitulo: "${_ong!.cidade}, ${_ong!.estado}",
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MensagensPage(
          usuarioId: _idResolvido,
          tipoUsuario: widget.tipoUsuario,
          conversaInicial: conversaDireta,
        ),
      ),
    );
  }

  Future<void> _abrirDetalhesEvento(OngOportunidadeModel op) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventoDetalhePage(
          eventoId: op.id,
          usuarioAtualId: _idResolvido,
          voluntarioId: _idResolvido,
          isOng: false,
        ),
      ),
    );
    _carregarDados();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isDesktop = Responsive.isDesktop(context);

    final int navIndex = isOng ? 4 : 1;
    final String idAtivo = isOng ? widget.ongId : _idResolvido;

    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF7),
      bottomNavigationBar: isMobile
          ? AppBottomNav(
              currentIndex: navIndex,
              usuarioId: idAtivo,
              tipoUsuario: widget.tipoUsuario,
            )
          : null,
      body: Row(
        children: [
          if (isDesktop)
            AppSidebar(
              currentIndex: navIndex,
              usuarioId: idAtivo,
              tipoUsuario: widget.tipoUsuario,
            ),
          Expanded(
            child: Column(
              children: [
                AppHeader(
                  usuarioId: idAtivo,
                  tipoUsuario: widget.tipoUsuario,
                  nomeUsuario:
                      SessionService.instance.nomeUsuario ?? _ong?.nome,
                  fotoPerfilUrl: _ong?.logoUrl,
                  showBackButton: true,
                ),
                Expanded(
                  child: _carregando || _ong == null
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF0C6B6B),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 24,
                            vertical: 16,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 860),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // 1. Header Compacto e Funcional com Redes Sociais
                                  OngPerfilHeader(
                                    ong: _ong!,
                                    isOng: isOng,
                                    isMobile: isMobile,
                                    onToggleSeguir: () {},
                                    onConversar: _abrirChatComOng,
                                    onEditarDados: () async {
                                      final atualizado =
                                          await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditarPerfilOngPage(
                                            ongId: _ong!.id,
                                            ongAtual: _ong,
                                          ),
                                        ),
                                      );
                                      if (atualizado == true && mounted) {
                                        _carregarDados();
                                      }
                                    },
                                    onCriarEvento: () async {
                                      final criado = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CriarEventoPage(
                                            ongId: _ong!.id,
                                            tipoUsuario: isOng
                                                ? "ong"
                                                : widget.tipoUsuario,
                                          ),
                                        ),
                                      );
                                      if (criado == true && mounted) {
                                        _carregarDados();
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // 2. Métricas Reais da API (logo abaixo do Header)
                                  OngPerfilMetricasCards(
                                    voluntariosAtivos: _ong!.voluntariosAtivos,
                                    eventosRealizados: _ong!.eventosRealizados,
                                    anosAtuacao: _ong!.anosAtuacao,
                                  ),
                                  const SizedBox(height: 16),

                                  // 3. Card de Match (Front-end mockado pronto para API futura)
                                  if (!isOng) ...[
                                    MatchCompatibilidadeCard(
                                      isVisaoOng: false,
                                      isMobile: isMobile,
                                      nomeAlvo: _ong!.nome,
                                      pontosEmComum: <String>[
                                        _ong!.categoria,
                                        "Atuação Presencial",
                                        "Finais de Semana",
                                        "Apoio Comunitário",
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  // 4. Oportunidades e Eventos Abertos (> 1h antes do início)
                                  OngPerfilOportunidadesSection(
                                    oportunidades: _ong!.oportunidadesAbertas,
                                    onVerEvento: _abrirDetalhesEvento,
                                    isMobile: isMobile,
                                  ),

                                  // 4B. Eventos Passados (Realizados)
                                  if (_ong!.eventosPassados.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    OngPerfilEventosPassadosSection(
                                      eventosPassados: _ong!.eventosPassados,
                                      onVerEvento: _abrirDetalhesEvento,
                                      isMobile: isMobile,
                                    ),
                                  ],
                                  const SizedBox(height: 16),

                                  // 5. Sobre a Instituição
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0xFFC2E4DC),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Sobre a Instituição",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF062222),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          _ong!.sobre.isNotEmpty
                                              ? _ong!.sobre
                                              : "Instituição atuante na promoção de impacto social no Grande ABC.",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF3A6868),
                                            height: 1.45,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // 6. Necessidades e Doações
                                  OngPerfilNecessidadesSection(
                                    necessidades: _ong!.necessidadesUrgentes,
                                    chavePix: _ong!.chavePix,
                                    horarioRecebimento:
                                        _ong!.horarioRecebimentoDoacoes,
                                    mostrarBotaoAjudar: !isOng,
                                    onQueroAjudar: _abrirChatComOng,
                                  ),
                                  const SizedBox(height: 16),

                                  // 7. Sede e Localização com OpenStreetMap Dinâmico
                                  OngPerfilLocalizacaoSection(
                                    enderecoCompleto: _ong!.enderecoCompleto,
                                    cidade: _ong!.cidade,
                                    isMobile: isMobile,
                                    latitude: _ong!.latitude,
                                    longitude: _ong!.longitude,
                                  ),
                                  const SizedBox(height: 24),

                                  // 8. Feed com Relatos Recentes
                                  OngPerfilFeedSection(
                                    publicacoes: _ong!.publicacoes,
                                    ongNome: _ong!.nome,
                                    logoUrl: _ong!.logoUrl,
                                    isMobile: isMobile,
                                  ),
                                  const SizedBox(height: 36),
                                ],
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
