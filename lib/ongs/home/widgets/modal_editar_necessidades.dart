// lib/ongs/home/widgets/modal_editar_necessidades.dart

import 'package:flutter/material.dart';
import '../../../nlp/pln_pipeline_service.dart';

class ModalEditarNecessidades {
  static void exibir(
    BuildContext context, {
    required List<String> necessidadesIniciais,
    required Future<void> Function(List<String>) onSalvar,
    String? causaOng,
    String? nomeOng,
  }) {
    final List<String> tempLista = List.from(necessidadesIniciais);
    final TextEditingController novoItemCtrl = TextEditingController();

    final String contextoPerfilOng = [
      if (causaOng != null && causaOng.trim().isNotEmpty) causaOng.trim(),
      if (nomeOng != null && nomeOng.trim().isNotEmpty) nomeOng.trim(),
    ].join(' ');

    final String causaExibicao = (causaOng ?? '')
        .replaceAll(
          RegExp(
            r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F1E0}-\u{1F1FF}]',
            unicode: true,
          ),
          '',
        )
        .trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalCtx) {
        final double alturaTela = MediaQuery.of(modalCtx).size.height;
        // Quadro fixo e compacto: elimina o espaço branco excessivo e não pula ao digitar
        final double alturaFixaModal = (alturaTela * 0.56).clamp(395.0, 455.0);

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final sugestoesPln = PlnPipelineService.recomendarNecessidades(
              tipoOuCausaOng: contextoPerfilOng,
              textoDigitado: novoItemCtrl.text,
              jaSelecionados: tempLista,
              minimoRecomendacoes: 5,
              limite: 8,
            );

            void adicionarItem(String item) {
              final limpo = item.trim();
              if (limpo.isNotEmpty && !tempLista.contains(limpo)) {
                setModalState(() {
                  tempLista.add(limpo);
                  novoItemCtrl.clear();
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
              ),
              child: SizedBox(
                height: alturaFixaModal,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cabeçalho fixo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Necessidades e Doações Urgentes",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF062222),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(modalCtx),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.grey,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Adicione os materiais, alimentos ou perfis de voluntários que a instituição mais precisa:",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),

                      // Campo de entrada fixo
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: novoItemCtrl,
                              onChanged: (_) => setModalState(() {}),
                              onSubmitted: adicionarItem,
                              decoration: InputDecoration(
                                hintText:
                                    "Ex: Arroz, feijão, pedagogo voluntário...",
                                hintStyle: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF0FAF7),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFC2E4DC),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFC2E4DC),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
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
                            onPressed: () => adicionarItem(novoItemCtrl.text),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0C6B6B),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
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

                      // Bloco de Recomendações PLN com altura fixa comportando >= 5 chips
                      Container(
                        height: 124,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FCFA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD9EFE9)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                    causaExibicao.isNotEmpty
                                        ? "Recomendações PLN • $causaExibicao"
                                        : "Recomendações PLN para sua instituição",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0C6B6B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: sugestoesPln.map((sugestao) {
                                    return InkWell(
                                      onTap: () => adicionarItem(sugestao),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: const Color(0xFF0C6B6B),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.add_rounded,
                                              size: 13,
                                              color: Color(0xFF0C6B6B),
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                sugestao,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF062222),
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

                      const SizedBox(height: 10),

                      // Cabeçalho da lista selecionada
                      Text(
                        "Itens selecionados (${tempLista.length}):",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF062222),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Área compacta com rolagem interna para os itens adicionados
                      Expanded(
                        child: tempLista.isEmpty
                            ? const Center(
                                child: Text(
                                  "Nenhuma necessidade cadastrada no momento.",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: tempLista.length,
                                itemBuilder: (_, index) {
                                  final item = tempLista[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF7E6),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFFFD591),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.favorite_rounded,
                                          size: 14,
                                          color: Color(0xFFD46B08),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            item,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFD46B08),
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () => setModalState(
                                            () => tempLista.removeAt(index),
                                          ),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),

                      const SizedBox(height: 10),

                      // Botão Salvar sempre fixo na base
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(modalCtx);
                          await onSalvar(tempLista);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0C6B6B),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Salvar Alterações",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
