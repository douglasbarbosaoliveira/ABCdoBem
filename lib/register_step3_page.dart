// lib/register_step3_page.dart

import 'package:flutter/material.dart';

import 'volunteer_homepage.dart';
import 'models/voluntario_cadastro_dto.dart';
import 'services/auth_service.dart';

class RegisterStep3Page extends StatefulWidget {
  final Map<String, String> dadosBasicos; // Textos da Etapa 1
  final List<String> habilidadesSelecionadas; // Habilidades da Etapa 2

  const RegisterStep3Page({
    super.key,
    required this.dadosBasicos,
    required this.habilidadesSelecionadas,
  });

  @override
  State<RegisterStep3Page> createState() => _RegisterStep3PageState();
}

class _RegisterStep3PageState extends State<RegisterStep3Page> {
  final AuthService _authService = AuthService();

  // Opções de disponibilidade e formato
  final List<String> _opcoesDisponibilidade = [
    "Manhã",
    "Tarde",
    "Noite",
    "Dia inteiro",
    "Voluntariado presencial",
    "Voluntariado remoto",
    "Voluntariado em eventos",
    "Segunda-feira",
    "Terça-feira",
    "Quarta-feira",
    "Quinta-feira",
    "Sexta-feira",
    "Sábado",
    "Domingo",
    "Disponibilidade para emergências",
  ];

