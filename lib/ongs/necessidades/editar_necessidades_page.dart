// lib/ongs/necessidades/editar_necessidades_page.dart

import 'package:flutter/material.dart';

import '../../nlp/ia_sugestao_causa_service.dart';
import '../../nlp/pln_pipeline_service.dart';
import '../../services/session_service.dart';
import '../../utils/responsive.dart';
import '../../widgets/header/app_header.dart';
import '../../widgets/sidebar/app_sidebar.dart';

class EditarNecessidadesPage extends StatefulWidget {
  final List<String> necessidadesIniciais;
  final String? ongId;
  final String? causaOng;
  final String? nomeOng;
  final String? fotoPerfilUrl;

  /// Lista de títulos ou descrições dos eventos ativos da ONG (vindos da API)
  final List<String> textosEventosAtivos;

  final String tituloPagina;
  final String subtituloPagina;
  final String textoBotaoConfirmar;
  final Future<void> Function(List<String>)? onSalvar;

  const EditarNecessidadesPage({
    super.key,
    required this.necessidadesIniciais,
    this.ongId,
    this.causaOng,
    this.nomeOng,
    this.fotoPerfilUrl,
    this.textosEventosAtivos = const [],
    this.tituloPagina = "Necessidades e Doações Urgentes",
    this.subtituloPagina =
        "Adicione os materiais, alimentos ou perfis de voluntários que a instituição mais precisa:",
    this.textoBotaoConfirmar = "Salvar Alterações",
    this.onSalvar,
  });

  /// 1. Uso padrão para o Perfil da ONG (salva direto na API via onSalvar)
  static Future<List<String>?> abrir(
    BuildContext context, {
    required List<String> necessidadesIniciais,
    String? ongId,
    String? causaOng,
    String? nomeOng,
    String? fotoPerfilUrl,
    List<String> textosEventosAtivos = const [],
    String tituloPagina = "Necessidades e Doações Urgentes",
    String subtituloPagina =
        "Adicione os materiais, alimentos ou perfis de voluntários que a instituição mais precisa:",
    String textoBotaoConfirmar = "Salvar Alterações",
    Future<void> Function(List<String>)? onSalvar,
  }) {
    return Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => EditarNecessidadesPage(
          necessidadesIniciais: necessidadesIniciais,
          ongId: ongId,
          causaOng: causaOng,
          nomeOng: nomeOng,
          fotoPerfilUrl: fotoPerfilUrl,
          textosEventosAtivos: textosEventosAtivos,
          tituloPagina: tituloPagina,
          subtituloPagina: subtituloPagina,
          textoBotaoConfirmar: textoBotaoConfirmar,
          onSalvar: onSalvar,
        ),
      ),
    );
  }

  /// 2. Uso dedicado para Cadastro/Edição de Eventos (retorna a lista selecionada para o formulário do evento)
  static Future<List<String>?> abrirParaEvento(
    BuildContext context, {
    required List<String> requisitosIniciais,
    required String tituloEvento,
    String descricaoEvento = '',
    String? causaEvento,
    String? ongId,
    String? nomeOng,
    String? fotoPerfilUrl,
  }) {
    return Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => EditarNecessidadesPage(
          necessidadesIniciais: requisitosIniciais,
          ongId: ongId,
          causaOng: causaEvento,
          nomeOng: nomeOng,
          fotoPerfilUrl: fotoPerfilUrl,
          textosEventosAtivos: [
            if (tituloEvento.trim().isNotEmpty) tituloEvento.trim(),
            if (descricaoEvento.trim().isNotEmpty) descricaoEvento.trim(),
          ],
          tituloPagina: "Materiais e Voluntários do Evento",
          subtituloPagina:
              "Selecione os perfis de voluntários e insumos necessários para realizar esta ação:",
          textoBotaoConfirmar: "Confirmar Itens do Evento",
        ),
      ),
    );
  }

  @override
  State<EditarNecessidadesPage> createState() => _EditarNecessidadesPageState();
}

