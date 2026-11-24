// lib/voluntarios/perfil/voluntario_perfil_page.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../utils/responsive.dart';
import '../../services/session_service.dart';
import '../../widgets/header/app_header.dart';
import '../../widgets/sidebar/app_sidebar.dart';
import '../../widgets/bottom_nav/app_bottom_nav.dart';
import '../../../login/login_page.dart';
import '../../../mensagens/chat_conversa_page.dart';

import '../models/voluntario_profile_models.dart';
import '../services/voluntario_profile_service.dart';

import 'widgets/perfil_header_banner.dart';
import 'widgets/perfil_metricas_cards.dart';
import 'widgets/perfil_info_card.dart';
import 'widgets/perfil_redes_sociais_card.dart';
import 'widgets/perfil_feed_experiencias.dart';
import 'widgets/modal_foto_perfil.dart';
import 'widgets/modal_nova_experiencia.dart';
import 'widgets/modal_compartilhar_social.dart';

class VoluntarioPerfilPage extends StatefulWidget {
  final String usuarioId;
  final String? usuarioLogadoId;
  final String tipoUsuario;
  final String? token;

  const VoluntarioPerfilPage({
    super.key,
    required this.usuarioId,
    this.usuarioLogadoId,
    this.tipoUsuario = "voluntario",
    this.token,
  });

  @override
  State<VoluntarioPerfilPage> createState() => _VoluntarioPerfilPageState();
}

class _VoluntarioPerfilPageState extends State<VoluntarioPerfilPage> {
  final VoluntarioProfileService _service = VoluntarioProfileService();
  final ImagePicker _picker = ImagePicker();

  VoluntarioPerfilModel? _perfil;
  bool _carregando = true;
  String? _mensagemErro;
  File? _novaFotoPerfilArquivo;

  String get _idResolvido {
    final sessaoId = SessionService.instance.usuarioId?.trim();
    final paramId = widget.usuarioId.trim();

    if (paramId.isEmpty ||
        paramId == "meu-perfil" ||
        paramId == "voluntario-1") {
      if (sessaoId != null && sessaoId.isNotEmpty) {
        return sessaoId;
      }
    }
    return paramId;
  }

  String? get _tokenResolvido =>
      (widget.token != null && widget.token!.trim().isNotEmpty)
          ? widget.token!.trim()
          : SessionService.instance.token;

  bool get _isMeuPerfil {
    final sessaoId = SessionService.instance.usuarioId?.trim();
    if (sessaoId == null || sessaoId.isEmpty) return false;
    return _idResolvido == sessaoId;
  }

  List<String> get _titulosEventosParticipados {
    if (_perfil == null) return const <String>[];
    return _perfil!.acoesParticipadas
        .map((a) => a.titulo)
        .where((t) => t.trim().isNotEmpty)
        .toSet()
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  @override
  void didUpdateWidget(covariant VoluntarioPerfilPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.usuarioId != widget.usuarioId ||
        oldWidget.token != widget.token) {
      _carregarPerfil();
    }
  }

  Future<void> _carregarPerfil({bool forcarAtualizacao = false}) async {
    if (!mounted) return;
    setState(() {
      _carregando = true;
      _mensagemErro = null;
    });

    try {
      final res = await _service.buscarPerfil(
        _idResolvido,
        token: _tokenResolvido,
        forcarAtualizacao: forcarAtualizacao,
      );

      if (mounted) {
        setState(() {
          _perfil = res;
          _carregando = false;
        });
      }
    } catch (e) {
      debugPrint(">>> [Perfil] Erro ao carregar perfil real: $e");
      if (mounted) {
        setState(() {
          _mensagemErro = e.toString().replaceFirst("Exception: ", "");
          _carregando = false;
        });
      }
    }
  }

  void _abrirSeletorFotoPerfil() {
    if (!_isMeuPerfil) return;
    ModalFotoPerfil.exibir(
      context,
      picker: _picker,
      onImagemArquivo: (file) async {
        setState(() => _novaFotoPerfilArquivo = File(file.path));
        final bytes = await file.readAsBytes();
        final base64Img = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        await _service.atualizarPerfil(
          _idResolvido,
          {'avatar': base64Img},
          token: _tokenResolvido,
        );
        SessionService.instance.atualizarFotoUrl(base64Img);
        if (_perfil != null && mounted) {
          setState(() {
            _perfil = _perfil!.copyWith(fotoUrl: base64Img);
          });
        }
      },
      onImagemUrl: (url) async {
        if (_perfil != null) {
          await _service.atualizarPerfil(
            _idResolvido,
            {'avatar': url},
            token: _tokenResolvido,
          );
          SessionService.instance.atualizarFotoUrl(url);
          if (mounted) {
            setState(() {
              _novaFotoPerfilArquivo = null;
              _perfil = _perfil!.copyWith(fotoUrl: url);
            });
          }
        }
      },
    );
  }

