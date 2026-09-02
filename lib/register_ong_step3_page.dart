import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import 'legal_popups.dart';
import 'models/ong_cadastro_dto.dart';
import 'services/ong_auth_service.dart';

// import 'landing_page.dart';

class RegisterOngStep3Page extends StatefulWidget {
  final Map<String, dynamic> dadosCompletos;

  const RegisterOngStep3Page({super.key, required this.dadosCompletos});

  @override
  State<RegisterOngStep3Page> createState() => _RegisterOngStep3PageState();
}

class _RegisterOngStep3PageState extends State<RegisterOngStep3Page> {
  final OngAuthService _ongAuthService = OngAuthService();

  // --- CONTROLADORES DE CONTA ---
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController =
      TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  String? _erroEmail;

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  // Variáveis da Senha Forte
  bool _temMinimo = false;
  bool _temMaiuscula = false;
  bool _temMinuscula = false;
  bool _temEspecial = false;
  bool _senhasIguais = false;

  // Variáveis Legais (Termos e LGPD)
  bool _aceitouTermos = false;
  bool _aceitouLGPD = false;

  // Estado de Carregamento (Spinner do botão final)
  bool _isCarregando = false;

  // --- SELEÇÕES DA ONG ---
  String? _formatoVoluntariado;
  final List<String> _opcoesFormato = [
    "Apenas Presencial",
    "Apenas Remoto (Online)",
    "Híbrido (Presencial e Remoto)",
  ];

  final Set<String> _habilidadesSelecionadas = {};

  // --- A MÁGICA ACONTECE AQUI: O Dicionário de Habilidades e Doações por Causa ---
  final Map<String, List<String>> _habilidadesPorCausaOng = {
    "🤝 Apoio humanitário": [
      "Apoio operacional",
      "Escuta ativa",
      "Tradução e interpretação",
      "Primeiros socorros",
      "Empatia",
      "Responsabilidade",
      "Organização",
    ],
    "🫂 Assistência social": [
      "Atendimento",
      "Apoio a famílias",
      "Apoio operacional",
      "Separação e distribuição de doações",
      "Cadastro e documentação",
      "Assistência social",
      "Escuta ativa",
      "Empatia",
    ],
    "💻 Ciência e tecnologia": [
      "Informática e tecnologia",
      "Desenvolvimento de software",
      "Desenvolvimento web",
      "Desenvolvimento de aplicativos",
      "Tecnologia da informação",
      "Suporte técnico",
      "Inteligência artificial",
    ],
    "🍲 Combate à pobreza": [
      "Cozinha",
      "Panificação e confeitaria",
      "Logística",
      "Distribuição",
      "Estoque",
      "Separação e distribuição de doações",
      "Trabalho manual",
    ],
    "🧒 Crianças e adolescentes": [
      "Reforço escolar",
      "Alfabetização",
      "Artes",
      "Esportes",
      "Teatro",
      "Música",
      "Mentoria",
      "Trabalho com crianças",
      "Paciência",
    ],
    "🎨 Cultura": [
      "Artes visuais",
      "Música",
      "Teatro",
      "Dança",
      "Artesanato",
      "Fotografia",
      "Audiovisual",
      "Escrita",
      "Produção cultural",
      "Criatividade",
    ],
    "🏘️ Desenvolvimento comunitário": [
      "Trabalho comunitário",
      "Mobilização comunitária",
      "Gestão de projetos",
      "Planejamento",
      "Educação ambiental",
      "Comunicação",
      "Liderança",
    ],
    "⚖️ Direitos humanos": [
      "Direito",
      "Orientação jurídica",
      "Mediação",
      "Proteção de dados",
      "Compliance",
      "Comunicação",
      "Empatia",
    ],
    "📚 Educação": [
      "Ensino",
      "Reforço escolar",
      "Alfabetização",
      "Idiomas",
      "Matemática e ciências",
      "Capacitação e treinamento",
      "Mentoria",
      "Organização",
    ],
    "💼 Emprego e capacitação profissional": [
      "Capacitação e treinamento",
      "Orientação profissional",
      "Recursos humanos",
      "Administração",
      "Planejamento",
      "Comunicação",
      "Oratória",
    ],
    "⚽ Esporte": [
      "Esportes",
      "Educação física",
      "Eventos",
      "Organização",
      "Trabalho em equipe",
      "Liderança",
    ],
    "🏠 Habitação": [
      "Pedreiro",
      "Elétrica",
      "Hidráulica",
      "Pintura",
      "Marcenaria",
      "Serralheria",
      "Manutenção geral",
      "Reparos e instalações",
    ],
    "👴 Idosos": [
      "Trabalho com idosos",
      "Cuidados e bem-estar",
      "Fisioterapia",
      "Enfermagem",
      "Paciência",
      "Empatia",
      "Acolhimento",
    ],
    "🤝 Inclusão social": [
      "Inclusão social",
      "Inclusão de pessoas com deficiência",
      "Acolhimento",
      "Assistência social",
      "Escuta ativa",
      "Empatia",
      "Flexibilidade",
    ],
    "🌱 Meio ambiente": [
      "Agricultura",
      "Jardinagem",
      "Agroecologia",
      "Permacultura",
      "Reciclagem",
      "Gestão de resíduos",
      "Reflorestamento",
      "Conservação ambiental",
      "Educação ambiental",
    ],
    "👩 Mulheres": [
      "Acolhimento",
      "Psicologia",
      "Orientação jurídica",
      "Assistência social",
      "Escuta ativa",
      "Empatia",
      "Comunicação",
    ],
    "♿ Pessoas com deficiência": [
      "Inclusão de pessoas com deficiência",
      "Fisioterapia",
      "Terapias",
      "Psicologia",
      "Acolhimento",
      "Paciência",
      "Empatia",
    ],
    "🐾 Proteção animal": [
      "Veterinária",
      "Cuidados com animais",
      "Adestramento",
      "Resgate animal",
      "Abrigos e proteção animal",
      "Transporte de animais",
      "Adoção e divulgação",
    ],
    "🏥 Saúde": [
      "Medicina",
      "Enfermagem",
      "Odontologia",
      "Psicologia",
      "Nutrição",
      "Primeiros socorros",
      "Cuidados e bem-estar",
      "Responsabilidade",
    ],
    "🍽️ Segurança alimentar": [
      "Cozinha",
      "Nutrição",
      "Logística",
      "Distribuição",
      "Estoque",
      "Separação e distribuição de doações",
      "Organização",
    ],
  };

