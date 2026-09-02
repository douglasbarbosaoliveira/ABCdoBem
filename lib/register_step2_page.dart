import 'package:flutter/material.dart';

import 'register_step3_page.dart'; // Importe a próxima página do cadastro

class RegisterStep2Page extends StatefulWidget {
  final Map<String, String>
  dadosBasicos; // 1. Criamos o espaço para receber a mala da Etapa 1

  const RegisterStep2Page({
    super.key,
    required this.dadosBasicos, // 2. Tornamos obrigatório receber isso ao abrir a tela
  });

  @override
  State<RegisterStep2Page> createState() => _RegisterStep2PageState();
}

class _RegisterStep2PageState extends State<RegisterStep2Page> {
  // Estrutura de categorias ordenadas alfabeticamente com tecnologia atualizada
  final Map<String, List<String>> _categoriasHabilidades = {
    "🧠 Habilidades pessoais": [
      "Liderança",
      "Trabalho em equipe",
      "Comunicação",
      "Organização",
      "Empatia",
      "Proatividade",
      "Criatividade",
      "Resolução de problemas",
      "Flexibilidade",
      "Responsabilidade",
      "Paciência",
      "Adaptabilidade",
      "Escuta ativa",
    ],
    "📊 Administração e gestão": [
      "Administração",
      "Gestão de projetos",
      "Gestão de pessoas",
      "Recursos humanos",
      "Finanças",
      "Contabilidade",
      "Planejamento",
      "Organização",
      "Compras",
      "Gestão de documentos",
      "Processos administrativos",
    ],
    "🌱 Agricultura e Meio Ambiente": [
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
    "🍳 Alimentação e hospitalidade": [
      "Cozinha",
      "Panificação e confeitaria",
      "Alimentação",
      "Atendimento",
      "Recepção",
      "Hotelaria",
      "Limpeza",
      "Organização de espaços",
      "Hospedagem",
    ],
    "🐶 Animais e cuidados veterinários": [
      "Veterinária",
      "Cuidados com animais",
      "Adestramento",
      "Resgate animal",
      "Abrigos e proteção animal",
      "Transporte de animais",
      "Adoção e divulgação",
    ],
    "📋 Apoio geral": [
      "Organização",
      "Limpeza",
      "Apoio operacional",
      "Separação e distribuição de doações",
      "Atendimento",
      "Eventos",
      "Cadastro e documentação",
      "Pesquisa",
      "Divulgação",
      "Apoio em atividades",
      "Trabalho manual",
      "Serviços gerais",
    ],
    "🎨 Artes e cultura": [
      "Artes visuais",
      "Música",
      "Teatro",
      "Dança",
      "Artesanato",
      "Fotografia",
      "Audiovisual",
      "Escrita",
      "Produção cultural",
      "Atividades criativas",
    ],
    "💰 Captação de recursos": [
      "Captação de doações",
      "Fundraising",
      "Elaboração de projetos",
      "Editais",
      "Patrocínios",
      "Parcerias",
      "Eventos beneficentes",
      "Campanhas de arrecadação",
      "Vendas",
    ],
    "🗣️ Comunicação e idiomas": [
      "Inglês",
      "Espanhol",
      "Tradução e interpretação",
      "Comunicação",
      "Oratória",
      "Escrita",
      "Jornalismo",
      "Atendimento ao público",
      "Mediação",
    ],
    "🔨 Construção e manutenção": [
      "Pedreiro",
      "Elétrica",
      "Hidráulica",
      "Pintura",
      "Marcenaria",
      "Serralheria",
      "Manutenção geral",
      "Jardinagem",
      "Reparos e instalações",
    ],
    "👩‍🏫 Educação": [
      "Ensino",
      "Reforço escolar",
      "Alfabetização",
      "Idiomas",
      "Matemática e ciências",
      "Informática e tecnologia",
      "Artes",
      "Esportes",
      "Mentoria",
      "Orientação profissional",
      "Capacitação e treinamento",
    ],
    "⚖️ Jurídico e documentação": [
      "Direito",
      "Orientação jurídica",
      "Contratos",
      "Documentação",
      "Regularização",
      "Mediação",
      "Proteção de dados",
      "Compliance",
    ],
    "📣 Marketing e comunicação digital": [
      "Marketing",
      "Redes sociais",
      "Criação de conteúdo",
      "Publicidade",
      "Comunicação institucional",
      "Relações públicas",
      "Fotografia",
      "Vídeo e audiovisual",
      "Design gráfico",
    ],
    "🧑‍⚕️ Saúde e bem-estar": [
      "Medicina",
      "Enfermagem",
      "Odontologia",
      "Psicologia",
      "Fisioterapia",
      "Nutrição",
      "Terapias",
      "Educação física",
      "Primeiros socorros",
      "Cuidados e bem-estar",
    ],
    "💻 Tecnologia": [
      "Desenvolvimento de software",
      "Desenvolvimento web",
      "Desenvolvimento de aplicativos",
      "Tecnologia da informação",
      "Suporte técnico",
      "Dados e análise",
      "Automação",
      "Inteligência artificial",
      "Informática",
      "Design digital",
    ],
    "🤝 Trabalho social e comunitário": [
      "Assistência social",
      "Trabalho comunitário",
      "Acolhimento",
      "Apoio a famílias",
      "Trabalho com crianças",
      "Trabalho com jovens",
      "Trabalho com idosos",
      "Inclusão social",
      "Inclusão de pessoas com deficiência",
      "Mobilização comunitária",
      "Mentoria",
    ],
    "🚗 Transporte e logística": [
      "Transporte",
      "Motorista",
      "Entregas",
      "Logística",
      "Estoque",
      "Distribuição",
      "Organização de materiais",
      "Carga e descarga",
      "Manutenção de veículos",
      "Apoio em eventos",
    ],
  };

  // Conjunto para armazenar quais habilidades o usuário selecionou
  final Set<String> _habilidadesSelecionadas = {};

  // Função para mostrar erro na tela (a trava!)
  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem, textAlign: TextAlign.center),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Quicksand'),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0FAF7),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // --- TOPO ESCURO COM O INDICADOR DE PASSOS (ETAPA 2 ATIVA) ---
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
                            onPressed: () => Navigator.pop(context),
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

