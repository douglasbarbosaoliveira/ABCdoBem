// lib/ongs/perfil/widgets/ong_perfil_localizacao_section.dart

import 'package:flutter/material.dart';
import '../../../widgets/mapa/localizacao_mapa_card.dart';

class OngPerfilLocalizacaoSection extends StatelessWidget {
  final String enderecoCompleto;
  final String cidade;
  final bool isMobile;
  final double latitude;
  final double longitude;

  const OngPerfilLocalizacaoSection({
    super.key,
    required this.enderecoCompleto,
    required this.cidade,
    required this.isMobile,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return LocalizacaoMapaCard(
      tituloSecao: "Sede e Localização",
      endereco: enderecoCompleto,
      cidade: cidade,
      latitude: latitude,
      longitude: longitude,
      alturaMapa: isMobile ? 180 : 210,
      tooltipCentralizar: "Centralizar na sede da ONG",
    );
  }
}
