import 'package:flutter/material.dart';

import 'register_ong_step3_page.dart';

// import 'register_ong_step3_page.dart';

class RegisterOngStep2Page extends StatefulWidget {
  final Map<String, dynamic> dadosOng; // Recebe os dados da Etapa 1

  const RegisterOngStep2Page({super.key, required this.dadosOng});

  @override
  State<RegisterOngStep2Page> createState() => _RegisterOngStep2PageState();
}

class _RegisterOngStep2PageState extends State<RegisterOngStep2Page> {
  // --- CONTROLADORES ---
  final TextEditingController _descricaoController = TextEditingController();
  int _tamanhoDescricao = 0;
  bool _logoAdicionado = false;

  // --- VARIÁVEIS DE ESTADO ---
  String? _causaPrincipalSelecionada;
  final Set<String> _oferecimentosSelecionados = {};
  final Set<String> _publicoSelecionado = {};

  // --- 1. A LISTA DE CAUSAS PRINCIPAIS ---
  final List<String> _causas = [
    "🤝 Apoio humanitário",
    "🌾 Agricultura e desenvolvimento rural",
    "🫂 Assistência social",
    "💻 Ciência e tecnologia",
    "🍲 Combate à pobreza",
    "🧒 Crianças e adolescentes",
    "🎨 Cultura e artes",
    "🏘️ Desenvolvimento comunitário",
    "🏳️‍⚧️ Diversidade e inclusão",
    "🧑‍🌾 Economia solidária e empreendedorismo",
    "🚨 Emergências e desastres",
    "💼 Emprego e capacitação profissional",
    "⚽ Esporte e lazer",
    "👨‍👩‍👧‍👦 Família e parentalidade",
    "🧑🏿‍🤝‍🧑🏽 Igualdade racial",
    "🤝 Inclusão social",
    "⚖️ Justiça e cidadania",
    "🌱 Meio ambiente e sustentabilidade",
    "👩 Mulheres",
    "🪶 Povos indígenas e comunidades tradicionais",
    "♿ Pessoas com deficiência",
    "🐾 Proteção animal",
    "🏥 Saúde",
    "🧠 Saúde mental e bem-estar",
    "🍽️ Segurança alimentar",
  ];