class _EditarNecessidadesPageState extends State<EditarNecessidadesPage> {
  late List<String> _listaItens;
  final TextEditingController _novoItemCtrl = TextEditingController();
  bool _salvando = false;

  String get _idAtual {
    final paramId = widget.ongId?.trim() ?? '';
    if (paramId.isNotEmpty) return paramId;
    return SessionService.instance.usuarioId?.trim() ?? '';
  }

  @override
  void initState() {
    super.initState();
    _listaItens = List<String>.from(widget.necessidadesIniciais);
  }

  @override
  void dispose() {
    _novoItemCtrl.dispose();
    super.dispose();
  }

  String get _contextoPerfilOng {
    return [
      if (widget.causaOng != null && widget.causaOng!.trim().isNotEmpty)
        widget.causaOng!.trim(),
      if (widget.nomeOng != null && widget.nomeOng!.trim().isNotEmpty)
        widget.nomeOng!.trim(),
    ].join(' ');
  }

  String get _causaLimpaExibicao {
    return IaSugestaoCausaService.removerEmojis(widget.causaOng ?? '');
  }

  void _adicionarItem(String item) {
    final limpo = item.trim();
    if (limpo.isEmpty) return;

    final jaExiste = _listaItens.any(
      (e) => PlnPipelineService.saoSemanticamenteIguais(e, limpo),
    );

    if (jaExiste) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Este item (ou equivalente) já está na lista."),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _listaItens.add(limpo);
      _novoItemCtrl.clear();
    });
  }

  Future<void> _confirmarSalvar() async {
    if (_salvando) return;

    if (widget.onSalvar != null) {
      setState(() => _salvando = true);
      try {
        await widget.onSalvar!(_listaItens);
        if (!mounted) return;
        Navigator.pop(context, _listaItens);
      } catch (e) {
        if (!mounted) return;
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Erro ao salvar: ${e.toString().replaceFirst('Exception: ', '')}",
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      Navigator.pop(context, _listaItens);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isDesktop = Responsive.isDesktop(context);
    final String idAtual = _idAtual;

    final sugestoesPln = PlnPipelineService.recomendarNecessidades(
      tipoOuCausaOng: _contextoPerfilOng,
      textosEventosAtivos: widget.textosEventosAtivos,
      textoDigitado: _novoItemCtrl.text,
      jaSelecionados: _listaItens,
      minimoRecomendacoes: 5,
      limite: 6,
    );

    final int qtdEventosContexto =
        widget.textosEventosAtivos.where((e) => e.trim().isNotEmpty).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF7),
      body: SafeArea(
        child: Row(
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
                    nomeUsuario: widget.nomeOng ??
                        SessionService.instance.nomeUsuario ??
                        "Instituição Parceira",
                    fotoPerfilUrl:
                        widget.fotoPerfilUrl ?? SessionService.instance.fotoUrl,
                    showBackButton: true,
                    onVoltar: _salvando ? null : () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 14 : 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 880),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                widget.tituloPagina,
                                style: TextStyle(
                                  fontSize: isMobile ? 18 : 21,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF062222),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // METADE SUPERIOR (Flex 5): Busca + 5 a 6 Recomendações PLN
                              Expanded(
                                flex: 5,
                                child: Container(
                                  padding: EdgeInsets.all(isMobile ? 14 : 18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFC2E4DC),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.subtituloPagina,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF3A6868),
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _novoItemCtrl,
                                              onChanged: (_) => setState(() {}),
                                              onSubmitted: _adicionarItem,
                                              decoration: InputDecoration(
                                                hintText:
                                                    "Ex: Arroz, feijão, pedagogo voluntário...",
                                                hintStyle: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                                filled: true,
                                                fillColor:
                                                    const Color(0xFFF0FAF7),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 11,
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  borderSide: const BorderSide(
                                                    color: Color(0xFFC2E4DC),
                                                  ),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  borderSide: const BorderSide(
                                                    color: Color(0xFFC2E4DC),
                                                  ),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  borderSide: const BorderSide(
                                                    color: Color(0xFF0C6B6B),
                                                    width: 1.5,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () => _adicionarItem(
                                                _novoItemCtrl.text),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF0C6B6B),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 12,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.add_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Expanded(
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF7FCFA),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: const Color(0xFFD9EFE9),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.auto_awesome_rounded,
                                                    size: 14,
                                                    color: Color(0xFF0C6B6B),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      _causaLimpaExibicao
                                                              .isNotEmpty
                                                          ? "PLN • $_causaLimpaExibicao${qtdEventosContexto > 0 ? ' + $qtdEventosContexto evento(s)' : ''}"
                                                          : "Recomendações PLN para sua instituição",
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color:
                                                            Color(0xFF0C6B6B),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Expanded(
                                                child: SingleChildScrollView(
                                                  child: Wrap(
                                                    spacing: 6,
                                                    runSpacing: 6,
                                                    children: sugestoesPln
                                                        .map((sugestao) {
                                                      return InkWell(
                                                        onTap: () =>
                                                            _adicionarItem(
                                                                sugestao),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 10,
                                                            vertical: 5,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                            border: Border.all(
                                                              color: const Color(
                                                                  0xFF0C6B6B),
                                                            ),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .add_rounded,
                                                                size: 13,
                                                                color: Color(
                                                                    0xFF0C6B6B),
                                                              ),
                                                              const SizedBox(
                                                                  width: 4),
                                                              Flexible(
                                                                child: Text(
                                                                  sugestao,
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        11,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: Color(
                                                                        0xFF062222),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // METADE INFERIOR (Flex 5): Itens Selecionados + Botão Salvar
                              Expanded(
                                flex: 5,
                                child: Container(
                                  padding: EdgeInsets.all(isMobile ? 14 : 18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFC2E4DC),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Itens selecionados (${_listaItens.length})",
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF062222),
                                            ),
                                          ),
                                          if (_listaItens.isNotEmpty)
                                            InkWell(
                                              onTap: () => setState(
                                                () => _listaItens.clear(),
                                              ),
                                              child: const Text(
                                                "Limpar tudo",
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Expanded(
                                        child: _listaItens.isEmpty
                                            ? const Center(
                                                child: Text(
                                                  "Nenhuma necessidade cadastrada no momento.",
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              )
                                            : SingleChildScrollView(
                                                child: Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: _listaItens
                                                      .asMap()
                                                      .entries
                                                      .map((entry) {
                                                    final index = entry.key;
                                                    final item = entry.value;

                                                    return Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 10,
                                                        vertical: 7,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                            0xFFFFF7E6),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                        border: Border.all(
                                                          color: const Color(
                                                              0xFFFFD591),
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          const Icon(
                                                            Icons
                                                                .favorite_rounded,
                                                            size: 13,
                                                            color: Color(
                                                                0xFFD46B08),
                                                          ),
                                                          const SizedBox(
                                                              width: 6),
                                                          Flexible(
                                                            child: Text(
                                                              item,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Color(
                                                                    0xFFD46B08),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 6),
                                                          InkWell(
                                                            onTap: () =>
                                                                setState(
                                                              () => _listaItens
                                                                  .removeAt(
                                                                      index),
                                                            ),
                                                            child: const Icon(
                                                              Icons
                                                                  .close_rounded,
                                                              size: 15,
                                                              color: Color(
                                                                  0xFFD46B08),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                      ),
                                      const SizedBox(height: 10),
                                      ElevatedButton(
                                        onPressed:
                                            _salvando ? null : _confirmarSalvar,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF0C6B6B),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: _salvando
                                            ? const SizedBox(
                                                height: 18,
                                                width: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                                widget.textoBotaoConfirmar,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
      ),
    );
  }
}
