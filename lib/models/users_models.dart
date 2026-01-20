class LoginModel {
  final String username;
  final String password;

  LoginModel({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }

 
  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      username: json['username'] ?? '',
      password: json['password'] ?? '',
    );
  }


  bool isValid() {
    return username.isNotEmpty && password.isNotEmpty;
  }
}

class LoginResponse {
  final bool success;
  final String message;
  final String? token;
  final UserData? userData;

  LoginResponse({
    required this.success,
    required this.message,
    this.token,
    this.userData,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      token: json['token'],
      userData: json['user'] != null 
          ? UserData.fromJson(json['user']) 
          : null,
    );
  }
}

class UserData {
  final String id;
  final String username;
  final String? email;
  final String? fullName;
  final String? role;

  UserData({
    required this.id,
    required this.username,
    this.email,
    this.fullName,
    this.role,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'],
      fullName: json['full_name'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'role': role,
    };
  }
}