  // --- 2. O CÉREBRO DOS SERVIÇOS (Filtro Dinâmico A -> B) ---
  final Map<String, List<String>> _mapaOferecimentos = {
    "🤝 Apoio humanitário": [
      "Distribuição de água e alimentos",
      "Distribuição de roupas e itens essenciais",
      "Acolhimento e triagem",
      "Logística de suprimentos",
      "Arrecadação de doações",
      "Organização de campanhas",
      "Montagem de kits de emergência",
      "Transporte de doações",
      "Apoio em abrigos",
      "Apoio psicológico pós-trauma",
      "Primeiros socorros",
      "Busca e resgate",
      "Apoio a pessoas desalojadas",
      "Apoio a pessoas desabrigadas",
      "Tradução e interpretação",
      "Apoio a imigrantes e refugiados",
      "Reconstrução após desastres",
      "Apoio em situações de emergência",
    ],

    "🫂 Assistência social": [
      "Visitas domiciliares",
      "Acompanhamento de famílias",
      "Distribuição de cestas básicas",
      "Distribuição de roupas",
      "Distribuição de itens de higiene",
      "Geração de renda familiar",
      "Orientação sobre benefícios sociais",
      "Encaminhamento para serviços públicos",
      "Apoio na obtenção de documentos",
      "Acompanhamento a serviços públicos",
      "Acompanhamento de mães solo",
      "Apoio a famílias vulneráveis",
      "Atendimento e escuta social",
      "Campanhas de arrecadação",
      "Organização de bazares solidários",
      "Doação de materiais",
      "Apoio administrativo",
    ],

    "💻 Ciência e tecnologia": [
      "Letramento digital",
      "Inclusão digital",
      "Manutenção de computadores",
      "Configuração de celulares e computadores",
      "Instalação de softwares",
      "Suporte técnico para ONGs",
      "Desenvolvimento de sites",
      "Desenvolvimento de aplicativos",
      "Capacitação tecnológica",
      "Automação de processos",
      "Produção de conteúdo digital",
      "Marketing digital",
      "Robótica",
      "Eletrônica",
      "Oficinas de tecnologia",
      "Prevenção de crimes digitais",
      "Prevenção de fraudes online",
    ],

    "🍲 Combate à pobreza": [
      "Resgate de alimentos",
      "Preparo de marmitas",
      "Distribuição de alimentos",
      "Bancos de alimentos",
      "Aproveitamento integral de alimentos",
      "Hortas comunitárias",
      "Capacitação profissional",
      "Geração de renda",
      "Empreendedorismo",
      "Doação de roupas",
      "Doação de itens de higiene",
      "Campanhas de arrecadação",
      "Bazar solidário",
      "Apoio emergencial",
      "Educação financeira",
      "Orientação para acesso a benefícios",
    ],

    "🧒 Crianças e adolescentes": [
      "Reforço escolar",
      "Alfabetização",
      "Oficinas de arte",
      "Oficinas de música",
      "Oficinas de leitura",
      "Oficinas de tecnologia",
      "Recreação",
      "Atividades esportivas",
      "Contação de histórias",
      "Mentoria",
      "Orientação profissional",
      "Apoio à permanência escolar",
      "Combate à evasão escolar",
      "Acompanhamento educacional",
      "Apoio psicológico",
      "Apoio às famílias",
      "Atividades culturais",
      "Passeios e atividades externas",
      "Doação de materiais escolares",
      "Doação de brinquedos",
      "Campanhas de arrecadação",
      "Proteção contra violência e abuso",
      "Prevenção da gravidez na adolescência",
      "Educação sobre consentimento e limites",
      "Prevenção da violência sexual",
      "Orientação sobre relacionamentos saudáveis",
      "Apoio a crianças em situação de abandono",
      "Apoio a famílias acolhedoras",
      "Preparação para adoção",
      "Apadrinhamento afetivo",
    ],

    "🎨 Cultura e artes": [
      "Oficinas de artes visuais",
      "Oficinas de desenho",
      "Oficinas de pintura",
      "Oficinas de fotografia",
      "Oficinas de dança",
      "Oficinas de teatro",
      "Oficinas de música",
      "Oficinas de literatura",
      "Oficinas de artesanato",
      "Oficinas de cinema",
      "Produção cultural",
      "Organização de eventos culturais",
      "Preservação de acervos",
      "Digitalização de acervos",
      "Bibliotecas comunitárias",
      "Mediação de leitura",
      "Patrimônio histórico",
      "Memória comunitária",
      "Cultura popular",
      "Grafite e arte urbana",
    ],

    "🏘️ Desenvolvimento comunitário": [
      "Revitalização de espaços públicos",
      "Revitalização de espaços comunitários",
      "Hortas comunitárias",
      "Criação e manutenção de praças",
      "Gestão de resíduos",
      "Reciclagem",
      "Educação ambiental",
      "Mutirões comunitários",
      "Pintura e manutenção",
      "Pequenos reparos",
      "Jardinagem",
      "Paisagismo",
      "Organização comunitária",
      "Formação de lideranças",
      "Mobilização comunitária",
      "Mapeamento de necessidades",
      "Desenvolvimento de projetos sociais",
      "Captação de recursos",
    ],

    "⚖️ Direitos humanos": [
      "Assistência jurídica gratuita",
      "Orientação sobre direitos",
      "Educação em direitos",
      "Combate à discriminação",
      "Combate ao preconceito",
      "Defesa de minorias",
      "Apoio a vítimas de violência",
      "Apoio a vítimas de violações de direitos",
      "Acompanhamento social",
      "Documentação e cidadania",
      "Defesa dos direitos das crianças",
      "Defesa dos direitos das mulheres",
      "Defesa dos direitos LGBTQIA+",
      "Defesa dos direitos de povos indígenas",
      "Defesa dos direitos de pessoas com deficiência",
      "Defesa dos direitos de pessoas privadas de liberdade",
      "Campanhas de conscientização",
    ],

    "📚 Educação": [
      "Alfabetização",
      "Educação de jovens e adultos (EJA)",
      "Reforço escolar",
      "Aulas de idiomas",
      "Aulas de matemática",
      "Aulas de português",
      "Aulas de ciências",
      "Preparação para ENEM",
      "Preparação para vestibular",
      "Orientação para acesso à universidade",
      "Mentoria acadêmica",
      "Capacitação pedagógica",
      "Formação de professores",
      "Educação financeira",
      "Educação digital",
      "Educação ambiental",
      "Educação profissional",
      "Doação de livros",
      "Doação de material escolar",
      "Bibliotecas comunitárias",
      "Clubes de leitura",
    ],

    "💼 Emprego e capacitação profissional": [
      "Elaboração de currículos",
      "Preparação para entrevistas",
      "Mentoria de carreira",
      "Orientação profissional",
      "Cursos profissionalizantes",
      "Capacitação técnica",
      "Oficinas de empreendedorismo",
      "Empreendedorismo feminino",
      "Educação financeira",
      "Orientação para MEI",
      "Orientação para pequenos negócios",
      "Capacitação digital",
      "Marketing e vendas",
      "Contabilidade voluntária",
      "Consultoria empresarial",
      "Mentoria para empreendedores",
      "Networking profissional",
      "Encaminhamento para vagas",
      "Recolocação profissional",
      "Inclusão no mercado de trabalho",
    ],

    "⚽ Esporte e lazer": [
      "Treinamento esportivo",
      "Iniciação esportiva",
      "Futebol",
      "Vôlei",
      "Basquete",
      "Atletismo",
      "Artes marciais",
      "Dança",
      "Ciclismo",
      "Caminhadas",
      "Atividades recreativas",
      "Campeonatos e torneios",
      "Organização de eventos esportivos",
      "Doação de materiais esportivos",
      "Manutenção de espaços esportivos",
      "Esporte adaptado",
      "Lazer comunitário",
      "Promoção da saúde através do esporte",
    ],

    "🏠 Habitação": [
      "Reformas e melhorias",
      "Pintura",
      "Pequenos reparos",
      "Instalações elétricas",
      "Instalações hidráulicas",
      "Construção",
      "Mutirões de construção",
      "Arquitetura popular",
      "Engenharia voluntária",
      "Projetos de acessibilidade",
      "Regularização fundiária",
      "Orientação habitacional",
      "Saneamento básico",
      "Instalação de equipamentos",
      "Captação de água da chuva",
      "Melhorias de eficiência energética",
    ],

    "👴 Idosos": [
      "Visitas e companhia",
      "Combate ao isolamento social",
      "Acompanhamento em consultas",
      "Acompanhamento em atividades externas",
      "Auxílio com tecnologia",
      "Alfabetização digital",
      "Oficinas cognitivas",
      "Atividades físicas",
      "Atividades recreativas",
      "Oficinas de artes",
      "Oficinas de música",
      "Oficinas de memória",
      "Rodas de conversa",
      "Apoio em atividades cotidianas",
      "Apoio a cuidadores",
      "Doação de medicamentos e itens de saúde",
    ],

    "🤝 Inclusão social": [
      "Acolhimento",
      "Escuta e acompanhamento",
      "Reintegração social",
      "Apoio a pessoas em situação de rua",
      "Apoio a egressos do sistema prisional",
      "Apoio a pessoas em recuperação",
      "Rodas de conversa",
      "Resgate da autoestima",
      "Capacitação profissional",
      "Inclusão no mercado de trabalho",
      "Atividades culturais",
      "Atividades esportivas",
      "Apoio à documentação",
      "Orientação sobre serviços públicos",
      "Mediação comunitária",
    ],

    "🌱 Meio ambiente e sustentabilidade": [
      "Plantio de árvores",
      "Reflorestamento",
      "Recuperação de áreas degradadas",
      "Limpeza de rios",
      "Limpeza de praias",
      "Limpeza de parques e praças",
      "Educação ambiental",
      "Reciclagem",
      "Coleta seletiva",
      "Compostagem",
      "Hortas comunitárias",
      "Jardinagem comunitária",
      "Resgate de fauna",
      "Resgate de flora",
      "Monitoramento ambiental",
      "Preservação de nascentes",
      "Conservação de florestas",
      "Combate às queimadas",
      "Proteção da biodiversidade",
      "Proteção da fauna",
      "Proteção da flora",
      "Agricultura sustentável",
      "Agroecologia",
      "Permacultura",
      "Economia circular",
      "Redução de resíduos",
      "Reutilização de materiais",
      "Consumo consciente",
      "Combate ao desperdício",
      "Mudanças climáticas",
      "Energias renováveis",
      "Eficiência energética",
      "Uso consciente da água",
      "Captação de água da chuva",
      "Campanhas de conscientização",
    ],

    "👩 Mulheres": [
      "Apoio a vítimas de violência",
      "Acolhimento",
      "Acompanhamento social",
      "Apoio psicológico",
      "Apoio jurídico",
      "Empreendedorismo feminino",
      "Capacitação profissional",
      "Geração de renda",
      "Educação financeira",
      "Saúde da mulher",
      "Apoio durante a gestação",
      "Apoio à maternidade",
      "Apoio a mães solo",
      "Prevenção da violência",
      "Defesa de direitos",
      "Oficinas de autoestima",
    ],

    "♿ Pessoas com deficiência": [
      "Acessibilidade física",
      "Adaptação de espaços",
      "Tecnologia assistiva",
      "Libras",
      "Audiodescrição",
      "Legendagem",
      "Apoio à comunicação",
      "Esporte adaptado",
      "Atividades culturais inclusivas",
      "Inclusão educacional",
      "Inclusão profissional",
      "Capacitação profissional",
      "Apoio às famílias",
      "Acompanhamento social",
      "Mobilidade e transporte",
      "Doação de equipamentos",
      "Conscientização sobre acessibilidade",
    ],

    "🐾 Proteção animal": [
      "Resgate de animais",
      "Lar temporário",
      "Adoção responsável",
      "Feiras de adoção",
      "Arrecadação de ração",
      "Doação de medicamentos",
      "Castração",
      "Transporte de animais",
      "Passeio com animais",
      "Banho e cuidados",
      "Fotografia para adoção",
      "Divulgação de animais",
      "Atendimento veterinário voluntário",
      "Educação sobre posse responsável",
      "Combate aos maus-tratos",
      "Resgate de animais silvestres",
      "Limpeza e manutenção de abrigos",
    ],

    "🏥 Saúde": [
      "Prevenção de doenças",
      "Educação em saúde",
      "Campanhas de vacinação",
      "Campanhas de doação de sangue",
      "Apoio em hospitais",
      "Acompanhamento de pacientes",
      "Acompanhamento em consultas",
      "Atendimento médico voluntário",
      "Atendimento odontológico voluntário",
      "Atendimento psicológico voluntário",
      "Fisioterapia voluntária",
      "Enfermagem voluntária",
      "Nutrição voluntária",
      "Arrecadação de medicamentos",
      "Doação de equipamentos",
      "Doação de sangue",
      "Apoio a pacientes crônicos",
      "Apoio a cuidadores",
      "Campanhas de conscientização",
      "Visitas lúdicas a hospitais",
      "Atividades recreativas em hospitais",
      "Contação de histórias em hospitais",
      "Entretenimento para pacientes",
      "Apoio emocional a pacientes",
      "Recreação para crianças hospitalizadas",
      "Humanização do atendimento em saúde",
    ],

    "🍽️ Segurança alimentar": [
      "Resgate de alimentos",
      "Preparo de refeições",
      "Distribuição de refeições",
      "Distribuição de cestas básicas",
      "Bancos de alimentos",
      "Arrecadação de alimentos",
      "Logística de alimentos",
      "Cozinha comunitária",
      "Cozinha solidária",
      "Hortas comunitárias",
      "Agricultura familiar",
      "Educação nutricional",
      "Orientação nutricional",
      "Aproveitamento integral de alimentos",
      "Combate ao desperdício",
    ],

    "🌾 Agricultura e desenvolvimento rural": [
      "Agricultura familiar",
      "Hortas comunitárias",
      "Agroecologia",
      "Permacultura",
      "Capacitação de agricultores",
      "Assistência técnica",
      "Comercialização de produtos",
      "Economia solidária",
      "Irrigação",
      "Recuperação de solos",
      "Preservação de sementes",
      "Educação ambiental",
      "Segurança alimentar",
    ],

    "🧠 Saúde mental e bem-estar": [
      "Escuta e acolhimento",
      "Rodas de conversa",
      "Apoio psicológico",
      "Psicologia voluntária",
      "Prevenção ao suicídio",
      "Prevenção ao uso problemático de substâncias",
      "Grupos de apoio",
      "Atividades de bem-estar",
      "Meditação e relaxamento",
      "Atividades físicas",
      "Arteterapia",
      "Apoio a familiares e cuidadores",
      "Campanhas de conscientização",
    ],

    "👨‍👩‍👧‍👦 Família e parentalidade": [
      "Apoio a famílias",
      "Apoio a mães e pais",
      "Apoio a mães solo",
      "Orientação parental",
      "Oficinas de parentalidade",
      "Apoio durante a gestação",
      "Apoio no pós-parto",
      "Atividades para famílias",
      "Educação financeira familiar",
      "Apoio psicossocial",
    ],

    "🌎 Migração e refúgio": [
      "Acolhimento",
      "Tradução e interpretação",
      "Ensino de português",
      "Orientação documental",
      "Orientação jurídica",
      "Inserção profissional",
      "Capacitação profissional",
      "Apoio psicológico",
      "Apoio habitacional",
      "Doação de itens essenciais",
      "Integração comunitária",
    ],

    "🧑🏿‍🤝‍🧑🏽 Igualdade racial": [
      "Combate ao racismo",
      "Educação antirracista",
      "Defesa de direitos",
      "Valorização da cultura afro-brasileira",
      "Capacitação profissional",
      "Empreendedorismo",
      "Apoio educacional",
      "Apoio jurídico",
      "Campanhas de conscientização",
    ],

    "🪶 Povos indígenas e comunidades tradicionais": [
      "Apoio comunitário",
      "Educação",
      "Saúde",
      "Segurança alimentar",
      "Preservação cultural",
      "Preservação ambiental",
      "Geração de renda",
      "Artesanato",
      "Defesa de direitos",
      "Apoio jurídico",
      "Capacitação",
    ],

    "🏳️‍⚧️ Diversidade e inclusão": [
      "Combate à discriminação",
      "Educação para diversidade",
      "Capacitação profissional",
      "Inclusão no trabalho",
      "Inclusão educacional",
      "Apoio psicossocial",
      "Rodas de conversa",
      "Campanhas de conscientização",
      "Acessibilidade",
    ],

    "⚖️ Justiça e cidadania": [
      "Orientação jurídica",
      "Assistência jurídica",
      "Educação em direitos",
      "Apoio documental",
      "Orientação sobre serviços públicos",
      "Acesso à justiça",
      "Mediação de conflitos",
      "Educação para cidadania",
      "Direitos do consumidor",
      "Direitos trabalhistas",
    ],

    "🕊️ Paz e prevenção de conflitos": [
      "Mediação de conflitos",
      "Cultura de paz",
      "Educação para paz",
      "Rodas de diálogo",
      "Prevenção da violência",
      "Mediação comunitária",
      "Convivência comunitária",
      "Campanhas de conscientização",
    ],

    "🚨 Emergências e desastres": [
      "Apoio em enchentes",
      "Apoio em deslizamentos",
      "Apoio em incêndios",
      "Apoio em secas",
      "Distribuição de água",
      "Distribuição de alimentos",
      "Apoio em abrigos",
      "Arrecadação de doações",
      "Triagem de doações",
      "Logística",
      "Transporte",
      "Reconstrução",
      "Limpeza e recuperação de áreas",
    ],

    "🧑‍🌾 Economia solidária e empreendedorismo": [
      "Empreendedorismo",
      "Cooperativismo",
      "Economia solidária",
      "Capacitação profissional",
      "Educação financeira",
      "Mentoria empresarial",
      "Marketing",
      "Vendas",
      "Contabilidade",
      "Gestão financeira",
      "Gestão de negócios",
      "Artesanato",
      "Geração de renda",
      "Feiras e eventos",
    ],
  };

