// lib/widgets/landing_page_sections.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../ongs/services/ong_painel_service.dart';
import '../utils/responsive.dart';

class _LandingStatsData {
  final int voluntariosCount;
  final int ongsCount;
  final int eventosCount;
  final String populacaoImpactadaTexto;

  const _LandingStatsData({
    required this.voluntariosCount,
    required this.ongsCount,
    required this.eventosCount,
    this.populacaoImpactadaTexto = "2.7 mi",
  });

  String formatarCompacto(int valor, {bool sufixoMais = false}) {
    if (valor <= 0) return "0";
    if (valor >= 1000000) {
      final mi = (valor / 1000000).toStringAsFixed(1).replaceAll('.', ',');
      return "$mi mi";
    }
    if (valor >= 1000) {
      final mil = (valor / 1000).toStringAsFixed(1).replaceAll('.', ',');
      return sufixoMais ? "$mil mil +" : "$mil mil";
    }
    return sufixoMais ? "$valor +" : "$valor";
  }
}

// --- ESTATÍSTICAS ---
class StatsSection extends StatefulWidget {
  const StatsSection({super.key});

  @override
  State<StatsSection> createState() => _StatsSectionState();
}

class _StatsSectionState extends State<StatsSection> {
  static const String _baseUrl = 'https://abc-do-bem.onrender.com';

  late Future<_LandingStatsData> _futureStats;

  @override
  void initState() {
    super.initState();
    _futureStats = _carregarEstatisticasApi();
  }

