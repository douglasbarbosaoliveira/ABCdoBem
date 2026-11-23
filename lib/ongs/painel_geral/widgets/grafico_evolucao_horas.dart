// lib/ongs/painel_geral/widgets/grafico_evolucao_horas.dart

import 'package:flutter/material.dart';

class PontoGraficoHoras {
  final String rotulo;
  final String? subrotulo;
  final double valor;
  final String detalhe;

  const PontoGraficoHoras({
    required this.rotulo,
    this.subrotulo,
    required this.valor,
    required this.detalhe,
  });
}

class GraficoEvolucaoHoras extends StatelessWidget {
  final List<PontoGraficoHoras> pontos;
  final int horasTotais;
  final bool mostrarSetas;
  final bool distribuirNaLargura;
  final ScrollController scrollController;
  final ValueChanged<double> onRolar;

  const GraficoEvolucaoHoras({
    super.key,
    required this.pontos,
    required this.horasTotais,
    required this.mostrarSetas,
    this.distribuirNaLargura = false,
    required this.scrollController,
    required this.onRolar,
  });

  @override
  Widget build(BuildContext context) {
    final double maximo = pontos.isEmpty
        ? 1.0
        : pontos
            .map((p) => p.valor)
            .reduce((a, b) => a > b ? a : b)
            .clamp(1.0, double.infinity);

    const double alturaMaxBarra = 90.0;
    const double larguraColunaFixa = 52.0;
    const double espacamentoFixo = 10.0;
    const double passoFixo = larguraColunaFixa + espacamentoFixo;
    final double larguraMinimaFixa =
        pontos.isEmpty ? 0.0 : (pontos.length * passoFixo) - espacamentoFixo;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6ECE6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    color: Color(0xFF0C6B6B),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Distribuição de Horas Doadas",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF062222),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Total: ${horasTotais}h",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0C6B6B),
                    ),
                  ),
                  if (mostrarSetas) ...[
                    const SizedBox(width: 8),
                    _BotaoSetaGrafico(
                      icone: Icons.chevron_left_rounded,
                      onTap: () => onRolar(-160),
                    ),
                    const SizedBox(width: 4),
                    _BotaoSetaGrafico(
                      icone: Icons.chevron_right_rounded,
                      onTap: () => onRolar(160),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 164,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double larguraDisponivel = constraints.maxWidth;
                final bool usarLarguraEspalhada = distribuirNaLargura &&
                    pontos.isNotEmpty &&
                    larguraDisponivel > larguraMinimaFixa;

                final double larguraConteudo = usarLarguraEspalhada
                    ? larguraDisponivel
                    : larguraMinimaFixa;

                final double larguraItem = usarLarguraEspalhada
                    ? (larguraConteudo / pontos.length).clamp(52.0, 140.0)
                    : larguraColunaFixa;

                final double espacamentoEntreItens = usarLarguraEspalhada
                    ? ((larguraConteudo - (larguraItem * pontos.length)) /
                            (pontos.length > 1 ? pontos.length - 1 : 1))
                        .clamp(8.0, 64.0)
                    : espacamentoFixo;

                final double larguraReal = pontos.isEmpty
                    ? 0.0
                    : usarLarguraEspalhada
                        ? larguraConteudo
                        : (pontos.length *
                                (larguraItem + espacamentoEntreItens)) -
                            espacamentoEntreItens;

                final coordenadasTopo = <Offset>[];
                for (int i = 0; i < pontos.length; i++) {
                  final double cx = usarLarguraEspalhada
                      ? (larguraReal / pontos.length) * (i + 0.5)
                      : (i * (larguraItem + espacamentoEntreItens)) +
                          (larguraItem / 2);

                  final double alturaPct =
                      (pontos[i].valor / maximo).clamp(0.0, 1.0);
                  final double h = (alturaPct * alturaMaxBarra).clamp(
                    pontos[i].valor > 0 ? 8.0 : 3.0,
                    alturaMaxBarra,
                  );
                  final double topY = alturaMaxBarra - h;
                  coordenadasTopo.add(Offset(cx, topY));
                }

                return SingleChildScrollView(
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: larguraReal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 122,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                height: alturaMaxBarra,
                                child: CustomPaint(
                                  painter: _LinhaToposBarrasPainter(
                                    pontos: coordenadasTopo,
                                    corLinha: const Color(0xFF062222),
                                    corPonto: const Color(0xFF0C6B6B),
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: usarLarguraEspalhada
                                    ? MainAxisAlignment.spaceBetween
                                    : MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(pontos.length, (i) {
                                  final p = pontos[i];
                                  final double alturaPct =
                                      (p.valor / maximo).clamp(0.0, 1.0);
                                  final double alturaBarra =
                                      (alturaPct * alturaMaxBarra).clamp(
                                    p.valor > 0 ? 8.0 : 3.0,
                                    alturaMaxBarra,
                                  );

                                  return Padding(
                                    padding: EdgeInsets.only(
                                      right: (!usarLarguraEspalhada &&
                                              i < pontos.length - 1)
                                          ? espacamentoEntreItens
                                          : 0,
                                    ),
                                    child: SizedBox(
                                      width: larguraItem,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            p.detalhe,
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0C6B6B),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            width: 20,
                                            height: alturaBarra,
                                            decoration: BoxDecoration(
                                              color: p.valor > 0
                                                  ? const Color(0xFF0C6B6B)
                                                      .withValues(alpha: 0.72)
                                                  : const Color(0xFFD6ECE6),
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                top: Radius.circular(5),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: usarLarguraEspalhada
                              ? MainAxisAlignment.spaceBetween
                              : MainAxisAlignment.start,
                          children: List.generate(pontos.length, (i) {
                            final p = pontos[i];
                            return Padding(
                              padding: EdgeInsets.only(
                                right: (!usarLarguraEspalhada &&
                                        i < pontos.length - 1)
                                    ? espacamentoEntreItens
                                    : 0,
                              ),
                              child: SizedBox(
                                width: larguraItem,
                                child: Column(
                                  children: [
                                    Text(
                                      p.rotulo,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF062222),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (p.subrotulo != null)
                                      Text(
                                        p.subrotulo!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: Color(0xFF4C7A70),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BotaoSetaGrafico extends StatelessWidget {
  final IconData icone;
  final VoidCallback onTap;

  const _BotaoSetaGrafico({
    required this.icone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FAF7),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFC2E4DC)),
        ),
        child: Icon(
          icone,
          size: 16,
          color: const Color(0xFF0C6B6B),
        ),
      ),
    );
  }
}

class _LinhaToposBarrasPainter extends CustomPainter {
  final List<Offset> pontos;
  final Color corLinha;
  final Color corPonto;

  const _LinhaToposBarrasPainter({
    required this.pontos,
    required this.corLinha,
    required this.corPonto,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pontos.length < 2) return;

    final linhaPaint = Paint()
      ..color = corLinha.withValues(alpha: 0.65)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(pontos.first.dx, pontos.first.dy);
    for (int i = 1; i < pontos.length; i++) {
      path.lineTo(pontos[i].dx, pontos[i].dy);
    }
    canvas.drawPath(path, linhaPaint);

    final pontoPaint = Paint()
      ..color = corPonto
      ..style = PaintingStyle.fill;
    final bordaPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final pt in pontos) {
      canvas.drawCircle(pt, 3.8, pontoPaint);
      canvas.drawCircle(pt, 3.8, bordaPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinhaToposBarrasPainter oldDelegate) {
    return oldDelegate.pontos != pontos ||
        oldDelegate.corLinha != corLinha ||
        oldDelegate.corPonto != corPonto;
  }
}
