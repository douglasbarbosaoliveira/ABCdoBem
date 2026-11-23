// lib/ongs/painel_geral/widgets/secao_voluntarios_destaque.dart

import 'package:flutter/material.dart';
import '../../services/ong_painel_service.dart';
import 'card_painel_base.dart';

class SecaoVoluntariosDestaque extends StatelessWidget {
  final bool isMobile;
  final ValueChanged<String> onNavegar;
  final VoidCallback? onAbrirTodos;
  final List<VoluntarioGuardiaoResumo> voluntarios;

  const SecaoVoluntariosDestaque({
    super.key,
    required this.isMobile,
    required this.onNavegar,
    this.onAbrirTodos,
    this.voluntarios = const <VoluntarioGuardiaoResumo>[],
  });

  List<VoluntarioGuardiaoResumo> _topCincoRanking() {
    if (voluntarios.isEmpty) return const <VoluntarioGuardiaoResumo>[];
    final ordenados = List<VoluntarioGuardiaoResumo>.from(voluntarios)
      ..sort((a, b) {
        final cmpAcoes = b.acoesConcluidas.compareTo(a.acoesConcluidas);
        if (cmpAcoes != 0) return cmpAcoes;
        return b.horasAcumuladas.compareTo(a.horasAcumuladas);
      });
    return ordenados.take(5).toList();
  }

  void _handleVerTodos() {
    if (onAbrirTodos != null) {
      onAbrirTodos!();
    } else {
      onNavegar("Voluntários");
    }
  }

  String _iniciais(String nome) {
    final partes =
        nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return 'V';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }

  Color _corPosicao(int indice) {
    switch (indice) {
      case 0:
        return const Color(0xFFD46B08); // 1º lugar destaque
      case 1:
        return const Color(0xFF1A528F); // 2º lugar azul principal
      case 2:
        return const Color(0xFF2B6CB0); // 3º lugar azul médio
      default:
        return const Color(0xFF5A7D9A); // 4º e 5º azul acinzentado
    }
  }

  @override
  Widget build(BuildContext context) {
    final topCinco = _topCincoRanking();

    const corDestaque = Color(0xFF1A528F);
    const corFundoItem = Color(0xFFEFF6FC);
    const corBordaItem = Color(0xFFC8DFF2);

    return CardPainelBase(
      titulo: "3. Gestão de voluntários",
      icone: Icons.workspace_premium_rounded,
      isMobile: isMobile,
      botaoAcao: TextButton(
        onPressed: _handleVerTodos,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text(
          "Ver Todos",
          style: TextStyle(
            color: corDestaque,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      conteudo: topCinco.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: corFundoItem,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: corBordaItem),
              ),
              child: const Text(
                "Nenhum voluntário registrado nas ações desta ONG ainda.",
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF4E6E88),
                ),
              ),
            )
          : Column(
              children: List.generate(topCinco.length, (indice) {
                final vol = topCinco[indice];
                final corRank = _corPosicao(indice);
                final temAvatar =
                    vol.avatarUrl != null && vol.avatarUrl!.trim().isNotEmpty;

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: indice < topCinco.length - 1 ? 8 : 0,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _handleVerTodos,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: corFundoItem,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: corBordaItem),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            child: Text(
                              "${indice + 1}º",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: corRank,
                              ),
                            ),
                          ),
                          CircleAvatar(
                            radius: 15,
                            backgroundColor:
                                corDestaque.withValues(alpha: 0.14),
                            backgroundImage:
                                temAvatar ? NetworkImage(vol.avatarUrl!) : null,
                            child: !temAvatar
                                ? Text(
                                    _iniciais(vol.nome),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: corDestaque,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vol.nome.isNotEmpty ? vol.nome : "Voluntário",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0B253A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "${vol.acoesConcluidas} ${vol.acoesConcluidas == 1 ? 'ação' : 'ações'} • ${vol.horasAcumuladas}h",
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF4E6E88),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: corBordaItem),
                            ),
                            child: Text(
                              "${vol.acoesConcluidas}x",
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: corDestaque,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
    );
  }
}
