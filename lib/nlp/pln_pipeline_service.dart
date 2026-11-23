// lib/nlp/pln_pipeline_service.dart

import '../utils/app_data.dart';
import 'vocabulario_causas.dart';

class PlnPipelineService {
  // Conjunto completo de Stop Words em Português (sem duplicatas)
  static const Set<String> stopWordsCompletas = {
    ...VocabularioCausas.stopWords,
    'ante',
    'apos',
    'contra',
    'desde',
    'entre',
    'per',
    'perante',
    'sem',
    'tras',
    'mas',
    'porem',
    'contudo',
    'todavia',
    'entretanto',
    'portanto',
    'logo',
    'pois',
    'porque',
    'embora',
    'conforme',
    'segundo',
    'este',
    'esta',
    'estes',
    'estas',
    'isto',
    'esse',
    'essa',
    'esses',
    'essas',
    'isso',
    'aquele',
    'aquela',
    'aqueles',
    'aquelas',
    'aquilo',
    'meu',
    'minha',
    'meus',
    'minhas',
    'teu',
    'tua',
    'nosso',
    'nossa',
    'nossos',
    'nossas',
    'dele',
    'dela',
    'deles',
    'delas',
    'qual',
    'quais',
    'quem',
    'onde',
    'quando',
    'quanto',
    'quanta',
    'quantos',
    'quantas',
    'muito',
    'muita',
    'muitos',
    'muitas',
    'pouco',
    'pouca',
    'poucos',
    'poucas',
    'todo',
    'toda',
    'todos',
    'todas',
    'outro',
    'outra',
    'outros',
    'outras',
    'algum',
    'alguma',
    'alguns',
    'algumas',
    'nenhum',
    'nenhuma',
    'cada',
    'mesmo',
    'mesma',
    'proprio',
    'propria',
    'tal',
    'tais',
    'ser',
    'estar',
    'ter',
    'haver',
    'fazer',
    'ir',
    'vir',
    'poder',
    'dever',
    'sao',
    'foi',
    'foram',
    'era',
    'eram',
    'sera',
    'serao',
    'tem',
    'tinha',
    'estao',
    'estava',
    'ja',
    'nao',
    'sim',
    'tambem',
    'ainda',
    'apenas',
    'somente',
    'so',
    'bem',
    'mal',
    'aqui',
    'ali',
    'la',
    'ca',
    'precisamos',
    'precisa',
    'necessitamos',
    'necessita',
    'urgente',
    'urgentes',
    'doacao',
    'doacoes',
    'voluntario',
    'voluntarios',
    'ajuda',
    'mutirao',
    'acao',
    'campanha',
    'projeto',
    'abc',
    'maua',
    'santo',
    'andre',
    'bernardo',
    'caetano',
    'diadema',
    'ribeirao',
    'pires',
  };

  // Dicionário de correção ortográfica e mapeamento de sinônimos/gírias regionais
  static const Map<String, String> _correcoesESinonimos = {
    'fejao': 'feijao',
    'arros': 'arroz',
    'macarao': 'macarrao',
    'mantimento': 'alimentos',
    'mantimentos': 'alimentos',
    'marmitex': 'marmita',
    'quentinha': 'marmita',
    'quentinhas': 'marmita',
    'frada': 'fralda',
    'fradas': 'fraldas',
    'coberto': 'cobertor',
    'agasalhos': 'agasalho',
    'roupa': 'roupas',
    'calcado': 'calcados',
    'tenis': 'calcados',
    'sapato': 'calcados',
    'remedio': 'medicamentos',
    'remedios': 'medicamentos',
    'curativo': 'insumos',
    'curativos': 'insumos',
    'psicologo': 'psicologia',
    'psicologa': 'psicologia',
    'terapeuta': 'terapias',
    'pedagogo': 'ensino',
    'pedagoga': 'ensino',
    'professor': 'ensino',
    'professora': 'ensino',
    'contraturno': 'reforco',
    'tutor': 'mentoria',
    'tutora': 'mentoria',
    'medico': 'medicina',
    'medica': 'medicina',
    'enfermeiro': 'enfermagem',
    'enfermeira': 'enfermagem',
    'dentista': 'odontologia',
    'fisio': 'fisioterapia',
    'nutri': 'nutricao',
    'cozinheiro': 'cozinha',
    'cozinheira': 'cozinha',
    'padeiro': 'panificacao',
    'motorista': 'transporte',
    'frete': 'transporte',
    'van': 'transporte',
    'advogado': 'direito',
    'advogada': 'direito',
    'juridico': 'direito',
    'programador': 'software',
    'dev': 'software',
    'ti': 'tecnologia',
    'computadores': 'computador',
    'notebooks': 'notebook',
    'veterinario': 'veterinaria',
    'veterinaria': 'veterinaria',
    'pet': 'animais',
    'cachorro': 'animais',
    'gato': 'animais',
    'racao': 'racao',
    'racoes': 'racao',
    'crianca': 'criancas',
    'idoso': 'idosos',
    'idosa': 'idosos',
    'cadernos': 'caderno',
    'livros': 'livro',
    'brinquedos': 'brinquedo',
  };

