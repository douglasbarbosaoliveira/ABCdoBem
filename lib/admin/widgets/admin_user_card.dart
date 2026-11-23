// lib/admin/widgets/admin_user_card.dart

import 'package:flutter/material.dart';
import '../models/admin_models.dart';

class AdminUserCard extends StatelessWidget {
  final AdminUserModel usuario;
  final Function(String novoRole) onAlterarRole;
  final VoidCallback onBanir;

  const AdminUserCard({
    super.key,
    required this.usuario,
    required this.onAlterarRole,
    required this.onBanir,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFC2E4DC)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE3F5F1),
          child: Text(
            usuario.nome.isNotEmpty ? usuario.nome[0].toUpperCase() : 'U',
            style: const TextStyle(
                color: Color(0xFF0C6B6B), fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          usuario.nome,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          '${usuario.email}\nPapel: ${usuario.role}',
          style: const TextStyle(fontSize: 12),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.security, color: Color(0xFF0C6B6B)),
              tooltip: 'Alterar Papel',
              onSelected: onAlterarRole,
              itemBuilder: (context) => const [
                PopupMenuItem(
                    value: 'USER', child: Text('Definir como Voluntário')),
                PopupMenuItem(value: 'ONG', child: Text('Definir como ONG')),
                PopupMenuItem(value: 'ADMIN', child: Text('Promover a ADMIN')),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Banir Utilizador',
              onPressed: onBanir,
            ),
          ],
        ),
      ),
    );
  }
}
