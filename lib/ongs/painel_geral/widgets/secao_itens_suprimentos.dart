// lib/ongs/painel_geral/widgets/secao_itens_suprimentos.dart

import 'package:flutter/material.dart';
import '../../services/ong_painel_service.dart';
import 'card_painel_base.dart';

class SecaoItensSuprimentos extends StatelessWidget {
  final bool isMobile;
  final ValueChanged<String> onNavegar;
  final List<OngSuprimentoItem> suprimentos;
  final VoidCallback? onGerenciar;
  final ValueChanged<OngSuprimentoItem>? onSelecionarItem;

  const SecaoItensSuprimentos({
    super.key,
    required this.isMobile,
    required this.onNavegar,
    this.suprimentos = const <OngSuprimentoItem>[],
    this.onGerenciar,
    this.onSelecionarItem,
  });

  String _formatarQuantidade(double valor) {
    if (valor == valor.roundToDouble()) {
      return valor.toInt().toString();
    }
    return valor.toStringAsFixed(1);
  }

  ({String texto, Color bg, Color corTexto, String statusLabel})
      _resolverVisualItem(
    OngSuprimentoItem item,
  ) {
    if (item.metaAtingida) {
      return (
        texto: "${item.nome} (Meta Atingida)",
        bg: const Color(0xFFF6FFED),
        corTexto: const Color(0xFF389E0D),
        statusLabel: "Meta Atingida",
      );
    }

    final double faltam = item.saldoFaltante;
    final String faltamFmt = _formatarQuantidade(faltam);
    final String unidadeSufixo =
        item.unidade.trim().isNotEmpty ? " ${item.unidade.trim()}" : "";

    final bool urgente = item.prioridade.toUpperCase() == 'URGENTE' ||
        (item.quantidadeMeta > 0 &&
            (item.quantidadeRecebida / item.quantidadeMeta) < 0.35);

    if (faltam <= 0 && item.quantidadePrometida > 0) {
      return (
        texto:
            "${item.nome} (${_formatarQuantidade(item.quantidadePrometida)}$unidadeSufixo prometidos)",
        bg: const Color(0xFFE6F7FF),
        corTexto: const Color(0xFF096DD9),
        statusLabel: "Prometido",
      );
    }

    if (urgente) {
      return (
        texto: "${item.nome} (Faltam $faltamFmt$unidadeSufixo)",
        bg: const Color(0xFFFFF1F0),
        corTexto: const Color(0xFFCF1322),
        statusLabel: "Urgente",
      );
    }

    return (
      texto: "${item.nome} (Faltam $faltamFmt$unidadeSufixo)",
      bg: const Color(0xFFFFF7E6),
      corTexto: const Color(0xFFD46B08),
      statusLabel: "Em andamento",
    );
  }

  void _abrirDetalheSuprimento(
    BuildContext context,
    OngSuprimentoItem item,
  ) {
    if (onSelecionarItem != null) {
      onSelecionarItem!(item);
      return;
    }

    const corVerde = Color(0xFF0C6B6B);
    const corFundoSuave = Color(0xFFF0FAF7);
    const corBordaSuave = Color(0xFFC2E4DC);

    final visual = _resolverVisualItem(item);
    final double pct = item.quantidadeMeta <= 0
        ? 0.0
        : (item.quantidadeRecebida / item.quantidadeMeta).clamp(0.0, 1.0);
    final String sufixo =
        item.unidade.trim().isNotEmpty ? " ${item.unidade.trim()}" : "";

    final String recebidaFmt = _formatarQuantidade(item.quantidadeRecebida);
    final String prometidaFmt = _formatarQuantidade(item.quantidadePrometida);
    final String metaFmt = _formatarQuantidade(item.quantidadeMeta);
    final String faltamFmt = _formatarQuantidade(item.saldoFaltante);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: corBordaSuave,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.volunteer_activism_rounded,
                      color: corVerde,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.nome.isNotEmpty ? item.nome : "Item de suprimento",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF062222),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: visual.bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: visual.corTexto.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        visual.statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: visual.corTexto,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: corFundoSuave,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: corBordaSuave),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Arrecadação / Estoque",
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF4C7A70),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            "${(pct * 100).round()}%",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: corVerde,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 8,
                          backgroundColor: Colors.white,
                          color: corVerde,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Recebido: $recebidaFmt$sufixo • Prometido: $prometidaFmt$sufixo",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF062222),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Meta: $metaFmt$sufixo • Saldo faltante: $faltamFmt$sufixo",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF4C7A70),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: corBordaSuave),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Fechar",
                          style: TextStyle(
                            color: Color(0xFF4C7A70),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          if (onGerenciar != null) {
                            onGerenciar!();
                          } else {
                            onNavegar("Gerenciar Doações");
                          }
                        },
                        icon: const Icon(
                          Icons.inventory_2_outlined,
                          size: 15,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Abrir Mini ERP",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: corVerde,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onGerenciar ?? () => onNavegar("Gerenciar Doações"),
      child: CardPainelBase(
        titulo: "5. Itens e Suprimentos",
        icone: Icons.volunteer_activism_rounded,
        isMobile: isMobile,
        botaoAcao: TextButton(
          onPressed: onGerenciar ?? () => onNavegar("Gerenciar Doações"),
          child: const Text(
            "Gerenciar",
            style: TextStyle(
              color: Color(0xFF0C6B6B),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        conteudo: suprimentos.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FAF7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFC2E4DC)),
                ),
                child: const Text(
                  "Nenhum item ou suprimento cadastrado até o momento.",
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF4C7A70),
                  ),
                ),
              )
            : Wrap(
                spacing: 6,
                runSpacing: 6,
                children: suprimentos.map((item) {
                  final visual = _resolverVisualItem(item);
                  return InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => _abrirDetalheSuprimento(context, item),
                    child: _ChipItem(
                      texto: visual.texto,
                      bg: visual.bg,
                      corTexto: visual.corTexto,
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }
}

class _ChipItem extends StatelessWidget {
  final String texto;
  final Color bg;
  final Color corTexto;

  const _ChipItem({
    required this.texto,
    required this.bg,
    required this.corTexto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: corTexto.withValues(alpha: 0.4)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: corTexto,
        ),
      ),
    );
  }
}
