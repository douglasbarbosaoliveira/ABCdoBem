// lib/admin/pages/admin_dashboard_page.dart

import 'package:flutter/material.dart';
import '../../services/session_service.dart';
import 'models/admin_models.dart';
import 'services/admin_service.dart';
import 'widgets/admin_stats_view.dart';
import 'widgets/admin_users_view.dart';
import 'widgets/admin_moderation_view.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final AdminService _adminService = AdminService();

  int _abaSelecionada = 0;
  bool _carregando = true;
  String? _erroAcesso;

  AdminStatsModel? _stats;
  List<AdminUserModel> _usuarios = [];
  String _filtroRole = 'ALL';

  final TextEditingController _idOportunidadeCtrl = TextEditingController();
  final TextEditingController _idPostOngCtrl = TextEditingController();
  final TextEditingController _idExperienciaCtrl = TextEditingController();

  String? get _token => SessionService.instance.token;

  @override
  void initState() {
    super.initState();
    _validarAcessoECarregar();
  }

  @override
  void dispose() {
    _idOportunidadeCtrl.dispose();
    _idPostOngCtrl.dispose();
    _idExperienciaCtrl.dispose();
    super.dispose();
  }

  void _validarAcessoECarregar() {
    final role = SessionService.instance.role?.toUpperCase();
    if (role != 'ADMIN') {
      setState(() {
        _erroAcesso =
            'Acesso restrito. Esta secção requer privilégios de Administrador.';
        _carregando = false;
      });
      return;
    }
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);

    final stats = await _adminService.obterEstatisticas(token: _token);
    final users = await _adminService.listarUsuarios(
      token: _token,
      role: _filtroRole == 'ALL' ? null : _filtroRole,
    );

    if (mounted) {
      setState(() {
        _stats = stats;
        _usuarios = users;
        _carregando = false;
      });
    }
  }

  Future<void> _alterarRole(AdminUserModel usuario, String novoRole) async {
    final sucesso = await _adminService.alterarRoleUsuario(
      id: usuario.id,
      novoRole: novoRole,
      token: _token,
    );

    if (!mounted) return;
    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Papel de ${usuario.nome} alterado para $novoRole.')),
      );
      _carregarDados();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao atualizar papel do utilizador.')),
      );
    }
  }

  void _confirmarBanimento(AdminUserModel usuario) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Banir Utilizador',
            style: TextStyle(
                color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text(
            'Tem a certeza de que deseja banir e remover permanentemente "${usuario.nome}" (${usuario.email})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              final sucesso = await _adminService.banirUsuario(
                  id: usuario.id, token: _token);
              if (!mounted) return;
              if (sucesso) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Utilizador removido do sistema com sucesso.')),
                );
                _carregarDados();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Falha ao remover o utilizador.')),
                );
              }
            },
            child:
                const Text('Sim, Banir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _removerOportunidade() async {
    final id = _idOportunidadeCtrl.text.trim();
    if (id.isEmpty) return;

    final sucesso =
        await _adminService.removerOportunidade(id: id, token: _token);
    if (!mounted) return;
    if (sucesso) {
      _idOportunidadeCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oportunidade removida com sucesso.')));
      _carregarDados();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao remover oportunidade.')));
    }
  }

  Future<void> _removerPostOng() async {
    final id = _idPostOngCtrl.text.trim();
    if (id.isEmpty) return;

    final sucesso =
        await _adminService.removerPostagemOng(id: id, token: _token);
    if (!mounted) return;
    if (sucesso) {
      _idPostOngCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Publicação de ONG removida com sucesso.')));
      _carregarDados();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao remover publicação da ONG.')));
    }
  }

  Future<void> _removerExperiencia() async {
    final id = _idExperienciaCtrl.text.trim();
    if (id.isEmpty) return;

    final sucesso =
        await _adminService.removerExperienciaVoluntario(id: id, token: _token);
    if (!mounted) return;
    if (sucesso) {
      _idExperienciaCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Relato de experiência removido com sucesso.')));
      _carregarDados();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Falha ao remover relato de voluntário.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_erroAcesso != null) {
      return Scaffold(
        appBar: AppBar(
            title: const Text('Acesso Restrito'),
            backgroundColor: const Color(0xFF0C6B6B)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.gpp_bad_rounded,
                    size: 64, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(_erroAcesso!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C6B6B)),
                  child: const Text('Voltar',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF7),
      appBar: AppBar(
        title: const Text('Painel de Controlo & Moderação',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white)),
        backgroundColor: const Color(0xFF0C6B6B),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Atualizar Dados',
            onPressed: _carregarDados,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _abaSelecionada,
        selectedItemColor: const Color(0xFF0C6B6B),
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _abaSelecionada = index),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined), label: 'Métricas'),
          BottomNavigationBarItem(
              icon: Icon(Icons.manage_accounts_outlined),
              label: 'Utilizadores'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shield_outlined), label: 'Moderação'),
        ],
      ),
      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0C6B6B)))
          : IndexedStack(
              index: _abaSelecionada,
              children: [
                AdminStatsView(stats: _stats),
                AdminUsersView(
                  usuarios: _usuarios,
                  filtroRole: _filtroRole,
                  onFiltroChanged: (novo) {
                    setState(() => _filtroRole = novo);
                    _carregarDados();
                  },
                  onAlterarRole: _alterarRole,
                  onBanir: _confirmarBanimento,
                ),
                AdminModerationView(
                  oportunidadeCtrl: _idOportunidadeCtrl,
                  postOngCtrl: _idPostOngCtrl,
                  experienciaCtrl: _idExperienciaCtrl,
                  onRemoverOportunidade: _removerOportunidade,
                  onRemoverPostOng: _removerPostOng,
                  onRemoverExperiencia: _removerExperiencia,
                ),
              ],
            ),
    );
  }
}
