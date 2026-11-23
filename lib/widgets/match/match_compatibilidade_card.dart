// lib/widgets/match/match_compatibilidade_card.dart

import 'package:flutter/material.dart';

class MatchCompatibilidadeCard extends StatelessWidget {
  /// false = Visão do Voluntário vendo uma ONG
  /// true  = Visão da ONG vendo um Voluntário
  final bool isVisaoOng;
  final bool isMobile;
  final String? nomeAlvo;
  final int scoreGeral;
  final String? nivelCompatibilidade;
  final String? resumoAnalise;
  final double? distanciaKm;

  /// Lista de mapas simples: [{'label': 'Habilidades', 'percentual': 92}]
  final List<dynamic>? criterios;
  final List<String>? pontosEmComum;

  const MatchCompatibilidadeCard({
    super.key,
    this.isVisaoOng = false,
    this.isMobile = false,
    this.nomeAlvo,
    this.scoreGeral = 88,
    this.nivelCompatibilidade,
    this.resumoAnalise,
    this.distanciaKm = 3.4,
    this.criterios,
    this.pontosEmComum,
  });

  Color get _corScore {
    if (scoreGeral >= 80) return const Color(0xFF0C6B6B);
    if (scoreGeral >= 55) return const Color(0xFFD97706);
    return const Color(0xFF64748B);
  }

  Color get _corFundoBadge {
    if (scoreGeral >= 80) return const Color(0xFFD1F5EE);
    if (scoreGeral >= 55) return const Color(0xFFFEF3C7);
    return const Color(0xFFF1F5F9);
  }

  @override
  Widget build(BuildContext context) {
    final String tituloCard = isVisaoOng
        ? "Compatibilidade com as Necessidades da ONG"
        : "Sua Compatibilidade com a ONG";

    final String badgeTexto = nivelCompatibilidade ??
        (isVisaoOng ? "Candidato Recomendado" : "Alta Compatibilidade");

    final String alvo = (nomeAlvo != null && nomeAlvo!.trim().isNotEmpty)
        ? nomeAlvo!.trim()
        : (isVisaoOng ? "Este voluntário" : "esta instituição");

    final String textoResumo = resumoAnalise ??
        (isVisaoOng
            ? "$alvo atende aos requisitos prioritários da sua instituição, destacando-se pelas habilidades buscadas e proximidade com a sede."
            : "Seu perfil possui forte aderência às demandas de $alvo, combinando suas habilidades cadastradas, disponibilidade e proximidade no Grande ABC.");

    final List<dynamic> listaCriterios = criterios ??
        (isVisaoOng
            ? const [
                {
                  "label": "Aderência às Habilidades Buscadas",
                  "percentual": 94
                },
                {
                  "label": "Alinhamento com o Público Atendido",
                  "percentual": 89
                },
                {"label": "Compatibilidade de Turnos", "percentual": 85},
              ]
            : const [
                {"label": "Habilidades & Competências", "percentual": 92},
                {"label": "Causa & Propósito Social", "percentual": 90},
                {"label": "Disponibilidade & Formato", "percentual": 82},
              ]);

    final List<String> listaTags = pontosEmComum ??
        (isVisaoOng
            ? const [
                "Organização de Eventos",
                "Atendimento ao Público",
                "Disponibilidade Imediata",
                "Reside no Grande ABC",
              ]
            : const [
                "Apoio Comunitário",
                "Atuação Presencial",
                "Finais de Semana",
                "Grande ABC",
              ]);

    final String subtituloTags = isVisaoOng
        ? "Requisitos atendidos pelo perfil do voluntário:"
        : "Pontos em comum identificados no seu perfil:";

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC2E4DC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho com Gauge Circular
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildScoreIndicator(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: _corScore,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            tituloCard,
                            style: TextStyle(
                              fontSize: isMobile ? 14.5 : 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF062222),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _corFundoBadge,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badgeTexto,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _corScore,
                            ),
                          ),
                        ),
                        if (distanciaKm != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.near_me_rounded,
                                size: 13,
                                color: Color(0xFF5A8A80),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${distanciaKm!.toStringAsFixed(1)} km de distância",
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF5A8A80),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (textoResumo.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6FCFA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDDF2EC)),
              ),
              child: Text(
                textoResumo,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF2D5555),
                  height: 1.4,
                ),
              ),
            ),
          ],

          // Barras de Critérios
          if (listaCriterios.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...listaCriterios.map((dynamic rawItem) {
              final Map item = rawItem is Map ? rawItem : {};
              final String label = item['label']?.toString() ?? '';
              final int percentual =
                  (item['percentual'] as num?)?.toInt().clamp(0, 100) ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1D4444),
                            ),
                          ),
                        ),
                        Text(
                          "$percentual%",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _corScore,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: percentual / 100.0,
                        minHeight: 7,
                        backgroundColor: const Color(0xFFE6F4F0),
                        valueColor: AlwaysStoppedAnimation<Color>(_corScore),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // Chips de Pontos em Comum
          if (listaTags.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtituloTags,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5A8A80),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: listaTags.map((String tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF8F4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFB8E2D7)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 13,
                        color: Color(0xFF0C6B6B),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0C6B6B),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreIndicator() {
    final double tamanho = isMobile ? 62 : 70;
    return SizedBox(
      width: tamanho,
      height: tamanho,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: scoreGeral.clamp(0, 100) / 100.0,
            strokeWidth: 6.5,
            backgroundColor: const Color(0xFFE2F3EE),
            valueColor: AlwaysStoppedAnimation<Color>(_corScore),
            strokeCap: StrokeCap.round,
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${scoreGeral.clamp(0, 100)}%",
                  style: TextStyle(
                    fontSize: isMobile ? 15 : 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF062222),
                  ),
                ),
                const Text(
                  "Match",
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5A8A80),
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
