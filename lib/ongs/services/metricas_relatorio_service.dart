// lib/ongs/painel_geral/services/metricas_relatorio_service.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/ong_painel_service.dart';
import '../painel_geral/widgets/grafico_evolucao_horas.dart';
import '../painel_geral/widgets/secao_dashboard_impacto.dart';

class MetricasRelatorioService {
  const MetricasRelatorioService();

  String gerarCsv({
    required String nomeOng,
    required String periodoRotulo,
    required OngPainelDados? dados,
    required List<PontoGraficoHoras> serieHoras,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Indicador;Valor');
    buffer.writeln('Instituicao;$nomeOng');
    buffer.writeln('Periodo;$periodoRotulo');
    buffer.writeln('Horas doadas;${dados?.horasDoadas ?? 0}h');
    buffer.writeln(
      'Vagas preenchidas;${dados?.percentualVagasPreenchidas ?? 0}%',
    );
    buffer.writeln(
      'Retencao voluntarios;${dados?.percentualRetencaoVoluntarios ?? 0}%',
    );
    buffer.writeln(
      'Valor arrecadado em dinheiro;${(dados?.valorArrecadadoDinheiro ?? 0).toStringAsFixed(2)}',
    );
    buffer.writeln('Gastos;${(dados?.gastos ?? 0).toStringAsFixed(2)}');
    buffer.writeln();
    buffer.writeln('Segmento;Horas');
    for (final p in serieHoras) {
      final rotuloCompleto =
          p.subrotulo != null ? '${p.rotulo} (${p.subrotulo})' : p.rotulo;
      buffer.writeln('$rotuloCompleto;${p.valor.round()}');
    }
    return buffer.toString();
  }

  String gerarResumoTexto({
    required String nomeOng,
    required String periodoRotulo,
    required OngPainelDados? dados,
    required List<PontoGraficoHoras> serieHoras,
  }) {
    final double arrecadado = dados?.valorArrecadadoDinheiro ?? 0;
    final double gastos = dados?.gastos ?? 0;
    final double saldo = arrecadado - gastos;

    final linhas = <String>[
      'RELATÓRIO DE MÉTRICAS — $nomeOng',
      'Período: $periodoRotulo',
      '----------------------------------------',
      'Horas doadas: ${dados?.horasDoadas ?? 0}h',
      'Vagas preenchidas: ${dados?.percentualVagasPreenchidas ?? 0}%',
      'Retenção de voluntários: ${dados?.percentualRetencaoVoluntarios ?? 0}%',
      'Valor arrecadado em dinheiro: R\$ ${arrecadado.toStringAsFixed(2).replaceAll('.', ',')}',
      'Gastos: R\$ ${gastos.toStringAsFixed(2).replaceAll('.', ',')}',
      'Saldo líquido: R\$ ${saldo.toStringAsFixed(2).replaceAll('.', ',')}',
      '',
      'Distribuição de horas:',
      ...serieHoras.map((p) {
        final label =
            p.subrotulo != null ? '${p.rotulo} (${p.subrotulo})' : p.rotulo;
        return '• $label: ${p.detalhe}';
      }),
    ];
    return linhas.join('\n');
  }

  Future<void> exportarCsv(
    BuildContext context, {
    required String nomeOng,
    required PeriodoIndicadores periodo,
    required OngPainelDados? dados,
    required List<PontoGraficoHoras> serieHoras,
  }) async {
    final rotulo = _rotuloPeriodo(periodo);
    final csv = gerarCsv(
      nomeOng: nomeOng,
      periodoRotulo: rotulo,
      dados: dados,
      serieHoras: serieHoras,
    );

    await Clipboard.setData(ClipboardData(text: csv));
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "CSV ($rotulo) copiado para a área de transferência pronto para exportar.",
        ),
        backgroundColor: const Color(0xFF0C6B6B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> abrirVisualizacaoImpressao(
    BuildContext context, {
    required String nomeOng,
    required PeriodoIndicadores periodo,
    required OngPainelDados? dados,
    required List<PontoGraficoHoras> serieHoras,
  }) async {
    final rotulo = _rotuloPeriodo(periodo);
    final resumo = gerarResumoTexto(
      nomeOng: nomeOng,
      periodoRotulo: rotulo,
      dados: dados,
      serieHoras: serieHoras,
    );

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Row(
            children: [
              const Icon(Icons.print_rounded, color: Color(0xFF0C6B6B)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Imprimir / Resumo ($rotulo)",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF062222),
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Container(
              width: 440,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FAF7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFC2E4DC)),
              ),
              child: SelectableText(
                resumo,
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.45,
                  color: Color(0xFF062222),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: resumo));
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text("Resumo copiado."),
                      backgroundColor: Color(0xFF0C6B6B),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text(
                "Copiar texto",
                style: TextStyle(color: Color(0xFF0C6B6B)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C6B6B),
              ),
              child: const Text(
                "Fechar",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  String _rotuloPeriodo(PeriodoIndicadores periodo) {
    switch (periodo) {
      case PeriodoIndicadores.semanal:
        return "Semanal";
      case PeriodoIndicadores.mensal:
        return "Mensal";
      case PeriodoIndicadores.anual:
        return "Anual";
    }
  }
}
