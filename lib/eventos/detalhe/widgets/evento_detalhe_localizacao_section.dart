// lib/eventos/detalhe/widgets/evento_detalhe_localizacao_section.dart

import 'package:flutter/material.dart';
import '../../models/evento_model.dart';
import '../../../widgets/mapa/localizacao_mapa_card.dart';

class EventoDetalheLocalizacaoSection extends StatelessWidget {
  final EventoModel evento;
  final bool isDono;
  final VoidCallback? onEditarEndereco;

  const EventoDetalheLocalizacaoSection({
    super.key,
    required this.evento,
    required this.isDono,
    this.onEditarEndereco,
  });

  @override
  Widget build(BuildContext context) {
    return LocalizacaoMapaCard(
      tituloSecao: "Ponto de Encontro",
      endereco: evento.endereco ?? '',
      cidade: evento.cidade,
      latitude: evento.latitude,
      longitude: evento.longitude,
      alturaMapa: 200,
      mostrarBotaoEditar: isDono,
      onEditarEndereco: onEditarEndereco,
      tooltipCentralizar: "Centralizar no evento",
    );
  }
}
