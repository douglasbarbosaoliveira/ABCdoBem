// lib/ongs/painel_geral/widgets/secao_metas_campanhas.dart

import 'package:flutter/material.dart';
import '../../services/ong_painel_service.dart';
import 'card_painel_base.dart';

class SecaoMetasCampanhas extends StatelessWidget {
  final bool isMobile;
  final ValueChanged<String> onNavegar;
  final List<OngMetaItem> metas;
  final VoidCallback? onAdicionarMeta;
  final VoidCallback? onAbrirPainelMetas;
  final bool usarMockupQuandoVazio;

  const SecaoMetasCampanhas({
    super.key,
    required this.isMobile,
    required this.onNavegar,
    this.metas = const <OngMetaItem>[],
    this.onAdicionarMeta,
    this.onAbrirPainelMetas,
    this.usarMockupQuandoVazio = true,
  });

  List<OngMetaItem> get _metasMockup => <OngMetaItem>[
        OngMetaItem(
          id: "mock-meta-1",
          titulo: "Horas de voluntariado no mês",
          valorAtual: 84,
          valorMeta: 120,
          unidade: "h",
        ),
        OngMetaItem(
          id: "mock-meta-2",
          titulo: "Famílias atendidas nas ações",
          valorAtual: 45,
          valorMeta: 60,
          unidade: "famílias",
        ),
        OngMetaItem(
          id: "mock-meta-3",
          titulo: "Voluntários recorrentes (2+ ações)",
          valorAtual: 14,
          valorMeta: 20,
          unidade: "voluntários",
        ),
      ];

  String _formatarValor(double valor) {
    if (valor == valor.roundToDouble()) {
      return valor.toInt().toString();
    }
    return valor.toStringAsFixed(1);
  }

  double _calcularPercentual(OngMetaItem meta) {
    if (meta.valorMeta <= 0) return 0.0;
    return (meta.valorAtual / meta.valorMeta).clamp(0.0, 1.0);
  }

  void _abrirDetalheMeta(
      BuildContext context, OngMetaItem meta, bool isMockup) {
    const corVerde = Color(0xFF0C6B6B);
    const corFundoSuave = Color(0xFFF0FAF7);
    const corBordaSuave = Color(0xFFC2E4DC);

    final pct = _calcularPercentual(meta);
    final pctTexto = "${(pct * 100).round()}%";
    final atualFmt = _formatarValor(meta.valorAtual);
    final alvoFmt = _formatarValor(meta.valorMeta);
    final restanteFmt = _formatarValor(
        (meta.valorMeta - meta.valorAtual).clamp(0, meta.valorMeta));
    final sufixo =
        meta.unidade.trim().isNotEmpty ? " ${meta.unidade.trim()}" : "";

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
                    const Icon(Icons.flag_rounded, color: corVerde, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        meta.titulo.isNotEmpty
                            ? meta.titulo
                            : "Meta institucional",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF062222),
                        ),
                      ),
                    ),
                    if (isMockup)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: corFundoSuave,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: corBordaSuave),
                        ),
                        child: const Text(
                          "Exemplo",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: corVerde,
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
                            "Andamento atual",
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF4C7A70),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            pctTexto,
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
                        "Realizado: $atualFmt$sufixo de $alvoFmt$sufixo • Falta: $restanteFmt$sufixo",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF062222),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: corVerde,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    "Fechar",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _abrirPainelCompletoMetas(
    BuildContext context,
    List<OngMetaItem> listaMetas,
    bool isMockup,
  ) {
    if (onAbrirPainelMetas != null) {
      onAbrirPainelMetas!();
      return;
    }

    const corVerde = Color(0xFF0C6B6B);
    const corFundoSuave = Color(0xFFF0FAF7);
    const corBordaSuave = Color(0xFFC2E4DC);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
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
                    const Icon(Icons.track_changes_rounded,
                        color: corVerde, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Painel de Metas da Instituição",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF062222),
                        ),
                      ),
                    ),
                    if (isMockup)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: corFundoSuave,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: corBordaSuave),
                        ),
                        child: const Text(
                          "Mockup",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: corVerde,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  "Toque em qualquer meta para ver o detalhamento do progresso.",
                  style: TextStyle(fontSize: 11, color: Color(0xFF4C7A70)),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: listaMetas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final meta = listaMetas[index];
                      final pct = _calcularPercentual(meta);
                      final atualFmt = _formatarValor(meta.valorAtual);
                      final alvoFmt = _formatarValor(meta.valorMeta);
                      final sufixo = meta.unidade.trim().isNotEmpty
                          ? " ${meta.unidade.trim()}"
                          : "";

                      return InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _abrirDetalheMeta(context, meta, isMockup);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: corFundoSuave,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: corBordaSuave),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      meta.titulo.isNotEmpty
                                          ? meta.titulo
                                          : "Meta institucional",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF062222),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "${(pct * 100).round()}%",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: corVerde,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "$atualFmt de $alvoFmt$sufixo",
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF4C7A70),
                                ),
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 6,
                                  backgroundColor: Colors.white,
                                  color: corVerde,
                                ),
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool usandoMockup = metas.isEmpty && usarMockupQuandoVazio;
    final List<OngMetaItem> metasExibidas = usandoMockup ? _metasMockup : metas;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () =>
          _abrirPainelCompletoMetas(context, metasExibidas, usandoMockup),
      child: CardPainelBase(
        titulo: "4. Metas",
        icone: Icons.flag_rounded,
        isMobile: isMobile,
        botaoAcao: TextButton(
          onPressed: onAdicionarMeta ?? () => onNavegar("Configurar Metas"),
          child: const Text(
            "+ Meta",
            style: TextStyle(
              color: Color(0xFF0C6B6B),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        conteudo: metasExibidas.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FAF7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFC2E4DC)),
                ),
                child: const Text(
                  "Nenhuma meta institucional cadastrada até o momento.",
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF4C7A70),
                  ),
                ),
              )
            : Column(
                children: metasExibidas.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final OngMetaItem meta = entry.value;

                  final String atualFmt = _formatarValor(meta.valorAtual);
                  final String alvoFmt = _formatarValor(meta.valorMeta);
                  final String unidadeSufixo = meta.unidade.trim().isNotEmpty
                      ? " ${meta.unidade.trim()}"
                      : "";

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < metasExibidas.length - 1 ? 10 : 0,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () =>
                          _abrirDetalheMeta(context, meta, usandoMockup),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: _ItemMeta(
                          titulo: meta.titulo.isNotEmpty
                              ? meta.titulo
                              : "Meta institucional",
                          progressoTexto: "$atualFmt de $alvoFmt$unidadeSufixo",
                          porcentagem: _calcularPercentual(meta),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }
}

class _ItemMeta extends StatelessWidget {
  final String titulo;
  final String progressoTexto;
  final double porcentagem;

  const _ItemMeta({
    required this.titulo,
    required this.progressoTexto,
    required this.porcentagem,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF062222),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              progressoTexto,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: porcentagem,
            backgroundColor: const Color(0xFFE3F5F1),
            color: const Color(0xFF0C6B6B),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
