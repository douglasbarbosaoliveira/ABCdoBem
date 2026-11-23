// lib/ongs/painel_geral/models/suprimentos_erp_models.dart

enum FiltroSuprimentos { todos, pendentes, urgentes, atingidos }

class LogTransacaoSuprimento {
  final String id;
  final String itemId;
  final String itemNome;
  final String tipo;
  final String descricao;
  final String ator;
  final DateTime timestamp;

  const LogTransacaoSuprimento({
    required this.id,
    required this.itemId,
    required this.itemNome,
    required this.tipo,
    required this.descricao,
    required this.ator,
    required this.timestamp,
  });
}

class VoluntarioPlataforma {
  final String id;
  final String nome;
  final String? infoSecundaria;

  const VoluntarioPlataforma({
    required this.id,
    required this.nome,
    this.infoSecundaria,
  });
}
