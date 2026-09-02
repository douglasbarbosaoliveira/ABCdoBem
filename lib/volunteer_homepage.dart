// lib/voluntario_home_page.dart

import 'package:flutter/material.dart';

import 'app_sidebar.dart';
import 'app_header.dart';
import 'search_ongs_page.dart';
import 'events_page.dart';
import 'notifications_page.dart';
import 'messages_page.dart';
import 'models/dashboard_volunteer_models.dart';
import 'models/event_models.dart';
import 'models/ong_models.dart';
import 'services/dashboard_volunteer_service.dart';

class VoluntarioHomePage extends StatefulWidget {
  final String voluntarioId;

  const VoluntarioHomePage({super.key, this.voluntarioId = "voluntario-1"});

  @override
  State<VoluntarioHomePage> createState() => _VoluntarioHomePageState();
}

class _VoluntarioHomePageState extends State<VoluntarioHomePage> {
  final DashboardService _dashboardService = DashboardService();

  bool _carregando = true;
  bool _erroConexao = false;
  VoluntarioDashboardModel? _dashboard;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
      _erroConexao = false;
    });

    try {
      final dados = await _dashboardService.buscarDashboard(
        widget.voluntarioId,
      );
      if (mounted) {
        setState(() {
          _dashboard = dados;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _carregando = false;
          _erroConexao = true;
        });
      }
    }
  }

  void _navegarPara(Widget pagina) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, a1, a2) => pagina,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Quicksand'),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0FAF7),
        body: Row(
          children: [
            if (isDesktop) const AppSidebar(currentIndex: 0),
            Expanded(
              child: Column(
                children: [
                  const AppHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: _carregando
                              ? const Padding(
                                  padding: EdgeInsets.all(80.0),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF0C6B6B),
                                    ),
                                  ),
                                )
                              : _erroConexao
                              ? _buildErrorState()
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildWelcomeBanner(_dashboard!),
                                    const SizedBox(height: 24),
                                    _buildQuickActionsGrid(),
                                    const SizedBox(height: 32),

                                    // Seção de Próximo Evento
                                    _buildSectionHeader(
                                      "Próximo Evento",
                                      "Ver todos",
                                      () => _navegarPara(const EventosPage()),
                                    ),
                                    const SizedBox(height: 12),
                                    if (_dashboard!.proximoEvento != null)
                                      _buildEventCard(
                                        _dashboard!.proximoEvento!,
                                      )
                                    else
                                      _buildEmptyEventCard(),

                                    const SizedBox(height: 32),

                                    // Seção de ONG Próxima
                                    _buildSectionHeader(
                                      "ONG Próxima de Você",
                                      "Ver mapa",
                                      () =>
                                          _navegarPara(const BuscarOngsPage()),
                                    ),
                                    const SizedBox(height: 12),
                                    if (_dashboard!.ongProxima != null)
                                      _buildOngCard(_dashboard!.ongProxima!)
                                    else
                                      _buildEmptyOngCard(),

                                    const SizedBox(height: 40),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(VoluntarioDashboardModel dash) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF062222), Color(0xFF0C5252), Color(0xFF1A8F8F)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "BEM-VINDA DE VOLTA",
            style: TextStyle(
              color: Color(0xFF9FE8D8),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Olá, ${dash.nome}! 👋",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              CircleAvatar(
                backgroundImage: NetworkImage(dash.fotoUrl),
                radius: 30,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Sua comunidade precisa de você hoje.",
            style: TextStyle(color: Color(0xFF9FE8D8), fontSize: 14),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem("${dash.metricas.totalCidades}", "Cidades"),
              _buildMetricItem(
                "${dash.metricas.ongsAjudadas}",
                "ONGs que ajudei",
              ),
              _buildMetricItem(dash.metricas.horasDoadas, "Horas doadas"),
              _buildRatingMetricItem(
                dash.metricas.rankingEstrelas,
                "Meu Ranking",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF9FE8D8), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildRatingMetricItem(double rating, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "$rating",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF9FE8D8), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            Icons.search_rounded,
            "Buscar ONGs",
            const Color(0xFFE3F5F1),
            const Color(0xFF0C6B6B),
            () => _navegarPara(const BuscarOngsPage()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            Icons.event_available_rounded,
            "Ver Eventos",
            const Color(0xFFE3EDF5),
            const Color(0xFF1A528F),
            () => _navegarPara(const EventosPage()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            Icons.notifications_active_rounded,
            "Notificações",
            const Color(0xFFFDF3E3),
            const Color(0xFF8F6B1A),
            () => _navegarPara(const NotificacoesPage()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            Icons.chat_bubble_rounded,
            "Mensagens",
            const Color(0xFFF5E3F0),
            const Color(0xFF8F1A73),
            () => _navegarPara(const MensagensPage()),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    IconData icon,
    String label,
    Color bgColor,
    Color textColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: textColor.withOpacity(0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String actionText,
    VoidCallback onAction,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF062222),
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(
            actionText,
            style: const TextStyle(
              color: Color(0xFF0C6B6B),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(EventoModel ev) {
    return InkWell(
      onTap: () => _navegarPara(const EventosPage()),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFC2E4DC)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              ev.imagemUrl,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: ev.tags.map((t) => _buildTag(t)).toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ev.titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF062222),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${ev.ongNome} • ${ev.data} • ${ev.horario}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F5F1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${ev.vagasRestantes} vagas",
                          style: const TextStyle(
                            color: Color(0xFF0C6B6B),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyEventCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC2E4DC)),
      ),
      child: const Center(
        child: Text(
          "Você não possui eventos agendados para os próximos dias.",
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildOngCard(OngModel ong) {
    return InkWell(
      onTap: () => _navegarPara(const BuscarOngsPage()),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFC2E4DC)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                ong.imagem,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          ong.nome,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF062222),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (ong.endereco != null)
                        Text(
                          ong.endereco!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${ong.cidade} • ${ong.categoria}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOngCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC2E4DC)),
      ),
      child: const Center(
        child: Text(
          "Nenhuma ONG próxima encontrada no momento.",
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F5F1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF0C6B6B),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Colors.redAccent,
            size: 40,
          ),
          const SizedBox(height: 12),
          const Text(
            "Não foi possível carregar seu painel",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF062222),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Verifique sua conexão com o servidor e tente novamente.",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _carregarDados,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0C6B6B),
            ),
            child: const Text(
              "Tentar novamente",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
