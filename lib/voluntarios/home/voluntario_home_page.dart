// lib/voluntarios/home/voluntario_home_page.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../utils/responsive.dart';
import '../../services/session_service.dart';
import '../../widgets/header/app_header.dart';
import '../../widgets/sidebar/app_sidebar.dart';
import '../../widgets/bottom_nav/app_bottom_nav.dart';
import '../../eventos/voluntario/eventos_page.dart';
import '../../eventos/detalhe/evento_detalhe_page.dart';
import '../../ongs/perfil/ong_perfil_page.dart';
import '../perfil/meu_perfil_page.dart';
import '../../models/dashboard_volunteer_models.dart';
import '../../eventos/models/evento_model.dart';
import '../buscar/buscar_ongs_page.dart';

import '../services/voluntario_profile_service.dart';
import '../services/voluntario_home_service.dart';
import '../services/home_match_service.dart';
import '../perfil/widgets/modal_nova_experiencia.dart';
import '../perfil/widgets/modal_compartilhar_social.dart';

import 'widgets/home_welcome_banner.dart';
import 'widgets/home_recomendados_section.dart';
import 'widgets/home_quem_seguir_section.dart';
import 'widgets/home_feed_comunidade_section.dart';

class VoluntarioHomePage extends StatefulWidget {
  final String voluntarioId;
  final String? nomeUsuario;
  final String? token;

  const VoluntarioHomePage({
    super.key,
    required this.voluntarioId,
    this.nomeUsuario,
    this.token,
  });

  @override
  State<VoluntarioHomePage> createState() => _VoluntarioHomePageState();
}

class _VoluntarioHomePageState extends State<VoluntarioHomePage> {
  final VoluntarioHomeService _homeService = VoluntarioHomeService();
  final VoluntarioProfileService _profileService = VoluntarioProfileService();
  final HomeMatchService _matchService = HomeMatchService();
  final ImagePicker _picker = ImagePicker();

  bool _carregando = true;
  bool _erroConexao = false;
  VoluntarioDashboardModel? _dashboard;
  EventoModel? _eventoRecomendado;
  List<MapaRecomendado> _eventosRecomendados = <MapaRecomendado>[];
  List<EventoModel> _eventosInscritos = <EventoModel>[];

  List<String> _eventosConcluidos = <String>[];
  List<dynamic> _postagensReais = <dynamic>[];
  bool _carregandoFeed = false;

  List<dynamic> _perfisRecomendados = <dynamic>[];
  bool _carregandoRecomendados = false;

  String get _tokenAtivo => widget.token ?? SessionService.instance.token ?? '';

  @override
  void initState() {
    super.initState();
    _inicializarHome();
  }

  Future<void> _inicializarHome() async {
    await Future.wait(<Future<void>>[
      _carregarDados(),
      _carregarFeedComunidade(),
      _carregarRecomendacoesMatch(),
    ]);
  }

  String _resolverNomeUsuario() {
    if (widget.nomeUsuario != null && widget.nomeUsuario!.trim().isNotEmpty) {
      return widget.nomeUsuario!.trim();
    }
    if (SessionService.instance.nomeUsuario != null &&
        SessionService.instance.nomeUsuario!.trim().isNotEmpty) {
      return SessionService.instance.nomeUsuario!.trim();
    }
    return 'Voluntário';
  }

