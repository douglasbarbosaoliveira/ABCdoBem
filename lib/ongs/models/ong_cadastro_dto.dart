// lib/ongs/models/ong_cadastro_dto.dart

/// DTO consolidado alinhado exatamente ao schema POST /auth/ongRegister
class OngCadastroDTO {
  final Map<String, dynamic> dadosCompletosEtapasAnteriores;
  final List<String> habilidadesBuscadas;
  final List<String> doacoesAceitas;
  final String formatoVoluntariado;
  final String emailLogin;
  final String senhaLogin;
  final bool termosAceitos;
  final bool lgpdAceita;

  OngCadastroDTO({
    required this.dadosCompletosEtapasAnteriores,
    required this.habilidadesBuscadas,
    required this.doacoesAceitas,
    required this.formatoVoluntariado,
    required this.emailLogin,
    required this.senhaLogin,
    required this.termosAceitos,
    required this.lgpdAceita,
  });

  String? _textoOpcional(dynamic valor) {
    if (valor == null) return null;
    final texto = valor.toString().trim();
    return texto.isEmpty ? null : texto;
  }

  Map<String, dynamic> toJson() {
    final d = dadosCompletosEtapasAnteriores;

    final int anoFundacaoInt =
        int.tryParse((d['ano_fundacao'] ?? '').toString().trim()) ??
            DateTime.now().year;

    final String? avatarBase64 = _textoOpcional(d['logo_base64']);

    final Map<String, dynamic> payload = {
      'razaoSocial': (d['razao_social'] ?? '').toString().trim(),
      'name': (d['nome_fantasia'] ?? '').toString().trim(),
      'cnpj': (d['cnpj'] ?? '').toString().trim(),
      'anoFundacao': anoFundacaoInt,
      'telefoneFixo': (d['telefone'] ?? '').toString().trim(),
      'whatsapp': (d['whatsapp'] ?? '').toString().trim(),
      'cep': (d['cep'] ?? '').toString().trim(),
      'logradouro': (d['rua'] ?? '').toString().trim(),
      'numero': (d['numero'] ?? '').toString().trim(),
      'bairro': (d['bairro'] ?? '').toString().trim(),
      'cidade': (d['cidade'] ?? '').toString().trim(),
      'estado': (d['estado'] ?? '').toString().trim(),
      'causaPrincipal': (d['causa_principal'] ?? '').toString().trim(),
      'servicosOferecidos': List<String>.from(d['servicos_oferecidos'] ?? []),
      'publicoAtendido': List<String>.from(d['publico_atendido'] ?? []),
      'descricao': (d['descricao'] ?? '').toString().trim(),
      'habilidadesBuscadas': habilidadesBuscadas,
      'formatoVoluntariado': formatoVoluntariado,
      'aceitaDoacoes': doacoesAceitas,
      'email': emailLogin.trim().toLowerCase(),
      'password': senhaLogin,
      'aceiteTermos': termosAceitos,
      'aceiteLgpd': lgpdAceita,
    };

    // Campos opcionais: inclui apenas se preenchidos
    final site = _textoOpcional(d['site']);
    if (site != null) payload['site'] = site;

    final instagram = _textoOpcional(d['instagram']);
    if (instagram != null) payload['instagram'] = instagram;

    final facebook = _textoOpcional(d['facebook']);
    if (facebook != null) payload['facebook'] = facebook;

    final tiktok = _textoOpcional(d['tiktok']);
    if (tiktok != null) payload['tiktok'] = tiktok;

    if (avatarBase64 != null) {
      payload['avatar'] = avatarBase64;
    }

    return payload;
  }
}

/// Resposta de confirmação retornada pelo endpoint POST /auth/ongRegister
class RespostaCadastroOngModel {
  final String ongId;
  final String email;
  final String mensagem;

  RespostaCadastroOngModel({
    required this.ongId,
    required this.email,
    required this.mensagem,
  });

  factory RespostaCadastroOngModel.fromJson(
    Map<String, dynamic> json, {
    String emailFallback = '',
  }) {
    final userObj = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : null;
    final ongObj = json['ong'] is Map<String, dynamic>
        ? json['ong'] as Map<String, dynamic>
        : null;

    final idExtraido =
        json['ongId'] ?? json['id'] ?? ongObj?['id'] ?? userObj?['id'] ?? '';

    final emailExtraido =
        json['email'] ?? userObj?['email'] ?? ongObj?['email'] ?? emailFallback;

    return RespostaCadastroOngModel(
      ongId: idExtraido.toString(),
      email: emailExtraido.toString(),
      mensagem: (json['mensagem'] ??
              json['message'] ??
              'Cadastro realizado com sucesso!')
          .toString(),
    );
  }
}
