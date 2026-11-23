// lib/admin/models/admin_models.dart

class AdminStatsModel {
  final int totalUsuarios;
  final int totalVoluntarios;
  final int totalOngs;
  final int totalVagas;
  final int totalCandidaturas;
  final int totalPublicacoesFeed;
  final int totalExperiencias;

  AdminStatsModel({
    required this.totalUsuarios,
    required this.totalVoluntarios,
    required this.totalOngs,
    required this.totalVagas,
    required this.totalCandidaturas,
    required this.totalPublicacoesFeed,
    required this.totalExperiencias,
  });

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminStatsModel(
      totalUsuarios: json['totalUsuarios'] ?? json['usersCount'] ?? 0,
      totalVoluntarios:
          json['totalVoluntarios'] ?? json['voluntariosCount'] ?? 0,
      totalOngs: json['totalOngs'] ?? json['ongsCount'] ?? 0,
      totalVagas: json['totalVagas'] ?? json['opportunitiesCount'] ?? 0,
      totalCandidaturas:
          json['totalCandidaturas'] ?? json['applicationsCount'] ?? 0,
      totalPublicacoesFeed:
          json['totalPublicacoesFeed'] ?? json['postsCount'] ?? 0,
      totalExperiencias:
          json['totalExperiencias'] ?? json['experiencesCount'] ?? 0,
    );
  }
}

class AdminUserModel {
  final String id;
  final String nome;
  final String email;
  final String role;
  final String? tipoDocumento;
  final String? documento;
  final String? fotoUrl;
  final String? dataCriacao;

  AdminUserModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.role,
    this.tipoDocumento,
    this.documento,
    this.fotoUrl,
    this.dataCriacao,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id']?.toString() ?? '',
      nome: json['nome'] ?? json['name'] ?? 'Utilizador sem nome',
      email: json['email'] ?? '',
      role: json['role'] ?? 'USER',
      tipoDocumento: json['tipoDocumento'],
      documento: json['cpf'] ?? json['cnpj'] ?? json['documento'],
      fotoUrl: json['avatar'] ?? json['fotoUrl'],
      dataCriacao: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
                  ?.toLocal()
                  .toString()
                  .split(' ')
                  .first ??
              json['createdAt'].toString()
          : null,
    );
  }

  AdminUserModel copyWith({
    String? id,
    String? nome,
    String? email,
    String? role,
    String? tipoDocumento,
    String? documento,
    String? fotoUrl,
    String? dataCriacao,
  }) {
    return AdminUserModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      role: role ?? this.role,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      documento: documento ?? this.documento,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      dataCriacao: dataCriacao ?? this.dataCriacao,
    );
  }
}
