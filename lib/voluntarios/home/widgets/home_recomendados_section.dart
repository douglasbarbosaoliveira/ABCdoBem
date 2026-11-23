// lib/voluntarios/home/widgets/home_recomendados_section.dart

import 'package:flutter/material.dart';
import '../../../eventos/models/evento_model.dart';
import 'home_evento_inscrito_card.dart';
import 'home_evento_recomendado_card.dart';

typedef MapaRecomendado = Map<String, dynamic>;

class HomeRecomendadosSection extends StatefulWidget {
  final EventoModel? evento;
  final List<MapaRecomendado> eventosRecomendados;
  final List<EventoModel> eventosInscritos;
  final Function(String) onAbrirDetalhes;
  final VoidCallback onVerTodos;
  final bool isMobile;

  const HomeRecomendadosSection({
    super.key,
    this.evento,
    this.eventosRecomendados = const <MapaRecomendado>[],
    this.eventosInscritos = const <EventoModel>[],
    required this.onAbrirDetalhes,
    required this.onVerTodos,
    required this.isMobile,
  });

  @override
  State<HomeRecomendadosSection> createState() =>
      _HomeRecomendadosSectionState();
}

class _HomeRecomendadosSectionState extends State<HomeRecomendadosSection> {
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
  void didUpdateWidget(covariant HomeRecomendadosSection oldWidget) {
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
    final List<MapaRecomendado> listaRecomendados =
        widget.eventosRecomendados.isNotEmpty
            ? widget.eventosRecomendados
            : (widget.evento != null
                ? <MapaRecomendado>[
                    <String, dynamic>{
                      'evento': widget.evento!,
                      'matchScore': 0,
                      'distanciaKm': null,
                    },
                  ]
                : <MapaRecomendado>[]);

    final double larguraCard = widget.isMobile ? 275 : 310;
    final double passoScroll = larguraCard + 14;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.eventosInscritos.isNotEmpty) ...[
          _buildSectionHeader(
            titulo: 'Meus Eventos',
            badgeCount: widget.eventosInscritos.length,
            acaoLabel: 'Ver agenda',
            onAcao: widget.onVerTodos,
          ),
          const SizedBox(height: 8),
          ...widget.eventosInscritos.map(
            (ev) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: HomeEventoInscritoCard(
                evento: ev,
                onTap: () => widget.onAbrirDetalhes(ev.id),
              ),
            ),
          ),
          SizedBox(height: widget.isMobile ? 16 : 22),
        ],
        _buildSectionHeader(
          titulo: 'Recomendados para você',
          subtitulo: 'De acordo com suas habilidades e mais próximos a você',
          acaoLabel: 'Ver todos',
          onAcao: widget.onVerTodos,
        ),
        const SizedBox(height: 10),
        if (listaRecomendados.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC2E4DC)),
            ),
            child: const Center(
              child: Text(
                'Nenhuma recomendação disponível no momento.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          )
        else
          SizedBox(
            height: widget.isMobile ? 268 : 282,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ListView.separated(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: listaRecomendados.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final MapaRecomendado item = listaRecomendados[index];
                    final EventoModel ev = item['evento'] as EventoModel;
                    final int matchScore = (item['matchScore'] as int?) ?? 0;
                    final double? distanciaKm = item['distanciaKm'] as double?;

                    return SizedBox(
                      width: larguraCard,
                      child: HomeEventoRecomendadoCard(
                        evento: ev,
                        matchScore: matchScore,
                        distanciaKm: distanciaKm,
                        onTap: () => widget.onAbrirDetalhes(ev.id),
                      ),
                    );
                  },
                ),
                if (listaRecomendados.length > 1 && _podeVoltar)
                  Positioned(
                    left: 4,
                    child: _buildSetaNavegacao(
                      icon: Icons.chevron_left_rounded,
                      tooltip: 'Anterior',
                      onTap: () => _rolarCarrossel(-passoScroll),
                    ),
                  ),
                if (listaRecomendados.length > 1 && _podeAvancar)
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
            width: 36,
            height: 36,
            child: Icon(
              icon,
              color: const Color(0xFF0C6B6B),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String titulo,
    String? subtitulo,
    int? badgeCount,
    required String acaoLabel,
    required VoidCallback onAcao,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF062222),
                    ),
                  ),
                  if (badgeCount != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1F5EE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0C6B6B),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (subtitulo != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF5A8A80),
                  ),
                ),
              ],
            ],
          ),
        ),
        TextButton(
          onPressed: onAcao,
          child: Text(
            acaoLabel,
            style: const TextStyle(
              color: Color(0xFF0C6B6B),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