  void _iniciarConversaComVoluntario() {
    if (_perfil == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatConversaPage(
          destinatarioId: _idResolvido,
          destinatarioNome: _perfil!.nome,
          destinatarioFoto: _perfil!.fotoUrl,
        ),
      ),
    );
  }

  void _abrirModalNovaExperiencia() {
    if (!_isMeuPerfil) return;

    ModalNovaExperiencia.abrir(
      context: context,
      eventosConcluidos: _titulosEventosParticipados,
      carregandoEventos: _carregando,
      picker: _picker,
      onSolicitarConfirmacao: ({
        required String texto,
        required String origem,
        required List<XFile> imagens,
        required BuildContext modalParentContext,
      }) {
        _confirmarEPublicar(
          texto: texto,
          origem: origem,
          imagens: imagens,
          modalParentContext: modalParentContext,
        );
      },
    );
  }

  void _confirmarEPublicar({
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
          "Confirmar publicação?",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF062222),
          ),
        ),
        content: Text(
          "Sua experiência será compartilhada no ABC do Bem.\n\nOrigem: $origem${imagens.isNotEmpty ? '\nFotos anexadas: ${imagens.length}' : ''}",
          style: const TextStyle(fontSize: 13, color: Color(0xFF3A6868)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmCtx),
            child: const Text("Revisar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(confirmCtx);
              Navigator.pop(modalParentContext);

              final sucesso = await _service.publicarExperiencia(
                _idResolvido,
                texto,
                null,
                opportunityId: origem != "Postagem Livre" ? origem : null,
                imagensArquivos: imagens,
                token: _tokenResolvido,
              );

              if (!mounted) return;

              if (sucesso) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Experiência publicada com sucesso!'),
                  ),
                );
                _carregarPerfil();

                ModalCompartilharSocial.exibir(
                  context,
                  texto: texto,
                  origem: origem,
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
              "Sim, publicar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmarLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Sair da conta"),
        content: const Text("Deseja realmente sair?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              SessionService.instance.limparSessao();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Sair", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isDesktop = Responsive.isDesktop(context);
    final bool souEu = _isMeuPerfil;
    final int navIndex = souEu ? 4 : -1;
    final String sessaoId = SessionService.instance.usuarioId ?? _idResolvido;

    return Scaffold(
      // Fundo menta com mais contraste para destacar os cards brancos
      backgroundColor: const Color(0xFFE2F3EF),
      bottomNavigationBar: !isDesktop
          ? AppBottomNav(
              currentIndex: navIndex,
              usuarioId: sessaoId,
              tipoUsuario: widget.tipoUsuario,
            )
          : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isDesktop)
            AppSidebar(
              currentIndex: navIndex,
              usuarioId: sessaoId,
              tipoUsuario: widget.tipoUsuario,
            ),
          Expanded(
            child: Column(
              children: [
                AppHeader(
                  usuarioId: SessionService.instance.usuarioId ?? _idResolvido,
                  tipoUsuario: widget.tipoUsuario,
                  nomeUsuario:
                      SessionService.instance.nomeUsuario ?? "Meu Perfil",
                  fotoPerfilUrl: souEu ? _perfil?.fotoUrl : null,
                  showBackButton: !souEu,
                  onPerfilAtualizado: _carregarPerfil,
                ),
                Expanded(
                  child: _carregando
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF0C6B6B),
                          ),
                        )
                      : _mensagemErro != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      size: 54,
                                      color: Colors.redAccent,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _mensagemErro!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF062222),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _carregarPerfil,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF0C6B6B),
                                      ),
                                      child: const Text(
                                        "Tentar Novamente",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 12 : 24,
                                vertical: 16,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 820),
                                  child: Column(
                                    children: [
                                      PerfilHeaderBanner(
                                        perfil: _perfil!,
                                        novaFotoPerfilArquivo:
                                            _novaFotoPerfilArquivo,
                                        onAlterarFoto: _abrirSeletorFotoPerfil,
                                        onPerfilAtualizado: _carregarPerfil,
                                        onConversar:
                                            _iniciarConversaComVoluntario,
                                        isMobile: isMobile,
                                        isMeuPerfil: souEu,
                                        token: _tokenResolvido,
                                      ),
                                      const SizedBox(height: 16),
                                      PerfilMetricasCards(
                                        totalEventos: _perfil!.totalEventos,
                                        totalHoras: _perfil!.totalHoras,
                                        tempoAtivo: _perfil!.tempoAtivo,
                                        estrelas: _perfil!.estrelasEngajamento,
                                      ),
                                      const SizedBox(height: 16),
                                      PerfilInfoCard(
                                        titulo: "Sobre mim",
                                        conteudo: Container(
                                          padding: const EdgeInsets.only(
                                            left: 12,
                                            top: 2,
                                            bottom: 2,
                                          ),
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              left: BorderSide(
                                                color: Color(0xFF0C6B6B),
                                                width: 3,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            _perfil!.bio.isNotEmpty
                                                ? _perfil!.bio
                                                : "Nenhuma biografia informada.",
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              color: Color(0xFF285252),
                                              height: 1.45,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (_perfil!
                                          .causasInteresse.isNotEmpty) ...[
                                        const SizedBox(height: 14),
                                        PerfilInfoCard(
                                          titulo: "Causas de Interesse",
                                          conteudo: Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: _perfil!.causasInteresse
                                                .map((c) => _buildBadgeCausa(c))
                                                .toList(),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 14),
                                      PerfilInfoCard(
                                        titulo: "Habilidades & Competências",
                                        conteudo: _perfil!.habilidades.isEmpty
                                            ? const Text(
                                                "Nenhuma competência cadastrada.",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF7AAAA0),
                                                ),
                                              )
                                            : Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: _perfil!.habilidades
                                                    .map((h) =>
                                                        _buildBadgeHabilidade(
                                                            h))
                                                    .toList(),
                                              ),
                                      ),
                                      if (_perfil!.escolaridade.isNotEmpty ||
                                          _perfil!.curso.isNotEmpty) ...[
                                        const SizedBox(height: 14),
                                        PerfilInfoCard(
                                          titulo: "Formação & Escolaridade",
                                          conteudo: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF3FBF9),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: const Color(0xFFD1EFE8),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(7),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFF0C6B6B)
                                                            .withOpacity(0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: const Icon(
                                                    Icons.school_rounded,
                                                    size: 18,
                                                    color: Color(0xFF0C6B6B),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    [
                                                      if (_perfil!.escolaridade
                                                          .isNotEmpty)
                                                        _perfil!.escolaridade,
                                                      if (_perfil!
                                                          .curso.isNotEmpty)
                                                        _perfil!.curso,
                                                    ].join(" • "),
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Color(0xFF062222),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 14),
                                      PerfilInfoCard(
                                        titulo: "Disponibilidade no ABC",
                                        conteudo:
                                            _perfil!.disponibilidade.isEmpty
                                                ? const Text(
                                                    "Nenhuma disponibilidade informada.",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF7AAAA0),
                                                    ),
                                                  )
                                                : Wrap(
                                                    spacing: 8,
                                                    runSpacing: 8,
                                                    children: _perfil!
                                                        .disponibilidade
                                                        .map((d) =>
                                                            _buildBadgeDisponibilidade(
                                                                d))
                                                        .toList(),
                                                  ),
                                      ),
                                      const SizedBox(height: 14),
                                      PerfilRedesSociaisCard(
                                        instagram: _perfil!.instagram,
                                        facebook: _perfil!.facebook,
                                        linkedin: _perfil!.linkedin,
                                        tiktok: _perfil!.tiktok,
                                        site: _perfil!.site,
                                        whatsapp: _perfil!.whatsapp,
                                      ),
                                      const SizedBox(height: 24),
                                      PerfilFeedExperiencias(
                                        experiencias: _perfil!.experiencias,
                                        acoesParticipadas:
                                            _perfil!.acoesParticipadas,
                                        fotoUsuario: _perfil!.fotoUrl,
                                        nomeUsuario: _perfil!.nome,
                                        onPublicarNova:
                                            _abrirModalNovaExperiencia,
                                        isMobile: isMobile,
                                        isMeuPerfil: souEu,
                                      ),
                                      const SizedBox(height: 24),
                                      if (souEu) ...[
                                        TextButton(
                                          onPressed: _confirmarLogout,
                                          child: const Text(
                                            "Sair da conta",
                                            style: TextStyle(
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 32),
                                      ] else
                                        const SizedBox(height: 24),
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

  /// Badge com destaque em âmbar/dourado para competências
  Widget _buildBadgeHabilidade(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFDCF5EE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF9EDEC9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            size: 15,
            color: Color(0xFFD98218),
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF084C4C),
            ),
          ),
        ],
      ),
    );
  }

  /// Badge em tom coral suave para causas sociais
  Widget _buildBadgeCausa(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFCCD5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.favorite_rounded,
            size: 14,
            color: Color(0xFFD9385A),
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF801B32),
            ),
          ),
        ],
      ),
    );
  }

  /// Badge em azul celeste suave para horários/disponibilidade
  Widget _buildBadgeDisponibilidade(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5FC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFB8DCF2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 14,
            color: Color(0xFF0B6E99),
          ),
          const SizedBox(width: 5),
          Text(
            texto,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF074866),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