  String _resolverIdUsuario() {
    if (widget.voluntarioId.trim().isNotEmpty &&
        widget.voluntarioId != 'voluntario-1') {
      return widget.voluntarioId.trim();
    }
    if (SessionService.instance.usuarioId != null &&
        SessionService.instance.usuarioId!.trim().isNotEmpty) {
      return SessionService.instance.usuarioId!.trim();
    }
    return widget.voluntarioId.trim();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
      _erroConexao = false;
    });

    try {
      final dados = await _homeService.carregarPainelVoluntario(
        voluntarioId: _resolverIdUsuario(),
        nomeFallback: _resolverNomeUsuario(),
        token: _tokenAtivo,
      );

      if (mounted) {
        setState(() {
          _dashboard = dados.dashboard;
          _eventosInscritos = dados.eventosInscritos;
          _eventosRecomendados = dados.eventosRecomendados;
          _eventoRecomendado = dados.eventoDestaqueFallback;
          _eventosConcluidos = dados.titulosEventosConcluidos;
          _carregando = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados reais da Home: $e');
      if (mounted) {
        setState(() {
          _carregando = false;
          _erroConexao = true;
        });
      }
    }
  }

  Future<void> _carregarFeedComunidade() async {
    setState(() => _carregandoFeed = true);
    try {
      final posts = await _profileService.buscarFeedComunidade(
        token: _tokenAtivo,
        dias: 10,
        limit: 20,
      );
      if (mounted) {
        setState(() {
          _postagensReais = posts;
          _carregandoFeed = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar feed da comunidade: $e');
      if (mounted) setState(() => _carregandoFeed = false);
    }
  }

  Future<void> _carregarRecomendacoesMatch() async {
    setState(() => _carregandoRecomendados = true);
    final recomendados = await _matchService.buscarPerfisRecomendados(
      usuarioAtualId: _resolverIdUsuario(),
      token: _tokenAtivo,
    );
    if (mounted) {
      setState(() {
        _perfisRecomendados = recomendados;
        _carregandoRecomendados = false;
      });
    }
  }

  void _abrirModalNovaPublicacao() {
    ModalNovaExperiencia.abrir(
      context: context,
      eventosConcluidos: _eventosConcluidos,
      carregandoEventos: false,
      picker: _picker,
      onSolicitarConfirmacao: ({
        required String texto,
        required String origem,
        required List<XFile> imagens,
        required BuildContext modalParentContext,
      }) {
        _confirmarEPublicarNaHome(
          texto: texto,
          origem: origem,
          imagens: imagens,
          modalParentContext: modalParentContext,
        );
      },
    );
  }

  void _confirmarEPublicarNaHome({
    required String texto,
    required String origem,
    required List<XFile> imagens,
    required BuildContext modalParentContext,
  }) {
    showDialog(
      context: context,
      builder: (confirmCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirmar publicação?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF062222),
          ),
        ),
        content: Text(
          'Sua experiência será compartilhada com a comunidade do ABC do Bem.\n\nOrigem: $origem${imagens.isNotEmpty ? '\nFotos anexadas: ${imagens.length}' : ''}',
          style: const TextStyle(fontSize: 13, color: Color(0xFF3A6868)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmCtx),
            child: const Text('Revisar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(confirmCtx);
              Navigator.pop(modalParentContext);

              final sucesso = await _profileService.publicarExperiencia(
                _resolverIdUsuario(),
                texto,
                null,
                opportunityId: origem != 'Postagem Livre' ? origem : null,
                imagensArquivos: imagens,
                token: _tokenAtivo,
              );

              if (!mounted) return;

              if (sucesso) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Experiência publicada com sucesso!'),
                  ),
                );
                _carregarFeedComunidade();
                ModalCompartilharSocial.exibir(
                  context,
                  texto: texto,
                  origem: origem,
                  tipo: TipoCompartilhamentoSocial.experiencia,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Falha ao publicar relato no servidor.'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0C6B6B),
            ),
            child: const Text(
              'Sim, publicar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _abrirDetalhesEvento(String eventoId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventoDetalhePage(
          eventoId: eventoId,
          usuarioAtualId: _resolverIdUsuario(),
          voluntarioId: _resolverIdUsuario(),
          isOng: false,
        ),
      ),
    ).then((_) => _carregarDados());
  }

  void _aoClicarPerfil(Map<String, dynamic> item) {
    final tipo = (item['tipo'] ?? '').toString().toUpperCase();
    if (tipo == 'ONG') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OngPerfilPage(
            ongId: item['id'] as String,
            voluntarioId: _resolverIdUsuario(),
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MeuPerfilPage(
            usuarioId: item['id'] as String,
            token: _tokenAtivo,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isDesktop = Responsive.isDesktop(context);
    final String idAtivo = _resolverIdUsuario();
    final String nomeExibicao = _resolverNomeUsuario();

    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF7),
      bottomNavigationBar:
          isMobile ? AppBottomNav(currentIndex: 0, usuarioId: idAtivo) : null,
      body: Row(
        children: [
          if (isDesktop) AppSidebar(currentIndex: 0, usuarioId: idAtivo),
          Expanded(
            child: Column(
              children: [
                AppHeader(
                  usuarioId: idAtivo,
                  tipoUsuario: 'voluntario',
                  nomeUsuario: nomeExibicao,
                  fotoPerfilUrl: _dashboard?.fotoUrl,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 880),
                        child: _carregando
                            ? const Padding(
                                padding: EdgeInsets.all(80.0),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF0C6B6B),
                                  ),
                                ),
                              )
                            : _erroConexao
                                ? _buildErrorState()
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      HomeWelcomeBanner(
                                        dashboard: _dashboard!,
                                        isMobile: isMobile,
                                      ),
                                      SizedBox(height: isMobile ? 20 : 28),
                                      if (_eventosInscritos.isNotEmpty ||
                                          _eventosRecomendados.isNotEmpty ||
                                          _eventoRecomendado != null) ...[
                                        HomeRecomendadosSection(
                                          evento: _eventoRecomendado,
                                          eventosRecomendados:
                                              _eventosRecomendados,
                                          eventosInscritos: _eventosInscritos,
                                          onAbrirDetalhes: _abrirDetalhesEvento,
                                          onVerTodos: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const EventosPage(),
                                              ),
                                            ).then((_) => _carregarDados());
                                          },
                                          isMobile: isMobile,
                                        ),
                                        SizedBox(height: isMobile ? 22 : 30),
                                      ],
                                      if (_perfisRecomendados.isNotEmpty ||
                                          _carregandoRecomendados) ...[
                                        HomeQuemSeguirSection(
                                          perfis: _perfisRecomendados,
                                          onPerfilTap: _aoClicarPerfil,
                                          onVerOngs: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const BuscarOngsPage(),
                                              ),
                                            );
                                          },
                                        ),
                                        SizedBox(height: isMobile ? 22 : 30),
                                      ],
                                      HomeFeedComunidadeSection(
                                        postagens: _postagensReais,
                                        carregando: _carregandoFeed,
                                        onAutorTap: _aoClicarPerfil,
                                        isMobile: isMobile,
                                        onPublicar: _abrirModalNovaPublicacao,
                                      ),
                                      const SizedBox(height: 32),
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

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Colors.redAccent,
            size: 36,
          ),
          const SizedBox(height: 10),
          const Text(
            'Não foi possível carregar seu painel',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF062222),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Verifique sua conexão e tente novamente.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _inicializarHome,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0C6B6B),
            ),
            child: const Text(
              'Tentar novamente',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
