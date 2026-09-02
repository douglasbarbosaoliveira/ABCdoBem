// lib/models/voluntario_cadastro_dto.dart

/// DTO consolidado com todas as informações das 3 etapas de cadastro do voluntário
class VoluntarioCadastroDTO {
  // Etapa 1: Dados básicos e acesso
  final String nome;
  final String email;
  final String? telefone;
  final String? dataNascimento;
  final String cidade;
  final String estado;
  final String? senha;

  // Etapa 2: Interesses e Habilidades
  final List<String> habilidades;

  // Etapa 3: Disponibilidade e Aceites Legais
  final List<String> disponibilidade;
  final bool termosAceitos;
  final bool lgpdAceita;

  VoluntarioCadastroDTO({
    required this.nome,
    required this.email,
    this.telefone,
    this.dataNascimento,
    required this.cidade,
    required this.estado,
    this.senha,
    required this.habilidades,
    required this.disponibilidade,
    required this.termosAceitos,
    required this.lgpdAceita,
  });

  /// Converte a união dos Maps das 3 etapas no objeto tipado
  factory VoluntarioCadastroDTO.deEtapas({
    required Map<String, String> dadosBasicos,
    required List<String> habilidades,
    required List<String> disponibilidade,
    required bool termosAceitos,
    required bool lgpdAceita,
  }) {
    return VoluntarioCadastroDTO(
      nome: dadosBasicos['nome'] ?? '',
      email: dadosBasicos['email'] ?? '',
      telefone: dadosBasicos['telefone'],
      dataNascimento: dadosBasicos['dataNascimento'],
      cidade: dadosBasicos['cidade'] ?? 'Grande ABC',
      estado: dadosBasicos['estado'] ?? 'SP',
      senha: dadosBasicos['senha'],
      habilidades: habilidades,
      disponibilidade: disponibilidade,
      termosAceitos: termosAceitos,
      lgpdAceita: lgpdAceita,
    );
  }

  /// Converte para o formato JSON esperado pelo endpoint da API
  Map<String, dynamic> toJson() {
    return {
      'nome': nome.trim(),
      'email': email.trim().toLowerCase(),
      'telefone': telefone,
      'dataNascimento': dataNascimento,
      'cidade': cidade,
      'estado': estado,
      if (senha != null && senha!.isNotEmpty) 'senha': senha,
      'habilidades': habilidades,
      'disponibilidade': disponibilidade,
      'termos_aceitos': termosAceitos,
      'lgpd_aceita': lgpdAceita,
    };
  }
}

/// Resposta de sucesso do cadastro retornada pela API
class RespostaCadastroVoluntario {
  final String voluntarioId;
  final String tokenJWT;
  final String mensagem;

  RespostaCadastroVoluntario({
    required this.voluntarioId,
    required this.tokenJWT,
    required this.mensagem,
  });

  factory RespostaCadastroVoluntario.fromJson(Map<String, dynamic> json) {
    return RespostaCadastroVoluntario(
      voluntarioId:
          json['voluntarioId']?.toString() ?? json['id']?.toString() ?? '',
      tokenJWT: json['token'] ?? json['tokenJWT'] ?? '',
      mensagem: json['mensagem'] ?? 'Cadastro concluído com sucesso!',
    );
  }
}
