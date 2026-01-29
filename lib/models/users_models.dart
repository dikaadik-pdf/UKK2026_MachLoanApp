class UserModel {
  final int? idUser;
  final String username;
  final String? role;
  final String? password;

  UserModel({
    this.idUser,
    required this.username,
    this.role,
    this.password,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      idUser: json['id_user'] is int
          ? json['id_user']
          : int.tryParse(json['id_user'].toString()),
      username: json['username'] ?? '',
      role: json['role'],
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_user': idUser,
      'username': username,
      'role': role,
      'password': password,
    };
  }

  // ✅ TAMBAHKAN INI
  bool isValid() {
    return username.isNotEmpty && (password?.isNotEmpty ?? false);
  }
}