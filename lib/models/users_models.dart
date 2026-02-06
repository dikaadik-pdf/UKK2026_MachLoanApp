class UserModel {
  final String id;
  final String username;
  final String role;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.username,
    required this.role,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id_user'],
        username: json['username'],
        role: json['role'],
        avatarUrl: json['avatar_url'],
      );

  Map<String, dynamic> toJson() => {
        'id_user': id,
        'username': username,
        'role': role,
        'avatar_url': avatarUrl,
      };

  // Helper method untuk copy dengan perubahan
  UserModel copyWith({
    String? id,
    String? username,
    String? role,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, username: $username, role: $role, avatarUrl: $avatarUrl)';
  }
}