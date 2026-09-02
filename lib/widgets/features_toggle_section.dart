import 'package:flutter/material.dart';

// Passos para Voluntários
final List<Map<String, String>> volunteerSteps = [
  {
    "icon": "👤",
    "title": "Crie seu perfil",
    "desc":
        "Cadastre suas habilidades e causas que você tem interesse em apoiar.",
  },
  {
    "icon": "🗺️",
    "title": "Encontre ONGs",
    "desc": "Busque organizações por geolocalização na região do Grande ABC.",
  },
  {
    "icon": "📅",
    "title": "Inscreva-se",
    "desc": "Encontrou uma ação legal? Participe com apenas dois cliques.",
  },
  {
    "icon": "🤝",
    "title": "Faça a diferença",
    "desc": "Alinhe os detalhes pelo chat direto com a ONG e comece a atuar.",
  },
];

// Passos para ONGs
final List<Map<String, String>> ongSteps = [
  {
    "icon": "🏢",
    "title": "Cadastre a Instituição",
    "desc": "Crie o perfil da sua organização e mostre sua missão para a comunidade.",
  },
  {
    "icon": "📢",
    "title": "Divulgue necessidades",
    "desc": "Publique eventos, vagas para mutirões ou necessidades diárias.",
  },
  {
    "icon": "🎯",
    "title": "Aprove voluntários",
    "desc": "Receba inscrições de pessoas com as habilidades exatas que você precisa.",
  },
  {
    "icon": "💬",
    "title": "Gerencie projetos",
    "desc": "Use o chat integrado para coordenar os voluntários com agilidade.",
  },
];

class FeaturesToggleSection extends StatefulWidget {
  const FeaturesToggleSection({super.key});

  @override
  State<FeaturesToggleSection> createState() => _FeaturesToggleSectionState();
}

class _FeaturesToggleSectionState extends State<FeaturesToggleSection> {
  bool isVolunteerSelected = true;

  Widget _buildGrid(
    List<Map<String, String>> steps,
    Color iconBgColor,
    Color stepColor,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisExtent: 220,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    step["icon"]!,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "PASSO ${index + 1}",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: stepColor,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                step["title"]!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF062222),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                step["desc"]!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF3A6868),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0C6B6B) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF3A6868),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFC2E4DC)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTabButton(
                      "Para Voluntários",
                      isVolunteerSelected,
                      () {
                        setState(() => isVolunteerSelected = true);
                      },
                    ),
                    _buildTabButton(
                      "Para Instituições",
                      !isVolunteerSelected,
                      () {
                        setState(() => isVolunteerSelected = false);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isVolunteerSelected
                    ? _buildGrid(
                        volunteerSteps,
                        const Color(0xFFD1F5EE),
                        const Color(0xFF29B0A0),
                      )
                    : _buildGrid(
                        ongSteps,
                        const Color(0xFFC2E4DC),
                        const Color(0xFF0C6B6B),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