  // --- 3. O CÉREBRO DO PÚBLICO (Filtro Dinâmico A -> C) ---
  final Map<String, List<String>> _mapaPublico = {
    "🤝 Apoio humanitário": [
      "👶 Bebês (0 a 2 anos)",
      "🧒 Crianças (3 a 11 anos)",
      "🧑‍🎓 Adolescentes (12 a 17 anos)",
      "🎓 Jovens (18 a 24 anos)",
      "🧑 Adultos (25 a 59 anos)",
      "👴 Idosos (60 anos ou mais)",
      "👨‍👩‍👧‍👦 Famílias",
      "🏠 Pessoas em situação de rua",
      "💰 Pessoas em situação de pobreza",
      "🫂 Pessoas em situação de vulnerabilidade",
      "🏚️ Pessoas desalojadas",
      "🏚️ Pessoas desabrigadas",
      "🌎 Imigrantes",
      "🛂 Refugiados",
      "🚨 Pessoas afetadas por desastres",
      "👥 Comunidade em geral",
      "Outros",
    ],

    "🫂 Assistência social": [
      "👶 Bebês (0 a 2 anos)",
      "🧒 Crianças (3 a 11 anos)",
      "🧑‍🎓 Adolescentes (12 a 17 anos)",
      "🎓 Jovens (18 a 24 anos)",
      "🧑 Adultos (25 a 59 anos)",
      "👴 Idosos (60 anos ou mais)",
      "👨‍👩‍👧‍👦 Famílias",
      "👩 Mães solo",
      "🤰 Gestantes",
      "💰 Pessoas em situação de pobreza",
      "🏠 Pessoas em situação de rua",
      "🫂 Pessoas em situação de vulnerabilidade",
      "♿ Pessoas com deficiência",
      "🌎 Imigrantes",
      "🛂 Refugiados",
      "💼 Pessoas desempregadas",
      "Outros",
    ],

    "💻 Ciência e tecnologia": [
      "🧑‍🎓 Adolescentes (12 a 17 anos)",
      "🎓 Jovens (18 a 24 anos)",
      "🧑 Adultos (25 a 59 anos)",
      "👴 Idosos (60 anos ou mais)",
      "🎓 Estudantes",
      "👩‍🏫 Professores e educadores",
      "♿ Pessoas com deficiência",
      "🫂 Pessoas em situação de vulnerabilidade",
      "💼 Empreendedores",
      "🏢 Organizações sociais",
      "👥 Comunidade em geral",
      "Outros",
    ],

    "🍲 Combate à pobreza": [
      "👶 Bebês (0 a 2 anos)",
      "🧒 Crianças (3 a 11 anos)",
      "🧑‍🎓 Adolescentes (12 a 17 anos)",
      "🎓 Jovens (18 a 24 anos)",
      "🧑 Adultos (25 a 59 anos)",
      "👴 Idosos (60 anos ou mais)",
      "👨‍👩‍👧‍👦 Famílias",
      "👩 Mães solo",
      "💰 Pessoas em situação de pobreza",
      "🏠 Pessoas em situação de rua",
      "💼 Pessoas desempregadas",
      "🫂 Pessoas em situação de vulnerabilidade",
      "🌾 Comunidades rurais",
      "🪶 Comunidades tradicionais",
      "Outros",
    ],

    "🧒 Crianças e adolescentes": [
      "👶 Bebês (0 a 2 anos)",
      "🧒 Crianças (3 a 11 anos)",
      "🧑‍🎓 Adolescentes (12 a 17 anos)",
      "👨‍👩‍👧‍👦 Famílias",
      "👩 Mães solo",
      "♿ Crianças e adolescentes com deficiência",
      "💰 Crianças e adolescentes em situação de pobreza",
      "🫂 Crianças e adolescentes em situação de vulnerabilidade",
      "🌎 Imigrantes",
      "🛂 Refugiados",
      "Outros",
    ],

    "🎨 Cultura e artes": [
      "🧒 Crianças (3 a 11 anos)",
      "🧑‍🎓 Adolescentes (12 a 17 anos)",
      "🎓 Jovens (18 a 24 anos)",
      "🧑 Adultos (25 a 59 anos)",
      "👴 Idosos (60 anos ou mais)",
      "🎓 Estudantes",
      "🎭 Artistas",
      "👩‍🏫 Professores e educadores",
      "🪶 Comunidades tradicionais",
      "👥 Comunidade em geral",
      "Outros",
    ],

    "🏘️ Desenvolvimento comunitário": [
      "🧒 Crianças (5 a 11 anos)",
      "🧑‍🎓 Adolescentes (12 a 17 anos)",
      "🎓 Jovens (18 a 24 anos)",
      "🧑 Adultos (25 a 59 anos)",
      "👴 Idosos (60 anos ou mais)",
      "👨‍👩‍👧‍👦 Famílias",
      "👥 Comunidade em geral",
      "🏘️ Moradores de comunidades vulneráveis",
      "🌾 Comunidades rurais",
      "🪶 Comunidades tradicionais",
      "🤝 Lideranças comunitárias",
      "Outros",
    ],

    "⚖️ Direitos humanos": [
      "🧒 Crianças (0 a 11 anos)",
      "🧑‍🎓 Adolescentes (12 a 17 anos)",
      "🎓 Jovens (18 a 24 anos)",
      "🧑 Adultos (25 a 59 anos)",
      "👴 Idosos (60 anos ou mais)",
      "👩 Mulheres",
      "🏳️‍🌈 Pessoas LGBTQIA+",
      "♿ Pessoas com deficiência",
      "🧑🏿 Pessoas negras",
      "🪶 Povos indígenas",
      "🪶 Comunidades tradicionais",
      "🌎 Imigrantes",
      "🛂 Refugiados",
      "⚖️ Pessoas privadas de liberdade",
      "🔄 Egressos do sistema prisional",
      "🏠 Pessoas em situação de rua",
      "🫂 Pessoas em situação de vulnerabilidade",
      "Outros",
    ],

    "📚 Educação": [
      "👶 Bebês (0 a 2 anos)",
      "🧒 Crianças (3 a 11 anos)",
      "🧑‍🎓 Adolescentes (12 a 17 anos)",
      "🎓 Jovens (18 a 24 anos)",
      "🧑 Adultos (25 a 59 anos)",
      "👴 Idosos (60 anos ou mais)",
      "🎓 Estudantes",
      "👩‍🏫 Professores e educadores",
      "🌎 Imigrantes",
      "🛂 Refugiados",
      "♿ Pessoas com deficiência",
      "🫂 Pessoas em situação de vulnerabilidade",
      "Outros",
    ],

    "💼 Emprego e capacitação profissional": [
      "🧑‍🎓 Adolescentes (12 a 17 anos)",
      "🎓 Jovens (18 a 24 anos)",
      "🧑 Adultos (25 a 59 anos)",
      "👴 Idosos (60 anos ou mais)",
      "👩 Mulheres",
      "👩 Mães solo",
      "♿ Pessoas com deficiência",
      "💼 Pessoas desempregadas",
      "💰 Pessoas em situação de pobreza",
      "🌎 Imigrantes",
      "🛂 Refugiados",
      "🔄 Egressos do sistema prisional",
      "🫂 Pessoas em situação de vulnerabilidade",
      "🧑‍🌾 Agricultores familiares",
      "👨‍💼 Pequenos empreendedores",
      "Outros",
    ],

    "⚽ Esporte e lazer": [
      "🧒 Crianças (5 a 11 anos)",
      "🧑‍🎓 Adolescentes (12 a 17 anos)",
      "🎓 Jovens (18 a 24 anos)",
      "🧑 Adultos (25 a 59 anos)",
      "👴 Idosos (60 anos ou mais)",
      "♿ Pessoas com deficiência",
      "🫂 Pessoas em situação de vulnerabilidade",
      "👥 Comunidade em geral",
      "Outros",
    ],

    "🏠 Habitação": [
      "🧒 Crianças (0 a 11 anos)",
      "🧑‍🎓 Adolescentes (12 a 17 anos)",
      "🎓 Jovens (18 a 24 anos)",
      "🧑 Adultos (25 a 59 anos)",
      "👴 Idosos (60 anos ou mais)",
      "👨‍👩‍👧‍👦 Famílias",
      "👩 Mães solo",
      "♿ Pessoas com deficiência",
      "💰 Pessoas em situação de pobreza",
      "🏠 Pessoas em situação de rua",
      "🏚️ Pessoas desalojadas",
      "🏚️ Pessoas desabrigadas",
      "🏘️ Comunidades vulneráveis",
      "🌾 Comunidades rurais",
      "Outros",
    ],

    "👴 Idosos": [
      "👴 Idosos (60 anos ou mais)",
      "👴 Idosos em situação de vulnerabilidade",
      "👴 Idosos que vivem sozinhos",
      "👨‍👩‍👧‍👦 Famílias",
      "🧑‍🦽 Cuidadores e familiares",
      "Outros",
    ],

    "🤝 Inclusão social": [
      "🧒 Crianças (3 a 11 anos)",
      "🧑‍🎓 Adolescentes (12 a 17 anos)",
      "🎓 Jovens (18 a 24 anos)",
      "🧑 Adultos (25 a 59 anos)",
      "👴 Idosos (60 anos ou mais)",
      "🏠 Pessoas em situação de rua",
      "💰 Pessoas em situação de pobreza",
      "🫂 Pessoas em situação de vulnerabilidade",
      "♿ Pessoas com deficiência",
      "🏳️‍🌈 Pessoas LGBTQIA+",
      "🌎 Imigrantes",
      "🛂 Refugiados",
      "🔄 Egressos do sistema prisional",
      "🧑‍⚕️ Pessoas em recuperação de dependência",
      "💼 Pessoas desempregadas",
      "Outros",
    ],

    "🌱 Meio ambiente e sustentabilidade": [
      "🧒 Crianças (3 a 11 anos)",
      "🧑‍🎓 Adolescentes (12 a 17 anos)",
      "🎓 Jovens (18 a 24 anos)",
      "🧑 Adultos (25 a 59 anos)",
      "👴 Idosos (60 anos ou mais)",
      "👥 Comunidade em geral",
      "🌾 Comunidades rurais",
      "🪶 Povos indígenas",
      "🪶 Comunidades tradicionais",
      "🧑‍🌾 Agricultores",
      "👩‍🏫 Educadores",
      "Outros",
    ],

    "👩 Mulheres": [
      "🧑‍🎓 Adolescentes (12 a 17 anos)",
      "🎓 Jovens (18 a 24 anos)",
      "👩 Mulheres adultas (25 a 59 anos)",
      "👴 Mulheres idosas (60 anos ou mais)",
      "👩 Mães solo",
      "🤰 Gestantes",
      "🤱 Puérperas",
      "👩 Mulheres em situação de violência",
      "💰 Mulheres em situação de pobreza",
      "💼 Mulheres desempregadas",
      "👨‍👩‍👧‍👦 Famílias",
      "Outros",
    ],

    "♿ Pessoas com deficiência": [
      "👶 Bebês com deficiência (0 a 2 anos)",
      "🧒 Crianças com deficiência (3 a 11 anos)",
      "🧑‍🎓 Adolescentes com deficiência (12 a 17 anos)",
      "🎓 Jovens com deficiência (18 a 24 anos)",
      "🧑 Adultos com deficiência (25 a 59 anos)",
      "👴 Idosos com deficiência (60 anos ou mais)",
      "♿ Pessoas com deficiência",
      "👨‍👩‍👧‍👦 Famílias",
      "🧑‍🦽 Cuidadores",
      "👩‍🏫 Profissionais da área",
      "Outros",
    ],

    "🐾 Proteção animal": [
      "🐶 Cães",
      "🐱 Gatos",
      "🦜 Animais silvestres",
      "🐄 Animais de produção",
      "🐾 Animais abandonados",
      "🐾 Animais vítimas de maus-tratos",
      "❤️ Protetores de animais",
      "🏠 Abrigos e organizações de proteção animal",
      "👥 Comunidade em geral",
      "Outros",
    ],

    "🏥 Saúde": [
      "👶 Bebês (0 a 2 anos)",
      "🧒 Crianças (3 a 11 anos)",
      "🧑‍🎓 Adolescentes (12 a 17 anos)",
      "🎓 Jovens (18 a 24 anos)",
      "🧑 Adultos (25 a 59 anos)",
      "👴 Idosos (60 anos ou mais)",
      "👩 Mulheres",
      "🤰 Gestantes",
      "♿ Pessoas com deficiência",
      "🩺 Pessoas com doenças crônicas",
      "🏥 Pacientes",
      "👨‍👩‍👧‍👦 Familiares de pacientes",
      "🧑‍🦽 Cuidadores",
      "🫂 Pessoas em situação de vulnerabilidade",
      "👥 Comunidade em geral",
      "Outros",
    ],

    "🍽️ Segurança alimentar": [
      "👶 Bebês (0 a 2 anos)",
      "🧒 Crianças (3 a 11 anos)",
      "🧑‍🎓 Adolescentes (12 a 17 anos)",
      "🎓 Jovens (18 a 24 anos)",
      "🧑 Adultos (25 a 59 anos)",
      "👴 Idosos (60 anos ou mais)",
      "👨‍👩‍👧‍👦 Famílias",
      "👩 Mães solo",
      "🍽️ Pessoas em situação de fome",
      "💰 Pessoas em situação de pobreza",
      "🏠 Pessoas em situação de rua",
      "🫂 Pessoas em situação de vulnerabilidade",
      "🌾 Comunidades rurais",
      "🪶 Comunidades tradicionais",
      "Outros",
    ],

    "🌾 Agricultura e desenvolvimento rural": [
      "🧑‍🌾 Agricultores familiares",
      "🌾 Pequenos produtores",
      "🏘️ Comunidades rurais",
      "🪶 Povos indígenas",
      "🪶 Comunidades tradicionais",
      "👨‍👩‍👧‍👦 Famílias",
      "🎓 Jovens rurais",
      "👩 Mulheres rurais",
      "Outros",
    ],

    "🧠 Saúde mental e bem-estar": [
      "🧒 Crianças (3 a 11 anos)",
      "🧑‍🎓 Adolescentes (12 a 17 anos)",
      "🎓 Jovens (18 a 24 anos)",
      "🧑 Adultos (25 a 59 anos)",
      "👴 Idosos (60 anos ou mais)",
      "👨‍👩‍👧‍👦 Famílias",
      "👩 Mulheres",
      "🏠 Pessoas em situação de rua",
      "🫂 Pessoas em situação de vulnerabilidade",
      "🧑‍🦽 Cuidadores",
      "👥 Comunidade em geral",
      "Outros",
    ],

    "👨‍👩‍👧‍👦 Família e parentalidade": [
      "👶 Bebês (0 a 2 anos)",
      "🧒 Crianças (3 a 11 anos)",
      "🧑‍🎓 Adolescentes (12 a 17 anos)",
      "👨‍👩‍👧‍👦 Famílias",
      "👩 Mães",
      "👨 Pais",
      "👩 Mães solo",
      "🤰 Gestantes",
      "🤱 Puérperas",
      "🧑‍🦽 Cuidadores",
      "Outros",
    ],

    "🌎 Migração e refúgio": [
      "👶 Bebês (0 a 2 anos)",
      "🧒 Crianças (3 a 11 anos)",
      "🧑‍🎓 Adolescentes (12 a 17 anos)",
      "🎓 Jovens (18 a 24 anos)",
      "🧑 Adultos (25 a 59 anos)",
      "👴 Idosos (60 anos ou mais)",
      "🌎 Imigrantes",
      "🛂 Refugiados",
      "📄 Solicitantes de refúgio",
      "👨‍👩‍👧‍👦 Famílias migrantes",
      "👩 Mulheres migrantes",
      "🫂 Pessoas em situação de vulnerabilidade",
      "Outros",
    ],

    "🧑🏿‍🤝‍🧑🏽 Igualdade racial": [
      "👶 Bebês (0 a 2 anos)",
      "🧒 Crianças (3 a 11 anos)",
      "🧑‍🎓 Adolescentes (12 a 17 anos)",
      "🎓 Jovens (18 a 24 anos)",
      "🧑 Adultos (25 a 59 anos)",
      "👴 Idosos (60 anos ou mais)",
      "🧑🏿 Pessoas negras",
      "👩🏿 Mulheres negras",
      "🪶 Comunidades quilombolas",
      "🏘️ Comunidades vulneráveis",
      "👥 Comunidade em geral",
      "Outros",
    ],

    "🪶 Povos indígenas e comunidades tradicionais": [
      "👶 Bebês (0 a 2 anos)",
      "🧒 Crianças (3 a 11 anos)",
      "🧑‍🎓 Adolescentes (12 a 17 anos)",
      "🎓 Jovens (18 a 24 anos)",
      "🧑 Adultos (25 a 59 anos)",
      "👴 Idosos (60 anos ou mais)",
      "🪶 Povos indígenas",
      "🪶 Comunidades quilombolas",
      "🌊 Comunidades ribeirinhas",
      "🪶 Comunidades tradicionais",
      "👨‍👩‍👧‍👦 Famílias",
      "👩 Mulheres",
      "🧑‍🌾 Agricultores",
      "Outros",
    ],

    "🏳️‍⚧️ Diversidade e inclusão": [
      "🧒 Crianças (3 a 11 anos)",
      "🧑‍🎓 Adolescentes (12 a 17 anos)",
      "🎓 Jovens (18 a 24 anos)",
      "🧑 Adultos (25 a 59 anos)",
      "👴 Idosos (60 anos ou mais)",
      "🏳️‍🌈 Pessoas LGBTQIA+",
      "♿ Pessoas com deficiência",
      "👩 Mulheres",
      "🧑🏿 Pessoas negras",
      "🪶 Povos indígenas",
      "🪶 Comunidades tradicionais",
      "🌎 Imigrantes",
      "🛂 Refugiados",
      "👥 Comunidade em geral",
      "Outros",
    ],

    "⚖️ Justiça e cidadania": [
      "👶 Bebês (0 a 2 anos)",
      "🧒 Crianças (3 a 11 anos)",
      "🧑‍🎓 Adolescentes (12 a 17 anos)",
      "🎓 Jovens (18 a 24 anos)",
      "🧑 Adultos (25 a 59 anos)",
      "👴 Idosos (60 anos ou mais)",
      "👩 Mulheres",
      "♿ Pessoas com deficiência",
      "🏳️‍🌈 Pessoas LGBTQIA+",
      "🧑🏿 Pessoas negras",
      "🪶 Povos indígenas",
      "🌎 Imigrantes",
      "🛂 Refugiados",
      "⚖️ Pessoas privadas de liberdade",
      "🔄 Egressos do sistema prisional",
      "🫂 Pessoas em situação de vulnerabilidade",
      "👥 Comunidade em geral",
      "Outros",
    ],

    "🕊️ Paz e prevenção de conflitos": [
      "🧒 Crianças (3 a 11 anos)",
      "🧑‍🎓 Adolescentes (12 a 17 anos)",
      "🎓 Jovens (18 a 24 anos)",
      "🧑 Adultos (25 a 59 anos)",
      "👴 Idosos (60 anos ou mais)",
      "👨‍👩‍👧‍👦 Famílias",
      "🏘️ Comunidades vulneráveis",
      "🤝 Lideranças comunitárias",
      "👩‍🏫 Educadores",
      "👥 Comunidade em geral",
      "Outros",
    ],

    "🚨 Emergências e desastres": [
      "👶 Bebês (0 a 2 anos)",
      "🧒 Crianças (3 a 11 anos)",
      "🧑‍🎓 Adolescentes (12 a 17 anos)",
      "🎓 Jovens (18 a 24 anos)",
      "🧑 Adultos (25 a 59 anos)",
      "👴 Idosos (60 anos ou mais)",
      "👨‍👩‍👧‍👦 Famílias",
      "🌊 Pessoas afetadas por enchentes",
      "⛰️ Pessoas afetadas por deslizamentos",
      "🔥 Pessoas afetadas por incêndios",
      "☀️ Pessoas afetadas por secas",
      "🏚️ Pessoas desalojadas",
      "🏚️ Pessoas desabrigadas",
      "♿ Pessoas com deficiência",
      "🫂 Pessoas em situação de vulnerabilidade",
      "🏘️ Comunidades afetadas",
      "Outros",
    ],

    "🧑‍🌾 Economia solidária e empreendedorismo": [
      "🧑‍🎓 Adolescentes (12 a 17 anos)",
      "🎓 Jovens (18 a 24 anos)",
      "🧑 Adultos (25 a 59 anos)",
      "👩 Mulheres",
      "👩 Mães solo",
      "💼 Pessoas desempregadas",
      "💰 Pessoas em situação de pobreza",
      "♿ Pessoas com deficiência",
      "🌎 Imigrantes",
      "🛂 Refugiados",
      "👨‍💼 Pequenos empreendedores",
      "🧑‍🌾 Agricultores familiares",
      "🎨 Artesãos",
      "🤝 Cooperativas",
      "Outros",
    ],
  };

