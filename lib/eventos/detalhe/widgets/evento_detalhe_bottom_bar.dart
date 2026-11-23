// lib/eventos/detalhe/widgets/evento_detalhe_bottom_bar.dart

import 'package:flutter/material.dart';
import '../../models/evento_model.dart';

class EventoDetalheBottomBar extends StatelessWidget {
  final EventoModel evento;
  final bool isDono;
  final bool isEventoPassado;
  final bool isInscricoesEncerradas;
  final bool aguardandoAprovacaoLocal;
  final bool incluirSafeAreaBottom;
  final VoidCallback onInscrever;
  final VoidCallback onCancelar;
  final VoidCallback onEditarEvento;
  final VoidCallback onAbrirChamada;

  const EventoDetalheBottomBar({
    super.key,
    required this.evento,
    required this.isDono,
    required this.isEventoPassado,
    required this.isInscricoesEncerradas,
    required this.aguardandoAprovacaoLocal,
    required this.incluirSafeAreaBottom,
    required this.onInscrever,
    required this.onCancelar,
    required this.onEditarEvento,
    required this.onAbrirChamada,
  });

  bool get _estaAprovado {
    final status = (evento.statusInscricao ?? '').toUpperCase().trim();
    return status == 'ACCEPTED' ||
        status == 'APPROVED' ||
        status == 'CONFIRMED' ||
        status == 'CONFIRMADA' ||
        status == 'APROVADO' ||
        status == 'PRESENTE' ||
        status == 'ATTENDED';
  }

  @override
  Widget build(BuildContext context) {
    final bool estaConfirmado = evento.isInscrito && _estaAprovado;
    final bool pendenteAprovacao =
        aguardandoAprovacaoLocal || (evento.isInscrito && !_estaAprovado);

    final Widget conteudoBarra = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 860),
      child: isDono
          ? _buildAcoesOng()
          : estaConfirmado
              ? _buildStatusConfirmado()
              : pendenteAprovacao
                  ? _buildStatusPendente()
                  : _buildBotaoInscrever(),
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        incluirSafeAreaBottom ? MediaQuery.of(context).padding.bottom + 10 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFD9EAE6)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: incluirSafeAreaBottom,
        child: Center(child: conteudoBarra),
      ),
    );
  }

  Widget _buildAcoesOng() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child: OutlinedButton.icon(
              onPressed: onEditarEvento,
              icon: const Icon(
                Icons.edit_rounded,
                color: Color(0xFF0C6B6B),
                size: 18,
              ),
              label: const Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Editar Evento',
                    maxLines: 1,
                    style: TextStyle(
                      color: Color(0xFF0C6B6B),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                side: const BorderSide(color: Color(0xFF0C6B6B)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: onAbrirChamada,
              icon: const Icon(
                Icons.checklist_rtl_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: const Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Chamada & Gestão',
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                backgroundColor: const Color(0xFF0C6B6B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusConfirmado() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: isEventoPassado
                  ? const Color(0xFFECEFF1)
                  : const Color(0xFFD1F5EE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isEventoPassado
                      ? Icons.history_rounded
                      : Icons.check_circle_rounded,
                  color: isEventoPassado
                      ? const Color(0xFF546E7A)
                      : const Color(0xFF0C6B6B),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  isEventoPassado
                      ? 'Evento Passado • Participou'
                      : 'Presença Confirmada',
                  style: TextStyle(
                    color: isEventoPassado
                        ? const Color(0xFF546E7A)
                        : const Color(0xFF0C6B6B),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isEventoPassado) ...[
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: onCancelar,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cancelar'),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusPendente() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: isEventoPassado
                  ? const Color(0xFFECEFF1)
                  : const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isEventoPassado
                    ? const Color(0xFFCFD8DC)
                    : const Color(0xFFFFD591),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isEventoPassado
                      ? Icons.history_rounded
                      : Icons.hourglass_top_rounded,
                  color: isEventoPassado
                      ? const Color(0xFF546E7A)
                      : const Color(0xFFD46B08),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  isEventoPassado
                      ? 'Evento Passado'
                      : 'Aguardando Aprovação da ONG',
                  style: TextStyle(
                    color: isEventoPassado
                        ? const Color(0xFF546E7A)
                        : const Color(0xFFD46B08),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isEventoPassado) ...[
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: onCancelar,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey,
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Desistir'),
          ),
        ],
      ],
    );
  }

  Widget _buildBotaoInscrever() {
    return ElevatedButton(
      onPressed:
          (isEventoPassado || isInscricoesEncerradas) ? null : onInscrever,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0C6B6B),
        disabledBackgroundColor: Colors.grey.shade300,
        minimumSize: const Size(double.infinity, 46),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        isEventoPassado
            ? 'Evento Passado'
            : (isInscricoesEncerradas
                ? 'Inscrições Encerradas'
                : 'Quero Participar desta Ação'),
        style: TextStyle(
          color: (isEventoPassado || isInscricoesEncerradas)
              ? Colors.grey.shade700
              : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