  final Set<String> _disponibilidadeSelecionada = {};
  bool _aceiteTermos = false;
  bool _aceiteLgpd = false;
  bool _enviando = false;

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem, textAlign: TextAlign.center),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _mostrarTermos() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Termos e Condições - ABC do Bem",
          style: TextStyle(
            color: Color(0xFF0C6B6B),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const SingleChildScrollView(
          child: Text(
            "1. Natureza do Serviço\n"
            "O ABC do Bem é uma plataforma facilitadora que conecta voluntários a Organizações Não Governamentais (ONGs). O cadastro e a atuação não geram qualquer vínculo empregatício, trabalhista ou previdenciário com a plataforma ou com as instituições.\n\n"
            "2. Idade Mínima e Autorização\n"
            "O cadastro na plataforma é permitido para pessoas a partir de 12 anos de idade. No entanto, voluntários menores de 18 anos precisarão obrigatoriamente da autorização e consentimento expresso de um dos pais ou responsável legal para confirmar presença e participar das ações e eventos divulgados.\n\n"
            "3. Conduta e Ambiente Seguro\n"
            "O ABC do Bem preza por um ambiente acolhedor. Não será tolerada nenhuma forma de discriminação, assédio, preconceito ou comportamento inadequado. Violações a esta regra resultarão no banimento imediato da plataforma.\n\n"
            "4. Privacidade e LGPD\n"
            "Em conformidade com a Lei Geral de Proteção de Dados (Lei nº 13.709/2018), seus dados pessoais serão armazenados com segurança e utilizados exclusivamente para conectá-lo às ONGs. Você pode solicitar a exclusão da sua conta a qualquer momento.\n\n"
            "5. Responsabilidades e Direitos de Imagem\n"
            "A plataforma atua apenas como intermediadora. O alinhamento de expectativas, regras de segurança e eventuais autorizações de uso de imagem (para fotos das ações) devem ser acordados diretamente entre o voluntário (ou seus responsáveis) e a ONG organizadora.\n\n"
            "6. Veracidade das Informações\n"
            "O usuário declara que todas as informações prestadas são verdadeiras, sob pena de exclusão da plataforma.",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF062222),
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Fechar",
              style: TextStyle(
                color: Color(0xFF0C6B6B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _concluirCadastro() async {
    if (_disponibilidadeSelecionada.isEmpty) {
      _mostrarErro(
        "Por favor, selecione pelo menos uma opção de disponibilidade.",
      );
      return;
    }

    setState(() => _enviando = true);

    final dto = VoluntarioCadastroDTO.deEtapas(
      dadosBasicos: widget.dadosBasicos,
      habilidades: widget.habilidadesSelecionadas,
      disponibilidade: _disponibilidadeSelecionada.toList(),
      termosAceitos: _aceiteTermos,
      lgpdAceita: _aceiteLgpd,
    );

    try {
      final resposta = await _authService.cadastrarVoluntario(dto);

      if (!mounted) return;
      setState(() => _enviando = false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Bem-vindo ao ABC do Bem! 🎉",
            style: TextStyle(
              color: Color(0xFF0C6B6B),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "${resposta.mensagem}\nExplore as oportunidades e comece a impactar o Grande ABC!",
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF3A6868),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                // Redireciona diretamente para a tela inicial do voluntário autenticado
                Navigator.pushAndRemoveUntil(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, a1, a2) =>
                        VoluntarioHomePage(voluntarioId: resposta.voluntarioId),
                    transitionDuration: Duration.zero,
                  ),
                  (route) => false,
                );
              },
              child: const Text(
                "Acessar Plataforma",
                style: TextStyle(
                  color: Color(0xFF0C6B6B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      _mostrarErro("Falha ao salvar seu perfil. Tente novamente.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final String nomeExibicao = (widget.dadosBasicos['nome'] ?? '').isEmpty
        ? "NOME NÃO INFORMADO"
        : widget.dadosBasicos['nome']!.toUpperCase();

    final String cidadeExibicao = (widget.dadosBasicos['cidade'] ?? '').isEmpty
        ? "Cidade não informada"
        : "${widget.dadosBasicos['cidade']}, ${widget.dadosBasicos['estado'] ?? 'SP'}";

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Quicksand'),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0FAF7),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // --- TOPO COM GRADIENTE E PASSOS ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF062222),
                      Color(0xFF0C5252),
                      Color(0xFF1A8F8F),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextButton.icon(
                            onPressed: _enviando
                                ? null
                                : () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xFF9FE8D8),
                              size: 20,
                            ),
                            label: const Text(
                              "Voltar",
                              style: TextStyle(
                                color: Color(0xFF9FE8D8),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "CADASTRO",
                            style: TextStyle(
                              color: Color(0xFF9FE8D8),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Sou Voluntário",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Crie seu perfil e comece a impactar",
                            style: TextStyle(
                              color: Color(0xFF9FE8D8),
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Row(
                            children: [
                              _buildStepItem(
                                "✓",
                                "Dados pessoais",
                                true,
                                isCompleted: true,
                              ),
                              _buildStepDivider(true),
                              _buildStepItem(
                                "✓",
                                "Habilidades",
                                true,
                                isCompleted: true,
                              ),
                              _buildStepDivider(true),
                              _buildStepItem("3", "Disponibilidade", true),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // --- CORPO DA ETAPA 3 ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 48,
                  horizontal: 20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Disponibilidade e perfil",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF062222),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Selecione as formas de atuação que melhor combinam com a sua rotina",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF3A6868),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Chips de Disponibilidade
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFC2E4DC)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _opcoesDisponibilidade.map((opcao) {
                              final bool selecionada =
                                  _disponibilidadeSelecionada.contains(opcao);
                              return FilterChip(
                                label: Text(opcao),
                                selected: selecionada,
                                selectedColor: const Color(0xFFD1F5EE),
                                checkmarkColor: const Color(0xFF0C6B6B),
                                labelStyle: TextStyle(
                                  color: selecionada
                                      ? const Color(0xFF0C6B6B)
                                      : const Color(0xFF062222),
                                  fontWeight: selecionada
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                backgroundColor: const Color(0xFFF0FAF7),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: selecionada
                                        ? const Color(0xFF0C6B6B)
                                        : const Color(0xFFC2E4DC),
                                  ),
                                ),
                                onSelected: _enviando
                                    ? null
                                    : (bool value) {
                                        setState(() {
                                          if (value) {
                                            _disponibilidadeSelecionada.add(
                                              opcao,
                                            );
                                          } else {
                                            _disponibilidadeSelecionada.remove(
                                              opcao,
                                            );
                                          }
                                        });
                                      },
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Resumo do Perfil (Etapas 1 e 2)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFC2E4DC)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Resumo do perfil",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                nomeExibicao,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF062222),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                cidadeExibicao,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF3A6868),
                                ),
                              ),
                              const SizedBox(height: 16),
                              widget.habilidadesSelecionadas.isEmpty
                                  ? const Text(
                                      "Nenhuma habilidade selecionada.",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    )
                                  : Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: widget.habilidadesSelecionadas
                                          .map((hab) {
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE3F5F1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFFC2E4DC,
                                                  ),
                                                ),
                                              ),
                                              child: Text(
                                                hab,
                                                style: const TextStyle(
                                                  color: Color(0xFF0C6B6B),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            );
                                          })
                                          .toList(),
                                    ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Termos de Uso e LGPD
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F5F1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFC2E4DC)),
                          ),
                          child: Column(
                            children: [
                              CheckboxListTile(
                                value: _aceiteTermos,
                                onChanged: _enviando
                                    ? null
                                    : (val) => setState(
                                        () => _aceiteTermos = val ?? false,
                                      ),
                                title: Row(
                                  children: [
                                    const Text(
                                      "Li e concordo com os ",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF062222),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _mostrarTermos,
                                      child: const Text(
                                        "Termos de Uso.",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                activeColor: const Color(0xFF0C6B6B),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                              ),
                              const Divider(color: Color(0xFFC2E4DC)),
                              CheckboxListTile(
                                value: _aceiteLgpd,
                                onChanged: _enviando
                                    ? null
                                    : (val) => setState(
                                        () => _aceiteLgpd = val ?? false,
                                      ),
                                title: const Text(
                                  "Autorizo o tratamento dos meus dados pessoais em conformidade com a Lei Geral de Proteção de Dados (LGPD) para fins de conexão com ONGs.",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF062222),
                                  ),
                                ),
                                activeColor: const Color(0xFF0C6B6B),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Botões de Ação
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _enviando
                                    ? null
                                    : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFF0C6B6B),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  "← Voltar",
                                  style: TextStyle(
                                    color: Color(0xFF0C6B6B),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    (_aceiteTermos && _aceiteLgpd && !_enviando)
                                    ? _concluirCadastro
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0C6B6B),
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: _enviando
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        "Criar Perfil ✓",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(
    String number,
    String label,
    bool isActive, {
    bool isCompleted = false,
  }) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted || isActive
                ? Colors.white
                : Colors.white.withOpacity(0.2),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: isCompleted || isActive
                    ? const Color(0xFF062222)
                    : Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(bool isPassed) {
    return Expanded(
      child: Container(
        height: 2,
        color: isPassed ? Colors.white : Colors.white.withOpacity(0.2),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      ),
    );
  }
}
