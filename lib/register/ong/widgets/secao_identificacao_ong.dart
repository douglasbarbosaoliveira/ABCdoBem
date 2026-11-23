// lib/register/ong/widgets/secao_identificacao_ong.dart

import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'campo_texto_ong.dart';

class SecaoIdentificacaoOng extends StatelessWidget {
  final TextEditingController razaoSocialCtrl;
  final TextEditingController nomeFantasiaCtrl;
  final TextEditingController cnpjCtrl;
  final TextEditingController anoFundacaoCtrl;
  final TextEditingController siteCtrl;

  final FocusNode razaoSocialFocus;
  final FocusNode nomeFantasiaFocus;
  final FocusNode cnpjFocus;
  final FocusNode anoFocus;
  final FocusNode siteFocus;

  final String? erroRazaoSocial;
  final String? erroNomeFantasia;
  final String? erroCnpj;
  final String? erroAno;
  final String? erroSite;

  final MaskTextInputFormatter cnpjMask;
  final bool isMobile;
  final bool dadosBloqueados;
  final VoidCallback? onDestravarDados;

  const SecaoIdentificacaoOng({
    super.key,
    required this.razaoSocialCtrl,
    required this.nomeFantasiaCtrl,
    required this.cnpjCtrl,
    required this.anoFundacaoCtrl,
    required this.siteCtrl,
    required this.razaoSocialFocus,
    required this.nomeFantasiaFocus,
    required this.cnpjFocus,
    required this.anoFocus,
    required this.siteFocus,
    required this.erroRazaoSocial,
    required this.erroNomeFantasia,
    required this.erroCnpj,
    required this.erroAno,
    required this.erroSite,
    required this.cnpjMask,
    required this.isMobile,
    this.dadosBloqueados = false,
    this.onDestravarDados,
  });

  Widget _envolverSeBloqueado(
      {required bool bloqueado, required Widget child}) {
    if (!bloqueado) return child;
    return IgnorePointer(
      ignoring: true,
      child: Opacity(
        opacity: 0.72,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Identificação da ONG",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF062222),
              ),
            ),
            if (dadosBloqueados && onDestravarDados != null)
              TextButton.icon(
                onPressed: onDestravarDados,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 14,
                  color: Color(0xFF0C6B6B),
                ),
                label: const Text(
                  "Editar dados",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0C6B6B),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // 1º: CNPJ NO TOPO
        CampoTextoOng(
          label: "CNPJ",
          hint: "00.000.000/0000-00",
          obrigatorio: true,
          keyboardType: TextInputType.number,
          controller: cnpjCtrl,
          formatters: [cnpjMask],
          focusNode: cnpjFocus,
          errorText: erroCnpj,
        ),
        const SizedBox(height: 12),

        // 2º: RAZÃO SOCIAL (Bloqueada visualmente e contra toque se importada)
        _envolverSeBloqueado(
          bloqueado: dadosBloqueados,
          child: CampoTextoOng(
            label: dadosBloqueados ? "Razão Social" : "Razão Social",
            hint: "Ex: Associação ABC do Bem",
            obrigatorio: true,
            controller: razaoSocialCtrl,
            focusNode: razaoSocialFocus,
            errorText: erroRazaoSocial,
          ),
        ),
        const SizedBox(height: 12),

        // 3º: NOME FANTASIA (Sempre liberado para edição)
        CampoTextoOng(
          label: "Nome Fantasia",
          hint: "Ex: ABC do Bem",
          obrigatorio: true,
          controller: nomeFantasiaCtrl,
          focusNode: nomeFantasiaFocus,
          errorText: erroNomeFantasia,
        ),
        const SizedBox(height: 12),

        // 4º e 5º: ANO DE FUNDAÇÃO E SITE (Responsivo: Coluna no mobile / Linha no desktop)
        if (isMobile) ...[
          _envolverSeBloqueado(
            bloqueado: dadosBloqueados,
            child: CampoTextoOng(
              label: dadosBloqueados ? "Ano de Fundação" : "Ano de Fundação",
              hint: "Ex: 2015",
              obrigatorio: true,
              keyboardType: TextInputType.number,
              controller: anoFundacaoCtrl,
              maxLength: 4,
              focusNode: anoFocus,
              errorText: erroAno,
            ),
          ),
          const SizedBox(height: 12),
          CampoTextoOng(
            label: "Site",
            hint: "www.suaong.org.br",
            obrigatorio: false,
            keyboardType: TextInputType.url,
            controller: siteCtrl,
            focusNode: siteFocus,
            errorText: erroSite,
          ),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: _envolverSeBloqueado(
                  bloqueado: dadosBloqueados,
                  child: CampoTextoOng(
                    label: dadosBloqueados
                        ? "Ano de Fundação (Oficial)"
                        : "Ano de Fundação",
                    hint: "Ex: 2015",
                    obrigatorio: true,
                    keyboardType: TextInputType.number,
                    controller: anoFundacaoCtrl,
                    maxLength: 4,
                    focusNode: anoFocus,
                    errorText: erroAno,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: CampoTextoOng(
                  label: "Site",
                  hint: "www.suaong.org.br",
                  obrigatorio: false,
                  keyboardType: TextInputType.url,
                  controller: siteCtrl,
                  focusNode: siteFocus,
                  errorText: erroSite,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
