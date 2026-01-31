class UserModel {
  final String id;     
  final String username;
  final String role;

  UserModel({
    required this.id,
    required this.username,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id_user'],
        username: json['username'],
        role: json['role'],
      );

  Map<String, dynamic> toJson() => {
        'id_user': id,
        'username': username,
        'role': role,
      };
}
