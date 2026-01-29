import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/users_models.dart';

class SessionService {
  static const String _keyUser = 'current_user';
  static const String _keyIsLoggedIn = 'is_logged_in';

  // ================= SAVE SESSION =================
  Future<void> saveSession(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert UserModel ke JSON string
      final userJson = jsonEncode(user.toJson());
      
      await prefs.setString(_keyUser, userJson);
      await prefs.setBool(_keyIsLoggedIn, true);
    } catch (e) {
      print('Error saving session: $e');
    }
  }

  // ================= GET SESSION =================
  Future<UserModel?> getSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      if (!isLoggedIn) return null;
      
      final userJson = prefs.getString(_keyUser);
      if (userJson == null) return null;
      
      // Convert JSON string ke UserModel
      final userMap = jsonDecode(userJson);
      return UserModel.fromJson(userMap);
    } catch (e) {
      print('Error getting session: $e');
      return null;
    }
  }

  // ================= CHECK IF LOGGED IN =================
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyIsLoggedIn) ?? false;
    } catch (e) {
      return false;
    }
  }

  // ================= CLEAR SESSION (LOGOUT) =================
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUser);
      await prefs.setBool(_keyIsLoggedIn, false);
    } catch (e) {
      print('Error clearing session: $e');
    }
  }

  // ================= GET USER ROLE =================
  Future<String?> getUserRole() async {
    try {
      final user = await getSession();
      return user?.role;
    } catch (e) {
      return null;
    }
  }

  // ================= GET USER ID =================
  Future<int?> getUserId() async {
    try {
      final user = await getSession();
      return user?.idUser;
    } catch (e) {
      return null;
    }
  }

  // ================= GET USERNAME =================
  Future<String?> getUsername() async {
    try {
      final user = await getSession();
      return user?.username;
    } catch (e) {
      return null;
    }
  }
}