  Future<_LandingStatsData> _carregarEstatisticasApi() async {
    int voluntariosCount = 0;
    int ongsCount = 0;
    int eventosCount = 0;

    final headers = <String, String>{'Accept': 'application/json'};

    try {
      final resVol = await http
          .get(Uri.parse('$_baseUrl/users/voluntarios'), headers: headers)
          .timeout(const Duration(seconds: 12));
      if (resVol.statusCode >= 200 && resVol.statusCode < 300) {
        final lista = JsonParsers.extractList(
          jsonDecode(utf8.decode(resVol.bodyBytes)),
          ['volunteers', 'voluntarios', 'users', 'items'],
        );
        voluntariosCount = lista.length;
      }
    } catch (_) {}

    try {
      final resOngs = await http
          .get(Uri.parse('$_baseUrl/users/ongs'), headers: headers)
          .timeout(const Duration(seconds: 12));
      if (resOngs.statusCode >= 200 && resOngs.statusCode < 300) {
        final lista = JsonParsers.extractList(
          jsonDecode(utf8.decode(resOngs.bodyBytes)),
          ['ongs', 'organizations', 'users', 'items'],
        );
        ongsCount = lista.length;
      }
    } catch (_) {}

    try {
      final resOpp = await http
          .get(Uri.parse('$_baseUrl/opportunities'), headers: headers)
          .timeout(const Duration(seconds: 12));
      if (resOpp.statusCode >= 200 && resOpp.statusCode < 300) {
        final decoded = jsonDecode(utf8.decode(resOpp.bodyBytes));
        final lista = JsonParsers.extractList(
          decoded,
          ['opportunities', 'acoes', 'events', 'items'],
        );
        eventosCount = lista.length;
      }
    } catch (_) {}

    return _LandingStatsData(
      voluntariosCount: voluntariosCount,
      ongsCount: ongsCount,
      eventosCount: eventosCount,
      populacaoImpactadaTexto: "2.7 mi",
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final double screenWidth = MediaQuery.of(context).size.width;

    // Largura calculada para manter os cards em 2x2 no mobile
    final double itemWidth = isMobile ? (screenWidth - 72) / 2 : 200;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 32 : 48,
        horizontal: isMobile ? 16 : 20,
      ),
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: FutureBuilder<_LandingStatsData>(
            future: _futureStats,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF0C6B6B)),
                  ),
                );
              }

              final data = snapshot.data ??
                  const _LandingStatsData(
                    voluntariosCount: 0,
                    ongsCount: 0,
                    eventosCount: 0,
                    populacaoImpactadaTexto: "2.7 mi",
                  );

              return Wrap(
                alignment: WrapAlignment.spaceAround,
                spacing: isMobile ? 16 : 40,
                runSpacing: isMobile ? 24 : 40,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _StatItem(
                      number: data.formatarCompacto(
                        data.voluntariosCount,
                        sufixoMais: true,
                      ),
                      label: "VOLUNTÁRIOS CADASTRADOS",
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _StatItem(
                      number: data.formatarCompacto(data.ongsCount),
                      label: "ONGs PARCEIRAS",
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _StatItem(
                      number: data.formatarCompacto(data.eventosCount),
                      label: "EVENTOS REALIZADOS",
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _StatItem(
                      number: data.populacaoImpactadaTexto,
                      label: "POPULAÇÃO IMPACTADA",
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String number, label;
  const _StatItem({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          number,
          style: TextStyle(
            fontSize: isMobile ? 28 : 36,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0C6B6B),
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            color: const Color(0xFF3A6868),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// --- CARDS DIVIDIDOS (VOLUNTÁRIOS VS ONGS) ---
class SplitRoleSection extends StatelessWidget {
  final VoidCallback onRegisterVolunteer;
  final VoidCallback onRegisterOng;

  const SplitRoleSection({
    super.key,
    required this.onRegisterVolunteer,
    required this.onRegisterOng,
  });

  Widget _buildBullet(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "• ",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    final bool isDesktop = Responsive.isDesktop(context);

    Widget volunteerCard = Container(
      padding: EdgeInsets.all(isMobile ? 24 : 40),
      color: const Color(0xFF0C5252),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "PARA VOLUNTÁRIOS",
            style: TextStyle(
              color: Color(0xFF9FE8D8),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Coloque suas habilidades a serviço da comunidade",
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 22 : 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Cadastre suas competências — educação, tecnologia, serviços, mão-de-obra, alimentação — e encontre ONGs que precisam exatamente do que você sabe fazer.",
            style: TextStyle(
              color: Color(0xFF9FE8D8),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          _buildBullet("Perfil com suas habilidades", Colors.white),
          _buildBullet("Encontre as ONGs mais próximas de você", Colors.white),
          _buildBullet("Inscrição rápida em eventos", Colors.white),
          _buildBullet("Compartilhe suas ações com a comunidade", Colors.white),
          SizedBox(height: isMobile ? 24 : 32),
          SizedBox(
            width: isMobile ? double.infinity : null,
            child: ElevatedButton(
              onPressed: onRegisterVolunteer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3DCFB0),
                foregroundColor: const Color(0xFF062222),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Criar perfil de voluntário",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );

    Widget ongCard = Container(
      padding: EdgeInsets.all(isMobile ? 24 : 40),
      color: const Color(0xFF3DCFB0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "PARA ONGS",
            style: TextStyle(
              color: Color(0xFF062222),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Encontre os voluntários que sua causa precisa",
            style: TextStyle(
              color: const Color(0xFF062222),
              fontSize: isMobile ? 22 : 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Cadastre sua organização, defina suas necessidades e publique eventos. Nossa plataforma conecta você a voluntários no grande ABC.",
            style: TextStyle(
              color: Color(0xFF0C5252),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          _buildBullet(
            "Perfil completo da organização",
            const Color(0xFF062222),
          ),
          _buildBullet(
            "Cadastro das necessidades desejadas para voluntários",
            const Color(0xFF062222),
          ),
          _buildBullet(
            "Publicação de eventos e mutirões",
            const Color(0xFF062222),
          ),
          _buildBullet(
            "Combine ações com voluntários dentro da nossa plataforma",
            const Color(0xFF062222),
          ),
          SizedBox(height: isMobile ? 24 : 32),
          SizedBox(
            width: isMobile ? double.infinity : null,
            child: ElevatedButton(
              onPressed: onRegisterOng,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF062222),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Cadastrar minha ONG",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 80,
        horizontal: isMobile ? 16 : 20,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: isDesktop
                ? IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: volunteerCard),
                        Expanded(child: ongCard),
                      ],
                    ),
                  )
                : Column(
                    children: [volunteerCard, ongCard],
                  ),
          ),
        ),
      ),
    );
  }
}

// --- CTA FINAL (PRONTO PARA FAZER A DIFERENÇA?) ---
class FinalCtaSection extends StatelessWidget {
  final VoidCallback onRegisterVolunteer;
  final VoidCallback onLogin;

  const FinalCtaSection({
    super.key,
    required this.onRegisterVolunteer,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 48 : 80,
        horizontal: isMobile ? 16 : 20,
      ),
      color: const Color(0xFF0C5252),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Text(
                "Pronto para fazer a diferença?",
                style: TextStyle(
                  fontSize: isMobile ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "Sozinhos podemos fazer tão pouco, mas juntos podemos fazer muito.\nO Grande ABC tem uma comunidade incrível. Faça parte dela.",
                style: TextStyle(
                  fontSize: isMobile ? 15 : 18,
                  color: const Color(0xFF9FE8D8),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isMobile ? 32 : 40),
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: onRegisterVolunteer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3DCFB0),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Quero participar - Cadastrar",
                        style: TextStyle(
                          color: Color(0xFF062222),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: onLogin,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF9FE8D8),
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Já tenho minha conta — Entrar",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: onRegisterVolunteer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3DCFB0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Quero participar - Cadastrar",
                        style: TextStyle(
                          color: Color(0xFF062222),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: onLogin,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF9FE8D8),
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Já tenho minha conta — Entrar",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- RODAPÉ ---
class CustomFooter extends StatelessWidget {
  const CustomFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);

    return Container(
      width: double.infinity,
      color: const Color(0xFF062222),
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 24 : 32,
        horizontal: 20,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: isMobile
              ? Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/logo_abcdobem.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.eco_rounded,
                            size: 24,
                            color: Color(0xFF9FE8D8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "ABC do Bem",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "© 2026 ABC do Bem. Todos os direitos reservados.",
                      style: TextStyle(color: Color(0xFF9FE8D8), fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/logo_abcdobem.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.eco_rounded,
                            size: 24,
                            color: Color(0xFF9FE8D8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "ABC do Bem",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      "© 2026 ABC do Bem. Todos os direitos reservados.",
                      style: TextStyle(color: Color(0xFF9FE8D8), fontSize: 12),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