                          // --- INDICADOR DE PASSOS ---
                          Row(
                            children: [
                              _buildStepItem(
                                "✓",
                                "Dados pessoais",
                                true,
                                isCompleted: true,
                              ),
                              _buildStepDivider(true),
                              _buildStepItem("2", "Habilidades", true),
                              _buildStepDivider(false),
                              _buildStepItem("3", "Disponibilidade", false),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // --- CORPO DA PÁGINA (LISTA DE HABILIDADES ORDENADA) ---
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
                          "Suas habilidades",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF062222),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Selecione todas as competências que você deseja disponibilizar para a rede",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF3A6868),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Renderiza dinamicamente cada categoria em ordem alfabética
                        ..._categoriasHabilidades.entries.map((entry) {
                          String categoria = entry.key;
                          List<String> itens = entry.value;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFC2E4DC),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ExpansionTile(
                              title: Text(
                                categoria,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF062222),
                                  fontSize: 16,
                                ),
                              ),
                              childrenPadding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                16,
                              ),
                              collapsedIconColor: const Color(0xFF0C6B6B),
                              iconColor: const Color(0xFF0C6B6B),
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: itens.map((habilidade) {
                                      bool selecionada =
                                          _habilidadesSelecionadas.contains(
                                            habilidade,
                                          );
                                      return FilterChip(
                                        label: Text(habilidade),
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
                                        backgroundColor: const Color(
                                          0xFFF0FAF7,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          side: BorderSide(
                                            color: selecionada
                                                ? const Color(0xFF0C6B6B)
                                                : const Color(0xFFC2E4DC),
                                          ),
                                        ),
                                        onSelected: (bool value) {
                                          setState(() {
                                            if (value) {
                                              _habilidadesSelecionadas.add(
                                                habilidade,
                                              );
                                            } else {
                                              _habilidadesSelecionadas.remove(
                                                habilidade,
                                              );
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 32),

                        // --- BOTÕES DE NAVEGAÇÃO INFERIORES ---
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
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
                                onPressed: () {
                                  if (_habilidadesSelecionadas.isEmpty) {
                                    _mostrarErro(
                                      "Por favor, selecione pelo menos uma habilidade.",
                                    );
                                    return; // Interrompe o processo e não avança de tela!
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RegisterStep3Page(
                                        dadosBasicos: widget.dadosBasicos, // 1. Repassa a maleta da Etapa 1 pra frente
                                        habilidadesSelecionadas:
                                            _habilidadesSelecionadas.toList(), // 2. Envia as habilidades escolhidas aqui
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8CD4C7),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  "Continuar →",
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