  // --- LÓGICA DO MEDIDOR VISUAL DA DESCRIÇÃO ---
  String get _statusDescricao {
    if (_tamanhoDescricao == 0) return "";
    if (_tamanhoDescricao < 200) return "Muito curto (mín. 200)";
    if (_tamanhoDescricao < 400) return "Razoável";
    if (_tamanhoDescricao < 550) return "Bom!";
    return "Excelente!";
  }

  Color get _corStatusDescricao {
    if (_tamanhoDescricao < 200) return Colors.redAccent;
    if (_tamanhoDescricao < 400) return Colors.orange;
    if (_tamanhoDescricao < 550) return Colors.lightGreen;
    return Colors.green;
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

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
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
                            "Detalhes da Causa",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Fale mais sobre o trabalho incrível de vocês",
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
                              _buildStepItem("2", "Detalhes", true),
                              _buildStepDivider(),
                              _buildStepItem("3", "Finalizar", false),
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
                          "Identidade Visual",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF062222),
                          ),
                        ),
                        const SizedBox(height: 16),

                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _logoAdicionado = !_logoAdicionado;
                            });
                          },
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: _logoAdicionado
                                  ? const Color(0xFFE3F5F1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _logoAdicionado
                                    ? const Color(0xFF0C6B6B)
                                    : const Color(0xFFC2E4DC),
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _logoAdicionado
                                      ? Icons.check_circle
                                      : Icons.cloud_upload_outlined,
                                  color: const Color(0xFF0C6B6B),
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _logoAdicionado
                                      ? "Logo adicionado com sucesso!"
                                      : "Toque para enviar o Logo da ONG",
                                  style: TextStyle(
                                    color: _logoAdicionado
                                        ? const Color(0xFF0C6B6B)
                                        : Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        const Text(
                          "A Essência do Projeto",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF062222),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // --- CAUSA PRINCIPAL ---
                        const Text(
                          "Causa Principal",
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
                                "Selecione a área de atuação principal",
                                style: TextStyle(color: Colors.grey),
                              ),
                              value: _causaPrincipalSelecionada,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Color(0xFF0C6B6B),
                              ),
                              items: _causas.map((String causa) {
                                return DropdownMenuItem<String>(
                                  value: causa,
                                  child: Text(causa),
                                );
                              }).toList(),
                              onChanged: (novoValor) {
                                setState(() {
                                  // A MÁGICA ACONTECE AQUI: Ao mudar a causa, apagamos os filtros anteriores!
                                  _causaPrincipalSelecionada = novoValor;
                                  _oferecimentosSelecionados.clear();
                                  _publicoSelecionado.clear();
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // --- O QUE A ONG OFERECE (DINÂMICO) ---
                        const Text(
                          "O que a ONG oferece? (Atividades/Serviços)",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF062222),
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (_causaPrincipalSelecionada == null)
                          _buildAvisoVazio(
                            "Selecione a Causa Principal acima para ver os serviços correspondentes.",
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                _mapaOferecimentos[_causaPrincipalSelecionada]!
                                    .map((oferecimento) {
                                      bool selecionado =
                                          _oferecimentosSelecionados.contains(
                                            oferecimento,
                                          );
                                      return _buildChip(
                                        oferecimento,
                                        selecionado,
                                        (value) {
                                          setState(() {
                                            value
                                                ? _oferecimentosSelecionados
                                                      .add(oferecimento)
                                                : _oferecimentosSelecionados
                                                      .remove(oferecimento);
                                          });
                                        },
                                      );
                                    })
                                    .toList(),
                          ),
                        const SizedBox(height: 24),

                        // --- PÚBLICO ATENDIDO (DINÂMICO) ---
                        const Text(
                          "Público Atendido (Selecione um ou mais)",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF062222),
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (_causaPrincipalSelecionada == null)
                          _buildAvisoVazio(
                            "Selecione a Causa Principal para ver os públicos correspondentes.",
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _mapaPublico[_causaPrincipalSelecionada]!
                                .map((publico) {
                                  bool selecionado = _publicoSelecionado
                                      .contains(publico);
                                  return _buildChip(publico, selecionado, (
                                    value,
                                  ) {
                                    setState(() {
                                      value
                                          ? _publicoSelecionado.add(publico)
                                          : _publicoSelecionado.remove(publico);
                                    });
                                  });
                                })
                                .toList(),
                          ),
                        const SizedBox(height: 24),

                        // --- CAMPO DE DESCRIÇÃO COM MEDIDOR ---
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Descrição da ONG",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF062222),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _descricaoController,
                              maxLines: 5,
                              maxLength: 600,
                              onChanged: (val) => setState(
                                () => _tamanhoDescricao = val.length,
                              ),
                              decoration: InputDecoration(
                                hintText: "Conte a história, a missão e os projetos da organização (Mín. 200 caracteres)...",
                                hintStyle: const TextStyle(color: Colors.grey),
                                counterText: "",
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.all(16),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFC2E4DC),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF0C6B6B),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (_tamanhoDescricao > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LinearProgressIndicator(
                                  value: _tamanhoDescricao / 600,
                                  backgroundColor: Colors.grey.shade300,
                                  color: _corStatusDescricao,
                                  minHeight: 6,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _statusDescricao,
                                      style: TextStyle(
                                        color: _corStatusDescricao,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "$_tamanhoDescricao / 600",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 32),

                        // --- BOTÃO CONTINUAR ---
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
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
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_causaPrincipalSelecionada == null) {
                                    _mostrarErro(
                                      "Por favor, selecione a Causa Principal da ONG.",
                                    );
                                    return;
                                  }
                                  if (_oferecimentosSelecionados.isEmpty) {
                                    _mostrarErro(
                                      "Selecione pelo menos um serviço que a ONG oferece.",
                                    );
                                    return;
                                  }
                                  if (_publicoSelecionado.isEmpty) {
                                    _mostrarErro(
                                      "Selecione pelo menos um público atendido pela organização.",
                                    );
                                    return;
                                  }
                                  if (_descricaoController.text.trim().length <
                                      200) {
                                    _mostrarErro(
                                      "A descrição da ONG está muito curta. Por favor, escreva no mínimo 200 caracteres para detalhar bem o seu projeto.",
                                    );
                                    return;
                                  }

                                  // Empacotando Tudo!
                                  final dadosOngStep2 = {
                                    ...widget.dadosOng,
                                    "logo_adicionado": _logoAdicionado,
                                    "causa_principal":
                                        _causaPrincipalSelecionada,
                                    "servicos_oferecidos":
                                        _oferecimentosSelecionados.toList(),
                                    "publico_atendido": _publicoSelecionado
                                        .toList(),
                                    "descricao": _descricaoController.text
                                        .trim(),
                                  };

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          RegisterOngStep3Page(
                                            dadosCompletos: dadosOngStep2,
                                          ),
                                    ),
                                  );

                                  print(
                                    "📦 DADOS ONG ACUMULADOS (STEP 1 + 2):",
                                  );
                                  print(dadosOngStep2);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8CD4C7),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
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

  // --- MÉTODOS AUXILIARES UI ---

  // Cria o balãozinho clicável
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

  // Cria a mensagem pontilhada quando nenhuma causa foi selecionada
  Widget _buildAvisoVazio(String mensagem) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFC2E4DC),
          style: BorderStyle.solid,
        ), // Usando solid pra não dar erro
      ),
      child: Center(
        child: Text(
          mensagem,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF3A6868),
            fontStyle: FontStyle.italic,
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
            color: isActive || isCompleted
                ? Colors.white
                : Colors.white.withOpacity(0.2),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: isActive || isCompleted
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
