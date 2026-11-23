import 'package:flutter/material.dart';
import 'acessibilidade/acessibilidade.dart';

// Utilitário de responsividade
import 'utils/responsive.dart';

// Blocos da página
import 'widgets/custom_nav_bar.dart';
import 'widgets/hero_section.dart';
import 'widgets/features_toggle_section.dart';
import 'widgets/impact_gallery_section.dart';
import 'widgets/landing_page_sections.dart';

class LandingPage extends StatelessWidget {
  final AcessibilidadeController acessibilidadeController;
  final VoidCallback onLogin;
  final VoidCallback onRegisterVolunteer;
  final VoidCallback onRegisterOng;
  final VoidCallback onOpenAccessibility;

  const LandingPage({
    super.key,
    required this.acessibilidadeController,
    required this.onLogin,
    required this.onRegisterVolunteer,
    required this.onRegisterOng,
    required this.onOpenAccessibility,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool altoContraste = acessibilidadeController.altoContraste;
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(
          fontFamily: 'Quicksand',
          bodyColor: altoContraste ? Colors.white : null,
          displayColor: altoContraste ? Colors.white : null,
        ),
      ),
      child: Scaffold(
        backgroundColor: altoContraste ? Colors.black : const Color(0xFFF0FAF7),
        body: Stack(
          children: [
            SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  // Espaçamento para acomodar a CustomNavBar flutuante
                  SizedBox(height: isMobile ? 70 : 80),

                  HeroSection(
                    onRegisterVolunteer: onRegisterVolunteer,
                    onRegisterOng: onRegisterOng,
                  ),

                  const StatsSection(),
                  const FeaturesToggleSection(),
                  const ImpactGallerySection(),

                  SplitRoleSection(
                    onRegisterVolunteer: onRegisterVolunteer,
                    onRegisterOng: onRegisterOng,
                  ),

                  FinalCtaSection(
                    onRegisterVolunteer: onRegisterVolunteer,
                    onLogin: onLogin,
                  ),

                  const CustomFooter(),
                ],
              ),
            ),

            // Barra de navegação superior fixa
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: CustomNavBar(
                onLogin: onLogin,
                onOpenAccessibility: onOpenAccessibility,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
