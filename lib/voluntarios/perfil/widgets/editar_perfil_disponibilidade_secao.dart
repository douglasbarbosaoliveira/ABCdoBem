// lib/voluntarios/perfil/widgets/editar_perfil_disponibilidade_secao.dart

import 'package:flutter/material.dart';
import '../../../../utils/app_data.dart';

class EditarPerfilDisponibilidadeSecao extends StatelessWidget {
  final List<String> disponibilidadeSelecionada;
  final List<String> causasSelecionadas;
  final ValueChanged<String> onToggleDisponibilidade;
  final ValueChanged<String> onToggleCausa;

  const EditarPerfilDisponibilidadeSecao({
    super.key,
    required this.disponibilidadeSelecionada,
    required this.causasSelecionadas,
    required this.onToggleDisponibilidade,
    required this.onToggleCausa,
  });

  static const int maxCausas = 3;

  static const List<String> opcoesTurnosBase = [
    "Manhã",
    "Tarde",
    "Noite",
    "Madrugada",
    "Dias úteis (Segunda a Sexta)",
    "Finais de semana (Sábado e Domingo)",
    "Feriados",
    "Horário flexível",
    ...AppData.formatosVoluntariado,
  ];

  /// Normaliza texto removendo emojis, espaços extras e acentos para comparação segura
  static String normalizarTexto(String texto) {
    final semAcentos = texto
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ç', 'c');

    final buffer = StringBuffer();
    for (int i = 0; i < semAcentos.length; i++) {
      final code = semAcentos.codeUnitAt(i);
      final isLetraOuNumero =
          (code >= 97 && code <= 122) || (code >= 48 && code <= 57);
      if (isLetraOuNumero) {
        buffer.writeCharCode(code);
      }
    }
    return buffer.toString();
  }

  static bool listaContemEquivalente(List<String> lista, String alvo) {
    final normAlvo = normalizarTexto(alvo);
    if (normAlvo.isEmpty) return false;
    return lista.any((item) => normalizarTexto(item) == normAlvo);
  }

  List<String> get _todasOpcoesTurnos {
    final List<String> lista = List<String>.from(opcoesTurnosBase);
    for (final salvo in disponibilidadeSelecionada) {
      if (!listaContemEquivalente(lista, salvo)) {
        lista.add(salvo);
      }
    }
    return lista;
  }

  List<String> get _todasOpcoesCausas {
    final List<String> lista = AppData.habilidadesPorCausa.keys.toList();
    for (final salva in causasSelecionadas) {
      if (!listaContemEquivalente(lista, salva)) {
        lista.add(salva);
      }
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final turnos = _todasOpcoesTurnos;
    final causas = _todasOpcoesCausas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Disponibilidade no ABC",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF062222),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Selecione os períodos e formatos em que você pode atuar.",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: turnos.map((turno) {
            final ativo =
                listaContemEquivalente(disponibilidadeSelecionada, turno);
            return FilterChip(
              label: Text(
                turno,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: ativo ? FontWeight.bold : FontWeight.w500,
                  color: ativo ? Colors.white : const Color(0xFF062222),
                ),
              ),
              selected: ativo,
              selectedColor: const Color(0xFF0C6B6B),
              backgroundColor: const Color(0xFFF0FAF7),
              checkmarkColor: Colors.white,
              side: BorderSide(
                color:
                    ativo ? const Color(0xFF0C6B6B) : const Color(0xFFC2E4DC),
              ),
              onSelected: (_) => onToggleDisponibilidade(turno),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Causas de Interesse",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF062222),
              ),
            ),
            Text(
              "${causasSelecionadas.length}/$maxCausas selecionadas",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: causasSelecionadas.length >= maxCausas
                    ? const Color(0xFF0C6B6B)
                    : Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          "Escolha até 3 causas sociais com as quais você mais se identifica.",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: causas.map((causa) {
            final ativo = listaContemEquivalente(causasSelecionadas, causa);
            final bloqueado = !ativo && causasSelecionadas.length >= maxCausas;
            return FilterChip(
              label: Text(
                causa,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: ativo ? FontWeight.bold : FontWeight.w500,
                  color: ativo
                      ? Colors.white
                      : (bloqueado ? Colors.grey : const Color(0xFF062222)),
                ),
              ),
              selected: ativo,
              selectedColor: const Color(0xFF0C6B6B),
              backgroundColor: const Color(0xFFF0FAF7),
              checkmarkColor: Colors.white,
              side: BorderSide(
                color:
                    ativo ? const Color(0xFF0C6B6B) : const Color(0xFFC2E4DC),
              ),
              onSelected: (_) => onToggleCausa(causa),
            );
          }).toList(),
        ),
      ],
    );
  }
}
