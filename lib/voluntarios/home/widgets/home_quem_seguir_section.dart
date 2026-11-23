// lib/voluntarios/home/widgets/home_quem_seguir_section.dart

import 'package:flutter/material.dart';

class HomeQuemSeguirSection extends StatefulWidget {
  final List<dynamic> perfis;
  final Function(Map<String, dynamic>) onPerfilTap;
  final Function(int)? onToggleSeguir;
  final VoidCallback onVerOngs;

  const HomeQuemSeguirSection({
    super.key,
    required this.perfis,
    required this.onPerfilTap,
    this.onToggleSeguir,
    required this.onVerOngs,
  });

  @override
  State<HomeQuemSeguirSection> createState() => _HomeQuemSeguirSectionState();
}

class _HomeQuemSeguirSectionState extends State<HomeQuemSeguirSection> {
  final ScrollController _scrollController = ScrollController();
  bool _podeVoltar = false;
  bool _podeAvancar = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_atualizarEstadoSetas);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _atualizarEstadoSetas());
  }

  @override
  void didUpdateWidget(covariant HomeQuemSeguirSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _atualizarEstadoSetas());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_atualizarEstadoSetas);
    _scrollController.dispose();
    super.dispose();
  }

  void _atualizarEstadoSetas() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final novoPodeVoltar = pos.pixels > 8;
    final novoPodeAvancar = pos.pixels < (pos.maxScrollExtent - 8);

    if (novoPodeVoltar != _podeVoltar || novoPodeAvancar != _podeAvancar) {
      setState(() {
        _podeVoltar = novoPodeVoltar;
        _podeAvancar = novoPodeAvancar;
      });
    }
  }

  void _rolarCarrossel(double delta) {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final destino = (pos.pixels + delta).clamp(0.0, pos.maxScrollExtent);
    _scrollController.animateTo(
      destino,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    const double larguraCard = 160;
    const double espacamentoCard = 10;
    const double passoScroll = (larguraCard + espacamentoCard) * 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  const Text(
                    "Conecte-se com",
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF062222),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: widget.onVerOngs,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                "Explorar",
                style: TextStyle(
                  color: Color(0xFF0C6B6B),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 184,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: widget.perfis.length,
                itemBuilder: (context, index) {
                  final raw = widget.perfis[index];
                  final Map<String, dynamic> item = raw is Map<String, dynamic>
                      ? raw
                      : Map<String, dynamic>.from(raw as Map);

                  final String tipo = (item["tipo"] ?? "ONG").toString();
                  final bool isOng = tipo.toUpperCase() == "ONG";
                  final String fotoUrl = (item["foto"] ?? "").toString().trim();
                  final int? matchScore = item["matchScore"] is int
                      ? item["matchScore"] as int
                      : int.tryParse(item["matchScore"]?.toString() ?? '');

                  final Color corPrincipal =
                      isOng ? const Color(0xFF0C6B6B) : const Color(0xFF1A528F);
                  final Color corSuave =
                      isOng ? const Color(0xFFE3F5F1) : const Color(0xFFE8F1FC);
                  final Color corBorda =
                      isOng ? const Color(0xFF9FE8D8) : const Color(0xFFB6D4FA);

                  return Padding(
                    padding: const EdgeInsets.only(right: espacamentoCard),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => widget.onPerfilTap(item),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: larguraCard,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: corBorda, width: 1.2),
                          ),
                          child: Column(
                            children: [
                              Container(
                                height: 6,
                                width: double.infinity,
                                color: corPrincipal,
                              ),
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 8, 10, 10),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (matchScore != null && matchScore > 0)
                                        Align(
                                          alignment: Alignment.topRight,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: corSuave,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              "$matchScore% Match",
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: corPrincipal,
                                              ),
                                            ),
                                          ),
                                        )
                                      else
                                        const SizedBox(height: 14),
                                      Stack(
                                        alignment: Alignment.bottomRight,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: corPrincipal
                                                    .withOpacity(0.45),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: CircleAvatar(
                                              radius: 25,
                                              backgroundColor: corSuave,
                                              backgroundImage:
                                                  fotoUrl.isNotEmpty
                                                      ? NetworkImage(fotoUrl)
                                                      : null,
                                              child: fotoUrl.isEmpty
                                                  ? Icon(
                                                      isOng
                                                          ? Icons
                                                              .business_rounded
                                                          : Icons
                                                              .person_rounded,
                                                      color: corPrincipal,
                                                      size: 24,
                                                    )
                                                  : null,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 1.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: corPrincipal,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            child: Text(
                                              isOng ? "ONG" : "Voluntário",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 7.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        (item["nome"] ?? "").toString(),
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF062222),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        (item["subtitulo"] ?? "").toString(),
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          color: Color(0xFF5A8A80),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                      const Spacer(),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 27,
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              widget.onPerfilTap(item),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: corSuave,
                                            foregroundColor: corPrincipal,
                                            elevation: 0,
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(7),
                                            ),
                                          ),
                                          child: const Text(
                                            "Ver perfil",
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                            ),
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
                  );
                },
              ),
              if (widget.perfis.length > 1 && _podeVoltar)
                Positioned(
                  left: 4,
                  child: _buildSetaNavegacao(
                    icon: Icons.chevron_left_rounded,
                    tooltip: 'Anterior',
                    onTap: () => _rolarCarrossel(-passoScroll),
                  ),
                ),
              if (widget.perfis.length > 1 && _podeAvancar)
                Positioned(
                  right: 4,
                  child: _buildSetaNavegacao(
                    icon: Icons.chevron_right_rounded,
                    tooltip: 'Próximo',
                    onTap: () => _rolarCarrossel(passoScroll),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeLegenda({
    required String label,
    required Color corTexto,
    required Color corFundo,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          color: corTexto,
        ),
      ),
    );
  }

  Widget _buildSetaNavegacao({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.95),
      elevation: 3,
      shadowColor: const Color(0xFF062222).withOpacity(0.25),
      shape: const CircleBorder(
        side: BorderSide(color: Color(0xFF8CD3C3), width: 1.2),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              icon,
              color: const Color(0xFF0C6B6B),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
