// lib/voluntarios/perfil/widgets/modal_nova_experiencia.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/voluntario_profile_models.dart';

class ModalNovaExperiencia {
  static void abrir({
    required BuildContext context,
    List<String>? eventosConcluidos,
    List<AcaoParticipadaVoluntarioModel>? acoesParticipadas,
    List<({String id, String titulo, String dataFormatada})>? eventosOpcoes,
    bool carregandoEventos = false,
    String? textoInicial,
    List<XFile>? imagensIniciais,
    required ImagePicker picker,
    required Function({
      required String texto,
      required String origem,
      required List<XFile> imagens,
      required BuildContext modalParentContext,
    }) onSolicitarConfirmacao,
  }) {
    final TextEditingController textoCtrl = TextEditingController(
      text: textoInicial ?? '',
    );
    final List<XFile> midiasSelecionadas = [
      if (imagensIniciais != null) ...imagensIniciais,
    ];

    final List<AcaoParticipadaVoluntarioModel> listaAcoes = [];
    if (acoesParticipadas != null && acoesParticipadas.isNotEmpty) {
      listaAcoes.addAll(acoesParticipadas);
    } else if (eventosOpcoes != null && eventosOpcoes.isNotEmpty) {
      for (final ev in eventosOpcoes) {
        listaAcoes.add(
          AcaoParticipadaVoluntarioModel(
            id: ev.id,
            opportunityId: ev.id,
            titulo: ev.titulo,
            ongNome: '',
            dataFormatada: ev.dataFormatada,
            duracaoHoras: 0,
            status: 'ACTIVE',
          ),
        );
      }
    } else if (eventosConcluidos != null) {
      for (final titulo in eventosConcluidos) {
        listaAcoes.add(
          AcaoParticipadaVoluntarioModel(
            id: titulo,
            opportunityId: '',
            titulo: titulo,
            ongNome: 'Ação Solidária',
            dataFormatada: '',
            duracaoHoras: 4,
            status: 'COMPLETED',
          ),
        );
      }
    }

    AcaoParticipadaVoluntarioModel? acaoSelecionada;

    int contarPalavras(String str) {
      final limpo = str.trim();
      if (limpo.isEmpty) return 0;
      return limpo.split(RegExp(r'\s+') as Pattern).length;
    }

    int palavrasContadas = contarPalavras(textoCtrl.text);

    DateTime? converterData(String dataStr) {
      final limpo = dataStr.trim();
      if (limpo.isEmpty || limpo == 'Recente') return null;
      if (limpo.contains('/')) {
        final partes = limpo.split('/');
        if (partes.length == 3) {
          final dia = int.tryParse(partes[0]);
          final mes = int.tryParse(partes[1]);
          final ano = int.tryParse(partes[2]);
          if (dia != null && mes != null && ano != null) {
            return DateTime(ano, mes, dia);
          }
        }
      }
      return DateTime.tryParse(limpo);
    }

    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isLimiteExcedido = palavrasContadas > 1000;

          Future<void> selecionarFoto() async {
            if (midiasSelecionadas.length >= 4) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Limite de 4 fotos atingido.')),
              );
              return;
            }

            final XFile? foto = await picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 70,
              maxWidth: 1080,
            );

            if (foto != null) {
              setModalState(() {
                midiasSelecionadas.add(foto);
              });
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Compartilhar experiência",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF062222),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(modalContext),
                        icon:
                            const Icon(Icons.close_rounded, color: Colors.grey),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: textoCtrl,
                    maxLines: 5,
                    onChanged: (val) {
                      setModalState(
                          () => palavrasContadas = contarPalavras(val));
                    },
                    decoration: InputDecoration(
                      hintText:
                          "Escreva sua postagem livre, relatos ou histórias marcantes...",
                      hintStyle:
                          const TextStyle(fontSize: 12, color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFFF0FAF7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFC2E4DC), width: 1.2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFC2E4DC), width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF0C6B6B), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Spacer(),
                      Text(
                        "$palavrasContadas / 1000 palavras",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isLimiteExcedido
                              ? Colors.redAccent
                              : const Color(0xFF7AAAA0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: selecionarFoto,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FAF7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFC2E4DC)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_photo_alternate_outlined,
                                  size: 22, color: Color(0xFF0C6B6B)),
                              const SizedBox(height: 2),
                              Text(
                                "${midiasSelecionadas.length}/4",
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0C6B6B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      Expanded(
                        child: Container(
                          height: 60,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FAF7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFC2E4DC)),
                          ),
                          child: carregandoEventos
                              ? const Center(
                                  child: SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF0C6B6B),
                                    ),
                                  ),
                                )
                              : DropdownButtonHideUnderline(
                                  child: DropdownButton<
                                      AcaoParticipadaVoluntarioModel?>(
                                    value: acaoSelecionada,
                                    isExpanded: true,
                                    hint: const Text(
                                      "Deseja citar algum evento?",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF5A8A80),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    items: [
                                      const DropdownMenuItem<
                                          AcaoParticipadaVoluntarioModel?>(
                                        value: null,
                                        child: Text(
                                          "Escolha um evento",
                                          style: TextStyle(
                                              fontSize: 11, color: Colors.grey),
                                        ),
                                      ),
                                      ...listaAcoes.map((acao) {
                                        final dt =
                                            converterData(acao.dataFormatada);
                                        final bool isFuturo = dt != null &&
                                            (dt.isAfter(hoje) ||
                                                dt.isAtSameMomentAs(hoje));
                                        final String statusLabel =
                                            isFuturo ? "Próximo" : "Passado";

                                        return DropdownMenuItem<
                                            AcaoParticipadaVoluntarioModel?>(
                                          value: acao,
                                          child: Text(
                                            acao.dataFormatada.isNotEmpty
                                                ? "[$statusLabel]${acao.titulo}"
                                                : acao.titulo,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: Color(0xFF062222),
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }),
                                    ],
                                    onChanged: (val) {
                                      setModalState(
                                          () => acaoSelecionada = val);
                                    },
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (midiasSelecionadas.isNotEmpty) ...[
                    SizedBox(
                      height: 60,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: midiasSelecionadas.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final item = midiasSelecionadas[index];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: FutureBuilder<Uint8List>(
                                  future: item.readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey[200],
                                      );
                                    }
                                    return Image.memory(
                                      snapshot.data!,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () => setModalState(() {
                                    midiasSelecionadas.removeAt(index);
                                  }),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 8),

                  ElevatedButton(
                    onPressed:
                        (textoCtrl.text.trim().isEmpty || isLimiteExcedido)
                            ? null
                            : () {
                                onSolicitarConfirmacao(
                                  texto: textoCtrl.text.trim(),
                                  origem: acaoSelecionada != null
                                      ? acaoSelecionada!.titulo
                                      : "Postagem Livre",
                                  imagens: midiasSelecionadas,
                                  modalParentContext: modalContext,
                                );
                              },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C6B6B),
                      disabledBackgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Publicar",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}