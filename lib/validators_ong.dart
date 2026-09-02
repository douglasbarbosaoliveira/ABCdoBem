class AppValidators {
  static String? validarObrigatorio(String valor) {
    return valor.trim().isEmpty ? "Este campo é obrigatório." : null;
  }

  static String? validarCnpj(String cnpj) {
    if (cnpj.trim().isEmpty) return "O CNPJ é obrigatório.";
    String numeros = cnpj.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeros.length != 14) return "CNPJ incompleto.";
    if (RegExp(r'^(\d)\1*$').hasMatch(numeros)) return "CNPJ inválido.";

    List<int> digitos = numeros
        .split('')
        .map((String d) => int.parse(d))
        .toList();
    int calcularDigito(int n, List<int> pesos) {
      int soma = 0;
      for (int i = 0; i < n; i++) soma += digitos[i] * pesos[i];
      int resto = soma % 11;
      return resto < 2 ? 0 : 11 - resto;
    }

    List<int> pesos1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    List<int> pesos2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    if (digitos[12] != calcularDigito(12, pesos1)) return "CNPJ inválido.";
    if (digitos[13] != calcularDigito(13, pesos2)) return "CNPJ inválido.";
    return null;
  }

  static String? validarAno(String anoStr) {
    if (anoStr.trim().isEmpty) return "O ano é obrigatório.";
    if (anoStr.length != 4) return "Deve conter 4 dígitos.";
    int? ano = int.tryParse(anoStr);
    if (ano == null) return "Ano inválido.";
    if (ano > DateTime.now().year) return "O ano não pode estar no futuro.";
    if (ano < 1800) return "Ano irreal.";
    return null;
  }

  static String? validarSite(String site) {
    if (site.trim().isEmpty) return null; // Opcional
    final siteRegex = RegExp(
      r"^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$",
    );
    if (!siteRegex.hasMatch(site)) return "Formato de site inválido.";
    return null;
  }

  static String? validarTelefone(String telefone) {
    if (telefone.trim().isEmpty) return "O telefone é obrigatório.";
    if (telefone.length < 14) return "Telefone incompleto.";
    return null;
  }

  static String? validarWhatsapp(String whatsapp) {
    if (whatsapp.trim().isEmpty) return "O WhatsApp é obrigatório.";
    // MUDANÇA AQUI: Agora aceita 14 (8 dígitos) ou 15 caracteres (9 dígitos)!
    if (whatsapp.length < 14) return "WhatsApp incompleto.";
    return null;
  }

  static String? validarCep(String cep) {
    if (cep.trim().isEmpty) return "O CEP é obrigatório.";
    if (cep.length < 9) return "CEP incompleto.";
    return null;
  }
}
