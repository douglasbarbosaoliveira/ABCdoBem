// lib/utils/tempo_plataforma_formatter.dart

class TempoPlataformaFormatter {
  static String formatarTempoNaPlataforma(DateTime? dataCadastro,
      {DateTime? referencia}) {
    if (dataCadastro == null) return '';

    final DateTime agora = referencia ?? DateTime.now();
    final DateTime inicio =
        DateTime(dataCadastro.year, dataCadastro.month, dataCadastro.day);
    final DateTime fim = DateTime(agora.year, agora.month, agora.day);

    if (fim.isBefore(inicio)) return 'Hoje';

    final int diasTotais = fim.difference(inicio).inDays;
    if (diasTotais <= 1) {
      return diasTotais == 0 ? 'Hoje' : '1 dia';
    }

    if (diasTotais < 30) {
      return '$diasTotais dias';
    }

    int meses = (fim.year - inicio.year) * 12 + (fim.month - inicio.month);
    if (fim.day < inicio.day) {
      meses -= 1;
    }
    if (meses < 1) meses = 1;

    if (meses < 12) {
      return meses == 1 ? '1 mês' : '$meses meses';
    }

    final int anos = meses ~/ 12;
    return anos == 1 ? '1 ano' : '$anos anos';
  }
}