  static final RegExp _emojiRegex = RegExp(
    r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F1E0}-\u{1F1FF}]',
    unicode: true,
  );

  /// ETAPA 1: Normalizar (caixa baixa, remoção de emojis, acentos e espaços múltiplos)
  static String normalizar(String texto) {
    const comAcento = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖòóôõöÈÉÊËèéêëÌÍÎÏìíîïÙÚÛÜùúûüÇçÑñ';
    const semAcento = 'AAAAAAaaaaaaOOOOOoooooEEEEeeeeIIIIiiiiUUUUuuuuCcNn';

    String limpo = texto.replaceAll(_emojiRegex, '');
    for (int i = 0; i < comAcento.length; i++) {
      limpo = limpo.replaceAll(comAcento[i], semAcento[i]);
    }
    return limpo.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// ETAPA 2: Corrigir ortografia e normalizar sinônimos léxicos
  static String corrigirOrtografia(String textoNormalizado) {
    final palavras = textoNormalizado.split(' ');
    final corrigidas = palavras.map((p) {
      final limpa = p.replaceAll(RegExp(r'[^a-z0-9]'), '');
      return _correcoesESinonimos[limpa] ?? p;
    });
    return corrigidas.join(' ');
  }

  /// ETAPA 3 & 4: Tokenizar e Filtrar pontuação
  static List<String> tokenizarESemPontuacao(String texto) {
    return texto
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
  }

  /// ETAPA 5: Stemming em Português (redução ao radical)
  static String aplicarStemming(String token) {
    if (token.length <= 4) return token;

    const sufixos = [
      'amentos',
      'imentos',
      'amento',
      'imento',
      'adores',
      'adoras',
      'encias',
      'ancias',
      'amente',
      'izacao',
      'izacoes',
      'aveis',
      'iveis',
      'istas',
      'ismos',
      'acoes',
      'icoes',
      'ador',
      'adora',
      'avel',
      'ivel',
      'ista',
      'ismo',
      'acao',
      'icao',
      'eiro',
      'eira',
      'eiros',
      'eiras',
      'ario',
      'aria',
      'arios',
      'arias',
      'ando',
      'endo',
      'indo',
      'ar',
      'er',
      'ir',
      'es',
      'os',
      'as',
      's',
    ];

    for (final sufixo in sufixos) {
      if (token.endsWith(sufixo) && (token.length - sufixo.length) >= 4) {
        return token.substring(0, token.length - sufixo.length);
      }
    }
    return token;
  }

  /// PIPELINE COMPLETO (Etapas 1 a 6 em ordem estrita)
  static List<String> executarPipeline(String textoBruto) {
    // 1. Normalizar
    final passo1 = normalizar(textoBruto);
    if (passo1.isEmpty) return [];

    // 2. Corrigir ortografia e sinônimos
    final passo2 = corrigirOrtografia(passo1);

    // 3. Tokenizar + 4. Filtrar pontuação
    final passo3e4 = tokenizarESemPontuacao(passo2);

    // 6. Remover Stop Words + 5. Aplicar Stemming
    final stemsValidos = <String>[];
    for (final token in passo3e4) {
      if (token.length <= 2 || stopWordsCompletas.contains(token)) {
        continue;
      }
      final stem = aplicarStemming(token);
      if (stem.length >= 3 && !stopWordsCompletas.contains(stem)) {
        stemsValidos.add(stem);
      }
    }

    return stemsValidos;
  }

  /// Verifica se dois itens são semanticamente equivalentes sem bloquear perfis distintos de voluntários
  static bool saoSemanticamenteIguais(String a, String b) {
    final normA = normalizar(a);
    final normB = normalizar(b);
    if (normA == normB) return true;

    // Se ambos forem perfis de voluntário, exige igualdade exata da habilidade após "voluntario:"
    if (normA.startsWith('voluntario:') && normB.startsWith('voluntario:')) {
      final habA = normA.replaceFirst('voluntario:', '').trim();
      final habB = normB.replaceFirst('voluntario:', '').trim();
      return habA == habB;
    }

    // Se um for voluntário e o outro for material/doação, nunca são iguais
    if (normA.startsWith('voluntario:') != normB.startsWith('voluntario:')) {
      return false;
    }

    final stemsA = executarPipeline(a).toSet();
    final stemsB = executarPipeline(b).toSet();
    if (stemsA.isEmpty || stemsB.isEmpty) return false;

    return stemsA.length == stemsB.length && stemsA.containsAll(stemsB);
  }

  /// Motor completo de recomendação:
  /// Cruza [tipoOuCausaOng], [textosEventosAtivos] (títulos/descrições da API) e [textoDigitado].
  static List<String> recomendarNecessidades({
    String? tipoOuCausaOng,
    List<String> textosEventosAtivos = const [],
    String textoDigitado = '',
    List<String> jaSelecionados = const [],
    int minimoRecomendacoes = 5,
    int limite = 6,
  }) {
    final pontuacaoItens = <String, int>{};

    final textoDigitadoNorm = normalizar(textoDigitado);
    final stemsCausa = executarPipeline(tipoOuCausaOng ?? '');
    final stemsEventos = textosEventosAtivos
        .where((e) => e.trim().isNotEmpty)
        .expand(executarPipeline)
        .toSet();
    final stemsTexto = executarPipeline(textoDigitado);

    bool jaFoiSelecionado(String candidato) {
      return jaSelecionados
          .any((sel) => saoSemanticamenteIguais(sel, candidato));
    }

    for (final entry in AppData.doacoesPorCausa.entries) {
      final causaChave = entry.key;
      final stemsDaCausa = executarPipeline(causaChave).toSet();

      final chaveVocab = VocabularioCausas.dicionarioPorCausa.keys.firstWhere(
        (k) => normalizar(k) == normalizar(causaChave),
        orElse: () => '',
      );
      final termosVocab =
          VocabularioCausas.dicionarioPorCausa[chaveVocab] ?? [];
      final stemsVocab = termosVocab.expand(executarPipeline).toSet();

      int scoreBaseCausa = 0;

      // 1. Peso do perfil/causa principal da ONG
      for (final s in stemsCausa) {
        if (stemsDaCausa.contains(s)) scoreBaseCausa += 28;
        if (stemsVocab.contains(s)) scoreBaseCausa += 14;
      }

      // 2. Peso extra vindo dos eventos ativos cadastrados na API
      int scoreEventosNaCausa = 0;
      for (final s in stemsEventos) {
        if (stemsDaCausa.contains(s)) scoreEventosNaCausa += 20;
        if (stemsVocab.contains(s)) scoreEventosNaCausa += 15;
      }

      // 3. Peso dinâmico do que está sendo digitado agora
      int scoreTextoNaCausa = 0;
      for (final s in stemsTexto) {
        if (stemsDaCausa.contains(s)) scoreTextoNaCausa += 32;
        if (stemsVocab.contains(s)) scoreTextoNaCausa += 24;
      }

      final candidatos = <String>[
        ...entry.value.where((d) => normalizar(d) != 'outros'),
        ...(AppData.habilidadesPorCausa[causaChave] ?? [])
            .map((h) => 'Voluntário: $h'),
      ];

      for (final item in candidatos) {
        if (jaFoiSelecionado(item)) continue;

        final itemNorm = normalizar(item);
        int scoreItem =
            scoreBaseCausa + scoreEventosNaCausa + scoreTextoNaCausa;
        final stemsItem = executarPipeline(item);

        // Boost direto com a digitação atual
        if (textoDigitadoNorm.length >= 2) {
          if (itemNorm.contains(textoDigitadoNorm)) {
            scoreItem += 65;
          }
          for (final s in stemsTexto) {
            if (stemsItem.any((si) => si.startsWith(s) || s.startsWith(si))) {
              scoreItem += 48;
            }
          }
        }

        // Boost específico se o item combinar com algum evento ativo da ONG
        for (final s in stemsEventos) {
          if (stemsItem.any((si) => si.startsWith(s) || s.startsWith(si))) {
            scoreItem += 26;
          }
        }

        // Boost específico se o item combinar com a causa da ONG
        for (final s in stemsCausa) {
          if (stemsItem.any((si) => si.startsWith(s) || s.startsWith(si))) {
            scoreItem += 16;
          }
        }

        final scoreFinal = scoreItem > 0 ? scoreItem : 1;
        final atual = pontuacaoItens[item] ?? 0;
        if (scoreFinal > atual) {
          pontuacaoItens[item] = scoreFinal;
        }
      }
    }

    final ordenados = pontuacaoItens.entries.toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        if (cmp != 0) return cmp;
        return a.key.compareTo(b.key);
      });

    final qtdRetorno =
        limite < minimoRecomendacoes ? minimoRecomendacoes : limite;
    return ordenados.take(qtdRetorno).map((e) => e.key).toList();
  }
}
