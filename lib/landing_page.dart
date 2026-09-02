import 'package:flutter/material.dart';

// Importando os blocos da página
import 'widgets/custom_nav_bar.dart';
import 'widgets/hero_section.dart';
import 'widgets/features_toggle_section.dart';
import 'widgets/impact_gallery_section.dart';
import 'widgets/landing_page_sections.dart';

class LandingPage extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegisterVolunteer;
  final VoidCallback onRegisterOng;

  const LandingPage({
    super.key,
    required this.onLogin,
    required this.onRegisterVolunteer,
    required this.onRegisterOng,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Quicksand'),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0FAF7),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  HeroSection(
                    onRegisterVolunteer: onRegisterVolunteer,
                    onRegisterOng: onRegisterOng,
                  ),
                  StatsSection(),
                  FeaturesToggleSection(),
                  ImpactGallerySection(),

                  // Nossas duas seções fiéis ao Figma entram aqui!
                  SplitRoleSection(
                    onRegisterVolunteer: onRegisterVolunteer,
                    onRegisterOng: onRegisterOng,
                  ),
                  FinalCtaSection(
                    onRegisterVolunteer: onRegisterVolunteer,
                    onLogin: onLogin,
                  ),

                  CustomFooter(),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: CustomNavBar(
                onLogin: onLogin,
                onRegisterVolunteer: onRegisterVolunteer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
