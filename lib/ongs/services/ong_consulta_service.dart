// lib/ongs/services/ong_consulta_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OngConsultaService {
  static const List _municipiosGrandeAbc = [
    'santo andre',
    'sao bernardo do campo',
    'sao caetano do sul',
    'diadema',
    'maua',
    'ribeirao pires',
    'rio grande da serra',
  ];

  static String _apenasDigitos(String texto) {
    final buffer = StringBuffer();
    for (int i = 0; i < texto.length; i++) {
      final code = texto.codeUnitAt(i);
      if (code >= 48 && code <= 57) {
        buffer.writeCharCode(code);
      }
    }
    return buffer.toString();
  }

  static String _removerAcentos(String texto) {
    const comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const semAcento = 'aaaaaeeeeiiiiooooouuuucn';
    String resultado = texto.trim().toLowerCase();
    for (int i = 0; i < comAcento.length; i++) {
      resultado = resultado.replaceAll(comAcento[i], semAcento[i]);
    }
    return resultado;
  }

  /// Valida exclusivamente os 7 municípios do Grande ABC Paulista
  static bool pertenceAoGrandeAbc(String cidade, String uf) {
    if (uf.trim().toUpperCase() != 'SP') return false;
    final cidadeNormalizada = _removerAcentos(cidade);
    return _municipiosGrandeAbc.contains(cidadeNormalizada);
  }

  /// Consulta CNPJ na BrasilAPI com contingência na Minha Receita e valida Grande ABC
  static Future consultarCnpj(String cnpj) async {
    final cnpjLimpo = _apenasDigitos(cnpj);
    if (cnpjLimpo.length != 14) {
      throw Exception('CNPJ inválido.');
    }

    Map? dados;

    // 1ª Tentativa: BrasilAPI
    try {
      final resBrasil = await http.get(
        Uri.parse('https://brasilapi.com.br/api/cnpj/v1/$cnpjLimpo'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (resBrasil.statusCode == 200) {
        dados = json.decode(utf8.decode(resBrasil.bodyBytes)) as Map;
      } else if (resBrasil.statusCode == 404) {
        throw const FormatException(
            'CNPJ não encontrado na base da Receita Federal.');
      }
    } on FormatException {
      rethrow;
    } catch (e) {
      debugPrint('Falha na BrasilAPI ($e), tentando contingência...');
    }

    // 2ª Tentativa (Contingência): Minha Receita
    if (dados == null) {
      final resFallback = await http.get(
        Uri.parse('https://minhareceita.org/$cnpjLimpo'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 12));

      if (resFallback.statusCode == 200) {
        dados = json.decode(utf8.decode(resFallback.bodyBytes)) as Map;
      } else if (resFallback.statusCode == 404) {
        throw const FormatException(
            'CNPJ não encontrado na base da Receita Federal.');
      } else {
        throw Exception(
            'Erro HTTP ${resFallback.statusCode} ao consultar CNPJ.');
      }
    }

    final String municipio = (dados['municipio'] ?? '').toString();
    final String uf = (dados['uf'] ?? '').toString();

    if (!pertenceAoGrandeAbc(municipio, uf)) {
      return {
        'permitido': false,
        'municipio': municipio,
        'uf': uf,
      };
    }

    // Formata telefone
    String telefoneFormatado = '';
    final String ddd = (dados['ddd_telefone_1'] ?? '').toString().trim();
    if (ddd.isNotEmpty) {
      final nums = _apenasDigitos(ddd);
      if (nums.length == 10) {
        telefoneFormatado =
            '(${nums.substring(0, 2)}) ${nums.substring(2, 6)}-${nums.substring(6)}';
      } else if (nums.length >= 11) {
        telefoneFormatado =
            '(${nums.substring(0, 2)}) ${nums.substring(2, 7)}-${nums.substring(7, 11)}';
      }
    }

    // Formata CEP
    final String cepRaw = _apenasDigitos((dados['cep'] ?? '').toString());
    final String cepFormatado = cepRaw.length == 8
        ? '${cepRaw.substring(0, 5)}-${cepRaw.substring(5)}'
        : cepRaw;

    // Formata Logradouro
    final String logradouro = (dados['logradouro'] ?? '').toString();
    final String tipoLogradouro =
        (dados['descricao_tipo_de_logradouro'] ?? '').toString();
    final String ruaCompleta = tipoLogradouro.isNotEmpty &&
            !logradouro.toLowerCase().startsWith(tipoLogradouro.toLowerCase())
        ? '$tipoLogradouro $logradouro'.trim()
        : logradouro;

    // Extrai Ano
    final String dataInicio = (dados['data_inicio_atividade'] ?? '').toString();
    final String ano = dataInicio.length >= 4 ? dataInicio.substring(0, 4) : '';

    return {
      'permitido': true,
      'razao_social': (dados['razao_social'] ?? '').toString(),
      'nome_fantasia': (dados['nome_fantasia'] ?? '').toString().trim(),
      'ano_fundacao': ano,
      'telefone': telefoneFormatado,
      'cep': cepFormatado,
      'rua': ruaCompleta,
      'numero': (dados['numero'] ?? '').toString(),
      'bairro': (dados['bairro'] ?? '').toString(),
      'cidade': municipio,
      'estado': uf,
    };
  }

  /// Consulta CEP via ViaCEP e valida se pertence ao Grande ABC
  static Future consultarCep(String cep) async {
    final cepLimpo = _apenasDigitos(cep);
    if (cepLimpo.length != 8) {
      throw Exception('CEP inválido.');
    }

    final res = await http
        .get(Uri.parse('https://viacep.com.br/ws/$cepLimpo/json/'))
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception('Erro HTTP ${res.statusCode} ao buscar CEP.');
    }

    final dados = json.decode(utf8.decode(res.bodyBytes)) as Map;
    if (dados['erro'] == true) {
      throw const FormatException('CEP não encontrado.');
    }

    final String localidade = (dados['localidade'] ?? '').toString();
    final String uf = (dados['uf'] ?? '').toString();

    if (!pertenceAoGrandeAbc(localidade, uf)) {
      return {
        'permitido': false,
        'municipio': localidade,
        'uf': uf,
      };
    }

    return {
      'permitido': true,
      'rua': (dados['logradouro'] ?? '').toString(),
      'bairro': (dados['bairro'] ?? '').toString(),
      'cidade': localidade,
      'estado': uf,
    };
  }
}
