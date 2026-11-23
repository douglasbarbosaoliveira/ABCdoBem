// lib/ongs/painel_geral/widgets/secao_dashboard_impacto.dart

import 'package:flutter/material.dart';
import 'card_painel_base.dart';

enum PeriodoIndicadores { semanal, mensal, anual }

class SecaoDashboardImpacto extends StatelessWidget {
  final bool isMobile;
  final ValueChanged<String> onNavegar;
  final VoidCallback? onAbrirDetalhes;
  final int horasDoadas;
  final int percentualVagasPreenchidas;
  final int percentualRetencaoVoluntarios;
  final double valorArrecadadoDinheiro;
  final double gastos;

  const SecaoDashboardImpacto({
    super.key,
    required this.isMobile,
    required this.onNavegar,
    this.onAbrirDetalhes,
    this.horasDoadas = 0,
    this.percentualVagasPreenchidas = 0,
    this.percentualRetencaoVoluntarios = 0,
    this.valorArrecadadoDinheiro = 0,
    this.gastos = 0,
  });

  String _formatarMoedaBr(double valor) {
    final bool negativo = valor < 0;
    final double absValor = valor.abs();
    final String fixo = absValor.toStringAsFixed(2);
    final List<String> partes = fixo.split('.');
    final String inteiro = partes[0];
    final String centavos = partes.length > 1 ? partes[1] : '00';

    final StringBuffer comMilhares = StringBuffer();
    for (int i = 0; i < inteiro.length; i++) {
      if (i > 0 && (inteiro.length - i) % 3 == 0) {
        comMilhares.write('.');
      }
      comMilhares.write(inteiro[i]);
    }

    return "${negativo ? '-' : ''}R\$ ${comMilhares.toString()},$centavos";
  }

  void _handleAbrirDetalhes() {
    if (onAbrirDetalhes != null) {
      onAbrirDetalhes!();
    } else {
      onNavegar("Métricas Completas");
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _handleAbrirDetalhes,
      child: CardPainelBase(
        titulo: "1. Métricas e indicadores",
        icone: Icons.insights_rounded,
        isMobile: isMobile,
        conteudo: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FAF7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFC2E4DC)),
                  ),
                  child: const Text(
                    "Últimos 30 dias",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0C6B6B),
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: _handleAbrirDetalhes,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Ver detalhes",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0C6B6B),
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 14,
                          color: Color(0xFF0C6B6B),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildMiniIndicador(
                  valor: "${horasDoadas}h",
                  rotulo: "Horas de eventos",
                  icon: Icons.schedule_rounded,
                  cor: const Color(0xFF0C6B6B),
                ),
                const SizedBox(width: 8),
                _buildMiniIndicador(
                  valor: "$percentualVagasPreenchidas%",
                  rotulo: "Vagas preenchidas",
                  icon: Icons.pie_chart_rounded,
                  cor: const Color(0xFF1A528F),
                ),
                const SizedBox(width: 8),
                _buildMiniIndicador(
                  valor: "$percentualRetencaoVoluntarios%",
                  rotulo: "Assiduidade",
                  icon: Icons.repeat_rounded,
                  cor: const Color(0xFFD46B08),
                ),
              ],
            ),
            const SizedBox(height: 10),
            isMobile
                ? Column(
                    children: [
                      _buildCaixaFinanceira(
                        titulo: "Arrecadado com doações",
                        valorFormatado:
                            _formatarMoedaBr(valorArrecadadoDinheiro),
                        icon: Icons.payments_outlined,
                        cor: const Color(0xFF0C6B6B),
                      ),
                      const SizedBox(height: 8),
                      _buildCaixaFinanceira(
                        titulo: "Gastos operacionais",
                        valorFormatado: _formatarMoedaBr(gastos),
                        icon: Icons.receipt_long_outlined,
                        cor: const Color(0xFFD46B08),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _buildCaixaFinanceira(
                          titulo: "Valor arrecadado em dinheiro",
                          valorFormatado:
                              _formatarMoedaBr(valorArrecadadoDinheiro),
                          icon: Icons.payments_outlined,
                          cor: const Color(0xFF0C6B6B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildCaixaFinanceira(
                          titulo: "Gastos",
                          valorFormatado: _formatarMoedaBr(gastos),
                          icon: Icons.receipt_long_outlined,
                          cor: const Color(0xFFD46B08),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaixaFinanceira({
    required String titulo,
    required String valorFormatado,
    required IconData icon,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FAF7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC2E4DC)),
      ),
      child: Row(
        children: [
          Icon(icon, color: cor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF4C7A70),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  valorFormatado,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF062222),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniIndicador({
    required String valor,
    required String rotulo,
    required IconData icon,
    required Color cor,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(isMobile ? 8 : 12),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: cor),
            const SizedBox(height: 4),
            Text(
              valor,
              style: TextStyle(
                fontSize: isMobile ? 15 : 18,
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
            Text(
              rotulo,
              style: TextStyle(
                fontSize: isMobile ? 9 : 10,
                color: Colors.grey.shade700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
