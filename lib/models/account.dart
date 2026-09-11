enum UserRole { admin, garcom }

extension UserRoleLabel on UserRole {
  String get label => this == UserRole.admin ? 'Administrador' : 'Garcom';
}

class UserAccount {
  final String id;
  final String name;
  final String username;
  final String password;
  final UserRole role;
  final bool active;

  const UserAccount({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    required this.role,
    this.active = true,
  });

  UserAccount copyWith({
    String? id,
    String? name,
    String? username,
    String? password,
    UserRole? role,
    bool? active,
  }) {
    return UserAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'password': password,
        'role': role.index,
        'active': active,
      };

  factory UserAccount.fromJson(Map<String, dynamic> map) {
    return UserAccount(
      id: map['id'] as String,
      name: (map['name'] ?? 'Usuario') as String,
      username: (map['username'] ?? '') as String,
      password: (map['password'] ?? '') as String,
      role: UserRole.values[(map['role'] as int?) ?? UserRole.garcom.index],
      active: (map['active'] as bool?) ?? true,
    );
  }
}
