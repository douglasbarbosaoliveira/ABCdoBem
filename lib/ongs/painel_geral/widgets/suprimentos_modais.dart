// lib/ongs/painel_geral/widgets/suprimentos_modais.dart

import 'package:flutter/material.dart';

import '../../services/ong_painel_service.dart';
import '../../models/suprimentos_erp_models.dart';

class SuprimentosModais {
  static const Color _corVerde = Color(0xFF0C6B6B);
  static const Color _corFundoSuave = Color(0xFFF0FAF7);
  static const Color _corBordaSuave = Color(0xFFC2E4DC);
  static const Color _corTextoEscuro = Color(0xFF062222);
  static const Color _corTextoSecundario = Color(0xFF4C7A70);

  static const List<String> unidadesDisponiveis = <String>[
    'un',
    'kg',
    'g',
    'L',
    'cx',
    'fardo',
    'cesta',
    'pct',
    'par',
  ];

  static const List<String> prioridadesDisponiveis = <String>[
    'BAIXA',
    'MEDIA',
    'ALTA',
    'URGENTE',
  ];

  static DateTime get hojeSemHora {
    final agora = DateTime.now();
    return DateTime(agora.year, agora.month, agora.day);
  }

  static String formatarQtd(double valor) {
    if (valor == valor.roundToDouble()) {
      return valor.toInt().toString();
    }
    return valor.toStringAsFixed(1);
  }

  static String formatarDataBr(DateTime dt) {
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    return "$dia/$mes/${dt.year}";
  }

  static String formatarDataHoraLog(DateTime dt) {
    final data = formatarDataBr(dt);
    final hora = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return "$data às $hora:$min";
  }

  static DateTime? parseDataPrazo(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final iso = DateTime.tryParse(raw.trim());
    if (iso != null) return iso.toLocal();
    final partes = raw.trim().split('/');
    if (partes.length == 3) {
      final d = int.tryParse(partes[0]);
      final m = int.tryParse(partes[1]);
      final y = int.tryParse(partes[2]);
      if (d != null && m != null && y != null) {
        return DateTime(y, m, d);
      }
    }
    return null;
  }

  static String _normalizarPrioridade(String? raw) {
    switch (raw?.trim().toUpperCase()) {
      case 'BAIXA':
        return 'BAIXA';
      case 'MEDIA':
      case 'MÉDIA':
      case 'NORMAL':
        return 'MEDIA';
      case 'ALTA':
        return 'ALTA';
      case 'URGENTE':
        return 'URGENTE';
      default:
        return 'MEDIA';
    }
  }

  static Future<VoluntarioPlataforma?> abrirSeletorVoluntario(
    BuildContext context, {
    required List<VoluntarioPlataforma> voluntarios,
    required bool carregando,
    required Future<void> Function() onRecarregar,
  }) async {
    if (voluntarios.isEmpty && !carregando) {
      await onRecarregar();
    }
    if (!context.mounted) return null;

    String filtroVol = '';
    return showModalBottomSheet<VoluntarioPlataforma>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setVolState) {
            final filtrados = voluntarios.where((v) {
              if (filtroVol.trim().isEmpty) return true;
              final q = filtroVol.trim().toLowerCase();
              return v.nome.toLowerCase().contains(q) ||
                  (v.infoSecundaria?.toLowerCase().contains(q) ?? false);
            }).toList();

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _corBordaSuave,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Importar Voluntário da Plataforma",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _corTextoEscuro,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      onChanged: (v) => setVolState(() => filtroVol = v),
                      decoration: const InputDecoration(
                        hintText: "Buscar voluntário por nome ou cidade...",
                        prefixIcon:
                            Icon(Icons.person_search_rounded, color: _corVerde),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (carregando)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(color: _corVerde),
                        ),
                      )
                    else if (filtrados.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          "Nenhum voluntário encontrado na plataforma.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, color: _corTextoSecundario),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: filtrados.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, idx) {
                            final vol = filtrados[idx];
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                backgroundColor: _corFundoSuave,
                                child: Text(
                                  vol.nome.characters.first.toUpperCase(),
                                  style: const TextStyle(
                                    color: _corVerde,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                vol.nome,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              subtitle: vol.infoSecundaria != null
                                  ? Text(
                                      vol.infoSecundaria!,
                                      style: const TextStyle(fontSize: 11),
                                    )
                                  : null,
                              onTap: () => Navigator.of(ctx).pop(vol),
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
      },
    );
  }