  final Set<String> _doacoesSelecionadas = {};

  final Map<String, List<String>> _doacoesPorCausaOng = {
    "🤝 Apoio humanitário": [
      "Alimentos não perecíveis",
      "Água potável",
      "Kits de higiene pessoal e limpeza",
      "Roupas, cobertores e calçados",
      "Doações Financeiras (Pix/Conta)",
      "Outros",
    ],
    "🫂 Assistência social": [
      "Alimentos não perecíveis",
      "Roupas, calçados e enxovais",
      "Produtos de higiene e limpeza",
      "Brinquedos",
      "Doações Financeiras (Pix/Conta)",
      "Outros",
    ],
    "💻 Ciência e tecnologia": [
      "Equipamentos Eletrônicos (PCs, Celulares, Tablets)",
      "Peças de hardware",
      "Periféricos",
      "Doações Financeiras (Pix/Conta)",
      "Outros",
    ],
    "🍲 Combate à pobreza": [
      "Alimentos não perecíveis",
      "Alimentos perecíveis",
      "Roupas e Calçados",
      "Produtos de Higiene Pessoal",
      "Doações Financeiras (Pix/Conta)",
      "Outros",
    ],
    "🧒 Crianças e adolescentes": [
      "Material Escolar",
      "Livros infantis",
      "Brinquedos",
      "Roupas e Calçados",
      "Doações Financeiras (Pix/Conta)",
      "Outros",
    ],
    "🎨 Cultura": [
      "Instrumentos musicais",
      "Livros",
      "Equipamentos Eletrônicos (Som, Luz, Foto)",
      "Material Escolar/Artesanato",
      "Doações Financeiras (Pix/Conta)",
      "Outros",
    ],
    "🏘️ Desenvolvimento comunitário": [
      "Materiais de Construção",
      "Móveis e Eletrodomésticos",
      "Equipamentos Eletrônicos",
      "Produtos de Limpeza",
      "Doações Financeiras (Pix/Conta)",
      "Outros",
    ],
    "⚖️ Direitos humanos": [
      "Material Escolar/Escritório",
      "Equipamentos Eletrônicos (PCs, Celulares)",
      "Doações Financeiras (Pix/Conta)",
      "Outros",
    ],
    "📚 Educação": [
      "Material Escolar",
      "Livros didáticos",
      "Equipamentos Eletrônicos",
      "Móveis e Eletrodomésticos",
      "Doações Financeiras (Pix/Conta)",
      "Outros",
    ],
    "💼 Emprego e capacitação profissional": [
      "Material Escolar/Escritório",
      "Roupas e Calçados (Vestuário profissional)",
      "Equipamentos Eletrônicos",
      "Doações Financeiras (Pix/Conta)",
      "Outros",
    ],
    "⚽ Esporte": [
      "Material esportivo (Bolas, Redes)",
      "Roupas e Calçados (Chuteiras, Tênis)",
      "Troféus e medalhas",
      "Doações Financeiras (Pix/Conta)",
      "Outros",
    ],
    "🏠 Habitação": [
      "Materiais de Construção",
      "Móveis e Eletrodomésticos",
      "Ferramentas",
      "Doações Financeiras (Pix/Conta)",
      "Outros",
    ],
    "👴 Idosos": [
      "Fraldas geriátricas",
      "Produtos de Higiene Pessoal",
      "Medicamentos",
      "Alimentos não perecíveis",
      "Doações Financeiras (Pix/Conta)",
      "Outros",
    ],
    "🤝 Inclusão social": [
      "Roupas e Calçados",
      "Produtos de Higiene Pessoal",
      "Alimentos não perecíveis",
      "Doações Financeiras (Pix/Conta)",
      "Outros",
    ],
    "🌱 Meio Ambiente": [
      "Mudas e sementes",
      "Ferramentas de jardinagem",
      "Materiais recicláveis",
      "Doações Financeiras (Pix/Conta)",
      "Outros",
    ],
    "👩 Mulheres": [
      "Produtos de Higiene Pessoal (Absorventes)",
      "Roupas e Calçados",
      "Alimentos não perecíveis",
      "Doações Financeiras (Pix/Conta)",
      "Outros",
    ],
    "♿ Pessoas com deficiência": [
      "Equipamentos de mobilidade (Cadeiras de rodas)",
      "Tecnologia assistiva",
      "Medicamentos",
      "Doações Financeiras (Pix/Conta)",
      "Outros",
    ],
    "🐾 Proteção animal": [
      "Ração e Itens Pet",
      "Medicamentos veterinários",
      "Produtos de Limpeza",
      "Caminhas e cobertores",
      "Doações Financeiras (Pix/Conta)",
      "Outros",
    ],
    "🏥 Saúde": [
      "Medicamentos",
      "Insumos hospitalares",
      "Produtos de Higiene Pessoal",
      "Fraldas",
      "Doações Financeiras (Pix/Conta)",
      "Outros",
    ],
    "🍽️ Segurança alimentar": [
      "Alimentos perecíveis",
      "Alimentos não perecíveis",
      "Utensílios de cozinha",
      "Produtos de Limpeza",
      "Doações Financeiras (Pix/Conta)",
      "Outros",
    ],
  };

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus && _emailController.text.isNotEmpty) {
        setState(() {
          final emailRegex = RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
          );
          _erroEmail = emailRegex.hasMatch(_emailController.text)
              ? null
              : "E-mail inválido.";
        });
      }
    });
  }

  void _mostrarErro(String mensagem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF062222),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "OK",
                style: TextStyle(
                  color: Color(0xFF0C6B6B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarSucesso(String emailCadastrado) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.mark_email_read_rounded,
              color: Color(0xFF0C6B6B),
              size: 64,
            ),
            const SizedBox(height: 24),
            const Text(
              "Quase lá!",
              style: TextStyle(
                fontSize: 24,
                color: Color(0xFF062222),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF3A6868),
                  fontFamily: 'Quicksand',
                ),
                children: [
                  const TextSpan(
                    text: "Enviamos um e-mail de confirmação para\n",
                  ),
                  TextSpan(
                    text: emailCadastrado,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF062222),
                    ),
                  ),
                  const TextSpan(
                    text: ".\n\nPor favor, clique no link enviado para ativar a conta da sua ONG e começar a acessar a plataforma!",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C6B6B),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Entendi",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String causaPrincipal =
        widget.dadosCompletos['causa_principal'] ?? "Outros";

    final List<String> listaHabilidadesExibir =
        _habilidadesPorCausaOng.containsKey(causaPrincipal)
        ? _habilidadesPorCausaOng[causaPrincipal]!
        : ["Atendimento", "Organização", "Apoio operacional", "Outros"];

    final List<String> listaDoacoesExibir =
        _doacoesPorCausaOng.containsKey(causaPrincipal)
        ? _doacoesPorCausaOng[causaPrincipal]!
        : ["Doações Financeiras (Pix/Conta)", "Outros"];

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Quicksand'),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0FAF7),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // --- TOPO ESCURO ---
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
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextButton.icon(
                            onPressed: _isCarregando
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
                            "CADASTRO ONG",
                            style: TextStyle(
                              color: Color(0xFF9FE8D8),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Necessidades",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Mostre aos voluntários como eles podem ajudar",
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
                                "Dados Gerais",
                                true,
                                isCompleted: true,
                              ),
                              _buildStepDivider(),
                              _buildStepItem(
                                "✓",
                                "Detalhes",
                                true,
                                isCompleted: true,
                              ),
                              _buildStepDivider(),
                              _buildStepItem("3", "Finalizar", true),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // --- FORMULÁRIO ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 48,
                  horizontal: 20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "O que vocês estão buscando?",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF062222),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Com base na causa ($causaPrincipal), selecione o que a ONG precisa.",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // --- HABILIDADES BUSCADAS (FILTRADAS) ---
                        const Text(
                          "Habilidades Voluntárias Buscadas",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF062222),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: listaHabilidadesExibir.map((habilidade) {
                            bool selecionado = _habilidadesSelecionadas
                                .contains(habilidade);
                            return _buildChip(habilidade, selecionado, (value) {
                              setState(() {
                                value
                                    ? _habilidadesSelecionadas.add(habilidade)
                                    : _habilidadesSelecionadas.remove(
                                        habilidade,
                                      );
                              });
                            });
                          }).toList(),
                        ),
                        const SizedBox(height: 32),

                        // --- FORMA DE ATUAÇÃO ---
                        const Text(
                          "Formato de Voluntariado Aceito",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF062222),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFC2E4DC)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              hint: const Text(
                                "Ex: Apenas Presencial",
                                style: TextStyle(color: Colors.grey),
                              ),
                              value: _formatoVoluntariado,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Color(0xFF0C6B6B),
                              ),
                              items: _opcoesFormato.map((String formato) {
                                return DropdownMenuItem<String>(
                                  value: formato,
                                  child: Text(formato),
                                );
                              }).toList(),
                              onChanged: (novoValor) => setState(
                                () => _formatoVoluntariado = novoValor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // --- DOAÇÕES (FILTRADAS) ---
                        const Text(
                          "A ONG aceita doações de:",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF062222),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: listaDoacoesExibir.map((doacao) {
                            bool selecionado = _doacoesSelecionadas.contains(
                              doacao,
                            );
                            return _buildChip(doacao, selecionado, (value) {
                              setState(() {
                                value
                                    ? _doacoesSelecionadas.add(doacao)
                                    : _doacoesSelecionadas.remove(doacao);
                              });
                            });
                          }).toList(),
                        ),
                        const SizedBox(height: 48),

                        // --- CRIAR CONTA DE ACESSO ---
                        const Divider(color: Color(0xFFC2E4DC)),
                        const SizedBox(height: 32),
                        const Text(
                          "Criar Conta de Acesso",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF062222),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Este será o login para a ONG acessar a plataforma.",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 24),

                        _buildTextField(
                          "E-mail Institucional",
                          "ong@email.com",
                          keyboardType: TextInputType.emailAddress,
                          controller: _emailController,
                          focusNode: _emailFocus,
                          errorText: _erroEmail,
                        ),
                        const SizedBox(height: 16),

                        _buildPasswordField(
                          "Senha",
                          "Crie uma senha forte",
                          obscurePassword,
                          (val) => setState(() => obscurePassword = val),
                          controller: _senhaController,
                          onChanged: (val) {
                            setState(() {
                              _temMinimo = val.length >= 8;
                              _temMaiuscula = val.contains(RegExp(r'[A-Z]'));
                              _temMinuscula = val.contains(RegExp(r'[a-z]'));
                              _temEspecial = val.contains(RegExp(r'[\W_]'));
                              _senhasIguais =
                                  (val == _confirmarSenhaController.text) &&
                                  val.isNotEmpty;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildRequisito("Mínimo de 8 caracteres", _temMinimo),
                        _buildRequisito(
                          "Pelo menos 1 letra maiúscula",
                          _temMaiuscula,
                        ),
                        _buildRequisito(
                          "Pelo menos 1 letra minúscula",
                          _temMinuscula,
                        ),
                        _buildRequisito(
                          "Pelo menos 1 caractere especial (@, #, !, etc)",
                          _temEspecial,
                        ),
                        const SizedBox(height: 16),

                        _buildPasswordField(
                          "Confirmar senha",
                          "Digite a senha novamente",
                          obscureConfirmPassword,
                          (val) => setState(() => obscureConfirmPassword = val),
                          controller: _confirmarSenhaController,
                          onChanged: (val) {
                            setState(() {
                              _senhasIguais =
                                  (val == _senhaController.text) &&
                                  val.isNotEmpty;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildRequisito("As senhas coincidem", _senhasIguais),
                        const SizedBox(height: 32),

                        // --- CHECKBOXES DE TERMOS E LGPD ---
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFC2E4DC)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _aceitouTermos,
                                      activeColor: const Color(0xFF0C6B6B),
                                      onChanged: (val) => setState(
                                        () => _aceitouTermos = val ?? false,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          color: Color(0xFF062222),
                                          fontSize: 13,
                                          fontFamily: 'Quicksand',
                                        ),
                                        children: [
                                          const TextSpan(
                                            text: "Declaro que li e concordo com os ",
                                          ),
                                          TextSpan(
                                            text: "Termos e Condições de Uso",
                                            style: const TextStyle(
                                              color: Color(0xFF0C6B6B),
                                              fontWeight: FontWeight.bold,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                LegalPopups.mostrarTermosOng(
                                                  context,
                                                );
                                              },
                                          ),
                                          const TextSpan(
                                            text: " da plataforma ABC do Bem.",
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _aceitouLGPD,
                                      activeColor: const Color(0xFF0C6B6B),
                                      onChanged: (val) => setState(
                                        () => _aceitouLGPD = val ?? false,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          color: Color(0xFF062222),
                                          fontSize: 13,
                                          fontFamily: 'Quicksand',
                                        ),
                                        children: [
                                          const TextSpan(
                                            text: "Concordo com a ",
                                          ),
                                          TextSpan(
                                            text: "Política de Privacidade e Tratamento de Dados (LGPD)",
                                            style: const TextStyle(
                                              color: Color(0xFF0C6B6B),
                                              fontWeight: FontWeight.bold,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                LegalPopups.mostrarLGPD(
                                                  context,
                                                );
                                              },
                                          ),
                                          const TextSpan(
                                            text: ", autorizando a exibição pública do perfil da ONG para fins de engajamento social.",
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),

                        // --- BOTÃO FINALIZAR ---
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isCarregando
                                    ? null
                                    : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
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
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _isCarregando
                                    ? null
                                    : () async {
                                        // Trava de Erros Visuais
                                        if (_erroEmail != null) {
                                          _mostrarErro(
                                            "Verifique o campo de E-mail antes de finalizar.",
                                          );
                                          return;
                                        }

                                        // Travas de Negócio
                                        if (_habilidadesSelecionadas.isEmpty) {
                                          _mostrarErro(
                                            "Selecione pelo menos uma habilidade que vocês buscam em voluntários.",
                                          );
                                          return;
                                        }
                                        if (_formatoVoluntariado == null) {
                                          _mostrarErro(
                                            "Por favor, informe o formato de voluntariado aceito.",
                                          );
                                          return;
                                        }
                                        if (_emailController.text
                                            .trim()
                                            .isEmpty) {
                                          _mostrarErro(
                                            "O E-mail institucional é obrigatório para criar a conta.",
                                          );
                                          return;
                                        }
                                        if (!_temMinimo ||
                                            !_temMaiuscula ||
                                            !_temMinuscula ||
                                            !_temEspecial) {
                                          _mostrarErro(
                                            "A senha não atende a todos os requisitos de segurança visualizados no checklist.",
                                          );
                                          return;
                                        }
                                        if (!_senhasIguais) {
                                          _mostrarErro(
                                            "A confirmação da senha está diferente. Por favor, verifique.",
                                          );
                                          return;
                                        }

                                        // TRAVA DE POLÍTICAS DE USO (LGPD)
                                        if (!_aceitouTermos || !_aceitouLGPD) {
                                          _mostrarErro(
                                            "Para concluir o cadastro, você deve ler e aceitar os Termos de Uso e a Política de Privacidade.",
                                          );
                                          return;
                                        }

                                        setState(() {
                                          _isCarregando = true;
                                        });

                                        final dto = OngCadastroDTO(
                                          dadosCompletosEtapasAnteriores:
                                              widget.dadosCompletos,
                                          habilidadesBuscadas:
                                              _habilidadesSelecionadas.toList(),
                                          doacoesAceitas: _doacoesSelecionadas
                                              .toList(),
                                          formatoVoluntariado:
                                              _formatoVoluntariado!,
                                          emailLogin: _emailController.text
                                              .trim(),
                                          senhaLogin: _senhaController.text,
                                          termosAceitos: _aceitouTermos,
                                          lgpdAceita: _aceitouLGPD,
                                        );

                                        try {
                                          final resposta = await _ongAuthService
                                              .cadastrarOng(dto);

                                          if (!mounted) return;
                                          setState(() {
                                            _isCarregando = false;
                                          });

                                          _mostrarSucesso(resposta.email);
                                        } catch (e) {
                                          if (!mounted) return;
                                          setState(() {
                                            _isCarregando = false;
                                          });
                                          _mostrarErro(
                                            "Falha ao realizar o cadastro no servidor. Tente novamente.",
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0C6B6B),
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isCarregando
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        "Finalizar Cadastro ✓",
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

  // --- MÉTODOS AUXILIARES UI ---
  Widget _buildChip(String label, bool isSelected, Function(bool) onSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFFD1F5EE),
      checkmarkColor: const Color(0xFF0C6B6B),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF0C6B6B) : const Color(0xFF062222),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? const Color(0xFF0C6B6B) : const Color(0xFFC2E4DC),
        ),
      ),
      onSelected: onSelected,
    );
  }

  Widget _buildRequisito(String texto, bool atendido) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            atendido ? Icons.check_circle : Icons.radio_button_unchecked,
            color: atendido ? Colors.green : Colors.grey.shade400,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              color: atendido ? Colors.green : Colors.grey.shade600,
              fontWeight: atendido ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint, {
    TextInputType? keyboardType,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF062222),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            errorText: errorText,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFC2E4DC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0C6B6B), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(
    String label,
    String hint,
    bool obscure,
    Function(bool) onToggle, {
    TextEditingController? controller,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF062222),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFC2E4DC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0C6B6B), width: 2),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF3A6868),
              ),
              onPressed: () => onToggle(!obscure),
            ),
          ),
        ),
      ],
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
            color: isActive || isCompleted
                ? Colors.white
                : Colors.white.withOpacity(0.7),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider() {
    return Expanded(
      child: Container(
        height: 2,
        color: Colors.white.withOpacity(0.2),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      ),
    );
  }
}
