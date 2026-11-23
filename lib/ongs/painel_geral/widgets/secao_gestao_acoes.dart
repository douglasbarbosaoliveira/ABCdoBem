// lib/ongs/painel_geral/widgets/secao_gestao_acoes.dart

import 'package:flutter/material.dart';
import '../../../eventos/detalhe/evento_detalhe_page.dart';
import '../../criar_evento/criar_evento_page.dart';
import '../../gestao_eventos/gestao_eventos_page.dart';
import '../../services/ong_painel_service.dart';
import 'card_painel_base.dart';

class SecaoGestaoAcoes extends StatelessWidget {
  final String ongId;
  final String tipoUsuario;
  final bool isMobile;
  final ValueChanged<String> onNavegar;
  final VoidCallback onEventoCriado;
  final ValueChanged<OngAcaoResumo>? onEditarAcao;
  final List<OngAcaoResumo> acoes;

  const SecaoGestaoAcoes({
    super.key,
    required this.ongId,
    required this.tipoUsuario,
    required this.isMobile,
    required this.onNavegar,
    required this.onEventoCriado,
    this.onEditarAcao,
    this.acoes = const <OngAcaoResumo>[],
  });

  List<OngAcaoResumo> _selecionarDuasAcoes() {
    if (acoes.isEmpty) return const <OngAcaoResumo>[];
    final agora = DateTime.now();

    final futuros = <OngAcaoResumo>[];
    final passadosOuSemData = <OngAcaoResumo>[];

    for (final acao in acoes) {
      final dt = acao.dataEvento;
      if (dt != null && !dt.isBefore(agora)) {
        futuros.add(acao);
      } else {
        passadosOuSemData.add(acao);
      }
    }

    futuros.sort((a, b) => a.dataEvento!.compareTo(b.dataEvento!));
    passadosOuSemData.sort((a, b) {
      final da = a.dataEvento;
      final db = b.dataEvento;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });

    return <OngAcaoResumo>[...futuros, ...passadosOuSemData].take(2).toList();
  }

  void _abrirGestaoEventos(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => GestaoEventosPage(
          ongId: ongId,
          tipoUsuario: tipoUsuario,
        ),
      ),
    );
  }

  Future<void> _abrirDetalheEvento(
    BuildContext context,
    OngAcaoResumo acao,
  ) async {
    if (acao.id.trim().isEmpty) {
      _abrirGestaoEventos(context);
      return;
    }

    final alterou = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) => EventoDetalhePage(
          eventoId: acao.id,
          usuarioAtualId: ongId,
          isOng: true,
        ),
      ),
    );
    if (alterou == true) {
      onEventoCriado();
    }
  }

  @override
  Widget build(BuildContext context) {
    final duasAcoes = _selecionarDuasAcoes();

    const corDestaque = Color(0xFFD46B08);
    const corTitulo = Color(0xFF3B1D04);
    const corFundoItem = Color(0xFFFFF7EE);
    const corBordaItem = Color(0xFFF5D5B0);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _abrirGestaoEventos(context),
      child: Theme(
        data: Theme.of(context).copyWith(
          iconTheme: const IconThemeData(color: corDestaque),
        ),
        child: CardPainelBase(
          titulo: "2. Gestão de ações",
          icone: Icons.event_available_rounded,
          isMobile: isMobile,
          botaoAcao: ElevatedButton.icon(
            onPressed: () async {
              final criado =
                  await Navigator.of(context, rootNavigator: true).push<bool>(
                MaterialPageRoute(
                  builder: (_) => CriarEventoPage(
                    ongId: ongId,
                    tipoUsuario: tipoUsuario,
                  ),
                ),
              );
              if (criado == true) onEventoCriado();
            },
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              size: 13,
              color: Colors.white,
            ),
            label: const Text(
              "Novo Evento",
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0C6B6B),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
          conteudo: Column(
            children: [
              if (duasAcoes.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: corFundoItem,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: corBordaItem),
                  ),
                  child: const Text(
                    "Nenhuma ação ou evento cadastrado até o momento.",
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7A5433),
                    ),
                  ),
                )
              else
                ...duasAcoes.map((acao) {
                  final String dataHora = [
                    if (acao.dataFormatada.isNotEmpty) acao.dataFormatada,
                    if (acao.horarioFormatado.isNotEmpty) acao.horarioFormatado,
                  ].join(' - ');

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildItemEvento(
                      titulo: acao.titulo.isNotEmpty
                          ? acao.titulo
                          : "Ação sem título",
                      dataInfo: dataHora.isNotEmpty ? dataHora : acao.status,
                      vagasInfo:
                          "${acao.vagasOcupadas}/${acao.vagasTotais} vagas",
                      pct: acao.ocupacao,
                      corDestaque: corDestaque,
                      corTitulo: corTitulo,
                      corFundoItem: corFundoItem,
                      corBordaItem: corBordaItem,
                      onTapEvento: () => _abrirDetalheEvento(context, acao),
                      onEditar: () {
                        if (onEditarAcao != null) {
                          onEditarAcao!(acao);
                        } else {
                          onNavegar("Editar ${acao.titulo}");
                        }
                      },
                    ),
                  );
                }),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _abrirGestaoEventos(context),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Text(
                    "Ver histórico completo ->",
                    style: TextStyle(
                      color: Color(0xFF0C6B6B),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemEvento({
    required String titulo,
    required String dataInfo,
    required String vagasInfo,
    required double pct,
    required Color corDestaque,
    required Color corTitulo,
    required Color corFundoItem,
    required Color corBordaItem,
    required VoidCallback onTapEvento,
    required VoidCallback onEditar,
  }) {
    return Material(
      color: corFundoItem,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTapEvento,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: corBordaItem),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      titulo,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: corTitulo,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.edit_note_rounded,
                      size: 18,
                      color: corDestaque,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onEditar,
                  ),
                ],
              ),
              Text(
                dataInfo,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF7A5433),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: corBordaItem,
                        color: corDestaque,
                        minHeight: 5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    vagasInfo,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: corDestaque,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
