// lib/admin/widgets/admin_stats_view.dart

import 'package:flutter/material.dart';
import '../models/admin_models.dart';
import 'admin_metric_card.dart';

class AdminStatsView extends StatelessWidget {
  final AdminStatsModel? stats;

  const AdminStatsView({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Resumo da Plataforma',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF062222),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              AdminMetricCard(
                titulo: 'Total Utilizadores',
                valor: stats?.totalUsuarios ?? 0,
                icone: Icons.people,
                cor: Colors.blueGrey,
              ),
              AdminMetricCard(
                titulo: 'Voluntários',
                valor: stats?.totalVoluntarios ?? 0,
                icone: Icons.volunteer_activism,
                cor: const Color(0xFF0C6B6B),
              ),
              AdminMetricCard(
                titulo: 'ONGs Ativas',
                valor: stats?.totalOngs ?? 0,
                icone: Icons.domain,
                cor: Colors.orange[800]!,
              ),
              AdminMetricCard(
                titulo: 'Vagas Criadas',
                valor: stats?.totalVagas ?? 0,
                icone: Icons.campaign,
                cor: Colors.teal,
              ),
              AdminMetricCard(
                titulo: 'Candidaturas',
                valor: stats?.totalCandidaturas ?? 0,
                icone: Icons.assignment_turned_in,
                cor: Colors.indigo,
              ),
              AdminMetricCard(
                titulo: 'Publicações Feed',
                valor: stats?.totalPublicacoesFeed ?? 0,
                icone: Icons.dynamic_feed,
                cor: Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
