// lib/admin/widgets/admin_users_view.dart

import 'package:flutter/material.dart';
import '../models/admin_models.dart';
import 'admin_user_card.dart';

class AdminUsersView extends StatelessWidget {
  final List<AdminUserModel> usuarios;
  final String filtroRole;
  final Function(String novoFiltro) onFiltroChanged;
  final Function(AdminUserModel usuario, String novoRole) onAlterarRole;
  final Function(AdminUserModel usuario) onBanir;

  const AdminUsersView({
    super.key,
    required this.usuarios,
    required this.filtroRole,
    required this.onFiltroChanged,
    required this.onAlterarRole,
    required this.onBanir,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filtrar por Papel:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              DropdownButton<String>(
                value: filtroRole,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('Todos')),
                  DropdownMenuItem(
                      value: 'USER', child: Text('Voluntários (USER)')),
                  DropdownMenuItem(value: 'ONG', child: Text('ONGs')),
                  DropdownMenuItem(
                      value: 'ADMIN', child: Text('Administradores')),
                ],
                onChanged: (novo) {
                  if (novo != null) onFiltroChanged(novo);
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: usuarios.isEmpty
              ? const Center(
                  child: Text('Nenhum utilizador encontrado com este filtro.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: usuarios.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final u = usuarios[index];
                    return AdminUserCard(
                      usuario: u,
                      onAlterarRole: (novoRole) => onAlterarRole(u, novoRole),
                      onBanir: () => onBanir(u),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