  static Future<bool> abrirFormularioSuprimento(
    BuildContext context, {
    OngSuprimentoItem? itemExistente,
    required String nomeOng,
    required OngSuprimentosService service,
    required List<VoluntarioPlataforma> voluntarios,
    required bool carregandoVoluntarios,
    required Future<void> Function() onRecarregarVoluntarios,
    required void Function(String msg, {bool erro}) onFeedback,
    required void Function({
      required String itemId,
      required String itemNome,
      required String tipo,
      required String descricao,
      required String ator,
      String? quemBateuMeta,
    }) onRegistrarLog,
  }) async {
    final isEdicao = itemExistente != null;
    final nomeCtrl = TextEditingController(text: itemExistente?.nome ?? '');
    final doadorInicialCtrl = TextEditingController();

    String unidadeSelecionada =
        unidadesDisponiveis.contains(itemExistente?.unidade.trim())
            ? itemExistente!.unidade.trim()
            : 'un';

    final metaCtrl = TextEditingController(
      text: itemExistente != null
          ? formatarQtd(itemExistente.quantidadeMeta)
          : '20',
    );
    final recebidaCtrl = TextEditingController(
      text: itemExistente != null
          ? formatarQtd(itemExistente.quantidadeRecebida)
          : '0',
    );

    final dataParseada = parseDataPrazo(itemExistente?.prazoLimite);
    DateTime? dataPrazo =
        dataParseada != null && !dataParseada.isBefore(hojeSemHora)
            ? DateTime(dataParseada.year, dataParseada.month, dataParseada.day)
            : hojeSemHora.add(const Duration(days: 15));

    String prioridade = _normalizarPrioridade(itemExistente?.prioridade);
    bool sincronizarPerfil = itemExistente?.sincronizarPerfil ?? true;

    final salvo = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        bool enviando = false;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            Future<void> selecionarPrazo() async {
              final inicial =
                  (dataPrazo != null && !dataPrazo!.isBefore(hojeSemHora))
                      ? dataPrazo!
                      : hojeSemHora;
              final escolhida = await showDatePicker(
                context: ctx,
                initialDate: inicial,
                firstDate: hojeSemHora,
                lastDate: hojeSemHora.add(const Duration(days: 365 * 5)),
                helpText: "Selecione o prazo (a partir de hoje)",
              );
              if (escolhida != null) {
                setModalState(() => dataPrazo = escolhida);
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  14,
                  20,
                  MediaQuery.of(ctx).viewInsets.bottom + 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _corBordaSuave,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isEdicao
                            ? "Editar Suprimento"
                            : "Novo Item de Suprimento",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _corTextoEscuro,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nomeCtrl,
                        decoration: const InputDecoration(
                          labelText:
                              "Nome do item (ex.: Panetone para o Natal)",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: metaCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                labelText: "Quantidade meta",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: recebidaCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                labelText: "Recebido / Estoque",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 105,
                            child: DropdownButtonFormField<String>(
                              value: unidadeSelecionada,
                              decoration: const InputDecoration(
                                labelText: "Unidade",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: unidadesDisponiveis
                                  .map(
                                    (u) => DropdownMenuItem<String>(
                                      value: u,
                                      child: Text(
                                        u,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() => unidadeSelecionada = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: prioridade,
                              decoration: const InputDecoration(
                                labelText: "Prioridade",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: prioridadesDisponiveis
                                  .map(
                                    (p) => DropdownMenuItem<String>(
                                      value: p,
                                      child: Text(
                                        p,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() => prioridade = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: selecionarPrazo,
                              icon: const Icon(Icons.event_rounded,
                                  size: 16, color: _corVerde),
                              label: Text(
                                dataPrazo != null
                                    ? "Prazo: ${formatarDataBr(dataPrazo!)}"
                                    : "Escolher prazo",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _corTextoEscuro,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: _corBordaSuave),
                                backgroundColor: _corFundoSuave,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 11),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: doadorInicialCtrl,
                              decoration: const InputDecoration(
                                labelText: "Doador / Responsável (log local)",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final vol = await abrirSeletorVoluntario(
                                ctx,
                                voluntarios: voluntarios,
                                carregando: carregandoVoluntarios,
                                onRecarregar: onRecarregarVoluntarios,
                              );
                              if (vol != null) {
                                setModalState(() {
                                  doadorInicialCtrl.text = vol.nome;
                                });
                              }
                            },
                            icon: const Icon(Icons.person_add_alt_1_rounded,
                                size: 15, color: _corVerde),
                            label: const Text(
                              "Voluntário",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _corVerde,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: _corBordaSuave),
                              backgroundColor: _corFundoSuave,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: _corVerde,
                        title: const Text(
                          "Sincronizar necessidades no perfil da ONG",
                          style: TextStyle(fontSize: 12),
                        ),
                        value: sincronizarPerfil,
                        onChanged: (val) =>
                            setModalState(() => sincronizarPerfil = val),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: enviando
                            ? null
                            : () async {
                                final nome = nomeCtrl.text.trim();
                                if (nome.isEmpty) {
                                  onFeedback("Informe o nome do item.",
                                      erro: true);
                                  return;
                                }

                                final qtdMeta = (double.tryParse(metaCtrl.text
                                            .trim()
                                            .replaceAll(',', '.')) ??
                                        1)
                                    .clamp(0.1, 9999999.0);
                                final qtdRecebida = (double.tryParse(
                                            recebidaCtrl.text
                                                .trim()
                                                .replaceAll(',', '.')) ??
                                        0)
                                    .clamp(0.0, 9999999.0);

                                final unidLimpa =
                                    unidadeSelecionada.trim().isEmpty
                                        ? 'un'
                                        : unidadeSelecionada.trim();
                                final doadorNome =
                                    doadorInicialCtrl.text.trim();

                                final prazoIso = dataPrazo != null
                                    ? DateTime(
                                        dataPrazo!.year,
                                        dataPrazo!.month,
                                        dataPrazo!.day,
                                        23,
                                        59,
                                        59,
                                      ).toUtc().toIso8601String()
                                    : null;

                                final payload = <String, dynamic>{
                                  'nome': nome,
                                  'unidade': unidLimpa,
                                  'quantidadeMeta': qtdMeta,
                                  'quantidadeRecebida': qtdRecebida,
                                  'prioridade': prioridade,
                                  'sincronizarPerfil': sincronizarPerfil,
                                  if (prazoIso != null) 'prazoLimite': prazoIso,
                                };

                                setModalState(() => enviando = true);
                                try {
                                  if (isEdicao) {
                                    await service.atualizarSuprimento(
                                      itemExistente.id,
                                      payload,
                                    );
                                  } else {
                                    await service.criarSuprimento(payload);
                                  }

                                  final bateuMeta = qtdRecebida >= qtdMeta;
                                  final ator = doadorNome.isNotEmpty
                                      ? doadorNome
                                      : nomeOng;
                                  final prazoFmt = dataPrazo != null
                                      ? formatarDataBr(dataPrazo!)
                                      : '-';

                                  onRegistrarLog(
                                    itemId: itemExistente?.id ?? nome,
                                    itemNome: nome,
                                    tipo: isEdicao ? "EDICAO" : "CADASTRO",
                                    descricao: isEdicao
                                        ? "Atualizado: ${formatarQtd(qtdRecebida)}/${formatarQtd(qtdMeta)} $unidLimpa (prazo $prazoFmt)${bateuMeta ? ' • Meta atingida!' : ''}"
                                        : "Cadastrado: meta ${formatarQtd(qtdMeta)} $unidLimpa, recebido ${formatarQtd(qtdRecebida)} $unidLimpa (prazo $prazoFmt)",
                                    ator: ator,
                                    quemBateuMeta: bateuMeta ? ator : null,
                                  );

                                  if (ctx.mounted) Navigator.of(ctx).pop(true);
                                } catch (e) {
                                  setModalState(() => enviando = false);
                                  onFeedback(
                                    e.toString().replaceAll('Exception: ', ''),
                                    erro: true,
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _corVerde,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: enviando
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isEdicao
                                    ? "Salvar Alterações"
                                    : "Cadastrar Suprimento",
                                style: const TextStyle(
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

    nomeCtrl.dispose();
    doadorInicialCtrl.dispose();
    metaCtrl.dispose();
    recebidaCtrl.dispose();

    return salvo == true;
  }

  static Future<bool> abrirRegistrarDoacao(
    BuildContext context, {
    required OngSuprimentoItem item,
    required OngSuprimentosService service,
    required List<VoluntarioPlataforma> voluntarios,
    required bool carregandoVoluntarios,
    required Future<void> Function() onRecarregarVoluntarios,
    required void Function(String msg, {bool erro}) onFeedback,
    required void Function({
      required String itemId,
      required String itemNome,
      required String tipo,
      required String descricao,
      required String ator,
      String? quemBateuMeta,
    }) onRegistrarLog,
  }) async {
    final doadorCtrl = TextEditingController();
    final qtdCtrl = TextEditingController(
      text: item.saldoFaltante > 0 ? formatarQtd(item.saldoFaltante) : '1',
    );
    final obsCtrl = TextEditingController();
    bool marcarComoEntregueAgora = true;

    final salvo = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        bool enviando = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(
                "Registrar Doação • ${item.nome}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _corTextoEscuro,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: doadorCtrl,
                            decoration: const InputDecoration(
                              labelText: "Quem doou / voluntário",
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: "Importar voluntário da plataforma",
                          onPressed: () async {
                            final vol = await abrirSeletorVoluntario(
                              ctx,
                              voluntarios: voluntarios,
                              carregando: carregandoVoluntarios,
                              onRecarregar: onRecarregarVoluntarios,
                            );
                            if (vol != null) {
                              setDialogState(() {
                                doadorCtrl.text = vol.nome;
                              });
                            }
                          },
                          icon: const Icon(Icons.person_search_rounded,
                              color: _corVerde),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: qtdCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Quantidade (${item.unidade})",
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: _corVerde,
                      title: const Text(
                        "Atualizar estoque recebido agora",
                        style: TextStyle(fontSize: 12),
                      ),
                      value: marcarComoEntregueAgora,
                      onChanged: (v) => setDialogState(
                          () => marcarComoEntregueAgora = v ?? true),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: obsCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: "Observação / previsão (opcional)",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      enviando ? null : () => Navigator.of(ctx).pop(false),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: enviando
                      ? null
                      : () async {
                          final qtd = double.tryParse(
                                  qtdCtrl.text.trim().replaceAll(',', '.')) ??
                              0;
                          if (qtd <= 0) {
                            onFeedback("Informe uma quantidade válida.",
                                erro: true);
                            return;
                          }

                          final nomeDoador = doadorCtrl.text.trim().isEmpty
                              ? "Voluntário / Doador"
                              : doadorCtrl.text.trim();

                          final payload = <String, dynamic>{
                            'quantidade': qtd,
                            'doadorNome': nomeDoador,
                            if (obsCtrl.text.trim().isNotEmpty)
                              'observacao': obsCtrl.text.trim(),
                          };

                          setDialogState(() => enviando = true);
                          try {
                            await service.registrarCompromissoDoacao(
                                item.id, payload);

                            String? quemBateuMeta;
                            if (marcarComoEntregueAgora) {
                              final novaRecebida =
                                  item.quantidadeRecebida + qtd;
                              await service.atualizarSuprimento(
                                item.id,
                                <String, dynamic>{
                                  'quantidadeRecebida': novaRecebida,
                                },
                              );
                              if (item.quantidadeMeta > 0 &&
                                  novaRecebida >= item.quantidadeMeta) {
                                quemBateuMeta = nomeDoador;
                              }
                            }

                            onRegistrarLog(
                              itemId: item.id,
                              itemNome: item.nome,
                              tipo: marcarComoEntregueAgora
                                  ? "DOACAO_RECEBIDA"
                                  : "COMPROMISSO",
                              descricao:
                                  "+${formatarQtd(qtd)} ${item.unidade} de $nomeDoador${marcarComoEntregueAgora ? ' (estoque atualizado)' : ' (prometido)'}",
                              ator: nomeDoador,
                              quemBateuMeta: quemBateuMeta,
                            );

                            if (ctx.mounted) Navigator.of(ctx).pop(true);
                          } catch (e) {
                            setDialogState(() => enviando = false);
                            onFeedback(
                              e.toString().replaceAll('Exception: ', ''),
                              erro: true,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: _corVerde),
                  child: const Text(
                    "Registrar",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    doadorCtrl.dispose();
    qtdCtrl.dispose();
    obsCtrl.dispose();

    return salvo == true;
  }

  static void abrirLogs(
    BuildContext context, {
    required List<LogTransacaoSuprimento> logs,
    String? filtrarItemId,
    String? tituloItem,
  }) {
    final logsExibidos = filtrarItemId == null
        ? logs
        : logs.where((l) => l.itemId == filtrarItemId).toList();

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
                      color: _corBordaSuave,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.history_rounded,
                        color: _corVerde, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tituloItem != null
                            ? "Logs • $tituloItem"
                            : "Logs de Transações de Suprimentos",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _corTextoEscuro,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (logsExibidos.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _corFundoSuave,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _corBordaSuave),
                    ),
                    child: const Text(
                      "Nenhuma transação registrada nesta sessão ainda.",
                      style:
                          TextStyle(fontSize: 12, color: _corTextoSecundario),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: logsExibidos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, idx) {
                        final log = logsExibidos[idx];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _corFundoSuave,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _corBordaSuave),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${log.tipo} • ${log.itemNome}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _corVerde,
                                    ),
                                  ),
                                  Text(
                                    formatarDataHoraLog(log.timestamp),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: _corTextoSecundario,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                log.descricao,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _corTextoEscuro,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Responsável/Doador: ${log.ator}",
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: _corTextoSecundario,
                                ),
                              ),
                            ],
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

  static void abrirCompromissos(
    BuildContext context, {
    required OngSuprimentoItem item,
    required VoidCallback onRegistrarNovaDoacao,
    required Future<void> Function(
      OngSuprimentoItem item,
      OngCompromissoDoacao pledge,
      String novoStatus,
    ) onAlterarStatus,
  }) {
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
                      color: _corBordaSuave,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.inventory_2_rounded,
                        color: _corVerde, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Compromissos • ${item.nome}",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _corTextoEscuro,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onRegistrarNovaDoacao();
                      },
                      icon: const Icon(Icons.add_rounded,
                          size: 16, color: _corVerde),
                      label: const Text(
                        "Registrar Doação",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _corVerde,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (item.compromissos.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _corFundoSuave,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _corBordaSuave),
                    ),
                    child: const Text(
                      "Nenhum compromisso de doação registrado para este item.",
                      style:
                          TextStyle(fontSize: 12, color: _corTextoSecundario),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: item.compromissos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final p = item.compromissos[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _corFundoSuave,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _corBordaSuave),
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
                                      p.doadorNome,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _corTextoEscuro,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "${formatarQtd(p.quantidade)} ${item.unidade} • ${p.status}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _corVerde,
                                    ),
                                  ),
                                ],
                              ),
                              if (p.observacao != null &&
                                  p.observacao!.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  p.observacao!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: _corTextoSecundario,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  OutlinedButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      onAlterarStatus(item, p, 'ENTREGUE');
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      side: const BorderSide(
                                          color: Color(0xFF389E0D)),
                                    ),
                                    child: const Text(
                                      "Entregue",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF389E0D),
                                      ),
                                    ),
                                  ),
                                  OutlinedButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      onAlterarStatus(item, p, 'ATRASADO');
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      side: const BorderSide(
                                          color: Color(0xFFD46B08)),
                                    ),
                                    child: const Text(
                                      "Atrasado",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFD46B08),
                                      ),
                                    ),
                                  ),
                                  OutlinedButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      onAlterarStatus(item, p, 'CANCELADO');
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      side: const BorderSide(
                                          color: Colors.redAccent),
                                    ),
                                    child: const Text(
                                      "Cancelar",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
}
